#!/bin/bash

gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
gsettings set org.gnome.desktop.interface color-scheme '"prefer-dark"'
gsettings set org.gnome.desktop.interface font-name 'Ubuntu 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrainsMono NF 11'
git config --global user.email "jackamoah.pa@gmail.com"
git config --global user.name "paglobal"

chmod +x ~/scripts/*.sh
