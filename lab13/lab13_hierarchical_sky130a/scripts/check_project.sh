#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

required=(
  rtl/counter_macro.sv rtl/accumulator_macro.sv rtl/hier_system.sv
  blocks/counter_macro/config.yaml blocks/accumulator_macro/config.yaml
  top/config.yaml top/constraints.sdc
  macros/counter_macro/vh/counter_macro.vh
  macros/accumulator_macro/vh/accumulator_macro.vh
)
for f in "${required[@]}"; do
  [[ -s "$f" ]] || { echo "[FAIL] missing $f"; exit 1; }
  echo "[PASS] $f"
done

python3 - <<'PY'
from pathlib import Path
try:
    import yaml
except ImportError:
    print('[WARN] PyYAML is unavailable; skipping YAML parser check')
else:
    for p in [Path('blocks/counter_macro/config.yaml'), Path('blocks/accumulator_macro/config.yaml'), Path('top/config.yaml'), Path('top/config_hier_sta.yaml')]:
        with p.open(encoding='utf-8') as f:
            yaml.safe_load(f)
        print(f'[PASS] YAML: {p}')
PY
