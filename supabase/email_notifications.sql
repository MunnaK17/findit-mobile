-- Notifikasi email FindIT.
-- Perubahan status laporan/klaim -> trigger -> pg_net -> Edge Function notify-email -> Gmail SMTP.
-- Rollback: supabase/email_notifications_rollback.sql

create extension if not exists pg_net with schema extensions;

-- 1. Preferensi pengguna: notifikasi email aktif secara default, bisa dimatikan di Profil.
alter table public.profiles
  add column if not exists email_notifications boolean not null default true;
grant update (email_notifications) on public.profiles to authenticated;

-- 2. Log pengiriman: satu baris per (event, ref, penerima) agar tidak ada email ganda.
create table if not exists public.email_notifications (
  id bigint generated always as identity primary key,
  event text not null,
  ref_id bigint not null,
  recipient uuid references public.profiles(id) on delete set null,
  recipient_email text,
  status text not null default 'pending'
    check (status in ('pending', 'sent', 'skipped', 'failed')),
  error text,
  created_at timestamptz not null default now(),
  sent_at timestamptz,
  unique (event, ref_id, recipient)
);
alter table public.email_notifications enable row level security;
-- Tanpa policy: hanya service_role (Edge Function) yang bisa membaca/menulis.
revoke all on public.email_notifications from anon, authenticated;

-- 3. Secret webhook dibuat acak di Vault; nilainya tidak pernah keluar dari database.
do $$
begin
  if not exists (select 1 from vault.secrets where name = 'notify_email_secret') then
    perform vault.create_secret(encode(extensions.gen_random_bytes(32), 'hex'), 'notify_email_secret');
  end if;
  if not exists (select 1 from vault.secrets where name = 'notify_email_url') then
    perform vault.create_secret(
      'https://ulrxqbvccwhcvywssjfb.supabase.co/functions/v1/notify-email',
      'notify_email_url');
  end if;
end $$;

-- Edge Function memverifikasi header lewat RPC ini (hanya service_role).
create or replace function public.verify_notify_secret(p_secret text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from vault.decrypted_secrets
    where name = 'notify_email_secret' and decrypted_secret = p_secret
  );
$$;
revoke execute on function public.verify_notify_secret(text) from public, anon, authenticated;
grant execute on function public.verify_notify_secret(text) to service_role;

-- 4. Trigger: kirim event ke Edge Function. Gagal kirim tidak boleh menggagalkan update data.
create or replace function public.notify_email_dispatch()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event text;
  v_url text;
  v_secret text;
begin
  if tg_table_name = 'reports' then
    if new.status is distinct from old.status
       and new.status in ('approved', 'rejected', 'completed') then
      v_event := 'report_' || new.status;
    end if;
  elsif tg_table_name = 'claims' then
    if tg_op = 'INSERT' then
      v_event := 'claim_created';
    elsif new.status_klaim is distinct from old.status_klaim
          and new.status_klaim in ('approved', 'rejected') then
      v_event := 'claim_' || new.status_klaim;
    end if;
  end if;

  if v_event is null then
    return new;
  end if;

  select decrypted_secret into v_url from vault.decrypted_secrets where name = 'notify_email_url';
  select decrypted_secret into v_secret from vault.decrypted_secrets where name = 'notify_email_secret';
  if v_url is null or v_secret is null then
    return new;
  end if;

  perform net.http_post(
    url := v_url,
    body := jsonb_build_object('event', v_event, 'id', new.id),
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-findit-secret', v_secret
    ),
    timeout_milliseconds := 20000  -- koneksi SMTP Gmail bisa lebih lama dari 5 detik
  );
  return new;
exception when others then
  raise warning 'notify_email_dispatch gagal untuk % %: %', tg_table_name, new.id, sqlerrm;
  return new;
end;
$$;
revoke execute on function public.notify_email_dispatch() from public, anon, authenticated;

drop trigger if exists reports_notify_email on public.reports;
create trigger reports_notify_email
  after update of status on public.reports
  for each row execute function public.notify_email_dispatch();

drop trigger if exists claims_notify_email on public.claims;
create trigger claims_notify_email
  after insert or update of status_klaim on public.claims
  for each row execute function public.notify_email_dispatch();
