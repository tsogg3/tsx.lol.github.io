-- 1) has_role: switch to SECURITY INVOKER (own user_roles row is readable via RLS)
CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role public.app_role)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role);
$$;

-- 2) Lock down EXECUTE on the remaining SECURITY DEFINER functions.
--    Triggers run as table owner regardless of EXECUTE grants, and
--    increment_profile_views will only be called by the service role from a server function.
REVOKE ALL ON FUNCTION public.increment_profile_views() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.promote_first_user() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.has_role(uuid, public.app_role) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_profile_views() TO service_role;
GRANT EXECUTE ON FUNCTION public.promote_first_user() TO service_role;