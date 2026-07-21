
# Lab 10 Physical Verification: DRC and LVS

## 10.1 บทนำ

หลังจากผ่านกระบวนการวางเซลล์ สร้าง Clock Tree และเดินสายสัญญาณแล้ว ขั้นตอนสำคัญก่อนส่งแบบวงจรรวมไปผลิตคือ **Physical Verification** หรือการตรวจสอบความถูกต้องทางกายภาพของ Layout

Physical Verification ที่สำคัญประกอบด้วย

1. **Design Rule Checking: DRC**  
   ตรวจสอบว่า Layout ปฏิบัติตามกฎการผลิตของโรงงาน เช่น ความกว้างขั้นต่ำ ระยะห่างขั้นต่ำ และพื้นที่ซ้อนทับของแต่ละชั้นโลหะ

2. **Layout Versus Schematic: LVS**  
   ตรวจสอบว่าโครงข่ายไฟฟ้าที่สกัดจาก Layout มีความสมมูลกับ Gate-level Netlist ที่ได้จากการสังเคราะห์หรือไม่

3. **Layout Stream-out Consistency**  
   ตรวจสอบความสอดคล้องของไฟล์ GDSII ที่สร้างโดยเครื่องมือมากกว่าหนึ่งชุด เช่น Magic และ KLayout

LibreLane Classic Flow ประกอบด้วยขั้นตอน `Magic.DRC`, `KLayout.DRC`, `Magic.SpiceExtraction` และ `Netgen.LVS` รวมทั้ง checker ที่ใช้ตัดสินว่าผลการตรวจสอบผ่านเกณฑ์หรือไม่ 

---

## 10.2 วัตถุประสงค์ของบทปฏิบัติการ

เมื่อจบ Lab นี้ ผู้เรียนจะสามารถ

1. อธิบายความแตกต่างระหว่าง DRC และ LVS
2. กำหนดค่า Physical Verification ใน `config.yaml`
3. รัน LibreLane ตั้งแต่ RTL จนถึงขั้นตอน DRC และ LVS
4. ตรวจสอบผลจาก Magic DRC และ KLayout DRC
5. ตรวจสอบผลจาก Netgen LVS
6. เปิด Layout เพื่อตรวจสอบตำแหน่ง DRC violation
7. แยกแยะข้อผิดพลาดด้าน Geometry, Connectivity และ Netlist
8. วิเคราะห์สาเหตุของ LVS mismatch
9. แก้ไขปัญหาที่เกิดจาก Power/Ground, pin name และ top-level module
10. จัดทำ Signoff Checklist สำหรับงาน RTL-to-GDSII

---

## 10.3 เครื่องมือที่ใช้

Lab นี้ใช้เครื่องมือหลักดังต่อไปนี้

| เครื่องมือ | หน้าที่ |
|---|---|
| LibreLane | ควบคุม RTL-to-GDSII flow |
| Yosys | สังเคราะห์ RTL เป็น Gate-level Netlist |
| OpenROAD | Floorplan, Placement, CTS และ Routing |
| Magic | GDS stream-out, DRC และ SPICE extraction |
| KLayout | GDS stream-out, DRC และตรวจสอบ Layout |
| Netgen | เปรียบเทียบ Layout-extracted netlist กับ schematic netlist |
| OpenSTA | วิเคราะห์ Timing |
| PDK | กำหนด technology files และกฎการผลิต |

OpenROAD ใช้สำหรับกระบวนการ Physical Design ส่วนการตรวจสอบขั้นสุดท้ายอาจใช้ Magic หรือ KLayout กับ DRC deck ที่มากับ PDK 

---

# 10.4 ทฤษฎีพื้นฐานของ Design Rule Checking

## 10.4.1 DRC คืออะไร

DRC เป็นกระบวนการตรวจสอบรูปทรงเรขาคณิตของ Layout เทียบกับกฎที่กำหนดโดยโรงงานผลิตวงจรรวม

ตัวอย่างกฎ DRC ได้แก่

- Minimum width
- Minimum spacing
- Minimum enclosure
- Minimum overlap
- Minimum area
- End-of-line spacing
- Via enclosure
- Via-to-via spacing
- Metal density
- Well spacing
- Implant spacing

ตัวอย่างเช่น ถ้า PDK กำหนดให้ชั้นโลหะหนึ่งต้องมีระยะห่างไม่น้อยกว่าเกณฑ์ที่กำหนด แต่ Router สร้างเส้นโลหะสองเส้นอยู่ใกล้กันเกินไป DRC จะรายงาน violation

LibreLane ใช้ทั้ง Magic และ KLayout สำหรับ DRC เพราะเครื่องมือแต่ละชุดอาจมีวิธีตีความหรือขอบเขตการตรวจสอบแตกต่างกัน การใช้มากกว่าหนึ่ง checker ช่วยเพิ่มความมั่นใจในผลตรวจสอบ 

## 10.4.2 Input ของ DRC

DRC ต้องการข้อมูลสำคัญสองส่วน

1. **Layout**
   - GDSII
   - Magic layout
   - หรือ database ที่สามารถแปลงเป็น geometry ได้

2. **DRC Rule Deck**
   - กฎการผลิตจาก PDK
   - Layer mapping
   - Width/spacing/enclosure rules
   - Special process rules

แนวคิดการทำงานคือ

```text
Layout Geometry
       +
PDK DRC Rule Deck
       |
       v
   DRC Engine
       |
       +--> Clean
       |
       +--> Violation Report
```

---

# 10.5 ทฤษฎีพื้นฐานของ Layout Versus Schematic

## 10.5.1 LVS คืออะไร

LVS ตรวจสอบว่า Layout ที่สร้างขึ้นมีโครงข่ายไฟฟ้าเหมือนกับวงจรอ้างอิงหรือไม่

วงจรอ้างอิงใน Digital ASIC Flow มักเป็น Gate-level Netlist ที่ได้จากการสังเคราะห์และได้รับการปรับแต่งระหว่าง Physical Design

กระบวนการ LVS ประกอบด้วย

1. สกัดอุปกรณ์และโครงข่ายจาก Layout
2. อ่าน Schematic หรือ Gate-level Netlist
3. Normalize ชื่ออุปกรณ์และชนิดเซลล์
4. เปรียบเทียบจำนวนอุปกรณ์
5. เปรียบเทียบจำนวน Net
6. เปรียบเทียบ Pin
7. เปรียบเทียบ Connectivity
8. ตรวจสอบความสมมูลของวงจร

แนวคิดการทำงานคือ

```text
GDSII Layout
     |
     v
SPICE Extraction
     |
     v
Extracted Netlist --------+
                          |
                          v
                    LVS Comparator
                          ^
                          |
Reference Gate Netlist ---+
```

## 10.5.2 สิ่งที่ LVS ตรวจสอบ

LVS ไม่ได้ตรวจสอบว่ารูปร่างสวยงามหรือเดินสายเหมาะสมหรือไม่ แต่ตรวจสอบความสมมูลทางไฟฟ้า เช่น

