
# Lab 7  
# Placement Optimization ด้วย LibreLane

## 7.1 วัตถุประสงค์ของบทปฏิบัติการ

Placement คือกระบวนการกำหนดตำแหน่งทางกายภาพของ Standard Cell ภายใน Core Area หลังจากการสังเคราะห์วงจรและการสร้าง Floorplan แล้ว เป้าหมายไม่ได้มีเพียงการวางเซลล์ให้ครบ แต่ต้องทำให้ตำแหน่งของเซลล์เหมาะสมกับข้อกำหนดหลายด้านพร้อมกัน ได้แก่

- ความยาวสายสัญญาณโดยประมาณ
- Timing
- Routing congestion
- ความหนาแน่นของเซลล์
- ความถูกต้องตาม Placement Site และ Row
- พื้นที่ว่างสำหรับ Buffer, Clock Tree และ Routing
- ความสามารถในการผ่าน Detailed Routing และ DRC ในขั้นตอนถัดไป

LibreLane แบ่ง Placement ที่สำคัญออกเป็นสองขั้นตอนหลักคือ

1. **Global Placement**  
   กระจายเซลล์ทั่ว Core Area โดยยอมให้เซลล์ยังวางซ้อนกันได้บางส่วน เพื่อหาตำแหน่งโดยรวมที่เหมาะสม

2. **Detailed Placement**  
   ปรับตำแหน่งเซลล์ให้ถูกต้องตาม Placement Row และ Site รวมถึงกำจัดการวางซ้อนกันและทำให้ตำแหน่งถูกกฎหมาย

Global Placement ของ OpenROAD ใช้อัลกอริทึมจาก RePlAce ซึ่งเป็นการวางแบบวิเคราะห์และแก้ปัญหาเชิงไม่เป็นเชิงเส้น ส่วน Detailed Placement ทำหน้าที่นำผล Global Placement ไปจัดเซลล์ลงตำแหน่งที่ถูกกฎหมายจริง 

---

## 7.2 ผลลัพธ์การเรียนรู้

เมื่อจบ Lab นี้ ผู้เรียนจะสามารถ

1. อธิบายความแตกต่างระหว่าง Global Placement และ Detailed Placement
2. กำหนด Placement Configuration ด้วย `config.yaml`
3. วิเคราะห์ความสัมพันธ์ระหว่าง Core Utilization และ Placement Density
4. เปิดใช้ Timing-driven Placement และ Routability-driven Placement
5. ตรวจสอบ Cell Overlap, Placement Legality และ Congestion
6. วิเคราะห์ HPWL, Density, Overflow และ Timing หลัง Placement
7. เปรียบเทียบ Placement หลาย Configuration
8. ปรับ Placement Density และ Cell Padding อย่างมีหลักการ
9. ระบุสาเหตุของ Placement Failure
10. เลือก Configuration ที่เหมาะสมก่อนเข้าสู่ Clock Tree Synthesis

---

# 7.3 ภาพรวม Placement Flow

Placement Flow โดยย่อมีลำดับดังนี้

```text
Synthesized Netlist
        |
        v
Floorplan
        |
        v
Tap Cell / Endcap Insertion
        |
        v
PDN Generation
        |
        v
I/O Placement
        |
        v
Global Placement
        |
        v
Timing / Routability Optimization
        |
        v
Detailed Placement
        |
        v
Placement Legality Check
        |
        v
Post-Placement STA
        |
        v
Clock Tree Synthesis
```

ใน LibreLane แต่ละขั้นตอนของ Flow เป็นหน่วยที่เรียกว่า Step และแต่ละ Step รับ State จากขั้นตอนก่อนหน้า LibreLane รองรับการกำหนด Flow ด้วย Configuration และค่าใน Configuration จะถูกตรวจสอบชนิดและความถูกต้องก่อนเริ่มทำงาน 

---

# 7.4 Global Placement

## 7.4.1 หน้าที่ของ Global Placement

Global Placement พยายามกำหนดตำแหน่งโดยประมาณให้ Standard Cell ทุกตัว โดยพิจารณา objective หลัก เช่น

$$Cost = \alpha W + \beta D + \gamma T + \delta C$$

เมื่อ

- $$W$$ คือ Wirelength Cost
- $$D$$ คือ Density Penalty
- $$T$$ คือ Timing Cost
- $$C$$ คือ Congestion หรือ Routability Cost
- $$\alpha,\beta,\gamma,\delta$$ คือน้ำหนักของแต่ละ objective

Global Placement ยังไม่บังคับให้ทุกเซลล์อยู่ตรงกับ Placement Site อย่างสมบูรณ์ และอาจมีการซ้อนทับของเซลล์ระหว่างกระบวนการ Optimization

อัลกอริทึม Global Placement ของ OpenROAD ใช้แนวคิด Electrostatic Force โดยมองเซลล์เสมือนประจุไฟฟ้าที่ผลักกันเพื่อควบคุม Density พร้อมกับแรงดึงจาก Net Connectivity เพื่อลด Wirelength 

---

## 7.4.2 Half-Perimeter Wirelength

Metric ที่นิยมใช้ประเมิน Placement เบื้องต้นคือ Half-Perimeter Wirelength หรือ HPWL

สำหรับ Net ที่มีตำแหน่ง Pin หลายจุด

$$HPWL = (x_{\max}-x_{\min})+(y_{\max}-y_{\min})$$

ค่า HPWL ที่ต่ำมักหมายถึงระยะเชื่อมต่อโดยรวมสั้นลง แต่ไม่ได้รับประกันว่า Routing จะไม่มี Congestion เพราะ Net จำนวนมากอาจถูกรวมอยู่ในบริเวณเดียวกัน

ดังนั้นการเลือก Placement ที่ดีที่สุดไม่ควรพิจารณา HPWL เพียงค่าเดียว แต่ต้องดูร่วมกับ

- Routing congestion
- Timing slack
- Cell density
- Buffer count
- Max slew
- Max capacitance
- Placement legality

---

# 7.5 Detailed Placement

Detailed Placement รับผลจาก Global Placement แล้วดำเนินการดังนี้

1. ย้ายเซลล์ลง Placement Row
2. จัดตำแหน่งให้ตรงกับ Placement Site
3. กำจัด Cell Overlap
4. รักษาลำดับเซลล์ให้ใกล้เคียงผล Global Placement
5. จำกัดระยะการเคลื่อนที่ของเซลล์
6. ปรับ Cell Orientation
7. ตรวจสอบ Placement Legality

คำสั่ง `detailed_placement` ของ OpenROAD ทำหน้าที่จัด Instance ลงตำแหน่งที่ถูกกฎหมายหลัง Global Placement และรองรับการจำกัด Maximum Displacement ของเซลล์ 

---

# 7.6 โครงสร้าง Project

สร้างโครงสร้างโฟลเดอร์ดังนี้

