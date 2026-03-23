#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

niri msg action spawn -- kitty bash -ic "$@"
