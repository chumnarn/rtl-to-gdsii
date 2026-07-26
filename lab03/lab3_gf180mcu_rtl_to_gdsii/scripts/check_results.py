#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
import sys

ROOT = Path("runs")
if not ROOT.exists():
    raise SystemExit("No runs/ directory. Run `make pnr` first.")

runs = sorted((p for p in ROOT.iterdir() if p.is_dir()), key=lambda p: p.stat().st_mtime, reverse=True)
if not runs:
    raise SystemExit("No LibreLane run directories found.")
run = runs[0]
print(f"Latest run: {run}")

patterns = {
    "GDSII": ("*.gds", "*.gdsii"),
    "DEF": ("*.def",),
    "ODB": ("*.odb",),
    "Netlist": ("*.v",),
    "SPEF": ("*.spef",),
    "SDF": ("*.sdf",),
    "Metrics": ("*metrics*.json", "*metrics*.csv"),
}

for label, globs in patterns.items():
    found: list[Path] = []
    for pattern in globs:
        found.extend(run.rglob(pattern))
    unique = sorted(set(found))
    print(f"\n{label}: {len(unique)}")
    for path in unique[-8:]:
        print(f"  {path}")

metric_files = sorted(run.rglob("*metrics*.json"))
if metric_files:
    metric = metric_files[-1]
    try:
        data = json.loads(metric.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"\nCould not parse {metric}: {exc}")
    else:
        print(f"\nSelected metrics from {metric}:")
        keywords = ("wns", "tns", "drc", "lvs", "antenna", "area", "utilization", "wirelength", "unrouted")
        for key in sorted(data):
            if any(word in key.lower() for word in keywords):
                print(f"  {key}: {data[key]}")
