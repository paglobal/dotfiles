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
    realpath ~/.config
    fd . ~/Documents/committed/ ~/Documents/uncommitted/ ~/Documents/antigravity/ --max-depth 1 --type d --absolute-path
  } | fzf >"$SELECTED_DIR_T"
}
export -f PICK_PROJECT_DIR

run.term.sh PICK_PROJECT_DIR

selected_dir=$(rd_t "$SELECTED_DIR_T")

[ -z "$selected_dir" ] && exit 0

SELECTED_CMDS_T=$(mk_t)
export SELECTED_CMDS_T

GET_COMMANDS() {
  gum input --placeholder "cmd1:cmd2:cmd3" >"$SELECTED_CMDS_T"
}
export -f GET_COMMANDS

run.term.sh GET_COMMANDS

selected_cmds=$(rd_t "$SELECTED_CMDS_T")

[ -z "$selected_cmds" ] && exit 0

IFS=':' read -ra cmds <<<"$selected_cmds"
for cmd in "${cmds[@]}"; do
  trimmed_cmd=$(echo "$cmd" | xargs)
  [ -n "$trimmed_cmd" ] && nohup run.term.sh "cd '$selected_dir' && $trimmed_cmd ." &
done
