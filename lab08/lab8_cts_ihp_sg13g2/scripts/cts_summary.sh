#!/usr/bin/env bash
set -euo pipefail

RUN_DIR="${1:-}"
if [[ -z "$RUN_DIR" ]]; then
    RUN_DIR="$(scripts/find_latest_run.sh)"
fi

if [[ ! -d "$RUN_DIR" ]]; then
    echo "ERROR: run directory not found: $RUN_DIR" >&2
    exit 1
fi

echo "============================================================"
echo "Lab 8 CTS summary — IHP SG13G2"
echo "Run directory: $RUN_DIR"
echo "============================================================"

section() {
    local title="$1"
    local regex="$2"
    echo
    echo "[$title]"
    grep -RniE \
        --include='*.log' --include='*.rpt' --include='*.txt' \
        "$regex" "$RUN_DIR" 2>/dev/null | head -80 || true
}

section "CTS statistics" \
    'clock roots|buffers inserted|clock subnets|number of sinks|clock sinks|report_cts'

section "Clock cells selected by the PDK" \
    'sg13g2_clkbuf|clkbuf|root buffer|clock buffer'

section "Clock skew and latency" \
    'clock skew|skew|clock latency|insertion delay|arrival time'

section "Setup timing" \
    'setup violation|setup slack|worst negative slack|wns|tns'

section "Hold timing" \
    'hold violation|hold slack|min slack'

section "Electrical checks" \
    'max transition|slew violation|max capacitance|capacitance violation|max fanout'

section "Physical warnings" \
    'warning|error|failed|unplaced|illegal|congestion|CTS-0127'

echo
echo "[CTS-related artifacts]"
find "$RUN_DIR" -type f \
    \( -iname '*cts*' \
       -o -iname '*clock*' \
       -o -iname '*timing*' \
       -o -iname '*metrics*.json' \) \
    | sort | head -150
