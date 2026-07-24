#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from common import REPORTS_DIR


def flatten(prefix: str, value: Any, output: dict[str, Any]) -> None:
    if isinstance(value, dict):
        for key, child in value.items():
            child_prefix = f"{prefix}.{key}" if prefix else str(key)
            flatten(child_prefix, child, output)
    else:
        output[prefix] = value


def main() -> None:
    state_files = sorted(REPORTS_DIR.glob("*state*.json"))
    if not state_files:
        raise SystemExit(
            "No exported state JSON found. Run 'make state' first."
        )

    for path in state_files:
        with path.open("r", encoding="utf-8") as stream:
            data = json.load(stream)

        flattened: dict[str, Any] = {}
        flatten("", data, flattened)

        print()
        print(path.name)
        print("=" * 80)
        for key, value in sorted(flattened.items()):
            lowered = key.lower()
            if any(token in lowered for token in ("wns", "tns", "area", "drc", "lvs")):
                print(f"{key} = {value}")


if __name__ == "__main__":
    main()
