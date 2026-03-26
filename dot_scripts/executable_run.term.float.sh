#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

exec kitty -e --class "float-term" bash -ic "$@"
