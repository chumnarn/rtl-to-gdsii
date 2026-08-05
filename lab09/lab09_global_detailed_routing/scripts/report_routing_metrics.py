#!/usr/bin/env python3
"""Print routing-related LibreLane metrics from the newest run."""

from __future__ import annotations

import csv
import json
import sys
from pathlib import Path
from typing import Any, Iterable

KEYWORDS = (
    "route", "routing", "wirelength", "via", "drc", "antenna",
    "congestion", "disconnected", "short", "setup", "hold", "wns", "tns",
)


def newest_run(runs_dir: Path) -> Path:
    candidates = [p for p in runs_dir.iterdir() if p.is_dir()]
    if not candidates:
        raise RuntimeError(f"No runs found under {runs_dir}")
    return max(candidates, key=lambda p: p.stat().st_mtime)


def is_relevant(name: str) -> bool:
    lowered = name.lower()
    return any(keyword in lowered for keyword in KEYWORDS)


def flatten(value: Any, prefix: str = "") -> Iterable[tuple[str, Any]]:
    if isinstance(value, dict):
        for key, child in value.items():
            name = f"{prefix}.{key}" if prefix else str(key)
            yield from flatten(child, name)
    else:
        yield prefix, value


def read_json(path: Path) -> list[tuple[str, Any]]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return []
    return [(name, value) for name, value in flatten(data) if is_relevant(name)]


def read_csv(path: Path) -> list[tuple[str, Any]]:
    found: list[tuple[str, Any]] = []
    try:
        with path.open(newline="", encoding="utf-8") as handle:
            for row in csv.DictReader(handle):
                found.extend(
                    (key, value) for key, value in row.items()
                    if key and value not in (None, "") and is_relevant(key)
                )
    except (OSError, csv.Error):
        return []
    return found


def main() -> int:
    runs_dir = Path(sys.argv[1] if len(sys.argv) > 1 else "runs")
    if not runs_dir.is_dir():
        print(f"ERROR: {runs_dir} does not exist", file=sys.stderr)
        return 1

    try:
        run = newest_run(runs_dir)
    except RuntimeError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    print(f"Latest run: {run}")
    files = sorted(set(run.rglob("*metrics*.json")) | set(run.rglob("metrics.csv")))
    if not files:
        print("ERROR: no metrics files found", file=sys.stderr)
        return 1

    count = 0
    seen: set[tuple[str, str]] = set()
    for path in files:
        entries = read_json(path) if path.suffix == ".json" else read_csv(path)
        for name, value in entries:
            item = (name, str(value))
            if item in seen:
                continue
            seen.add(item)
            print(f"{name:64s} : {value}")
            count += 1

    if count == 0:
        print("No routing-related metrics were found.")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
