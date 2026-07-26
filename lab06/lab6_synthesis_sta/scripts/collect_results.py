#!/usr/bin/env python3
"""Collect the most useful synthesis and STA outputs from a LibreLane run."""
from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any

KEYWORDS = (
    "wns", "tns", "slack", "area", "cell", "instance",
    "setup", "hold", "violation", "clock"
)


def latest_run(runs_dir: Path) -> Path:
    candidates = [p for p in runs_dir.iterdir() if p.is_dir()]
    if not candidates:
        raise FileNotFoundError(f"No run directories found under {runs_dir}")
    return max(candidates, key=lambda p: p.stat().st_mtime)


def interesting(key: str) -> bool:
    k = key.lower()
    return any(word in k for word in KEYWORDS)


def read_json(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as f:
        obj = json.load(f)
    return obj if isinstance(obj, dict) else {}


def print_json_metrics(path: Path) -> None:
    data = read_json(path)
    print(f"\n[metrics] {path}")
    for key in sorted(data):
        if interesting(key):
            print(f"{key}: {data[key]}")


def print_csv_metrics(path: Path) -> None:
    print(f"\n[metrics] {path}")
    with path.open(newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    if not rows:
        return
    row = rows[-1]
    for key in sorted(row):
        if interesting(key) and row[key] not in (None, ""):
            print(f"{key}: {row[key]}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--runs", default="runs", type=Path)
    parser.add_argument("--run", type=Path, help="Specific run directory")
    args = parser.parse_args()

    run_dir = args.run or latest_run(args.runs)
    if not run_dir.exists():
        raise FileNotFoundError(run_dir)

    print(f"Run directory: {run_dir}")

    metric_files = sorted(run_dir.rglob("metrics.json")) + sorted(run_dir.rglob("metrics.csv"))
    if not metric_files:
        metric_files = sorted(run_dir.rglob("*metrics*.json"))

    for path in metric_files:
        try:
            if path.suffix == ".csv":
                print_csv_metrics(path)
            else:
                print_json_metrics(path)
        except (OSError, ValueError, json.JSONDecodeError) as exc:
            print(f"WARNING: could not read {path}: {exc}")

    print("\n[reports]")
    reports = [
        p for p in run_dir.rglob("*")
        if p.is_file() and (p.suffix in {".rpt", ".log"} or "summary" in p.name.lower())
    ]
    for path in sorted(reports):
        name = str(path).lower()
        if any(k in name for k in ("synth", "sta", "timing", "summary", "check")):
            print(path)

    print("\n[netlists]")
    for path in sorted(run_dir.rglob("*.v")):
        if any(k in path.name.lower() for k in ("nl", "synth", "netlist")):
            print(path)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
