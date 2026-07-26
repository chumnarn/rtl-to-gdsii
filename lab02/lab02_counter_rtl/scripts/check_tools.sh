#!/usr/bin/env bash
set -euo pipefail

required=(make verilator)
optional=(yosys gtkwave librelane)

echo "Required tools"
for tool in "${required[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        printf "  [OK]      %-12s %s\n" "$tool" "$(command -v "$tool")"
    else
        printf "  [MISSING] %-12s\n" "$tool"
        exit 1
    fi
done

echo
echo "Optional tools"
for tool in "${optional[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        printf "  [OK]      %-12s %s\n" "$tool" "$(command -v "$tool")"
    else
        printf "  [MISSING] %-12s (needed only for its related target)\n" "$tool"
    fi
done
