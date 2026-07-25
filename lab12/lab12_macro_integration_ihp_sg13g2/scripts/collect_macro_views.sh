#!/usr/bin/env bash
set -euo pipefail

MACRO_NAME="counter_macro"
RUN_DIR="${MACRO_RUN_DIR:?MACRO_RUN_DIR is required}"
FINAL_DIR="${MACRO_FINAL_DIR:-}"
DEST_DIR="${DEST_DIR:?DEST_DIR is required}"

mkdir -p \
    "${DEST_DIR}/gds" \
    "${DEST_DIR}/lef" \
    "${DEST_DIR}/nl" \
    "${DEST_DIR}/vh"

find_view() {
    local extension="$1"
    local result=""

    if [[ -n "${FINAL_DIR}" && -d "${FINAL_DIR}" ]]; then
        result="$(find "${FINAL_DIR}" -type f -iname "*.${extension}" \
            | grep -E "/${MACRO_NAME}(\.|/)|${MACRO_NAME}\.${extension}$" \
            | sort | head -n 1 || true)"
        if [[ -z "${result}" ]]; then
            result="$(find "${FINAL_DIR}" -type f -iname "*.${extension}" \
                | sort | head -n 1 || true)"
        fi
    fi

    if [[ -z "${result}" && -d "${RUN_DIR}" ]]; then
        result="$(find "${RUN_DIR}" -type f -iname "*.${extension}" \
            | grep -E "/final/|/KLayout.StreamOut/|/OpenROAD.Write" \
            | sort | tail -n 1 || true)"
    fi

    printf '%s' "${result}"
}

copy_required() {
    local extension="$1"
    local output="$2"
    local source
    source="$(find_view "${extension}")"

    if [[ -z "${source}" || ! -s "${source}" ]]; then
        echo "[ERROR] Cannot find non-empty .${extension} view"
        echo "        RUN_DIR=${RUN_DIR}"
        echo "        FINAL_DIR=${FINAL_DIR}"
        exit 1
    fi

    cp -f "${source}" "${output}"
    echo "[OK] ${source}"
    echo "  -> ${output}"
}

copy_required "gds" "${DEST_DIR}/gds/${MACRO_NAME}.gds"
copy_required "lef" "${DEST_DIR}/lef/${MACRO_NAME}.lef"

netlist=""
if [[ -n "${FINAL_DIR}" && -d "${FINAL_DIR}" ]]; then
    netlist="$(find "${FINAL_DIR}" -type f \
        \( -iname "*.nl.v" -o -iname "*.pnl.v" -o -iname "*.v" \) \
        | grep -vE '/src/|\.vh$' \
        | sort | head -n 1 || true)"
fi

if [[ -z "${netlist}" && -d "${RUN_DIR}" ]]; then
    netlist="$(find "${RUN_DIR}" -type f \
        \( -iname "*.nl.v" -o -iname "*.pnl.v" -o -iname "*.v" \) \
        | grep -E 'Yosys|final|OpenROAD' \
        | grep -vE '\.vh$' \
        | sort | tail -n 1 || true)"
fi

if [[ -z "${netlist}" || ! -s "${netlist}" ]]; then
    echo "[ERROR] Cannot find a generated macro Verilog netlist."
    exit 1
fi

cp -f "${netlist}" "${DEST_DIR}/nl/${MACRO_NAME}.nl.v"
echo "[OK] ${netlist}"
echo "  -> ${DEST_DIR}/nl/${MACRO_NAME}.nl.v"

cp -f "$(dirname "$0")/../top/src/counter_macro.vh" \
      "${DEST_DIR}/vh/${MACRO_NAME}.vh"

echo
echo "Collected macro views:"
find "${DEST_DIR}" -type f -maxdepth 2 -printf '  %p (%s bytes)\n' | sort
