
REVOKE EXECUTE ON FUNCTION public.promote_first_user() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.increment_profile_views() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.increment_profile_views() TO anon, authenticated;
