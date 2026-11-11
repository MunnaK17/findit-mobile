-- Kotak notifikasi di dalam aplikasi (ikon lonceng di Beranda).
-- Baris dibuat oleh Edge Function notify-email (service_role) untuk event yang sama dengan email,
-- terlepas dari pengaturan email pengguna.
-- Rollback: supabase/app_notifications_rollback.sql

create table if not exists public.app_notifications (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  event text not null,
  report_id bigint references public.reports(id) on delete cascade,
  claim_id bigint references public.claims(id) on delete cascade,
  title text not null,
  body text not null,
  read_at timestamptz,
  created_at timestamptz not null default now(),
  unique nulls not distinct (user_id, event, report_id, claim_id)
);
create index if not exists app_notifications_user_created_idx
  on public.app_notifications (user_id, created_at desc);

alter table public.app_notifications enable row level security;

create policy "app_notifications_select_own" on public.app_notifications
  for select to authenticated
  using (user_id = (select auth.uid()));

create policy "app_notifications_update_own" on public.app_notifications
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- Pengguna hanya boleh menandai sudah dibaca; isi notifikasi tidak bisa diubah.
revoke all on public.app_notifications from anon, authenticated;
grant select on public.app_notifications to authenticated;
grant update (read_at) on public.app_notifications to authenticated;

-- Realtime: badge lonceng ter-update tanpa refresh.
alter publication supabase_realtime add table public.app_notifications;
