# Lab 12: Macro Integration with LibreLane and GF180MCU

Lab นี้เป็นตัวอย่าง hierarchical physical design ที่รันเป็นสอง flow:

1. Harden `counter_macro` จาก RTL เป็น hard macro
2. รวบรวม LEF, GDS และ gate-level netlist
3. Instantiate hard macro ใน `macro_wrapper`
4. รัน top-level RTL-to-GDSII ด้วย `MACROS` ใน `config.yaml`

## Target

```text
PDK                  = gf180mcuD
Standard-cell library = gf180mcu_fd_sc_mcu7t5v0
Power/Ground          = VDD / VSS
Clock period          = 20 ns
```

สามารถ override ค่าได้จาก command line:

```bash
make all \
  PDK_ROOT="$HOME/.ciel" \
  PDK=gf180mcuD \
  SCL=gf180mcu_fd_sc_mcu7t5v0
```

## โครงสร้าง

```text
lab12_macro_integration_gf180mcu/
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
unzip lab12_macro_integration_gf180mcu.zip
cd lab12_macro_integration_gf180mcu

export PDK_ROOT="$HOME/.ciel"
export PDK=gf180mcuD
export SCL=gf180mcu_fd_sc_mcu7t5v0

make check
make all
make summary
```

## ติดตั้ง PDK

LibreLane มักใช้ PDK ที่จัดการด้วย `ciel`:

```bash
make install-pdk
```

หากต้องการระบุ revision:

```bash
make install-pdk PDK_REVISION=<revision>
```

ตรวจสอบรายการ PDK ที่ติดตั้ง:

```bash
ciel list --pdk-root "$PDK_ROOT"
```

> รูปแบบคำสั่ง `ciel` อาจแตกต่างเล็กน้อยตามรุ่น ให้ใช้
> `ciel --help` และ `ciel enable --help` เมื่อ package manager รุ่นที่ติดตั้ง
> ต้องการ option เพิ่มเติม

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
make check
    │
    ▼
Harden counter_macro
    │
    ├── GDS
    ├── LEF
    └── gate-level netlist
    │
    ▼
Collect macro views
    │
    ▼
Verify cell name and pins
    │
    ▼
Integrate u_counter_macro
    │
    ▼
Verify top netlist / DEF / final GDS
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

## จุดสำคัญของ Macro Integration

Top-level RTL instantiate:

```systemverilog
counter_macro u_counter_macro (...);
```

ดังนั้น configuration ต้องใช้:

```yaml
MACROS:
  counter_macro:
    instances:
      u_counter_macro:
```

และเชื่อม power:

```yaml
PDN_MACRO_CONNECTIONS:
  - "u_counter_macro VDD VSS VDD VSS"
```

## Timing Model

ชุด Lab นี้เน้น physical macro integration จึงใช้:

- LEF
- GDS
- Verilog black-box header
- Gate-level netlist

ไม่บังคับ Liberty/SPEF ของ Macro เพื่อให้สามารถสร้างทั้ง Lab ด้วย open-source flow ชุดเดียวได้

สำหรับ hierarchical timing signoff จริงควรเพิ่ม:

- Liberty สำหรับ min/nom/max corners
- SPEF หลาย corners
- Powered netlist
- SPICE/CDL
- SDF
- Macro DRC/LVS reports

## Troubleshooting

### LibreLane หา PDK ไม่พบ

ตรวจสอบ:

```bash
echo "$PDK_ROOT"
find "$PDK_ROOT" -maxdepth 3 -type d -name 'gf180mcuD'
```

จากนั้น:

```bash
make check PDK_ROOT=/path/to/ciel-root
```

### Standard-cell library ไม่พบ

ทดลองค่า default ของ PDK:

```bash
librelane --pdk gf180mcuD --pdk-root "$PDK_ROOT" macro/config.yaml
```

หรือตรวจสอบ:

```bash
find "$PDK_ROOT" -type d -name 'gf180mcu_fd_sc_mcu7t5v0'
```

### Macro views ไม่พบหลัง hardening

```bash
make summary-macro
find macro/runs/macro_harden -type f | sort
```

### Macro instance ถูก optimize ทิ้ง

ตรวจว่า output ของ Macro เชื่อมกับ top-level output หรือ logic ที่ใช้งานจริง:

```bash
grep -R "u_counter_macro" top/runs/macro_integration \
  --include='*.v' --include='*.def'
```

### Macro power ไม่เชื่อม

```bash
grep -nE 'PIN (VDD|VSS)' \
  macros/counter_macro/lef/counter_macro.lef
```

และตรวจ:

```yaml
PDN_MACRO_CONNECTIONS:
  - "u_counter_macro VDD VSS VDD VSS"
```

### Routing congestion

ขยาย core หรือเพิ่ม halo:

```yaml
FP_MACRO_HORIZONTAL_HALO: 20
FP_MACRO_VERTICAL_HALO: 20
PL_TARGET_DENSITY_PCT: 25
```

## การทดลองเพิ่มเติม

1. เปลี่ยนตำแหน่ง Macro
2. เปลี่ยน orientation เป็น `S`, `FN`, `FS`
3. เปลี่ยน halo เป็น 5, 10 และ 20 µm
4. เปรียบเทียบ WNS, TNS, wire length และ DRC
5. เพิ่ม Macro instance ตัวที่สอง
6. เพิ่ม Liberty/SPEF แล้วเปรียบเทียบ STA
