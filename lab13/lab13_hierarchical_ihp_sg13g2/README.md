# Lab 13 — Hierarchical Physical Design with LibreLane and IHP SG13G2

ชุดทดลองนี้สร้าง hard macro สองบล็อก แล้วนำมาประกอบใน top-level design:

- `counter_macro`
- `accumulator_macro`
- `hier_system` ซึ่งประกอบ hard macro ทั้งสองตัว

## 1. เครื่องมือที่ต้องมี

- Linux หรือ WSL2
- LibreLane รุ่นที่รองรับ `ihp-sg13g2`
- IHP Open PDK SG13G2 ติดตั้งใน PDK root
- Verilator
- OpenROAD และ KLayout ซึ่งมากับ LibreLane environment

เริ่มจากเข้า LibreLane/Nix shell ที่ติดตั้ง PDK แล้ว:

```bash
cd lab13_hierarchical_ihp_sg13g2
make tools
make check
```

## 2. ตรวจสอบ RTL

```bash
make lint
make sim
```

ผล simulation ที่คาดหวัง:

```text
[PASS] counter counts five cycles value=0x05
[PASS] accumulator adds four times value=0x0c
[PASS] counter asynchronous reset value=0x00
[PASS] accumulator asynchronous reset value=0x00
[PASS] Lab 13 RTL simulation completed
```

## 3. Harden macro ระดับล่าง

```bash
make counter
make accumulator
```

หรือ:

```bash
make macros
```

LibreLane จะสร้าง run directories ใต้:

```text
blocks/counter_macro/runs/
blocks/accumulator_macro/runs/
```

## 4. รวบรวม macro views

คำสั่งต่อไปนี้เลือก run ล่าสุดอัตโนมัติ แล้วคัดลอกไฟล์ไปยัง path คงที่:

```bash
make collect
```

Views ขั้นต่ำที่ top-level ต้องใช้:

```text
macros/counter_macro/gds/counter_macro.gds
macros/counter_macro/lef/counter_macro.lef
macros/counter_macro/vh/counter_macro.vh
macros/accumulator_macro/gds/accumulator_macro.gds
macros/accumulator_macro/lef/accumulator_macro.lef
macros/accumulator_macro/vh/accumulator_macro.vh
```

ตรวจสอบเองได้ด้วย:

```bash
make check-macros
```

กรณีต้องการเลือก run เอง:

```bash
./scripts/collect_macro_views.sh counter_macro blocks/counter_macro/runs/RUN_...
./scripts/collect_macro_views.sh accumulator_macro blocks/accumulator_macro/runs/RUN_...
```

## 5. รัน top-level integration

โหมดพื้นฐาน ใช้ LEF, GDS และ Verilog header จึงมีความทนต่อความแตกต่างของชื่อ timing outputs ระหว่าง LibreLane versions:

```bash
make top
```

คำสั่งจริงคือ:

```bash
librelane --pdk ihp-sg13g2 top/config.yaml
```

Top-level macro placement:

```text
u_counter_macro      origin = (40, 105), orientation = N
u_accumulator_macro  origin = (300, 100), orientation = N
```

Top die/core:

```text
DIE_AREA  = [0, 0, 520, 340] um
CORE_AREA = [10, 10, 510, 330] um
```

## 6. Hierarchical STA ด้วย NL + SPEF

หลัง `make collect` หากพบไฟล์ `.nl.v` และ `.spef` ครบ สามารถรัน:

```bash
make top-sta
```

โหมดนี้ใช้:

```yaml
STA_MACRO_PRIORITIZE_NL: true
```

และ `top/config_hier_sta.yaml` เพื่อให้ OpenSTA มองเห็น gate-level netlist และ parasitics ภายใน macro มากกว่าการวิเคราะห์แบบ black box

## 7. รันทุกขั้นตอน

```bash
make all
```

ลำดับคือ:

```text
RTL simulation
  -> counter hardening
  -> accumulator hardening
  -> collect macro views
  -> top-level integration
```

## 8. เปิดผลลัพธ์

ค้นหา final ODB/GDS:

```bash
find top/runs -type f \( -name '*.odb' -o -name 'hier_system.gds' \) | sort
```

เปิด OpenROAD GUI:

```bash
openroad -gui path/to/final.odb
```

เปิด KLayout:

```bash
klayout path/to/hier_system.gds
```

ตรวจสอบ:

- hard macro ทั้งสองอยู่ในตำแหน่งที่กำหนด
- ไม่มี macro overlap
- สายสัญญาณเชื่อมถึง macro pins
- `VDD/VSS` เชื่อมผ่าน top-level PDN
- clock เชื่อมถึง `clk_i` ของทั้งสอง macro
- DRC, LVS และ antenna reports
- setup/hold slack และ unconstrained paths

## 9. คำสั่งแบบเรียงลำดับ

```bash
cd lab13_hierarchical_ihp_sg13g2

make tools
make check
make lint
make sim

make counter
make accumulator

make collect
make check-macros

make top

# เลือกใช้เมื่อ NL/SPEF ถูกเก็บครบ
make top-sta
```

## 10. จุดที่อาจต้องปรับตาม LibreLane/PDK revision

IHP SG13G2 และ LibreLane ยังมีการพัฒนาอย่างต่อเนื่อง หาก flow แจ้งว่า configuration variable ถูกเปลี่ยนชื่อ ให้ตรวจสอบด้วย:

```bash
librelane --version
librelane --pdk ihp-sg13g2 blocks/counter_macro/config.yaml --validate-only
```

ถ้า CLI รุ่นที่ติดตั้งไม่มี `--validate-only` ให้รัน flow ปกติ เพราะ LibreLane จะตรวจ schema ก่อนเริ่มขั้นตอน implementation

Timing corner patterns ใน `config_hier_sta.yaml` อิงชื่อ IHP SG13G2:

```text
*_typ_1p20V_25C
*_fast_1p32V_m40C
*_slow_1p08V_125C
```

หาก environment ใช้ชื่อ corner ต่างออกไป ให้ดู corner names ใน startup log แล้วแก้ keys ใต้ `spef:` ให้ตรงกัน

## 11. หมายเหตุด้าน signoff

`top/config.yaml` เป็นโหมด integration ที่รันได้โดยใช้ views ขั้นต่ำ แต่ STA ภายใน macro จะเป็น black-box timing. สำหรับผล timing ที่มีความหมายมากขึ้น ให้ใช้ `make top-sta` หรือ Liberty models ที่ผ่าน characterization แล้ว
