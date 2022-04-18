#!/usr/bin/bash

while true ; do
  target=$(ps -ef | tail -n +2 | shuf | head -n1)
  sudo kill $(echo "${target}" | awk '{print $2}')
  echo "$(echo "${target}" | awk '{print $8}') has been shot dead."
  read -p 'Dare to pull the trigger one more time? [Y/n] ' yesno
  if [[ ! -z ${yesno} ]] && [[ ${yesno} != [yY] ]] ; then
    echo "Not too courageous, I see…"
    exit 0
  fi
done
