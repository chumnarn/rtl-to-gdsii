#!/usr/bin/env python3
from pathlib import Path
import sys
import yaml

required = [
    Path("config.yaml"),
    Path("src/synth_sta_top.sv"),
    Path("tb/tb_synth_sta_top.sv"),
    Path("constraints/synth_sta_top.sdc"),
]
missing = [str(p) for p in required if not p.is_file()]
if missing:
    print("ERROR: missing files:", *missing, sep="\n  ")
    sys.exit(1)

with Path("config.yaml").open(encoding="utf-8") as f:
    cfg = yaml.safe_load(f)

for key in ("DESIGN_NAME", "VERILOG_FILES", "CLOCK_PORT", "CLOCK_PERIOD"):
    if key not in cfg:
        print(f"ERROR: missing config key {key}")
        sys.exit(1)

if cfg["DESIGN_NAME"] != "synth_sta_top":
    print("ERROR: DESIGN_NAME must be synth_sta_top")
    sys.exit(1)

print("PASS: project structure and config.yaml are valid")
