#!/usr/bin/bash
sudo mount -t proc /proc /mnt/proc
sudo mount -o bind /sys /mnt/sys
sudo mount -o bind /dev /mnt/dev
