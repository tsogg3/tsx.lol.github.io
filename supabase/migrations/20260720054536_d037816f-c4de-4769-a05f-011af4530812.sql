
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_decoration text NOT NULL DEFAULT '';
ALTER TABLE public.social_links ADD COLUMN IF NOT EXISTS icon_url text NOT NULL DEFAULT '';

-- Ensure the promote-first-user trigger exists on auth.users
DROP TRIGGER IF EXISTS on_auth_user_created_promote ON auth.users;
CREATE TRIGGER on_auth_user_created_promote
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.promote_first_user();
