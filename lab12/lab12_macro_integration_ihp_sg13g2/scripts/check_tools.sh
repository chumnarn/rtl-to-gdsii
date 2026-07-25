#!/usr/bin/env bash
set -euo pipefail

PDK_ROOT="${PDK_ROOT:?PDK_ROOT is required}"
PDK="${PDK:-ihp-sg13g2}"

errors=0

check_cmd() {
    local cmd="$1"
    if command -v "${cmd}" >/dev/null 2>&1; then
        echo "[OK] ${cmd}: $(command -v "${cmd}")"
    else
        echo "[ERROR] Missing command: ${cmd}"
        errors=$((errors + 1))
    fi
}

check_cmd python3
check_cmd make
check_cmd librelane

if [[ -d "${PDK_ROOT}/${PDK}" ]]; then
    echo "[OK] PDK directory: ${PDK_ROOT}/${PDK}"
elif [[ -d "${PDK_ROOT}" && "$(basename "${PDK_ROOT}")" == "${PDK}" ]]; then
    echo "[WARN] PDK_ROOT appears to point directly at the PDK."
    echo "       LibreLane manual-PDK normally expects: PDK_ROOT/PDK"
else
    echo "[ERROR] PDK directory not found: ${PDK_ROOT}/${PDK}"
    echo "        Run 'make clone-pdk' or set PDK_ROOT correctly."
    errors=$((errors + 1))
fi

if (( errors > 0 )); then
    exit 1
fi
