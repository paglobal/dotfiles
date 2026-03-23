#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

. lib.tmp-provider.sh

SELECTED_DIR_T=$(mk_t)
export SELECTED_DIR_T

PICK_PROJECT_DIR() {
  fd . ~/Documents/committed/ ~/Documents/uncommitted/ \
    --max-depth 1 \
    --type d \
    --absolute-path | fzf >"$SELECTED_DIR_T"
}
export -f PICK_PROJECT_DIR

run.term.sh PICK_PROJECT_DIR

selected_dir=$(rd_t "$SELECTED_DIR_T")

[ -z "$selected_dir" ] && exit 0

# Try refacting the strings below into functions
# Also remember `disown` exists for the future
nohup run.term.sh "cd \"$selected_dir\" && nvim ." &
nohup run.term.sh "cd \"$selected_dir\" && gemini" &
