ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS meta_title TEXT NOT NULL DEFAULT 'Perfil — Neon Bio',
  ADD COLUMN IF NOT EXISTS meta_description TEXT NOT NULL DEFAULT 'Cartão de perfil animado com efeitos neon.',
  ADD COLUMN IF NOT EXISTS meta_image TEXT NOT NULL DEFAULT '';