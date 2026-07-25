# Lab 12: Macro Integration with LibreLane and IHP SG13G2

Lab นี้สาธิต hierarchical physical design แบบ 2 ขั้นตอน:

1. Harden RTL `counter_macro` เป็น hard macro ด้วย LibreLane
2. รวบรวม LEF/GDS/netlist จากผลลัพธ์
3. Instantiate macro ใน `macro_wrapper`
4. รัน top-level RTL-to-GDSII โดยประกาศ macro ผ่าน `MACROS` ใน `config.yaml`

## โครงสร้าง

```text
lab12_macro_integration_ihp_sg13g2/
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
├── scripts/
│   ├── check_tools.sh
│   ├── collect_macro_views.sh
│   ├── preflight.py
│   ├── report_summary.sh
│   └── verify_macro_instance.sh
└── macros/counter_macro/
    ├── gds/
    ├── lef/
    ├── nl/
    └── vh/
```

## ข้อกำหนดเบื้องต้น

- LibreLane ที่รองรับ YAML configuration version 3
- IHP Open PDK ติดตั้งในรูปแบบ LibreLane
- PDK name: `ihp-sg13g2`
- `ciel`, `python3`, `make`
- แนะนำให้รันภายใน Nix shell ของ LibreLane

IHP template ปัจจุบันใช้คำสั่งแบบ manual PDK:

```bash
librelane config.yaml \
  --pdk ihp-sg13g2 \
  --pdk-root "$PDK_ROOT" \
  --manual-pdk
```

## เริ่มต้นอย่างเร็ว

```bash
cd lab12_macro_integration_ihp_sg13g2

# กำหนดตำแหน่ง PDK หากไม่ได้อยู่ที่ ./IHP-Open-PDK
export PDK_ROOT=/absolute/path/to/IHP-Open-PDK
export PDK=ihp-sg13g2

make check
make all
make summary
```

`make all` ทำงานตามลำดับ:

```text
preflight
  -> harden macro
  -> collect LEF/GDS/netlist
  -> verify macro views
  -> integrate top level
```

## ติดตั้ง PDK ด้วย ciel

ค่าคอมมิตด้านล่างอิงจาก IHP LibreLane template และสามารถ override ได้:

```bash
make clone-pdk
```

หรือ:

```bash
PDK_COMMIT=<commit> make clone-pdk
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

## Run tag

กำหนด run tag เองได้:

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

## ผลลัพธ์สำคัญ

หลัง `make collect`:

```text
macros/counter_macro/gds/counter_macro.gds
macros/counter_macro/lef/counter_macro.lef
macros/counter_macro/nl/counter_macro.nl.v
macros/counter_macro/vh/counter_macro.vh
```

หลัง `make top`:

```text
top/final/
top/runs/macro_integration/
```

## จุดเรียนรู้สำคัญ

- `MACROS.counter_macro` คือชื่อ macro master/module
- `instances.u_counter_macro` คือชื่อ instance หลัง synthesis
- Macro ถูกวางที่ `[105, 100]` µm ด้วย orientation `N`
- Top-level ใช้ `PDN_MACRO_CONNECTIONS` เชื่อม `VDD/VSS`
- LEF และ GDS เป็น views ที่จำเป็น
- Verilog header ทำให้ Yosys คง instance เป็น black box
- Script จะตรวจว่า instance ยังปรากฏใน synthesized netlist และ DEF

## หมายเหตุด้าน timing

Lab นี้เน้นกลไก physical macro integration และใช้ LEF/GDS/header/netlist ที่สร้างจาก flow แรก โดยไม่บังคับ Liberty characterization ของ macro เพื่อให้ตัวอย่างทำงานได้ด้วย open-source flow ล้วน ๆ

สำหรับ signoff hierarchy จริง ควรเพิ่ม:

- Liberty หลาย PVT corners
- SPEF min/nom/max
- Powered netlist
- SPICE/CDL
- SDF
- Macro-level DRC/LVS signoff reports

## Troubleshooting

### ไม่พบ PDK

```text
PDK directory not found
```

แก้ไข:

```bash
export PDK_ROOT=/path/to/IHP-Open-PDK
export PDK=ihp-sg13g2
make check
```

### ไม่พบ GDS/LEF หลัง macro run

```bash
make summary-macro
find macro/runs -type f | sort
```

จากนั้นตรวจว่า macro flow จบด้วย `Flow complete`.

### Instance ไม่ตรง

Top RTL ใช้ชื่อ:

```systemverilog
counter_macro u_counter_macro (...);
```

ดังนั้น top `config.yaml` ต้องใช้:

```yaml
instances:
  u_counter_macro:
```

### PDN ไม่เชื่อม macro

ตรวจชื่อ pins ใน LEF:

```bash
grep -nE 'PIN (VDD|VSS)' macros/counter_macro/lef/counter_macro.lef
```

และตรวจ:

```yaml
PDN_MACRO_CONNECTIONS:
  - "u_counter_macro VDD VSS VDD VSS"
```

### Routing congestion รอบ macro

เพิ่ม halo หรือขยาย floorplan:

```yaml
FP_MACRO_HORIZONTAL_HALO: 15
FP_MACRO_VERTICAL_HALO: 15
PL_TARGET_DENSITY_PCT: 30
```

## ลำดับทดลองแนะนำ

1. รันค่าเริ่มต้นและเปิด OpenROAD GUI
2. เปลี่ยนตำแหน่ง macro
3. เปลี่ยน orientation เป็น `S`, `FN`, `FS`
4. เปลี่ยน halo 5, 10, 20 µm
5. เปรียบเทียบ wire length, WNS/TNS, congestion และ DRC
