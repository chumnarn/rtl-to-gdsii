# Lab 11 Command Sheet — IHP SG13G2

```bash
# Setup
make env
make clone-pdk
make validate

# RTL
make lint
make sim
make synth

# Flow control
make flow RUN_TAG=baseline
make synthesis-only
make floorplan
make placement
make cts
make routing

# Experiments
make density25
make small-core
make clk25
make compare A=baseline B=density25

# Intentional failure and debug
make bad-clock || true
make inspect RUN_TAG=bad_clock
make errors RUN_TAG=bad_clock

# Signoff-control exercises
make nodrc
make magic-drc
make klayout-drc

# Reports and reproduction
make inspect RUN_TAG=baseline
make errors RUN_TAG=baseline
make metrics RUN_TAG=baseline
make reproduce RUN_TAG=baseline

# GUI
make open-klayout
make open-openroad

# Cleanup
make clean
make distclean
```
