#!/usr/bin/env bash
set -euo pipefail

pdk="${PDK:-ihp-sg13g2}"
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

echo "PASS: all required project files exist."

python3 - <<'PY'
from pathlib import Path
try:
    import yaml
except ImportError:
    print("INFO: PyYAML unavailable; skipped standalone YAML parsing.")
else:
    with Path("config.yaml").open(encoding="utf-8") as stream:
        cfg = yaml.safe_load(stream)
    assert cfg["DESIGN_NAME"] == "routing_demo"
    assert cfg["meta"]["flow"] == "Classic"
    assert cfg["RT_MIN_LAYER"] == "Metal2"
    assert cfg["RT_MAX_LAYER"] == "TopMetal2"
    print("PASS: config.yaml parsed; IHP routing layer names are correct.")
PY

status=0
for tool in librelane verilator python3; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "PASS: $tool -> $(command -v "$tool")"
    else
        echo "WARN: $tool is not available in the current shell."
        [[ "$tool" == python3 ]] && status=1
    fi
done

if command -v librelane >/dev/null 2>&1; then
    librelane --version || true
    echo "INFO: target PDK is '$pdk'. Run 'make validate' to verify that its installed revision is visible."
else
    echo "INFO: enter the LibreLane Nix/Docker shell before running PnR."
fi

exit "$status"
