#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PDK="${PDK:-sky130A}"

cd "$ROOT"
python3 scripts/make_experiments.py

for config in experiments/config_density_*.yaml experiments/config_die_*.yaml experiments/config_obstructions.yaml; do
    echo "================================================================"
    echo "LibreLane configuration: $config"
    echo "PDK: $PDK"
    echo "================================================================"
    librelane --pdk "$PDK" "$config"
done