- จำนวน cell instance
- ชนิดของ standard cell
- จำนวน net
- การเชื่อมต่อ input/output
- การเชื่อมต่อ power และ ground
- Top-level pin
- Global net
- Short circuit
- Open circuit
- Missing instance
- Extra instance

## 10.5.3 ตัวอย่าง LVS mismatch

### กรณี Open Net

```text
Expected:
U1/Y ---- U2/A

Extracted:
U1/Y      U2/A
```

เส้นทางระหว่าง `U1/Y` และ `U2/A` ไม่ได้เชื่อมต่อกันจริงใน Layout

### กรณี Short Net

```text
Expected:
net_a และ net_b แยกจากกัน

Extracted:
net_a เชื่อมรวมกับ net_b
```

### กรณี Pin mismatch

```text
Schematic pin : reset_n
Layout pin    : rst_n
```

### กรณี Power mismatch

```text
Schematic : VPWR
Layout    : VDD
```

ถ้าไม่ได้กำหนดการเทียบชื่อหรือไม่ได้เชื่อม global net อย่างถูกต้อง LVS อาจไม่ผ่าน

---

# 10.6 ความสัมพันธ์ระหว่าง DRC และ LVS

DRC และ LVS เป็นคนละการตรวจสอบ

| DRC | LVS |
|---|---|
| ตรวจสอบ Geometry | ตรวจสอบ Connectivity |
| ใช้ Rule Deck | ใช้ Reference Netlist |
| ตรวจ minimum width/spacing | ตรวจ open/short |
| ไม่จำเป็นต้องเข้าใจฟังก์ชันลอจิก | ตรวจโครงข่ายไฟฟ้า |
| Layout อาจ DRC-clean แต่ LVS-fail | Layout อาจ LVS-clean แต่ DRC-fail |

ดังนั้น Layout ที่พร้อมสำหรับ Signoff ต้องผ่านทั้งสองการตรวจสอบ

```text
DRC Clean
    +
LVS Clean
    +
Timing Clean
    +
Antenna/Power Checks
    =
Physical Signoff Candidate
```

---

# 10.7 โครงสร้างโปรเจกต์

สร้างโครงสร้างโปรเจกต์ดังนี้

```text
lab10_physical_verification/
├── config.yaml
├── src/
│   └── counter.sv
├── constraints/
│   ├── pnr.sdc
│   └── signoff.sdc
├── pin_order.cfg
├── Makefile
└── README.md
```

สร้างโฟลเดอร์ด้วยคำสั่ง

```bash
mkdir -p lab10_physical_verification/src
mkdir -p lab10_physical_verification/constraints

cd lab10_physical_verification
```

ตรวจสอบตำแหน่งปัจจุบัน

```bash
pwd
```

---

# 10.8 การสร้าง RTL Design

สร้างไฟล์ `src/counter.sv`

```systemverilog
module counter (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       enable,
    output logic [7:0] count
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 8'h00;
        else if (enable)
            count <= count + 8'h01;
    end

endmodule
```

วงจรนี้มี

- Clock input ชื่อ `clk`
- Active-low asynchronous reset ชื่อ `rst_n`
- Enable input ชื่อ `enable`
- Output counter ขนาด 8 บิตชื่อ `count`

ตรวจสอบ syntax เบื้องต้นด้วย Verilator

```bash
verilator --lint-only --Wall src/counter.sv
```

ผลที่คาดหวังคือไม่มี error

---

# 10.9 การสร้าง Timing Constraint

## 10.9.1 ไฟล์ `constraints/pnr.sdc`

```tcl
create_clock \
    -name core_clk \
    -period 20.000 \
    [get_ports clk]

set_clock_uncertainty 0.250 [get_clocks core_clk]
set_clock_transition 0.150 [get_clocks core_clk]

set_input_delay 2.000 \
    -clock core_clk \
    [get_ports {rst_n enable}]

set_output_delay 4.000 \
    -clock core_clk \
    [get_ports {count[*]}]

set_load 0.033442 [get_ports {count[*]}]

set_false_path \
    -from [get_ports rst_n]
```

Clock period 20 ns เท่ากับความถี่

```text
f = 1 / T
  = 1 / 20 ns
  = 50 MHz
```

## 10.9.2 ไฟล์ `constraints/signoff.sdc`

```tcl
create_clock \
    -name core_clk \
    -period 20.000 \
    [get_ports clk]

set_clock_uncertainty 0.250 [get_clocks core_clk]
set_clock_transition 0.150 [get_clocks core_clk]

set_input_delay 2.000 \
    -clock core_clk \
    [get_ports {rst_n enable}]

set_output_delay 4.000 \
    -clock core_clk \
    [get_ports {count[*]}]

set_load 0.033442 [get_ports {count[*]}]

set_false_path \
    -from [get_ports rst_n]

set_timing_derate \
    -early 0.95 \
    -late 1.05
```

`pnr.sdc` ใช้ระหว่าง Physical Design ส่วน `signoff.sdc` ใช้สำหรับการวิเคราะห์หลัง Routing และการตรวจสอบขั้นท้าย

---

# 10.10 การกำหนด Pin Order

สร้างไฟล์ `pin_order.cfg`

```text
#N
clk
rst_n

#E
enable

#S
count\[0\]
count\[1\]
count\[2\]
count\[3\]

#W
count\[4\]
count\[5\]
count\[6\]
count\[7\]
```

แนวทางนี้แยก output bus ออกเป็นสองด้าน ช่วยลดการกระจุกตัวของ pin และลดโอกาสเกิด routing congestion

หมายเหตุ: รูปแบบ regex และชื่อ bus pin ต้องตรงกับชื่อที่ LibreLane/OpenROAD เห็นหลัง elaboration หาก pin placement ไม่ตรงตามที่คาด ให้ตรวจสอบรายชื่อ port จาก netlist หรือรายงานของขั้น IO placement

---

# 10.11 การสร้างไฟล์ config.yaml

สร้างไฟล์ `config.yaml`

```yaml
meta:
  version: 2
  flow: Classic

DESIGN_NAME: counter

VERILOG_FILES:
  - dir::src/counter.sv

CLOCK_PORT: clk
CLOCK_PERIOD: 20.0

PNR_SDC_FILE: dir::constraints/pnr.sdc
SIGNOFF_SDC_FILE: dir::constraints/signoff.sdc

FP_SIZING: relative
FP_CORE_UTIL: 35
FP_ASPECT_RATIO: 1.0

PL_TARGET_DENSITY_PCT: 45

GRT_ALLOW_CONGESTION: false

RUN_CTS: true
RUN_ANTENNA_REPAIR: true
RUN_DRT: true
RUN_FILL_INSERTION: true

RUN_MAGIC_STREAMOUT: true
RUN_KLAYOUT_STREAMOUT: true
RUN_KLAYOUT_XOR: true

RUN_MAGIC_DRC: true
RUN_KLAYOUT_DRC: true
RUN_LVS: true

RUN_MCSTA: true
RUN_SPEF_EXTRACTION: true

Odb.CustomIOPlacement:
  IO_PIN_ORDER_CFG: dir::pin_order.cfg
```

## 10.11.1 คำอธิบายส่วน `meta`

