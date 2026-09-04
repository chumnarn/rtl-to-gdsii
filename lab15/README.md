 **Lab 15 Full-Chip Design with I/O Pads**  

> **ข้อควรทราบ:** ชื่อเซลล์ I/O pad, corner pad, power pad และชื่อขาไฟแตกต่างกันตาม PDK การทดลองนี้จึงแยกส่วนที่เป็น **LibreLane มาตรฐาน** ออกจากส่วนที่ต้องปรับตาม I/O library ของ PDK อย่างชัดเจน
> LibreLane `Chip` flow ถูกออกแบบสำหรับ complete-chip implementation และเพิ่มขั้นตอน pad-ring generation, seal-ring generation, filler insertion และ density checking จาก flow ปกติ ([LibreLane][1])

# Lab 15 Full-Chip Design with I/O Pads

## 15.1 วัตถุประสงค์

บทปฏิบัติการนี้นำวงจรดิจิทัลระดับ core มาสร้างเป็นวงจรรวมระดับ full-chip ซึ่งประกอบด้วย

1. วงจรดิจิทัลภายในหรือ core logic
2. Full-chip wrapper
3. Input pads
4. Output pads
5. Clock pad
6. Reset pad
7. Power และ ground pads
8. Corner pads
9. Pad fillers
10. Core power distribution network
11. Seal ring และ metal density structures
12. GDSII สำหรับตรวจสอบทางกายภาพ

หลังจบการทดลอง ผู้เรียนจะสามารถ

* อธิบายความแตกต่างระหว่าง core-level และ chip-level design
* สร้าง RTL wrapper สำหรับเชื่อม core logic กับ I/O pads
* จัดเรียง pad instances รอบ die
* กำหนด full-chip floorplan
* สร้าง `config.yaml` สำหรับ LibreLane
* ใช้ LibreLane `Chip` flow
* ตรวจสอบ clock, reset, power และ ground connectivity
* วิเคราะห์ pad-ring placement
* ตรวจสอบ routing, timing, antenna, DRC และ LVS
* ระบุปัญหาที่มักเกิดขึ้นใน full-chip implementation

---

# 15.2 ภาพรวม Full-Chip Design

## 15.2.1 Core-level design

ใน Lab ก่อนหน้า top-level module มักประกอบด้วย logic ports เช่น

```text
clk
rst_n
enable
count[7:0]
```

พอร์ตเหล่านี้ถือเป็น logical ports ซึ่ง OpenROAD สามารถสร้าง metal pins บริเวณขอบ core ได้โดยตรง

โครงสร้างโดยทั่วไปคือ

```text
Core boundary
+--------------------------------+
|                                |
|       Standard-cell logic      |
|                                |
| clk                      q[7:0]|
+--------------------------------+
```

โครงสร้างนี้เหมาะสำหรับ

* IP block
* Hard macro
* Digital core
* Hierarchical block
* Block-level timing closure

แต่ยังไม่ใช่ชิปที่สามารถเชื่อมต่อกับ package โดยตรง

---

## 15.2.2 Full-chip design

Full-chip design เพิ่ม I/O pad cells ระหว่างวงจรภายในกับขาเชื่อมต่อภายนอก

```text
                    Bonding pads
       +---------------------------------------+
       |     PAD   PAD   PAD   PAD   PAD       |
       |                                       |
       | PAD  +--------------------------+ PAD | 
       |      |                          |     |
       | PAD  |        Digital Core      | PAD |
       |      |                          |     |
       | PAD  +--------------------------+ PAD |
       |                                       |
       |     PAD   PAD   PAD   PAD   PAD       |
       +---------------------------------------+
```

I/O pad cells อาจมีวงจรเพิ่มเติม เช่น

* ESD protection
* Input buffer
* Output driver
* Tri-state control
* Slew-rate control
* Pull-up หรือ pull-down
* Level shifting
* Schmitt trigger
* Power clamp
* Core-to-pad isolation

ดังนั้น I/O pad ไม่ควรถูกแทนด้วย standard-cell buffer ธรรมดา

---

# 15.3 ความแตกต่างระหว่าง Classic Flow และ Chip Flow

LibreLane มี reference flows หลัก ได้แก่ `Classic` และ `Chip` โดย `Classic` เหมาะกับวงจรทั่วไปจาก RTL ถึง GDSII ส่วน `Chip` เพิ่มขั้นตอนที่จำเป็นสำหรับ complete-chip design เช่น pad ring, seal ring, filler และ density check ([LibreLane][2])

## Classic flow

```text
RTL
 ↓
Synthesis
 ↓
Floorplan
 ↓
Placement
 ↓
CTS
 ↓
Routing
 ↓
GDSII
```

## Chip flow

```text
Full-chip RTL
 ↓
Synthesis
 ↓
Floorplan
 ↓
Pad-ring generation
 ↓
Core PDN
 ↓
Placement
 ↓
CTS
 ↓
Routing
 ↓
GDSII stream-out
 ↓
Antenna check
 ↓
Seal ring
 ↓
Filler insertion
 ↓
Density check
 ↓
DRC/LVS
```

เรียก flow ด้วยคำสั่ง

```bash
librelane --flow Chip config.yaml
```

LibreLane documentation ระบุรูปแบบ CLI ของ flow นี้เป็น

```bash
librelane --flow Chip [...]
```

และใช้ `OpenROAD.PadRing` สำหรับประกอบ pad ring บนฐานข้อมูล ODB หลัง floorplanning ([LibreLane][1])

---

# 15.4 สถาปัตยกรรมของวงจรตัวอย่าง

วงจรตัวอย่างใช้ counter ขนาด 8 บิต

## External pad interface

```text
clk_PAD
rst_n_PAD
enable_PAD
count_PAD[7:0]
```

## Internal core interface

```text
clk_core
rst_n_core
enable_core
count_core[7:0]
```

## Signal flow

```text
clk_PAD
   │
   ▼
Clock Input Pad
   │
   ▼
clk_core
   │
   ▼
+----------------+
| counter_core   |
+----------------+
   │
   ▼
count_core[7:0]
   │
   ▼
Output Pads
   │
   ▼
count_PAD[7:0]
```

ต้องแยกชื่อ external pad signal กับ internal core signalอย่างชัดเจน เพื่อป้องกันการเชื่อมต่อผิดและช่วยให้ตรวจสอบ LVS ได้ง่าย

---

# 15.5 โครงสร้างไดเรกทอรี

สร้างโครงสร้างดังนี้

```text
lab15_full_chip/
├── config.yaml
├── Makefile
├── src/
│   ├── counter_core.sv
│   ├── chip_top.sv
│   └── io_cells_stub.v
├── constraints/
│   ├── pnr.sdc
│   └── signoff.sdc
├── pad/
│   └── padframe.cfg
├── scripts/
│   ├── check_design.sh
│   ├── inspect_pads.tcl
│   └── report_results.sh
└── runs/
```

สร้างไดเรกทอรีด้วยคำสั่ง

```bash
mkdir -p lab15_full_chip/{src,constraints,pad,scripts,runs}
cd lab15_full_chip
```

---

# 15.6 ขั้นตอนที่ 1: สร้าง Core RTL

สร้างไฟล์

```text
src/counter_core.sv
```

เนื้อหา

```systemverilog
`default_nettype none

module counter_core #(
    parameter int WIDTH = 8
) (
    input  logic             clk_i,
    input  logic             rst_ni,
    input  logic             enable_i,
    output logic [WIDTH-1:0] count_o
);

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            count_o <= '0;
        end else if (enable_i) begin
            count_o <= count_o + 1'b1;
        end
    end

endmodule

`default_nettype wire
```

## อธิบายวงจร

* `clk_i` เป็น clock ภายใน core
* `rst_ni` เป็น asynchronous reset แบบ active-low
* `enable_i` ควบคุมการนับ
* `count_o` เป็นผลลัพธ์ขนาด 8 บิต
* `default_nettype none` ป้องกันการสร้าง implicit nets จากการสะกดชื่อสัญญาณผิด

---

# 15.7 ขั้นตอนที่ 2: ทำความเข้าใจ I/O Cell Interface

I/O library แต่ละ PDK ใช้ชื่อ module และชื่อ pin แตกต่างกัน ตัวอย่างเชิงแนวคิดของ input pad คือ

```systemverilog
PAD_INPUT u_clk_pad (
    .PAD (clk_PAD),
    .Y   (clk_core)
);
```

ตัวอย่าง output pad คือ

```systemverilog
PAD_OUTPUT u_count_pad (
    .A   (count_core[0]),
    .PAD (count_PAD[0])
);
```

อย่างไรก็ตาม pad library จริงอาจใช้ชื่อขา เช่น

```text
PAD
Y
A
I
O
IN
OUT
C
OE
EN
PUEN
PDEN
VDD
VSS
VDDIO
VSSIO
```

