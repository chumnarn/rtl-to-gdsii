#!/usr/bin/env bash
set -euo pipefail

config="${1:-config.yaml}"
tag="${2:-baseline}"
shift $(( $# >= 2 ? 2 : $# ))

if ! command -v librelane >/dev/null 2>&1; then
    echo "ERROR: librelane is not in PATH." >&2
    exit 127
fi
if [[ ! -f "$config" ]]; then
    echo "ERROR: configuration not found: $config" >&2
    exit 2
fi

mkdir -p logs
set -o pipefail
librelane \
    --pdk "${PDK:-sky130A}" \
    --scl "${SCL:-sky130_fd_sc_hd}" \
    --run-tag "$tag" \
    "$@" \
    "$config" \
    2>&1 | tee "logs/${tag}-console.log"