```text
lab7_placement/
├── config.yaml
├── src/
│   └── placement_top.sv
├── constraints/
│   └── placement.sdc
├── scripts/
│   ├── run_baseline.sh
│   ├── run_low_density.sh
│   ├── run_balanced.sh
│   └── run_high_density.sh
├── reports/
└── README.md
```

สร้าง Project

```bash
mkdir -p lab7_placement/{src,constraints,scripts,reports}
cd lab7_placement
```

ตรวจสอบ LibreLane

```bash
librelane --version
```

LibreLane ใช้ `Classic` เป็น Default Flow จาก Command Line และสามารถรับ YAML Configuration เป็น Input ได้โดยตรง 

---

# 7.7 RTL Design สำหรับทดลอง Placement

เพื่อให้เห็นผลของ Placement ชัดเจนกว่าวงจร Counter ขนาดเล็ก Lab นี้ใช้วงจร Datapath ที่ประกอบด้วย Register, Adder, XOR และ Multiplexer หลายชุด

สร้างไฟล์ `src/placement_top.sv`

```systemverilog
module placement_top #(
    parameter int WIDTH = 32
) (
    input  logic                 clk_i,
    input  logic                 rst_ni,
    input  logic                 enable_i,
    input  logic [WIDTH-1:0]     data_a_i,
    input  logic [WIDTH-1:0]     data_b_i,
    input  logic [WIDTH-1:0]     data_c_i,
    input  logic [WIDTH-1:0]     data_d_i,
    output logic [WIDTH-1:0]     result_o
);

    logic [WIDTH-1:0] stage0_q;
    logic [WIDTH-1:0] stage1_q;
    logic [WIDTH-1:0] stage2_q;
    logic [WIDTH-1:0] stage3_q;

    logic [WIDTH-1:0] add0_w;
    logic [WIDTH-1:0] add1_w;
    logic [WIDTH-1:0] xor0_w;
    logic [WIDTH-1:0] mix0_w;

    assign add0_w = data_a_i + data_b_i;
    assign add1_w = data_c_i + data_d_i;
    assign xor0_w = stage0_q ^ stage1_q;

    assign mix0_w = stage2_q[0]
                  ? (xor0_w + stage2_q)
                  : (xor0_w ^ stage2_q);

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            stage0_q <= '0;
            stage1_q <= '0;
            stage2_q <= '0;
            stage3_q <= '0;
        end else if (enable_i) begin
            stage0_q <= add0_w;
            stage1_q <= add1_w;
            stage2_q <= stage0_q + stage1_q;
            stage3_q <= mix0_w;
        end
    end

    assign result_o = stage3_q;

endmodule
```

ตรวจสอบ Syntax เบื้องต้นด้วย Verilator

```bash
verilator --lint-only \
  --Wall \
  --Wno-fatal \
  src/placement_top.sv
```

ผลที่คาดหวังคือไม่มี Syntax Error หรือ Unsupported Construct

---

# 7.8 Timing Constraint

สร้างไฟล์ `constraints/placement.sdc`

```tcl
# ============================================================
# Primary clock
# 10 ns period = 100 MHz
# ============================================================

create_clock \
    -name core_clk \
    -period 10.000 \
    [get_ports clk_i]

# ============================================================
# Clock margin
# ============================================================

set_clock_uncertainty 0.25 [get_clocks core_clk]
set_clock_transition  0.15 [get_clocks core_clk]

# ============================================================
# Input constraints
# ============================================================

set non_clock_inputs [remove_from_collection \
    [all_inputs] \
    [get_ports clk_i]]

set_input_delay 2.0 \
    -clock core_clk \
    $non_clock_inputs

# ============================================================
# Output constraints
# ============================================================

set_output_delay 4.0 \
    -clock core_clk \
    [all_outputs]

set_load 0.033442 [all_outputs]

# ============================================================
# Reset is not a timed data input
# ============================================================

set_false_path -from [get_ports rst_ni]
```

ข้อควรระวัง:

- ชื่อ Clock Port ใน SDC ต้องตรงกับ RTL
- `CLOCK_PERIOD` ใน `config.yaml` ควรตรงกับ `create_clock`
- ไม่ควรใช้ Base SDC โดยไม่ตรวจสอบ Input/Output Delay
- Reset แบบ Asynchronous มักกำหนดเป็น False Path สำหรับการวิเคราะห์ Functional Data Path
- Constraint ที่ใช้จริงต้องสอดคล้องกับ Interface Specification ของระบบ

---

# 7.9 Baseline config.yaml

สร้างไฟล์ `config.yaml`

```yaml
meta:
  version: 2
  flow: Classic

# ============================================================
# Design
# ============================================================

DESIGN_NAME: placement_top

VERILOG_FILES:
  - dir::src/placement_top.sv

# ============================================================
# PDK
# ============================================================

PDK: sky130A
STD_CELL_LIBRARY: sky130_fd_sc_hd

# ============================================================
# Clock
# ============================================================

CLOCK_PORT: clk_i
CLOCK_NET: clk_i
CLOCK_PERIOD: 10.0

# ============================================================
# Timing constraints
# ============================================================

PNR_SDC_FILE: dir::constraints/placement.sdc
SIGNOFF_SDC_FILE: dir::constraints/placement.sdc

# ============================================================
# Floorplan
# ============================================================

FP_SIZING: relative
FP_CORE_UTIL: 45
FP_ASPECT_RATIO: 1.0
FP_CORE_MARGIN: 5

# ============================================================
# I/O placement
# ============================================================

FP_IO_MODE: 0
FP_IO_MIN_DISTANCE: 3

# ============================================================
# Placement
# ============================================================

PL_TARGET_DENSITY_PCT: 60

PL_TIMING_DRIVEN: true
PL_ROUTABILITY_DRIVEN: true

PL_SKIP_INITIAL_PLACEMENT: false
PL_WIRE_LENGTH_COEF: 0.25

PL_OPTIMIZE_MIRRORING: true
PL_MAX_DISPLACEMENT_X: 500
PL_MAX_DISPLACEMENT_Y: 100

# ============================================================
# Routing preparation
# ============================================================

GRT_ADJUSTMENT: 0.30

# ============================================================
# Reports and checks
# ============================================================

ERROR_ON_SYNTH_CHECKS: true
ERROR_ON_UNMAPPED_CELLS: true
ERROR_ON_DISCONNECTED_PINS: true
```

LibreLane รองรับการระบุ `DESIGN_NAME`, `CLOCK_PORT`, `CLOCK_PERIOD` และ `PDK` เป็น Universal Configuration Variable โดย `DESIGN_NAME` ต้องตรงกับชื่อ Top-level Module 

---

# 7.10 ความหมายของ Placement Variables

## 7.10.1 FP_CORE_UTIL

```yaml
FP_CORE_UTIL: 45
```

กำหนดเปอร์เซ็นต์พื้นที่ Core ที่คาดว่าจะถูกใช้โดย Standard Cell หลัง Synthesis

นิยามโดยประมาณคือ

$$Core\ Utilization = \frac{Total\ Standard\ Cell\ Area} {Available\ Core\ Area} \times 100$$

