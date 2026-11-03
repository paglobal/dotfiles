#!/bin/bash
set -euo pipefail

shared_dir="$HOME/.agents"
pi_dir="$HOME/.pi/agent"
gemini_dir="$HOME/.gemini/config"
config_list="$HOME/.assets/txts/config-list.txt"

# Check every destination before moving existing files. Never replace existing data.
for destination in \
  "$shared_dir/skills" \
  "$shared_dir/AGENTS.md" \
  "$gemini_dir/skills" \
  "$gemini_dir/AGENTS.md"; do
  if [[ -e "$destination" || -L "$destination" ]]; then
    printf 'Destination already exists; resolve manually: %s\n' "$destination" >&2
    exit 1
  fi
done

if [[ ! -d "$pi_dir/skills" || -L "$pi_dir/skills" ||
      ! -f "$pi_dir/AGENTS.md" || -L "$pi_dir/AGENTS.md" ]]; then
  printf 'Expected regular Pi skills directory and AGENTS.md file. No changes made.\n' >&2
  exit 1
fi
if [[ ! -f "$config_list" || ! -w "$config_list" ]]; then
  printf 'Config list missing or not writable: %s\n' "$config_list" >&2
  exit 1
fi

mkdir -p "$shared_dir" "$gemini_dir"
mv -T "$pi_dir/skills" "$shared_dir/skills"
mv -T "$pi_dir/AGENTS.md" "$shared_dir/AGENTS.md"
ln -sT ../../.agents/skills "$pi_dir/skills"
ln -sT ../../.agents/AGENTS.md "$pi_dir/AGENTS.md"
ln -sT ../../.agents/skills "$gemini_dir/skills"
ln -sT ../../.agents/AGENTS.md "$gemini_dir/AGENTS.md"

# Config list stores literal ~ paths, not machine-specific absolute paths.
# shellcheck disable=SC2088
for entry in \
  '~/.agents' \
  '~/.pi/agent/skills' \
  '~/.pi/agent/AGENTS.md' \
  '~/.gemini/config/skills' \
  '~/.gemini/config/AGENTS.md'; do
  if ! grep -qxF "$entry" "$config_list"; then
    printf '\n%s\n' "$entry" >>"$config_list"
  fi
done

printf 'Migration complete. Run chezmoi sync separately to capture changes.\n'
