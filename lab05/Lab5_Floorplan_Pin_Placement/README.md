# Lab 5 — Floorplan and Pin Placement with IHP SG13G2

This project is a small LibreLane Classic-flow design prepared specifically for
the `ihp-sg13g2` PDK.

## Directory structure

```text
Lab5_Floorplan_Pin_Placement_IHP_SG13G2/
├── config.yaml
├── Makefile
├── README.md
├── constraints/
│   ├── pin_order.cfg
│   ├── pnr.sdc
│   └── signoff.sdc
├── scripts/
│   ├── check_config.py
│   ├── check_pin_order.py
│   └── list_results.py
├── src/
│   └── floorplan_demo.sv
└── tb/
    └── tb_floorplan_demo.sv
```

## Prerequisites

- LibreLane with the IHP SG13G2 PDK enabled
- `PDK_ROOT` pointing to the PDK installation when required by the environment
- Verilator
- Icarus Verilog
- Python 3
- GNU Make

The official IHP template uses a Nix shell and installs/enables the PDK before
running LibreLane.

## Commands

```bash
make check-tools
make check
make synthesis
make floorplan
make results
```

Open the floorplan in OpenROAD:

```bash
make gui
```

Run the complete Classic flow:

```bash
make run
```

For a Docker-based LibreLane installation:

```bash
make floorplan LL_FLAGS=--dockerized
make run LL_FLAGS=--dockerized
```

## Floorplan

- Die: `300 um x 300 um`
- Core: `(20,20)` to `(280,280)`
- Core size: `260 um x 260 um`
- Margin: `20 um` per side
- Target placement density: `35%`

## Expected pin locations

| Side | Pins |
|---|---|
| North | `clk`, `rst_n`, `enable_i`, `load_i` |
| East | `data_i[0]` to `data_i[7]` |
| South | `terminal_o` |
| West | `count_o[0]` to `count_o[7]` |

## Why PDK defaults are retained

The configuration intentionally does not hard-code an IHP standard-cell library,
CTS buffer name, tap cell, routing layer name, or PDN layer. These values can
depend on the exact IHP PDK and LibreLane revision. Selecting:

```bash
librelane --pdk ihp-sg13g2 config.yaml
```

lets LibreLane use the compatible defaults packaged with that PDK revision.
