#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

exec kitty -e bash -ic "$@"