จึงต้องตรวจสอบ Verilog model, LEF และ CDL/SPICE ของ PDK ก่อนเขียน wrapper

---

# 15.8 ขั้นตอนที่ 3: ตรวจสอบ Pad Library ของ PDK

ตรวจสอบค่า PDK root

```bash
echo "$PDK_ROOT"
```

หรือกรณีใช้ Ciel

```bash
ls ~/.ciel
```

ค้นหาไฟล์ที่เกี่ยวข้องกับ I/O cells

```bash
find "$PDK_ROOT" \
    \( -iname "*io*.lef" \
    -o -iname "*pad*.lef" \
    -o -iname "*io*.v" \
    -o -iname "*pad*.v" \
    -o -iname "*io*.gds" \
    -o -iname "*pad*.gds" \) \
    2>/dev/null | sort
```

ค้นหาชื่อ module ใน Verilog model

```bash
grep -R "^module .*Pad\|^module .*PAD\|^module .*IO" \
    "$PDK_ROOT" 2>/dev/null | head -100
```

ตรวจสอบชื่อ macro ใน LEF

```bash
grep -R "^MACRO " "$PDK_ROOT" 2>/dev/null |
grep -Ei "pad|corner|fill|io" |
head -100
```

## สิ่งที่ต้องบันทึก

สร้างตาราง pad inventory

| หน้าที่           | ชื่อเซลล์    | ขาสัญญาณ      | ขาไฟ    | LEF | GDS | Verilog |
| ----------------- | ------------ | ------------- | ------- | --- | --- | ------- |
| Input pad         | PDK-specific | PAD, Y        | VDD/VSS | มี  | มี  | มี      |
| Output pad        | PDK-specific | A, PAD        | VDD/VSS | มี  | มี  | มี      |
| Bidirectional pad | PDK-specific | A, Y, OE, PAD | VDD/VSS | มี  | มี  | มี      |
| Power pad         | PDK-specific | VDD           | —       | มี  | มี  | มี      |
| Ground pad        | PDK-specific | VSS           | —       | มี  | มี  | มี      |
| Corner pad        | PDK-specific | —             | —       | มี  | มี  | มี      |
| Filler pad        | PDK-specific | —             | —       | มี  | มี  | มี      |

ห้ามคาดเดาชื่อ pin จากชื่อเซลล์ ต้องเปิดดู module declaration จริงเสมอ

---

# 15.9 ขั้นตอนที่ 4: สร้าง I/O Cell Stub สำหรับตรวจ RTL

ในช่วงตรวจ syntax สามารถใช้ stub model ได้ แต่ห้ามใช้ stub แทน physical model ใน signoff flow

สร้างไฟล์

```text
src/io_cells_stub.v
```

```systemverilog
`default_nettype none

module PAD_INPUT (
    inout  wire PAD,
    output wire Y
);
    assign Y = PAD;
endmodule

module PAD_OUTPUT (
    input  wire A,
    inout  wire PAD
);
    assign PAD = A;
endmodule

module PAD_POWER (
    inout wire PAD
);
endmodule

module PAD_GROUND (
    inout wire PAD
);
endmodule

module PAD_CORNER;
endmodule

`default_nettype wire
```

ไฟล์นี้มีไว้สำหรับ

* RTL lint
* elaboration
* functional simulation
* ตรวจชื่อ instances

สำหรับ LibreLane จริงต้องให้ PDK หรือ `EXTRA_VERILOG_MODELS` จัดเตรียม black-box model ที่ตรงกับ LEF/GDS

---

# 15.10 ขั้นตอนที่ 5: สร้าง Full-Chip Wrapper

สร้างไฟล์

```text
src/chip_top.sv
```

```systemverilog
`default_nettype none

module chip_top (
    inout wire       clk_PAD,
    inout wire       rst_n_PAD,
    inout wire       enable_PAD,
    inout wire [7:0] count_PAD,
    inout wire       vdd_PAD,
    inout wire       vss_PAD
);

    wire       clk_core;
    wire       rst_n_core;
    wire       enable_core;
    wire [7:0] count_core;

    // ------------------------------------------------------------
    // Input pads
    // ------------------------------------------------------------

    PAD_INPUT u_pad_clk (
        .PAD (clk_PAD),
        .Y   (clk_core)
    );

    PAD_INPUT u_pad_rst_n (
        .PAD (rst_n_PAD),
        .Y   (rst_n_core)
    );

    PAD_INPUT u_pad_enable (
        .PAD (enable_PAD),
        .Y   (enable_core)
    );

    // ------------------------------------------------------------
    // Digital core
    // ------------------------------------------------------------

    counter_core #(
        .WIDTH (8)
    ) u_core (
        .clk_i    (clk_core),
        .rst_ni   (rst_n_core),
        .enable_i (enable_core),
        .count_o  (count_core)
    );

    // ------------------------------------------------------------
    // Output pads
    // ------------------------------------------------------------

    PAD_OUTPUT u_pad_count_0 (
        .A   (count_core[0]),
        .PAD (count_PAD[0])
    );

    PAD_OUTPUT u_pad_count_1 (
        .A   (count_core[1]),
        .PAD (count_PAD[1])
    );

    PAD_OUTPUT u_pad_count_2 (
        .A   (count_core[2]),
        .PAD (count_PAD[2])
    );

    PAD_OUTPUT u_pad_count_3 (
        .A   (count_core[3]),
        .PAD (count_PAD[3])
    );

    PAD_OUTPUT u_pad_count_4 (
        .A   (count_core[4]),
        .PAD (count_PAD[4])
    );

    PAD_OUTPUT u_pad_count_5 (
        .A   (count_core[5]),
        .PAD (count_PAD[5])
    );

    PAD_OUTPUT u_pad_count_6 (
        .A   (count_core[6]),
        .PAD (count_PAD[6])
    );

    PAD_OUTPUT u_pad_count_7 (
        .A   (count_core[7]),
        .PAD (count_PAD[7])
    );

    // ------------------------------------------------------------
    // Supply pads
    // ------------------------------------------------------------

    PAD_POWER u_pad_vdd (
        .PAD (vdd_PAD)
    );

    PAD_GROUND u_pad_vss (
        .PAD (vss_PAD)
    );

    // ------------------------------------------------------------
    // Corner pad instances
    // ------------------------------------------------------------

    PAD_CORNER u_corner_sw ();
    PAD_CORNER u_corner_se ();
    PAD_CORNER u_corner_ne ();
    PAD_CORNER u_corner_nw ();

endmodule

`default_nettype wire
```

## ข้อสังเกต

ชื่อ instance มีความสำคัญ เพราะ `PAD_SOUTH`, `PAD_EAST`, `PAD_NORTH` และ `PAD_WEST` อ้างถึง **instance name** ไม่ใช่ module name

ตัวอย่าง

```yaml
PAD_SOUTH:
  - u_pad_clk
  - u_pad_rst_n
```

หมายถึง instances

```systemverilog
u_pad_clk
u_pad_rst_n
```

---

# 15.11 ขั้นตอนที่ 6: ปรับ Wrapper ให้ตรงกับ PDK จริง

สมมติ PDK ใช้ชื่อเซลล์ดังนี้

```text
PAD_IN_CELL
PAD_OUT_CELL
PAD_VDD_CELL
PAD_VSS_CELL
PAD_CORNER_CELL
```

ให้เปลี่ยนจาก

```systemverilog
PAD_INPUT
PAD_OUTPUT
PAD_POWER
PAD_GROUND
PAD_CORNER
```

เป็นชื่อจริงของ PDK

นอกจากนี้ต้องปรับชื่อขา เช่น

```systemverilog
PAD_IN_CELL u_pad_clk (
    .pad (clk_PAD),
    .dout(clk_core)
);
```

หรือ

```systemverilog
PAD_OUT_CELL u_pad_count_0 (
    .din (count_core[0]),
    .pad (count_PAD[0])
);
```

การใช้ชื่อขาผิดอาจทำให้เกิดปัญหา

* Yosys unmapped cell
* missing pin
* OpenDB macro pin mismatch
* disconnected pad signal
* LVS mismatch
* power pin not connected

---

# 15.12 ขั้นตอนที่ 7: วางแผน Pad Ring

กำหนดทิศทางของ pads ตัวอย่างดังนี้

## South side

```text
u_corner_sw
u_pad_clk
u_pad_rst_n
u_pad_enable
u_corner_se
```

## East side

```text
u_pad_count_0
u_pad_count_1
u_pad_count_2
u_pad_count_3
```

## North side

```text
u_corner_ne
u_pad_vdd
u_pad_vss
u_corner_nw
```

## West side

```text
u_pad_count_7
u_pad_count_6
u_pad_count_5
u_pad_count_4
```

เมื่อมองจากด้านบนของ die ลำดับ pad ต้องสอดคล้องกับ orientation ของแต่ละด้าน

