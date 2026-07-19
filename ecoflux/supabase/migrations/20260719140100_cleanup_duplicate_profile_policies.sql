-- Supprime les policies RLS dupliquées sur "profiles" (nommage FR historique),
-- redondantes avec les policies EN équivalentes ("Users can ... own profile").
drop policy if exists "Insertion profil personnel" on public.profiles;
drop policy if exists "Lecture profil personnel" on public.profiles;
drop policy if exists "Modification profil personnel" on public.profiles;
