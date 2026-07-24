#!/usr/bin/env python3
from __future__ import annotations

from common import make_flow, resolve_step_id


def main() -> None:
    target = resolve_step_id(
        "Yosys.Synthesis",
        contains=("yosys", "synthesis"),
    )

    flow = make_flow()
    state = flow.start(
        tag="lab14_ihp_synthesis",
        to=target,
        overwrite=True,
    )

    print("Synthesis-stage run completed")
    print("=" * 72)
    print(f"Stopped after   : {target}")
    print(f"Run directory   : {flow.run_dir}")
    print(f"Executed steps  : {len(flow.step_objects)}")
    print(f"Metric count    : {len(state.metrics)}")


if __name__ == "__main__":
    main()
