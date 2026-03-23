#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

systemd-run --user kitty -e bash -ic "$@"
