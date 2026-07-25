# Lab 13 — Hierarchical Physical Design with LibreLane and SKY130A

ชุดปฏิบัติการนี้สร้าง hard macro สองบล็อก แล้วนำมาประกอบเป็น top-level แบบ hierarchical physical design โดยใช้ LibreLane และ PDK `sky130A` พร้อม RTL verification, macro hardening, view collection, top-level integration และโหมด hierarchical STA แบบ NL+SPEF

## โครงสร้างโครงการ

```text
lab13_hierarchical_sky130a/
├── rtl/
│   ├── counter_macro.sv
│   ├── accumulator_macro.sv
│   └── hier_system.sv
├── tb/tb_hier_system.sv
├── blocks/
│   ├── counter_macro/{config.yaml,constraints.sdc,pin_order.cfg}
│   └── accumulator_macro/{config.yaml,constraints.sdc,pin_order.cfg}
├── macros/
│   ├── counter_macro/{gds,lef,vh,nl,pnl,spef,lib,spice}
│   └── accumulator_macro/{gds,lef,vh,nl,pnl,spef,lib,spice}
├── top/
│   ├── config.yaml
│   ├── config_hier_sta.yaml
│   ├── constraints.sdc
│   └── pin_order.cfg
├── scripts/
├── docs/COMMANDS.md
└── Makefile
```

## ความต้องการ

- LibreLane รุ่นที่รองรับ YAML configuration version 3
- PDK `sky130A` พร้อม standard-cell library ค่าเริ่มต้นของ PDK โดยทั่วไปคือ `sky130_fd_sc_hd`
- Verilator
- OpenROAD และ KLayout ซึ่งมักติดมากับ LibreLane environment
- Python 3 พร้อม PyYAML สำหรับ `make check`

ตรวจสอบ environment:

```bash
librelane --version
verilator --version
openroad -version
klayout -v
```

## เริ่มต้นใช้งาน

```bash
unzip lab13_hierarchical_sky130a.zip
cd lab13_hierarchical_sky130a
make tools
make check
make lint
make sim
```

## ลำดับ Hierarchical Flow

### 1. Harden counter macro

```bash
make counter
```

เทียบเท่ากับ:

```bash
librelane --pdk sky130A blocks/counter_macro/config.yaml
```

### 2. Harden accumulator macro

```bash
make accumulator
```

หรือรันทั้งสองบล็อก:

```bash
make macros
```

### 3. รวบรวม macro views

```bash
make collect
make check-macros
```

สคริปต์จะค้นหา run ล่าสุด แล้วคัดลอกผลลัพธ์สำคัญเข้าสู่ `macros/<macro>/` ได้แก่ GDS, LEF, gate-level netlist, powered netlist, SPEF, Liberty และ SPICE เท่าที่ flow สร้างได้

### 4. Top-level physical integration

```bash
make top
```

Top-level config ใช้ LEF สำหรับ abstract geometry, GDS สำหรับ stream-out และ Verilog header สำหรับ black-box declaration

### 5. Optional hierarchical STA

หลังจากมี netlist และ SPEF ครบ:

```bash
make top-sta
```

โหมดนี้เพิ่ม `nl` และ `spef` views และกำหนด `STA_MACRO_PRIORITIZE_NL: true`

### 6. รันทั้งหมด

```bash
make all
```

ลำดับคือ RTL simulation → harden macros → collect views → top-level integration

## ค่าออกแบบเริ่มต้น

- PDK: `sky130A`
- Clock: `clk_i`
- Clock period: 20 ns หรือ 50 MHz
- Power nets: `VDD`, `VSS`
- Counter macro die: 140 × 140 µm
- Accumulator macro die: 140 × 140 µm
- Top die: 600 × 400 µm
- Macro placement:
  - `u_counter_macro`: `(55, 120)`, orientation `N`
  - `u_accumulator_macro`: `(360, 120)`, orientation `N`

พื้นที่เหล่านี้ตั้งใจให้มี margin สำหรับการเรียนการสอน หาก congestion สูง สามารถขยาย `DIE_AREA`/`CORE_AREA` หรือปรับ `PL_TARGET_DENSITY_PCT` ได้

## ผลลัพธ์ที่ควรตรวจสอบ

```bash
find blocks top -type f \
  \( -name '*.gds' -o -name '*.lef' -o -name '*.odb' \
     -o -name '*.def' -o -name '*.spef' -o -name '*.nl.v' \
     -o -name 'metrics.csv' \) | sort
```

ตรวจสอบ log และ report:

```bash
find blocks top -type f \
  \( -name '*.log' -o -name '*.rpt' -o -name 'metrics.csv' \) | sort
```

## หมายเหตุสำคัญ

ชื่อไฟล์ผลลัพธ์และตำแหน่ง run directory อาจต่างกันเล็กน้อยตาม LibreLane revision สคริปต์ `collect_macro_views.sh` จึงค้นหาไฟล์หลายรูปแบบ แต่จะหยุดพร้อมข้อความชัดเจนหากไม่พบ LEF หรือ GDS ซึ่งเป็น views หลักสำหรับ top-level integration
