
# Bonus Lab: Full-Chip Design with I/O Pads

## การออกแบบชิประดับ Full-Chip ด้วย LibreLane และ IHP SG13G2

---

## 1. วัตถุประสงค์ของบทปฏิบัติการ

บทปฏิบัติการนี้เป็นการต่อยอดจากการออกแบบวงจรดิจิทัลระดับ Core ซึ่งมีเฉพาะ Standard Cells ภายในพื้นที่ Core ไปสู่การออกแบบระดับ Full-Chip ที่ประกอบด้วยส่วนสำคัญดังต่อไปนี้

1. วงจรดิจิทัลภายในหรือ Chip Core
2. วงจร I/O Pad สำหรับรับและส่งสัญญาณภายนอก
3. Power Pad และ Ground Pad
4. I/O Power Pad และ I/O Ground Pad
5. Pad Ring รอบขอบชิป
6. Bond Pad สำหรับเชื่อมต่อกับ Bond Wire
7. Power Distribution Network หรือ PDN
8. Core Power Ring
9. Seal Ring รอบขอบ Die
10. Layout ระดับ Top-Level สำหรับผลิตเป็นชิป

เมื่อจบบทปฏิบัติการ ผู้เรียนจะสามารถ

- อธิบายความแตกต่างระหว่าง Core Design และ Full-Chip Design ได้
- เข้าใจโครงสร้างของ Top-Level RTL ที่เชื่อมต่อ I/O Pads
- กำหนดตำแหน่ง Pad แต่ละด้านของชิปได้
- กำหนด Timing Constraint ที่อ้างอิงสัญญาณหลังผ่าน I/O Pad ได้
- เพิ่ม External LEF และ GDS ของ Bond Pad เข้าใน Flow ได้
- เรียกใช้ LibreLane ด้วย `Chip` flow
- เปิดผลลัพธ์ด้วย OpenROAD GUI และ KLayout
- ตรวจสอบผลลัพธ์ด้าน Pad Ring, Floorplan, PDN, Routing, Antenna และ LVS ได้
- แยกแยะระหว่างผลลัพธ์สำหรับการเรียนรู้กับผลลัพธ์ที่พร้อม Tapeout จริงได้

---

## 2. แนวคิดของ Full-Chip Design

### 2.1 Core Design

ในงาน Physical Design ทั่วไป วงจรที่ออกแบบด้วย RTL จะถูกสังเคราะห์และวางลงในพื้นที่ที่เรียกว่า Core Area

ภายใน Core Area ประกอบด้วย

- Standard Cells
- Clock Tree
- Signal Routing
- Power Straps
- Power Rails
- Hard Macros ถ้ามี

Core Design ยังไม่สามารถเชื่อมต่อกับขาภายนอกของ Package ได้โดยตรง เนื่องจาก Standard Cells ไม่ได้ถูกออกแบบให้รับแรงดัน กระแส และสภาวะทางไฟฟ้าจากภายนอกชิปโดยตรง

### 2.2 Full-Chip Design

Full-Chip Design เพิ่มองค์ประกอบที่จำเป็นสำหรับการเชื่อมต่อชิปจริง ได้แก่

- Input Pad
- Output Pad
- Bidirectional Pad
- Analog Pad
- Power Pad
- Ground Pad
- Bond Pad
- Pad Ring
- Seal Ring

โครงสร้างเชิงลำดับสามารถอธิบายได้ดังนี้

```text
Package Pin
    │
    ▼
Bond Wire
    │
    ▼
Bond Pad
    │
    ▼
I/O Pad Cell
    │
    ▼
Core-Side Signal
    │
    ▼
Digital Core Logic
```

ตัวอย่างสัญญาณ Input มีทิศทางดังนี้

```text
External Pin
    │
    ▼
input_PAD
    │
    ▼
sg13g2_IOPadIn
    │ p2c
    ▼
input_PAD2CORE
    │
    ▼
chip_core
```

ตัวอย่างสัญญาณ Output มีทิศทางดังนี้

```text
chip_core
    │
    ▼
output_CORE2PAD
    │ c2p
    ▼
sg13g2_IOPadOut30mA
    │
    ▼
output_PAD
    │
    ▼
External Pin
```

คำว่า `p2c` หมายถึง Pad-to-Core ส่วน `c2p` หมายถึง Core-to-Pad

---

## 3. ขั้นตอนเพิ่มเติมของ Chip Flow

การสร้าง Full-Chip จำเป็นต้องใช้ขั้นตอนเพิ่มเติมจาก Classic RTL-to-GDSII Flow ได้แก่

### 3.1 OpenROAD.PadRing

ทำหน้าที่

- อ่านรายชื่อ I/O Pad Instances
- จัดวาง Pad ตามแต่ละด้านของ Die
- หมุน Orientation ของ Pad ให้ถูกต้อง
- จัดวาง Corner Cells หรือ Filler Cells ตามกฎของ PDK
- สร้างโครงสร้าง Pad Ring รอบ Core

### 3.2 KLayout.SealRing

ทำหน้าที่สร้าง Seal Ring รอบขอบ Die

Seal Ring มีหน้าที่ช่วย

- ป้องกันความเสียหายเชิงกลบริเวณขอบ Die
- ลดความเสี่ยงจากรอยแตกในกระบวนการ Dicing
- ป้องกันโครงสร้างโลหะและ Active Region ใกล้ขอบชิป
- กำหนดขอบเขตระหว่างวงจรกับบริเวณตัดแผ่น Wafer

### 3.3 KLayout.Filler หรือ Magic.Filler

ทำหน้าที่เติมโครงสร้าง Filler ในบริเวณที่จำเป็นตามกฎของ PDK เช่น

- Density Filler
- Metal Filler
- Geometry สำหรับรักษาความหนาแน่นของ Layer
- Shape ที่จำเป็นต่อกระบวนการผลิต

### 3.4 KLayout.Density

ใช้ตรวจสอบความหนาแน่นของ Layout ในแต่ละ Layer เพื่อให้เป็นไปตามกฎกระบวนการผลิต

> ใน Configuration ของ Lab นี้ ขั้นตอน DRC บางส่วนถูกปิดไว้เพื่อลดเวลาและหลีกเลี่ยงข้อจำกัดของตัวอย่าง ดังนั้นผลลัพธ์ของ Lab ไม่ควรถูกถือว่าเป็น Tapeout Signoff โดยอัตโนมัติ

---

## 4. โครงสร้างไฟล์ของบทปฏิบัติการ

เข้าสู่ไดเรกทอรี Repository แล้วตรวจสอบโครงสร้างของโฟลเดอร์ `bonus`

```bash
cd heichips26-digital-workshop/bonus
find . -maxdepth 4 -type f | sort
```

โครงสร้างหลักควรมีลักษณะดังนี้

```text
bonus/
├── README.md
├── config.yaml
├── chip_top.sdc
├── src/
│   ├── chip_top.sv
│   └── chip_core.sv
├── ip/
│   └── bondpad_70x70_novias/
│       ├── gds/
│       │   └── bondpad_70x70_novias.gds
│       ├── lef/
│       │   └── bondpad_70x70_novias.lef
│       └── vh/
└── img/
```

หน้าที่ของแต่ละไฟล์มีดังนี้

| ไฟล์หรือไดเรกทอรี | หน้าที่ |
|---|---|
| `config.yaml` | กำหนด LibreLane Chip Flow, Pad Order, Floorplan, Clock, PDN และ External IP |
| `chip_top.sdc` | กำหนด Timing Constraints ของ Full-Chip |
| `src/chip_top.sv` | Top-Level RTL ซึ่งสร้างและเชื่อมต่อ I/O Pad Cells |
| `src/chip_core.sv` | วงจรดิจิทัลภายในชิป |
| `ip/.../lef` | Physical Abstract ของ Bond Pad สำหรับ Placement และ Routing |
| `ip/.../gds` | Layout Geometry จริงของ Bond Pad สำหรับ GDS Stream-Out |
| `img/` | รูปตัวอย่างผลลัพธ์จาก OpenROAD และ KLayout |

---

## 5. ขั้นตอนที่ 1: เตรียมสภาพแวดล้อม

### 5.1 เข้าสู่โฟลเดอร์ Repository

```bash
cd heichips26-digital-workshop
```

ตรวจสอบตำแหน่งปัจจุบัน

```bash
pwd
```

### 5.2 เปิด Nix Environment

จาก Root Directory ของ Repository ให้เรียก

```bash
nix-shell
```

หรือในกรณีที่ Repository กำหนด Flake Environment

```bash
nix develop
```

หลังเข้าสู่ Environment ให้ตรวจสอบคำสั่ง LibreLane

```bash
librelane --version
```

ตรวจสอบ OpenROAD

```bash
openroad -version
```

ตรวจสอบ KLayout

```bash
klayout -v
```

### 5.3 ตรวจสอบ PDK

```bash
librelane --pdk ihp-sg13g2 --manual-pdk
```

หาก Environment ได้กำหนด PDK ไว้อย่างถูกต้อง LibreLane ต้องสามารถค้นหา IHP SG13G2 PDK ได้

### 5.4 เข้าสู่โฟลเดอร์ Bonus

```bash
cd bonus
```

ตรวจสอบไฟล์

```bash
ls -lah
ls -lah src
ls -lah ip/bondpad_70x70_novias/lef
ls -lah ip/bondpad_70x70_novias/gds
```

ผลลัพธ์ต้องแสดงไฟล์อย่างน้อยดังนี้

```text
config.yaml
chip_top.sdc
src/chip_top.sv
src/chip_core.sv
ip/bondpad_70x70_novias/lef/bondpad_70x70_novias.lef
ip/bondpad_70x70_novias/gds/bondpad_70x70_novias.gds
```

---

## 6. ขั้นตอนที่ 2: ศึกษาโครงสร้างของ `chip_core.sv`

เปิดไฟล์

```bash
sed -n '1,220p' src/chip_core.sv
```

โมดูล `chip_core` เป็นวงจรดิจิทัลที่อยู่ภายใน Pad Ring

ส่วนประกาศ Parameter มีลักษณะดังนี้

