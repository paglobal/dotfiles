#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

yay -S --needed - < ~/assets/txts/pkglist.txt
