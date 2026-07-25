#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("[ERROR] PyYAML is required for preflight.py", file=sys.stderr)
    raise

ROOT = Path(__file__).resolve().parents[1]

def load_yaml(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    if not isinstance(data, dict):
        raise ValueError(f"{path}: root YAML object must be a mapping")
    return data

def check_config(path: Path, expected_design: str) -> list[str]:
    errors: list[str] = []
    cfg = load_yaml(path)

    if cfg.get("DESIGN_NAME") != expected_design:
        errors.append(
            f"{path}: DESIGN_NAME must be {expected_design!r}, "
            f"found {cfg.get('DESIGN_NAME')!r}"
        )

    meta = cfg.get("meta", {})
    if meta.get("version") != 3:
        errors.append(f"{path}: meta.version must be 3")

    for key in ("VERILOG_FILES", "CLOCK_PORT", "CLOCK_PERIOD",
                "PNR_SDC_FILE", "SIGNOFF_SDC_FILE", "VDD_NETS", "GND_NETS"):
        if key not in cfg:
            errors.append(f"{path}: missing required key {key}")

    return errors

def module_ports(path: Path, module_name: str) -> set[str]:
    text = path.read_text(encoding="utf-8")
    if not re.search(rf"\bmodule\s+{re.escape(module_name)}\b", text):
        raise ValueError(f"{path}: module {module_name} not found")
    ports = set(re.findall(r"\b(?:input|output|inout)\s+(?:wire|reg|logic)?\s*(?:\[[^\]]+\]\s*)?([A-Za-z_][A-Za-z0-9_$]*)", text))
    return ports

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--require-macro", action="store_true")
    args = parser.parse_args()

    errors: list[str] = []
    errors += check_config(ROOT / "macro/config.yaml", "counter_macro")
    errors += check_config(ROOT / "top/config.yaml", "macro_wrapper")

    macro_rtl = ROOT / "macro/src/counter_macro.sv"
    macro_vh = ROOT / "top/src/counter_macro.vh"
    top_rtl = ROOT / "top/src/macro_wrapper.sv"

    for path in (macro_rtl, macro_vh, top_rtl,
                 ROOT / "macro/constraints.sdc",
                 ROOT / "top/constraints.sdc"):
        if not path.is_file() or path.stat().st_size == 0:
            errors.append(f"Missing or empty file: {path}")

    try:
        rtl_ports = module_ports(macro_rtl, "counter_macro")
        vh_ports = module_ports(macro_vh, "counter_macro")
        if rtl_ports != vh_ports:
            errors.append(
                "counter_macro RTL/header port mismatch: "
                f"RTL-only={sorted(rtl_ports-vh_ports)}, "
                f"header-only={sorted(vh_ports-rtl_ports)}"
            )
    except Exception as exc:
        errors.append(str(exc))

    top_text = top_rtl.read_text(encoding="utf-8")
    if not re.search(r"\bcounter_macro\s+u_counter_macro\b", top_text):
        errors.append(
            "top/src/macro_wrapper.sv must instantiate "
            "'counter_macro u_counter_macro'"
        )

    top_cfg = load_yaml(ROOT / "top/config.yaml")
    instances = (
        top_cfg.get("MACROS", {})
        .get("counter_macro", {})
        .get("instances", {})
    )
    if "u_counter_macro" not in instances:
        errors.append(
            "top/config.yaml must declare "
            "MACROS.counter_macro.instances.u_counter_macro"
        )

    if args.require_macro:
        required = [
            ROOT / "macros/counter_macro/gds/counter_macro.gds",
            ROOT / "macros/counter_macro/lef/counter_macro.lef",
            ROOT / "macros/counter_macro/nl/counter_macro.nl.v",
        ]
        for path in required:
            if not path.is_file() or path.stat().st_size == 0:
                errors.append(f"Generated macro view missing or empty: {path}")

        lef = ROOT / "macros/counter_macro/lef/counter_macro.lef"
        if lef.is_file():
            text = lef.read_text(encoding="utf-8", errors="replace")
            if not re.search(r"(?m)^\s*MACRO\s+counter_macro\s*$", text):
                errors.append(f"{lef}: MACRO counter_macro not found")
            for pin in ("VDD", "VSS", "clk_i", "rst_ni"):
                if not re.search(rf"(?m)^\s*PIN\s+{re.escape(pin)}\s*$", text):
                    errors.append(f"{lef}: PIN {pin} not found")

        nl = ROOT / "macros/counter_macro/nl/counter_macro.nl.v"
        if nl.is_file():
            text = nl.read_text(encoding="utf-8", errors="replace")
            if not re.search(r"\bmodule\s+counter_macro\b", text):
                errors.append(f"{nl}: module counter_macro not found")

    if errors:
        print("Preflight FAILED:")
        for err in errors:
            print(f"  [ERROR] {err}")
        return 1

    print("Preflight PASSED")
    print("  macro design : counter_macro")
    print("  top design   : macro_wrapper")
    print("  instance     : u_counter_macro")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
