#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from common import REPORTS_DIR, make_flow


def json_default(value: Any) -> str:
    return str(value)


def main() -> None:
    flow = make_flow()
    state = flow.start(
        tag="lab14_ihp_state",
        overwrite=True,
    )

    output = REPORTS_DIR / "final_state.json"
    raw = state.to_raw_dict(metrics=True)

    with output.open("w", encoding="utf-8") as stream:
        json.dump(raw, stream, indent=2, default=json_default)

    metrics_output = REPORTS_DIR / "metrics.txt"
    with metrics_output.open("w", encoding="utf-8") as stream:
        for name in sorted(state.metrics):
            stream.write(f"{name} = {state.metrics[name]}\n")

    print(f"State JSON      : {output}")
    print(f"Metrics report  : {metrics_output}")
    print(f"Run directory   : {flow.run_dir}")


if __name__ == "__main__":
    main()
