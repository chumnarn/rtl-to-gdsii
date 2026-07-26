#!/usr/bin/env bash
set -euo pipefail

RUN_TAG="${RUN_TAG:-lab6_ihp}"
JOBS="${JOBS:-1}"

echo "=== Lab 6: IHP SG13G2 Synthesis and STA ==="
make check
make tools
make lint
make sim
make sta RUN_TAG="${RUN_TAG}" JOBS="${JOBS}"
make reports RUN_TAG="${RUN_TAG}"

echo
echo "PASS: Lab flow completed"
echo "Read: reports/${RUN_TAG}_summary.md"
