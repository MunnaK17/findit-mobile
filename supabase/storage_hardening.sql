-- Perketat Storage bucket `reports`.
-- Sebelumnya: siapa pun (termasuk anon) bisa UPDATE/menimpa file dan INSERT file baru.
-- App selalu mengunggah file baru bernama reports/<millis>_<user_id>.<ext>, tidak pernah menimpa.
-- Rollback: supabase/storage_hardening_rollback.sql

drop policy if exists "Allow public update reports storage" on storage.objects;

drop policy if exists "Allow authenticated upload reports storage" on storage.objects;
create policy "reports_storage_insert_own" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'reports'
    and (storage.foldername(name))[1] = 'reports'
    and storage.filename(name) like '%\_' || (select auth.uid())::text || '.%'
  );
