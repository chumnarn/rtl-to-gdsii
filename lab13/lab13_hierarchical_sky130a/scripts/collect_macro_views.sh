#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
    echo "Usage: $0 <counter_macro|accumulator_macro> [run-directory]" >&2
    exit 2
}

[[ $# -ge 1 && $# -le 2 ]] || usage
macro="$1"
case "$macro" in
    counter_macro|accumulator_macro) ;;
    *) usage ;;
esac

runs_dir="$ROOT/blocks/$macro/runs"
if [[ $# -eq 2 ]]; then
    run_dir="$(realpath "$2")"
else
    [[ -d "$runs_dir" ]] || { echo "No runs directory: $runs_dir" >&2; exit 1; }
    run_dir="$(find "$runs_dir" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' | sort -nr | head -1 | cut -d' ' -f2-)"
fi
[[ -n "${run_dir:-}" && -d "$run_dir" ]] || { echo "Cannot determine run directory" >&2; exit 1; }

echo "Collecting $macro views from: $run_dir"
dest="$ROOT/macros/$macro"
mkdir -p "$dest"/{gds,lef,nl,pnl,spef,lib,spice}

find_best() {
    local pattern="$1"
    find "$run_dir" -type f -name "$pattern" -printf '%p\n' \
      | awk 'BEGIN{best=""} /\/final\//{print; found=1} !found{fallback[NR]=$0} END{if(!found) for(i=1;i<=NR;i++) if(fallback[i]!=""){print fallback[i]; exit}}' \
      | head -1
}

copy_required() {
    local pattern="$1" out="$2" src
    src="$(find_best "$pattern")"
    [[ -n "$src" ]] || { echo "Required view missing: $pattern" >&2; exit 1; }
    cp -f "$src" "$out"
    echo "  [OK] $(basename "$out") <- $src"
}

copy_optional() {
    local pattern="$1" out="$2" src
    src="$(find_best "$pattern")"
    if [[ -n "$src" ]]; then
        cp -f "$src" "$out"
        echo "  [OK] $(basename "$out") <- $src"
    else
        echo "  [SKIP] $pattern"
    fi
}

copy_required "${macro}.gds" "$dest/gds/${macro}.gds"
copy_required "${macro}.lef" "$dest/lef/${macro}.lef"
copy_optional "${macro}.nl.v" "$dest/nl/${macro}.nl.v"
copy_optional "${macro}.pnl.v" "$dest/pnl/${macro}.pnl.v"
copy_optional "${macro}.spef" "$dest/spef/${macro}.spef"
copy_optional "${macro}*.lib" "$dest/lib/${macro}.lib"
copy_optional "${macro}.spice" "$dest/spice/${macro}.spice"

printf '%s\n' "$run_dir" > "$dest/SOURCE_RUN.txt"
