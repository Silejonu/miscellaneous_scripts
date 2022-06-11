#!/usr/bin/bash

read -rp 'Titre du film ? ' titre_du_film
repertoire_encodage="$(xdg-user-dir VIDEOS)/rips/${titre_du_film}"

mkdir -p "${repertoire_encodage}"

# Extraire les sous-titres
cp /run/media/${USER}/*/VIDEO_TS/*.IFO "${repertoire_encodage}"
# Extraire les méta-données
mpv dvd://longest > "${repertoire_encodage}/meta.txt" &
sleep 10
kill $(pidof mpv)
# Récupérer le numéro de piste
numero_piste=$(grep '\[dvdnav\] Selecting title' "${repertoire_encodage}/meta.txt" | cut -d' ' -f4 | tr -d '.')
# Extraire le fichier .vob
mpv dvd://longest --stream-dump="${repertoire_encodage}/${titre_du_film}.vob"

# Récupérer le chapitrage
dvdxchap -t ${numero_piste} /dev/sr0 > "${repertoire_encodage}/chapitres.txt"

# Éjecter le DVD
eject /dev/sr0