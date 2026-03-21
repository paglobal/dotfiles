#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

yay -Qqe > ~/assets/txts/pkglist.txt

success_message="Done! Run 'chezmoi cd' to inspect, and don't forget to commit your changes!"
config_list="$HOME/assets/txts/config-list.txt"

# Clean up any duplicate/redundant new lines
sed -i '/^$/d' "$config_list"

path="${1:-}"
# Process a single target if an argument is provided
if [[ -n "$path" ]]; then
    # Convert to absolute path before beginning 
    path=$(realpath -m "$path")
    # Removing all trailing slashes from path
    shopt -s extglob
    path="${path%%+(/)}"
    if [[ ! -e "$path" ]]; then
        echo "Error: '$path' does not exist."
        exit 1
    fi
    echo "Processing single target: $path"
    if ! chezmoi forget --force "$path"; then
        echo "Path doesn't seem to be managed"
    fi
    # Normalize path to use "~" instead of its expansion
    formatted_path="${path/#$HOME/\~}"
    if ! grep -qxF "$formatted_path" "$config_list"; then
       echo "Adding path to config list..."
       # Add new line before the adding the path to ensure config list doesn't break
       printf "\n%s" "$formatted_path" >> "$config_list"
       # Clean up any duplicate/redundant new lines
       sed -i '/^$/d' "$config_list"
    fi
    chezmoi add "$path"
    echo "$success_message"
    exit 0
fi

[[ ! -f "$config_list" ]] && echo "File $config_list not found" && exit 1

chezmoi managed -p absolute | xargs -d '\n' chezmoi forget --force

while read -r entry || [[ -n "$entry" ]]; do
  [[ -z "$entry" ]] && continue
  echo "Processing: $entry"
  chezmoi add "$entry"
done < "$config_list"

echo "$success_message"