```systemverilog
module chip_core #(
    parameter NUM_INPUT_PADS,
    parameter NUM_OUTPUT_PADS,
    parameter NUM_BIDIR_PADS,
    parameter NUM_ANALOG_PADS
)(
    input  logic clk,
    input  logic rst_n,

    input  wire [NUM_INPUT_PADS-1:0]  input_in,
    output wire [NUM_OUTPUT_PADS-1:0] output_out,

    input  wire [NUM_BIDIR_PADS-1:0]  bidir_in,
    output wire [NUM_BIDIR_PADS-1:0]  bidir_out,
    output wire [NUM_BIDIR_PADS-1:0]  bidir_oe,

    inout wire [NUM_ANALOG_PADS-1:0] analog
);
```

### 6.1 หน้าที่ของสัญญาณ

| สัญญาณ | ทิศทาง | หน้าที่ |
|---|---:|---|
| `clk` | Input | Clock ที่ผ่าน Input Pad แล้ว |
| `rst_n` | Input | Active-Low Reset |
| `input_in` | Input | ข้อมูลจาก Input Pads |
| `output_out` | Output | ข้อมูลที่จะส่งไป Output Pads |
| `bidir_in` | Input | ข้อมูลที่อ่านจาก Bidirectional Pads |
| `bidir_out` | Output | ข้อมูลที่จะขับออก Bidirectional Pads |
| `bidir_oe` | Output | Output Enable ของ Bidirectional Pads |
| `analog` | Inout | สัญญาณ Analog ที่ส่งผ่าน Analog Pads |

### 6.2 การกำหนดทิศทางของ Bidirectional Pads

```systemverilog
assign bidir_oe = '1;
```

คำสั่งนี้กำหนดให้ทุกบิตของ `bidir_oe` มีค่าเป็น Logic 1

ใน Pad Cell ที่ใช้ในตัวอย่าง ค่า `c2p_en = 1` หมายถึงเปิด Output Driver ดังนั้น Bidirectional Pads ทั้งหมดถูกใช้เป็น Output ใน Lab นี้

> ในการออกแบบจริงต้องตรวจสอบ Polarity ของ Output Enable จาก Datasheet หรือ Verilog Model ของ Pad Cell เสมอ เพราะ Pad Library แต่ละชุดอาจนิยาม Active-High หรือ Active-Low ต่างกัน

### 6.3 การใช้สัญญาณ `bidir_in`

```systemverilog
logic _unused;
assign _unused = &bidir_in;
```

วงจร Reduction AND นี้ไม่มีผลต่อฟังก์ชันหลัก แต่ช่วยให้สัญญาณ `bidir_in` ถูกอ้างอิงใน RTL และลดคำเตือนเกี่ยวกับ Input ที่ไม่ได้ใช้งาน

### 6.4 Counter ภายใน Core

```systemverilog
logic [NUM_BIDIR_PADS-1:0] count;

always_ff @(posedge clk) begin
    if (!rst_n) begin
        count <= '0;
    end else begin
        if (&input_in) begin
            count <= count + 1;
        end
    end
end
```

การทำงานมีดังนี้

1. เมื่อ `rst_n = 0` ค่า `count` ถูกล้างเป็นศูนย์
2. เมื่อเกิดขอบขาขึ้นของ `clk`
3. วงจรตรวจสอบว่า Input ทุกบิตเป็น 1 หรือไม่
4. Reduction AND `&input_in` จะเป็น 1 เมื่อทุกบิตของ `input_in` เป็น 1
5. หากเงื่อนไขเป็นจริง Counter จะเพิ่มค่าทีละ 1
6. หากเงื่อนไขไม่เป็นจริง Counter จะคงค่าเดิม

### 6.5 การส่งค่า Counter ออก

```systemverilog
assign bidir_out  = count;
assign output_out = count;
```

ค่า Counter ถูกส่งออกพร้อมกันผ่าน

- Output Pads
- Bidirectional Pads

ถ้า `NUM_OUTPUT_PADS` และ `NUM_BIDIR_PADS` มีขนาดเท่ากัน ค่า Counter ทั้งหมดจะถูกส่งออกโดยตรง

---

## 7. ขั้นตอนที่ 3: ศึกษาโครงสร้างของ `chip_top.sv`

เปิดไฟล์

```bash
sed -n '1,260p' src/chip_top.sv
```

`chip_top` เป็นโมดูลระดับบนสุดของชิป มีหน้าที่

- สร้าง Pad Cells
- สร้าง Power Pads
- เชื่อมต่อสัญญาณระหว่าง Pad และ Core
- สร้าง `chip_core`
- เปิดเผยขาระดับชิป เช่น `clk_PAD`, `input_PAD` และ `output_PAD`

### 7.1 จำนวน Pad แต่ละประเภท

```systemverilog
parameter NUM_VDD_PADS    = 1;
parameter NUM_VSS_PADS    = 1;
parameter NUM_IOVDD_PADS  = 1;
parameter NUM_IOVSS_PADS  = 1;

parameter NUM_INPUT_PADS  = 10;
parameter NUM_OUTPUT_PADS = 8;
parameter NUM_BIDIR_PADS  = 8;
parameter NUM_ANALOG_PADS = 8;
```

จำนวน Signal Pads คือ

```text
Clock Pad          =  1
Reset Pad          =  1
Input Pads         = 10
Output Pads        =  8
Bidirectional Pads =  8
Analog Pads        =  8
--------------------------------
Signal Pads        = 36
```

จำนวน Power Pads คือ

```text
Core VDD Pad = 1
Core VSS Pad = 1
I/O VDD Pad  = 1
I/O VSS Pad  = 1
--------------------------------
Power Pads   = 4
```

จำนวน Pad Instances รวมโดยไม่รวม Corner Cells และ Pad Fillers เท่ากับ

```text
36 + 4 = 40 Pads
```

### 7.2 Power Pins

```systemverilog
`ifdef USE_POWER_PINS
    inout wire IOVDD,
    inout wire IOVSS,
    inout wire VDD,
    inout wire VSS,
`endif
```

การใช้ Compiler Directive ทำให้สามารถเปิดหรือปิด Explicit Power Pins ได้

Power Domain ในตัวอย่างแบ่งเป็น

| Net | หน้าที่ |
|---|---|
| `VDD` | แหล่งจ่ายของ Digital Core |
| `VSS` | Ground ของ Digital Core |
| `IOVDD` | แหล่งจ่ายของ I/O Circuit |
| `IOVSS` | Ground ของ I/O Circuit |

แม้ Layout จะมี Power Pad หลายประเภท แต่ Configuration ของ Lab กำหนด Global Power/Ground Nets หลักเป็น `VDD` และ `VSS`

### 7.3 ขาระดับชิป

```systemverilog
inout wire clk_PAD;
inout wire rst_n_PAD;

inout wire [NUM_INPUT_PADS-1:0]  input_PAD;
inout wire [NUM_OUTPUT_PADS-1:0] output_PAD;
inout wire [NUM_BIDIR_PADS-1:0]  bidir_PAD;
inout wire [NUM_ANALOG_PADS-1:0] analog_PAD;
```

ขาระดับ Top ถูกประกาศเป็น `inout` เนื่องจาก Physical Pad Cells เชื่อมต่อขอบเขตชิปและอาจมีโครงสร้างไฟฟ้าภายในที่ไม่ตรงกับทิศทางเชิงตรรกะแบบธรรมดา

ทิศทางเชิงฟังก์ชันจริงถูกกำหนดโดยชนิดของ Pad Cell

### 7.4 Internal Nets ระหว่าง Pad และ Core

```systemverilog
wire clk_PAD2CORE;
wire rst_n_PAD2CORE;

wire [NUM_INPUT_PADS-1:0]  input_PAD2CORE;
wire [NUM_OUTPUT_PADS-1:0] output_CORE2PAD;

wire [NUM_BIDIR_PADS-1:0] bidir_PAD2CORE;
wire [NUM_BIDIR_PADS-1:0] bidir_CORE2PAD;
wire [NUM_BIDIR_PADS-1:0] bidir_CORE2PAD_OE;
```

ชื่อสัญญาณระบุทิศทางไว้อย่างชัดเจน

- `PAD2CORE` คือสัญญาณจาก Pad ไป Core
- `CORE2PAD` คือสัญญาณจาก Core ไป Pad
- `CORE2PAD_OE` คือ Output Enable จาก Core ไป Pad

แนวทางการตั้งชื่อเช่นนี้ช่วยลดความสับสนเมื่อออกแบบ Full-Chip ที่มีสัญญาณหลายระดับ

---

## 8. ขั้นตอนที่ 4: ศึกษา Power Pad Instances

Power Pad ถูกสร้างด้วย Generate Loop

ตัวอย่าง I/O Supply Pad

```systemverilog
for (genvar i = 0; i < NUM_IOVDD_PADS; i++) begin : iovdd_pads
    (* keep *)
    sg13g2_IOPadIOVdd iovdd_pad (
`ifdef USE_POWER_PINS
        .iovdd(IOVDD),
        .iovss(IOVSS),
        .vdd(VDD),
        .vss(VSS)
`endif
    );
end
```

### 8.1 เหตุผลที่ใช้ Generate Loop

Generate Loop ช่วยให้

- เปลี่ยนจำนวน Power Pads ได้จาก Parameter
- สร้าง Instance Name อย่างเป็นระบบ
- รองรับการเพิ่มจำนวน Pads เพื่อรองรับกระแสสูงขึ้น
- ทำให้ Pad Ordering ใน Configuration อ้างอิง Instance ได้ชัดเจน

ตัวอย่างชื่อ Hierarchical Instance ที่เกิดขึ้นคือ

```text
iovdd_pads[0].iovdd_pad
iovss_pads[0].iovss_pad
vdd_pads[0].vdd_pad
vss_pads[0].vss_pad
```

ในไฟล์ YAML ต้อง Escape เครื่องหมายวงเล็บเหลี่ยม เช่น

```yaml
"vdd_pads\\[0\\].vdd_pad"
```

### 8.2 Attribute `(* keep *)`

```systemverilog
(* keep *)
```

