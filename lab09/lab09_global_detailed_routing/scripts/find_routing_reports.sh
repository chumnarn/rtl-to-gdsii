#!/usr/bin/env bash
set -euo pipefail

runs_dir="${1:-runs}"
[[ -d "$runs_dir" ]] || { echo "ERROR: $runs_dir does not exist" >&2; exit 1; }

latest_run=$(find "$runs_dir" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' \
    | sort -n | tail -1 | cut -d' ' -f2-)
[[ -n "$latest_run" ]] || { echo "ERROR: no LibreLane run found" >&2; exit 1; }

echo "Latest run: $latest_run"
echo "Routing step directories:"
find "$latest_run" -type d \
    \( -iname '*globalrouting*' -o -iname '*detailedrouting*' -o -iname '*antenna*' \) \
    | sort

echo
echo "Routing reports and logs:"
find "$latest_run" -type f \
    \( -iname '*route*.rpt' -o -iname '*routing*.rpt' -o -iname '*drc*.rpt' \
       -o -iname '*antenna*.rpt' -o -iname '*route*.log' -o -iname '*routing*.log' \) \
    | sort
