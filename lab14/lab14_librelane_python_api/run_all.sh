#!/usr/bin/env bash
set -euo pipefail

export PDK="${PDK:-ihp-sg13g2}"

make check
make sim
make flows
make steps
make validate
make synth

echo
echo "Environment, simulation, API introspection, validation and synthesis passed."
echo "Run the complete flow with:"
echo "  make run TAG=lab14_ihp_full"
