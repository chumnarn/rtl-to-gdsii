#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path

KEYS = (
    "DESIGN_NAME", "PDK", "STD_CELL_LIBRARY", "CLOCK_PORT", "CLOCK_PERIOD",
    "FP_CORE_UTIL", "FP_ASPECT_RATIO", "FP_CORE_MARGIN",
    "PL_TARGET_DENSITY_PCT", "RT_MIN_LAYER", "RT_MAX_LAYER",
)


def main() -> None:
    parser = argparse.ArgumentParser(description="Print important resolved configuration values")
    parser.add_argument("resolved_json", type=Path)
    args = parser.parse_args()

    try:
        data = json.loads(args.resolved_json.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise SystemExit(f"File not found: {args.resolved_json}") from exc
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Invalid JSON: {exc}") from exc

    for key in KEYS:
        print(f"{key:26}: {data.get(key, '<not present>')}")


if __name__ == "__main__":
    main()