ใช้บอก Synthesis Tool ไม่ให้ลบ Instance ที่อาจดูเหมือนไม่มีผลเชิงตรรกะ

Power Pads และ Analog Pads อาจไม่มี Logic Path ที่เครื่องมือสังเคราะห์มองเห็น ดังนั้นหากไม่มี Attribute หรือ Configuration ที่เหมาะสม Instance อาจถูก Optimize ออก

---

## 9. ขั้นตอนที่ 5: ศึกษา Signal I/O Pads

### 9.1 Clock Input Pad

```systemverilog
sg13g2_IOPadIn clk_pad (
    .p2c(clk_PAD2CORE),
    .pad(clk_PAD)
);
```

การเชื่อมต่อคือ

```text
clk_PAD → Pad Cell → clk_PAD2CORE → chip_core.clk
```

สัญญาณ Clock ที่เข้า Core ไม่ใช่ Net `clk_PAD` โดยตรง แต่เป็น Output Pin `p2c` ของ Instance `clk_pad`

จุดนี้มีความสำคัญต่อการกำหนด `CLOCK_NET` ใน `config.yaml`

### 9.2 Reset Input Pad

```systemverilog
sg13g2_IOPadIn rst_n_pad (
    .p2c(rst_n_PAD2CORE),
    .pad(rst_n_PAD)
);
```

การเชื่อมต่อคือ

```text
rst_n_PAD → rst_n_pad → rst_n_PAD2CORE → chip_core.rst_n
```

### 9.3 Input Pads

```systemverilog
for (genvar i = 0; i < NUM_INPUT_PADS; i++) begin : inputs
    sg13g2_IOPadIn input_pad (
        .p2c(input_PAD2CORE[i]),
        .pad(input_PAD[i])
    );
end
```

Hierarchical Instance Names ที่เกิดขึ้น เช่น

```text
inputs[0].input_pad
inputs[1].input_pad
...
inputs[9].input_pad
```

### 9.4 Output Pads

```systemverilog
for (genvar i = 0; i < NUM_OUTPUT_PADS; i++) begin : outputs
    sg13g2_IOPadOut30mA output_pad (
        .c2p(output_CORE2PAD[i]),
        .pad(output_PAD[i])
    );
end
```

Output Pad รุ่นนี้มี Output Driver ที่ระบุความสามารถในการขับกระแสในชื่อ Cell

การเชื่อมต่อคือ

```text
chip_core.output_out[i]
        │
        ▼
output_CORE2PAD[i]
        │
        ▼
sg13g2_IOPadOut30mA
        │
        ▼
output_PAD[i]
```

### 9.5 Bidirectional Pads

```systemverilog
sg13g2_IOPadInOut30mA bidir_pad (
    .c2p(bidir_CORE2PAD[i]),
    .c2p_en(bidir_CORE2PAD_OE[i]),
    .p2c(bidir_PAD2CORE[i]),
    .pad(bidir_PAD[i])
);
```

Bidirectional Pad มีสัญญาณสำคัญสามชุด

| Pin | ทิศทางเชิงฟังก์ชัน | หน้าที่ |
|---|---|---|
| `c2p` | Core-to-Pad | ข้อมูลที่ต้องการส่งออก |
| `c2p_en` | Core-to-Pad | เปิดหรือปิด Output Driver |
| `p2c` | Pad-to-Core | ข้อมูลที่อ่านจากขาภายนอก |

### 9.6 Analog Pads

```systemverilog
sg13g2_IOPadAnalog analog_pad (
    .padres(analog_PADRES[i]),
    .pad(analog_PAD[i])
);
```

Analog Pad ส่งผ่านสัญญาณจาก Pad เข้าสู่ Analog Net ภายในโดยไม่ผ่าน Digital Input Buffer แบบเดียวกับ Input Pad

ใน Lab นี้ Analog Nets ถูกส่งต่อไปยัง `chip_core` แต่ไม่ได้ถูกใช้สร้างฟังก์ชันอนาล็อกจริง

---

## 10. ขั้นตอนที่ 6: ตรวจสอบการเชื่อมต่อกับ Core

ส่วนท้ายของ `chip_top.sv` สร้าง `chip_core`

```systemverilog
(* keep *) chip_core #(
    .NUM_INPUT_PADS (NUM_INPUT_PADS),
    .NUM_OUTPUT_PADS(NUM_OUTPUT_PADS),
    .NUM_BIDIR_PADS (NUM_BIDIR_PADS),
    .NUM_ANALOG_PADS(NUM_ANALOG_PADS)
) i_chip_core (
    .clk       (clk_PAD2CORE),
    .rst_n     (rst_n_PAD2CORE),
    .input_in  (input_PAD2CORE),
    .output_out(output_CORE2PAD),
    .bidir_in  (bidir_PAD2CORE),
    .bidir_out (bidir_CORE2PAD),
    .bidir_oe  (bidir_CORE2PAD_OE),
    .analog    (analog_PADRES)
);
```

ตรวจสอบให้แน่ใจว่า

- จำนวนบิตของ Port ตรงกัน
- Clock เชื่อมจาก `clk_PAD2CORE`
- Reset เชื่อมจาก `rst_n_PAD2CORE`
- Input Bus เชื่อมจาก Input Pads
- Output Bus เชื่อมไป Output Pads
- Bidirectional Control เชื่อมครบทั้ง Data Input, Data Output และ Output Enable

---

## 11. ขั้นตอนที่ 7: ศึกษา `config.yaml`

เปิดไฟล์

```bash
sed -n '1,240p' config.yaml
```

### 11.1 เลือก Chip Flow

```yaml
meta:
  version: 3
  flow: Chip
```

ค่า

```yaml
flow: Chip
```

เป็นหัวใจสำคัญของบทปฏิบัติการ เพราะทำให้ LibreLane เพิ่มขั้นตอนระดับ Full-Chip เช่น

- Pad Ring
- Bond Pad
- Seal Ring
- Filler
- Density Processing
- Full-Chip GDS Stream-Out

### 11.2 ปิด Checker บางรายการ

```yaml
substituting_steps:
  Checker.IllegalOverlap: null

  KLayout.DRC: null
  Checker.KLayoutDRC: null

  Magic.DRC: null
  Checker.MagicDRC: null
```

Configuration นี้ปิด

- Illegal Overlap Checker
- KLayout DRC
- Magic DRC

เหตุผลที่ Comment ระบุไว้คือ Magic รายงาน Overlap บางรายการซึ่งสามารถละเว้นได้ในตัวอย่าง

อย่างไรก็ตาม การปิด DRC หมายความว่า Flow นี้ยังไม่ผ่าน Physical Verification ครบถ้วน

> ผลลัพธ์ที่ Antenna และ LVS ผ่าน แต่ DRC ถูกปิด ไม่ถือเป็น Tapeout-Clean Design

สำหรับงานจริงควรเปิด DRC กลับคืนและแก้ Violation ทั้งหมดก่อน Signoff

### 11.3 กำหนดชื่อ Top-Level Design

```yaml
DESIGN_NAME: chip_top
```

ค่าต้องตรงกับชื่อโมดูลใน RTL

```systemverilog
module chip_top;
```

### 11.4 กำหนด RTL Files

```yaml
VERILOG_FILES:
  - dir::src/chip_top.sv
  - dir::src/chip_core.sv
```

`dir::` หมายถึง Path ที่สัมพันธ์กับตำแหน่งของ `config.yaml`

ลำดับของไฟล์ควรทำให้ Tool มองเห็น Top-Level และ Submodule ได้ครบถ้วน

### 11.5 เลือก GDS Stream-Out Tool

```yaml
PRIMARY_GDSII_STREAMOUT_TOOL: klayout
```

กำหนดให้ KLayout เป็นเครื่องมือหลักในการรวม Layout และสร้าง Final GDSII

---

## 12. ขั้นตอนที่ 8: กำหนด Pad Order

Pad Ring ถูกแบ่งเป็นสี่ด้าน

- South
- East
- North
- West

### 12.1 South Pads

```yaml
PAD_SOUTH: [
  clk_pad,
  rst_n_pad,
  "bidirs\\[0\\].bidir_pad",
  "bidirs\\[1\\].bidir_pad",
  "bidirs\\[2\\].bidir_pad",
  "bidirs\\[3\\].bidir_pad",
  "bidirs\\[4\\].bidir_pad",
  "bidirs\\[5\\].bidir_pad",
  "bidirs\\[6\\].bidir_pad",
  "bidirs\\[7\\].bidir_pad"
]
```

ด้านใต้ประกอบด้วย

- Clock Pad
- Reset Pad
- Bidirectional Pads 8 ตัว

รวม 10 Pads

### 12.2 East Pads

```yaml
PAD_EAST: [
  "analogs\\[0\\].analog_pad",
  ...
  "analogs\\[7\\].analog_pad",
  "vdd_pads\\[0\\].vdd_pad",
  "vss_pads\\[0\\].vss_pad"
]
```

ด้านตะวันออกประกอบด้วย

- Analog Pads 8 ตัว
- Core VDD Pad 1 ตัว
- Core VSS Pad 1 ตัว

รวม 10 Pads

### 12.3 North Pads

```yaml
PAD_NORTH: [
  "outputs\\[7\\].output_pad",
  ...
  "outputs\\[0\\].output_pad",
  "iovdd_pads\\[0\\].iovdd_pad",
  "iovss_pads\\[0\\].iovss_pad"
]
```

ด้านเหนือประกอบด้วย

- Output Pads 8 ตัว
- I/O VDD Pad 1 ตัว
- I/O VSS Pad 1 ตัว

รวม 10 Pads

ลำดับ Output ถูกกำหนดจากบิต 7 ลงมาบิต 0 เพื่อให้ Orientation บนขอบชิปสอดคล้องกับลำดับที่ต้องการเมื่อมอง Layout

### 12.4 West Pads

```yaml
PAD_WEST: [
  "inputs\\[9\\].input_pad",
  ...
  "inputs\\[0\\].input_pad"
]
```

ด้านตะวันตกประกอบด้วย Input Pads 10 ตัว

### 12.5 สรุป Pad Distribution

