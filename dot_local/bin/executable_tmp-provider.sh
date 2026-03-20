#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

export TMP_PREFIX="/tmp/universal_tmp_run_prefix_007_1234_$$_"

trap 'rm -f "${TMP_PREFIX}"*' EXIT

mk_t() { mktemp "${TMP_PREFIX}XXXXXX"; }
rd_t() { [[ -f "$1" ]] && cat "$1"; }

export -f mk_t rd_t

# Run the child script with safe-guards
bash -euo pipefail "$@"