```yaml
meta:
  version: 2
  flow: Classic
```

- `version: 2` ระบุรูปแบบ configuration
- `flow: Classic` เลือก LibreLane Classic Flow
- Classic Flow ครอบคลุมขั้นตอนจาก RTL ถึง Physical Verification

## 10.11.2 คำอธิบาย Design Input

```yaml
DESIGN_NAME: counter

VERILOG_FILES:
  - dir::src/counter.sv
```

`DESIGN_NAME` ต้องตรงกับชื่อ top-level module

ข้อผิดพลาดที่พบบ่อยคือ

```yaml
DESIGN_NAME: counter_top
```

แต่ RTL มี

```systemverilog
module counter (...);
```

กรณีนี้ Yosys จะไม่พบ top-level design ที่กำหนด

`dir::` หมายถึง path ที่อ้างอิงจากตำแหน่งของไฟล์ configuration

## 10.11.3 คำอธิบาย Clock

```yaml
CLOCK_PORT: clk
CLOCK_PERIOD: 20.0
```

- `CLOCK_PORT` ต้องตรงกับชื่อ port
- `CLOCK_PERIOD` มีหน่วยเป็น ns
- 20 ns เท่ากับ 50 MHz

## 10.11.4 คำอธิบาย Physical Verification Switch

```yaml
RUN_MAGIC_STREAMOUT: true
RUN_KLAYOUT_STREAMOUT: true
RUN_KLAYOUT_XOR: true
RUN_MAGIC_DRC: true
RUN_KLAYOUT_DRC: true
RUN_LVS: true
```

ความหมายคือ

| ตัวแปร | หน้าที่ |
|---|---|
| `RUN_MAGIC_STREAMOUT` | สร้าง GDS ด้วย Magic |
| `RUN_KLAYOUT_STREAMOUT` | สร้าง GDS ด้วย KLayout |
| `RUN_KLAYOUT_XOR` | เปรียบเทียบ GDS จาก stream-out ทั้งสอง |
| `RUN_MAGIC_DRC` | รัน Magic DRC |
| `RUN_KLAYOUT_DRC` | รัน KLayout DRC |
| `RUN_LVS` | รัน Netgen LVS |

Classic Flow กำหนดตัวเลือกเหล่านี้ไว้เป็นตัวแปรควบคุมขั้นตอน Signoff และมี checker สำหรับตรวจผล DRC, XOR และ LVS 

---

# 10.12 การตรวจสอบสภาพแวดล้อม

ตรวจสอบ LibreLane

```bash
librelane --version
```

ตรวจสอบ PDK ที่ต้องการใช้

```bash
librelane --pdk sky130A --help
```

หรือสำหรับ PDK อื่น เช่น

```bash
librelane --pdk gf180mcuD --help
```

```bash
librelane --pdk ihp-sg13g2 --help
```

ชื่อ PDK ที่ติดตั้งจริงอาจแตกต่างตาม environment จึงควรตรวจสอบจาก environment หรือคำสั่ง help ก่อนรัน

สำหรับตัวอย่างหลักใน Lab นี้ใช้

```bash
sky130A
```

---

# 10.13 การรัน LibreLane Full Flow

รันจากโฟลเดอร์โปรเจกต์

```bash
librelane --pdk sky130A config.yaml
```

LibreLane จะดำเนินการโดยสรุปดังนี้

```text
RTL
 |
 v
Lint
 |
 v
Synthesis
 |
 v
Floorplan
 |
 v
Placement
 |
 v
CTS
 |
 v
Routing
 |
 v
GDS Stream-out
 |
 +--> Magic DRC
 |
 +--> KLayout DRC
 |
 +--> SPICE Extraction
 |
 +--> Netgen LVS
```

ขั้นตอนท้ายของ Classic Flow รวมถึง `Magic.StreamOut`, `KLayout.StreamOut`, `KLayout.XOR`, `Magic.DRC`, `KLayout.DRC`, `Magic.SpiceExtraction` และ `Netgen.LVS` 

---

# 10.14 การตรวจสอบ Run Directory

หลังรันสำเร็จ LibreLane จะสร้างโฟลเดอร์ประมาณดังนี้

```text
runs/
└── RUN_YYYY-MM-DD_HH-MM-SS/
    ├── config.yaml
    ├── final/
    ├── resolved.json
    ├── state_out.json
    └── xx-step-name/
```

ชื่อและลำดับหมายเลขของแต่ละ step อาจแตกต่างตามเวอร์ชันและ PDK ตัวอย่างเช่น

```text
...
52-magic-streamout/
53-klayout-streamout/
54-klayout-xor/
55-magic-drc/
56-klayout-drc/
57-magic-spice-extraction/
58-netgen-lvs/
```

อย่าอ้างอิงหมายเลข step แบบตายตัว ให้ค้นหาจากชื่อ suffix

```bash
find runs -maxdepth 2 -type d | grep -E \
'magic-drc|klayout-drc|netgen-lvs|spice-extraction|xor'
```

---

# 10.15 การตรวจสอบ Summary

ค้นหาไฟล์ summary

```bash
find runs -type f | grep -E \
'summary|metrics|manufacturability|final'
```

ตรวจสอบไฟล์ใน final directory

```bash
find runs -path '*/final/*' -type f
```

โดยทั่วไป final directory จะประกอบด้วยไฟล์บางส่วนต่อไปนี้

```text
final/
├── def/
├── gds/
├── lef/
├── nl/
├── odb/
├── sdf/
├── spef/
├── spice/
└── views/
```

รายชื่อจริงขึ้นกับ Flow, LibreLane version และ PDK

---

# 10.16 การตรวจสอบ Magic DRC

## 10.16.1 ค้นหา Magic DRC Step

```bash
MAGIC_DRC_DIR=$(find runs -maxdepth 2 \
    -type d \
    -name '*-magic-drc' \
    | sort \
    | tail -1)

echo "${MAGIC_DRC_DIR}"
```

## 10.16.2 แสดงรายการไฟล์

```bash
find "${MAGIC_DRC_DIR}" -maxdepth 3 -type f
```

ค้นหารายงาน

```bash
find "${MAGIC_DRC_DIR}" \
    -type f \
    | grep -E 'drc|report|rpt'
```

ชื่อไฟล์ที่พบบ่อย เช่น

```text
reports/drc_violations.magic.rpt
```

หรือ

```text
reports/drc.rpt
```

ชื่อไฟล์อาจเปลี่ยนไปตามเวอร์ชันของ LibreLane จึงควรใช้ `find` แทนการกำหนด path แบบตายตัว

## 10.16.3 เปิดรายงาน

```bash
cat "${MAGIC_DRC_DIR}"/reports/*.rpt
```

ตัวอย่างผล DRC-clean

```text
counter
----------------------------------------
[INFO] COUNT: 0
```

เอกสารตัวอย่างของ LibreLane แสดงว่า Magic DRC report จะรายงานจำนวน violation และกรณี clean จะมีค่า count เป็นศูนย์ 

## 10.16.4 ค้นหา violation count อัตโนมัติ

