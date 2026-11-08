-- FindIT: perbaikan P0 untuk project Findit-UBSI (ulrxqbvccwhcvywssjfb).
-- Jalankan setelah rls_hardening.sql. Rollback: p0_fixes_rollback.sql.
-- Aplikasi mobile versi terbaru membaca public_profiles, jadi jalankan file ini sebelum merilis build baru.

begin;

-- =====================================================================
-- Profil publik pelapor: policy profiles_select_own memblokir join reports -> profiles,
-- sehingga nama pelapor tidak pernah tampil. View ini hanya membuka kolom yang aman.
-- Email, nomor HP, NIM, dan NIP tetap tertutup.
-- View dimiliki postgres (bukan security_invoker), jadi RLS profiles sengaja dilewati untuk kolom ini saja.
-- =====================================================================
create or replace view public.public_profiles as
select p.id, p.name, p.role, p.id_campus, p.prodi_unit
from public.profiles p;

revoke all on public.public_profiles from anon, authenticated;
grant select on public.public_profiles to anon, authenticated;

-- =====================================================================
-- Tandai laporan selesai: policy reports_update_own_unverified hanya mengizinkan hasil
-- pending atau rejected, jadi update langsung ke completed ditolak tanpa error.
-- Fungsi ini hanya mengizinkan pemilik mengubah laporan approved menjadi completed.
-- =====================================================================
create or replace function public.mark_report_completed(p_report_id bigint)
returns boolean
language plpgsql
security definer
set search_path = public
as $function$
begin
  update public.reports
     set status = 'completed'
   where id = p_report_id
     and id_user = (select auth.uid())
     and status = 'approved';
  return found;
end;
$function$;

revoke all on function public.mark_report_completed(bigint) from public, anon;
grant execute on function public.mark_report_completed(bigint) to authenticated;

commit;
