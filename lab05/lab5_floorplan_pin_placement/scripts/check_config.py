#!/usr/bin/env python3
"""Perform lightweight checks on the Lab 5 YAML configuration."""

from __future__ import annotations

import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("SKIP: PyYAML is not installed; LibreLane will validate YAML at runtime.")
    raise SystemExit(0)

path = Path("config.yaml")
data = yaml.safe_load(path.read_text(encoding="utf-8"))

required = {
    "DESIGN_NAME",
    "VERILOG_FILES",
    "CLOCK_PORT",
    "CLOCK_PERIOD",
    "FP_SIZING",
    "DIE_AREA",
    "CORE_AREA",
    "IO_PIN_ORDER_CFG",
    "PNR_SDC_FILE",
    "SIGNOFF_SDC_FILE",
}

missing = sorted(required - set(data))
if missing:
    print(f"ERROR: missing required keys: {', '.join(missing)}", file=sys.stderr)
    raise SystemExit(1)

if data["FP_SIZING"] != "absolute":
    print("ERROR: this lab requires FP_SIZING: absolute", file=sys.stderr)
    raise SystemExit(1)

die = data["DIE_AREA"]
core = data["CORE_AREA"]

if not (
    die[0] <= core[0] < core[2] <= die[2]
    and die[1] <= core[1] < core[3] <= die[3]
):
    print("ERROR: CORE_AREA must lie inside DIE_AREA", file=sys.stderr)
    raise SystemExit(1)

print("PASS: config.yaml passed lightweight structural checks.")
