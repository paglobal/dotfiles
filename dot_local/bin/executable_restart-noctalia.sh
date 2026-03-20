#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

killall qs && qs -c noctalia-shell