```text
                 NORTH
       +-------------------------+
       | corner VDD VSS corner   |
       |                         |
 WEST  |                         | EAST
       |                         |
       |                         |
       +-------------------------+
        corner CLK RST EN corner
                 SOUTH
```

## หลักการจัดวาง

* Clock pad ควรอยู่ใกล้ตำแหน่ง clock entry
* Reset pad ไม่ควรอยู่ไกลจาก reset distribution มากเกินไป
* Output bus ควรวางเรียงตามลำดับบิต
* Power/ground pads ควรกระจายรอบ die
* หลีกเลี่ยงการรวม output drivers กระแสสูงไว้จุดเดียว
* Corner pads ต้องตรงกับ orientation ของมุม
* ต้องมี filler pads ปิดช่องว่างระหว่าง I/O cells
* ต้องคำนึงถึง bond-wire crossing และ package pinout

---

# 15.13 ขั้นตอนที่ 8: สร้าง Timing Constraints

## 15.13.1 PnR SDC

สร้างไฟล์

```text
constraints/pnr.sdc
```

```tcl
# ================================================================
# Lab 15: Full-Chip PnR Constraints
# ================================================================

set clock_port clk_PAD
set clock_period 20.0

create_clock \
    -name core_clk \
    -period $clock_period \
    [get_ports $clock_port]

set_clock_uncertainty 0.25 [get_clocks core_clk]
set_clock_transition 0.15 [get_clocks core_clk]

# Input delays represent external source + package + pad delay budget.
set_input_delay 2.0 \
    -clock core_clk \
    [get_ports {rst_n_PAD enable_PAD}]

# Output delay represents receiver and board timing budget.
set_output_delay 4.0 \
    -clock core_clk \
    [get_ports {count_PAD[*]}]

# Reset is asynchronous and should not be treated as a normal data path.
set_false_path \
    -from [get_ports rst_n_PAD]

# Conservative external load applied to output pads.
set_load 0.033442 \
    [get_ports {count_PAD[*]}]
```

## 15.13.2 Signoff SDC

สร้างไฟล์

```text
constraints/signoff.sdc
```

```tcl
set clock_port clk_PAD
set clock_period 20.0

create_clock \
    -name core_clk \
    -period $clock_period \
    [get_ports $clock_port]

set_clock_uncertainty 0.25 [get_clocks core_clk]
set_clock_transition 0.15 [get_clocks core_clk]

set_input_delay 2.0 \
    -clock core_clk \
    [get_ports {rst_n_PAD enable_PAD}]

set_output_delay 4.0 \
    -clock core_clk \
    [get_ports {count_PAD[*]}]

set_false_path \
    -from [get_ports rst_n_PAD]

set_load 0.033442 \
    [get_ports {count_PAD[*]}]
```

## Clock port ต้องเป็นพอร์ตใด

หาก clock เข้ามาจากภายนอกผ่าน pad

```text
clk_PAD → input pad → clk_core → core
```

`CLOCK_PORT` ควรเป็น top-level external clock port

```yaml
CLOCK_PORT: clk_PAD
```

ไม่ใช่ `clk_core` เพราะ `clk_core` เป็น internal net ไม่ใช่ top-level port

LibreLane อนุญาตให้กำหนด `CLOCK_PORT` เป็นชื่อพอร์ต clock และถ้าต้องการให้ root clock buffer เริ่มจาก net อื่น สามารถใช้ `CLOCK_NET` แยกต่างหากได้ ([LibreLane][3])

ตัวอย่าง

```yaml
CLOCK_PORT: clk_PAD
CLOCK_NET: clk_core
```

การใช้ `CLOCK_NET` ต้องตรวจสอบว่า flow และ pad model สามารถติดตาม clock path ผ่าน I/O pad ได้ถูกต้อง

---

# 15.14 ขั้นตอนที่ 9: กำหนด Full-Chip Floorplan

ต่างจาก core-level design ที่มักใช้ utilization-based sizing การออกแบบ full-chip ควรกำหนด die area แบบ explicit

ตัวอย่าง

```yaml
DIE_AREA:
  - 0
  - 0
  - 1600
  - 1600
```

LibreLane กำหนด `DIE_AREA` เป็นสี่พิกัด

```text
x0 y0 x1 y1
```

หน่วยไมโครเมตร ([LibreLane][3])

## การประมาณขนาด die

กำหนด

```text
Wpad = ความกว้าง pad
Nside = จำนวน pad มากที่สุดในหนึ่งด้าน
S = spacing ระหว่าง pads
M = margin สำหรับ corner และ filler
```

ประมาณความยาวด้านหนึ่งได้จาก

```text
Die width ≥ Nside × Wpad + (Nside - 1) × S + M
```

ต้องเผื่อพื้นที่สำหรับ

* pad depth
* pad-to-core spacing
* power ring
* routing channel
* seal ring
* scribe-line constraint
* bond-pad overhang
* corner cells

## Core area กับ die area

```text
Die boundary
+------------------------------------------+
|             I/O pad ring                 |
|    +--------------------------------+    |
|    |          Core area             |    |
|    |                                |    |
|    |      Standard-cell region      |    |
|    |                                |    |
|    +--------------------------------+    |
|             I/O pad ring                 |
+------------------------------------------+
```

หาก die เล็กเกินไปอาจเกิด

* pad overlap
* corner overlap
* insufficient routing channel
* core rows ชน I/O pads
* PDN ring ไม่มีพื้นที่
* detailed routing congestion
* seal ring overlap

---

# 15.15 ขั้นตอนที่ 10: สร้าง config.yaml

LibreLane รองรับ YAML โดยตรง และแนะนำ YAML/JSON สำหรับ configuration ที่ตรงไปตรงมา ปลอดภัย และเหมาะกับการเก็บใน version control ([LibreLane][4])

สร้างไฟล์

```text
config.yaml
```

ตัวอย่างแม่แบบ

```yaml
# ================================================================
# Lab 15: Full-Chip Design with I/O Pads
# LibreLane Chip Flow
# ================================================================

meta:
  version: 3
  flow: Chip
  substituting_steps:

   # Magic can report benign overlap markers around some pad structures.
    Checker.IllegalOverlap: null

    # Disable KLayout DRC
    KLayout.DRC: null
    Checker.KLayoutDRC: null

    # Disable magic DRC
    Magic.DRC: null
    Checker.MagicDRC: null

    # Disable KLayout antenna check
    #KLayout.Antenna: null
    #Checker.KLayoutAntenna: null

    # Disable KLayout density check
    #KLayout.Density: null
    #Checker.KLayoutDensity: null

    # Save time
    #OpenROAD.IRDropReport: null
    #KLayout.XOR: null
    #Netgen.LVS: null
    #Checker.LVS: null


DESIGN_NAME: chip_top
PDK: ihp-sg13g2
STD_CELL_LIBRARY: sg13g2_stdcell

VERILOG_FILES:
 - dir::src/counter_core.sv
 - dir::src/chip_top.sv

VERILOG_DEFINES:
 - FUNCTIONAL

# Enable the newer SystemVerilog frontend when available.
USE_SLANG: true

PRIMARY_GDSII_STREAMOUT_TOOL: klayout

# ------------------------------------------------------------
# Pad-ring order; these are synthesized instance names.
# ------------------------------------------------------------

PAD_SOUTH: [
   clk_pad,
   rst_n_pad,
   enable_pad
]

PAD_EAST: [
   "outputs\\[0\\].output_pad",
   "outputs\\[1\\].output_pad",
   "outputs\\[2\\].output_pad",
   "outputs\\[3\\].output_pad"
]

PAD_NORTH: [
   "outputs\\[7\\].output_pad",
   "outputs\\[6\\].output_pad",
   "outputs\\[5\\].output_pad",
   "outputs\\[4\\].output_pad"
]

PAD_WEST: [
   "vdd_pads\\[0\\].vdd_pad",
   "vss_pads\\[0\\].vss_pad",
   "iovdd_pads\\[0\\].iovdd_pad",
   "iovss_pads\\[0\\].iovss_pad"
]
# ------------------------------------------------------------
# Timing
# ------------------------------------------------------------
# SDC files
PNR_SDC_FILE: dir::constraints/chip_top.sdc
SIGNOFF_SDC_FILE: dir::constraints/chip_top.sdc
FALLBACK_SDC: dir::constraints/chip_top.sdc

CLOCK_PORT: clk_PAD
CLOCK_NET: clk_pad/p2c

CLOCK_PERIOD: 20.0

# ------------------------------------------------------------
# Floorplan
# ------------------------------------------------------------

FP_SIZING: absolute

DIE_AREA: [0, 0, 1600, 1600]
CORE_AREA: [365, 365, 1235, 1235]

PL_TARGET_DENSITY_PCT: 10
GRT_ALLOW_CONGESTION: true

# ------------------------------------------------------------
# Power distribution
# ------------------------------------------------------------

VDD_NETS:
  - VDD

GND_NETS:
  - VSS

# PDN
PDN_CORE_RING: true

PDN_CORE_RING_VWIDTH: 15
PDN_CORE_RING_HWIDTH: 15

PDN_CORE_RING_VSPACING: 5
PDN_CORE_RING_HSPACING: 5
PDN_CORE_RING_CONNECT_TO_PADS: true
PDN_ENABLE_PINS: false

# Multiple supply pads feed the same core supply nets.
MAGIC_EXT_UNIQUE: notopports

# ------------------------------------------------------------
# Bondpads
# ------------------------------------------------------------

PAD_BONDPAD_NAME: bondpad_70x70_novias
PAD_BONDPAD_WIDTH: 70
PAD_BONDPAD_HEIGHT: 70

EXTRA_GDS:
  - dir::ip/bondpad_70x70_novias/gds/bondpad_70x70_novias.gds

EXTRA_LEFS:
  - dir::ip/bondpad_70x70_novias/lef/bondpad_70x70_novias.lef

IGNORE_DISCONNECTED_MODULES:
  - bondpad_70x70_novias

# ------------------------------------------------------------
# Flow checks
# ------------------------------------------------------------

RUN_CTS: true
RUN_ANTENNA_REPAIR: true
RUN_DRT: true
RUN_SPEF_EXTRACTION: true
RUN_MCSTA: true
RUN_IRDROP_REPORT: false

ERROR_ON_DISCONNECTED_PINS: true
ERROR_ON_TR_DRC: true
ERROR_ON_LVS_ERROR: true
ERROR_ON_MAGIC_DRC: true
ERROR_ON_KLAYOUT_DRC: true

MAGIC_GDS_FLATGLOB:
  - "*_CELL_CORNER"
  - "*_CELL_SUB"
  - "RSC_*"
  - "VIA_M1_*"
  - "VIA_M2_*"

# Due to OpenROAD bug
# https://github.com/The-OpenROAD-Project/OpenROAD/issues/8229
#PL_TIME_DRIVEN: False
#PL_ROUTABILITY_DRIVEN: False

# Because we have multiple power pads for one power domain
MAGIC_EXT_UNIQUE: notopports

# ------------------------------------------------
# PDK-specific section
# Select and edit one section for the actual PDK.
# ------------------------------------------------

pdk::ihp-sg13g2:
  STD_CELL_LIBRARY: sg13g2_stdcell

pdk::sky130A:
  STD_CELL_LIBRARY: sky130_fd_sc_hd

pdk::gf180mcuD:
  FP_CORE_UTIL: 30
  PL_TARGET_DENSITY_PCT: 40
```

