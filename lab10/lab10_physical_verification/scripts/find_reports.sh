#!/usr/bin/env bash
set -euo pipefail

RUNS_DIR="${1:-runs}"

if [[ ! -d "${RUNS_DIR}" ]]; then
    echo "ERROR: ${RUNS_DIR} does not exist." >&2
    exit 1
fi

RUN_DIR="$(
    find "${RUNS_DIR}" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' \
    | sort -n \
    | tail -1 \
    | cut -d' ' -f2-
)"

if [[ -z "${RUN_DIR}" ]]; then
    echo "ERROR: no run directory found in ${RUNS_DIR}." >&2
    exit 1
fi

echo "Latest run: ${RUN_DIR}"
echo
find "${RUN_DIR}" -type f \
    \( -iname '*drc*' -o -iname '*lvs*' -o -iname '*xor*' \
       -o -iname '*violation*' -o -iname '*.gds' -o -iname '*.spice' \) \
    -print | sort
