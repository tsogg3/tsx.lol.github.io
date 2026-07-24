DROP TRIGGER IF EXISTS on_auth_user_created_promote ON auth.users;
CREATE TRIGGER on_auth_user_created_promote
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.promote_first_user();