#!/usr/bin/env python3
from __future__ import annotations

import csv

from common import (
    CONFIG_FILE,
    REPORTS_DIR,
    find_metric,
    make_flow,
)

EXPERIMENTS = [
    ("density_30", 30),
    ("density_35", 35),
    ("density_40", 40),
]


def main() -> None:
    rows: list[dict[str, object]] = []

    for name, density in EXPERIMENTS:
        print(f"\nRunning {name}: PL_TARGET_DENSITY_PCT={density}")
        overlay = {"PL_TARGET_DENSITY_PCT": density}
        flow = make_flow([CONFIG_FILE, overlay])

        try:
            state = flow.start(
                tag=f"lab14_ihp_{name}",
                overwrite=True,
            )
            metrics = state.metrics
            rows.append(
                {
                    "experiment": name,
                    "density_pct": density,
                    "status": "PASS",
                    "design_area": find_metric(metrics, "design", "area"),
                    "setup_wns": find_metric(metrics, "setup", "wns"),
                    "setup_tns": find_metric(metrics, "setup", "tns"),
                    "drc": find_metric(metrics, "drc"),
                    "run_dir": str(flow.run_dir),
                    "error": "",
                }
            )
        except Exception as exc:
            rows.append(
                {
                    "experiment": name,
                    "density_pct": density,
                    "status": "FAIL",
                    "design_area": "",
                    "setup_wns": "",
                    "setup_tns": "",
                    "drc": "",
                    "run_dir": str(getattr(flow, "run_dir", "")),
                    "error": str(exc),
                }
            )

    output = REPORTS_DIR / "parameter_sweep.csv"
    fieldnames = [
        "experiment",
        "density_pct",
        "status",
        "design_area",
        "setup_wns",
        "setup_tns",
        "drc",
        "run_dir",
        "error",
    ]

    with output.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    print(f"\nSweep report: {output}")


if __name__ == "__main__":
    main()