ตัวอย่างเช่น หาก Standard Cell Area เท่ากับ $$4,500\ \mu m^2$$ และต้องการ Utilization 45%

$$Core\ Area = \frac{4500}{0.45} = 10,000\ \mu m^2$$

ค่า Core Utilization ต่ำทำให้

- Core มีขนาดใหญ่ขึ้น
- มีพื้นที่ Routing มากขึ้น
- Congestion ลดลง
- Wirelength อาจเพิ่มขึ้น
- Die Area เพิ่มขึ้น

ค่า Core Utilization สูงทำให้

- Core มีขนาดเล็กลง
- Wirelength อาจลดลง
- Congestion เพิ่มขึ้น
- Detailed Placement ยากขึ้น
- มีพื้นที่สำหรับ CTS Buffer น้อยลง

LibreLane กำหนดค่าเริ่มต้นของ `FP_CORE_UTIL` เป็น 50% ใน Placement-related Step Configuration 

---

## 7.10.2 PL_TARGET_DENSITY_PCT

```yaml
PL_TARGET_DENSITY_PCT: 60
```

กำหนด Target Density ที่ Global Placer พยายามรักษาในแต่ละบริเวณของ Core

ค่า Density ไม่เหมือนกับ Core Utilization โดยตรง

- Core Utilization ใช้กำหนดขนาด Core
- Placement Density ใช้ควบคุมการกระจายตัวของเซลล์ระหว่าง Placement

ใน LibreLane ชื่อปัจจุบันคือ `PL_TARGET_DENSITY_PCT` ส่วน `PL_TARGET_DENSITY` เป็นชื่อเดิมที่เลิกแนะนำให้ใช้ หากไม่กำหนดค่า LibreLane จะคำนวณจาก `FP_CORE_UTIL`, `GPL_CELL_PADDING` และ Margin เพิ่มเติม 

แนวทางเริ่มต้น:

| ลักษณะวงจร | FP_CORE_UTIL | PL_TARGET_DENSITY_PCT |
|---|---:|---:|
| วงจรขนาดเล็ก | 35–45 | 50–60 |
| Datapath ทั่วไป | 40–50 | 55–65 |
| วงจรที่มี Fanout สูง | 35–45 | 50–58 |
| วงจรที่มี Routing มาก | 30–42 | 45–58 |
| Area-focused Design | 50–60 | 65–75 |

ค่าดังกล่าวเป็นจุดเริ่มต้นสำหรับการทดลอง ไม่ใช่ค่ารับประกันผลสำหรับทุก PDK

---

## 7.10.3 PL_TIMING_DRIVEN

```yaml
PL_TIMING_DRIVEN: true
```

เปิด Timing-driven Global Placement

เมื่อเปิดใช้งาน Global Placer จะให้น้ำหนักกับ Critical Net หรือ Critical Path มากขึ้น และพยายามจัดเซลล์ที่เกี่ยวข้องให้ใกล้กันเพื่อลด Estimated Interconnect Delay

LibreLane กำหนดค่าเริ่มต้นของ `PL_TIMING_DRIVEN` เป็น `false` ดังนั้นควรเปิดอย่างชัดเจนเมื่อต้องการให้ Placement คำนึงถึง Timing 

Timing-driven Placement อาจทำให้

- Setup Slack ดีขึ้น
- Critical Net สั้นลง
- Buffer หรือ Resizing เพิ่มขึ้น
- Density บริเวณ Critical Logic สูงขึ้น
- Congestion บางตำแหน่งเพิ่มขึ้น

ดังนั้นควรใช้ร่วมกับ Routability-driven Placement

---

## 7.10.4 PL_ROUTABILITY_DRIVEN

```yaml
PL_ROUTABILITY_DRIVEN: true
```

เปิด Routability-driven Placement เพื่อให้ Global Placer ประเมินบริเวณที่มี Routing Congestion และกระจายเซลล์ออกจากบริเวณที่แน่นเกินไป

LibreLane กำหนดค่าเริ่มต้นของตัวแปรนี้เป็น `true` 

ผลที่อาจเกิดขึ้น:

- Congestion ลดลง
- Routing Overflow ลดลง
- Cell Distribution สม่ำเสมอขึ้น
- Wirelength อาจเพิ่มขึ้นเล็กน้อย
- Runtime เพิ่มขึ้น

ไม่ควรปิด Routability-driven Placement เพียงเพื่อลด Runtime หากยังไม่ได้ตรวจ Congestion Map

---

## 7.10.5 PL_ROUTABILITY_OVERFLOW_THRESHOLD

ตัวอย่าง:

```yaml
PL_ROUTABILITY_OVERFLOW_THRESHOLD: 0.20
```

กำหนด Threshold ที่ใช้ควบคุมการเริ่มหรือหยุด Routability Optimization

ตัวแปรนี้เป็น Optional Variable หากไม่กำหนดจะใช้ค่าที่ OpenROAD เลือกให้ ควรปรับเมื่อมีเหตุผลจาก Log หรือ Congestion Report เท่านั้น 

---

## 7.10.6 PL_WIRE_LENGTH_COEF

```yaml
PL_WIRE_LENGTH_COEF: 0.25
```

เป็น Initial Wirelength Coefficient ของ Global Placement ค่าเริ่มต้นใน LibreLane คือ `0.25` 

แนวทางปรับ:

- ลดค่า: Placer อาจให้ความสำคัญกับ Wirelength มากขึ้นใน Initial Placement
- เพิ่มค่า: อาจช่วยให้ Placement กระจายตัวมากขึ้นในบางกรณี
- ควรปรับทีละน้อย เช่น 0.20, 0.25 และ 0.30
- ไม่ควรปรับพร้อมกับ Density หลายค่าในครั้งเดียว เพราะจะไม่ทราบว่าปัจจัยใดทำให้ผลเปลี่ยน

---

## 7.10.7 GPL_CELL_PADDING

ตัวอย่าง:

```yaml
GPL_CELL_PADDING: 2
```

กำหนดพื้นที่ว่างเสมือนรอบ Standard Cell ระหว่าง Global Placement หน่วยเป็น Placement Site

Padding ช่วยสร้างช่องว่างสำหรับ

- Routing
- Buffer insertion
- Diode insertion
- Clock Tree Buffer
- Detailed Placement movement

LibreLane ระบุว่า `GPL_CELL_PADDING` เป็นค่าในหน่วย Site และแบ่ง Padding ไปทั้งสองด้านของเซลล์ 

ข้อควรระวัง:

- ตัวแปรนี้เป็น PDK-defined Variable
- ค่า Default แตกต่างตาม PDK
- การ Override โดยไม่ตรวจค่าของ PDK อาจทำให้ Placement Density เปลี่ยนมาก
- Padding สูงเกินไปอาจทำให้ Placement ล้มเหลวเพราะพื้นที่ไม่เพียงพอ

สำหรับการเริ่มต้น ควรใช้ค่า Default ของ PDK ก่อน แล้วจึง Override เมื่อพบ Congestion หรือ Antenna Repair Space ไม่เพียงพอ

