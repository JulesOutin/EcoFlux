-- Documente le trigger qui crée automatiquement une ligne "profiles" à l'inscription.
-- Existe déjà en base (créé avant le suivi des migrations par la CLI) ; ce fichier
-- sert uniquement à versionner sa définition. "or replace" le rend idempotent.
create or replace trigger "on_auth_user_created"
  after insert on auth.users
  for each row execute function public.handle_new_user();
