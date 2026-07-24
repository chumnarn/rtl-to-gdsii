#!/usr/bin/env python3
from __future__ import annotations

from librelane.flows import SequentialFlow

from common import get_flow_class, resolve_step_id


def main() -> None:
    classic = get_flow_class("Classic")
    target = resolve_step_id(
        "Yosys.Synthesis",
        contains=("yosys", "synthesis"),
    )

    selected_steps = []
    for step_class in classic.Steps:
        selected_steps.append(step_class)
        identifier = str(getattr(step_class, "id", step_class.__name__))
        if identifier == target:
            break
    else:
        raise RuntimeError(f"Target step not found in Classic Flow: {target}")

    class Lab14SynthesisFlow(SequentialFlow):
        name = "Lab14SynthesisFlow"
        Steps = selected_steps

    print("Custom synthesis flow steps")
    print("=" * 72)
    for index, step_class in enumerate(selected_steps, start=1):
        print(f"{index:3d}. {getattr(step_class, 'id', step_class.__name__)}")

    flow = Lab14SynthesisFlow(
        "config.yaml",
        pdk="ihp-sg13g2",
        design_dir=".",
    )
    state = flow.start(
        tag="lab14_ihp_custom_synthesis",
        overwrite=True,
    )

    print()
    print(f"Run directory  : {flow.run_dir}")
    print(f"Metric count   : {len(state.metrics)}")


if __name__ == "__main__":
    main()
