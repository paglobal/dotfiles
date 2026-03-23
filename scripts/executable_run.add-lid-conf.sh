#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Define the target directory and file
target_dir="/etc/systemd/logind.conf.d"
target_file="$target_dir/99-lid.conf"

echo "Setting up logind overrides..."

# 1. Create the directory if it doesn't exist
sudo mkdir -p "$target_dir"

# 2. Use tee to write the content directly
sudo tee "$target_file" >/dev/null <<EOM
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
EOM

echo "Done!"
