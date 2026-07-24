#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys
import traceback

from common import make_flow


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run LibreLane Classic Flow.")
    parser.add_argument("--tag", default="lab14_ihp_full")
    parser.add_argument(
        "--no-overwrite",
        action="store_true",
        help="Keep an existing run directory instead of replacing it.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    try:
        from librelane.flows import FlowError

        flow = make_flow()
        print(f"Starting Classic Flow: tag={args.tag}")
        final_state = flow.start(
            tag=args.tag,
            overwrite=not args.no_overwrite,
        )

        print()
        print("Flow completed")
        print("=" * 72)
        print(f"Run directory   : {flow.run_dir}")
        print(f"Resolved config : {flow.config_resolved_path}")
        print(f"Executed steps  : {len(flow.step_objects)}")
        print(f"Metric count    : {len(final_state.metrics)}")
        return 0

    except FlowError as exc:
        print(f"LibreLane flow failed: {exc}", file=sys.stderr)
        return 2
    except Exception as exc:
        print(f"Unexpected error: {exc}", file=sys.stderr)
        traceback.print_exc()
        return 3


if __name__ == "__main__":
    raise SystemExit(main())
