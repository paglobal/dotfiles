#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si && rm -rf yay
