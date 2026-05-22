#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

. lib.tmp-provider.sh

SELECTED_DIR_T=$(mk_t)
export SELECTED_DIR_T

PICK_PROJECT_DIR() {
  {
    realpath ~/.scripts
    fd . ~/Documents/committed/ ~/Documents/uncommitted/ --max-depth 1 --type d --absolute-path
  } | fzf >"$SELECTED_DIR_T"
}
export -f PICK_PROJECT_DIR

run.term.sh PICK_PROJECT_DIR

selected_dir=$(rd_t "$SELECTED_DIR_T")

[ -z "$selected_dir" ] && exit 0

SELECTED_MODE_T=$(mk_t)
export SELECTED_MODE_T

export CODE_EDITOR="code-editor"
export AGENT="agent"
export BOTH="both"

PICK_MODE() {
  printf "%s\n%s\n%s\n" "$BOTH" "$CODE_EDITOR" "$AGENT" | fzf >"$SELECTED_MODE_T"
}
export -f PICK_MODE

run.term.sh PICK_MODE

selected_mode=$(rd_t "$SELECTED_MODE_T")

editor_command="cd '$selected_dir' && code ."
agent_command="cd '$selected_dir' && gemini"

case "$selected_mode" in
"$CODE_EDITOR")
  nohup run.term.sh "$editor_command" &
  ;;
"$AGENT")
  nohup run.term.sh "$agent_command" &
  ;;
"$BOTH")
  nohup run.term.sh "$editor_command" &
  nohup run.term.sh "$agent_command" &
  ;;
*)
  echo "Unexpected selection"
  exit 1
  ;;
esac
