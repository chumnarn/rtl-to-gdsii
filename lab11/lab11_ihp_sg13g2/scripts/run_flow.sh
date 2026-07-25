#!/usr/bin/env bash
set -euo pipefail

config="${1:-config.yaml}"
tag="${2:-baseline}"
shift $(( $# >= 2 ? 2 : $# ))

command -v librelane >/dev/null 2>&1 || {
    echo "ERROR: librelane is not in PATH. Enter the LibreLane Nix shell first." >&2
    exit 127
}
[[ -f "$config" ]] || { echo "ERROR: configuration not found: $config" >&2; exit 2; }

pdk="${PDK:-ihp-sg13g2}"
pdk_root="${PDK_ROOT:-$(pwd)/IHP-Open-PDK}"

if [[ ! -d "$pdk_root/$pdk" ]]; then
    echo "ERROR: PDK not found at $pdk_root/$pdk" >&2
    echo "Run: make clone-pdk" >&2
    exit 2
fi

mkdir -p logs
set -o pipefail
librelane \
    "$config" \
    --pdk "$pdk" \
    --pdk-root "$pdk_root" \
    --manual-pdk \
    --run-tag "$tag" \
    "$@" \
    2>&1 | tee "logs/${tag}-console.log"
