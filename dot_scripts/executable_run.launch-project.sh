#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

. lib.tmp-provider.sh

SELECTED_DIR_T=$(mk_t)
export SELECTED_DIR_T

PICK_PROJECT_DIR() {
  {
    realpath ~/.assets
    realpath ~/.gemini
    realpath ~/.scripts
    fd . ~/Documents/committed/ ~/Documents/uncommitted/ --max-depth 1 --type d --absolute-path
  } | fzf >"$SELECTED_DIR_T"
}
export -f PICK_PROJECT_DIR

run.term.sh PICK_PROJECT_DIR

selected_dir=$(rd_t "$SELECTED_DIR_T")

[ -z "$selected_dir" ] && exit 0

SELECTED_EDITOR_T=$(mk_t)
export SELECTED_EDITOR_T

export CODE="code"
export ZEDITOR="zeditor"
export NVIM="nvim"

PICK_EDITOR() {
  printf "%s\n%s\n%s\n" "$CODE" "$ZEDITOR" "$NVIM" | fzf >"$SELECTED_EDITOR_T"
}
export -f PICK_EDITOR

run.term.sh PICK_EDITOR

selected_editor=$(rd_t "$SELECTED_EDITOR_T")

editor_command="cd '$selected_dir' && '$selected_editor' ."

nohup run.term.sh "$editor_command" &
