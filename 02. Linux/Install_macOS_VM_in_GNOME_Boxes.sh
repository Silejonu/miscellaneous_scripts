#!/usr/bin/bash

git clone --depth 1 --recursive https://github.com/kholia/OSX-KVM.git

cd OSX-KVM
./fetch-macOS-v2.py

qemu-img convert BaseSystem.dmg -O raw BaseSystem.img
qemu-img create -f qcow2 mac_hdd_ng.img 128G

mkdir -p ~/.local/share/gnome-boxes/OSX-KVM/OpenCore
cp BaseSystem.img ~/.local/share/gnome-boxes/OSX-KVM
cp mac_hdd_ng.img ~/.local/share/gnome-boxes/OSX-KVM
cp OVMF_CODE.fd ~/.local/share/gnome-boxes/OSX-KVM
cp OVMF_VARS-1024x768.fd ~/.local/share/gnome-boxes/OSX-KVM
cp OpenCore/OpenCore.qcow2 ~/.local/share/gnome-boxes/OSX-KVM/OpenCore

cp macOS-libvirt-Catalina.xml ~/.config/libvirt/qemu/macOS.xml
sed -i "s#/CHANGEME/#/${USER}/.local/share/gnome-boxes/#" ~/.config/libvirt/qemu/macOS.xml
sed -i 's/type="bridge"/type="user"/' ~/.config/libvirt/qemu/macOS.xml
sed -i '/bridge="virbr0"/d' ~/.config/libvirt/qemu/macOS.xml
