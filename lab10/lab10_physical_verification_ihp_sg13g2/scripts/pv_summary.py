#!/usr/bin/env python3
"""Summarize IHP SG13G2 LibreLane DRC/XOR/LVS results.

The script does not depend on fixed step numbers. It recognizes both
KLayout.LVS (preferred/current IHP integration) and Netgen.LVS
(older or alternate LibreLane flows).
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Iterable, Optional


def newest_run(runs_dir: Path) -> Optional[Path]:
    if not runs_dir.exists():
        return None
    candidates = [p for p in runs_dir.iterdir() if p.is_dir()]
    return max(candidates, key=lambda p: p.stat().st_mtime) if candidates else None


def find_step(run_dir: Path, suffixes: tuple[str, ...]) -> Optional[Path]:
    suffixes_l = tuple(s.lower() for s in suffixes)
    candidates = [
        p for p in run_dir.iterdir()
        if p.is_dir() and p.name.lower().endswith(suffixes_l)
    ]
    return max(candidates, key=lambda p: p.stat().st_mtime) if candidates else None


def text_files(directory: Optional[Path]) -> list[Path]:
    if directory is None or not directory.exists():
        return []
    allowed = {".rpt", ".log", ".txt", ".json", ".xml", ".lyrdb"}
    return [
        p for p in directory.rglob("*")
        if p.is_file() and (p.suffix.lower() in allowed or "report" in p.name.lower())
    ]


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def generic_zero_count(step: Optional[Path], preferred_key: str) -> tuple[Optional[int], Optional[Path]]:
    files = text_files(step)

    # Structured JSON first.
    for path in files:
        if path.suffix.lower() != ".json":
            continue
        try:
            data = json.loads(read_text(path))
        except (json.JSONDecodeError, OSError):
            continue
        if isinstance(data, dict):
            for key in (preferred_key, "total", "count", "violations"):
                value = data.get(key)
                if isinstance(value, int):
                    return value, path

    patterns = [
        re.compile(r"\bCOUNT\s*:\s*(\d+)", re.I),
        re.compile(r'["\']?total["\']?\s*[:=]\s*(\d+)', re.I),
        re.compile(r"\bviolations?\s*[:=]\s*(\d+)", re.I),
    ]
    for path in files:
        text = read_text(path)
        for pattern in patterns:
            match = pattern.search(text)
            if match:
                return int(match.group(1)), path
    return None, None


def lvs_result(step: Optional[Path]) -> tuple[str, Optional[Path], str]:
    if step is None:
        return "NOT RUN", None, "-"

    pass_patterns = [
        re.compile(r"Final result:\s*Circuits match uniquely", re.I),
        re.compile(r"\bnetlists?\s+match\b", re.I),
        re.compile(r"\blvs\s+(?:result\s*[:=]\s*)?(?:clean|pass(?:ed)?)\b", re.I),
        re.compile(r"\bcomparison\s+(?:result\s*[:=]\s*)?equivalent\b", re.I),
    ]
    fail_patterns = [
        re.compile(r"Circuits do not match", re.I),
        re.compile(r"\bnetlists?\s+do not match\b", re.I),
        re.compile(r"\blvs\s+(?:result\s*[:=]\s*)?fail(?:ed)?\b", re.I),
        re.compile(r"\bnot equivalent\b", re.I),
    ]

    files = text_files(step)
    for path in files:
        text = read_text(path)
        if any(p.search(text) for p in fail_patterns):
            return "FAIL", path, step.name
    for path in files:
        text = read_text(path)
        if any(p.search(text) for p in pass_patterns):
            return "PASS", path, step.name
    return "UNKNOWN", files[0] if files else None, step.name


def xor_result(step: Optional[Path]) -> tuple[str, Optional[Path]]:
    if step is None:
        return "NOT RUN", None
    count, path = generic_zero_count(step, "total")
    if count is not None:
        return ("PASS/CLEAN" if count == 0 else f"FAIL ({count})"), path
    return "UNKNOWN", text_files(step)[0] if text_files(step) else None


def relative(path: Optional[Path], base: Path) -> str:
    if path is None:
        return "-"
    try:
        return str(path.relative_to(base))
    except ValueError:
        return str(path)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--runs", default="runs")
    ap.add_argument("--run")
    ap.add_argument("--strict", action="store_true")
    args = ap.parse_args()

    run_dir = Path(args.run) if args.run else newest_run(Path(args.runs))
    if run_dir is None or not run_dir.exists():
        print("ERROR: no LibreLane run directory found.", file=sys.stderr)
        return 2

    magic_step = find_step(run_dir, ("-magic-drc",))
    klayout_step = find_step(run_dir, ("-klayout-drc",))
    xor_step = find_step(run_dir, ("-klayout-xor",))
    lvs_step = find_step(run_dir, ("-klayout-lvs", "-netgen-lvs"))

    magic_count, magic_report = generic_zero_count(magic_step, "count")
    klayout_count, klayout_report = generic_zero_count(klayout_step, "total")
    xor_status, xor_report = xor_result(xor_step)
    lvs_status, lvs_report, lvs_engine = lvs_result(lvs_step)

    print("=" * 76)
    print("Lab 10 — IHP SG13G2 Physical Verification Summary")
    print("=" * 76)
    print(f"Run directory       : {run_dir}")
    print(f"Magic DRC count     : {magic_count if magic_count is not None else 'UNKNOWN'}")
    print(f"  report            : {relative(magic_report, run_dir)}")
    print(f"KLayout DRC count   : {klayout_count if klayout_count is not None else 'UNKNOWN'}")
    print(f"  report            : {relative(klayout_report, run_dir)}")
    print(f"KLayout XOR         : {xor_status}")
    print(f"  report            : {relative(xor_report, run_dir)}")
    print(f"LVS engine/step     : {lvs_engine}")
    print(f"LVS result          : {lvs_status}")
    print(f"  report            : {relative(lvs_report, run_dir)}")
    print("=" * 76)

    clean = magic_count == 0 and klayout_count == 0 and lvs_status == "PASS"
    print("CORE PV STATUS      :", "PASS" if clean else "REVIEW REQUIRED")

    return 1 if args.strict and not clean else 0


if __name__ == "__main__":
    raise SystemExit(main())
