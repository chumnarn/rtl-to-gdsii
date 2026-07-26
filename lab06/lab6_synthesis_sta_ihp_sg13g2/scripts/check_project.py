#!/usr/bin/env python3
from pathlib import Path
import sys

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML is not installed. Run: python3 -m pip install pyyaml")
    sys.exit(2)

root = Path(__file__).resolve().parents[1]
required = [
    root / "config.yaml",
    root / "src/synth_sta_top.sv",
    root / "tb/tb_synth_sta_top.sv",
    root / "constraints/synth_sta_top.sdc",
]

missing = [str(p.relative_to(root)) for p in required if not p.is_file()]
if missing:
    print("ERROR: Missing files:")
    for item in missing:
        print(f"  - {item}")
    sys.exit(1)

with (root / "config.yaml").open(encoding="utf-8") as f:
    cfg = yaml.safe_load(f)

expected = {
    "PDK": "ihp-sg13g2",
    "DESIGN_NAME": "synth_sta_top",
    "CLOCK_PORT": "clk_i",
}

errors = []
for key, value in expected.items():
    if cfg.get(key) != value:
        errors.append(f"{key}: expected {value!r}, found {cfg.get(key)!r}")

if float(cfg.get("CLOCK_PERIOD", -1)) <= 0:
    errors.append("CLOCK_PERIOD must be positive")

rtl_entries = cfg.get("VERILOG_FILES", [])
if "dir::src/synth_sta_top.sv" not in rtl_entries:
    errors.append("VERILOG_FILES does not include dir::src/synth_sta_top.sv")

for key in ("PNR_SDC_FILE", "SIGNOFF_SDC_FILE"):
    if cfg.get(key) != "dir::constraints/synth_sta_top.sdc":
        errors.append(f"{key} does not point to the Lab SDC")

if errors:
    print("ERROR: Configuration checks failed:")
    for err in errors:
        print(f"  - {err}")
    sys.exit(1)

print("PASS: project structure and config.yaml are valid")
print(f"  PDK          : {cfg['PDK']}")
print(f"  Design       : {cfg['DESIGN_NAME']}")
print(f"  Clock port   : {cfg['CLOCK_PORT']}")
print(f"  Clock period : {cfg['CLOCK_PERIOD']} ns")
