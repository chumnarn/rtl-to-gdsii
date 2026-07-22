#!/usr/bin/env bash
set -euo pipefail

required=(python3 make)
optional=(librelane ciel iverilog vvp verilator yosys openroad klayout)

echo "Tool check"
echo "=========="

for tool in "${required[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        printf "[PASS] %-12s %s\n" "$tool" "$(command -v "$tool")"
    else
        printf "[FAIL] %-12s not found\n" "$tool"
        exit 1
    fi
done

for tool in "${optional[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        printf "[PASS] %-12s %s\n" "$tool" "$(command -v "$tool")"
    else
        printf "[WARN] %-12s not found\n" "$tool"
    fi
done

if command -v librelane >/dev/null 2>&1; then
    echo
    librelane --version || true
fi
