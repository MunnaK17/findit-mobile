-- Mengembalikan kondisi sebelum rls_hardening.sql, termasuk celah keamanannya.
-- Pakai hanya bila pengetatan merusak alur produksi, lalu perbaiki dan terapkan ulang.

begin;

drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "profiles_update_own" on public.profiles;
drop policy if exists "reports_select_public_or_own" on public.reports;
drop policy if exists "reports_insert_own_pending" on public.reports;
drop policy if exists "reports_update_own_unverified" on public.reports;
drop policy if exists "reports_delete_own_unverified" on public.reports;
drop policy if exists "claims_select_own" on public.claims;
drop policy if exists "claims_insert_own_pending" on public.claims;
drop policy if exists "reports_storage_delete_own" on storage.objects;

create policy "Allow public read profiles" on public.profiles for select using (true);
create policy "Allow user update own profile" on public.profiles for update using (auth.uid() = id);
create policy "Allow public read approved reports" on public.reports for select using (true);
create policy "Allow authenticated insert reports" on public.reports for insert with check (true);
create policy "Allow owner update reports" on public.reports for update using (auth.uid() = id_user);
create policy "Allow users read claims" on public.claims for select using (true);
create policy "Allow authenticated insert claims" on public.claims for insert with check (true);
create policy "Allow public delete reports storage" on storage.objects
  for delete using (bucket_id = 'reports');

grant select, insert, update, delete, truncate on public.reports, public.claims, public.profiles to anon, authenticated;

drop index if exists public.claims_one_active_per_user;
drop index if exists public.claims_id_user_idx;
drop index if exists public.reports_id_user_idx;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
as $function$
begin
  insert into public.profiles (id, name, email, role, nim, nip, phone, id_campus, prodi_unit)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', 'User'),
    new.email,
    coalesce(new.raw_user_meta_data->>'role', 'mahasiswa'),
    new.raw_user_meta_data->>'nim',
    new.raw_user_meta_data->>'nip',
    new.raw_user_meta_data->>'phone',
    (new.raw_user_meta_data->>'id_campus')::bigint,
    new.raw_user_meta_data->>'prodi_unit'
  )
  on conflict (id) do nothing;
  return new;
end;
$function$;

commit;