| ด้าน | Pad Type | จำนวน |
|---|---|---:|
| South | Clock, Reset, Bidirectional | 10 |
| East | Analog, Core Power/Ground | 10 |
| North | Output, I/O Power/Ground | 10 |
| West | Input | 10 |
| รวม |  | 40 |

การกระจายจำนวน Pad เท่ากันทุกด้านช่วยให้ Pad Ring มีสมมาตรและใช้พื้นที่ขอบ Die ได้เหมาะสม

### 12.6 ข้อควรระวังเรื่อง Instance Name

รายชื่อใน `PAD_SOUTH`, `PAD_EAST`, `PAD_NORTH` และ `PAD_WEST` ต้องตรงกับ Hierarchical Instance Name หลัง Elaboration ทุกตัว

ตัวอย่าง

```systemverilog
for (...) begin : outputs
    sg13g2_IOPadOut30mA output_pad (...);
end
```

จะสร้างชื่อ

```text
outputs[0].output_pad
```

ใน YAML ต้องเขียนเป็น

```yaml
"outputs\\[0\\].output_pad"
```

หากสะกดผิด LibreLane อาจรายงานว่าไม่พบ Pad Instance หรือไม่สามารถสร้าง Pad Ring ได้

---

## 13. ขั้นตอนที่ 9: กำหนด Timing Constraint Files

```yaml
PNR_SDC_FILE: dir::chip_top.sdc
SIGNOFF_SDC_FILE: dir::chip_top.sdc
FALLBACK_SDC: dir::chip_top.sdc
```

ไฟล์เดียวถูกใช้ในสามบริบท

| Variable | หน้าที่ |
|---|---|
| `PNR_SDC_FILE` | Constraints ระหว่าง Placement, CTS และ Routing |
| `SIGNOFF_SDC_FILE` | Constraints สำหรับ Final STA |
| `FALLBACK_SDC` | Constraints สำรองในขั้นตอนที่ต้องการ SDC |

การระบุครบทั้งสามตัวช่วยหลีกเลี่ยงคำเตือนว่าไม่พบ PNR หรือ Signoff SDC

---

## 14. ขั้นตอนที่ 10: กำหนด Power และ Ground Nets

```yaml
VDD_NETS:
  - VDD

GND_NETS:
  - VSS
```

LibreLane ใช้ข้อมูลนี้เพื่อ

- ระบุ Global Power Nets
- สร้าง PDN
- เชื่อม Core Ring
- เชื่อม Standard Cell Rails
- วิเคราะห์ Connectivity ของ Power/Ground
- ช่วยในการตรวจสอบ LVS

ต้องตรวจสอบให้ชื่อ Net ตรงกับ Power Pins ใน RTL และ Pad Cells

---

## 15. ขั้นตอนที่ 11: กำหนด Clock

```yaml
CLOCK_PORT: clk_PAD
CLOCK_NET: clk_pad/p2c
CLOCK_PERIOD: 20
```

### 15.1 Clock Port

```yaml
CLOCK_PORT: clk_PAD
```

เป็นขาระดับ Top-Level ของชิป

### 15.2 Clock Net

```yaml
CLOCK_NET: clk_pad/p2c
```

เป็น Pin ภายในของ Clock Input Pad ที่ส่ง Clock ไปยัง Core

โครงสร้าง Clock Path คือ

```text
clk_PAD
   │
   ▼
clk_pad.pad
   │
   ▼
clk_pad/p2c
   │
   ▼
clk_PAD2CORE
   │
   ▼
chip_core.clk
```

การกำหนด `CLOCK_PORT` และ `CLOCK_NET` ต่างกันทำให้ SDC สามารถสร้าง Clock บน Pin ภายใน Pad Cell แทนการสร้าง Clock ที่ External Pad โดยตรง

### 15.3 Clock Period

```yaml
CLOCK_PERIOD: 20
```

หน่วยเป็นนาโนวินาที

ความถี่เป้าหมายคำนวณได้จาก

```text
f = 1 / T
```

ดังนั้น

```text
T = 20 ns
f = 1 / 20 ns
f = 50 MHz
```

วงจรนี้จึงมี Target Clock Frequency เท่ากับ 50 MHz

---

## 16. ขั้นตอนที่ 12: กำหนด Floorplan

```yaml
FP_SIZING: absolute
DIE_AREA:  [0, 0, 1600, 1600]
CORE_AREA: [365, 365, 1235, 1235]
```

### 16.1 Die Area

```yaml
DIE_AREA: [0, 0, 1600, 1600]
```

กำหนดขอบเขต Die เป็น

```text
Lower-left  = (0, 0)
Upper-right = (1600, 1600)
```

ขนาด Die คือ

```text
Width  = 1600 µm
Height = 1600 µm
Area   = 2,560,000 µm²
       = 2.56 mm²
```

### 16.2 Core Area

```yaml
CORE_AREA: [365, 365, 1235, 1235]
```

ขนาด Core คือ

```text
Width  = 1235 - 365 = 870 µm
Height = 1235 - 365 = 870 µm
Area   = 756,900 µm²
       = 0.7569 mm²
```

ระยะจาก Core ถึงขอบ Die แต่ละด้านคือ

```text
Left   = 365 µm
Bottom = 365 µm
Right  = 1600 - 1235 = 365 µm
Top    = 1600 - 1235 = 365 µm
```

จึงเป็น Floorplan แบบสมมาตร

พื้นที่ระหว่าง Core กับ Die ถูกใช้สำหรับ

- I/O Pads
- Bond Pads
- Pad Routing
- Core Ring
- Seal Ring
- Routing ระหว่าง Pads และ Core

### 16.3 Placement Density

```yaml
PL_TARGET_DENSITY_PCT: 10
```

กำหนด Target Density เพียง 10% เนื่องจากวงจร Core มีขนาดเล็กเมื่อเทียบกับ Core Area

ค่า Density ต่ำทำให้

- Placement มีพื้นที่ว่างมาก
- ลดความเสี่ยงด้าน Congestion
- ทำให้มองเห็นโครงสร้าง Full-Chip ได้ง่าย
- เหมาะสำหรับ Lab

แต่สำหรับชิปจริง ค่า Density ต่ำมากทำให้ใช้พื้นที่ Silicon ไม่คุ้มค่า

### 16.4 อนุญาต Congestion

```yaml
GRT_ALLOW_CONGESTION: true
```

อนุญาตให้ Global Routing ดำเนินต่อได้แม้มี Congestion บางส่วน

ค่านี้เหมาะสำหรับการทดลอง แต่ควรตรวจสอบ Congestion Report และแก้ไขในงานจริง

---

## 17. ขั้นตอนที่ 13: เพิ่ม Bond Pad IP

```yaml
PAD_BONDPAD_NAME: bondpad_70x70_novias
```

กำหนดชื่อ Macro ที่จะใช้เป็น Bond Pad

### 17.1 เพิ่ม GDS

```yaml
EXTRA_GDS:
  - dir::ip/bondpad_70x70_novias/gds/bondpad_70x70_novias.gds
```

GDS ประกอบด้วย Geometry จริงของ Bond Pad ซึ่งจะถูก Merge เข้ากับ Final GDSII

### 17.2 เพิ่ม LEF

```yaml
EXTRA_LEFS:
  - dir::ip/bondpad_70x70_novias/lef/bondpad_70x70_novias.lef
```

LEF เป็น Physical Abstract ซึ่งอธิบาย

- ขนาด Macro
- Boundary
- Pin Geometry
- Obstructions
- Routing Layers
- Placement Information

OpenROAD ใช้ LEF ระหว่าง Floorplan, Placement และ Routing ส่วน KLayout ใช้ GDS ในขั้นตอน Final Stream-Out

### 17.3 ไม่ตรวจสอบ Logic Connectivity ของ Bond Pad Module

```yaml
IGNORE_DISCONNECTED_MODULES:
  - bondpad_70x70_novias
```

Bond Pad เป็น Physical-Only Macro หรืออาจไม่มี Logical Connectivity แบบ Digital Logic จึงถูกกำหนดให้ละเว้นการตรวจสอบ Disconnected Module

### 17.4 ตรวจสอบชื่อ Macro ใน LEF

ใช้คำสั่ง

```bash
grep -n "^MACRO" \
  ip/bondpad_70x70_novias/lef/bondpad_70x70_novias.lef
```

ควรพบ

```text
MACRO bondpad_70x70_novias
```

ชื่อต้องตรงกับ

```yaml
PAD_BONDPAD_NAME: bondpad_70x70_novias
```

---

## 18. ขั้นตอนที่ 14: กำหนด PDN Core Ring

```yaml
PDN_CORE_RING: true
```

เปิดการสร้าง Power Ring รอบ Core

### 18.1 ความกว้างของ Ring

```yaml
PDN_CORE_RING_VWIDTH: 15
PDN_CORE_RING_HWIDTH: 15
```

กำหนด Vertical และ Horizontal Ring Width เท่ากับ 15 µm

### 18.2 ระยะห่างของ Ring

```yaml
PDN_CORE_RING_VSPACING: 5
PDN_CORE_RING_HSPACING: 5
```

กำหนดระยะห่างระหว่าง Power Ring และ Ground Ring เท่ากับ 5 µm

Configuration ระบุว่าโลหะที่กว้างเกินไปอาจต้องใช้ Slotting ตามกฎกระบวนการผลิต จึงเลือกความกว้าง 15 µm ซึ่งต่ำกว่าค่าที่ Comment ระบุว่าเป็น Maximum Width Without Slotting คือ 30 µm

### 18.3 เชื่อม Core Ring เข้ากับ Pads

```yaml
PDN_CORE_RING_CONNECT_TO_PADS: true
```

ทำให้ PDN Generator สร้างการเชื่อมต่อระหว่าง

- Power Pads
- Ground Pads
- Core Ring
- Core Power Grid

### 18.4 ปิด PDN Pins

```yaml
PDN_ENABLE_PINS: false
```

ใน Full-Chip Power เข้าสู่ Core ผ่าน Power Pads จึงไม่จำเป็นต้องสร้าง External PDN Pins แบบ Core-Only Design

---

## 19. ขั้นตอนที่ 15: ศึกษา `chip_top.sdc`

