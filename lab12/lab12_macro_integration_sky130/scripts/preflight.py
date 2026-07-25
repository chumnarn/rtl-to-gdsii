#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("[ERROR] PyYAML is required", file=sys.stderr)
    raise

ROOT = Path(__file__).resolve().parents[1]

def load_yaml(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    if not isinstance(data, dict):
        raise ValueError(f"{path}: YAML root must be a mapping")
    return data

def check_config(path: Path, design: str) -> list[str]:
    cfg = load_yaml(path)
    errors: list[str] = []

    if cfg.get("DESIGN_NAME") != design:
        errors.append(f"{path}: DESIGN_NAME must be {design}")

    if cfg.get("meta", {}).get("version") != 3:
        errors.append(f"{path}: meta.version must be 3")

    for key in (
        "VERILOG_FILES", "CLOCK_PORT", "CLOCK_PERIOD",
        "PNR_SDC_FILE", "SIGNOFF_SDC_FILE",
        "VDD_NETS", "GND_NETS"
    ):
        if key not in cfg:
            errors.append(f"{path}: missing {key}")

    if cfg.get("VDD_NETS") != ["VPWR"]:
        errors.append(f"{path}: VDD_NETS must be [VPWR]")
    if cfg.get("GND_NETS") != ["VGND"]:
        errors.append(f"{path}: GND_NETS must be [VGND]")

    return errors

def ports(path: Path, module: str) -> set[str]:
    text = path.read_text(encoding="utf-8")
    if not re.search(rf"\bmodule\s+{re.escape(module)}\b", text):
        raise ValueError(f"{path}: module {module} not found")
    return set(re.findall(
        r"\b(?:input|output|inout)\s+"
        r"(?:wire|reg|logic)?\s*"
        r"(?:\[[^\]]+\]\s*)?"
        r"([A-Za-z_][A-Za-z0-9_$]*)",
        text
    ))

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--require-macro", action="store_true")
    args = parser.parse_args()

    errors: list[str] = []
    errors += check_config(ROOT / "macro/config.yaml", "counter_macro")
    errors += check_config(ROOT / "top/config.yaml", "macro_wrapper")

    required_source = [
        ROOT / "macro/src/counter_macro.sv",
        ROOT / "macro/constraints.sdc",
        ROOT / "top/src/counter_macro.vh",
        ROOT / "top/src/macro_wrapper.sv",
        ROOT / "top/constraints.sdc",
    ]
    for path in required_source:
        if not path.is_file() or path.stat().st_size == 0:
            errors.append(f"Missing or empty: {path}")

    try:
        rtl_ports = ports(ROOT / "macro/src/counter_macro.sv", "counter_macro")
        hdr_ports = ports(ROOT / "top/src/counter_macro.vh", "counter_macro")
        if rtl_ports != hdr_ports:
            errors.append(
                "RTL/header port mismatch: "
                f"RTL-only={sorted(rtl_ports-hdr_ports)}, "
                f"header-only={sorted(hdr_ports-rtl_ports)}"
            )
    except Exception as exc:
        errors.append(str(exc))

    top_text = (ROOT / "top/src/macro_wrapper.sv").read_text(encoding="utf-8")
    if not re.search(r"\bcounter_macro\s+u_counter_macro\b", top_text):
        errors.append("Top RTL must instantiate counter_macro u_counter_macro")

    top_cfg = load_yaml(ROOT / "top/config.yaml")
    macro_cfg = top_cfg.get("MACROS", {}).get("counter_macro", {})
    if "u_counter_macro" not in macro_cfg.get("instances", {}):
        errors.append(
            "top/config.yaml missing "
            "MACROS.counter_macro.instances.u_counter_macro"
        )

    expected_pdn = "u_counter_macro VPWR VGND VPWR VGND"
    if expected_pdn not in top_cfg.get("PDN_MACRO_CONNECTIONS", []):
        errors.append(
            "top/config.yaml must contain PDN connection: " + expected_pdn
        )

    if args.require_macro:
        generated = {
            "GDS": ROOT / "macros/counter_macro/gds/counter_macro.gds",
            "LEF": ROOT / "macros/counter_macro/lef/counter_macro.lef",
            "netlist": ROOT / "macros/counter_macro/nl/counter_macro.nl.v",
        }

        for name, path in generated.items():
            if not path.is_file() or path.stat().st_size == 0:
                errors.append(f"Generated {name} missing or empty: {path}")

        lef = generated["LEF"]
        if lef.is_file():
            text = lef.read_text(encoding="utf-8", errors="replace")
            if not re.search(r"(?m)^\s*MACRO\s+counter_macro\s*$", text):
                errors.append(f"{lef}: MACRO counter_macro not found")
            for pin in ("VPWR", "VGND", "clk_i", "rst_ni"):
                if not re.search(
                    rf"(?m)^\s*PIN\s+{re.escape(pin)}\s*$", text
                ):
                    errors.append(f"{lef}: PIN {pin} not found")

        nl = generated["netlist"]
        if nl.is_file():
            text = nl.read_text(encoding="utf-8", errors="replace")
            if not re.search(r"\bmodule\s+counter_macro\b", text):
                errors.append(f"{nl}: module counter_macro not found")

    if errors:
        print("Preflight FAILED")
        for error in errors:
            print(f"  [ERROR] {error}")
        return 1

    print("Preflight PASSED")
    print("  PDK target   : sky130A")
    print("  SCL target   : sky130_fd_sc_hd")
    print("  macro design : counter_macro")
    print("  top design   : macro_wrapper")
    print("  instance     : u_counter_macro")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
