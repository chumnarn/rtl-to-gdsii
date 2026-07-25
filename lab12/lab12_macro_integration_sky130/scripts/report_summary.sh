#!/usr/bin/env bash
set -euo pipefail

print_run() {
    local title="$1"
    local dir="$2"

    echo
    echo "============================================================"
    echo "${title}"
    echo "============================================================"

    if [[ ! -d "${dir}" ]]; then
        echo "[WARN] Missing run directory: ${dir}"
        return
    fi

    echo "Physical views:"
    find "${dir}" -type f \
        \( -iname "*.gds" -o -iname "*.lef" \
           -o -iname "*.def" -o -iname "*.odb" \) \
        | sort | tail -n 20 | sed 's/^/  /'

    echo
    echo "Metrics and reports:"
    find "${dir}" -type f \
        \( -iname "*metrics*.csv" -o -iname "*metrics*.json" \
           -o -iname "*wns*" -o -iname "*tns*" \
           -o -iname "*summary*" \) \
        | sort | tail -n 20 | sed 's/^/  /'

    echo
    echo "Relevant log lines:"
    grep -RihE \
        --include='*.log' --include='*.rpt' \
        'ERROR|violation|overflow|unconnected|disconnected|blackbox|macro' \
        "${dir}" 2>/dev/null \
        | tail -n 30 | sed 's/^/  /' || true
}

print_run "MACRO HARDENING" "${MACRO_RUN_DIR:-}"
print_run "TOP-LEVEL INTEGRATION" "${TOP_RUN_DIR:-}"

echo
echo "============================================================"
echo "COLLECTED MACRO VIEWS"
echo "============================================================"
find macros/counter_macro -maxdepth 3 -type f \
    -printf '  %p (%s bytes)\n' 2>/dev/null | sort || true
