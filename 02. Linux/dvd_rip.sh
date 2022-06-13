#!/usr/bin/bash

for cmd in mpv dvdxchap ffmpeg ffprobe mencoder awk ; do
  command -v ${cmd} > /dev/null
  if [[ $? -ne 0 ]] ; then
    echo "Command '${cmd}' is missing, please install it and rerun the script."
    exit 1
  fi
done

read -rp 'Movie title? ' movie_title
rip_directory="$(xdg-user-dir VIDEOS)/rips/${movie_title}"
vob_file="${rip_directory}/${movie_title}.vob"
chapter_file="${rip_directory}/chapters.txt"
mkdir -p "${rip_directory}"

# Skip if the .vob file already exists
if [[ -f ${vob_file} ]] ; then
  echo 'The DVD seems to have already been copied to the local disk.'
  read -rp 'Do you want to skip directly to video encoding? [Y/n] ' yesno
  case $yesno in
    [nN]|[nN][oO]) skip_dump='no' ;;
    *) skip_dump='yes';;
  esac
fi

if [[ $skip_dump == 'no' ]] ; then
  # Extract metadata
  mpv dvd://longest -frames 0 > "${rip_directory}/metadata.txt"

  # Dump the movie to a .vob file
  mpv dvd://longest --stream-dump="${vob_file}"

  # Dump chapters
  title_number=$(grep '\[dvdnav\] Selecting title' "${rip_directory}/metadata.txt" | cut -d' ' -f4 | tr -d '.')
  dvdxchap --title $(( $title_number + 1 )) /dev/sr0 > "${chapter_file}"
  # Convert chapters into a format readable by FFmpeg
  for chapter in $(seq -f '%02g' $(cat "${chapter_file}" | sort -r | head -n1 | cut -d' ' -f2)) ; do
    timestamp="$(grep "CHAPTER${chapter}=" "${chapter_file}" | cut -d'=' -f2)"
    timestamp_ffmpeg=$(echo "${timestamp}" | awk -F[:.] '{ print ($1 * 3600000) + ($2 * 60000) + ($3 * 1000) + $4 }')
    sed -i "s#${timestamp}#${timestamp_ffmpeg}#" "${chapter_file}"
    sed -i "s#CHAPTER${chapter}=#\n[CHAPTER]\nTIMEBASE=1/1000\nSTART=#" "${chapter_file}"
    sed -i "s#CHAPTER${chapter}NAME#END=\nTITLE#" "${chapter_file}"
  done
  
  # Add remaining metadata
  sed -i "1 s#^#;FFMETADATA1\nTITLE=${movie_title}#" "${chapter_file}"

  eject /dev/sr0

  # Store subtitles stream IDs
  sub_id=($(grep -E "\--sid.*\--slang" "${rip_directory}/metadata.txt" | cut -d'=' -f2 | cut -d' ' -f1))
  # Store subtitles languages
  sub_lang=($(grep -E "\--sid.*\--slang" "${rip_directory}/metadata.txt" | cut -d'=' -f3 | cut -d' ' -f1))
  # Dump subtitles
  (
  cd "${rip_directory}"
  # Iterate through all subtitle streams
  for i in $(seq 0 $(( ${#sub_id[@]} -1 )) ) ; do
    mencoder "${vob_file}" \
      -vobsuboutindex 0 \
      -o /dev/null \
      -nosound \
      -ovc frameno \
      -vobsuboutid ${sub_lang[$i]} \
      -sid $(( sub_id[$i] - 1 )) \
      -vobsubout "${movie_title} ${sub_lang[$i]}${sub_id[$i]}"
  done
  )
fi

# Pick the audio track
echo
grep --color=never -E "\--aid.*\--alang" "${rip_directory}/metadata.txt" | cut -d'=' -f2,3 | sed 's/ --alang=/. /'
#ffprobe "${vob_file}" |& grep Audio | cut -d':' -f4 | cat -n
read -rp 'Enter the number of the desired audio track: ' aid
audio_track=$(ffprobe "${vob_file}" |& grep -m${aid} Audio | tail -n1 | cut -d'#' -f2 | cut -d'[' -f1)

# Find the video start delay
video_start_delay=$(ffprobe -select_streams v:0 -show_streams -i "${vob_file}" |& grep start_time | cut -d'=' -f2)
# Find the audio start delay
audio_start_delay=$(ffprobe -select_streams a:${aid} -show_streams -i "${vob_file}" |& grep start_time | cut -d'=' -f2)
offset=$(awk "BEGIN { print ${video_start_delay} - ${audio_start_delay} }")

# Determine the video cropping
top_left='0:0'
bottom_right='700:475'
echo "Recommended initial test value: ${top_left}"
while true ; do
  read -rp "Enter the coordinates (x:y) for the top-left corner of the video. [Last value: ${top_left}] " top_left
  mpv "${vob_file}" --vf=lavfi=[drawbox=${top_left}:${bottom_right}:invert:1]
  read -rp 'Are you sastified with the top-left corner? [y/N] ' yesno
  case $yesno in
    [yY]|[yY][eE][sS]) echo "Top-left: ${top_left}" > "${rip_directory}/cropping_values.txt" && break ;;
    *) ;;
  esac
done
echo "Recommended initial test value: ${bottom_right}"
while true ; do
  read -rp "Enter the coordinates (x:y) for the bottom-right corner of the video. [Last value: ${bottom_right}] " bottom_right
  mpv "${vob_file}" --vf=lavfi=[drawbox=${top_left}:${bottom_right}:invert:1]
  read -rp 'Are you sastified with the bottom_right corner? [y/N] ' yesno
  case $yesno in
    [yY]|[yY][eE][sS]) echo "Bottom-right: ${bottom_right}" >> "${rip_directory}/cropping_values.txt" && break ;;
    *) ;;
  esac
