#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

KEYWORDS = (
    "area", "utilization", "density", "wns", "tns", "slack", "drc",
    "lvs", "antenna", "wire", "via", "power", "clock", "skew", "cell",
)


def load(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise SystemExit(f"File not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Invalid JSON in {path}: {exc}") from exc
    if not isinstance(data, dict):
        raise SystemExit(f"Expected a JSON object in {path}")
    return data


def interesting(key: str) -> bool:
    key = key.lower()
    return any(word in key for word in KEYWORDS)


def main() -> None:
    parser = argparse.ArgumentParser(description="Compare two LibreLane metrics.json files")
    parser.add_argument("baseline", type=Path)
    parser.add_argument("experiment", type=Path)
    args = parser.parse_args()

    baseline = load(args.baseline)
    experiment = load(args.experiment)

    print(f"{'Metric':64} {'Baseline':>20} {'Experiment':>20}")
    print("-" * 108)
    changed = 0
    for key in sorted(set(baseline) | set(experiment)):
        if not interesting(key):
            continue
        old = baseline.get(key, "<missing>")
        new = experiment.get(key, "<missing>")
        if old == new:
            continue
        changed += 1
        print(f"{key[:64]:64} {str(old)[:20]:>20} {str(new)[:20]:>20}")

    if changed == 0:
        print("No differing selected metrics were found.")


if __name__ == "__main__":
    main()