---

## 7.10.8 DPL_CELL_PADDING

ตัวอย่าง:

```yaml
DPL_CELL_PADDING: 1
```

กำหนด Cell Padding ใน Detailed Placement

LibreLane ระบุว่า `DPL_CELL_PADDING` ควรน้อยกว่าหรือเท่ากับ `GPL_CELL_PADDING` 

ตัวอย่างที่เหมาะสม:

```yaml
GPL_CELL_PADDING: 2
DPL_CELL_PADDING: 1
```

ตัวอย่างที่ไม่แนะนำ:

```yaml
GPL_CELL_PADDING: 1
DPL_CELL_PADDING: 4
```

เพราะ Detailed Placement จะพยายามสร้างช่องว่างมากกว่าที่ Global Placement วางแผนไว้

---

## 7.10.9 PL_MAX_DISPLACEMENT_X และ Y

```yaml
PL_MAX_DISPLACEMENT_X: 500
PL_MAX_DISPLACEMENT_Y: 100
```

กำหนดระยะสูงสุดที่ Detailed Placement สามารถย้ายเซลล์จากตำแหน่ง Global Placement เพื่อหาตำแหน่งที่ถูกกฎหมาย

LibreLane กำหนดค่าเริ่มต้นเป็น

- X = 500 µm
- Y = 100 µm



ค่าที่ต่ำเกินไปอาจทำให้ Detailed Placement ไม่สามารถ Legalize เซลล์ได้ ส่วนค่าที่สูงมากอาจทำให้ตำแหน่งเปลี่ยนจาก Global Placement มากและทำให้ Timing หรือ Wirelength เสื่อมลง

---

## 7.10.10 PL_OPTIMIZE_MIRRORING

```yaml
PL_OPTIMIZE_MIRRORING: true
```

อนุญาตให้ Detailed Placement เปลี่ยน Orientation หรือ Mirror เซลล์เมื่อทำได้ เพื่อปรับปรุง Placement

LibreLane เปิดตัวเลือกนี้เป็นค่าเริ่มต้น 

การ Mirror Standard Cell ต้องยังคงสอดคล้องกับ

- Placement Row Orientation
- Power Rail Alignment
- Cell Symmetry ที่กำหนดใน LEF
- Legal Orientation ของ Standard Cell

---

# 7.11 รัน Baseline Flow

รัน LibreLane

```bash
librelane config.yaml
```

หรือกำหนด Run Tag

```bash
librelane \
  --run-tag lab7_baseline \
  config.yaml
```

ตรวจสอบว่า Configuration ถูกโหลดถูกต้อง

```text
DESIGN_NAME     = placement_top
PDK             = sky130A
CLOCK_PORT      = clk_i
CLOCK_PERIOD    = 10.0
FP_CORE_UTIL    = 45
PL_TARGET_DENSITY_PCT = 60
```

LibreLane จะใช้ Classic Flow ตามที่กำหนดใน `meta.flow` และ YAML สามารถระบุ Flow ได้โดยตรง 

---

# 7.12 ระบุ Placement Step ใน Run Directory

หลังรันเสร็จ ตรวจสอบ Run Directory

```bash
find runs/lab7_baseline -maxdepth 2 -type d | sort
```

ชื่อ Directory อาจแตกต่างตาม LibreLane Version แต่ให้ค้นหาขั้นตอนที่เกี่ยวข้องด้วยคำสั่ง

```bash
find runs/lab7_baseline \
  -type d \
  \( -iname "*GlobalPlacement*" \
     -o -iname "*DetailedPlacement*" \
     -o -iname "*Placement*" \) \
  | sort
```

ค้นหา Placement DEF

```bash
find runs/lab7_baseline \
  -type f \
  -name "*.def" \
  | sort
```

ค้นหา Placement OpenDB

```bash
find runs/lab7_baseline \
  -type f \
  -name "*.odb" \
  | sort
```

ค้นหา Placement Logs

```bash
find runs/lab7_baseline \
  -type f \
  -name "*.log" \
  | grep -Ei "placement|global|detailed"
```

ไม่ควรเขียน Script โดยสมมติหมายเลข Step แบบตายตัว เพราะลำดับ Step อาจเปลี่ยนตาม Flow และ LibreLane Version

---

# 7.13 ตรวจสอบ Global Placement Log

ค้นหาข้อมูลสำคัญ

```bash
grep -RniE \
  "overflow|density|wirelength|HPWL|congestion|timing|slack|iteration" \
  runs/lab7_baseline \
  | head -n 100
```

รายการที่ควรตรวจสอบ:

1. Initial HPWL
2. Final HPWL
3. Density Overflow
4. Number of Placement Iterations
5. Routability Iterations
6. Timing-driven Iterations
7. Estimated Congestion
8. Cell Count
9. Inserted Buffer Count
10. Global Placement Runtime

ตัวอย่างรูปแบบข้อความที่อาจพบ:

```text
Iteration: 120
HPWL: 125430.2
Overflow: 0.182
Objective: 2.531e+06
```

ค่าจริงและข้อความใน Log อาจแตกต่างตาม OpenROAD Version

---

# 7.14 ตรวจสอบ Detailed Placement

ค้นหา Placement Legality

```bash
grep -RniE \
  "legal|overlap|displacement|detailed placement|placement violations" \
  runs/lab7_baseline \
  | head -n 100
```

ผลที่ต้องการ:

```text
Placement is legal
```

หรือไม่มีข้อความ Error เกี่ยวกับ

- Cell overlap
- Cell outside rows
- Illegal orientation
- Off-site placement
- Unplaced instance
- Maximum displacement

Detailed Placement ต้องทำให้ Instance อยู่ในตำแหน่งที่ถูกกฎหมายหลัง Global Placement 

---

# 7.15 เปิด Layout ด้วย OpenROAD GUI

ค้นหา Final ODB

```bash
find runs/lab7_baseline/final \
  -type f \
  -name "*.odb"
```

เปิด GUI โดยใช้ ODB ที่เหมาะสม

```bash
openroad -gui
```

จาก OpenROAD GUI สามารถใช้ Tcl Console

```tcl
read_db /absolute/path/to/placement_top.odb
```

กดปุ่ม Zoom Fit แล้วตรวจสอบ

1. การกระจาย Standard Cell
2. บริเวณที่มีเซลล์หนาแน่นผิดปกติ
3. ช่องว่างรอบขอบ Core
4. ตำแหน่ง I/O Pin
5. Placement Row
6. Power Grid obstruction
7. กลุ่มเซลล์ที่รวมตัวอยู่ใกล้ Pin มากเกินไป
8. พื้นที่ว่างสำหรับ CTS Buffer
9. Macro blockage หากมี Macro
10. บริเวณที่อาจเกิด Routing Hotspot

---

# 7.16 ตรวจสอบ Placement ด้วย KLayout

หากมี DEF และ LEF ครบ สามารถเปิด DEF ด้วย KLayout ผ่าน LibreLane Generated Technology File หรือใช้ GDS หลัง Flow เสร็จ

