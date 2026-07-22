#!/usr/bin/env bash
set -euo pipefail

PDK_ROOT="${PDK_ROOT:-$PWD/IHP-Open-PDK}"
PDK="${PDK:-ihp-sg13g2}"
PDK_DIR="$PDK_ROOT/$PDK"

if [[ ! -d "$PDK_DIR" ]]; then
    echo "ERROR: PDK not installed at $PDK_DIR" >&2
    echo "Run: make pdk" >&2
    exit 1
fi

echo "Clock-buffer-related cells found under:"
echo "  $PDK_DIR"
echo

grep -RhoE \
    --include='*.lib' --include='*.lef' --include='*.v' \
    'sg13g2_clkbuf_[A-Za-z0-9_]+' \
    "$PDK_DIR" 2>/dev/null \
    | sort -u || true
