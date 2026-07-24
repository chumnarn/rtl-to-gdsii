# Lab 15 — Full-Chip Design with I/O Pads for IHP SG13G2

LibreLane `Chip` flow example implementing an 8-bit counter as a complete
pad-wrapped chip.

## Main cells

- `sg13g2_IOPadIn`: clock, reset and enable pads
- `sg13g2_IOPadOut30mA`: eight counter output pads
- `sg13g2_IOPadVdd` / `sg13g2_IOPadVss`: core supply pads
- `sg13g2_IOPadIOVdd` / `sg13g2_IOPadIOVss`: I/O supply pads
- `bondpad_70x70_novias`: 70 µm bondpad from the official IHP LibreLane template
- `sg13g2_stdcell`: digital standard-cell library

## Requirements

- LibreLane with the `Chip` flow
- IHP PDK enabled as `ihp-sg13g2`
- `PDK_ROOT` set by the Nix/container environment
- Network access during `make prepare` only when the bondpad GDS is not present

## Fast start

```bash
unzip lab15_ihp_sg13g2_fullchip.zip
cd lab15_ihp_sg13g2_fullchip

make preflight
make synth
make floorplan
make padring
make run
make reports
```

Open the latest database/layout:

```bash
make openroad
make klayout
```

## Clock and floorplan

- Clock period: `20 ns` or `50 MHz`
- External clock port: `clk_PAD`
- Internal clock root: `clk_pad/p2c`
- Die area: `1600 × 1600 µm`
- Core area: `(365,365)` to `(1235,1235) µm`

## Important

The IHP Open PDK is an experimental-preview open-source PDK. A successful
teaching run still requires reviewing all generated DRC, LVS, antenna,
density and timing reports before treating a result as fabrication-ready.