ตัวอย่าง:

```bash
klayout runs/lab7_baseline/final/gds/placement_top.gds
```

การดู GDS เหมาะสำหรับตรวจสอบภาพรวม แต่การวิเคราะห์ Cell Placement ก่อน Routing ควรใช้ OpenROAD GUI และ ODB เพราะสามารถดู Instance, Net, Congestion และ Timing ได้ละเอียดกว่า

---

# 7.17 Placement Optimization Experiments

Lab นี้ให้ทดลองอย่างน้อยสี่ Configuration

## Experiment A: Baseline

```yaml
FP_CORE_UTIL: 45
PL_TARGET_DENSITY_PCT: 60
PL_TIMING_DRIVEN: true
PL_ROUTABILITY_DRIVEN: true
```

รัน:

```bash
librelane \
  --run-tag lab7_baseline \
  config.yaml
```

---

## Experiment B: Low Density

สร้าง `config_low_density.yaml`

```yaml
meta:
  version: 2
  flow: Classic

DESIGN_NAME: placement_top

VERILOG_FILES:
  - dir::src/placement_top.sv

PDK: sky130A
STD_CELL_LIBRARY: sky130_fd_sc_hd

CLOCK_PORT: clk_i
CLOCK_NET: clk_i
CLOCK_PERIOD: 10.0

PNR_SDC_FILE: dir::constraints/placement.sdc
SIGNOFF_SDC_FILE: dir::constraints/placement.sdc

FP_SIZING: relative
FP_CORE_UTIL: 35
FP_ASPECT_RATIO: 1.0
FP_CORE_MARGIN: 5

FP_IO_MODE: 0
FP_IO_MIN_DISTANCE: 3

PL_TARGET_DENSITY_PCT: 50
PL_TIMING_DRIVEN: true
PL_ROUTABILITY_DRIVEN: true
PL_WIRE_LENGTH_COEF: 0.25

PL_OPTIMIZE_MIRRORING: true
PL_MAX_DISPLACEMENT_X: 500
PL_MAX_DISPLACEMENT_Y: 100

GRT_ADJUSTMENT: 0.30
```

รัน:

```bash
librelane \
  --run-tag lab7_low_density \
  config_low_density.yaml
```

ผลที่คาดหมาย:

- Core Area ใหญ่ขึ้น
- Density ลดลง
- Congestion ลดลง
- Wirelength อาจเพิ่มขึ้น
- Timing อาจดีขึ้นหรือแย่ลงขึ้นกับตำแหน่ง Critical Logic
- Routing มีโอกาสผ่านง่ายขึ้น

---

## Experiment C: Balanced Density

สร้าง `config_balanced.yaml`

```yaml
meta:
  version: 2
  flow: Classic

DESIGN_NAME: placement_top

VERILOG_FILES:
  - dir::src/placement_top.sv

PDK: sky130A
STD_CELL_LIBRARY: sky130_fd_sc_hd

CLOCK_PORT: clk_i
CLOCK_NET: clk_i
CLOCK_PERIOD: 10.0

PNR_SDC_FILE: dir::constraints/placement.sdc
SIGNOFF_SDC_FILE: dir::constraints/placement.sdc

FP_SIZING: relative
FP_CORE_UTIL: 45
FP_ASPECT_RATIO: 1.0
FP_CORE_MARGIN: 5

FP_IO_MODE: 0
FP_IO_MIN_DISTANCE: 3

PL_TARGET_DENSITY_PCT: 58

PL_TIMING_DRIVEN: true
PL_ROUTABILITY_DRIVEN: true

PL_SKIP_INITIAL_PLACEMENT: false
PL_WIRE_LENGTH_COEF: 0.25

PL_OPTIMIZE_MIRRORING: true
PL_MAX_DISPLACEMENT_X: 500
PL_MAX_DISPLACEMENT_Y: 100

GRT_ADJUSTMENT: 0.30
```

รัน:

```bash
librelane \
  --run-tag lab7_balanced \
  config_balanced.yaml
```

---

## Experiment D: High Density

สร้าง `config_high_density.yaml`

```yaml
meta:
  version: 2
  flow: Classic

DESIGN_NAME: placement_top

VERILOG_FILES:
  - dir::src/placement_top.sv

PDK: sky130A
STD_CELL_LIBRARY: sky130_fd_sc_hd

CLOCK_PORT: clk_i
CLOCK_NET: clk_i
CLOCK_PERIOD: 10.0

PNR_SDC_FILE: dir::constraints/placement.sdc
SIGNOFF_SDC_FILE: dir::constraints/placement.sdc

FP_SIZING: relative
FP_CORE_UTIL: 60
FP_ASPECT_RATIO: 1.0
FP_CORE_MARGIN: 5

FP_IO_MODE: 0
FP_IO_MIN_DISTANCE: 3

PL_TARGET_DENSITY_PCT: 72

PL_TIMING_DRIVEN: true
PL_ROUTABILITY_DRIVEN: true

PL_SKIP_INITIAL_PLACEMENT: false
PL_WIRE_LENGTH_COEF: 0.25

PL_OPTIMIZE_MIRRORING: true
PL_MAX_DISPLACEMENT_X: 500
PL_MAX_DISPLACEMENT_Y: 100

GRT_ADJUSTMENT: 0.30
```

รัน:

```bash
librelane \
  --run-tag lab7_high_density \
  config_high_density.yaml
```

ผลที่อาจเกิดขึ้น:

- Core Area ลดลง
- HPWL ลดลง
- Local Density สูงขึ้น
- Global Routing Overflow เพิ่มขึ้น
- CTS Buffer ไม่มีพื้นที่เพียงพอ
- Detailed Placement ใช้เวลามากขึ้น
- Setup Timing อาจดีขึ้นจาก Wirelength ที่ลดลง
- Hold Timing อาจเปลี่ยน
- Routing DRC อาจเพิ่มขึ้น

---

# 7.18 Shell Scripts สำหรับการทดลอง

สร้าง `scripts/run_baseline.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

librelane \
  --run-tag lab7_baseline \
  config.yaml
```

สร้าง `scripts/run_low_density.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

librelane \
  --run-tag lab7_low_density \
  config_low_density.yaml
```

สร้าง `scripts/run_balanced.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

librelane \
  --run-tag lab7_balanced \
  config_balanced.yaml
```

สร้าง `scripts/run_high_density.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

librelane \
  --run-tag lab7_high_density \
  config_high_density.yaml
```

กำหนด Permission

```bash
chmod +x scripts/*.sh
```

รันทั้งหมดทีละ Configuration

```bash
./scripts/run_baseline.sh
./scripts/run_low_density.sh
./scripts/run_balanced.sh
./scripts/run_high_density.sh
```

---

# 7.19 ตารางบันทึกผล

ให้ผู้เรียนบันทึกผลในตารางต่อไปนี้

