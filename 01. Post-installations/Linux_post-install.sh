#!/usr/bin/bash
cd $(mktemp -d) &&
wget https://github.com/Silejonu/Linux-desktop-post-install/archive/refs/heads/main.zip &&
unzip main.zip -d ~ &&
cd ~/Linux-desktop-post-install-main &&
chmod +x ./linux_desktop_post-install.sh &&
./linux_desktop_post-install.sh
