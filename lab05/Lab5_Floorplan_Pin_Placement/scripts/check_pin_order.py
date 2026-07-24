#!/usr/bin/env python3
"""Validate coverage and side assignment in constraints/pin_order.cfg."""

from __future__ import annotations

import re
import sys
from pathlib import Path

WIDTH = 8
CFG = Path("constraints/pin_order.cfg")

EXPECTED_BY_SIDE = {
    "N": ["clk", "rst_n", "enable_i", "load_i"],
    "E": [f"data_i[{i}]" for i in range(WIDTH)],
    "S": ["terminal_o"],
    "W": [f"count_o[{i}]" for i in range(WIDTH)],
}

def parse_cfg(path: Path) -> dict[str, list[str]]:
    side_patterns = {"N": [], "E": [], "S": [], "W": []}
    current_side: str | None = None

    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()

        if line in {"#N", "#E", "#S", "#W"}:
            current_side = line[1]
            continue

        if not line or line.startswith("#") or line.startswith("@"):
            continue

        if current_side is None:
            raise ValueError(f"pattern appears before a side declaration: {line}")

        re.compile(line)
        side_patterns[current_side].append(line)

    return side_patterns

def main() -> int:
    if not CFG.is_file():
        print(f"ERROR: missing {CFG}", file=sys.stderr)
        return 2

    try:
        side_patterns = parse_cfg(CFG)
    except (ValueError, re.error) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    errors: list[str] = []

    for expected_side, ports in EXPECTED_BY_SIDE.items():
        for port in ports:
            matched_sides = [
                side
                for side, patterns in side_patterns.items()
                if any(re.fullmatch(pattern, port) for pattern in patterns)
            ]

            if matched_sides != [expected_side]:
                errors.append(
                    f"{port}: expected side {expected_side}, matched {matched_sides}"
                )

    if errors:
        print("ERROR: pin-order validation failed:")
        for error in errors:
            print(f"  - {error}")
        return 1

    count = sum(len(ports) for ports in EXPECTED_BY_SIDE.values())
    print(f"PASS: all {count} pins match exactly one expected side.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
