# Lab 6 — Synthesis and Static Timing Analysis

A complete LibreLane lab using `config.yaml`, SKY130A, Yosys synthesis, and OpenROAD pre-PnR STA.

## Project contents

- `src/synth_sta_top.sv` — synthesizable multiply-accumulate datapath
- `tb/tb_synth_sta_top.sv` — self-checking SystemVerilog testbench
- `constraints/synth_sta_top.sdc` — clock and I/O timing constraints
- `config.yaml` — LibreLane Classic-flow configuration
- `Makefile` — lint, simulation, STA, synthesis exploration, and full-flow targets
- `scripts/collect_results.py` — finds timing metrics, reports, and netlists
- `run_lab.sh` — executes the normal lab sequence

## Requirements

Enter a LibreLane environment where `librelane` is available. Verilator is also required for `make lint` and `make sim`.

Check the setup:

```bash
make check
librelane --version
```

## Quick start

```bash
make lint
make sim
make sta
make reports
```

Or run the same sequence with:

```bash
./run_lab.sh
```

The default target PDK is `ihp-sg13g2`. Override variables when needed:

```bash
make sta PDK=ihp-sg13g2 RUN_TAG=lab6_test JOBS=4
```

## Full RTL-to-GDSII run

```bash
make run
```

## Synthesis strategy comparison

```bash
make synth-explore
```

This invokes LibreLane's `SynthesisExploration` flow and compares supported `AREA` and `DELAY` ABC strategies.

## Expected simulation result

```text
PASS: 4 output transactions checked
```

A waveform is written to `build/lab6.vcd`.

## Key timing assumptions

- Clock: `clk_i`
- Period: 10.000 ns (100 MHz)
- Clock uncertainty: 0.250 ns
- Input delay: 2.000 ns
- Output delay: 4.000 ns
- Output load: 0.033442 library capacitance units
- `rst_ni` is asynchronous and excluded from synchronous data-path analysis

## Important notes

1. Keep `CLOCK_PERIOD` in `config.yaml` consistent with `create_clock` in the SDC file.
2. `RT_MIN_LAYER` and `RT_MAX_LAYER` use SKY130 names. Remove or change them when porting to another PDK.
3. Pre-PnR STA is an early timing estimate. Final timing must be checked after CTS, routing, and parasitic extraction.
4. If a LibreLane release changes a step identifier, run `librelane --help` and inspect the installed Classic-flow step list.
