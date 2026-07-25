#!/usr/bin/env bash
set -euo pipefail

run_dir="${1:-}"
if [[ -z "$run_dir" || ! -d "$run_dir" ]]; then
    echo "Usage: $0 runs/<run-tag>" >&2
    exit 1
fi

echo "Run directory: $run_dir"
echo

echo "[Step directories]"
find "$run_dir" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | sort -V

echo
echo "[Last step directory]"
find "$run_dir" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | sort -V | tail -1 || true

echo
echo "[Global errors]"
find "$run_dir" -maxdepth 1 -type f -iname '*error*.log' -print -exec tail -n 80 {} \; || true

echo
echo "[Global warnings]"
find "$run_dir" -maxdepth 1 -type f -iname '*warning*.log' -print -exec tail -n 80 {} \; || true

echo
echo "[Final views]"
if [[ -d "$run_dir/final" ]]; then
    find "$run_dir/final" -maxdepth 2 -type f | sort
else
    echo "No final directory; the flow may have stopped early or failed."
fi

echo
echo "[Selected metrics]"
if [[ -f "$run_dir/final/metrics.csv" ]]; then
    grep -iE 'area|utilization|density|wns|tns|drc|lvs|antenna|wire|via|power|clock|skew' \
        "$run_dir/final/metrics.csv" || true
else
    echo "metrics.csv not found."
fi
