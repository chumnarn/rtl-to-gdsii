#!/usr/bin/env bash
set -euo pipefail

RUN_DIR="${1:-}"

if [[ -z "${RUN_DIR}" ]]; then
    if [[ ! -d runs ]]; then
        echo "ERROR: runs/ does not exist. Run LibreLane first." >&2
        exit 1
    fi
    RUN_DIR="$(find runs -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' \
        | sort -nr | head -1 | cut -d' ' -f2-)"
fi

if [[ -z "${RUN_DIR}" || ! -d "${RUN_DIR}" ]]; then
    echo "ERROR: LibreLane run directory not found: ${RUN_DIR}" >&2
    exit 1
fi

search_group() {
    local title="$1"
    local pattern="$2"
    echo
    echo "== ${title} =="
    grep -RniE --include='*.log' --include='*.rpt' --include='*.txt' \
        "${pattern}" "${RUN_DIR}" 2>/dev/null | head -40 || true
}

echo "LibreLane CTS summary"
echo "Run: ${RUN_DIR}"

search_group "CTS statistics" \
    'clock roots|buffers inserted|clock subnets|clock sinks|number of sinks'
search_group "Clock skew and latency" \
    'clock skew|skew|clock latency|insertion delay|arrival time'
search_group "Setup timing" \
    'setup violation|setup slack|worst negative slack|wns|tns'
search_group "Hold timing" \
    'hold violation|hold slack|min slack'
search_group "Electrical checks" \
    'max transition|slew violation|max capacitance|capacitance violation|max fanout'
search_group "Warnings and errors" \
    'warning|error|failed|fatal|unplaced|illegal|congestion'
