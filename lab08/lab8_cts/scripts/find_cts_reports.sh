#!/usr/bin/env bash
set -euo pipefail

RUN_DIR="${1:-}"

if [[ -z "${RUN_DIR}" ]]; then
    if [[ ! -d runs ]]; then
        echo "ERROR: runs/ does not exist. Run LibreLane first." >&2
        exit 1
    fi
    RUN_DIR="$(find runs -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' \
        | sort -nr | head -1 | cut -d' ' -f2-)"
fi

if [[ -z "${RUN_DIR}" || ! -d "${RUN_DIR}" ]]; then
    echo "ERROR: LibreLane run directory not found: ${RUN_DIR}" >&2
    exit 1
fi

echo "Run directory: ${RUN_DIR}"
echo
echo "CTS-related reports and artifacts"
find "${RUN_DIR}" -type f \
    \( -iname '*cts*' -o -iname '*clock*' -o -iname '*timing*' \
       -o -iname '*metrics*.json' \) \
    | sort
