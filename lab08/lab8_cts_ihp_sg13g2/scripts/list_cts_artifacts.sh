#!/usr/bin/env bash
set -euo pipefail

RUN_DIR="${1:-}"
if [[ -z "$RUN_DIR" ]]; then
    RUN_DIR="$(scripts/find_latest_run.sh)"
fi

find "$RUN_DIR" -type f \
    \( -iname '*cts*.odb' \
       -o -iname '*cts*.def' \
       -o -iname '*cts*.log' \
       -o -iname '*cts*.rpt' \
       -o -iname '*timing*.rpt' \
       -o -iname '*metrics*.json' \) \
    | sort