เปิดไฟล์

```bash
sed -n '1,220p' chip_top.sdc
```

### 19.1 กำหนด Current Design และหน่วยเวลา

```tcl
current_design $::env(DESIGN_NAME)
set_units -time ns
```

### 19.2 เลือก Clock Port

SDC ตรวจสอบตัวแปร `CLOCK_PORT` จาก Environment

```tcl
set clock_port __VIRTUAL_CLK__

if { [info exists ::env(CLOCK_PORT)] } {
    set port_count [llength $::env(CLOCK_PORT)]

    if { $port_count == "0" } {
        puts "[WARNING] No CLOCK_PORT found."
    } elseif { $port_count != "1" } {
        puts "[WARNING] Multi-clock files are not currently supported."
    }

    if { $port_count > "0" } {
        set ::clock_port [lindex $::env(CLOCK_PORT) 0]
    }
}
```

ไฟล์พื้นฐานนี้รองรับ Clock หลักหนึ่งตัว หากกำหนดหลาย Clock จะใช้เพียง Clock แรก

### 19.3 สร้าง Clock บน Clock Net ภายใน Pad

```tcl
if { $::env(CLOCK_PORT) == $::env(CLOCK_NET) } {
    set port_args [get_ports $clock_port]
} else {
    set port_args [get_pins [lindex $::env(CLOCK_NET) 0]]
}
```

ใน Lab นี้

```text
CLOCK_PORT = clk_PAD
CLOCK_NET  = clk_pad/p2c
```

ค่าทั้งสองไม่เท่ากัน จึงใช้

```tcl
get_pins clk_pad/p2c
```

จากนั้นสร้าง Clock

```tcl
create_clock \
    {*}$port_args \
    -name $clock_port \
    -period $::env(CLOCK_PERIOD)
```

### 19.4 คำนวณ Input และ Output Delay

```tcl
set input_delay_value \
    [expr $::env(CLOCK_PERIOD) *
          $::env(IO_DELAY_CONSTRAINT) / 100]

set output_delay_value \
    [expr $::env(CLOCK_PERIOD) *
          $::env(IO_DELAY_CONSTRAINT) / 100]
```

ค่า Delay ถูกคำนวณเป็นเปอร์เซ็นต์ของ Clock Period

ตัวอย่าง หาก

```text
CLOCK_PERIOD       = 20 ns
IO_DELAY_CONSTRAINT = 20%
```

จะได้

```text
Input Delay  = 4 ns
Output Delay = 4 ns
```

### 19.5 กำหนด Input Delay

```tcl
set clk_core_input_ports [get_ports {
    rst_n_PAD
    input_PAD[*]
}]
```

จากนั้นกำหนด

```tcl
set_input_delay -min 0 \
    -clock $clocks \
    $clk_core_input_ports

set_input_delay -max $input_delay_value \
    -clock $clocks \
    $clk_core_input_ports
```

Clock Pad ไม่ถูกรวมอยู่ใน Input Delay เนื่องจาก Clock ถูกใช้เป็น Reference Clock

### 19.6 กำหนด Output Delay

```tcl
set clk_core_output_ports [get_ports {
    output_PAD[*]
}]
```

จากนั้น

```tcl
set_output_delay $output_delay_value \
    -clock $clocks \
    $clk_core_output_ports
```

### 19.7 กำหนด Constraint สำหรับ Bidirectional Pads

```tcl
set clk_core_inout_ports [get_ports {
    bidir_PAD[*]
}]
```

Bidirectional Pads ถูกกำหนดทั้ง Input และ Output Delay

```tcl
set_input_delay -min 0 \
    -clock $clocks \
    $clk_core_inout_ports

set_input_delay -max $input_delay_value \
    -clock $clocks \
    $clk_core_inout_ports

set_output_delay $output_delay_value \
    -clock $clocks \
    $clk_core_inout_ports
```

### 19.8 Output Load

```tcl
set cap_load [expr $::env(OUTPUT_CAP_LOAD) / 1000.0]
set_load $cap_load [all_outputs]
```

มีการหารด้วย 1000 เพื่อแปลงหน่วยตามรูปแบบของตัวแปร Configuration และหน่วย Capacitance ที่ Tool ใช้

### 19.9 Clock Uncertainty

```tcl
set_clock_uncertainty \
    $::env(CLOCK_UNCERTAINTY_CONSTRAINT) \
    $clocks
```

Clock Uncertainty ครอบคลุมปัจจัย เช่น

- Clock Jitter
- Modeling Margin
- Clock Skew ที่ยังไม่ทราบในช่วงก่อน CTS
- Process Variation บางส่วน

### 19.10 Clock Transition

```tcl
set_clock_transition \
    $::env(CLOCK_TRANSITION_CONSTRAINT) \
    $clocks
```

กำหนด Rise/Fall Transition ที่ใช้ใน Timing Analysis

### 19.11 Timing Derate

```tcl
set_timing_derate -early \
    [expr 1 - $::env(TIME_DERATING_CONSTRAINT) / 100]

set_timing_derate -late \
    [expr 1 + $::env(TIME_DERATING_CONSTRAINT) / 100]
```

ตัวอย่าง Derate 5% จะได้

```text
Early Derate = 0.95
Late Derate  = 1.05
```

### 19.12 Propagated Clock

```tcl
set_propagated_clock [all_clocks]
```

ทำให้ STA ใช้ Clock Network Delay ที่เกิดจาก CTS และ Routing จริง แทน Ideal Clock

---

## 20. ขั้นตอนที่ 16: ตรวจสอบ Configuration ก่อนรัน

### 20.1 ตรวจสอบ YAML Syntax

```bash
python3 - <<'PY'
import pathlib
import yaml

path = pathlib.Path("config.yaml")

with path.open("r", encoding="utf-8") as f:
    data = yaml.safe_load(f)

print("YAML syntax: OK")
print("DESIGN_NAME :", data.get("DESIGN_NAME"))
print("FLOW        :", data.get("meta", {}).get("flow"))
print("CLOCK_PORT  :", data.get("CLOCK_PORT"))
print("CLOCK_NET   :", data.get("CLOCK_NET"))
print("CLOCK_PERIOD:", data.get("CLOCK_PERIOD"))
PY
```

ผลที่คาดหวัง

```text
YAML syntax: OK
DESIGN_NAME : chip_top
FLOW        : Chip
CLOCK_PORT  : clk_PAD
CLOCK_NET   : clk_pad/p2c
CLOCK_PERIOD: 20
```

### 20.2 ตรวจสอบ Source Files

```bash
test -f src/chip_top.sv  && echo "chip_top.sv: OK"
test -f src/chip_core.sv && echo "chip_core.sv: OK"
test -f chip_top.sdc     && echo "chip_top.sdc: OK"
```

### 20.3 ตรวจสอบ Bond Pad Files

```bash
test -f ip/bondpad_70x70_novias/lef/bondpad_70x70_novias.lef \
    && echo "Bond-pad LEF: OK"

test -f ip/bondpad_70x70_novias/gds/bondpad_70x70_novias.gds \
    && echo "Bond-pad GDS: OK"
```

### 20.4 ตรวจสอบ Top Module

```bash
grep -n "module chip_top" src/chip_top.sv
grep -n "module chip_core" src/chip_core.sv
```

### 20.5 ตรวจสอบ Clock Pin

```bash
grep -n "clk_pad" src/chip_top.sv
grep -n "\.p2c" src/chip_top.sv
grep -n "CLOCK_NET" config.yaml
```

ต้องยืนยันได้ว่า

```text
CLOCK_NET: clk_pad/p2c
```

สอดคล้องกับ Instance และ Pin ใน RTL

---

## 21. ขั้นตอนที่ 17: รัน LibreLane Chip Flow

จากโฟลเดอร์ `bonus` เรียก

```bash
librelane config.yaml --pdk ihp-sg13g2
```

หรือใช้รูปแบบที่วาง Option ก่อน Configuration

```bash
librelane --pdk ihp-sg13g2 config.yaml
```

ระหว่าง Flow LibreLane จะดำเนินขั้นตอนสำคัญ เช่น

```text
RTL Elaboration
      │
      ▼
Logic Synthesis
      │
      ▼
Floorplanning
      │
      ▼
Pad Ring Generation
      │
      ▼
PDN Generation
      │
      ▼
Placement
      │
      ▼
Clock Tree Synthesis
      │
      ▼
Global Routing
      │
      ▼
Detailed Routing
      │
      ▼
Antenna Repair/Check
      │
      ▼
Parasitic Extraction
      │
      ▼
Static Timing Analysis
      │
      ▼
LVS
      │
      ▼
Bond Pad / Seal Ring / Filler
      │
      ▼
Final GDSII
```

---

## 22. ขั้นตอนที่ 18: ติดตามสถานะระหว่าง Flow

LibreLane จะแสดงชื่อ Step และสถานะใน Terminal

ควรสังเกตคำต่อไปนี้

```text
ERROR
WARNING
VIOLATION
FAILED
PASS
Antenna
LVS
Timing
Routing
```

สามารถบันทึก Output ได้ด้วย

```bash
librelane --pdk ihp-sg13g2 config.yaml \
    2>&1 | tee full_chip_run.log
```

ค้นหา Error

```bash
grep -n -i "error" full_chip_run.log
```

ค้นหา Warning

```bash
grep -n -i "warning" full_chip_run.log
```

ค้นหา LVS

```bash
grep -n -i "lvs" full_chip_run.log
```

ค้นหา Antenna

```bash
grep -n -i "antenna" full_chip_run.log
```

---

## 23. ขั้นตอนที่ 19: ตรวจสอบ Run Directory

เมื่อ Flow เสร็จ LibreLane จะสร้าง Run Directory

ตรวจสอบด้วย

```bash
find runs -maxdepth 2 -type d | sort
```

หา Run ล่าสุด

```bash
ls -1dt runs/* | head -1
```

เก็บ Path ไว้ในตัวแปร

```bash
RUN_DIR=$(ls -1dt runs/* | head -1)
echo "$RUN_DIR"
```

ตรวจสอบไฟล์ผลลัพธ์

