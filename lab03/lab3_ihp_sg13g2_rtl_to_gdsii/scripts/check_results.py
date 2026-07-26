#!/usr/bin/env python3
"""Summarize key outputs from the newest LibreLane run."""

from __future__ import annotations

import csv
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def latest_run() -> Path | None:
    runs = [p for p in (ROOT / "runs").glob("*") if p.is_dir()]
    return max(runs, key=lambda p: p.stat().st_mtime) if runs else None


def files(run: Path, *patterns: str) -> list[Path]:
    result: set[Path] = set()
    for pattern in patterns:
        result.update(p for p in run.rglob(pattern) if p.is_file())
    return sorted(result)


def show(title: str, run: Path, found: list[Path]) -> None:
    print(f"\n{title}: {len(found)}")
    for path in found[-12:]:
        print(f"  {path.relative_to(run)}")
    if not found:
        print("  not found")


def show_metrics(run: Path) -> None:
    json_path = run / "final" / "metrics.json"
    csv_path = run / "final" / "metrics.csv"
    tokens = (
        "wns", "tns", "slack", "drc", "lvs", "antenna", "area",
        "utilization", "wirelength", "unrouted", "instance", "via"
    )

    data: dict[str, object] = {}
    if json_path.is_file():
        try:
            loaded = json.loads(json_path.read_text(encoding="utf-8"))
            if isinstance(loaded, dict):
                data = loaded
        except (OSError, json.JSONDecodeError) as exc:
            print(f"WARNING: cannot parse {json_path}: {exc}")
    elif csv_path.is_file():
        try:
            with csv_path.open(newline="", encoding="utf-8") as handle:
                for row in csv.reader(handle):
                    if len(row) >= 2:
                        data[row[0]] = row[1]
        except OSError as exc:
            print(f"WARNING: cannot parse {csv_path}: {exc}")

    print("\nSelected final metrics:")
    selected = [(k, v) for k, v in sorted(data.items())
                if any(token in k.lower() for token in tokens)]
    if not selected:
        print("  no selected metrics found")
    for key, value in selected:
        print(f"  {key}: {value}")


def main() -> int:
    run = latest_run()
    if run is None:
        print("ERROR: no runs/* directory found; run `make pnr` first.", file=sys.stderr)
        return 1

    print(f"Latest run: {run}")
    show("Final views", run, files(run / "final", "*"))
    show("GDSII", run, files(run, "*.gds", "*.gdsii"))
    show("OpenDB", run, files(run, "*.odb"))
    show("DEF", run, files(run, "*.def"))
    show("Netlists", run, files(run, "*.nl.v", "*.pnl.v"))
    show("SPEF", run, files(run, "*.spef"))
    show("SDF", run, files(run, "*.sdf"))
    show("STA summaries", run, files(run, "summary.rpt"))
    show("DRC/LVS/Antenna reports", run,
         [p for p in files(run, "*.rpt", "*.log")
          if any(t in str(p).lower() for t in ("drc", "lvs", "antenna"))])
    show_metrics(run)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
