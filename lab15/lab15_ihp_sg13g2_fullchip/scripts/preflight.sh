#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

command -v librelane >/dev/null || {
  echo "ERROR: librelane is not in PATH"
  exit 2
}

command -v verilator >/dev/null || {
  echo "ERROR: verilator is not in PATH"
  exit 2
}

python3 scripts/prepare.py

echo
echo "Running RTL lint..."
verilator \
  --lint-only \
  --Wall \
  --Wno-DECLFILENAME \
  --Wno-PINMISSING \
  --Wno-MODMISSING \
  --top-module chip_top \
  src/counter_core.sv \
  src/chip_top.sv

echo
echo "Checking config.yaml..."
grep -q '^PDK: ihp-sg13g2' config.yaml
grep -q '^  flow: Chip' config.yaml

echo
echo "Preflight passed."
