#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

exec kitty -e bash -ic "$@"

# Remember we used to have this, in case we need it in the future
# We ended up not needing it because of `nohup`, `&` and `disown`
# systemd-run --user kitty -e bash -ic "$@"
#
# Keep this in mind too!
# systemd-run --user --scope kitty -e bash -ic "$@"
