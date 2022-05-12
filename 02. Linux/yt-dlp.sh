#!/usr/bin/bash

yt-dlp \
  --sub-langs all,-live_chat \
  --embed-subs \
  --merge-output-format mkv \
  --download-archive ./.archive \
  --batch-file ./list \
  --output './%(title).240s.mkv'