## ตัวแปรสำคัญของ Pad Ring

LibreLane `OpenROAD.PadRing` รองรับตัวแปรหลักดังนี้

| ตัวแปร      | ความหมาย                                  |
| ----------- | ----------------------------------------- |
| `PAD_CFG`   | ไฟล์ Tcl สำหรับกำหนด pad ring แบบกำหนดเอง |
| `PAD_SOUTH` | รายชื่อ pad instances ด้านใต้             |
| `PAD_EAST`  | รายชื่อ pad instances ด้านขวา             |
| `PAD_NORTH` | รายชื่อ pad instances ด้านเหนือ           |
| `PAD_WEST`  | รายชื่อ pad instances ด้านซ้าย            |

ตัวแปรทั้งสี่ด้านต้องใช้ **instance names** และสามารถใช้ `PAD_CFG` แทนได้ในกรณีต้องควบคุมตำแหน่งหรือคำสั่ง pad placer แบบละเอียด ([LibreLane][5])

---

# 15.16 ขั้นตอนที่ 11: กำหนด PDK ใน config.yaml หรือ CLI

สามารถกำหนด PDK ในไฟล์

```yaml
PDK: ihp-sg13g2
```

หรือส่งจาก command line

```bash
librelane --pdk ihp-sg13g2 --flow Chip config.yaml
```

การส่งจาก CLI เหมาะกับ repository ที่ต้องรองรับหลาย PDK

```bash
librelane --pdk sky130A --flow Chip config.yaml
```

หรือ

```bash
librelane --pdk gf180mcuD --flow Chip config.yaml
```

อย่างไรก็ตาม full-chip flow จะรันได้เมื่อ PDK มีข้อมูลที่จำเป็น เช่น

* I/O pad LEF
* I/O pad GDS
* Verilog black-box models
* CDL/SPICE models
* corner pads
* pad fillers
* compatible site definitions
* KLayout technology files
* DRC runset
* density runset
* seal-ring support ถ้ามี

---

# 15.17 ขั้นตอนที่ 12: เพิ่ม Physical Views ของ I/O Library

หาก PDK ไม่โหลด I/O library อัตโนมัติ ต้องเพิ่ม physical และ logical views

ตัวอย่าง

```yaml
EXTRA_LEFS:
  - dir::pdk/io/io_cells.lef

EXTRA_GDS_FILES:
  - dir::pdk/io/io_cells.gds

EXTRA_VERILOG_MODELS:
  - dir::pdk/io/io_cells.v

EXTRA_SPICE_MODELS:
  - dir::pdk/io/io_cells.spice
```

ชื่อ configuration variable บางส่วนขึ้นอยู่กับเวอร์ชัน LibreLane และ PDK integration ที่ใช้ จึงควรตรวจสอบด้วย

```bash
librelane --help
```

และ

```bash
librelane --flow Chip --help
```

LibreLane มี `EXTRA_LEFS`, `EXTRA_VERILOG_MODELS`, `EXTRA_SPICE_MODELS` และ `EXTRA_CDLS` สำหรับเพิ่ม views ที่ไม่ได้อยู่ใน standard PDK configuration โดยตรง ([LibreLane][3])

## View consistency

ชื่อ macro ต้องตรงกันทุก view

```text
Verilog module name
        =
LEF MACRO name
        =
GDS top-cell name
        =
CDL/SPICE subcircuit name
```

หากไม่ตรงกันอาจเกิด

* unmapped cells
* missing macro master
* empty GDS cells
* LVS subcircuit mismatch
* pins missing from abstract view

---

# 15.18 ขั้นตอนที่ 13: ตรวจ RTL ก่อนรัน LibreLane

## ตรวจด้วย Verilator

```bash
verilator \
    --lint-only \
    --Wall \
    --Wno-DECLFILENAME \
    --Wno-PINMISSING \
    --Wno-MODMISSING \
    --Wno-UNDRIVEN \
    --Wno-UNUSEDSIGNAL \
    --top-module chip_top \
    src/io_cells_stub.v \
    src/counter_core.sv \
    src/chip_top.sv
```

ผลที่คาดหวัง

```text
ไม่มี syntax error
ไม่มี undriven core signal
ไม่มี implicit net
ไม่มี duplicate module
```

## ตรวจด้วย Yosys

```bash
yosys -p '
    read_verilog -sv src/io_cells_stub.v
    read_verilog -sv src/counter_core.sv
    read_verilog -sv src/chip_top.sv
    hierarchy -check -top chip_top
    proc
    check
    stat
'
```

ต้องระวังว่า stub อาจถูก Yosys optimize ออก หากต้องการทดสอบเพียง hierarchy สามารถหยุดก่อน synthesis mapping หรือกำหนด black-box attribute ใน model

---

# 15.19 ขั้นตอนที่ 14: ตรวจชื่อ Pad Instances

ใช้คำสั่ง

```bash
grep -oE "u_pad_[A-Za-z0-9_]+|u_corner_[A-Za-z0-9_]+" \
    src/chip_top.sv |
sort -u
```

ผลที่คาดหวัง

```text
u_corner_ne
u_corner_nw
u_corner_se
u_corner_sw
u_pad_clk
u_pad_count_0
u_pad_count_1
u_pad_count_2
u_pad_count_3
u_pad_count_4
u_pad_count_5
u_pad_count_6
u_pad_count_7
u_pad_enable
u_pad_rst_n
u_pad_vdd
u_pad_vss
```

เปรียบเทียบกับรายการใน `config.yaml`

หากพิมพ์ชื่อผิด เช่น

```yaml
- u_pad_reset
```

แต่ RTL ใช้

```text
u_pad_rst_n
```

OpenROAD จะไม่พบ instance และ pad-ring generation จะล้มเหลว

---

# 15.20 ขั้นตอนที่ 15: ตรวจ Configuration

รัน

```bash
librelane --pdk ihp-sg13g2 --flow Chip config.yaml --validate-only
```

หาก LibreLane version ที่ใช้ไม่มี `--validate-only` ให้ใช้

```bash
librelane --pdk ihp-sg13g2 --flow Chip config.yaml \
    --to Yosys.Synthesis
```

หรือเริ่ม flow และตรวจ configuration snapshot ใน run directory

LibreLane บันทึก configuration และ state ของแต่ละขั้นตอน เพื่อให้ flow สามารถทำซ้ำและตรวจย้อนกลับได้ ([LibreLane][2])

