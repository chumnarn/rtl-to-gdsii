#!/usr/bin/env bash
set -euo pipefail

required=(librelane verilator iverilog vvp yosys python3)
missing=0
for tool in "${required[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        printf '[OK]   %-12s %s\n' "$tool" "$(command -v "$tool")"
    else
        printf '[MISS] %-12s\n' "$tool"
        missing=1
    fi
done

[[ -f config.yaml ]] || { echo 'ERROR: config.yaml not found'; exit 1; }
[[ -f rtl/counter.sv ]] || { echo 'ERROR: RTL not found'; exit 1; }
[[ -f pin_order.cfg ]] || { echo 'ERROR: pin_order.cfg not found'; exit 1; }

if (( missing )); then
    echo 'ERROR: enter the LibreLane/Nix environment and retry.'
    exit 1
fi

echo 'Preflight checks passed.'
