#!/usr/bin/env bash
set -euo pipefail

printf 'Lab 11 IHP SG13G2 environment check\n'
printf '====================================\n'

required=(python3)
optional=(librelane ciel verilator iverilog vvp yosys jq klayout openroad)
for cmd in "${required[@]}"; do
    command -v "$cmd" >/dev/null 2>&1 || { echo "ERROR: missing $cmd" >&2; exit 1; }
    printf 'FOUND: %-12s %s\n' "$cmd" "$(command -v "$cmd")"
done
for cmd in "${optional[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        printf 'FOUND: %-12s %s\n' "$cmd" "$(command -v "$cmd")"
    else
        printf 'MISSING: %-10s (required only by related targets)\n' "$cmd"
    fi
done

printf '\nPDK=%s\n' "${PDK:-ihp-sg13g2}"
printf 'PDK_ROOT=%s\n' "${PDK_ROOT:-$(pwd)/IHP-Open-PDK}"
if command -v librelane >/dev/null 2>&1; then
    printf '\nLibreLane version:\n'
    librelane --version || true
fi
