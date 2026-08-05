#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

make check
make lint
make sim
make sta PDK="${PDK:-ihp-sg13g2}" RUN_TAG="${RUN_TAG:-lab6}" JOBS="${JOBS:-1}"
make reports