---

# 15.21 ขั้นตอนที่ 16: รัน Synthesis เท่านั้น

```bash
librelane \
    --pdk ihp-sg13g2 \
    --flow Chip \
    --to Yosys.Synthesis \
    config.yaml
```

ตรวจ log

```bash
find runs -type f |
grep -Ei "synthesis|yosys|stat|log" |
sort
```

ค้นหา error

```bash
grep -RniE "error|unmapped|unknown module|blackbox" runs |
head -100
```

## ตรวจ synthesis statistics

```bash
grep -Rni "Number of cells" runs |
tail -20
```

ต้องตรวจว่า

* `counter_core` ถูกสังเคราะห์
* standard cells ถูก map
* I/O pad instances ยังคงอยู่
* pad instances ไม่ถูก optimize ทิ้ง
* ไม่มี unknown module
* ไม่มี unmapped logic cells

---

# 15.22 ขั้นตอนที่ 17: รันถึง Floorplan

```bash
librelane \
    --pdk ihp-sg13g2 \
    --flow Chip \
    --to OpenROAD.Floorplan \
    config.yaml
```

ตรวจสอบ

* die area
* core area
* standard-cell rows
* core-to-pad spacing
* power ring clearance
* routing channels

เปิดด้วย OpenROAD

```bash
librelane \
    --pdk ihp-sg13g2 \
    --last-run \
    --flow OpenInOpenROAD \
    config.yaml
```

LibreLane มี flow `OpenInOpenROAD` สำหรับเปิด ODB จาก run ที่มีอยู่แล้ว ([LibreLane][1])

---

# 15.23 ขั้นตอนที่ 18: รันถึง Pad Ring

```bash
librelane \
    --pdk ihp-sg13g2 \
    --flow Chip \
    --to OpenROAD.PadRing \
    config.yaml
```

`OpenROAD.PadRing` รับ floorplanned ODB เป็น input และสร้าง ODB, DEF, SDC และ netlist ที่มีการจัดวาง pad ring แล้ว ([LibreLane][5])

เปิดผลลัพธ์

```bash
librelane \
    --pdk ihp-sg13g2 \
    --last-run \
    --flow OpenInOpenROAD \
    config.yaml
```

## Checklist ของ Pad Ring

ตรวจด้วยสายตา

* [ ] Pads อยู่ครบทั้งสี่ด้าน
* [ ] Corner pads อยู่ครบสี่มุม
* [ ] ไม่มี pad overlap
* [ ] Orientation ถูกต้อง
* [ ] Pad opening หันออกนอก die
* [ ] Core-facing pins หันเข้าด้านใน
* [ ] Bus bits เรียงลำดับถูกต้อง
* [ ] Power/ground pads อยู่ตำแหน่งเหมาะสม
* [ ] ไม่มี pad หลุดออกนอก die
* [ ] มี routing channel ระหว่าง pad ring กับ core

---

# 15.24 ขั้นตอนที่ 19: ตรวจ Orientation

Orientation ของ pad อาจเป็น

```text
R0
R90
R180
R270
MX
MY
MXR90
MYR90
```

การวาง orientation ผิดอาจทำให้

* bonding area หันเข้าหา core
* core-facing pins หันออกนอก die
* pad abutment ไม่ต่อเนื่อง
* power rail ของ I/O ring ไม่เชื่อมกัน
* filler pad ไม่สามารถปิดช่องว่าง
* DRC violations จำนวนมาก

ตรวจ DEF

```bash
grep -R "u_pad_\|u_corner_" runs |
grep -E "PLACED|FIXED" |
head -100
```

ตัวอย่าง DEF component

```text
- u_pad_clk PAD_INPUT
  + FIXED ( 400000 0 ) N ;
```

พิกัดใน DEF มักอยู่ใน database units ไม่ใช่ไมโครเมตรโดยตรง

---

# 15.25 ขั้นตอนที่ 20: รัน Full Chip Flow

เมื่อ synthesis, floorplan และ pad ring ผ่านแล้ว ให้รันทั้งหมด

```bash
librelane \
    --pdk ihp-sg13g2 \
    --flow Chip \
    --run-tag lab15_fullchip \
    config.yaml
```

กรณีใช้ Docker

```bash
librelane --dockerized \
    --pdk ihp-sg13g2 \
    --flow Chip \
    --run-tag lab15_fullchip \
    config.yaml
```

กรณีใช้ Nix environment

```bash
[nix-shell]
librelane \
    --pdk ihp-sg13g2 \
    --flow Chip \
    --run-tag lab15_fullchip \
    config.yaml
```

เพื่อประหยัดเวลาตอนรันขั้นต้น  เราสามารถข้ามบางขั้น เช่น ข้าม DRC ตัวอย่างคำสั่ง

```bash
[nix-shell]
librelane \
    --pdk ihp-sg13g2 \
    --flow Chip \
    config.yaml \
    --skip KLayout.DRC --skip Magic.DRC
```

---

# 15.26 ลำดับขั้นตอนที่ควรสังเกต

Chip flow ประกอบด้วยขั้นตอนหลัก เช่น

```text
Verilator.Lint
Yosys.Synthesis
OpenROAD.CheckSDCFiles
OpenROAD.STAPrePNR
OpenROAD.Floorplan
Odb.SetPowerConnections
OpenROAD.PadRing
Odb.ManualMacroPlacement
OpenROAD.CutRows
OpenROAD.TapEndcapInsertion
OpenROAD.GeneratePDN
OpenROAD.GlobalPlacement
OpenROAD.DetailedPlacement
OpenROAD.CTS
OpenROAD.GlobalRouting
OpenROAD.RepairAntennas
OpenROAD.DetailedRouting
OpenROAD.FillInsertion
OpenROAD.RCX
OpenROAD.STAPostPNR
OpenROAD.IRDropReport
Magic.StreamOut
KLayout.StreamOut
KLayout.XOR
KLayout.Antenna
KLayout.SealRing
KLayout.Filler
KLayout.Density
Magic.DRC
KLayout.DRC
Magic.SpiceExtraction
Netgen.LVS
```

LibreLane documentation แสดงว่า Chip flow เพิ่ม `OpenROAD.PadRing`, `KLayout.Antenna`, `KLayout.SealRing`, `KLayout.Filler` และ `KLayout.Density` ไว้ในลำดับ flow โดยตรง ([LibreLane][1])

---

# 15.27 ขั้นตอนที่ 21: ตรวจ Placement

ตรวจ global placement

```bash
grep -RniE "utilization|density|overflow|congestion" \
    runs/lab15_fullchip |
tail -100
```

## ประเด็นที่ต้องตรวจ

* Standard cells อยู่ภายใน core area
* ไม่มี standard cells อยู่ใต้ I/O pads
* ไม่มี cells ชน power ring
* ไม่มี density hotspot
* Clock source อยู่ในตำแหน่งที่ CTS เข้าถึงได้
* Output logic อยู่ใกล้ output pads เท่าที่เหมาะสม
* Reset fanout ไม่สูงผิดปกติ

---

# 15.28 ขั้นตอนที่ 22: ตรวจ PDN

Full-chip design อาจมี power network สองระดับ

```text
Package / Bond pads
        │
        ▼
I/O power ring
        │
        ▼
Core power ring
        │
        ▼
Core stripes
        │
        ▼
Standard-cell rails
```

ต้องแยกความเข้าใจระหว่าง

* Core supply
* I/O supply
* Analog supply
* Ground
* ESD return path

ตัวอย่างชื่อ net ที่อาจพบ

```text
VDD
VSS
VDDIO
VSSIO
VDDA
VSSA
```

## Config แบบหลาย supply

```yaml
VDD_NETS:
  - VDD
  - VDDIO

GND_NETS:
  - VSS
  - VSSIO
```

แต่การกำหนดหลาย supply nets ไม่ได้แปลว่า LibreLane จะสร้าง multi-domain PDN ให้สมบูรณ์โดยอัตโนมัติ ต้องมี

* pad models ที่ถูกต้อง
* global connection rules
* PDN configuration
* macro hooks
* isolation ระหว่าง supply domains
* LVS-compatible power connectivity

## ตรวจ PDN log

```bash
grep -RniE "PDN-|PSM-|power grid|unconnected" \
    runs/lab15_fullchip |
tail -100
```

LibreLane รองรับ `VDD_NETS` และ `GND_NETS` เพื่อระบุ power และ ground nets ที่ใช้สร้าง power grid ([LibreLane][3])

---

# 15.29 ขั้นตอนที่ 23: ตรวจ Clock Tree

ค้นหารายงาน CTS

```bash
find runs/lab15_fullchip -type f |
grep -Ei "cts|clock|skew|latency"
```

ค้นหา metric

```bash
grep -RniE "skew|latency|clock slew|clock period" \
    runs/lab15_fullchip |
tail -100
```