```bash
find "$RUN_DIR" -type f | sort | less
```

ไฟล์สำคัญที่ควรค้นหา ได้แก่

```bash
find "$RUN_DIR" -type f \
    \( -name "*.gds" \
    -o -name "*.lef" \
    -o -name "*.def" \
    -o -name "*.v" \
    -o -name "*.spef" \
    -o -name "*.sdf" \
    -o -name "*.rpt" \
    -o -name "*.json" \) | sort
```

---

## 24. ขั้นตอนที่ 20: ตรวจสอบผล Synthesis

ค้นหา Synthesis Report

```bash
find "$RUN_DIR" -type f | grep -Ei "synth|synthesis|stat"
```

ประเด็นที่ควรตรวจสอบ

- Top Module คือ `chip_top`
- `chip_core` ยังอยู่ใน Hierarchy หรือถูก Flatten ตาม Flow
- I/O Pad Instances ไม่ถูก Optimize ทิ้ง
- จำนวน Flip-Flop สอดคล้องกับ Counter
- ไม่มี Undefined Module
- ไม่มี Unresolved References
- ไม่มี Multiple Driver
- ไม่มี Combinational Loop

ค้นหา Pad Cell Names ใน Netlist

```bash
grep -R "sg13g2_IOPad" "$RUN_DIR" \
    --include="*.v" \
    --include="*.nl.v" | head -50
```

---

## 25. ขั้นตอนที่ 21: ตรวจสอบ Floorplan และ Pad Ring

เปิดผลลัพธ์ใน OpenROAD GUI

```bash
librelane \
    --pdk ihp-sg13g2 \
    config.yaml \
    --last-run \
    --flow OpenInOpenROAD
```

### 25.1 สิ่งที่ต้องตรวจสอบใน OpenROAD

#### Die Boundary

ตรวจสอบว่า Die มีขนาดประมาณ

```text
1600 µm × 1600 µm
```

#### Core Boundary

ตรวจสอบว่า Core Area อยู่กึ่งกลาง Die และมีขนาดประมาณ

```text
870 µm × 870 µm
```

#### South Side

ควรพบ

- Clock Pad
- Reset Pad
- Bidirectional Pads 8 ตัว

#### East Side

ควรพบ

- Analog Pads 8 ตัว
- Core VDD Pad
- Core VSS Pad

#### North Side

ควรพบ

- Output Pads 8 ตัว
- I/O VDD Pad
- I/O VSS Pad

#### West Side

ควรพบ Input Pads 10 ตัว

### 25.2 ตรวจสอบ Orientation

I/O Pads แต่ละด้านต้องหันขา Pad ออกสู่ขอบ Die และหัน Core-Side Pins เข้าสู่ Core

หาก Orientation ผิด อาจเกิดปัญหา

- Bond Pad อยู่ด้านใน
- Core Pins หันออกนอก Die
- Routing ยาวผิดปกติ
- Pad Overlap
- Seal Ring Overlap
- DRC Violations จำนวนมาก

---

## 26. ขั้นตอนที่ 22: ตรวจสอบ PDN

ใน OpenROAD GUI เปิดแสดง Metal Layers ที่ใช้สร้าง Power Ring

ตรวจสอบ

1. มี VDD Ring รอบ Core
2. มี VSS Ring รอบ Core
3. Ring มีความกว้างตาม Configuration
4. มีระยะห่างระหว่าง VDD และ VSS
5. มีการเชื่อมจาก Power Pads มายัง Core Ring
6. มีการเชื่อมจาก Core Ring เข้าสู่ Internal PDN Grid
7. Standard Cell Rails เชื่อมกับ Power Grid
8. ไม่มี Power Net ขาดตอน

ตรวจสอบ Net ใน GUI โดยเลือก

```text
VDD
VSS
```

หาก Tool รองรับ Tcl Console สามารถใช้แนวทางดังนี้

```tcl
selectNet VDD
selectNet VSS
```

ชื่อคำสั่งอาจแตกต่างตามเวอร์ชันของ OpenROAD GUI

---

## 27. ขั้นตอนที่ 23: ตรวจสอบ Placement

บริเวณภายใน Core ควรพบ Standard Cells ของ Counter และ Logic ที่เกี่ยวข้อง

เนื่องจาก

```yaml
PL_TARGET_DENSITY_PCT: 10
```

Standard Cells จะใช้พื้นที่เพียงเล็กน้อยของ Core

ตรวจสอบ

- ไม่มี Standard Cell อยู่นอก Core
- ไม่มี Standard Cell ซ้อนกัน
- Clock Buffer ถูกวางหลัง CTS
- Cells กระจายอยู่ใน Legal Rows
- Placement ไม่ทับ PDN
- Routing Access ยังเพียงพอ

---

## 28. ขั้นตอนที่ 24: ตรวจสอบ Clock Tree

Clock Path เริ่มจาก

```text
clk_PAD
  → clk_pad/p2c
  → Clock Network
  → Counter Flip-Flops
```

ตรวจสอบใน Clock Tree Report ว่า

- Clock ถูกสร้างสำเร็จ
- Clock Root คือ `clk_pad/p2c`
- Sequential Cells ได้รับ Clock ครบ
- ไม่มี Unconstrained Clock Pin
- Clock Buffer ถูก Insert
- Clock Skew อยู่ในค่าที่ยอมรับได้
- Clock Transition ไม่เกิน Constraint

ค้นหา Clock Report

```bash
find "$RUN_DIR" -type f | grep -Ei "clock|cts"
```

ค้นหาค่า Skew

```bash
grep -R -i "skew" "$RUN_DIR" \
    --include="*.rpt" \
    --include="*.log" | head -50
```

---

## 29. ขั้นตอนที่ 25: ตรวจสอบ Timing

ค้นหา Timing Reports

```bash
find "$RUN_DIR" -type f | grep -Ei "timing|sta|setup|hold"
```

ค้นหา Slack

```bash
grep -R -Ei \
    "worst.*slack|setup.*slack|hold.*slack|wns|tns" \
    "$RUN_DIR" \
    --include="*.rpt" \
    --include="*.log" | head -100
```

### 29.1 Setup Timing

Setup Check ตรวจสอบว่าข้อมูลมาถึง Flip-Flop ก่อนขอบ Clock ถัดไปตามเวลาที่กำหนด

เกณฑ์ทั่วไป

```text
Setup Slack ≥ 0
```

### 29.2 Hold Timing

Hold Check ตรวจสอบว่าข้อมูลไม่เปลี่ยนเร็วเกินไปหลังขอบ Clock

เกณฑ์ทั่วไป

```text
Hold Slack ≥ 0
```

### 29.3 I/O Timing

ตรวจสอบ Path เช่น

```text
input_PAD
  → Input Pad Cell
  → Core Logic
  → Counter Register
```

และ

```text
Counter Register
  → Core Logic
  → Output Pad Cell
  → output_PAD
```

ควรตรวจสอบว่า Input และ Output Paths ถูก Constrain ครบ ไม่ปรากฏเป็น Unconstrained Paths

---

## 30. ขั้นตอนที่ 26: ตรวจสอบ Routing

ใน OpenROAD GUI เปิดแสดง Routing Layers ทีละ Layer

ตรวจสอบ

- Signal Nets เชื่อมครบ
- Clock Routing เชื่อมครบ
- Pad-to-Core Routing ไม่มีเส้นขาด
- ไม่มีเส้นออกนอก Die
- ไม่มี Routing ผ่าน Macro Obstruction อย่างผิดกฎ
- Power Routing ไม่ถูกใช้เป็น Signal Routing
- Analog Pads ไม่ถูกเชื่อมผิดกับ Digital Nets
- ไม่มี Unrouted Nets

ค้นหา Routing Reports

```bash
find "$RUN_DIR" -type f | grep -Ei "route|routing|droute|grt"
```

ค้นหา Unrouted Nets

```bash
grep -R -Ei \
    "unrouted|not routed|failed net" \
    "$RUN_DIR" \
    --include="*.rpt" \
    --include="*.log" | head -100
```

---

## 31. ขั้นตอนที่ 27: ตรวจสอบ Antenna

Antenna Effect เกิดจากโลหะที่เชื่อมกับ Gate ระหว่างกระบวนการผลิตสะสมประจุจนทำให้ Gate Oxide เสียหาย

Flow อาจแก้ด้วย

- Antenna Diode
- Jumper
- Layer Hopping
- Routing Modification

ค้นหา Antenna Reports

```bash
find "$RUN_DIR" -type f | grep -Ei "antenna"
```

ค้นหาผลลัพธ์

```bash
grep -R -Ei \
    "antenna.*pass|antenna.*violation|violations" \
    "$RUN_DIR" \
    --include="*.rpt" \
    --include="*.log" | head -100
```

ผลที่คาดหวังตามโจทย์ของ Lab คือ Antenna Check ผ่าน

---

## 32. ขั้นตอนที่ 28: ตรวจสอบ LVS

LVS หรือ Layout Versus Schematic เปรียบเทียบ

```text
Layout-Extracted Netlist
          กับ
Schematic/Source Netlist
```

LVS ตรวจสอบ

- จำนวน Devices
- จำนวน Nets
- Connectivity
- Pin Mapping
- Hierarchy
- Power/Ground Connectivity

ค้นหา LVS Report

```bash
find "$RUN_DIR" -type f | grep -Ei "lvs|netgen"
```

ค้นหาข้อความสำคัญ

```bash
grep -R -Ei \
    "netlists match|circuits match|lvs.*pass|lvs.*fail|mismatch" \
    "$RUN_DIR" \
    --include="*.rpt" \
    --include="*.log" | head -100
```

ผลที่คาดหวังคือ

```text
LVS Passed
```

หรือข้อความที่มีความหมายว่า Netlists Match

### 32.1 ตัวแปร `MAGIC_EXT_UNIQUE`

```yaml
MAGIC_EXT_UNIQUE: notopports
```

ใช้ปรับพฤติกรรม Extraction ในกรณีที่มี Power Pads หลายตัวเชื่อมกับ Power Domain เดียวกัน เพื่อหลีกเลี่ยงปัญหาการตั้งชื่อ Top-Level Ports ซ้ำระหว่าง Extraction