| Metric | Low Density | Baseline | Balanced | High Density |
|---|---:|---:|---:|---:|
| FP_CORE_UTIL | 35 | 45 | 45 | 60 |
| PL_TARGET_DENSITY_PCT | 50 | 60 | 58 | 72 |
| Die Area |  |  |  |  |
| Core Area |  |  |  |  |
| Standard Cell Area |  |  |  |  |
| Instance Count |  |  |  |  |
| Global Placement HPWL |  |  |  |  |
| Final Wirelength |  |  |  |  |
| Setup WNS |  |  |  |  |
| Setup TNS |  |  |  |  |
| Hold WNS |  |  |  |  |
| Max Slew Violations |  |  |  |  |
| Max Cap Violations |  |  |  |  |
| Routing Overflow |  |  |  |  |
| Routing DRC |  |  |  |  |
| Placement Legal |  |  |  |  |
| Runtime |  |  |  |  |

---

# 7.20 ค้นหา Metrics จาก LibreLane

LibreLane ใช้ระบบ State และ Metrics เพื่อส่งผลลัพธ์ระหว่าง Step และจัดเก็บตัวชี้วัดของ Design 

ค้นหาไฟล์ Metrics

```bash
find runs/lab7_baseline \
  -type f \
  \( -name "metrics.json" \
     -o -name "*.metrics.json" \
     -o -name "resolved.json" \)
```

ดู Metrics ที่เกี่ยวข้องกับ Placement

```bash
grep -RniE \
  "wirelength|density|utilization|area|overflow|setup|hold|instance" \
  runs/lab7_baseline \
  --include="*.json" \
  | head -n 200
```

ใช้ `jq` หากติดตั้งแล้ว

```bash
find runs/lab7_baseline \
  -name "*metrics*.json" \
  -exec jq . {} \;
```

ค้นหา Timing Metric

```bash
grep -RniE \
  "wns|tns|setup|hold|slack" \
  runs/lab7_baseline \
  --include="*.json" \
  --include="*.rpt" \
  --include="*.log"
```

---

# 7.21 วิเคราะห์ Placement Quality

Placement ที่ดีควรมีลักษณะดังนี้

## 7.21.1 Placement ต้อง Legal

ต้องไม่มี

- Overlapping Cell
- Off-row Cell
- Off-site Cell
- Illegal Orientation
- Unplaced Instance
- Cell อยู่นอก Core Boundary

หาก Placement ไม่ Legal ไม่ควรดำเนินการเข้าสู่ CTS หรือ Routing

---

## 7.21.2 Density ต้องไม่สูงเกินไป

ตรวจสอบว่ามีบริเวณที่ Standard Cell รวมตัวหนาแน่นหรือไม่ โดยเฉพาะ

- ใกล้ Input Pin
- ใกล้ Output Pin
- รอบ Arithmetic Datapath
- รอบ MUX ขนาดใหญ่
- รอบ High-fanout Control Signal
- รอบ Macro Boundary
- ระหว่าง PDN Stripes

หากมี Density Hotspot อาจแก้ด้วย

```yaml
FP_CORE_UTIL: 40
PL_TARGET_DENSITY_PCT: 55
```

แทนค่าที่สูงกว่า

---

## 7.21.3 ต้องเหลือพื้นที่สำหรับ CTS

Placement ก่อน CTS ไม่ควรแน่นจนหมด เพราะ CTS จะเพิ่ม

- Clock Buffer
- Clock Inverter
- Delay Buffer
- Hold-fix Buffer
- Routing Segment ของ Clock Tree

หากพื้นที่ไม่พอ CTS อาจเกิด

- Buffer placement failure
- Excessive displacement
- Local congestion
- Clock routing detour
- Poor skew
- Placement legalization failure หลัง CTS

---

## 7.21.4 Timing ต้องไม่เสื่อมมากเกินไป

หลัง Placement ควรเปรียบเทียบ

```text
Pre-PNR STA
    versus
Post-Placement STA
```

หาก Setup Slack แย่ลงมาก ให้ตรวจสอบ

- Critical Path กระจายตัวไกลหรือไม่
- Output Pin อยู่ไกลจาก Driver หรือไม่
- High-fanout Net มี Buffer เพียงพอหรือไม่
- Timing-driven Placement เปิดอยู่หรือไม่
- Clock Constraint ถูกต้องหรือไม่
- Input/Output Delay สมจริงหรือไม่
- Core มีขนาดใหญ่เกินไปหรือไม่

---

## 7.21.5 Routing Congestion ต้องควบคุมได้

Global Routing ใช้ Routing Graph เพื่อประมาณและค้นหาเส้นทาง โดย FastRoute เป็นพื้นฐานของ Global Router ใน OpenROAD 

หากพบ Overflow หรือ Congestion สูง ให้ทดลองตามลำดับ

1. ลด `FP_CORE_UTIL`
2. ลด `PL_TARGET_DENSITY_PCT`
3. เปิด `PL_ROUTABILITY_DRIVEN`
4. เพิ่ม Cell Padding อย่างระมัดระวัง
5. ปรับ I/O Pin Placement
6. เพิ่ม Core Area
7. เปลี่ยน Aspect Ratio
8. ปรับ Macro Placement
9. ตรวจ PDN ที่กีดขวาง Routing
10. ตรวจ High-fanout Net และ Bus Structure

---

# 7.22 Timing-driven และ Routability-driven Trade-off

| Configuration | Timing | Routability | Runtime |
|---|---|---|---|
| Timing off, Routability off | อาจแย่ | อาจแย่ | ต่ำ |
| Timing on, Routability off | ดีขึ้นบาง Path | เสี่ยง Congestion | ปานกลาง |
| Timing off, Routability on | ไม่เน้น Critical Path | ดีขึ้น | ปานกลาง |
| Timing on, Routability on | สมดุลที่สุด | สมดุลที่สุด | สูงกว่า |

Configuration ที่แนะนำเป็นค่าเริ่มต้น:

```yaml
PL_TIMING_DRIVEN: true
PL_ROUTABILITY_DRIVEN: true
```

จากนั้นใช้ Metrics จริงในการตัดสิน ไม่ควรเลือก Configuration จาก Runtime เพียงอย่างเดียว

---

# 7.23 การปรับ Placement อย่างเป็นระบบ

ควรใช้หลัก **ปรับครั้งละหนึ่งตัวแปร**

ตัวอย่างลำดับการทดลอง:

```text
Run 1:
FP_CORE_UTIL = 45
PL_TARGET_DENSITY_PCT = 60

Run 2:
FP_CORE_UTIL = 40
PL_TARGET_DENSITY_PCT = 60

Run 3:
FP_CORE_UTIL = 40
PL_TARGET_DENSITY_PCT = 55

Run 4:
FP_CORE_UTIL = 40
PL_TARGET_DENSITY_PCT = 55
PL_WIRE_LENGTH_COEF = 0.20
```

ไม่ควรเปลี่ยนพร้อมกันดังนี้

```text
FP_CORE_UTIL
PL_TARGET_DENSITY_PCT
PL_WIRE_LENGTH_COEF
GRT_ADJUSTMENT
Aspect Ratio
Cell Padding
```

