#!/usr/bin/bash
yt-dlp --sub-langs all,-live_chat --embed-subs --merge-output-format mkv --download-archive ./.archive -a ./list -o '%(title).240s.mkv' ./
