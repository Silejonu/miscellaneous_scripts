#!/usr/bin/bash

while true ; do
  target=$(ps -ef | tail -n +2 | shuf -n1)
  sudo kill "$(echo "${target}" | awk '{print $2}')"
  echo "$(echo "${target}" | awk '{print $8}') has been shot dead."
  read -rp 'Dare to pull the trigger one more time? [Y/n] ' yesno
  if [[ -n ${yesno} ]] && [[ ${yesno} != [yY] ]] ; then
    echo "A bit of a coward, I see…"
    exit 0
  fi
done
