-- Membatalkan supabase/email_notifications.sql.
drop trigger if exists reports_notify_email on public.reports;
drop trigger if exists claims_notify_email on public.claims;
drop function if exists public.notify_email_dispatch();
drop function if exists public.verify_notify_secret(text);
delete from vault.secrets where name in ('notify_email_secret', 'notify_email_url');
drop table if exists public.email_notifications;
revoke update (email_notifications) on public.profiles from authenticated;
alter table public.profiles drop column if exists email_notifications;
-- pg_net dibiarkan terpasang; hapus manual bila tidak dipakai: drop extension pg_net;