---

## 33. ขั้นตอนที่ 29: เปิด Final Layout ใน KLayout

เรียก

```bash
librelane \
    --pdk ihp-sg13g2 \
    config.yaml \
    --last-run \
    --flow OpenInKLayout
```

### 33.1 สิ่งที่ต้องตรวจสอบ

#### Pad Ring

- Pads เรียงครบทั้งสี่ด้าน
- ไม่มี Pad ซ้อนกัน
- Pad Orientation ถูกต้อง
- ช่องว่างระหว่าง Pads ถูกเติมอย่างเหมาะสม

#### Bond Pads

- Bond Pad อยู่ด้านนอกของ I/O Pad
- Bond Pad มีขนาดประมาณ 70 × 70 µm ตามชื่อ Macro
- Bond Pad ไม่ทับ Seal Ring
- Bond Pad ไม่ยื่นออกนอก Die

#### Core

- Standard Cells อยู่ใน Core Boundary
- Routing อยู่ภายในขอบเขตที่กำหนด
- Core Ring ล้อมรอบ Core

#### Seal Ring

- Seal Ring ต่อเนื่องรอบขอบ Die
- ไม่มีช่องว่าง
- ไม่ทับ Bond Pads หรือ Active Circuit
- อยู่ภายในระยะที่ PDK กำหนด

#### Final GDS

- ไม่มี Cell Reference ที่หายไป
- Bond Pad GDS ถูก Merge แล้ว
- Layer Map ถูกต้อง
- Top Cell คือ `chip_top`

---

## 34. ขั้นตอนที่ 30: ค้นหา Final GDSII

```bash
find "$RUN_DIR" -type f -name "*.gds" | sort
```

ค้นหาไฟล์ที่มีชื่อ Top-Level

```bash
find "$RUN_DIR" -type f \
    \( -name "chip_top.gds" \
    -o -name "*final*.gds" \
    -o -name "*streamout*.gds" \)
```

ตรวจสอบขนาดไฟล์

```bash
ls -lh $(find "$RUN_DIR" -type f -name "*.gds")
```

ไฟล์ GDS ที่มีขนาดเป็นศูนย์หรือเล็กผิดปกติอาจบ่งชี้ว่า Stream-Out ไม่สมบูรณ์

---

## 35. ขั้นตอนที่ 31: ตรวจสอบ Final Netlist และ LEF

### 35.1 Final Verilog Netlist

```bash
find "$RUN_DIR" -type f -name "*.v" | sort
```

ตรวจสอบ Top Module

```bash
grep -R "module chip_top" "$RUN_DIR" \
    --include="*.v" | head
```

### 35.2 Final LEF

```bash
find "$RUN_DIR" -type f -name "*.lef" | sort
```

Final LEF มีประโยชน์หากต้องนำชิปหรือ Block นี้ไปใช้ใน Hierarchical Flow ระดับสูงกว่า

---

## 36. ขั้นตอนที่ 32: สร้าง Checklist ผลการทดลอง

ให้ผู้เรียนบันทึกผลในตารางต่อไปนี้

| รายการตรวจสอบ | ผลลัพธ์ | หมายเหตุ |
|---|---|---|
| LibreLane เริ่ม Chip Flow ได้ | Pass/Fail | |
| Top Module คือ `chip_top` | Pass/Fail | |
| Synthesis สำเร็จ | Pass/Fail | |
| Pad Instances ไม่ถูกลบ | Pass/Fail | |
| Pad Ring ถูกสร้างครบ 4 ด้าน | Pass/Fail | |
| Pads ด้านละ 10 ตัว | Pass/Fail | |
| Bond Pads ปรากฏใน Final GDS | Pass/Fail | |
| Core Area อยู่กึ่งกลาง Die | Pass/Fail | |
| Core Power Ring ถูกสร้าง | Pass/Fail | |
| VDD/VSS เชื่อมถึง Pads | Pass/Fail | |
| Clock Root คือ `clk_pad/p2c` | Pass/Fail | |
| CTS สำเร็จ | Pass/Fail | |
| Routing สำเร็จ | Pass/Fail | |
| ไม่มี Unrouted Nets | Pass/Fail | |
| Setup Timing ผ่าน | Pass/Fail | |
| Hold Timing ผ่าน | Pass/Fail | |
| Antenna ผ่าน | Pass/Fail | |
| LVS ผ่าน | Pass/Fail | |
| Final GDS ถูกสร้าง | Pass/Fail | |
| DRC ถูกเปิดและผ่าน | Pass/Fail/Not Run | |

---

## 37. การแปลผลลัพธ์อย่างถูกต้อง

README ของตัวอย่างระบุว่าควรเห็น Antenna และ LVS ผ่าน ขณะที่ DRC ถูกข้ามไว้

ดังนั้นผลสรุปที่ถูกต้องสำหรับ Lab คือ

```text
RTL-to-GDSII Flow     : Completed
Pad Ring              : Generated
Bond Pads             : Included
Antenna Check         : Expected to Pass
LVS                    : Expected to Pass
KLayout DRC            : Disabled
Magic DRC              : Disabled
Tapeout Signoff Status : Not yet complete
```

ไม่ควรสรุปว่า “พร้อม Tapeout” เพียงเพราะได้ไฟล์ GDSII

การพร้อม Tapeout จริงควรมีอย่างน้อย

- DRC Clean
- LVS Clean
- Antenna Clean
- Timing Signoff ผ่านทุก Corner
- Power Integrity ผ่าน
- IR Drop ผ่าน
- Electromigration ผ่าน
- Density ผ่าน
- ERC ผ่าน
- Pad Connectivity ผ่าน
- Seal Ring Verification ผ่าน
- Foundry Deck Version ถูกต้อง
- GDS Layer Mapping ถูกต้อง
- Waiver ได้รับอนุมัติอย่างเป็นทางการ

---

## 38. การเปิด DRC สำหรับการศึกษาต่อ

ใน `config.yaml` มีการปิด DRC ดังนี้

```yaml
KLayout.DRC: null
Checker.KLayoutDRC: null
Magic.DRC: null
Checker.MagicDRC: null
```

หากต้องการทดลองเปิด DRC ให้ Comment หรือเอารายการดังกล่าวออก เช่น

```yaml
substituting_steps:
  Checker.IllegalOverlap: null

  # KLayout.DRC: null
  # Checker.KLayoutDRC: null

  # Magic.DRC: null
  # Checker.MagicDRC: null
```

จากนั้นรันใหม่

```bash
librelane --pdk ihp-sg13g2 config.yaml
```

ควรเตรียมรับ DRC Violations ที่อาจเกิดจาก

- Bond Pad Geometry
- Pad Overlaps
- Seal Ring Spacing
- Wide Metal Rules
- Density
- Pad-to-Ring Connections
- Metal Slotting
- Minimum Enclosure
- Minimum Spacing
- Layer Mapping
- Full-Chip Specific Rules

การเปิด DRC มีเป้าหมายเพื่อการเรียนรู้และวิเคราะห์ ไม่ควรคาดหวังว่าตัวอย่างจะ Clean โดยไม่แก้ไขเพิ่มเติม

---

## 39. Troubleshooting

### 39.1 ไม่พบ PDK

อาการ

```text
PDK ihp-sg13g2 not found
```

แนวทางแก้ไข

```bash
exit
cd heichips26-digital-workshop
nix-shell
cd bonus
librelane --pdk ihp-sg13g2 config.yaml
```

ตรวจสอบว่าชื่อ PDK ใช้รูปแบบเดียวกับ Environment ปัจจุบัน

---

### 39.2 ไม่พบ Pad Instance

อาการ

```text
Pad instance not found
Unknown pad instance
```

สาเหตุที่เป็นไปได้

- ชื่อใน `PAD_NORTH` หรือด้านอื่นไม่ตรงกับ RTL
- ลืม Escape `[` และ `]`
- Generate Block Name เปลี่ยน
- Instance ถูก Synthesis Optimize ออก
- ชื่อ Instance หลัง Flatten เปลี่ยน

ตรวจสอบชื่อใน RTL

```bash
grep -n "begin : inputs"  src/chip_top.sv
grep -n "begin : outputs" src/chip_top.sv
grep -n "begin : bidirs"  src/chip_top.sv
grep -n "begin : analogs" src/chip_top.sv
```

---

### 39.3 ไม่พบ Clock Net

อาการ

```text
clk_pad/p2c not found
Clock pin not found
```

ตรวจสอบ

```bash
grep -n "sg13g2_IOPadIn clk_pad" src/chip_top.sv
grep -n "\.p2c *(clk_PAD2CORE)" src/chip_top.sv
grep -n "CLOCK_NET" config.yaml
```

ค่าที่ต้องสอดคล้องกันคือ

```yaml
CLOCK_NET: clk_pad/p2c
```

---

### 39.4 Bond Pad LEF ไม่พบ

อาการ

```text
Cannot open LEF
Macro bondpad_70x70_novias not found
```

ตรวจสอบ

```bash
ls -l ip/bondpad_70x70_novias/lef/
grep "^MACRO" \
  ip/bondpad_70x70_novias/lef/bondpad_70x70_novias.lef
```

ตรวจสอบ Path ใน YAML

```yaml
EXTRA_LEFS:
  - dir::ip/bondpad_70x70_novias/lef/bondpad_70x70_novias.lef
```

---

### 39.5 Final GDS ไม่มี Bond Pad

ตรวจสอบว่า

```yaml
EXTRA_GDS:
  - dir::ip/bondpad_70x70_novias/gds/bondpad_70x70_novias.gds
```

ถูกกำหนดไว้ และชื่อ Cell ใน GDS ตรงกับ

```yaml
PAD_BONDPAD_NAME: bondpad_70x70_novias
```

เปิด GDS ต้นฉบับแยกใน KLayout เพื่อตรวจสอบว่าไฟล์ไม่เสียหาย

```bash
klayout \
  ip/bondpad_70x70_novias/gds/bondpad_70x70_novias.gds
```

---

### 39.6 LVS Mismatch ที่ Power Nets

สาเหตุที่เป็นไปได้

