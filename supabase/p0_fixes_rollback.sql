-- Mengembalikan kondisi sebelum p0_fixes.sql.
-- Build mobile yang membaca public_profiles akan gagal memuat laporan setelah rollback ini.

begin;

drop function if exists public.mark_report_completed(bigint);
drop view if exists public.public_profiles;

commit;
