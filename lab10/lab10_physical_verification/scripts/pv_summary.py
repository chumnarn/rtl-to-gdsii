#!/usr/bin/env python3
"""Summarize LibreLane physical-verification results without fixed step numbers."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Iterable, Optional


def newest_run(runs_dir: Path) -> Optional[Path]:
    candidates = [p for p in runs_dir.iterdir() if p.is_dir()] if runs_dir.exists() else []
    return max(candidates, key=lambda p: p.stat().st_mtime) if candidates else None


def find_step(run_dir: Path, suffix: str) -> Optional[Path]:
    candidates = [
        p for p in run_dir.iterdir()
        if p.is_dir() and p.name.lower().endswith(suffix.lower())
    ]
    return max(candidates, key=lambda p: p.stat().st_mtime) if candidates else None


def iter_text_files(directory: Optional[Path]) -> Iterable[Path]:
    if directory is None or not directory.exists():
        return []
    extensions = {".rpt", ".log", ".txt", ".json", ".xml"}
    return (
        p for p in directory.rglob("*")
        if p.is_file() and (p.suffix.lower() in extensions or "report" in p.name.lower())
    )


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def magic_drc_count(step: Optional[Path]) -> tuple[Optional[int], Optional[Path]]:
    pattern = re.compile(r"\bCOUNT\s*:\s*(\d+)", re.IGNORECASE)
    for path in iter_text_files(step):
        match = pattern.search(read_text(path))
        if match:
            return int(match.group(1)), path
    return None, None


def klayout_drc_count(step: Optional[Path]) -> tuple[Optional[int], Optional[Path]]:
    for path in iter_text_files(step):
        if path.suffix.lower() != ".json":
            continue
        try:
            data = json.loads(read_text(path))
        except json.JSONDecodeError:
            continue
        if isinstance(data, dict) and isinstance(data.get("total"), int):
            return data["total"], path

    pattern = re.compile(r'["\']?total["\']?\s*[:=]\s*(\d+)', re.IGNORECASE)
    for path in iter_text_files(step):
        match = pattern.search(read_text(path))
        if match:
            return int(match.group(1)), path
    return None, None


def lvs_result(step: Optional[Path]) -> tuple[str, Optional[Path]]:
    pass_re = re.compile(r"Final result:\s*Circuits match uniquely", re.IGNORECASE)
    fail_re = re.compile(
        r"Circuits do not match|Final result:.*(?:mismatch|fail)|"
        r"netlists? do not match",
        re.IGNORECASE,
    )
    for path in iter_text_files(step):
        text = read_text(path)
        if pass_re.search(text):
            return "PASS", path
    for path in iter_text_files(step):
        text = read_text(path)
        if fail_re.search(text):
            return "FAIL", path
    return "UNKNOWN", None


def xor_result(step: Optional[Path]) -> tuple[str, Optional[Path]]:
    if step is None:
        return "NOT RUN", None

    clean_patterns = [
        re.compile(r"\btotal\s*[:=]\s*0\b", re.IGNORECASE),
        re.compile(r"\bcount\s*[:=]\s*0\b", re.IGNORECASE),
        re.compile(r"\b0\s+(?:differences|violations)\b", re.IGNORECASE),
    ]
    fail_patterns = [
        re.compile(r"\b(?:total|count)\s*[:=]\s*[1-9]\d*\b", re.IGNORECASE),
        re.compile(r"\b[1-9]\d*\s+(?:differences|violations)\b", re.IGNORECASE),
    ]
    files = list(iter_text_files(step))
    for path in files:
        text = read_text(path)
        if any(p.search(text) for p in fail_patterns):
            return "FAIL/DIFFERENCES", path
    for path in files:
        text = read_text(path)
        if any(p.search(text) for p in clean_patterns):
            return "PASS/CLEAN", path
    return "UNKNOWN", files[0] if files else None


def fmt_source(path: Optional[Path], run_dir: Path) -> str:
    if path is None:
        return "-"
    try:
        return str(path.relative_to(run_dir))
    except ValueError:
        return str(path)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--runs", default="runs", help="LibreLane runs directory")
    parser.add_argument("--run", help="Explicit run directory")
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Return non-zero unless Magic DRC=0, KLayout DRC=0 and LVS passes",
    )
    args = parser.parse_args()

    runs_dir = Path(args.runs)
    run_dir = Path(args.run) if args.run else newest_run(runs_dir)

    if run_dir is None or not run_dir.exists():
        print("ERROR: No LibreLane run directory was found.", file=sys.stderr)
        return 2

    magic_step = find_step(run_dir, "-magic-drc")
    klayout_step = find_step(run_dir, "-klayout-drc")
    lvs_step = find_step(run_dir, "-netgen-lvs")
    xor_step = find_step(run_dir, "-klayout-xor")

    magic_count, magic_file = magic_drc_count(magic_step)
    klayout_count, klayout_file = klayout_drc_count(klayout_step)
    lvs_status, lvs_file = lvs_result(lvs_step)
    xor_status, xor_file = xor_result(xor_step)

    print("=" * 72)
    print("LibreLane Physical Verification Summary")
    print("=" * 72)
    print(f"Run directory       : {run_dir}")
    print(f"Magic DRC count     : {magic_count if magic_count is not None else 'UNKNOWN'}")
    print(f"  report            : {fmt_source(magic_file, run_dir)}")
    print(f"KLayout DRC count   : {klayout_count if klayout_count is not None else 'UNKNOWN'}")
    print(f"  report            : {fmt_source(klayout_file, run_dir)}")
    print(f"KLayout XOR         : {xor_status}")
    print(f"  report            : {fmt_source(xor_file, run_dir)}")
    print(f"Netgen LVS          : {lvs_status}")
    print(f"  report            : {fmt_source(lvs_file, run_dir)}")
    print("=" * 72)

    clean = magic_count == 0 and klayout_count == 0 and lvs_status == "PASS"
    print("CORE PV STATUS      :", "PASS" if clean else "REVIEW REQUIRED")

    if args.strict and not clean:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