- Power Pads หลายตัวเชื่อม Net เดียวกัน
- Extraction ตั้งชื่อ Top Ports ไม่ตรงกัน
- `VDD_NETS` หรือ `GND_NETS` ไม่ตรงกับ RTL
- Explicit Power Pins ไม่ถูกเปิดในบางขั้นตอน
- Pad Cell Model ไม่ตรงกับ Layout

ตรวจสอบ Configuration

```yaml
VDD_NETS:
  - VDD

GND_NETS:
  - VSS

MAGIC_EXT_UNIQUE: notopports
```

---

### 39.7 Routing Congestion

แม้ตั้งค่า

```yaml
GRT_ALLOW_CONGESTION: true
```

แต่ Detailed Routing อาจยังล้มเหลวได้

แนวทางแก้ไข

- เพิ่ม Core Area
- ลด Placement Density
- เปลี่ยน Pad Ordering
- กระจาย Pad ที่มี Connection หนาแน่น
- เพิ่ม Routing Layers ที่อนุญาต
- ลดขนาดหรือความซับซ้อนของ Core
- ตรวจสอบ PDN Obstruction
- ลดความกว้างของ PDN หากกฎอนุญาต

---

### 39.8 Clock Routing ผิดปกติ

ตรวจสอบว่า

```yaml
CLOCK_PORT: clk_PAD
CLOCK_NET: clk_pad/p2c
```

ไม่ควรกำหนด Clock Net เป็น `clk_PAD` หากต้องการให้ CTS เริ่มจาก Core-Side Pin ของ Input Pad

---

### 39.9 Output Width ไม่ตรง

ใน `chip_core`

```systemverilog
logic [NUM_BIDIR_PADS-1:0] count;
assign output_out = count;
```

หากเปลี่ยน `NUM_OUTPUT_PADS` ให้ไม่เท่ากับ `NUM_BIDIR_PADS` อาจเกิด Width Warning หรือ Truncation/Extension

แนวทางแก้ไขคือกำหนด Width ให้ชัดเจน เช่น

```systemverilog
localparam COUNT_WIDTH =
    (NUM_OUTPUT_PADS > NUM_BIDIR_PADS)
    ? NUM_OUTPUT_PADS
    : NUM_BIDIR_PADS;

logic [COUNT_WIDTH-1:0] count;

assign output_out = count[NUM_OUTPUT_PADS-1:0];
assign bidir_out  = count[NUM_BIDIR_PADS-1:0];
```

---

## 40. แบบฝึกหัดเพิ่มเติม

### แบบฝึกหัดที่ 1: เปลี่ยนเงื่อนไข Enable ของ Counter

แก้ไขจาก

```systemverilog
if (&input_in)
```

เป็นใช้เฉพาะ `input_in[0]`

```systemverilog
if (input_in[0])
```

จากนั้นรัน Flow ใหม่และเปรียบเทียบ

- Cell Count
- Area
- Timing
- Routing

---

### แบบฝึกหัดที่ 2: เปลี่ยน Clock Period

เปลี่ยนจาก

```yaml
CLOCK_PERIOD: 20
```

เป็น

```yaml
CLOCK_PERIOD: 10
```

Target Frequency ใหม่คือ

```text
100 MHz
```

เปรียบเทียบ

- Setup Slack
- Buffer Count
- Clock Tree
- Cell Area
- Routing

---

### แบบฝึกหัดที่ 3: เพิ่มจำนวน Input Pads

แก้ใน `chip_top.sv`

```systemverilog
parameter NUM_INPUT_PADS = 12;
```

จากนั้นต้องเพิ่ม Pad Instances ใน `PAD_WEST` หรือกระจายไปด้านอื่น

ตัวอย่าง

```yaml
"inputs\\[11\\].input_pad",
"inputs\\[10\\].input_pad"
```

ผู้เรียนต้องพิจารณาว่าด้านเดิมมีพื้นที่พอหรือไม่

---

### แบบฝึกหัดที่ 4: เปลี่ยน Bidirectional Pad ให้ควบคุมทิศทางได้

แทนที่จะกำหนด

```systemverilog
assign bidir_oe = '1;
```

ให้นำบางบิตของ `input_in` มาใช้เป็น Output Enable เช่น

```systemverilog
assign bidir_oe = {
    NUM_BIDIR_PADS{input_in[0]}
};
```

ศึกษาผลต่อ

- Logic Area
- Timing Path
- Bidirectional Pad Behavior
- SDC Constraints

---

### แบบฝึกหัดที่ 5: เปิด DRC

เปิด KLayout DRC และ Magic DRC แล้วจัดกลุ่ม Violation ตามประเภท

| ประเภท Violation | จำนวน | ตำแหน่ง | แนวทางแก้ไข |
|---|---:|---|---|
| Minimum Spacing | | | |
| Minimum Width | | | |
| Overlap | | | |
| Enclosure | | | |
| Seal Ring | | | |
| Density | | | |
| Wide Metal | | | |

---

### แบบฝึกหัดที่ 6: ออกแบบ Pad Map ใหม่

จัด Pad ใหม่โดยยึดหลัก

- Clock อยู่ใกล้ Ground Pad
- High-Speed Inputs อยู่ใกล้ Clock
- Output Pads กระจายให้สมดุล
- Power Pads กระจายรอบ Die
- Analog Pads แยกจาก Noisy Digital Outputs
- ลดเส้น Routing ที่ต้องข้ามกลาง Core

วาด Pad Map และปรับ `config.yaml`

---

## 41. คำถามท้ายบท

1. เหตุใด Standard Cell Input ไม่ควรเชื่อมต่อกับ Package Pin โดยตรง
2. `p2c` และ `c2p` แตกต่างกันอย่างไร
3. เหตุใด Clock จึงถูกสร้างบน `clk_pad/p2c`
4. Power `VDD` และ `IOVDD` มีหน้าที่ต่างกันอย่างไร
5. เพราะเหตุใด Power Pads จึงใช้ `(* keep *)`
6. LEF และ GDS ของ Bond Pad มีหน้าที่ต่างกันอย่างไร
7. เหตุใด Pad Order ต้องอ้างอิง Hierarchical Instance Name
8. เพราะเหตุใดเครื่องหมาย `[` และ `]` จึงต้อง Escape ใน YAML
9. Core Ring มีหน้าที่อย่างไร
10. เหตุใด `PDN_ENABLE_PINS` จึงปิดใน Full-Chip Flow
11. Seal Ring มีหน้าที่อะไร
12. Antenna Check แตกต่างจาก DRC อย่างไร
13. LVS ตรวจสอบสิ่งใด
14. เหตุใด LVS ผ่านจึงยังไม่เพียงพอสำหรับ Tapeout
15. การปิด KLayout DRC และ Magic DRC มีผลต่อ Signoff อย่างไร
16. หากเพิ่มจำนวน Pads ต้องแก้ไขไฟล์ใดบ้าง
17. หากเปลี่ยน Generate Block Name จะมีผลต่อ `config.yaml` อย่างไร
18. เหตุใด Analog Pads ควรแยกจาก Digital Output Pads
19. Pad Placement มีผลต่อ Routing Congestion อย่างไร
20. ค่า Clock Period 20 ns สอดคล้องกับความถี่เท่าใด

---

## 42. สรุปบทปฏิบัติการ

บทปฏิบัติการนี้แสดงกระบวนการเปลี่ยนวงจรดิจิทัลระดับ Core ให้เป็น Full-Chip Design โดยใช้ LibreLane Chip Flow และ IHP SG13G2 PDK

องค์ประกอบสำคัญที่เพิ่มเข้ามาคือ

- I/O Pad Cells
- Power/Ground Pads
- Pad Ring
- Bond Pads
- Core Power Ring
- Seal Ring
- Full-Chip Timing Constraints
- Final GDSII Stream-Out

ผู้เรียนได้ศึกษาความสัมพันธ์ระหว่างไฟล์สำคัญดังนี้

```text
chip_core.sv
    │
    │ Digital function
    ▼
chip_top.sv
    │
    │ I/O pad integration
    ▼
config.yaml
    │
    │ Pad order, floorplan, PDN, flow
    ▼
chip_top.sdc
    │
    │ Clock and I/O timing constraints
    ▼
LibreLane Chip Flow
    │
    ▼
Full-Chip GDSII
```

คำสั่งหลักสำหรับรัน Flow คือ

```bash
librelane --pdk ihp-sg13g2 config.yaml
```

คำสั่งเปิดผลลัพธ์ใน OpenROAD คือ

```bash
librelane \
    --pdk ihp-sg13g2 \
    config.yaml \
    --last-run \
    --flow OpenInOpenROAD
```

คำสั่งเปิดผลลัพธ์ใน KLayout คือ

```bash
librelane \
    --pdk ihp-sg13g2 \
    config.yaml \
    --last-run \
    --flow OpenInKLayout
```

ผลลัพธ์ที่คาดหวังคือ

- Pad Ring ถูกสร้างครบ
- Core อยู่กึ่งกลาง Die
- Bond Pads ถูกเพิ่มเข้าใน Layout
- Core Ring เชื่อมกับ Power Pads
- Clock Tree และ Routing สำเร็จ
- Antenna Check ผ่าน
- LVS ผ่าน
- Final GDSII ถูกสร้าง

อย่างไรก็ตาม เนื่องจาก Configuration ปิด KLayout DRC และ Magic DRC ไว้ ผลลัพธ์จึงควรถูกมองว่าเป็น Full-Chip Implementation สำหรับการเรียนรู้ ไม่ใช่ Tapeout Signoff ที่สมบูรณ์ จนกว่าจะเปิด Physical Verification ทุกขั้นตอนและแก้ Violation ทั้งหมดเรียบร้อย
:::

รายละเอียดในคู่มือนี้อ้างอิงโครงสร้างจริงของ `chip_top.sv`, `chip_core.sv`, `chip_top.sdc` และ `config.yaml` โดย Repository กำหนด `flow: Chip`, Clock 20 ns, Die 1600 × 1600 µm, Core 870 × 870 µm, Pad 40 ตัว และ External Bond-Pad LEF/GDS ตามที่อธิบายข้างต้น 