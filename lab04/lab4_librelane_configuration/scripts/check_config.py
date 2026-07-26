#!/usr/bin/env python3
"""Lightweight pre-flight checks for Lab 4 config.yaml."""

from __future__ import annotations

import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError as exc:
    print("ERROR: PyYAML is required for this checker: python3 -m pip install pyyaml", file=sys.stderr)
    raise SystemExit(2) from exc

ROOT = Path(__file__).resolve().parents[1]
CONFIG_PATH = ROOT / "config.yaml"


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def resolve_dir_path(value: str) -> Path:
    if not value.startswith("dir::"):
        fail(f"Expected a dir:: path, got {value!r}")
    return ROOT / value.removeprefix("dir::")


def main() -> int:
    with CONFIG_PATH.open("r", encoding="utf-8") as stream:
        cfg = yaml.safe_load(stream)

    if not isinstance(cfg, dict):
        fail("config.yaml must contain a YAML mapping")

    required = ["DESIGN_NAME", "VERILOG_FILES", "CLOCK_PORT", "CLOCK_PERIOD"]
    missing = [name for name in required if name not in cfg]
    if missing:
        fail("Missing required variable(s): " + ", ".join(missing))

    if cfg["DESIGN_NAME"] != "lab4_counter":
        fail("DESIGN_NAME must be lab4_counter for the supplied RTL")

    period = cfg["CLOCK_PERIOD"]
    if not isinstance(period, (int, float)) or period <= 0:
        fail("CLOCK_PERIOD must be a positive number")

    verilog_files = cfg["VERILOG_FILES"]
    if not isinstance(verilog_files, list) or not verilog_files:
        fail("VERILOG_FILES must be a non-empty YAML list")

    for entry in verilog_files:
        if not isinstance(entry, str):
            fail("Every VERILOG_FILES entry must be a string")
        path = resolve_dir_path(entry)
        if not path.is_file():
            fail(f"RTL file does not exist: {path}")

    pin_cfg = cfg.get("FP_PIN_ORDER_CFG")
    if pin_cfg is not None:
        pin_path = resolve_dir_path(pin_cfg)
        if not pin_path.is_file():
            fail(f"Pin-order file does not exist: {pin_path}")

    sizing = cfg.get("FP_SIZING", "relative")
    if sizing not in {"relative", "absolute"}:
        fail("FP_SIZING must be relative or absolute")
    if sizing == "relative" and "FP_CORE_UTIL" not in cfg:
        fail("Relative sizing requires FP_CORE_UTIL in this lab")
    if sizing == "absolute":
        area = cfg.get("DIE_AREA")
        if not (isinstance(area, list) and len(area) == 4 and all(isinstance(v, (int, float)) for v in area)):
            fail("Absolute sizing requires DIE_AREA: [x0, y0, x1, y1]")
        x0, y0, x1, y1 = area
        if not (x1 > x0 and y1 > y0):
            fail("DIE_AREA upper-right coordinates must exceed lower-left coordinates")

    density = cfg.get("PL_TARGET_DENSITY_PCT")
    if density is not None and not (1 <= density <= 100):
        fail("PL_TARGET_DENSITY_PCT must be between 1 and 100")

    rtl_text = (ROOT / "rtl/lab4_counter.sv").read_text(encoding="utf-8")
    module_pattern = re.compile(r"\bmodule\s+" + re.escape(cfg["DESIGN_NAME"]) + r"\b")
    if not module_pattern.search(rtl_text):
        fail("DESIGN_NAME does not match a module declaration")
    if not re.search(r"\b" + re.escape(cfg["CLOCK_PORT"]) + r"\b", rtl_text):
        fail("CLOCK_PORT was not found in the top-level RTL")

    print("PASS: config.yaml syntax and Lab 4 pre-flight checks")
    print(f"  Design       : {cfg['DESIGN_NAME']}")
    print(f"  Clock        : {cfg['CLOCK_PORT']} @ {period} ns ({1000.0 / period:.3f} MHz)")
    print(f"  Floorplan    : {sizing}")
    print(f"  Density      : {cfg.get('PL_TARGET_DENSITY_PCT', 'LibreLane default')}%")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
