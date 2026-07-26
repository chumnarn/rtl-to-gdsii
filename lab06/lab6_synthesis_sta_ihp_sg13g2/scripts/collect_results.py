#!/usr/bin/env python3
from pathlib import Path
import argparse
import json
import re

parser = argparse.ArgumentParser(description="Collect LibreLane synthesis/STA results")
parser.add_argument("--run-dir", type=Path, default=Path("runs/lab6_ihp"))
parser.add_argument("--output", type=Path, default=Path("reports/summary.md"))
args = parser.parse_args()

run_dir = args.run_dir
args.output.parent.mkdir(parents=True, exist_ok=True)

if not run_dir.exists():
    raise SystemExit(f"ERROR: run directory does not exist: {run_dir}")

patterns = {
    "setup_wns": re.compile(r"(?:setup[^\n]*wns|wns[^\n]*setup)[^-\d]*(-?\d+(?:\.\d+)?)", re.I),
    "setup_tns": re.compile(r"(?:setup[^\n]*tns|tns[^\n]*setup)[^-\d]*(-?\d+(?:\.\d+)?)", re.I),
    "hold_wns":  re.compile(r"(?:hold[^\n]*wns|wns[^\n]*hold)[^-\d]*(-?\d+(?:\.\d+)?)", re.I),
    "hold_tns":  re.compile(r"(?:hold[^\n]*tns|tns[^\n]*hold)[^-\d]*(-?\d+(?:\.\d+)?)", re.I),
}

results = {key: None for key in patterns}
matches = []

for path in sorted(run_dir.rglob("*")):
    if not path.is_file() or path.suffix.lower() not in {".log", ".rpt", ".txt", ".json"}:
        continue
    try:
        text = path.read_text(errors="ignore")
    except OSError:
        continue

    for key, pattern in patterns.items():
        found = pattern.search(text)
        if found and results[key] is None:
            results[key] = found.group(1)
            matches.append((key, str(path), found.group(0).strip()))

netlists = sorted(
    p for p in run_dir.rglob("*")
    if p.is_file() and (p.name.endswith(".nl.v") or "synthesis" in p.name.lower())
)
reports = sorted(
    p for p in run_dir.rglob("*")
    if p.is_file() and p.suffix.lower() in {".rpt", ".csv", ".json"}
)

lines = [
    "# Lab 6 IHP SG13G2 Result Summary",
    "",
    f"- Run directory: `{run_dir}`",
    f"- Setup WNS: `{results['setup_wns'] or 'not located automatically'}`",
    f"- Setup TNS: `{results['setup_tns'] or 'not located automatically'}`",
    f"- Hold WNS: `{results['hold_wns'] or 'not located automatically'}`",
    f"- Hold TNS: `{results['hold_tns'] or 'not located automatically'}`",
    "",
    "## Candidate synthesized netlists",
]
lines += [f"- `{p}`" for p in netlists[:20]] or ["- None found"]
lines += ["", "## Candidate reports"]
lines += [f"- `{p}`" for p in reports[:40]] or ["- None found"]
lines += ["", "## Pattern matches"]
lines += [f"- **{k}** in `{p}`: `{m}`" for k, p, m in matches] or ["- None found"]

args.output.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"Wrote {args.output}")