done

# Apply tuning
echo '[Optional] Use tuning:'
echo '1. film – use for high quality movie content; lowers deblocking'
echo '2. animation – good for cartoons; uses higher deblocking and more reference frames'
echo '3. grain – preserves the grain structure in old, grainy film material'
echo '4. stillimage – good for slideshow-like content'
echo '5. fastdecode – allows faster decoding by disabling certain filters'
echo '6. zerolatency – good for fast encoding and low-latency streaming'
read -rp 'Enter the desired tuning [1/2/3/4/5/6/(S)kip] ' tune
case $tune in
  1|film) tune='-tune film' ;;
  2|animation) tune='-tune animation' ;;
  3|grain) tune='-tune grain' ;;
  4|stillimage) tune='-tune stillimage' ;;
  5|fastdecode) tune='-tune fastdecode' ;;
  6|zerolatency) tune='-tune zerolatency' ;;
  *) ;;
esac

# Check if the video needs to be deinterlaced
while true ; do
  read -rp 'Does the video need to be deinterlaced? [y/N/(v)iew video] ' ynv
  case $ynv in
    [yY]) deinterlace='-vf yadif=1' && break ;;
    [vV]) mpv "${vob_file}" ;;
    *) break ;;
  esac
done

# Select the CRF
read -rp 'Do you want to get a preview of a few CRF values? [Y/n] ' yesno
case $yesno in
  [nN]|[nN][oO]) ;;
  *) crf_test=yes ;;
esac
if [[ $crf_test == 'yes' ]] ; then
  read -rp 'Pick the start time (in seconds) of the CRF test. [default 120] ' start_time
  if [[ -z $start_time ]] ; then
    start_time=120
  fi
  for test_crf in {15..25} ; do
    ffmpeg \
      -y \
      -threads 0 \
      -i "${vob_file}" \
      -map 0:v \
      -vf crop=${bottom_right}:${top_left} \
      -vcodec libx264 \
      ${tune} \
      ${deinterlace} \
      -preset ultrafast \
      -crf ${test_crf} \
      -ss ${start_time} -t 60 \
      "${rip_directory}/${movie_title}_crf${test_crf}.mkv"
  done
  
  echo "All CRF test files have been generated in ${rip_directory}"
  mpv "${rip_directory}/${movie_title}_crf*.mkv"

fi

read -rp 'Enter the desired CRF value (the highest number with an acceptable quality) for the final rip: ' crf

# Rappel commande

# Encode the movie
ffmpeg \
  -threads 0 \
  -i "${vob_file}" \
  -i "${chapter_file}" \
  -itsoffset ${offset} \
  -i "${vob_file}" \
  -map 2:v \
  -vf crop=${bottom_right}:${top_left} \
  -vcodec libx264 \
  ${tune} \
  ${deinterlace} \
  -preset veryslow \
  -map ${audio_track} \
  -crf ${crf} \
  -acodec copy \
  -map_metadata 1 \
  "${rip_directory}/${movie_title}.mkv"

echo
echo 'Encoding finished.'
echo

read -rp 'Clean up the source files? [Y/n] ' yesno
case $yesno in
  [nN]|[nN][oO]) ;;
  *) rm "${rip_directory}/${movie_title}"_crf*.mkv
     rm "${rip_directory}/${movie_title}.vob"
     rm "${rip_directory}/chapters.txt"
     rm "${rip_directory}/cropping_values.txt"
     rm "${rip_directory}/metadata.txt"
     ;;
esac
