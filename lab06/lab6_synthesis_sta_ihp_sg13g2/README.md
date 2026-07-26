# Lab 6: Synthesis and Static Timing Analysis

Target process: **IHP SG13G2**  
Flow: **LibreLane Classic**  
Configuration: **config.yaml**

## Project contents

```text
lab6_synthesis_sta_ihp_sg13g2/
├── config.yaml
├── config_5ns.yaml
├── Makefile
├── run_lab.sh
├── src/synth_sta_top.sv
├── tb/tb_synth_sta_top.sv
├── constraints/
│   ├── synth_sta_top.sdc
│   └── synth_sta_top_5ns.sdc
└── scripts/
    ├── check_project.py
    └── collect_results.py
```

## Prerequisites

The recommended IHP template uses a Nix environment. Enter the LibreLane
environment before running this project.

Verify:

```bash
librelane --version
verilator --version
iverilog -V
python3 --version
```

The LibreLane PDK identifier used by this project is:

```text
ihp-sg13g2
```

The PDK must be visible to LibreLane. In a conventional installation:

```bash
export PDK_ROOT="$HOME/.ciel"
test -d "$PDK_ROOT/ihp-sg13g2"
```

Do not manually set a standard-cell-library name in this Lab. LibreLane obtains
the compatible default library and technology files from the IHP PDK
configuration.

## Run the laboratory

```bash
make check
make tools
make lint
make sim
make sta
make reports
```

Or run all standard Lab steps:

```bash
chmod +x run_lab.sh
./run_lab.sh
```

Expected simulation result:

```text
PASS: 4 output transactions checked
```

## Main LibreLane command

```bash
librelane -j 1 \
  --flow Classic \
  --pdk ihp-sg13g2 \
  --run-tag lab6_ihp \
  --to OpenROAD.STAPrePNR \
  config.yaml
```

## Run the 5 ns experiment

```bash
make sta-5ns
make reports RUN_TAG=lab6_ihp_5ns
```

## Continue through the complete Classic flow

```bash
make run
```

For this Lab, success through `OpenROAD.STAPrePNR` is the required milestone.
A complete physical flow may expose version-specific PDK issues in later
placement, CTS, routing, DRC, or LVS steps; those belong to subsequent Labs.

## Common commands

```bash
make help
make list-steps
make sta JOBS=4 RUN_TAG=lab6_try1
make reports RUN_TAG=lab6_try1
find runs/lab6_try1 -type f | sort | less
grep -RniE "slack|wns|tns|startpoint|endpoint" runs/lab6_try1
```

## Important timing assumptions

- Clock: `clk_i`
- Period: 10 ns
- Frequency: 100 MHz
- Clock uncertainty: 0.25 ns
- Input delay: 2 ns
- Output delay: 4 ns
- Asynchronous reset: false path from `rst_ni`

## Troubleshooting

### PDK not found

```bash
echo "$PDK_ROOT"
find "$PDK_ROOT" -maxdepth 2 -type d -name "ihp-sg13g2"
```

Then retry:

```bash
make sta PDK=ihp-sg13g2
```

### `USE_SLANG` is unknown

Some older LibreLane releases may not expose `USE_SLANG`. The RTL in this Lab is
simple enough for ordinary SystemVerilog parsing. Remove this line from both
configuration files and rerun:

```yaml
USE_SLANG: true
```

### Step name differs

Inspect the installed flow:

```bash
make list-steps
```

If `OpenROAD.STAPrePNR` is unavailable, run the Classic flow and inspect the
first STA step produced by that release:

```bash
make run
```

### Synthesis strategy validation error

The supported strategy set can vary with LibreLane releases. Remove:

```yaml
SYNTH_STRATEGY: AREA 0
```

to use the PDK/flow default, or select a strategy listed by the installed
LibreLane configuration reference.
