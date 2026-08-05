#!/usr/bin/env bash
set -euo pipefail

runs_dir="${1:-runs}"
[[ -d "$runs_dir" ]] || { echo "ERROR: $runs_dir does not exist" >&2; exit 1; }

latest_run=$(find "$runs_dir" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' \
    | sort -n | tail -1 | cut -d' ' -f2-)
[[ -n "$latest_run" ]] || { echo "ERROR: no LibreLane run found" >&2; exit 1; }

mkdir -p artifacts
name=$(basename "$latest_run")
out="artifacts/${name}-routing-reports.tar.gz"

tar -czf "$out" \
    --ignore-failed-read \
    "$latest_run"/*metrics*.json \
    "$latest_run"/*metrics*.csv \
    $(find "$latest_run" -type f \
      \( -iname '*route*.rpt' -o -iname '*routing*.rpt' -o -iname '*drc*.rpt' \
         -o -iname '*antenna*.rpt' -o -iname '*route*.log' -o -iname '*routing*.log' \))

echo "Created: $out"