## สิ่งที่ต้องตรวจ

* CTS พบ clock root
* Clock path ผ่าน input pad ได้
* Clock buffer ถูก insert ภายใน core
* Clock skew อยู่ในเกณฑ์
* ไม่มี clock pin ที่ไม่ถูกขับ
* ไม่มี generated clock ที่หายไป
* Clock port และ clock net สอดคล้องกัน

## ปัญหาที่พบบ่อย

```text
CLOCK_PORT = clk_core
```

แต่ `clk_core` ไม่ใช่ top-level port

หรือ

```text
CLOCK_PORT = clk_PAD
```

แต่ pad model ไม่มี combinational timing arc จาก `PAD` ไปยัง output pin ทำให้ STA ไม่เห็น clock propagation

แนวทางแก้

* ใช้ Liberty model ของ pad ที่มี timing arcs
* ตรวจชื่อขาใน pad Liberty
* ใช้ `CLOCK_PORT` และ `CLOCK_NET` ให้ถูกต้อง
* ตรวจ generated SDC หลัง pad-ring step

---

# 15.30 ขั้นตอนที่ 24: ตรวจ Routing

ค้นหา routing summary

```bash
grep -RniE "route|overflow|congestion|violation" \
    runs/lab15_fullchip |
tail -150
```

## จุดเสี่ยงใน Full-Chip Routing

### 1. Pad-to-core escape routing

พื้นที่ด้านในของ pad ring ต้องเพียงพอสำหรับลากสัญญาณจาก pad เข้าหา core

### 2. Clock entry

Clock pad อาจอยู่ไกลจาก clock root ทำให้ insertion delay สูง

### 3. Output bus congestion

หาก output pads หลายตัวอยู่ด้านเดียวกันและ logic อยู่ตรงข้าม die อาจเกิด congestion

### 4. Power-ring obstruction

Power ring อาจบล็อก signal routing layers

### 5. I/O pad pins อยู่บน layer สูง

หาก pad pin ใช้ metal layer ที่เกิน `RT_MAX_LAYER` router อาจเชื่อมต่อไม่ได้

### 6. Pad pin ไม่มี access point

LEF ของ pad ต้องกำหนด geometry ที่ router เข้าถึงได้

---

# 15.31 ขั้นตอนที่ 25: ตรวจ Antenna

ค้นหารายงาน

```bash
find runs/lab15_fullchip -type f |
grep -Ei "antenna"
```

ตรวจจำนวน violation

```bash
grep -RniE "antenna.*violation|violation.*antenna" \
    runs/lab15_fullchip |
tail -100
```

Full-chip design มีความเสี่ยง antenna สูงจาก

* เส้นทางยาวจาก pad ไป core
* pad metal area ขนาดใหญ่
* long top-metal routes
* input gate เชื่อมกับ pad โดยตรง
* diode insertion ไม่สามารถวางใกล้ pad

แนวทางแก้

* เปิด `RUN_ANTENNA_REPAIR`
* เพิ่ม antenna diodes
* เปลี่ยน routing layer
* ใช้ jumper
* ลดระยะทาง pad-to-core
* ตรวจ antenna properties ใน LEF ของ pad

---

# 15.32 ขั้นตอนที่ 26: ตรวจ Timing หลัง Routing

ค้นหา timing reports

```bash
find runs/lab15_fullchip -type f |
grep -Ei "sta|timing|setup|hold|max"
```

ค้นหา WNS/TNS

```bash
grep -RniE "WNS|TNS|worst.*slack|setup.*slack|hold.*slack" \
    runs/lab15_fullchip |
tail -100
```

## Timing paths ที่ต้องตรวจ

### Input-to-register

```text
enable_PAD
 → input pad
 → core logic
 → register D
```

### Register-to-output

```text
register Q
 → core logic
 → output pad
 → count_PAD
```

### Clock path

```text
clk_PAD
 → clock input pad
 → clock root buffer
 → clock tree
 → register CK
```

## Timing budget

ตัวอย่าง clock period 20 ns

```text
External source delay      2.0 ns
Pad input delay            1.0 ns
Core combinational delay   5.0 ns
Setup time                 0.5 ns
Uncertainty                0.25 ns
Remaining margin          11.25 ns
```

ต้องรวม pad delay เข้าใน timing model หากต้องการผล signoff ที่สมจริง

---

# 15.33 ขั้นตอนที่ 27: ตรวจ GDSII

ค้นหา GDS

```bash
find runs/lab15_fullchip -type f -name "*.gds" -print
```

เปิดด้วย KLayout

```bash
klayout <path-to-final-gds>
```

หรือ

```bash
librelane \
    --pdk ihp-sg13g2 \
    --last-run \
    --flow OpenInKLayout \
    config.yaml
```

## สิ่งที่ต้องตรวจใน GDS

* Die boundary
* Pad ring
* Corner pads
* Bond-pad openings
* Core area
* Standard cells
* Power grid
* Routed signals
* Fill cells
* Metal fill
* Seal ring
* No empty macro cells
* No missing I/O pad geometries

หากเห็นเฉพาะ bounding box ของ pad แต่ไม่มี geometry แสดงว่า GDS view ของ pad library ไม่ถูก merge ใน stream-out

---

# 15.34 ขั้นตอนที่ 28: ตรวจ Seal Ring

Seal ring อยู่รอบขอบ die เพื่อช่วยป้องกันโครงสร้างภายในระหว่าง wafer dicing และลดความเสี่ยงจากความเสียหายเชิงกลหรือความชื้น

ตรวจว่า

* Seal ring ล้อมรอบ die ครบ
* ไม่ชน pad cells
* ไม่ชน bonding areas
* ระยะห่างจาก die edge ถูกต้อง
* ไม่มีช่องขาดต่อเนื่อง
* Corner geometry ถูกต้อง

หาก PDK ไม่มี seal-ring runset หรือ seal-ring cells ขั้นตอนนี้อาจถูกข้ามหรือไม่รองรับ ต้องตรวจ PDK documentation

---

# 15.35 ขั้นตอนที่ 29: ตรวจ Filler และ Density

## Pad fillers

Pad fillers ปิดช่องระหว่าง I/O pads เพื่อให้

* I/O power rails ต่อเนื่อง
* ไม่มีช่องว่างใน pad ring
* ผ่าน DRC
* ช่วยให้ ESD return path ต่อเนื่อง

## Standard-cell fillers

ใช้เติมช่องว่างใน core rows เพื่อให้

* well continuity
* implant continuity
* power rail continuity

## Metal density fill

ใช้เพิ่มความหนาแน่นโลหะให้เป็นไปตามข้อกำหนดการผลิต

ตรวจ density report

```bash
find runs/lab15_fullchip -type f |
grep -Ei "density|fill"
```

ค้นหา violations

```bash
grep -RniE "density.*error|density.*violation" \
    runs/lab15_fullchip |
tail -100
```

---

# 15.36 ขั้นตอนที่ 30: ตรวจ DRC

ค้นหา Magic DRC

```bash
find runs/lab15_fullchip -type f |
grep -Ei "magic.*drc|drc.*magic"
```

ค้นหา KLayout DRC

```bash
find runs/lab15_fullchip -type f |
grep -Ei "klayout.*drc|drc.*klayout"
```

ค้นหาจำนวน error

```bash
grep -RniE "drc.*count|violation|error count" \
    runs/lab15_fullchip |
tail -150
```

## Full-chip DRC hotspots

* Pad-to-corner spacing
* Pad-to-filler spacing
* Pad orientation
* Bond opening
* Top-metal spacing
* I/O power ring continuity
* Seal-ring clearance
* Die-edge enclosure
* Metal density
* Overlapping pad geometries
* Core ring ชน I/O ring

---

# 15.37 ขั้นตอนที่ 31: ตรวจ LVS

ค้นหา LVS report

```bash
find runs/lab15_fullchip -type f |
grep -Ei "lvs|netgen"
```

ค้นหาผลสรุป

```bash
grep -RniE "circuits match|match uniquely|mismatch|property errors" \
    runs/lab15_fullchip |
tail -100
```

ผลที่ต้องการ

```text
Circuits match uniquely.
```

## ปัญหา LVS ที่พบบ่อยใน Full-Chip Design

### 1. ไม่มี SPICE/CDL model ของ pad

Layout extraction พบ pad subcircuit แต่ schematic ไม่มี model ที่ตรงกัน

### 2. Pin order ไม่ตรงกัน

Verilog, LEF และ CDL ใช้ลำดับ pin ต่างกัน

### 3. Power pins ถูกซ่อน

Verilog model ซ่อน power pins แต่ extracted layout มี power pins แบบ explicit

### 4. Net names ไม่ตรงกัน

```text
VDD vs VPWR
VSS vs VGND
VDDIO vs VDD
```

### 5. Pad filler ถูก extract แต่ไม่มี schematic equivalent

