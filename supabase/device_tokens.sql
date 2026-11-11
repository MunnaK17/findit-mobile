-- Token FCM per perangkat untuk push notification di HP.
-- Diisi aplikasi lewat RPC register_device_token; dibaca Edge Function notify-email (service_role).
-- Rollback: supabase/device_tokens_rollback.sql

create table if not exists public.device_tokens (
  token text primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  platform text not null default 'android' check (platform in ('android', 'ios')),
  updated_at timestamptz not null default now()
);
create index if not exists device_tokens_user_idx on public.device_tokens (user_id);

-- Tanpa policy dan tanpa grant: klien hanya lewat RPC di bawah.
alter table public.device_tokens enable row level security;
revoke all on public.device_tokens from anon, authenticated;

-- Satu HP bisa dipakai bergantian; token selalu pindah ke akun yang terakhir login.
create or replace function public.register_device_token(p_token text, p_platform text default 'android')
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then
    raise exception 'harus login';
  end if;
  if p_token is null or length(p_token) < 20 or length(p_token) > 4096 then
    raise exception 'token tidak valid';
  end if;
  insert into public.device_tokens (token, user_id, platform, updated_at)
  values (p_token, (select auth.uid()), coalesce(p_platform, 'android'), now())
  on conflict (token) do update
    set user_id = excluded.user_id,
        platform = excluded.platform,
        updated_at = now();
end;
$$;

create or replace function public.unregister_device_token(p_token text)
returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.device_tokens
  where token = p_token and user_id = (select auth.uid());
$$;

revoke execute on function public.register_device_token(text, text) from public, anon;
revoke execute on function public.unregister_device_token(text) from public, anon;
grant execute on function public.register_device_token(text, text) to authenticated;
grant execute on function public.unregister_device_token(text) to authenticated;
