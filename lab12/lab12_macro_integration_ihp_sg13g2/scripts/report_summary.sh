#!/usr/bin/env bash
set -euo pipefail

MACRO_RUN_DIR="${MACRO_RUN_DIR:-}"
TOP_RUN_DIR="${TOP_RUN_DIR:-}"

print_run() {
    local title="$1"
    local dir="$2"

    echo
    echo "============================================================"
    echo "${title}"
    echo "============================================================"

    if [[ ! -d "${dir}" ]]; then
        echo "[WARN] Run directory not found: ${dir}"
        return
    fi

    echo "Run directory: ${dir}"

    echo
    echo "Final physical views:"
    find "${dir}" -type f \
        \( -iname "*.gds" -o -iname "*.lef" -o -iname "*.def" -o -iname "*.odb" \) \
        | sort | tail -n 20 | sed 's/^/  /'

    echo
    echo "Timing/metrics summaries:"
    find "${dir}" -type f \
        \( -iname "*metrics*.csv" -o -iname "*metrics*.json" \
           -o -iname "*wns*" -o -iname "*tns*" -o -iname "*summary*" \) \
        | sort | tail -n 20 | sed 's/^/  /'

    echo
    echo "Potential errors/warnings of interest:"
    grep -RihE \
        --include='*.log' --include='*.rpt' \
        'ERROR|violation|overflow|unconnected|disconnected|blackbox|macro' \
        "${dir}" 2>/dev/null \
        | tail -n 30 \
        | sed 's/^/  /' || true
}

print_run "MACRO HARDENING" "${MACRO_RUN_DIR}"
print_run "TOP-LEVEL MACRO INTEGRATION" "${TOP_RUN_DIR}"

echo
echo "============================================================"
echo "COLLECTED MACRO VIEWS"
echo "============================================================"
find macros/counter_macro -type f -maxdepth 3 \
    -printf '  %p (%s bytes)\n' 2>/dev/null | sort || true
