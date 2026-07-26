#!/usr/bin/env python3
"""Collect common LibreLane metric keys from JSON files under runs/."""

from __future__ import annotations

import csv
import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
RUNS = ROOT / "runs"
OUT = ROOT / "reports" / "run_summary.csv"

WANTED_SUFFIXES = (
    "design__instance__area",
    "design__instance__count",
    "design__die__area",
    "timing__setup__ws",
    "timing__setup__tns",
    "route__wirelength",
    "route__drc_errors",
    "magic__drc_error__count",
    "lvs__error__count",
)


def flatten(obj: Any, prefix: str = "") -> dict[str, Any]:
    result: dict[str, Any] = {}
    if isinstance(obj, dict):
        for key, value in obj.items():
            new_key = f"{prefix}.{key}" if prefix else str(key)
            result.update(flatten(value, new_key))
    else:
        result[prefix] = obj
    return result


def find_metrics(run_dir: Path) -> dict[str, Any]:
    merged: dict[str, Any] = {}
    for path in run_dir.rglob("*.json"):
        if "metric" not in path.name.lower() and "summary" not in path.name.lower():
            continue
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError, OSError):
            continue
        merged.update(flatten(data))
    selected: dict[str, Any] = {}
    for full_key, value in merged.items():
        for suffix in WANTED_SUFFIXES:
            if full_key.endswith(suffix):
                selected[suffix] = value
    return selected


def main() -> int:
    if not RUNS.is_dir():
        print("No runs/ directory found. Run LibreLane first.")
        return 0

    rows = []
    for run_dir in sorted(path for path in RUNS.iterdir() if path.is_dir()):
        row = {"run": run_dir.name}
        row.update(find_metrics(run_dir))
        rows.append(row)

    OUT.parent.mkdir(exist_ok=True)
    columns = ["run", *WANTED_SUFFIXES]
    with OUT.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=columns)
        writer.writeheader()
        writer.writerows(rows)

    print(f"Wrote {OUT.relative_to(ROOT)} ({len(rows)} run(s))")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