```bash
grep -RniE \
'count|violation|error' \
"${MAGIC_DRC_DIR}/reports"
```

ผลที่ต้องการคือ

```text
COUNT: 0
```

---

# 10.17 การตรวจสอบ KLayout DRC

## 10.17.1 ค้นหา KLayout DRC Step

```bash
KLAYOUT_DRC_DIR=$(find runs -maxdepth 2 \
    -type d \
    -name '*-klayout-drc' \
    | sort \
    | tail -1)

echo "${KLAYOUT_DRC_DIR}"
```

## 10.17.2 แสดงรายการรายงาน

```bash
find "${KLAYOUT_DRC_DIR}" \
    -type f \
    | grep -E 'json|xml|lyrdb|rpt|report'
```

ชื่อไฟล์ที่อาจพบ เช่น

```text
reports/drc_violations.klayout.json
```

หรือ

```text
violations.json
```

## 10.17.3 ตรวจสอบ JSON Report

```bash
find "${KLAYOUT_DRC_DIR}" \
    -type f \
    -name '*.json' \
    -exec sh -c '
        echo "===== $1 ====="
        tail -30 "$1"
    ' _ {} \;
```

กรณี DRC-clean ควรพบข้อมูลลักษณะ

```json
{
  "total": 0
}
```

ตัวอย่าง LibreLane ระบุว่า KLayout DRC report แบบ JSON จะมี `"total": 0` เมื่อไม่พบ violation 

ถ้าติดตั้ง `jq`

```bash
find "${KLAYOUT_DRC_DIR}" \
    -type f \
    -name '*.json' \
    -exec jq '.total // empty' {} \;
```

---

# 10.18 ทำไมต้องตรวจทั้ง Magic DRC และ KLayout DRC

Magic และ KLayout ใช้ engine และ rule deck คนละรูปแบบ

ผลลัพธ์อาจเกิดกรณีดังนี้

| Magic | KLayout | ความหมายเบื้องต้น |
|---:|---:|---|
| 0 | 0 | ดีที่สุด |
| >0 | 0 | ตรวจ rule deck, stream-out และ Magic-specific geometry |
| 0 | >0 | ตรวจ KLayout rule deck และ layer mapping |
| >0 | >0 | มี geometry violation ที่ควรแก้ |
| N/A | 0 | PDK อาจไม่รองรับ Magic DRC เต็มรูปแบบ |
| 0 | N/A | PDK อาจไม่มี KLayout DRC deck สำหรับ Flow นี้ |

การไม่พบ violation ในเครื่องมือหนึ่งไม่ได้รับประกันว่าอีกเครื่องมือจะให้ผลเหมือนกัน

---

# 10.19 การตรวจสอบ KLayout XOR

KLayout XOR ใช้เปรียบเทียบ GDSII ที่สร้างจาก Magic และ KLayout

แนวคิดคือ

```text
Magic-generated GDS
         XOR
KLayout-generated GDS
          |
          v
Difference Geometry
```

ค้นหา step

```bash
XOR_DIR=$(find runs -maxdepth 2 \
    -type d \
    -name '*-klayout-xor' \
    | sort \
    | tail -1)

echo "${XOR_DIR}"
```

ตรวจสอบรายงาน

```bash
find "${XOR_DIR}" \
    -type f \
    | grep -E 'json|xml|rpt|report|lyrdb'
```

ค้นหาข้อความสำคัญ

```bash
grep -RniE \
'difference|violation|error|count|total' \
"${XOR_DIR}"
```

XOR-clean หมายความว่า GDS ที่สร้างจาก stream-out ทั้งสองเส้นทางไม่แตกต่างกันในส่วนที่ flow ตรวจสอบ

อย่างไรก็ตาม XOR-clean ไม่ได้แทนที่ DRC และ LVS เพราะ XOR ตรวจความสอดคล้องระหว่างไฟล์ Layout สองไฟล์ ไม่ได้ตรวจ manufacturing rule หรือ logical equivalence โดยตรง

---

# 10.20 การตรวจสอบ SPICE Extraction

ก่อนทำ LVS LibreLane ใช้ Magic สกัด netlist จาก Layout

ค้นหา step

```bash
EXTRACT_DIR=$(find runs -maxdepth 2 \
    -type d \
    -name '*-magic-spice-extraction' \
    | sort \
    | tail -1)

echo "${EXTRACT_DIR}"
```

ค้นหาไฟล์ SPICE

```bash
find "${EXTRACT_DIR}" \
    -type f \
    | grep -Ei '\.(spice|spi|sp|cir)$'
```

ตรวจสอบส่วนต้นของไฟล์

```bash
SPICE_FILE=$(find "${EXTRACT_DIR}" \
    -type f \
    | grep -Ei '\.(spice|spi|sp|cir)$' \
    | head -1)

head -80 "${SPICE_FILE}"
```

ควรพบโครงสร้างลักษณะ

```spice
.subckt counter clk rst_n enable count[0] ...
...
.ends counter
```

สิ่งที่ต้องตรวจสอบคือ

- ชื่อ `.subckt` ตรงกับ top-level design
- จำนวน top-level pin ถูกต้อง
- มี power/ground pin ตามรูปแบบของ PDK
- ไม่พบ subcircuit ที่ขาดหาย
- ไม่มีข้อความ extraction error

---

# 10.21 การตรวจสอบ Netgen LVS

## 10.21.1 ค้นหา Netgen LVS Step

```bash
LVS_DIR=$(find runs -maxdepth 2 \
    -type d \
    -name '*-netgen-lvs' \
    | sort \
    | tail -1)

echo "${LVS_DIR}"
```

## 10.21.2 แสดงรายการไฟล์

```bash
find "${LVS_DIR}" -maxdepth 3 -type f
```

ค้นหา report

```bash
find "${LVS_DIR}" \
    -type f \
    | grep -Ei 'lvs|rpt|report|log'
```

## 10.21.3 เปิดรายงาน LVS

```bash
find "${LVS_DIR}" \
    -type f \
    -name '*lvs*.rpt' \
    -exec sh -c '
        echo "===== $1 ====="
        tail -100 "$1"
    ' _ {} \;
```

ถ้าไม่พบไฟล์ตาม pattern

```bash
grep -RniE \
'circuits match|mismatch|equivalent|not equivalent' \
"${LVS_DIR}"
```

## 10.21.4 ผล LVS ที่ผ่าน

ข้อความสำคัญที่ควรพบคือ

```text
Cell pin lists are equivalent.
Device classes counter and counter are equivalent.
Final result: Circuits match uniquely.
```

เอกสาร LibreLane แสดงรูปแบบผล Netgen LVS ที่ผ่านด้วยข้อความ `Final result: Circuits match uniquely.` 

## 10.21.5 สคริปต์ตรวจผลอย่างรวดเร็ว

```bash
grep -Rni \
'Final result:' \
"${LVS_DIR}"
```

ผ่าน

```text
Final result: Circuits match uniquely.
```

ไม่ผ่านอาจพบข้อความลักษณะ

```text
Circuits do not match.
```

หรือรายละเอียดเกี่ยวกับ

