#!/usr/bin/env bash
set -euo pipefail

run_dir="${1:-}"
if [[ -z "$run_dir" || ! -d "$run_dir" ]]; then
    echo "Usage: $0 runs/<run-tag>" >&2
    exit 1
fi

pattern='ERROR|FATAL|failed|unmapped|overflow|unrouted|short|violation|congestion|not found'

find "$run_dir" -type f \
    \( -name '*.log' -o -name '*.rpt' -o -name '*.txt' \) -print0 \
    | xargs -0 -r grep -niE "$pattern" \
    || true