ต้องกำหนด filler เป็น device-free หรือ black-box ตาม PDK LVS setup

### 6. Corner pad มี connectivity ที่ไม่คาดไว้

Corner cell บางชนิดเชื่อม I/O supply rails ภายใน

### 7. Global nets ไม่ถูกประกาศ

ต้องตรวจ global connection และ extraction setup

---

# 15.38 Makefile

สร้างไฟล์

```text
Makefile
```

```makefile
PDK ?= ihp-sg13g2
FLOW ?= Chip
CONFIG ?= config.yaml
TAG ?= lab15_fullchip

.PHONY: help lint synth floorplan padring run openroad klayout reports clean

help:
	@echo "Targets:"
	@echo "  make lint       - Run RTL lint"
	@echo "  make synth      - Run through synthesis"
	@echo "  make floorplan  - Run through floorplan"
	@echo "  make padring    - Run through pad-ring generation"
	@echo "  make run        - Run complete LibreLane Chip flow"
	@echo "  make openroad   - Open latest ODB in OpenROAD GUI"
	@echo "  make klayout    - Open latest result in KLayout"
	@echo "  make reports    - Search important reports"
	@echo "  make clean      - Remove generated runs"

lint:
	verilator \
		--lint-only \
		--Wall \
		--Wno-DECLFILENAME \
		--top-module chip_top \
		src/io_cells_stub.v \
		src/counter_core.sv \
		src/chip_top.sv

synth:
	librelane \
		--pdk $(PDK) \
		--flow $(FLOW) \
		--run-tag $(TAG)_synth \
		--to Yosys.Synthesis \
		$(CONFIG)

floorplan:
	librelane \
		--pdk $(PDK) \
		--flow $(FLOW) \
		--run-tag $(TAG)_floorplan \
		--to OpenROAD.Floorplan \
		$(CONFIG)

padring:
	librelane \
		--pdk $(PDK) \
		--flow $(FLOW) \
		--run-tag $(TAG)_padring \
		--to OpenROAD.PadRing \
		$(CONFIG)

run:
	librelane \
		--pdk $(PDK) \
		--flow $(FLOW) \
		--run-tag $(TAG) \
		$(CONFIG)

openroad:
	librelane \
		--pdk $(PDK) \
		--last-run \
		--flow OpenInOpenROAD \
		$(CONFIG)

klayout:
	librelane \
		--pdk $(PDK) \
		--last-run \
		--flow OpenInKLayout \
		$(CONFIG)

reports:
	@echo "=== Timing ==="
	@grep -RniE "WNS|TNS|worst.*slack" runs/ 2>/dev/null | tail -30 || true
	@echo "=== DRC ==="
	@grep -RniE "drc.*count|drc.*error" runs/ 2>/dev/null | tail -30 || true
	@echo "=== LVS ==="
	@grep -RniE "circuits match|mismatch|lvs.*error" runs/ 2>/dev/null | tail -30 || true
	@echo "=== Antenna ==="
	@grep -RniE "antenna.*error|antenna.*violation" runs/ 2>/dev/null | tail -30 || true

clean:
	rm -rf runs
```

ใช้งาน

```bash
make lint
make synth
make floorplan
make padring
make run
make reports
```

---

# 15.39 การใช้ PAD_CFG สำหรับควบคุมขั้นสูง

สำหรับ pad ring ที่ต้องกำหนดตำแหน่ง, corner, filler หรือ orientation อย่างละเอียด สามารถใช้

```yaml
PAD_CFG: dir::pad/padframe.cfg
```

จากนั้นไม่จำเป็นต้องใช้ `PAD_SOUTH`, `PAD_EAST`, `PAD_NORTH` และ `PAD_WEST`

รูปแบบคำสั่งภายใน `padframe.cfg` ต้องตรงกับ OpenROAD ICeWall/pad placer version ที่ LibreLane ใช้ ตัวอย่างเชิงแนวคิด

```tcl
# Conceptual example only.
# Verify command syntax against the installed OpenROAD version.

place_corners \
    PAD_CORNER_CELL \
    u_corner_sw \
    u_corner_se \
    u_corner_ne \
    u_corner_nw

place_pad -row IO_SOUTH -location 300 u_pad_clk
place_pad -row IO_SOUTH -location 500 u_pad_rst_n
place_pad -row IO_SOUTH -location 700 u_pad_enable

place_pad -row IO_EAST -location 300 u_pad_count_0
place_pad -row IO_EAST -location 500 u_pad_count_1

place_pad -row IO_NORTH -location 500 u_pad_vdd
place_pad -row IO_NORTH -location 700 u_pad_vss

place_pad -row IO_WEST -location 300 u_pad_count_7
place_pad -row IO_WEST -location 500 u_pad_count_6
```

ตรวจ syntax ที่รองรับจริงจาก OpenROAD shell

```bash
openroad -no_init
```

จากนั้น

```tcl
help place_pad
help make_io_sites
help place_corners
help place_io_fill
help connect_by_abutment
```

`PAD_CFG` เหมาะสำหรับกรณี

* ต้อง fix ตำแหน่ง pad ตาม package pinout
* มีหลาย I/O power domains
* ต้องควบคุม filler insertion
* pad dimensions ไม่เท่ากัน
* มี analog pads
* มี differential pads
* ต้องกำหนด exact bond-pad pitch
* มี custom corner cells

---

# 15.40 การ Debug แบบ Step-by-Step

## กรณีที่ 1: Unknown module

ตัวอย่าง

```text
ERROR: Module PAD_INPUT not found
```

สาเหตุ

* ไม่ได้โหลด Verilog model ของ pad
* ชื่อ module ไม่ตรง
* wildcard path ไม่พบไฟล์
* PDK ไม่ได้รวม I/O library

แนวทางแก้

```yaml
EXTRA_VERILOG_MODELS:
  - dir::pdk/io/io_cells.v
```

ตรวจ

```bash
grep "^module PAD_INPUT" pdk/io/io_cells.v
```

---

## กรณีที่ 2: Macro master not found

ตัวอย่าง

```text
ODB error: master PAD_INPUT not found
```

สาเหตุ

* ไม่มี LEF
* LEF macro name ไม่ตรงกับ netlist cell name
* I/O LEF ไม่ถูกโหลด
* PDK configuration ไม่รวม I/O library

แนวทางแก้

```yaml
EXTRA_LEFS:
  - dir::pdk/io/io_cells.lef
```

ตรวจ

```bash
grep "^MACRO PAD_INPUT" pdk/io/io_cells.lef
```

---

## กรณีที่ 3: Site not found

ตัวอย่าง

```text
PAD-0100: site IO_SITE not found
```

สาเหตุ

* Pad LEF อ้างถึง SITE ที่ไม่มีใน technology LEF
* โหลด LEF ผิดลำดับ
* I/O library ไม่ตรงกับ PDK variant
* site name ไม่ตรงกับ pad placer configuration

ตรวจ

```bash
grep -R "^SITE " "$PDK_ROOT" |
head -100
```

และ

```bash
grep -n "SITE" pdk/io/io_cells.lef |
head -50
```

---

## กรณีที่ 4: Pad instance not found

ตัวอย่าง

```text
Pad instance u_pad_reset was not found.
```

สาเหตุ

* ชื่อใน `PAD_SOUTH` ไม่ตรงกับ RTL
* Instance ถูก synthesis optimize ออก
* Hierarchy ถูก flatten แล้วเปลี่ยนชื่อ
* Pad module ไม่ได้ถูกมองเป็น black box

แนวทางแก้

* ตรวจ synthesized netlist
* ใช้ชื่อ instance หลัง synthesis
* กำหนด pad cells เป็น macro/black box
* หลีกเลี่ยงการให้ stub มี logic ที่ทำให้ pad ถูก optimize

---

## กรณีที่ 5: Pad overlap

สาเหตุ

* Die เล็กเกินไป
* จำนวน pad มากเกินด้าน
* Corner cell กว้างกว่าที่ประมาณ
* Pad spacing ไม่พอ
* Bond-pad overlay มีขนาดใหญ่

แนวทางแก้

* เพิ่ม `DIE_AREA`
* กระจาย pads ไปด้านอื่น
* ลด spacing เมื่อ DRC อนุญาต
* ใช้ pad cell ที่แคบกว่า
* ปรับ package pinout

---

## กรณีที่ 6: Disconnected pad pins

ค้นหา

```bash
grep -Rni "disconnected" runs/lab15_fullchip |
tail -100
```

สาเหตุ

* Pin direction ใน LEF ผิด
* RTL pin ไม่ตรงกับ LEF
* Power pin ไม่ถูก global-connect
* External pad port ไม่ได้ต่อ
* Output-enable pin ลอย
* Control pins ของ configurable pad ไม่ได้ tie-off

แนวทางแก้

