#!/usr/bin/env python3
"""Perform local checks that do not require LibreLane."""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

required = [
    ROOT / "config.yaml",
    ROOT / "src/counter.sv",
    ROOT / "tb/tb_counter.sv",
    ROOT / "constraints/pnr.sdc",
    ROOT / "constraints/signoff.sdc",
    ROOT / "pin_order.cfg",
]

missing = [str(p.relative_to(ROOT)) for p in required if not p.is_file()]
if missing:
    print("ERROR: missing files:", ", ".join(missing), file=sys.stderr)
    raise SystemExit(1)

rtl = (ROOT / "src/counter.sv").read_text()
cfg = (ROOT / "config.yaml").read_text()
pins = (ROOT / "pin_order.cfg").read_text()

if not re.search(r"\bmodule\s+counter\b", rtl):
    print("ERROR: top module 'counter' was not found.", file=sys.stderr)
    raise SystemExit(1)

for token in [
    "DESIGN_NAME: counter",
    "RUN_MAGIC_DRC: true",
    "RUN_KLAYOUT_DRC: true",
    "RUN_LVS: true",
]:
    if token not in cfg:
        print(f"ERROR: config.yaml is missing: {token}", file=sys.stderr)
        raise SystemExit(1)

for pin in ["clk", "rst_n", "enable"] + [rf"count\[{i}\]" for i in range(8)]:
    if pin not in pins:
        print(f"ERROR: pin_order.cfg is missing: {pin}", file=sys.stderr)
        raise SystemExit(1)

print("PASS: project structure and key configuration entries are valid.")