- Property errors
- Net mismatches
- Device mismatches
- Pin mismatches
- Bad nets
- Unmatched devices

---

# 10.22 การค้นหา Physical Verification Reports แบบรวม

ใช้คำสั่งต่อไปนี้

```bash
find runs \
    -type f \
    \( \
        -iname '*drc*' \
        -o -iname '*lvs*' \
        -o -iname '*xor*' \
        -o -iname '*violation*' \
    \) \
    -print
```

ค้นหาข้อความที่สำคัญ

```bash
grep -RniE \
'COUNT:|total|Circuits match|do not match|violation|mismatch' \
runs/*/*drc* \
runs/*/*lvs* \
runs/*/*xor* \
2>/dev/null
```

---

# 10.23 การสร้าง Makefile

สร้างไฟล์ `Makefile`

```makefile
PDK ?= sky130A
CONFIG ?= config.yaml

.PHONY: all run lint reports drc lvs xor final clean help

all: run

run:
	librelane --pdk $(PDK) $(CONFIG)

lint:
	verilator --lint-only --Wall src/counter.sv

reports:
	@echo "=== Physical Verification Files ==="
	@find runs -type f \( \
		-iname '*drc*' -o \
		-iname '*lvs*' -o \
		-iname '*xor*' -o \
		-iname '*violation*' \
	\) -print 2>/dev/null || true

drc:
	@echo "=== Magic DRC ==="
	@grep -RniE 'COUNT:|violation|error' \
		$$(find runs -maxdepth 2 -type d \
		-name '*-magic-drc' | sort | tail -1) \
		2>/dev/null || true
	@echo
	@echo "=== KLayout DRC ==="
	@grep -RniE '"total"|violation|error' \
		$$(find runs -maxdepth 2 -type d \
		-name '*-klayout-drc' | sort | tail -1) \
		2>/dev/null || true

lvs:
	@echo "=== Netgen LVS ==="
	@grep -RniE \
		'Final result:|Circuits match|do not match|equivalent|mismatch' \
		$$(find runs -maxdepth 2 -type d \
		-name '*-netgen-lvs' | sort | tail -1) \
		2>/dev/null || true

xor:
	@echo "=== KLayout XOR ==="
	@grep -RniE \
		'difference|violation|error|count|total' \
		$$(find runs -maxdepth 2 -type d \
		-name '*-klayout-xor' | sort | tail -1) \
		2>/dev/null || true

final:
	@echo "=== Final Artifacts ==="
	@find runs -path '*/final/*' -type f 2>/dev/null || true

clean:
	rm -rf runs

help:
	@echo "make lint              - Check RTL syntax"
	@echo "make run               - Run LibreLane"
	@echo "make reports           - Locate DRC/LVS/XOR reports"
	@echo "make drc               - Show DRC summary"
	@echo "make lvs               - Show LVS summary"
	@echo "make xor               - Show XOR summary"
	@echo "make final             - List final artifacts"
	@echo "make clean             - Delete runs directory"
	@echo "make run PDK=gf180mcuD - Select another PDK"
```

รันตามลำดับ

```bash
make lint
make run
make drc
make lvs
make xor
make final
```

---

# 10.24 การเปิด Layout ด้วย KLayout

ค้นหา final GDS

```bash
GDS_FILE=$(find runs \
    -path '*/final/gds/*' \
    -type f \
    -name '*.gds' \
    | sort \
    | tail -1)

echo "${GDS_FILE}"
```

เปิดด้วย KLayout

```bash
klayout "${GDS_FILE}"
```

หากใช้ LibreLane command สำหรับเปิด run ล่าสุด อาจใช้รูปแบบที่ installation รองรับ เช่น flow สำหรับเปิด KLayout จาก last run แต่ควรตรวจสอบ syntax จาก

```bash
librelane --help
```

เนื่องจากชื่อ flow helper และ argument อาจเปลี่ยนตามรุ่นของ LibreLane

เอกสารของ OpenLane/LibreLane แสดงแนวทางเปิดผลจาก run ล่าสุดด้วย KLayout เพื่อดู DRC error แบบกราฟิก 

## สิ่งที่ควรตรวจสอบใน KLayout

1. Die boundary
2. Core boundary
3. Standard cell rows
4. Power rails
5. Signal routing
6. Via placement
7. Fill cells
8. Top-level pins
9. Clock routing
10. DRC marker database

---

# 10.25 การเปิด Layout ด้วย Magic

ค้นหา `.mag`

```bash
MAG_FILE=$(find runs \
    -type f \
    -name '*.mag' \
    | sort \
    | tail -1)

echo "${MAG_FILE}"
```

เปิด Magic

```bash
magic -rcfile "${PDK_ROOT}/sky130A/libs.tech/magic/sky130A.magicrc" \
    "${MAG_FILE}"
```

ตำแหน่ง `PDK_ROOT` และชื่อ Magic RC file ขึ้นกับ environment

ในบาง environment สามารถเปิดผ่าน shell ของ LibreLane/PDK เพื่อให้ technology setup ถูกโหลดอัตโนมัติ

ภายใน Magic สามารถใช้คำสั่งตัวอย่าง

```tcl
drc check
drc count
drc find
```

หรือเลือกพื้นที่ที่มี violation แล้วใช้

```tcl
drc why
```

คำสั่งที่รองรับจริงขึ้นกับ Magic version และ startup configuration

---

# 10.26 การแปลผล DRC Violation

## 10.26.1 Minimum Width Violation

ตัวอย่างแนวคิด

```text
Required metal width >= Wmin
Actual width          < Wmin
```

สาเหตุที่เป็นไปได้

- Routing geometry แคบเกินไป
- Custom geometry ไม่ตรง manufacturing grid
- Stream-out mapping ไม่ถูกต้อง
- Macro obstruction ไม่สมบูรณ์

แนวทางแก้ไข

- ตรวจ routing layer
- เพิ่ม routing resources
- ตรวจ macro LEF
- ตรวจ manufacturing grid
- รัน detailed routing ใหม่
- หลีกเลี่ยง manual geometry ที่ไม่ตรง rule

## 10.26.2 Minimum Spacing Violation

```text
Metal A |<-- spacing -->| Metal B
                 spacing < minimum
```

สาเหตุ

- Congestion สูง
- Core utilization สูง
- Pin กระจุกตัว
- Macro placement ไม่เหมาะสม
- Routing channel แคบเกินไป

แนวทางแก้ไข

```yaml
FP_CORE_UTIL: 30
PL_TARGET_DENSITY_PCT: 40
```

หรือเพิ่ม die/core area

## 10.26.3 Via Enclosure Violation

เกิดเมื่อโลหะรอบ via ไม่ครอบคลุม via ตามข้อกำหนด

สาเหตุ

- Route ที่มุมแคบ
- Via อยู่ใกล้ปลาย segment
- Stream-out issue
- PDK rule-deck mismatch

แนวทางแก้ไข

- รัน detailed routing ใหม่
- ลด congestion
- ตรวจ routing layer constraints
- ตรวจ PDK version

## 10.26.4 Minimum Area Violation

เส้นโลหะสั้นเกินไปจนมีพื้นที่รวมต่ำกว่าค่าที่กำหนด

