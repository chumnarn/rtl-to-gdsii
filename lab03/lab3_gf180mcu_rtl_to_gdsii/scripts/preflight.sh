#!/usr/bin/env bash
set -euo pipefail

need() {
    if ! command -v "$1" >/dev/null 2>&1; then
        printf 'ERROR: required command not found: %s\n' "$1" >&2
        return 1
    fi
}

need python3
need librelane

python3 - <<'PY'
from pathlib import Path
import sys
try:
    import yaml
except ImportError:
    print("WARNING: PyYAML not installed; skipping YAML parser check")
else:
    with open("config.yaml", encoding="utf-8") as f:
        cfg = yaml.safe_load(f)
    required = ["DESIGN_NAME", "VERILOG_FILES", "CLOCK_PORT", "CLOCK_PERIOD"]
    missing = [key for key in required if key not in cfg]
    if missing:
        raise SystemExit(f"Missing config keys: {missing}")

for path in [
    "rtl/counter.sv",
    "constraints/pnr.sdc",
    "constraints/signoff.sdc",
    "pin_order.cfg",
]:
    if not Path(path).is_file():
        raise SystemExit(f"Missing file: {path}")
print("PASS: configuration files are present")
PY

printf 'LibreLane: '
librelane --version || true
printf 'PDK selected by Makefile: %s\n' "${PDK:-gf180mcuD}"
