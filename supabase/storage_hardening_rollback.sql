-- Mengembalikan policy Storage bucket `reports` ke keadaan sebelum storage_hardening.sql.
drop policy if exists "reports_storage_insert_own" on storage.objects;
create policy "Allow authenticated upload reports storage" on storage.objects
  for insert with check (bucket_id = 'reports');
create policy "Allow public update reports storage" on storage.objects
  for update using (bucket_id = 'reports') with check (bucket_id = 'reports');
