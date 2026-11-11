-- FindIT: pengetatan RLS untuk project Findit-UBSI (ulrxqbvccwhcvywssjfb).
-- Jalankan sekali di Supabase Dashboard > SQL Editor. Rollback: rls_hardening_rollback.sql.
--
-- Laravel konek sebagai role postgres (bypassrls = true), jadi query database web admin tidak terpengaruh.
-- Policy INSERT dan UPDATE storage tidak diubah: upload foto web memakai anon key dengan x-upsert.

begin;

-- =====================================================================
-- Hak akses dasar: anon hanya boleh membaca, kolom yang bisa diubah user dibatasi.
-- =====================================================================
revoke insert, update, delete, truncate on public.reports, public.claims, public.profiles from anon;
revoke truncate on public.reports, public.claims, public.profiles from authenticated;

-- role tidak bisa diubah sendiri.
revoke update on public.profiles from authenticated;
grant update (phone, avatar_url) on public.profiles to authenticated;

-- admin_notes dan id_user tidak bisa diubah pemilik.
revoke update on public.reports from authenticated;
grant update (nama_barang, deskripsi, lokasi, tanggal_kejadian, id_category, id_campus, status)
  on public.reports to authenticated;

-- =====================================================================
-- profiles: tiap user hanya bisa membaca dan mengubah barisnya sendiri.
-- =====================================================================
drop policy if exists "Allow public read profiles" on public.profiles;
drop policy if exists "Allow user update own profile" on public.profiles;

create policy "profiles_select_own" on public.profiles
  for select to authenticated
  using (id = (select auth.uid()));

create policy "profiles_update_own" on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- =====================================================================
-- reports: publik hanya melihat laporan terverifikasi, pemilik melihat miliknya.
-- =====================================================================
drop policy if exists "Allow public read approved reports" on public.reports;
drop policy if exists "Allow authenticated insert reports" on public.reports;
drop policy if exists "Allow owner update reports" on public.reports;

create policy "reports_select_public_or_own" on public.reports
  for select to anon, authenticated
  using (status in ('approved', 'completed') or id_user = (select auth.uid()));

create policy "reports_insert_own_pending" on public.reports
  for insert to authenticated
  with check (
    id_user = (select auth.uid())
    and status = 'pending'
    and admin_notes is null
  );

-- Pemilik tidak bisa menyetujui laporannya sendiri: hasil update hanya boleh pending atau rejected.
create policy "reports_update_own_unverified" on public.reports
  for update to authenticated
  using (id_user = (select auth.uid()) and status in ('pending', 'approved', 'rejected'))
  with check (id_user = (select auth.uid()) and status in ('pending', 'rejected'));

-- Laporan approved tidak bisa dihapus pemilik: FK claims ON DELETE CASCADE akan ikut menghapus klaim orang lain.
create policy "reports_delete_own_unverified" on public.reports
  for delete to authenticated
  using (id_user = (select auth.uid()) and status in ('pending', 'rejected'));

-- =====================================================================
-- claims: hanya atas nama sendiri, pada barang temuan terverifikasi milik orang lain.
-- =====================================================================
drop policy if exists "Allow users read claims" on public.claims;
drop policy if exists "Allow authenticated insert claims" on public.claims;

create policy "claims_select_own" on public.claims
  for select to authenticated
  using (id_user = (select auth.uid()));

create policy "claims_insert_own_pending" on public.claims
  for insert to authenticated
  with check (
    id_user = (select auth.uid())
    and status_klaim = 'pending'
    and catatan_admin is null
    and exists (
      select 1
      from public.reports r
      where r.id = id_report
        and r.jenis_laporan = 'temuan'
        and r.status = 'approved'
        and r.id_user is distinct from (select auth.uid())
    )
  );

-- =====================================================================
-- Satu klaim aktif per user per laporan, plus index untuk filter RLS.
-- =====================================================================
create unique index if not exists claims_one_active_per_user
  on public.claims (id_report, id_user)
  where status_klaim <> 'rejected';

create index if not exists claims_id_user_idx on public.claims (id_user);
create index if not exists reports_id_user_idx on public.reports (id_user);

-- =====================================================================
-- Pendaftaran: metadata signup dikendalikan client, jadi role dan domain email divalidasi di sini.
-- Role admin diberikan lewat database setelah akun terdaftar, bukan lewat signup.
-- =====================================================================
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $function$
begin
  if new.email is null or new.email !~* '^[^@\s]+@([a-z0-9-]+\.)*bsi\.ac\.id$' then
    raise exception 'Pendaftaran hanya dapat menggunakan email resmi BSI (@bsi.ac.id)';
  end if;

  insert into public.profiles (id, name, email, role, nim, nip, phone, id_campus, prodi_unit)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', 'User'),
    new.email,
    case when new.raw_user_meta_data->>'role' = 'staff' then 'staff' else 'mahasiswa' end,
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

-- =====================================================================
-- Storage: tidak ada alur aplikasi yang menghapus foto, jadi hapus hanya untuk pemilik file.
-- =====================================================================
drop policy if exists "Allow public delete reports storage" on storage.objects;

create policy "reports_storage_delete_own" on storage.objects
  for delete to authenticated
  using (bucket_id = 'reports' and owner_id = (select auth.uid())::text);

commit;
