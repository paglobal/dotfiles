#!/bin/bash

DIR=$(fd . ~/Documents/committed/ ~/Documents/uncommitted/ --max-depth 1 --type d --absolute-path | ~/scripts/sd-term.sh fzf)

[ -z "$DIR" ] && exit 0

~/scripts/term.sh "cd '$DIR' && nvim ."
~/scripts/term.sh "cd '$DIR' && gemini"