เพราะไม่สามารถแยกได้ว่าตัวแปรใดทำให้ผลดีขึ้นหรือแย่ลง

---

# 7.24 Placement Optimization Decision Tree

```text
Placement ล้มเหลวหรือไม่?
        |
        +-- ใช่ --> มี cell overlap หรือ legalization failure?
        |              |
        |              +-- ใช่ --> ลด density
        |              |          ลด core utilization
        |              |          เพิ่ม max displacement
        |              |
        |              +-- ไม่ใช่ --> ตรวจ PDK/site/row/macro blockage
        |
        +-- ไม่ใช่ --> Routing congestion สูงหรือไม่?
                       |
                       +-- ใช่ --> ลด density
                       |          เปิด routability-driven
                       |          ปรับ pin placement
                       |          เพิ่ม core area
                       |
                       +-- ไม่ใช่ --> Timing ไม่ผ่านหรือไม่?
                                      |
                                      +-- ใช่ --> เปิด timing-driven
                                      |          ลด critical wirelength
                                      |          ตรวจ SDC
                                      |          ปรับ core size
                                      |
                                      +-- ไม่ใช่ --> Placement พร้อมเข้าสู่ CTS
```

---

# 7.25 ปัญหาที่พบบ่อยและแนวทางแก้ไข

## ปัญหา 1: Global Placement Diverged

อาการ:

```text
Global placement diverged
```

หรือ Overflow ไม่ลดลงตาม Iteration

แนวทางแก้:

```yaml
FP_CORE_UTIL: 40
PL_TARGET_DENSITY_PCT: 55
```

หากยังไม่สำเร็จ อาจทดลองกำหนด Phi Coefficient

```yaml
PL_MIN_PHI_COEFFICIENT: 0.95
PL_MAX_PHI_COEFFICIENT: 1.05
```

LibreLane ระบุว่า `PL_MIN_PHI_COEFFICIENT` และ `PL_MAX_PHI_COEFFICIENT` สามารถใช้เมื่อ Global Placement Diverges แต่ควรใช้หลังจากตรวจ Density และ Floorplan ก่อน 

---

## ปัญหา 2: Detailed Placement Failed

อาการ:

```text
detailed placement failed
```

หรือ

```text
unable to legalize instances
```

สาเหตุที่เป็นไปได้:

- Core Utilization สูง
- Cell Padding สูง
- Placement Blockage มาก
- Macro Channel แคบ
- Maximum Displacement ต่ำเกินไป
- Placement Row ผิด
- Standard Cell Site ไม่ตรงกับ Library

แนวทางแก้:

```yaml
FP_CORE_UTIL: 35
PL_TARGET_DENSITY_PCT: 50
PL_MAX_DISPLACEMENT_X: 500
PL_MAX_DISPLACEMENT_Y: 200
```

---

## ปัญหา 3: Congestion สูง

อาการ:

- Routing Overflow
- Congestion Hotspot
- Global Routing Failure
- Detailed Routing DRC จำนวนมาก

แนวทางแก้:

```yaml
FP_CORE_UTIL: 38
PL_TARGET_DENSITY_PCT: 52
PL_ROUTABILITY_DRIVEN: true
```

จากนั้นตรวจ Pin Placement และ PDN Obstruction

---

## ปัญหา 4: HPWL ต่ำ แต่ Routing แย่

สาเหตุ:

- Cell ถูกดึงมารวมกันบริเวณเดียว
- Net หลายเส้นใช้ Routing Channel เดียวกัน
- Bus ขนาดใหญ่ผ่านช่องแคบ
- Pin อยู่ด้านเดียวกันมากเกินไป
- PDN ใช้ Routing Resource มาก

แนวทางแก้:

- อย่า Optimize HPWL เพียงอย่างเดียว
- เปิด Routability-driven Placement
- ลด Density
- กระจาย I/O Pin
- ตรวจ Congestion Heatmap

---

## ปัญหา 5: Timing แย่หลัง Placement

แนวทางแก้:

```yaml
PL_TIMING_DRIVEN: true
PL_ROUTABILITY_DRIVEN: true
```

จากนั้นตรวจ

- SDC
- Critical Path
- Buffer Count
- Net Fanout
- Output Load
- Input Delay
- Estimated Parasitics
- Placement ของ Launch และ Capture Register

---

## ปัญหา 6: Configuration Variable ไม่รู้จัก

อาการ:

```text
Unknown configuration variable
```

LibreLane ตรวจสอบ Configuration อย่างเข้มงวดและสามารถตรวจพบชื่อ Variable ผิดหรือชนิดข้อมูลผิดก่อนเริ่ม Flow 

ตัวอย่างชื่อปัจจุบัน:

```yaml
PL_TARGET_DENSITY_PCT: 60
```

ชื่อเดิม:

```yaml
PL_TARGET_DENSITY: 60
```

แม้ชื่อเดิมอาจยังรองรับในฐานะ Deprecated Alias แต่คู่มือใหม่ควรใช้ชื่อปัจจุบัน 

---

## ปัญหา 7: DPL_CELL_PADDING มากกว่า GPL_CELL_PADDING

แก้เป็น

```yaml
GPL_CELL_PADDING: 2
DPL_CELL_PADDING: 1
```

LibreLane กำหนดแนวทางว่า Detailed Placement Padding ควรไม่มากกว่า Global Placement Padding 

---

# 7.26 Configuration ที่แนะนำสำหรับงานทั่วไป

```yaml
# Floorplan
FP_CORE_UTIL: 40
FP_ASPECT_RATIO: 1.0
FP_CORE_MARGIN: 5

# Placement
PL_TARGET_DENSITY_PCT: 55
PL_TIMING_DRIVEN: true
PL_ROUTABILITY_DRIVEN: true
PL_SKIP_INITIAL_PLACEMENT: false
PL_WIRE_LENGTH_COEF: 0.25

# Detailed placement
PL_OPTIMIZE_MIRRORING: true
PL_MAX_DISPLACEMENT_X: 500
PL_MAX_DISPLACEMENT_Y: 100

# Routing estimation
GRT_ADJUSTMENT: 0.30
```

Configuration นี้เป็นเพียงค่าเริ่มต้น จากนั้นต้องปรับตาม

- Standard Cell Library
- PDK
- Design Size
- Number of Macros
- Number of Clock Domains
- Timing Target
- I/O Count
- Routing Layer Availability
- PDN Architecture

---

# 7.27 Configuration สำหรับ Timing-oriented Placement

```yaml
FP_CORE_UTIL: 45
PL_TARGET_DENSITY_PCT: 60

PL_TIMING_DRIVEN: true
PL_ROUTABILITY_DRIVEN: true

PL_KEEP_RESIZE_BELOW_OVERFLOW: 0.30
PL_WIRE_LENGTH_COEF: 0.20
```

`PL_KEEP_RESIZE_BELOW_OVERFLOW` ใช้เมื่อเปิด Timing-driven Placement เพื่อกำหนดระดับ Overflow ที่การเปลี่ยนแปลงจาก Resizer จะถูกเก็บไว้แทนการย้อนกลับ 

