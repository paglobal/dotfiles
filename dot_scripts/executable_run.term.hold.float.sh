#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

exec kitty -e --hold --class "float-term" bash -ic "$@"