แนวทางแก้ไข

- ให้ Router เติม metal extension
- ตรวจ min-area repair
- ลด routing congestion
- ปรับ pin placement

## 10.26.5 Off-grid Violation

เกิดเมื่อ geometry ไม่อยู่บน manufacturing grid

แนวทางแก้ไข

- หลีกเลี่ยงพิกัดที่กำหนดด้วยทศนิยมโดยไม่อิง site/grid
- ตรวจ custom DEF
- ตรวจ macro origin
- ตรวจ LEF unit
- ตรวจ PDK-specific site dimensions

---

# 10.27 การแปลผล LVS Mismatch

## 10.27.1 Top-level Cell Name Mismatch

อาการ

```text
Layout cell: counter
Schematic cell: counter_top
```

ตรวจสอบ

```yaml
DESIGN_NAME: counter
```

และ

```systemverilog
module counter (...);
```

ต้องตรงกัน

## 10.27.2 Pin List Mismatch

อาการ

```text
Layout pins:
clk rst_n enable count[0] ...

Schematic pins:
clk reset_n enable count[0] ...
```

แนวทางแก้ไข

- ตรวจ RTL port name
- ตรวจ synthesized netlist
- ตรวจ extracted SPICE `.subckt`
- ตรวจ pin label ใน Layout
- หลีกเลี่ยงการเปลี่ยนชื่อ port ระหว่าง wrapper กับ core

## 10.27.3 Power/Ground Mismatch

อาการที่พบบ่อย

```text
Layout: VPWR VGND
Netlist: VDD VSS
```

หรือ

```text
Unmatched net: VPWR
Unmatched net: VDD
```

แนวทางตรวจสอบ

1. ตรวจชื่อ power pin ของ standard cell
2. ตรวจ PDK-specific standard-cell library
3. ตรวจ global power connections
4. ตรวจ `USE_POWER_PINS` ถ้ามี wrapper หรือ macro
5. ตรวจ power net ที่สร้างโดย PDN
6. ตรวจ extracted netlist
7. ตรวจ schematic netlist ที่ส่งเข้า LVS

ตัวอย่าง RTL macro ที่เปิด power pin แบบ explicit

```systemverilog
module counter (
`ifdef USE_POWER_PINS
    inout VPWR,
    inout VGND,
`endif
    input  logic       clk,
    input  logic       rst_n,
    input  logic       enable,
    output logic [7:0] count
);
```

ไม่ควรเพิ่ม power pins โดยไม่ตรวจ conventions ของ PDK และ Flow เพราะแต่ละ standard-cell library อาจใช้ชื่อแตกต่างกัน

## 10.27.4 Missing Instance

อาการ

```text
Instance exists in schematic
but not found in layout
```

สาเหตุ

- Instance ถูก optimize ออก
- Black-box macro ไม่มี physical view
- LEF/GDS ของ macro ไม่ถูกโหลด
- Netlist สำหรับ LVS ไม่ใช่ post-PNR netlist
- Instance name transformation

แนวทางแก้ไข

- ตรวจ synthesized netlist
- ตรวจ post-PNR netlist
- ตรวจ macro LEF
- ตรวจ macro GDS
- ตรวจ SPICE model
- ตรวจ black-box declarations

## 10.27.5 Extra Instance

สาเหตุที่เป็นไปได้

- Fill cell หรือ tap cell ถูกนับผิด
- Physical-only cell ไม่มี matching rule
- Extraction setup ไม่รู้จัก primitive
- PDK LVS setup ไม่ได้ filter physical cells

แนวทางแก้ไข

- ตรวจชนิดของ extra instance
- ตรวจว่าเป็น tap, filler, endcap หรือ diode
- ตรวจ Netgen setup ของ PDK
- ไม่ควรลบ physical-only cell โดยตรงเพียงเพื่อให้ LVS ผ่าน

## 10.27.6 Shorted Nets

อาการ

```text
Net A and Net B are merged in layout
```

สาเหตุ

- Metal overlap
- Via เชื่อมผิด layer
- Power strap ทับ signal
- Pin label อยู่บน geometry ผิด net
- Macro obstruction ไม่ครบ

แนวทางแก้ไข

- เปิด Layout ตรงพิกัดปัญหา
- ตรวจ route geometry
- ตรวจ via stack
- ตรวจ PDN
- ตรวจ pin label
- รัน routing ใหม่

## 10.27.7 Open Nets

อาการ

```text
One schematic net corresponds to multiple layout nets
```

สาเหตุ

- Route ขาด
- Via หาย
- Pin ไม่สัมผัสกับ wire
- Label ไม่ได้อยู่บน conductive geometry
- Macro pin definition ไม่ตรงกับ GDS

---

# 10.28 Debugging Workflow สำหรับ DRC

ใช้ลำดับต่อไปนี้

```text
DRC Failure
    |
    v
ตรวจว่า Magic หรือ KLayout รายงาน
    |
    v
ระบุ Rule Name และ Layer
    |
    v
ระบุจำนวนและตำแหน่ง Violation
    |
    v
เปิด Layout พร้อม Marker
    |
    v
จำแนก:
Geometry / Congestion / Pin / Macro / Stream-out
    |
    v
แก้ config หรือ Layout source
    |
    v
รันใหม่จาก Step ที่เหมาะสม
    |
    v
ตรวจ DRC ทั้งสองเครื่องมืออีกครั้ง
```

## Checklist

- [ ] จำนวน violation เท่าใด
- [ ] เกิดบน layer ใด
- [ ] เป็น rule ประเภทใด
- [ ] เกิดเฉพาะขอบ die หรือไม่
- [ ] เกิดรอบ macro หรือไม่
- [ ] เกิดที่ pin หรือไม่
- [ ] เกิดจาก PDN หรือ signal route
- [ ] Magic และ KLayout รายงานตำแหน่งเดียวกันหรือไม่
- [ ] ใช้ PDK version เดียวกับ flow หรือไม่
- [ ] GDS stream-out สำเร็จหรือไม่

---

# 10.29 Debugging Workflow สำหรับ LVS

```text
LVS Failure
    |
    v
ตรวจ Top-level Cell
    |
    v
ตรวจ Pin List
    |
    v
ตรวจ Device Count
    |
    v
ตรวจ Net Count
    |
    v
ตรวจ Power/Ground
    |
    v
ตรวจ Unmatched Devices/Nets
    |
    v
เปิด Extracted SPICE
    |
    v
เปรียบเทียบกับ Reference Netlist
    |
    v
แก้ Connectivity หรือ Setup
    |
    v
Extract และรัน LVS ใหม่
```

## Checklist

- [ ] Top-level cell name ตรงกัน
- [ ] Pin count ตรงกัน
- [ ] Pin order และ pin name ตรงกัน
- [ ] Power pin ตรงกัน
- [ ] Ground pin ตรงกัน
- [ ] ไม่มี missing macro
- [ ] มี SPICE model ของทุก macro
- [ ] ใช้ post-PNR netlist ที่ถูกต้อง
- [ ] ไม่มี open net
- [ ] ไม่มี short net
- [ ] Physical-only cell ถูกจัดการตาม setup
- [ ] ผลสุดท้ายเป็น `Circuits match uniquely`

