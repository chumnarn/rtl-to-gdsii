#!/usr/bin/env python3
from __future__ import annotations

import os
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GDS = ROOT / "ip/bondpad_70x70_novias/gds/bondpad_70x70_novias.gds"
GDS_URL = (
    "https://github.com/IHP-GmbH/ihp-sg13g2-librelane-template/"
    "raw/refs/heads/main/ip/bondpad_70x70_novias/gds/"
    "bondpad_70x70_novias.gds"
)

def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(2)

pdk_root = os.environ.get("PDK_ROOT")
if not pdk_root:
    fail("PDK_ROOT is not set. Enter the LibreLane Nix/container shell first.")

pdk_dir = Path(pdk_root) / "ihp-sg13g2"
if not pdk_dir.is_dir():
    fail(f"IHP PDK not found: {pdk_dir}")

# Check representative I/O macro names in installed LEF files.
required = [
    "sg13g2_IOPadIn",
    "sg13g2_IOPadOut30mA",
    "sg13g2_IOPadVdd",
    "sg13g2_IOPadVss",
    "sg13g2_IOPadIOVdd",
    "sg13g2_IOPadIOVss",
]

lef_files = list(pdk_dir.rglob("*.lef"))
if not lef_files:
    fail(f"No LEF files found below {pdk_dir}")

lef_text = ""
for lef in lef_files:
    try:
        lef_text += lef.read_text(errors="ignore")
    except OSError:
        pass

missing = [cell for cell in required if f"MACRO {cell}" not in lef_text]
if missing:
    fail("Missing I/O macros in installed PDK: " + ", ".join(missing))

if not GDS.exists() or GDS.stat().st_size < 1000:
    print("Downloading official 70 um bondpad GDS...")
    GDS.parent.mkdir(parents=True, exist_ok=True)
    try:
        urllib.request.urlretrieve(GDS_URL, GDS)
    except Exception as exc:
        fail(
            f"Could not download bondpad GDS: {exc}\n"
            f"Download it manually from:\n{GDS_URL}\n"
            f"and place it at:\n{GDS}"
        )

print("Preparation passed.")
print(f"PDK: {pdk_dir}")
print(f"Bondpad GDS: {GDS} ({GDS.stat().st_size} bytes)")
