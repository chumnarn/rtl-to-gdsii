# Lab 15 Command Sequence

```bash
# 1. Enter a LibreLane environment
librelane --version
echo "$PDK_ROOT"

# 2. Verify PDK and download/check bondpad
make prepare

# 3. Tool and RTL checks
make preflight

# 4. Synthesis
make synth

# 5. Floorplan
make floorplan
make openroad

# 6. Pad ring
make padring
make openroad

# 7. Complete RTL-to-GDSII
make run

# 8. Reports and layout
make reports
find runs -type f -name '*.gds' -print
make klayout
```

## Direct LibreLane commands

```bash
librelane --pdk ihp-sg13g2 --flow Chip \
  --tag lab15_ihp_fullchip_synth \
  --to Yosys.Synthesis config.yaml

librelane --pdk ihp-sg13g2 --flow Chip \
  --tag lab15_ihp_fullchip_floorplan \
  --to OpenROAD.Floorplan config.yaml

librelane --pdk ihp-sg13g2 --flow Chip \
  --tag lab15_ihp_fullchip_padring \
  --to OpenROAD.PadRing config.yaml

librelane --pdk ihp-sg13g2 --flow Chip \
  --tag lab15_ihp_fullchip config.yaml
```

## Debug searches

```bash
grep -RniE 'error|fatal|unknown module|unmapped' runs | head -100
grep -RniE 'PAD-|PadRing|site.*not found|master.*not found' runs | tail -100
grep -RniE 'PDN-|PSM-|unconnected' runs | tail -100
grep -RniE 'WNS|TNS|slack' runs | tail -100
grep -RniE 'DRC|LVS|circuits match|mismatch' runs | tail -150
```
