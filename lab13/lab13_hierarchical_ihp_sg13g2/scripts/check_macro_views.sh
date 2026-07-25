#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
status=0
for macro in counter_macro accumulator_macro; do
  for view in "gds/${macro}.gds" "lef/${macro}.lef" "vh/${macro}.vh"; do
    f="$ROOT/macros/$macro/$view"
    if [[ -s "$f" ]]; then echo "[PASS] $f"; else echo "[FAIL] $f"; status=1; fi
  done
  for view in "nl/${macro}.nl.v" "spef/${macro}.spef"; do
    f="$ROOT/macros/$macro/$view"
    if [[ -s "$f" ]]; then echo "[PASS] optional STA view $f"; else echo "[WARN] optional STA view missing: $f"; fi
  done
done
exit "$status"
