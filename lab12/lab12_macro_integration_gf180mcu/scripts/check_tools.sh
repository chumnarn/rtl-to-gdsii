#!/usr/bin/env bash
set -euo pipefail

PDK_ROOT="${PDK_ROOT:?PDK_ROOT is required}"
PDK="${PDK:-gf180mcuD}"
SCL="${SCL:-gf180mcu_fd_sc_mcu7t5v0}"

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

pdk_candidates=(
    "${PDK_ROOT}/${PDK}"
    "${PDK_ROOT}/volare/${PDK}"
    "${PDK_ROOT}/gf180mcu/versions/${PDK}"
)

found_pdk=""
for candidate in "${pdk_candidates[@]}"; do
    if [[ -d "${candidate}" ]]; then
        found_pdk="${candidate}"
        break
    fi
done

if [[ -n "${found_pdk}" ]]; then
    echo "[OK] PDK candidate: ${found_pdk}"
else
    echo "[WARN] Could not confirm the PDK directory using common layouts."
    echo "       PDK_ROOT=${PDK_ROOT}"
    echo "       PDK=${PDK}"
    echo "       LibreLane may still resolve it through ciel."
fi

if find "${PDK_ROOT}" -type d -name "${SCL}" -print -quit 2>/dev/null \
    | grep -q .; then
    echo "[OK] SCL found: ${SCL}"
else
    echo "[WARN] Could not confirm SCL directory: ${SCL}"
    echo "       Continue if LibreLane's PDK config supplies this SCL."
fi

if (( errors > 0 )); then
    exit 1
fi
