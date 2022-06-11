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
dvdxchap --title $(( $numero_piste + 1 )) /dev/sr0 > "${repertoire_encodage}/chapitres.txt"

# Éjecter le DVD
eject /dev/sr0

# Récupérer les numéros de pistes des sous-titres
sub_title=$(grep '\--sid' "${repertoire_encodage}/meta.txt" | cut -d'=' -f2 | cut -d' ' -f1)
# Récupérer les langues des pistes de sous-titres
sub_lang=$(grep '\--sid' "${repertoire_encodage}meta.txt" | cut -d'=' -f3 | cut -d' ' -f1)

(
cd "${repertoire_encodage}"
mencoder "${repertoire_encodage}/${titre_du_film}.vob" -vobsuboutindex 0 -o /dev/null -nosound -ovc frameno -vobsubout ${sub_lang} -sid ${sub_title}
)
