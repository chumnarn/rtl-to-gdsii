#!/usr/bin/env bash
set -euo pipefail

mode="${1:-views}"

case "${mode}" in
    views)
        lef="macros/counter_macro/lef/counter_macro.lef"
        nl="macros/counter_macro/nl/counter_macro.nl.v"

        grep -Eq '^[[:space:]]*MACRO[[:space:]]+counter_macro[[:space:]]*$' "${lef}" \
            || { echo "[ERROR] counter_macro not found in LEF"; exit 1; }

        grep -Eq 'module[[:space:]]+counter_macro([[:space:]]|\()' "${nl}" \
            || { echo "[ERROR] counter_macro module not found in netlist"; exit 1; }

        for pin in VDD VSS clk_i rst_ni; do
            grep -Eq "^[[:space:]]*PIN[[:space:]]+${pin}[[:space:]]*$" "${lef}" \
                || { echo "[ERROR] LEF pin missing: ${pin}"; exit 1; }
        done

        echo "[OK] Macro master and required pins verified."
        ;;

    run)
        run_dir="${TOP_RUN_DIR:?TOP_RUN_DIR is required}"
        if [[ ! -d "${run_dir}" ]]; then
            echo "[ERROR] Top run directory not found: ${run_dir}"
            exit 1
        fi

        matches="$(grep -RIl \
            --include='*.v' --include='*.def' --include='*.odb' \
            'u_counter_macro' "${run_dir}" 2>/dev/null || true)"

        if [[ -z "${matches}" ]]; then
            echo "[ERROR] u_counter_macro not found in generated netlist/DEF text views."
            echo "        Inspect: ${run_dir}"
            exit 1
        fi

        echo "[OK] u_counter_macro found in:"
        printf '%s\n' "${matches}" | sed 's/^/  /'
        ;;

    *)
        echo "Usage: $0 {views|run}"
        exit 2
        ;;
esac
