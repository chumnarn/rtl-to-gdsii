#!/usr/bin/env python3
"""List important artifacts from the newest LibreLane run."""

from pathlib import Path
import sys

runs = Path("runs")
if not runs.is_dir():
    print("ERROR: no runs/ directory found.", file=sys.stderr)
    raise SystemExit(1)

directories = [p for p in runs.iterdir() if p.is_dir()]
if not directories:
    print("ERROR: no LibreLane run found.", file=sys.stderr)
    raise SystemExit(1)

latest = max(directories, key=lambda p: p.stat().st_mtime)
print(f"Latest run: {latest}")

wanted_suffixes = {".odb", ".def", ".gds", ".lef", ".lib", ".spef", ".rpt", ".csv"}
wanted_names = {"resolved.json", "metrics.json", "metrics.csv", "state_out.json"}

artifacts = [
    p for p in latest.rglob("*")
    if p.is_file() and (p.suffix.lower() in wanted_suffixes or p.name in wanted_names)
]

for artifact in sorted(artifacts):
    print(artifact)
