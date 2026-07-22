#!/usr/bin/env bash
set -euo pipefail

if [[ ! -d runs ]]; then
    echo "ERROR: runs/ does not exist." >&2
    exit 1
fi

latest="$(
    find runs -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' \
    | sort -nr | head -1 | cut -d' ' -f2-
)"

if [[ -z "$latest" ]]; then
    echo "ERROR: no LibreLane run directory found." >&2
    exit 1
fi

printf '%s\n' "$latest"
