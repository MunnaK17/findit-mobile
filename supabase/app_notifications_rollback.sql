-- Membatalkan supabase/app_notifications.sql.
alter publication supabase_realtime drop table public.app_notifications;
drop table if exists public.app_notifications;
