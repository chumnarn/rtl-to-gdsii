# Lab 12: Macro Integration with LibreLane and SKY130

Lab นี้สาธิต hierarchical physical design ด้วย LibreLane แบบสองขั้นตอน:

1. Harden RTL `counter_macro` เป็น hard macro
2. รวบรวม LEF, GDS และ gate-level netlist
3. Instantiate hard macro ใน `macro_wrapper`
4. รัน top-level RTL-to-GDSII ด้วย `MACROS` ใน `config.yaml`

## Target

```text
PDK                   = sky130A
Standard-cell library = sky130_fd_sc_hd
Power/Ground          = VPWR / VGND
Clock period          = 20 ns
```

ค่าทั้งหมดสามารถ override ผ่าน Makefile:

```bash
make all \
  PDK_ROOT="$HOME/.ciel" \
  PDK=sky130A \
  SCL=sky130_fd_sc_hd
```

## โครงสร้าง

```text
lab12_macro_integration_sky130/
├── Makefile
├── env.sh
├── macro/
│   ├── config.yaml
│   ├── constraints.sdc
│   └── src/counter_macro.sv
├── top/
│   ├── config.yaml
│   ├── constraints.sdc
│   └── src/
│       ├── counter_macro.vh
│       └── macro_wrapper.sv
├── macros/counter_macro/
│   ├── gds/
│   ├── lef/
│   ├── nl/
│   └── vh/
└── scripts/
    ├── check_tools.sh
    ├── collect_macro_views.sh
    ├── preflight.py
    ├── report_summary.sh
    └── verify_macro_instance.sh
```

## เริ่มต้นอย่างเร็ว

```bash
unzip lab12_macro_integration_sky130.zip
cd lab12_macro_integration_sky130

export PDK_ROOT="$HOME/.ciel"
export PDK=sky130A
export SCL=sky130_fd_sc_hd

make check
make all
make summary
```

## คำสั่งหลัก

```bash
make help
make check
make macro
make collect
make top
make all
make summary
make open-macro
make open-top
make klayout-top
make clean-runs
make distclean
```

## ลำดับของ make all

```text
Static preflight
      │
      ▼
Harden counter_macro
      │
      ├── counter_macro.gds
      ├── counter_macro.lef
      └── counter_macro.nl.v
      │
      ▼
Collect and verify views
      │
      ▼
Integrate u_counter_macro
      │
      ▼
Verify netlist/DEF/final GDS
```

## Run tags

```bash
make macro MACRO_RUN_TAG=macro_v2
make collect MACRO_RUN_TAG=macro_v2
make top TOP_RUN_TAG=top_v2
```

ค่าเริ่มต้น:

```text
MACRO_RUN_TAG = macro_harden
TOP_RUN_TAG   = macro_integration
```

## Views ที่ต้องได้

หลัง `make collect`:

```text
macros/counter_macro/gds/counter_macro.gds
macros/counter_macro/lef/counter_macro.lef
macros/counter_macro/nl/counter_macro.nl.v
macros/counter_macro/vh/counter_macro.vh
```

## Macro Integration Contract

Top-level RTL instantiate:

```systemverilog
counter_macro u_counter_macro (...);
```

ดังนั้น `top/config.yaml` ต้องมี:

```yaml
MACROS:
  counter_macro:
    instances:
      u_counter_macro:
```

และเชื่อม power grid:

```yaml
PDN_MACRO_CONNECTIONS:
  - "u_counter_macro VPWR VGND VPWR VGND"
```

## Timing Model

Lab นี้เน้น physical macro integration จึงใช้:

- LEF
- GDS
- Verilog black-box header
- Gate-level netlist

ไม่ได้บังคับ Liberty/SPEF ของ Macro เพื่อให้สร้างตัวอย่างทั้งหมดได้ด้วย open-source flow ชุดเดียว

สำหรับ hierarchical timing signoff จริงควรเพิ่ม:

- Liberty หลาย PVT corners
- SPEF หลาย corners
- Powered netlist
- SDF
- SPICE/CDL
- Macro DRC/LVS signoff reports

## Troubleshooting

### ไม่พบ PDK

```bash
echo "$PDK_ROOT"
find "$PDK_ROOT" -maxdepth 4 -type d -name sky130A
```

จากนั้น:

```bash
make check PDK_ROOT=/path/to/pdk-root
```

### ไม่พบ standard-cell library

```bash
find "$PDK_ROOT" -type d -name sky130_fd_sc_hd
```

หรือปล่อยให้ PDK ใช้ SCL ค่าเริ่มต้น:

```bash
make macro SCL=sky130_fd_sc_hd
```

### Macro views ไม่พบหลัง hardening

```bash
make summary-macro
find macro/runs/macro_harden -type f | sort
```

### Macro instance ถูก optimize ทิ้ง

```bash
grep -R "u_counter_macro" top/runs/macro_integration \
  --include='*.v' --include='*.def'
```

Macro outputs ต้องเชื่อมกับ top-level output หรือ logic ที่ใช้งานจริง

### Power pins ไม่ตรง

```bash
grep -nE 'PIN (VPWR|VGND)' \
  macros/counter_macro/lef/counter_macro.lef
```

ตรวจ configuration:

```yaml
VDD_NETS:
  - VPWR

GND_NETS:
  - VGND

PDN_MACRO_CONNECTIONS:
  - "u_counter_macro VPWR VGND VPWR VGND"
```

### Routing congestion รอบ Macro

เพิ่มพื้นที่หรือ halo:

```yaml
FP_MACRO_HORIZONTAL_HALO: 20
FP_MACRO_VERTICAL_HALO: 20
PL_TARGET_DENSITY_PCT: 25
```

## การทดลองเพิ่มเติม

1. เปลี่ยนตำแหน่ง Macro
2. เปลี่ยน orientation เป็น `S`, `FN` หรือ `FS`
3. เปรียบเทียบ halo 5, 10 และ 20 µm
4. เพิ่ม Macro instance ตัวที่สอง
5. เปรียบเทียบ WNS, TNS, wire length, congestion และ DRC
6. เพิ่ม Liberty/SPEF เพื่อทำ hierarchical STA
