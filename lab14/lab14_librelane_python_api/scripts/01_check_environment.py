#!/usr/bin/env python3
from __future__ import annotations

import os
import shutil
import sys

from common import CONFIG_FILE, DEFAULT_PDK, PROJECT_ROOT


def main() -> int:
    try:
        import librelane
    except ImportError as exc:
        print("ERROR: Python cannot import the 'librelane' package.", file=sys.stderr)
        print("Enter the LibreLane Nix shell/container first.", file=sys.stderr)
        print(f"Details: {exc}", file=sys.stderr)
        return 1

    print("Lab 14 environment check")
    print("=" * 72)
    print(f"Project root      : {PROJECT_ROOT}")
    print(f"Configuration     : {CONFIG_FILE}")
    print(f"Python executable : {sys.executable}")
    print(f"Python version    : {sys.version.split()[0]}")
    print(f"LibreLane module  : {librelane.__file__}")
    print(f"LibreLane version : {getattr(librelane, '__version__', 'unknown')}")
    print(f"PDK               : {DEFAULT_PDK}")
    print(f"PDK_ROOT          : {os.environ.get('PDK_ROOT', '<not set>')}")
    print()

    required = ["python3", "librelane"]
    optional = ["iverilog", "vvp", "verilator", "yosys", "openroad", "klayout"]

    failed = False
    for command in required:
        path = shutil.which(command)
        print(f"{command:<12}: {path or 'NOT FOUND'}")
        failed |= path is None

    for command in optional:
        path = shutil.which(command)
        print(f"{command:<12}: {path or 'not found in current PATH'}")

    if not CONFIG_FILE.is_file():
        print(f"ERROR: missing {CONFIG_FILE}", file=sys.stderr)
        return 2

    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
