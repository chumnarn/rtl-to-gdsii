# Lab 13 SKY130A — Command Sequence

```bash
unzip lab13_hierarchical_sky130a.zip
cd lab13_hierarchical_sky130a

make tools
make check
make lint
make sim

make counter
make accumulator
# หรือ: make macros

make collect
make check-macros
make top

# Optional เมื่อมี NL และ SPEF ครบ
make top-sta
```

รัน basic flow ด้วยคำสั่งเดียว:

```bash
make all
```

คำสั่ง LibreLane โดยตรง:

```bash
librelane --pdk sky130A blocks/counter_macro/config.yaml
librelane --pdk sky130A blocks/accumulator_macro/config.yaml
./scripts/collect_macro_views.sh counter_macro
./scripts/collect_macro_views.sh accumulator_macro
./scripts/check_macro_views.sh
librelane --pdk sky130A top/config.yaml
```