* ตรวจ pin list ทุก view
* tie-off control pins อย่างชัดเจน
* กำหนด global power connections
* เพิ่ม constant cells แทน `1'b0`/`1'b1` เมื่อ PDK ต้องการ

---

## กรณีที่ 7: CTS ไม่พบ clock

ตัวอย่าง

```text
No clock nets found.
```

ตรวจ

```yaml
CLOCK_PORT: clk_PAD
CLOCK_NET: clk_core
```

ตรวจ SDC

```tcl
create_clock [get_ports clk_PAD]
```

ตรวจ synthesized netlist ว่า clock pad ยังเชื่อมต่อกับ `clk_core`

---

## กรณีที่ 8: Routing pin not accessible

สาเหตุ

* Pad pin อยู่บน layer ที่ router ไม่ใช้
* LEF pin geometry เล็กเกินไป
* Obstruction บัง pin
* Orientation ทำให้ pin อยู่ด้านนอก
* `RT_MAX_LAYER` ต่ำเกินไป

แนวทางแก้

* เปิดดู LEF pin geometry
* ตรวจ pad orientation
* เพิ่ม routing layer ที่อนุญาต
* เพิ่ม access geometry ใน abstract LEF เมื่อได้รับอนุญาต

---

## กรณีที่ 9: LVS power mismatch

สาเหตุ

```text
Schematic: VDD
Layout: VPWR
```

แนวทางแก้

* ใช้ net naming เดียวกัน
* ตรวจ `VDD_NETS`, `GND_NETS`
* ตรวจ `VDD_PIN`, `GND_PIN`
* ตรวจ global-net mapping
* ตรวจ CDL subcircuit pin order

---

# 15.41 เกณฑ์ผ่านการทดลอง

การทดลองถือว่าผ่านเมื่อ

| รายการ        | เกณฑ์                                  |
| ------------- | -------------------------------------- |
| RTL lint      | ไม่มี error                            |
| Synthesis     | ไม่มี unmapped logic cells             |
| Pad instances | อยู่ครบตามที่กำหนด                     |
| Pad ring      | ไม่มี overlap                          |
| Floorplan     | Core และ pad ring ไม่ชนกัน             |
| Placement     | ผ่าน detailed placement                |
| CTS           | Clock ถูกสร้างและกระจายครบ             |
| Routing       | Detailed routing สำเร็จ                |
| Routing DRC   | 0 violation                            |
| Antenna       | 0 unresolved violation                 |
| LVS           | Circuits match                         |
| KLayout DRC   | 0 violation หรือมี waiver ที่อธิบายได้ |
| Magic DRC     | 0 violation หรือมี waiver ที่อธิบายได้ |
| Density       | ผ่าน PDK rule                          |
| GDSII         | มี pad, core, filler และ seal ring ครบ |

---

# 15.42 คำถามท้ายการทดลอง

1. Core-level design แตกต่างจาก full-chip design อย่างไร
2. เหตุใดจึงไม่ควรต่อ top-level signal เข้ากับ core โดยไม่ผ่าน I/O pad
3. Input pad และ output pad มีทิศทางสัญญาณต่างกันอย่างไร
4. เพราะเหตุใด clock pad ต้องมี timing model
5. `CLOCK_PORT` และ `CLOCK_NET` ต่างกันอย่างไร
6. เพราะเหตุใด pad instance names ใน `config.yaml` ต้องตรงกับ synthesized netlist
7. Corner pads มีหน้าที่อะไร
8. Pad fillers ต่างจาก standard-cell fillers อย่างไร
9. เหตุใด power pads ควรกระจายหลายตำแหน่ง
10. Pad orientation ผิดส่งผลต่อ routing และ DRC อย่างไร
11. เหตุใด full-chip design มีโอกาสเกิด antenna violation สูง
12. Seal ring มีหน้าที่อะไร
13. เหตุใด Verilog, LEF, GDS และ CDL ต้องใช้ชื่อ cell ตรงกัน
14. ถ้า LVS รายงาน power net mismatch ควรตรวจไฟล์ใดบ้าง
15. เหตุใดผล DRC ของ core-level อาจผ่าน แต่ full-chip DRC ไม่ผ่าน

---

# 15.43 งานเพิ่มเติม

## Exercise 15.1 เพิ่ม Output Enable

เปลี่ยน output pads เป็น tri-state pads และเพิ่มพอร์ต

```systemverilog
input wire output_enable_PAD;
```

ศึกษาเส้นทาง

```text
output_enable_PAD
 → input pad
 → output-enable logic
 → output pad OE
```

---

## Exercise 15.2 เพิ่ม GPIO แบบ Bidirectional

ออกแบบ GPIO จำนวน 4 บิต

```systemverilog
inout wire [3:0] gpio_PAD;
```

สัญญาณภายใน

```systemverilog
wire [3:0] gpio_in;
wire [3:0] gpio_out;
wire [3:0] gpio_oe;
```

---

## Exercise 15.3 แยก Core Supply และ I/O Supply

กำหนด

```text
VDD
VSS
VDDIO
VSSIO
```

และวิเคราะห์ว่าต้องมี power pads และ PDN connections เพิ่มเติมอย่างไร

---

## Exercise 15.4 เปรียบเทียบ Pad Placement

ทดลองสองแบบ

### แบบ A

วาง output pads ทั้งหมดด้านเดียว

### แบบ B

กระจาย output pads สองด้าน

เปรียบเทียบ

* Wire length
* Routing congestion
* WNS
* Antenna violations
* Total routed vias

---

## Exercise 15.5 ปรับ Die Area

ทดลอง

```yaml
DIE_AREA: [0, 0, 1200, 1200]
```

```yaml
DIE_AREA: [0, 0, 1600, 1600]
```

```yaml
DIE_AREA: [0, 0, 2000, 2000]
```

บันทึกผล

| Die size    | Pad overlap | Core utilization | Wire length | WNS | DRC |
| ----------- | ----------: | ---------------: | ----------: | --: | --: |
| 1200 × 1200 |             |                  |             |     |     |
| 1600 × 1600 |             |                  |             |     |     |
| 2000 × 2000 |             |                  |             |     |     |

---

# 15.44 สรุป

Lab 15 ยกระดับการออกแบบจาก digital core ไปสู่ complete-chip implementation โดยเพิ่มโครงสร้างสำคัญ ได้แก่

```text
RTL core
  +
I/O wrapper
  +
Signal pads
  +
Power/ground pads
  +
Corner pads
  +
Pad fillers
  +
Core PDN
  +
Seal ring
  +
Density fill
```

ขั้นตอนสำคัญที่สุดของ full-chip design ไม่ได้มีเพียงการวาง pad รอบ die แต่รวมถึงการรักษาความสอดคล้องของข้อมูลทุกมุมมอง

```text
RTL / Verilog
        ↕
Liberty timing model
        ↕
LEF physical abstract
        ↕
GDS layout
        ↕
CDL / SPICE netlist
```

ความผิดพลาดเพียงจุดเดียว เช่น ชื่อ pin ไม่ตรง, power net ต่างชื่อ, pad orientation ผิด หรือขาด GDS view สามารถทำให้ synthesis ผ่าน แต่ routing, stream-out, DRC หรือ LVS ล้มเหลวได้

แนวทางปฏิบัติที่แนะนำคือรัน flow เป็นช่วง

```text
Lint
 → Synthesis
 → Floorplan
 → Pad Ring
 → Placement
 → CTS
 → Routing
 → Signoff
```

ไม่ควรเริ่มด้วย full flow ทันที เพราะปัญหาของ I/O library และ pad-ring configuration ควรถูกตรวจพบและแก้ไขตั้งแต่ก่อน placement และ routing

ตัวอย่าง `config.yaml` ข้างต้นเป็นแม่แบบของ LibreLane 3.x โดยส่วน pad-cell names, supply names, physical views และ core/die dimensions ต้องปรับให้ตรงกับ I/O library ของ PDK ที่ติดตั้งจริง ปัจจุบัน LibreLane stable documentation รองรับ YAML configuration และ Chip flow ผ่าน `librelane --flow Chip` พร้อมตัวแปร `PAD_CFG` และรายการ pad ทั้งสี่ด้านตามที่ใช้ในคู่มือนี้ ([LibreLane][4])

[1]: https://librelane.readthedocs.io/en/stable/reference/flows.html "https://librelane.readthedocs.io/en/stable/reference/flows.html"
[2]: https://librelane.readthedocs.io/ "https://librelane.readthedocs.io/"
[3]: https://librelane.readthedocs.io/en/stable/reference/common_flow_vars.html "https://librelane.readthedocs.io/en/stable/reference/common_flow_vars.html"
[4]: https://librelane.readthedocs.io/en/stable/reference/configuration.html "https://librelane.readthedocs.io/en/stable/reference/configuration.html"
[5]: https://librelane.readthedocs.io/en/stable/reference/step_config_vars.html "https://librelane.readthedocs.io/en/stable/reference/step_config_vars.html"
