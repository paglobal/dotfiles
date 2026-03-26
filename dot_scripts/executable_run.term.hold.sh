#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

exec kitty --hold -e bash -ic "$@"