ควรใช้หลังจาก Baseline Flow ทำงานได้แล้ว

---

# 7.28 Configuration สำหรับ Routability-oriented Placement

```yaml
FP_CORE_UTIL: 35
PL_TARGET_DENSITY_PCT: 50

PL_TIMING_DRIVEN: true
PL_ROUTABILITY_DRIVEN: true

PL_ROUTABILITY_OVERFLOW_THRESHOLD: 0.20
GRT_ADJUSTMENT: 0.30
```

เหมาะกับ Design ที่มี

- Bus จำนวนมาก
- High fanout
- I/O จำนวนมาก
- Macro หลายตัว
- Routing Channel แคบ
- PDN หนาแน่น
- Metal Layer จำกัด

---

# 7.29 เกณฑ์ผ่าน Lab

ผลลัพธ์ถือว่าผ่านเมื่อ

- LibreLane อ่าน `config.yaml` ได้โดยไม่มี Configuration Error
- Synthesis ไม่มี Unmapped Cell
- Global Placement ทำงานสำเร็จ
- Detailed Placement ทำงานสำเร็จ
- ไม่มี Unplaced Instance
- ไม่มี Illegal Cell Overlap
- Placement ผ่าน Legality Check
- สามารถเปิดผลด้วย OpenROAD GUI
- สามารถระบุบริเวณ Density สูงได้
- สามารถเปรียบเทียบอย่างน้อยสาม Configuration
- มีการบันทึก Core Area, HPWL, Timing และ Congestion
- เลือก Configuration ที่เหมาะสมพร้อมเหตุผล
- Flow สามารถเดินหน้าสู่ CTS และ Routing ได้

---

# 7.30 แบบฝึกหัดท้าย Lab

## แบบฝึกหัดที่ 1

ทดลอง

```yaml
FP_CORE_UTIL: 30
PL_TARGET_DENSITY_PCT: 45
```

บันทึก

- Core Area
- HPWL
- Setup WNS
- Routing Overflow
- Runtime

อธิบายว่าทำไม Core Area ใหญ่ขึ้นแต่ Timing อาจไม่ได้ดีขึ้นเสมอไป

---

## แบบฝึกหัดที่ 2

ทดลอง

```yaml
FP_CORE_UTIL: 65
PL_TARGET_DENSITY_PCT: 75
```

ตรวจสอบว่าเกิด

- Placement Failure
- Congestion
- Routing Overflow
- CTS Buffer Placement Problem
- Timing Improvement หรือไม่

หาก Flow ล้มเหลว ให้ระบุ Step แรกที่ล้มเหลว

---

## แบบฝึกหัดที่ 3

เปรียบเทียบ

```yaml
PL_TIMING_DRIVEN: false
```

กับ

```yaml
PL_TIMING_DRIVEN: true
```

โดยคงตัวแปรอื่นเหมือนเดิม แล้วเปรียบเทียบ

- WNS
- TNS
- HPWL
- Cell Area
- Buffer Count
- Runtime

---

## แบบฝึกหัดที่ 4

เปรียบเทียบ

```yaml
PL_ROUTABILITY_DRIVEN: false
```

กับ

```yaml
PL_ROUTABILITY_DRIVEN: true
```

วิเคราะห์

- Congestion
- Overflow
- Wirelength
- Routing DRC
- Runtime

---

## แบบฝึกหัดที่ 5

ทดลองปรับ

```yaml
PL_WIRE_LENGTH_COEF: 0.20
```

```yaml
PL_WIRE_LENGTH_COEF: 0.25
```

```yaml
PL_WIRE_LENGTH_COEF: 0.30
```

สร้างกราฟหรือสรุปความสัมพันธ์ระหว่าง

- Wirelength Coefficient
- HPWL
- Setup Slack
- Routing Overflow

---

# 7.31 คำถามทบทวน

1. Global Placement ต่างจาก Detailed Placement อย่างไร
2. เพราะเหตุใด Global Placement จึงยอมให้เซลล์ซ้อนกันได้ชั่วคราว
3. Core Utilization ต่างจาก Placement Density อย่างไร
4. การลด Core Utilization ส่งผลต่อ Die Area อย่างไร
5. เพราะเหตุใด HPWL ต่ำจึงไม่ได้หมายความว่า Routing จะง่ายเสมอไป
6. Timing-driven Placement อาจเพิ่ม Congestion ได้อย่างไร
7. Routability-driven Placement อาจเพิ่ม Wirelength ได้อย่างไร
8. ทำไมต้องเหลือพื้นที่สำหรับ CTS Buffer
9. `GPL_CELL_PADDING` แตกต่างจาก `DPL_CELL_PADDING` อย่างไร
10. เพราะเหตุใด `DPL_CELL_PADDING` จึงควรไม่เกิน `GPL_CELL_PADDING`
11. Maximum Displacement ต่ำเกินไปทำให้เกิดปัญหาใด
12. Placement Legality ต้องตรวจสอบอะไรบ้าง
13. หาก Detailed Placement ล้มเหลว ควรปรับตัวแปรใดก่อน
14. เหตุใดจึงควรปรับ Configuration ทีละหนึ่งตัวแปร
15. Metric ใดบ้างที่ต้องพิจารณาก่อนเลือก Placement ที่ดีที่สุด

---

# 7.32 สรุป

Placement Optimization เป็นกระบวนการหาสมดุลระหว่าง

$$Area \leftrightarrow Timing \leftrightarrow Wirelength \leftrightarrow Density \leftrightarrow Routability$$

Configuration ที่มี Core เล็กที่สุดหรือ HPWL ต่ำที่สุดไม่จำเป็นต้องเป็น Configuration ที่ดีที่สุด

Placement ที่เหมาะสมต้อง

- ถูกกฎหมาย
- มี Timing ที่ยอมรับได้
- ไม่มี Density Hotspot รุนแรง
- มีพื้นที่สำหรับ CTS
- มี Routing Congestion ที่ควบคุมได้
- สามารถผ่าน Routing และ Physical Verification ได้

ขั้นตอนที่แนะนำคือ

```text
1. เริ่มจาก Core Utilization ปานกลาง
2. เปิด Timing-driven Placement
3. เปิด Routability-driven Placement
4. ตรวจ Placement Legality
5. ตรวจ HPWL และ Timing
6. ตรวจ Congestion และ Overflow
7. ลด Density หาก Routing ยาก
8. ปรับ Floorplan หาก Placement ยังไม่ดี
9. เปรียบเทียบหลาย Run
10. เลือก Configuration ก่อนเข้าสู่ CTS
```

LibreLane ทำให้สามารถกำหนดและตรวจสอบ Placement Configuration ผ่าน `config.yaml` ได้อย่างเป็นระบบ ส่วน OpenROAD ทำหน้าที่ Global Placement, Detailed Placement, Timing Optimization และ Routability Optimization ภายใน Flow เดียวกัน

