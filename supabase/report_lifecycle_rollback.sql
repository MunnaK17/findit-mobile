-- Membatalkan supabase/report_lifecycle.sql.
revoke update (foto_barang) on public.reports from authenticated;
drop function if exists public.extend_report(bigint);
drop index if exists public.reports_public_list_idx;
alter table public.reports drop column if exists expires_at;
