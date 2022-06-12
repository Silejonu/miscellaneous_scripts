#!/usr/bin/bash

for cmd in mpv dvdxchap ffmpeg mencoder ; do
  command -v ${cmd} > /dev/null
  if [[ $? -ne 0 ]] ; then
    echo "Command '${cmd}' is missing, please install it and rerun the script."
    exit 1
  fi
done

read -rp 'Movie title? ' movie_title
rip_directory="$(xdg-user-dir VIDEOS)/rips/${movie_title}"
vob_file="${rip_directory}/${movie_title}.vob"
mkdir -p "${rip_directory}"

# Extract subtitles
cp /run/media/${USER}/*/VIDEO_TS/*.IFO "${rip_directory}"

# Extract metadata
mpv dvd://longest -frames 0 > "${rip_directory}/metadata.txt"

# Dump the movie to a .vob file
title_number=$(grep '\[dvdnav\] Selecting title' "${rip_directory}/metadata.txt" | cut -d' ' -f4 | tr -d '.')
mpv dvd://longest --stream-dump="${vob_file}"

# Dump chapters
dvdxchap --title $(( $title_number + 1 )) /dev/sr0 > "${rip_directory}/chapters.txt"

eject /dev/sr0

# Store subtitles stream IDs
sub_title=($(grep -E "\--sid.*\--slang" "${rip_directory}/metadata.txt" | cut -d'=' -f2 | cut -d' ' -f1))
# Store subtitles languages
sub_lang=($(grep -E '\--sid.*\--slang' "${rip_directory}/metadata.txt" | cut -d'=' -f3 | cut -d' ' -f1))
# Dump subtitles
(
cd "${rip_directory}"
# Iterate through all subtitle streams
for i in $(seq 0 $(( ${#sub_title[@]} -1 )) ) ; do
  mencoder "${vob_file}" -vobsuboutindex 0 -o /dev/null -nosound -ovc frameno -vobsubout "${movie_title}.${sub_lang[$i]}" -sid ${sub_title[$i]}
done
)

# Determine the framerate
framerate=$(grep -E "\--vid" "${rip_directory}/metadata.txt" | fmt -w1 | grep fps | tr -d 'fps) ')

# Pick the audio track
grep --color=never -E "\--aid.*\--alang" "${rip_directory}/metadata.txt" | cut -d'=' -f2,3 | sed 's/ --alang=/. /'
read -rp 'Enter the number of the desired audio track. ' aid
audio_track=$(ffprobe "${vob_file}" |& grep -m${aid} Audio | tail -n1 | cut -d'#' -f2 | cut -d'[' -f1)

# Check if the video needs to be deinterlaced
while true ; do
  read -rp 'Does the video need to be deinterlaced? [y/N/(v)iew video] ' ynv
  case $ynv in
    y|Y) deinterlace='-deinterlace' && break ;;
    v|V) mpv "${vob_file}" ;;
    *) break ;;
  esac
done

# Determine the video cropping
top_left='0:0'
bottom_right='500:400'
while true ; do
  read -rp "Enter the coordinates (x:y) for the top-left corner of the video. [Current value: ${top_left}] " top_left
  mpv "${vob_file}" --vf=lavfi=[drawbox=${top_left}:${bottom_right}:invert:1]
  read -rp 'Are you sastified with the top-left corner? [y/N] ' yesno
  case $yesno in
    y|Y) break ;;
    *) ;;
  esac
done
while true ; do
  read -rp "Enter the coordinates (x:y) for the bottom_right corner of the video. [Current value: ${bottom_right}] " bottom_right
  mpv "${vob_file}" --vf=lavfi=[drawbox=${top_left}:${bottom_right}:invert:1]
  read -rp 'Are you sastified with the bottom_right corner? [y/N] ' yesno
  case $yesno in
    y|Y) break ;;
    *) ;;
  esac
done


# Select the CRF
# PTS
# preset
# animation?

# Encode the movie
ffmpeg \
  -threads 0 \
  -i "${vob_file}" \
  -map 0:0 \
  -r ${framerate} \
  ${deinterlace} \
  -vf crop=${top_left}:${bottom_right} \
  -map ${audio_track} \
  -acodec copy \
  






























