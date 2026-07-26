#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

make check-tools
make clean
make lint
make sim

if command -v yosys >/dev/null 2>&1; then
    make yosys
else
    echo "[SKIP] Yosys is not installed."
fi

echo
echo "Lab 2 completed successfully."
echo "Open the waveform with: make wave"
echo "Run physical implementation with: make librelane"
