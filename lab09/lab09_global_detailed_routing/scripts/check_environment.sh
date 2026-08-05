#!/usr/bin/env bash
set -euo pipefail

required_files=(
  config.yaml
  src/routing_demo.sv
  tb/tb_routing_demo.sv
  constraints/pnr.sdc
  constraints/signoff.sdc
)

for file in "${required_files[@]}"; do
    [[ -f "$file" ]] || { echo "ERROR: missing $file" >&2; exit 1; }
done

python3 - <<'PY'
from pathlib import Path
try:
    import yaml
except ImportError:
    print("INFO: PyYAML is unavailable; skipped YAML parser check.")
else:
    with Path("config.yaml").open(encoding="utf-8") as f:
        cfg = yaml.safe_load(f)
    assert cfg["DESIGN_NAME"] == "routing_demo"
    assert cfg["meta"]["flow"] == "Classic"
    print("PASS: config.yaml parsed successfully.")
PY

for tool in librelane verilator; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "PASS: $tool found: $(command -v "$tool")"
    else
        echo "WARN: $tool is not available in the current shell."
    fi
done

if command -v librelane >/dev/null 2>&1; then
    librelane --version || true
fi

echo "PASS: Lab 9 project structure is complete."