---

# 10.30 การรัน Physical Verification ใหม่หลังแก้ไข

วิธีที่ปลอดภัยที่สุดสำหรับการเรียนการสอนคือสร้าง run ใหม่

```bash
librelane --pdk sky130A config.yaml
```

การสร้าง run ใหม่ช่วยให้

- เปรียบเทียบผลก่อนและหลังได้
- ไม่ทำลายหลักฐานจาก run เดิม
- ลดความสับสนของ state
- ตรวจสอบ reproducibility ได้ง่าย

ตั้งชื่อ tag หาก LibreLane version รองรับ option ดังกล่าว โดยตรวจสอบจาก

```bash
librelane --help
```

---

# 10.31 การทดลองทำให้ DRC/LVS ไม่ผ่านอย่างมีระบบ

การทดลองควรทำกับสำเนาโปรเจกต์ ไม่ควรแก้ run ที่ผ่านแล้วโดยตรง

## การทดลองที่ 1: Top-level Name Mismatch

เปลี่ยน

```yaml
DESIGN_NAME: counter
```

เป็น

```yaml
DESIGN_NAME: counter_top
```

จากนั้นรัน

```bash
librelane --pdk sky130A config.yaml
```

ผลที่คาดหวัง

- Flow หยุดตั้งแต่ Synthesis หรือ Elaborate
- แสดงให้เห็นว่าความสอดคล้องของชื่อ top module เป็นเงื่อนไขพื้นฐานก่อน LVS

คืนค่า

```yaml
DESIGN_NAME: counter
```

## การทดลองที่ 2: Clock Port Mismatch

เปลี่ยน

```yaml
CLOCK_PORT: clk
```

เป็น

```yaml
CLOCK_PORT: clock
```

ผลที่คาดหวัง

- SDC checker หรือ STA รายงานว่าไม่พบ port
- อาจเกิด warning หรือ error ก่อน Physical Verification

## การทดลองที่ 3: Pin Name Mismatch ใน SDC

เปลี่ยน

```tcl
[get_ports enable]
```

เป็น

```tcl
[get_ports en]
```

ผลที่คาดหวัง

- SDC warning
- Constraint ไม่ถูกนำไปใช้กับ input จริง

การทดลองนี้ไม่ได้ทำให้ LVS fail โดยตรง แต่แสดงให้เห็นว่าความสอดคล้องของชื่อมีผลต่อทุกส่วนของ flow

## การทดลองที่ 4: ปิด LVS

```yaml
RUN_LVS: false
```

รันใหม่แล้วตรวจ run directory

ผลที่คาดหวัง

- ไม่มี `Netgen.LVS` step
- ไม่สามารถสรุปว่า design เป็น LVS-clean ได้

จุดสำคัญคือ “Flow จบ” ไม่ได้หมายความว่า “ผ่าน Signoff” ถ้าปิด checker ที่จำเป็น

## การทดลองที่ 5: ปิด DRC หนึ่งชุด

```yaml
RUN_MAGIC_DRC: false
RUN_KLAYOUT_DRC: true
```

ผลที่คาดหวัง

- มีผลเฉพาะ KLayout DRC
- ยังไม่ควรสรุปว่า design ผ่าน DRC ทุกชุดที่ PDK รองรับ

คืนค่า

```yaml
RUN_MAGIC_DRC: true
RUN_KLAYOUT_DRC: true
```

---

# 10.32 ตัวอย่าง config.yaml สำหรับเน้น Physical Verification

ไฟล์ต่อไปนี้เหมาะสำหรับใช้เป็น configuration หลักของ Lab

```yaml
meta:
  version: 2
  flow: Classic

DESIGN_NAME: counter

VERILOG_FILES:
  - dir::src/counter.sv

CLOCK_PORT: clk
CLOCK_PERIOD: 20.0

PNR_SDC_FILE: dir::constraints/pnr.sdc
SIGNOFF_SDC_FILE: dir::constraints/signoff.sdc

FP_SIZING: relative
FP_CORE_UTIL: 35
FP_ASPECT_RATIO: 1.0

PL_TARGET_DENSITY_PCT: 45
GRT_ALLOW_CONGESTION: false

RUN_CTS: true
RUN_POST_CTS_RESIZER_TIMING: true

RUN_ANTENNA_REPAIR: true
RUN_DRT: true
RUN_FILL_INSERTION: true

RUN_SPEF_EXTRACTION: true
RUN_MCSTA: true

RUN_MAGIC_STREAMOUT: true
RUN_KLAYOUT_STREAMOUT: true
RUN_KLAYOUT_XOR: true

RUN_MAGIC_DRC: true
RUN_KLAYOUT_DRC: true
RUN_LVS: true

Odb.CustomIOPlacement:
  IO_PIN_ORDER_CFG: dir::pin_order.cfg
```

---

# 10.33 Configuration สำหรับ Debug DRC

ถ้า DRC violation เกิดจาก routing congestion ให้ทดลองอย่างเป็นลำดับ

## ขั้นที่ 1 ลด Core Utilization

```yaml
FP_CORE_UTIL: 30
```

## ขั้นที่ 2 ลด Placement Density

```yaml
PL_TARGET_DENSITY_PCT: 40
```

## ขั้นที่ 3 ตรวจ Pin Placement

```yaml
Odb.CustomIOPlacement:
  IO_PIN_ORDER_CFG: dir::pin_order.cfg
```

## ขั้นที่ 4 ตรวจ Congestion Policy

```yaml
GRT_ALLOW_CONGESTION: false
```

ไม่แนะนำให้ตั้ง `GRT_ALLOW_CONGESTION: true` เพื่อบังคับให้ flow ผ่านในงาน Signoff เพราะ Global Routing congestion มักส่งผลให้ Detailed Routing ล้มเหลวหรือสร้าง DRC violation จำนวนมาก

## ขั้นที่ 5 เพิ่มพื้นที่

ถ้า relative sizing ยังแออัด ให้ลด utilization หรือใช้ absolute sizing ตาม syntax ที่รองรับใน LibreLane/PDK รุ่นที่ใช้งาน

---

# 10.34 Configuration สำหรับ Debug LVS

LVS ส่วนใหญ่ไม่แก้ด้วยการลด density แต่ต้องตรวจความสอดคล้องของข้อมูล

รายการที่ต้องตรวจใน `config.yaml`

```yaml
DESIGN_NAME: counter

VERILOG_FILES:
  - dir::src/counter.sv

RUN_MAGIC_STREAMOUT: true
RUN_LVS: true
```

สำหรับ macro design ต้องตรวจเพิ่มเติม

```yaml
MACROS:
  macro_name:
    instances:
      instance_name:
        location: [x, y]
        orientation: N
    lef:
      - dir::macros/macro_name.lef
    gds:
      - dir::macros/macro_name.gds
    nl:
      - dir::macros/macro_name.v
```

