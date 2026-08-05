#!/usr/bin/env bash
# Sweep global-routing capacity adjustment using complete generated YAML files.
set -euo pipefail

pdk="${PDK:-ihp-sg13g2}"
jobs="${JOBS:-4}"
mkdir -p build/experiments

for adjustment in 0.20 0.30 0.45; do
    suffix=${adjustment/./p}
    cfg="build/experiments/config-grt-${suffix}.yaml"
    tag="lab09-ihp-grt-adjust-${suffix}"

    awk -v value="$adjustment" '
        /^GRT_ADJUSTMENT:/ { print "GRT_ADJUSTMENT: " value; next }
        { print }
    ' config.yaml > "$cfg"

    echo "=== IHP SG13G2: GRT_ADJUSTMENT=$adjustment, tag=$tag ==="
    librelane -j "$jobs" --pdk "$pdk" --run-tag "$tag" \
        --to OpenROAD.DetailedRouting "$cfg"
done
