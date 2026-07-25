#!/usr/bin/env bash
# Source this file if desired:
#   source env.sh

export LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PDK_ROOT="${PDK_ROOT:-${LAB_ROOT}/IHP-Open-PDK}"
export PDK="${PDK:-ihp-sg13g2}"
export PDK_COMMIT="${PDK_COMMIT:-3b5a704ba6738aa686b08706187830e6284d2a10}"

echo "LAB_ROOT=${LAB_ROOT}"
echo "PDK_ROOT=${PDK_ROOT}"
echo "PDK=${PDK}"
echo "PDK_COMMIT=${PDK_COMMIT}"
