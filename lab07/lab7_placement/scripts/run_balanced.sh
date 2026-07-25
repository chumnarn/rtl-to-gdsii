#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
TMP_CONFIG="$(mktemp "${PROJECT_DIR}/.lab7-balanced.XXXXXX.yaml")"
trap 'rm -f -- "${TMP_CONFIG}"' EXIT

cd "${PROJECT_DIR}"
python3 - config.yaml "${TMP_CONFIG}" 45 58 <<'PY'
import re, sys
source, output, util, density = sys.argv[1:]
text = open(source, encoding="utf-8").read()
text = re.sub(r"(?m)^FP_CORE_UTIL:\s*.*$", f"FP_CORE_UTIL: {util}", text)
text = re.sub(r"(?m)^PL_TARGET_DENSITY_PCT:\s*.*$",
              f"PL_TARGET_DENSITY_PCT: {density}", text)
open(output, "w", encoding="utf-8").write(text)
PY
librelane --run-tag lab7_balanced --to OpenROAD.DetailedPlacement "${TMP_CONFIG}"
