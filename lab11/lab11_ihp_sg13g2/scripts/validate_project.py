#!/usr/bin/env python3
from __future__ import annotations

import argparse
import sys
from pathlib import Path

try:
    import yaml
except ImportError as exc:
    raise SystemExit(
        "PyYAML is required. Install it with: python3 -m pip install pyyaml"
    ) from exc


def resolve_dir_path(config_path: Path, value: str) -> Path:
    prefix = "dir::"
    if value.startswith(prefix):
        return (config_path.parent / value[len(prefix):]).resolve()
    return Path(value).expanduser().resolve()


def validate_config(config_path: Path) -> list[str]:
    errors: list[str] = []
    try:
        data = yaml.safe_load(config_path.read_text(encoding="utf-8"))
    except Exception as exc:
        return [f"{config_path}: YAML parse error: {exc}"]

    if not isinstance(data, dict):
        return [f"{config_path}: root must be a mapping"]

    required = ("DESIGN_NAME", "VERILOG_FILES", "CLOCK_PORT", "CLOCK_PERIOD")
    for key in required:
        if key not in data:
            errors.append(f"{config_path}: missing required key {key}")

    files = data.get("VERILOG_FILES", [])
    if isinstance(files, str):
        files = [files]
    if not isinstance(files, list):
        errors.append(f"{config_path}: VERILOG_FILES must be a list or string")
        return errors

    for entry in files:
        if not isinstance(entry, str):
            errors.append(f"{config_path}: invalid VERILOG_FILES entry: {entry!r}")
            continue
        resolved = resolve_dir_path(config_path, entry)
        if not resolved.is_file():
            errors.append(f"{config_path}: RTL file not found: {resolved}")

    for key in ("PNR_SDC_FILE", "SIGNOFF_SDC_FILE", "FALLBACK_SDC"):
        value = data.get(key)
        if value is not None:
            if not isinstance(value, str):
                errors.append(f"{config_path}: {key} must be a string")
            elif not resolve_dir_path(config_path, value).is_file():
                errors.append(f"{config_path}: {key} file not found: {resolve_dir_path(config_path, value)}")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate Lab 11 YAML and RTL paths")
    parser.add_argument("configs", nargs="+", type=Path)
    args = parser.parse_args()

    errors: list[str] = []
    for config in args.configs:
        errors.extend(validate_config(config.resolve()))

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print(f"PASS: validated {len(args.configs)} configuration file(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
