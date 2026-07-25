# Lab 13 command sequence — ihp-sg13g2

```bash
cd lab13_hierarchical_ihp_sg13g2

# 1) Environment and input checks
make tools
make check

# 2) RTL verification
make lint
make sim

# 3) Bottom-up hardening
librelane --pdk ihp-sg13g2 blocks/counter_macro/config.yaml
librelane --pdk ihp-sg13g2 blocks/accumulator_macro/config.yaml

# 4) Collect latest hard-macro views
./scripts/collect_macro_views.sh counter_macro
./scripts/collect_macro_views.sh accumulator_macro
./scripts/check_macro_views.sh

# 5) Top-level physical integration
librelane --pdk ihp-sg13g2 top/config.yaml

# 6) Optional hierarchical STA, when NL and SPEF exist
librelane --pdk ihp-sg13g2 top/config_hier_sta.yaml

# 7) Locate outputs
find blocks top -type f \
  \( -name '*.gds' -o -name '*.lef' -o -name '*.odb' \
     -o -name '*.spef' -o -name '*.nl.v' -o -name 'metrics.csv' \) \
  | sort
```