โครงสร้างการกำหนด macro อาจแตกต่างตาม LibreLane version จึงต้องตรวจ reference manual ของรุ่นที่ติดตั้งก่อนใช้งานจริง

---

# 10.35 เกณฑ์ผ่าน Lab

Lab นี้ถือว่าผ่านเมื่อ

## RTL และ Flow

- [ ] Verilator lint ไม่มี fatal error
- [ ] Synthesis สำเร็จ
- [ ] Floorplan สำเร็จ
- [ ] Placement สำเร็จ
- [ ] CTS สำเร็จ
- [ ] Routing สำเร็จ
- [ ] GDS stream-out สำเร็จ

## DRC

- [ ] Magic DRC violation count เป็น 0
- [ ] KLayout DRC total เป็น 0
- [ ] ไม่มี checker error ที่ถูก waive โดยไม่อธิบาย
- [ ] ไม่พบ geometry error ที่ถูกซ่อนจาก summary

## LVS

- [ ] Extracted SPICE ถูกสร้าง
- [ ] Top-level cell name ตรงกัน
- [ ] Pin lists equivalent
- [ ] Device classes equivalent
- [ ] Final result เป็น `Circuits match uniquely`

## Stream-out

- [ ] Magic GDS ถูกสร้าง
- [ ] KLayout GDS ถูกสร้าง
- [ ] XOR checker ผ่าน หรือมีคำอธิบายตามข้อจำกัดของ PDK

---

# 10.36 Signoff Report Template

ผู้เรียนควรจัดทำรายงานตามรูปแบบต่อไปนี้

## ข้อมูลการออกแบบ

```text
Design Name:
Top Module:
PDK:
LibreLane Version:
Run Directory:
Clock Port:
Clock Period:
Target Frequency:
```

## ผล Implementation

```text
Synthesis:
Floorplan:
Placement:
CTS:
Global Routing:
Detailed Routing:
GDS Stream-out:
```

## ผล Physical Verification

```text
Magic DRC Violations:
KLayout DRC Violations:
KLayout XOR Differences:
Netgen LVS Result:
```

## ผล Timing

```text
Worst Setup Slack:
Worst Hold Slack:
Setup Violations:
Hold Violations:
```

## สรุป

```text
[ ] DRC Clean
[ ] LVS Clean
[ ] XOR Clean
[ ] Timing Clean
[ ] Ready for Signoff Review
```

---

# 10.37 คำถามท้ายบท

1. DRC และ LVS ตรวจสอบคุณสมบัติของ Layout ต่างกันอย่างไร
2. เพราะเหตุใด Layout จึงอาจ DRC-clean แต่ LVS-fail
3. เพราะเหตุใด Layout จึงอาจ LVS-clean แต่ DRC-fail
4. Rule deck มาจากส่วนใดของ ASIC design environment
5. ทำไม LibreLane จึงใช้ทั้ง Magic DRC และ KLayout DRC
6. ข้อความใดใน Netgen report แสดงว่า LVS ผ่าน
7. Open net และ short net ต่างกันอย่างไร
8. ชื่อ power pin ที่ไม่ตรงกันส่งผลต่อ LVS อย่างไร
9. KLayout XOR ใช้ตรวจสอบอะไร
10. เหตุใดการปิด `RUN_LVS` จึงไม่ควรถือว่า design ผ่าน Signoff
11. Core utilization สูงสามารถทำให้ DRC เพิ่มขึ้นได้อย่างไร
12. Macro ที่มี LEF แต่ไม่มี GDS จะส่งผลอย่างไร
13. Macro ที่มี GDS แต่ไม่มี SPICE/LVS model จะส่งผลอย่างไร
14. เหตุใดจึงควรเก็บ run ก่อนและหลังการแก้ไขแยกกัน
15. ผล `Circuits match uniquely` มีความหมายอย่างไร

---

# 10.38 แบบฝึกหัดเพิ่มเติม

## Exercise 10.1 ตรวจสอบ Report

ให้ผู้เรียนค้นหาและบันทึก

- Magic DRC report
- KLayout DRC report
- Netgen LVS report
- Extracted SPICE
- Final GDS

## Exercise 10.2 เปรียบเทียบ DRC Engines

สร้างตารางเปรียบเทียบ

```text
Magic DRC count:
KLayout DRC total:
Rule categories:
Runtime:
Output report format:
```

## Exercise 10.3 วิเคราะห์ Extracted Netlist

เปิด extracted SPICE และตอบ

1. ชื่อ top-level subcircuit คืออะไร
2. มี top-level pin กี่ขา
3. Power และ ground ใช้ชื่ออะไร
4. มี standard-cell instance กี่ตัว
5. Pin order ตรงกับ reference netlist หรือไม่

## Exercise 10.4 ผลของ Utilization

ทดลอง

```yaml
FP_CORE_UTIL: 35
```

และ

```yaml
FP_CORE_UTIL: 60
```

เปรียบเทียบ

- Core area
- Placement density
- Routing congestion
- DRC count
- Runtime
- Timing

## Exercise 10.5 ปิด Physical Verification Step

ทดลองปิดทีละรายการ

```yaml
RUN_MAGIC_DRC: false
RUN_KLAYOUT_DRC: false
RUN_LVS: false
```

อธิบายว่าแต่ละกรณีทำให้หลักฐาน Signoff ส่วนใดหายไป

---

# 10.39 สรุปบทปฏิบัติการ

Physical Verification เป็นขั้นตอนที่ยืนยันว่า Layout

1. สามารถผลิตได้ตามกฎของ PDK
2. มีโครงข่ายไฟฟ้าตรงกับวงจรอ้างอิง
3. ไม่มี geometry violation ที่ตรวจพบ
4. ไม่มี open หรือ short ที่ทำให้วงจรเปลี่ยนไป
5. มี GDSII และ extracted netlist ที่สอดคล้องกัน

ใน LibreLane Classic Flow การตรวจสอบหลักประกอบด้วย

```text
Magic.StreamOut
KLayout.StreamOut
KLayout.XOR
Magic.DRC
KLayout.DRC
Magic.SpiceExtraction
Netgen.LVS
```

ลำดับการตรวจสอบที่แนะนำคือ

```text
ตรวจว่า Routing สำเร็จ
        |
        v
ตรวจ GDS Stream-out
        |
        v
ตรวจ XOR
        |
        v
ตรวจ Magic DRC
        |
        v
ตรวจ KLayout DRC
        |
        v
ตรวจ SPICE Extraction
        |
        v
ตรวจ Netgen LVS
        |
        v
จัดทำ Signoff Checklist
```

ผลที่ต้องการสำหรับ Lab คือ

```text
Magic DRC       : 0 violations
KLayout DRC     : 0 violations
Netgen LVS      : Circuits match uniquely
Physical Status : DRC-clean and LVS-clean
```

อย่างไรก็ตาม การผ่าน DRC และ LVS เพียงอย่างเดียวยังไม่ใช่ Tapeout Signoff ทั้งหมด การออกแบบจริงยังต้องตรวจสอบ Timing, Antenna, IR Drop, Power Integrity, Density, Reliability และกฎเฉพาะของโรงงานผลิตเพิ่มเติม
