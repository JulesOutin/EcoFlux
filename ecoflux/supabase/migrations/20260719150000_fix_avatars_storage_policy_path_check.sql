-- La policy "avatars_all" vérifiait la propriété (owner_id) en lecture/suppression
-- mais pas à l'insertion (with_check ne testait que bucket_id) : un utilisateur
-- pouvait écrire à n'importe quel chemin du bucket, y compris squatter le
-- dossier d'un autre utilisateur qui n'a pas encore uploadé d'avatar.
-- On vérifie désormais le chemin (premier segment = uuid utilisateur) sur les
-- deux clauses, conformément à la convention "$userId/avatar.jpg" utilisée par l'app.
drop policy if exists "avatars_all" on storage.objects;

create policy "avatars_all"
  on storage.objects
  for all
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (auth.uid())::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = (auth.uid())::text
  );
