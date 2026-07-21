#!/usr/bin/env bash
set -u
cd "$(dirname "$0")/.."

RUN_ROOT="${1:-runs}"

echo "=== Latest run directories ==="
find "$RUN_ROOT" -maxdepth 2 -type d 2>/dev/null | tail -20 || true

echo
echo "=== I/O pad and pad-ring messages ==="
grep -RniE 'PadRing|PAD-|IOPad|bondpad|site.*not found|master.*not found|overlap' \
  "$RUN_ROOT" 2>/dev/null | tail -80 || true

echo
echo "=== Timing ==="
grep -RniE 'WNS|TNS|worst.*slack|setup.*violation|hold.*violation' \
  "$RUN_ROOT" 2>/dev/null | tail -60 || true

echo
echo "=== Routing and antenna ==="
grep -RniE 'GRT-|DRT-|antenna|routing.*violation|congestion' \
  "$RUN_ROOT" 2>/dev/null | tail -80 || true

echo
echo "=== DRC and LVS ==="
grep -RniE 'DRC|LVS|circuits match|mismatch' \
  "$RUN_ROOT" 2>/dev/null | tail -100 || true

echo
echo "=== Final GDS ==="
find "$RUN_ROOT" -type f \( -name '*.gds' -o -name '*.gdsii' \) \
  2>/dev/null | tail -20 || true
