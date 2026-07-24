#!/usr/bin/env python3
from __future__ import annotations

from common import DEFAULT_PDK, make_flow


def main() -> None:
    flow = make_flow()

    print("Configuration resolved successfully")
    print("=" * 72)
    print(f"PDK                       : {DEFAULT_PDK}")
    print(f"Flow class                : {flow.__class__.__name__}")
    print(f"DESIGN_NAME               : {flow.config['DESIGN_NAME']}")
    print(f"CLOCK_PORT                : {flow.config['CLOCK_PORT']}")
    print(f"CLOCK_PERIOD              : {flow.config['CLOCK_PERIOD']} ns")
    print(f"DIE_AREA                  : {flow.config['DIE_AREA']}")
    print(f"CORE_AREA                 : {flow.config['CORE_AREA']}")
    print(
        "PL_TARGET_DENSITY_PCT     : "
        f"{flow.config['PL_TARGET_DENSITY_PCT']}"
    )


if __name__ == "__main__":
    main()
