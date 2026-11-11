-- Masa berlaku laporan + edit foto.
-- Laporan publik disembunyikan dari daftar setelah expires_at lewat (filter di query app),
-- pemilik bisa memperpanjang 30 hari lewat RPC extend_report. Kolom status tidak diubah
-- sehingga dashboard admin web tetap memakai nilai status yang sama.
-- Rollback: supabase/report_lifecycle_rollback.sql

alter table public.reports
  add column if not exists expires_at timestamptz;

update public.reports
   set expires_at = created_at + interval '60 days'
 where expires_at is null;

alter table public.reports
  alter column expires_at set default (now() + interval '60 days'),
  alter column expires_at set not null;

create index if not exists reports_public_list_idx
  on public.reports (status, expires_at, created_at desc);

-- Pemilik memperpanjang laporan terverifikasi miliknya 30 hari dari sekarang
-- (atau dari expires_at bila masih berlaku). Mengembalikan expires_at baru, null bila ditolak.
create or replace function public.extend_report(p_report_id bigint)
returns timestamptz
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_new timestamptz;
begin
  update public.reports
     set expires_at = greatest(now(), expires_at) + interval '30 days'
   where id = p_report_id
     and id_user = (select auth.uid())
     and status = 'approved'
  returning expires_at into v_new;
  return v_new;
end;
$$;
revoke execute on function public.extend_report(bigint) from public, anon;
grant execute on function public.extend_report(bigint) to authenticated;

-- Ganti foto lewat form edit. Policy reports_update_own_unverified tetap berlaku:
-- laporan terverifikasi yang diubah wajib kembali ke status pending.
grant update (foto_barang) on public.reports to authenticated;
