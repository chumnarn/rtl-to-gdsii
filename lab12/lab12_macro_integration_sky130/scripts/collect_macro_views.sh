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
    local ext="$1"
    local result=""

    if [[ -n "${FINAL_DIR}" && -d "${FINAL_DIR}" ]]; then
        result="$(find "${FINAL_DIR}" -type f -iname "*.${ext}" \
            | grep -E "/${MACRO_NAME}(\.|/)|${MACRO_NAME}\.${ext}$" \
            | sort | head -n 1 || true)"
        if [[ -z "${result}" ]]; then
            result="$(find "${FINAL_DIR}" -type f -iname "*.${ext}" \
                | sort | head -n 1 || true)"
        fi
    fi

    if [[ -z "${result}" && -d "${RUN_DIR}" ]]; then
        result="$(find "${RUN_DIR}" -type f -iname "*.${ext}" \
            | grep -E "/final/|KLayout.StreamOut|OpenROAD.Write" \
            | sort | tail -n 1 || true)"
    fi

    printf '%s' "${result}"
}

copy_required() {
    local ext="$1"
    local output="$2"
    local source
    source="$(find_view "${ext}")"

    if [[ -z "${source}" || ! -s "${source}" ]]; then
        echo "[ERROR] Cannot find non-empty .${ext} view"
        echo "        RUN_DIR=${RUN_DIR}"
        echo "        FINAL_DIR=${FINAL_DIR}"
        exit 1
    fi

    cp -f "${source}" "${output}"
    echo "[OK] ${source}"
    echo "  -> ${output}"
}

copy_required gds "${DEST_DIR}/gds/${MACRO_NAME}.gds"
copy_required lef "${DEST_DIR}/lef/${MACRO_NAME}.lef"

netlist=""
for base in "${FINAL_DIR}" "${RUN_DIR}"; do
    [[ -n "${base}" && -d "${base}" ]] || continue
    netlist="$(find "${base}" -type f \
        \( -iname "*.nl.v" -o -iname "*.pnl.v" -o -iname "*.v" \) \
        | grep -vE '/src/|\.vh$' \
        | grep -E 'final|Yosys|OpenROAD|nl\.v|pnl\.v' \
        | sort | tail -n 1 || true)"
    [[ -n "${netlist}" ]] && break
done

if [[ -z "${netlist}" || ! -s "${netlist}" ]]; then
    echo "[ERROR] Cannot find generated macro netlist"
    exit 1
fi

cp -f "${netlist}" "${DEST_DIR}/nl/${MACRO_NAME}.nl.v"
cp -f "$(dirname "$0")/../top/src/counter_macro.vh" \
      "${DEST_DIR}/vh/${MACRO_NAME}.vh"

echo "[OK] ${netlist}"
echo "  -> ${DEST_DIR}/nl/${MACRO_NAME}.nl.v"

echo
find "${DEST_DIR}" -maxdepth 2 -type f \
    -printf '  %p (%s bytes)\n' | sort
