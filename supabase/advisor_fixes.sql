-- FindIT: menutup temuan Security Advisor "SECURITY DEFINER function executable" via /rest/v1/rpc.
-- Kedua fungsi hanya dipakai trigger. EXECUTE dicek saat trigger dibuat, bukan saat trigger berjalan,
-- jadi signup (on_auth_user_created) dan event trigger ensure_rls tetap jalan.
-- Rollback: grant execute on function public.handle_new_user(), public.rls_auto_enable() to public, anon, authenticated;

begin;

revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.rls_auto_enable() from public, anon, authenticated;

-- Trigger signup dijalankan oleh supabase_auth_admin, yang sebelumnya mewarisi EXECUTE dari PUBLIC.
grant execute on function public.handle_new_user() to supabase_auth_admin;

commit;
