export TMP_PREFIX="/tmp/universal_tmp_run_prefix_007_1234_$$_${RANDOM}_"

trap 'rm -f "${TMP_PREFIX}"*' EXIT

mk_t() { mktemp "${TMP_PREFIX}XXXXXX"; }
rd_t() { [[ -f "$1" ]] && cat "$1"; }
