-- Le bucket "avatars" (public, nécessaire pour l'affichage des avatars dans
-- l'app) n'avait ni limite de taille ni restriction de type MIME : un
-- utilisateur authentifié pouvait uploader un fichier arbitrairement gros ou
-- d'un type non-image sur une URL publique. On restreint aux formats image
-- réellement utilisés par l'app (image_picker + upload en JPEG) avec une
-- marge confortable au-delà des 512x512 qualité 85 générés côté client.
update storage.buckets
set file_size_limit    = 2097152, -- 2 Mo
    allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp']
where id = 'avatars';
