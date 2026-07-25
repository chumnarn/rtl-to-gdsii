#!/usr/bin/env bash
set -euo pipefail

required=(python3)
optional=(librelane verilator iverilog yosys jq)

printf 'Environment check\n'
printf '=================\n'

for cmd in "${required[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf 'ERROR: required command not found: %s\n' "$cmd" >&2
        exit 1
    fi
    printf 'FOUND: %-12s %s\n' "$cmd" "$(command -v "$cmd")"
done

for cmd in "${optional[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        printf 'FOUND: %-12s %s\n' "$cmd" "$(command -v "$cmd")"
    else
        printf 'MISSING: %-10s (needed only for the related target)\n' "$cmd"
    fi
done

if command -v librelane >/dev/null 2>&1; then
    printf '\nLibreLane version:\n'
    librelane --version || true
fi

printf '\nPDK_ROOT=%s\n' "${PDK_ROOT:-$HOME/.ciel}"
