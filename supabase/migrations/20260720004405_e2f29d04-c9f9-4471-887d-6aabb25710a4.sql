
-- Roles
CREATE TYPE public.app_role AS ENUM ('admin');
CREATE TYPE public.profile_status AS ENUM ('online','away','offline');

CREATE TABLE public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role public.app_role NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, role)
);
GRANT SELECT ON public.user_roles TO authenticated;
GRANT ALL ON public.user_roles TO service_role;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role public.app_role)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role);
$$;

CREATE POLICY "own roles read" ON public.user_roles FOR SELECT TO authenticated USING (user_id = auth.uid());

-- Auto-promote first user to admin
CREATE OR REPLACE FUNCTION public.promote_first_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.user_roles WHERE role = 'admin') THEN
    INSERT INTO public.user_roles (user_id, role) VALUES (NEW.id, 'admin');
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.promote_first_user();

-- Profiles (single row keyed 'main')
CREATE TABLE public.profiles (
  id text PRIMARY KEY DEFAULT 'main',
  name text NOT NULL DEFAULT 'Seu Nome',
  username text NOT NULL DEFAULT 'usuario',
  bio text NOT NULL DEFAULT 'Sua biografia aqui.',
  location text NOT NULL DEFAULT '',
  pronoun text NOT NULL DEFAULT '',
  avatar_url text NOT NULL DEFAULT '',
  status public.profile_status NOT NULL DEFAULT 'online',
  view_count bigint NOT NULL DEFAULT 0,
  music_url text NOT NULL DEFAULT '',
  music_title text NOT NULL DEFAULT '',
  music_artist text NOT NULL DEFAULT '',
  music_cover text NOT NULL DEFAULT '',
  music_autoplay boolean NOT NULL DEFAULT false,
  theme_primary text NOT NULL DEFAULT '#a855f7',
  bg_image text NOT NULL DEFAULT '',
  account_created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.profiles TO anon, authenticated;
GRANT UPDATE ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO service_role;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public read profile" ON public.profiles FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "admin update profile" ON public.profiles FOR UPDATE TO authenticated USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));

INSERT INTO public.profiles (id, name, username, bio, location, pronoun, avatar_url)
VALUES ('main', 'Seu Nome', 'usuario', 'Bem-vindo ao meu perfil. Edite tudo pelo painel admin.', 'Brasil', 'ele/dele', '');

-- Badges
CREATE TABLE public.badges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id text NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE DEFAULT 'main',
  name text NOT NULL,
  description text NOT NULL DEFAULT '',
  icon text NOT NULL DEFAULT 'Award',
  color text NOT NULL DEFAULT '#a855f7',
  position int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.badges TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.badges TO authenticated;
GRANT ALL ON public.badges TO service_role;
ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public read badges" ON public.badges FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "admin manage badges" ON public.badges FOR ALL TO authenticated
USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));

INSERT INTO public.badges (name, description, icon, color, position) VALUES
('Owner','Dono desta página','Crown','#facc15',0),
('Developer','Desenvolvedor','Code','#22d3ee',1),
('Verified','Conta verificada','BadgeCheck','#a855f7',2),
('Premium','Membro Premium','Sparkles','#ec4899',3);

-- Social links
CREATE TABLE public.social_links (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id text NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE DEFAULT 'main',
  platform text NOT NULL,
  name text NOT NULL,
  description text NOT NULL DEFAULT '',
  url text NOT NULL,
  icon text NOT NULL DEFAULT 'Link',
  color text NOT NULL DEFAULT '#a855f7',
  position int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.social_links TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON public.social_links TO authenticated;
GRANT ALL ON public.social_links TO service_role;
ALTER TABLE public.social_links ENABLE ROW LEVEL SECURITY;
CREATE POLICY "public read links" ON public.social_links FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY "admin manage links" ON public.social_links FOR ALL TO authenticated
USING (public.has_role(auth.uid(),'admin')) WITH CHECK (public.has_role(auth.uid(),'admin'));

INSERT INTO public.social_links (platform, name, description, url, icon, color, position) VALUES
('discord','Discord','Me encontre no Discord','https://discord.com','MessageCircle','#5865F2',0),
('github','GitHub','Meus projetos','https://github.com','Github','#ffffff',1),
('instagram','Instagram','Meu Instagram','https://instagram.com','Instagram','#E1306C',2),
('youtube','YouTube','Meu canal','https://youtube.com','Youtube','#FF0000',3);

-- Increment view counter (public RPC)
CREATE OR REPLACE FUNCTION public.increment_profile_views()
RETURNS bigint LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v bigint;
BEGIN
  UPDATE public.profiles SET view_count = view_count + 1 WHERE id = 'main' RETURNING view_count INTO v;
  RETURN v;
END;
$$;
GRANT EXECUTE ON FUNCTION public.increment_profile_views() TO anon, authenticated;
