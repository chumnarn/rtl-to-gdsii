#!/usr/bin/env python3
"""Locate key outputs from the latest LibreLane run and print a concise summary."""

from __future__ import annotations

import json
import sys
from pathlib import Path


def newest_run(root: Path) -> Path | None:
    candidates = [p for p in root.glob("runs/*") if p.is_dir()]
    candidates += [p for p in root.glob("run/*") if p.is_dir()]
    return max(candidates, key=lambda p: p.stat().st_mtime) if candidates else None


def find_files(run: Path, patterns: list[str]) -> list[Path]:
    found: set[Path] = set()
    for pattern in patterns:
        found.update(p for p in run.rglob(pattern) if p.is_file())
    return sorted(found)


def print_group(title: str, files: list[Path], run: Path) -> None:
    print(f"\n{title} ({len(files)})")
    if not files:
        print("  - not found")
        return
    for path in files[-10:]:
        print(f"  - {path.relative_to(run)}")


def print_metrics(metrics_files: list[Path]) -> None:
    interesting = (
        "wns", "tns", "drc", "lvs", "antenna", "area", "utilization",
        "wirelength", "unrouted", "cell", "via"
    )
    for path in reversed(metrics_files):
        if path.suffix.lower() != ".json":
            continue
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        print(f"\nSelected metrics from {path.name}")
        matched = 0
        for key, value in sorted(data.items()):
            if any(token in key.lower() for token in interesting):
                print(f"  {key}: {value}")
                matched += 1
        if matched == 0:
            print("  No selected metric keys found; inspect the JSON directly.")
        return


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    run = newest_run(root)
    if run is None:
        print("ERROR: no LibreLane run directory found. Run `make pnr` first.", file=sys.stderr)
        return 1

    print(f"Latest run: {run}")
    print_group("GDSII", find_files(run, ["*.gds", "*.gdsii"]), run)
    print_group("DEF", find_files(run, ["*.def"]), run)
    print_group("OpenDB", find_files(run, ["*.odb"]), run)
    print_group("Gate-level netlists", find_files(run, ["*.v"]), run)
    print_group("SPEF", find_files(run, ["*.spef"]), run)
    print_group("SDF", find_files(run, ["*.sdf"]), run)
    print_group("Reports", find_files(run, ["*.rpt", "*.report"]), run)

    metrics = find_files(run, ["*metrics*.json", "*metrics*.csv", "*metrics*.yaml"])
    print_group("Metrics", metrics, run)
    print_metrics(metrics)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
