

# Lab 13  
# Hierarchical Physical Design

## 13.1 วัตถุประสงค์ของบทปฏิบัติการ

บทปฏิบัติการนี้สาธิตการออกแบบทางกายภาพแบบลำดับชั้น หรือ **Hierarchical Physical Design** โดยแบ่งวงจรขนาดใหญ่ออกเป็นบล็อกย่อย จากนั้นนำบล็อกย่อยแต่ละบล็อกผ่านกระบวนการ RTL-to-GDSII เพื่อสร้างเป็น **Hard Macro** ก่อนนำ Hard Macro เหล่านั้นมาประกอบเข้ากับวงจรระดับบนสุด

หลังจบบทปฏิบัติการ ผู้เรียนจะสามารถ

1. อธิบายความแตกต่างระหว่าง Flat Physical Design และ Hierarchical Physical Design
2. แบ่งระบบออกเป็นบล็อกย่อยสำหรับการออกแบบทางกายภาพ
3. สร้าง Hard Macro จาก RTL ด้วย LibreLane
4. ตรวจสอบไฟล์มุมมองหรือ Macro Views ที่จำเป็น
5. นำ Hard Macro ไปประกาศใน `config.yaml` ของวงจรระดับบน
6. กำหนดตำแหน่งและทิศทางของ Macro
7. วางแผน Floorplan, Macro Halo, Routing Channel และ Power Distribution Network
8. ตรวจสอบการเชื่อมต่อระหว่าง Top-Level Logic และ Macro
9. วิเคราะห์ Timing Boundary ระหว่างบล็อก
10. ตรวจสอบ DRC, LVS, Antenna และ Timing ของระบบระดับบน
11. วิเคราะห์และแก้ปัญหาที่มักเกิดขึ้นใน Hierarchical Flow
12. สร้าง Hierarchical RTL-to-GDSII Flow ที่นำกลับมาใช้ซ้ำได้

---

## 13.2 แนวคิดของ Hierarchical Physical Design

การออกแบบทางกายภาพแบบ Flat จะนำ RTL ทั้งหมดเข้าสู่กระบวนการสังเคราะห์ วางเซลล์ สร้าง Clock Tree และเดินสายพร้อมกันในครั้งเดียว

ตัวอย่างโครงสร้างแบบ Flat:

```text
soc_top
├── cpu_core
├── bus_interconnect
├── timer
├── gpio
├── uart
└── register_file
```

ใน Flat Flow โมดูลทั้งหมดจะถูกสังเคราะห์และทำ Physical Design เป็นฐานข้อมูลเดียว

```text
Complete RTL
    │
    ▼
Synthesis
    │
    ▼
Floorplan
    │
    ▼
Placement
    │
    ▼
CTS
    │
    ▼
Routing
    │
    ▼
GDSII
```

เมื่อวงจรมีขนาดใหญ่ขึ้น การทำทุกขั้นตอนในฐานข้อมูลเดียวอาจทำให้

- ใช้เวลาประมวลผลมาก
- ใช้หน่วยความจำสูง
- ปรับแก้ Floorplan ได้ยาก
- Timing Closure ซับซ้อน
- บล็อกที่ผ่านการตรวจสอบแล้วต้องถูกประมวลผลใหม่
- หลายทีมไม่สามารถพัฒนาบล็อกแยกกันได้สะดวก

Hierarchical Physical Design จะแบ่งวงจรออกเป็นหลายบล็อก โดยแต่ละบล็อกถูกทำให้เป็น Hard Macro ก่อนนำไปประกอบที่ระดับบน

```text
                     +----------------------+
                     |       soc_top        |
                     |                      |
 Inputs ------------>|  +---------------+   |
                     |  | cpu_core      |   |
                     |  | Hard Macro    |   |
                     |  +---------------+   |
                     |                      |
                     |  +---------------+   |
                     |  | peripheral    |   |----> Outputs
                     |  | Hard Macro    |   |
                     |  +---------------+   |
                     |                      |
                     | Top-Level Glue Logic |
                     +----------------------+
```

LibreLane อธิบายว่าในการออกแบบจริง บล็อกบางส่วนมักถูกทำให้เป็น Physical Macro ก่อน แล้วจึงนำมาประกอบที่ระดับบน วิธีนี้ช่วยลดเวลาการทำ Place-and-Route ซ้ำ เพิ่มความสามารถในการใช้บล็อกเดิมซ้ำ และรองรับการใช้งานบล็อกในลักษณะ Black Box ได้ 

---

## 13.3 Flat Flow เทียบกับ Hierarchical Flow

| หัวข้อ | Flat Flow | Hierarchical Flow |
|---|---|---|
| หน่วยการออกแบบ | RTL ทั้งระบบ | แบ่งเป็นหลายบล็อก |
| การสังเคราะห์ | สังเคราะห์พร้อมกัน | สังเคราะห์แยกบล็อก |
| Place-and-Route | ทำทั้งระบบ | ทำระดับบล็อกและระดับบน |
| Runtime | เพิ่มขึ้นเร็วตามขนาดวงจร | กระจายงานและใช้ Macro ซ้ำได้ |
| การใช้หน่วยความจำ | สูง | ลดลงในแต่ละงาน |
| การทำงานหลายทีม | ทำได้ยากกว่า | แยกความรับผิดชอบได้ |
| Timing Analysis | มองเห็นวงจรทั้งหมด | ต้องจัดการ Timing Boundary |
| Optimization | ข้ามโมดูลได้เต็มที่ | จำกัดด้วยขอบเขตของ Macro |
| IP Reuse | จำกัด | เหมาะสำหรับ IP Reuse |
| Floorplan | ง่ายสำหรับวงจรเล็ก | เหมาะกับระบบที่มีหลายบล็อก |
| Debug | ฐานข้อมูลเดียว | แยก Debug ระดับ Macro/Top |
| Signoff | Flow เดียว | ต้อง Signoff หลายระดับ |

Hierarchical Flow ไม่ได้ให้ผลลัพธ์ดีกว่า Flat Flow ในทุกกรณี สำหรับวงจรขนาดเล็ก Flat Flow มักง่ายกว่า แต่สำหรับ SoC หรือระบบที่มีบล็อกซับซ้อน การแบ่ง Physical Hierarchy ช่วยควบคุมความซับซ้อนได้ดีขึ้น

---

## 13.4 สถาปัตยกรรมที่ใช้ในบทปฏิบัติการ

ตัวอย่างใน Lab นี้ใช้ระบบชื่อ `hier_system` ประกอบด้วย Hard Macro สองตัว

1. `counter_macro`
2. `accumulator_macro`

วงจรระดับบนมี Register และ Multiplexer สำหรับควบคุมข้อมูล

```text
                      +-------------------------+
 clk_i -------------->|                         |
 rst_ni --------------|                         |
                      |      hier_system        |
 enable_i ------------|                         |
                      |   +------------------+  |
                      |   | counter_macro    |  |
                      |   |                  |  |
                      |   | count_o[7:0]     |--+----+
                      |   +------------------+  |    |
                      |                         |    |
 data_i[7:0] -------->|   +------------------+  |    |
                      |   | accumulator      |  |    |
                      |   | macro            |  |    |
                      |   | accum_o[7:0]     |--+--+ |
                      |   +------------------+     | |
                      |                            | |
 select_i ------------|-----------------------> MUX |
                      |                            | |
 result_o[7:0] <-------|----------------------------+
                      +-------------------------+
```

ลำดับการทำงานประกอบด้วย

```text
Phase 1: RTL Verification
Phase 2: Counter Macro Hardening
Phase 3: Accumulator Macro Hardening
Phase 4: Macro View Collection
Phase 5: Top-Level RTL Preparation
Phase 6: Top-Level Macro Integration
Phase 7: Macro Placement
Phase 8: Top-Level Place-and-Route
Phase 9: Timing and Physical Verification
Phase 10: Hierarchical Signoff Review
```

---

## 13.5 โครงสร้างไดเรกทอรี

สร้างโครงสร้างโครงการดังนี้

```text
lab13_hierarchical/
├── Makefile
├── README.md
├── rtl/
│   ├── counter_macro.sv
│   ├── accumulator_macro.sv
│   └── hier_system.sv
├── tb/
│   └── tb_hier_system.sv
├── blocks/
│   ├── counter_macro/
│   │   ├── config.yaml
│   │   ├── pin_order.cfg
│   │   └── constraints.sdc
│   └── accumulator_macro/
│       ├── config.yaml
│       ├── pin_order.cfg
│       └── constraints.sdc
├── top/
│   ├── config.yaml
│   ├── pin_order.cfg
│   ├── macro_placement.cfg
│   └── constraints.sdc
├── macros/
│   ├── counter_macro/
│   │   ├── gds/
│   │   ├── lef/
│   │   ├── lib/
│   │   ├── netlist/
│   │   ├── spef/
│   │   └── spice/
│   └── accumulator_macro/
│       ├── gds/
│       ├── lef/
│       ├── lib/
│       ├── netlist/
│       ├── spef/
│       └── spice/
├── scripts/
│   ├── collect_counter_macro.sh
│   ├── collect_accumulator_macro.sh
│   └── check_macro_views.sh
├── runs/
└── reports/
```

สร้างไดเรกทอรีด้วยคำสั่ง

```bash
mkdir -p lab13_hierarchical/{rtl,tb,blocks,top,macros,scripts,runs,reports}

mkdir -p lab13_hierarchical/blocks/counter_macro
mkdir -p lab13_hierarchical/blocks/accumulator_macro

mkdir -p lab13_hierarchical/macros/counter_macro/{gds,lef,lib,netlist,spef,spice}
mkdir -p lab13_hierarchical/macros/accumulator_macro/{gds,lef,lib,netlist,spef,spice}

cd lab13_hierarchical
```

---

# ส่วนที่ 1 การเตรียม RTL

## 13.6 สร้าง Counter Macro

สร้างไฟล์

```text
rtl/counter_macro.sv
```

เนื้อหาไฟล์:

```systemverilog
`default_nettype none

module counter_macro #(
    parameter int unsigned WIDTH = 8
) (
    input  logic                 clk_i,
    input  logic                 rst_ni,
    input  logic                 enable_i,
    output logic [WIDTH-1:0]     count_o
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

โมดูลนี้มีสัญญาณ

| Port | Direction | Width | Description |
|---|---:|---:|---|
| `clk_i` | Input | 1 | Clock |
| `rst_ni` | Input | 1 | Active-low asynchronous reset |
| `enable_i` | Input | 1 | Counter enable |
| `count_o` | Output | 8 | Counter value |

---

## 13.7 สร้าง Accumulator Macro

สร้างไฟล์

```text
rtl/accumulator_macro.sv
```

เนื้อหาไฟล์:

```systemverilog
`default_nettype none

module accumulator_macro #(
    parameter int unsigned WIDTH = 8
) (
    input  logic                 clk_i,
    input  logic                 rst_ni,
    input  logic                 enable_i,
    input  logic [WIDTH-1:0]     data_i,
    output logic [WIDTH-1:0]     accum_o
);

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            accum_o <= '0;
        end else if (enable_i) begin
            accum_o <= accum_o + data_i;
        end
    end

endmodule

`default_nettype wire
```

---

## 13.8 สร้าง Top-Level RTL

สร้างไฟล์

```text
rtl/hier_system.sv
```

เนื้อหาไฟล์:

```systemverilog
`default_nettype none

module hier_system (
    input  logic         clk_i,
    input  logic         rst_ni,

    input  logic         counter_enable_i,
    input  logic         accum_enable_i,
    input  logic [7:0]   data_i,
    input  logic         select_i,

    output logic [7:0]   result_o
);

    logic [7:0] count_value;
    logic [7:0] accum_value;

    counter_macro u_counter_macro (
        .clk_i    (clk_i),
        .rst_ni   (rst_ni),
        .enable_i (counter_enable_i),
        .count_o  (count_value)
    );

    accumulator_macro u_accumulator_macro (
        .clk_i    (clk_i),
        .rst_ni   (rst_ni),
        .enable_i (accum_enable_i),
        .data_i   (data_i),
        .accum_o  (accum_value)
    );

    always_comb begin
        if (select_i) begin
            result_o = accum_value;
        end else begin
            result_o = count_value;
        end
    end

endmodule

`default_nettype wire
```

### ข้อควรระวังเรื่องชื่อ Instance

ชื่อ Instance ใน Top-Level RTL ต้องตรงกับชื่อที่กำหนดในส่วน `instances` ของ `MACROS`

ตัวอย่าง:

```systemverilog
counter_macro u_counter_macro (...);
```

ต้องสอดคล้องกับ

```yaml
instances:
  u_counter_macro:
    location: [40.0, 50.0]
    orientation: N
```

ชื่อ Key ระดับแรกของ `MACROS` คือชื่อโมดูล Macro ไม่ใช่ชื่อ Instance ส่วนชื่อภายใน `instances` ต้องตรงกับชื่อ Instance ใน Netlist ระดับบน 

---

# ส่วนที่ 2 Functional Verification

## 13.9 สร้าง Testbench

สร้างไฟล์

```text
tb/tb_hier_system.sv
```

เนื้อหาไฟล์:

```systemverilog
`timescale 1ns/1ps
`default_nettype none

module tb_hier_system;

    localparam time CLK_PERIOD = 10ns;

    logic       clk_i;
    logic       rst_ni;
    logic       counter_enable_i;
    logic       accum_enable_i;
    logic [7:0] data_i;
    logic       select_i;
    logic [7:0] result_o;

    logic [7:0] expected_count;
    logic [7:0] expected_accum;

    hier_system dut (
        .clk_i            (clk_i),
        .rst_ni           (rst_ni),
        .counter_enable_i (counter_enable_i),
        .accum_enable_i   (accum_enable_i),
        .data_i           (data_i),
        .select_i         (select_i),
        .result_o         (result_o)
    );

    initial begin
        clk_i = 1'b0;
        forever #(CLK_PERIOD / 2) clk_i = ~clk_i;
    end

    task automatic check_result(
        input logic [7:0] expected,
        input string      test_name
    );
        #1;
        if (result_o !== expected) begin
            $error(
                "%s failed: expected=0x%02h actual=0x%02h",
                test_name,
                expected,
                result_o
            );
            $fatal(1);
        end else begin
            $display(
                "[PASS] %s expected=0x%02h actual=0x%02h",
                test_name,
                expected,
                result_o
            );
        end
    endtask

    initial begin
        $dumpfile("hier_system.vcd");
        $dumpvars(0, tb_hier_system);

        rst_ni           = 1'b0;
        counter_enable_i = 1'b0;
        accum_enable_i   = 1'b0;
        data_i           = 8'h00;
        select_i         = 1'b0;
        expected_count   = 8'h00;
        expected_accum   = 8'h00;

        repeat (3) @(posedge clk_i);
        rst_ni = 1'b1;

        // Counter test
        counter_enable_i = 1'b1;

        repeat (5) begin
            @(posedge clk_i);
            expected_count++;
        end

        counter_enable_i = 1'b0;
        select_i         = 1'b0;
        check_result(expected_count, "Counter output");

        // Accumulator test
        data_i         = 8'h03;
        accum_enable_i = 1'b1;

        repeat (4) begin
            @(posedge clk_i);
            expected_accum += data_i;
        end

        accum_enable_i = 1'b0;
        select_i       = 1'b1;
        check_result(expected_accum, "Accumulator output");

        // Reset test
        rst_ni = 1'b0;
        repeat (2) @(posedge clk_i);

        expected_count = 8'h00;
        expected_accum = 8'h00;

        select_i = 1'b0;
        check_result(expected_count, "Counter reset");

        select_i = 1'b1;
        check_result(expected_accum, "Accumulator reset");

        $display("[PASS] All hierarchical RTL tests completed");
        $finish;
    end

endmodule

`default_nettype wire
```

---

## 13.10 ตรวจสอบ RTL ด้วย Verilator

ใช้คำสั่ง

```bash
verilator \
    --binary \
    --timing \
    --trace \
    --top-module tb_hier_system \
    -Wall \
    -Wno-fatal \
    rtl/counter_macro.sv \
    rtl/accumulator_macro.sv \
    rtl/hier_system.sv \
    tb/tb_hier_system.sv
```

รัน Simulation:

```bash
./obj_dir/Vtb_hier_system
```

ผลลัพธ์ที่คาดหวัง:

```text
[PASS] Counter output expected=0x05 actual=0x05
[PASS] Accumulator output expected=0x0c actual=0x0c
[PASS] Counter reset expected=0x00 actual=0x00
[PASS] Accumulator reset expected=0x00 actual=0x00
[PASS] All hierarchical RTL tests completed
```

ตรวจสอบ Lint แยกต่างหาก:

```bash
verilator \
    --lint-only \
    --timing \
    -Wall \
    -Wno-fatal \
    rtl/counter_macro.sv \
    rtl/accumulator_macro.sv \
    rtl/hier_system.sv
```

ต้องแก้ไข Warning สำคัญก่อนเริ่ม Physical Design โดยเฉพาะ

- Undriven signal
- Unconnected port
- Width mismatch
- Multiple drivers
- Inferred latch
- Implicit net
- Circular combinational logic

---

# ส่วนที่ 3 Hardening Counter Macro

## 13.11 หลักการสร้าง Hard Macro

Hard Macro คือบล็อกที่ผ่าน Physical Implementation แล้ว และมีรูปร่าง ตำแหน่งขา Routing Obstruction และ Physical Geometry ที่แน่นอน

Macro อย่างน้อยต้องมี

- LEF สำหรับ Place-and-Route
- GDS สำหรับ Stream-Out และ Physical Verification

LibreLane ระบุว่า LEF และ GDS เป็น Macro Views หลักที่จำเป็น โดย LEF ทำหน้าที่เป็น Physical Interface ระบุขนาด ตำแหน่งขา และ Routing Obstruction ส่วน GDS เก็บรายละเอียด Layout สำหรับการผลิตและ Signoff 

Macro Views อื่นที่ควรเก็บ ได้แก่

| View | หน้าที่ |
|---|---|
| `.lef` | Physical abstraction |
| `.gds` | Full layout geometry |
| `.nl.v` หรือ `.gl.v` | Gate-level netlist |
| `.pnl.v` | Powered gate-level netlist |
| `.lib` | Timing model |
| `.spef` | Extracted parasitics |
| `.spice` | Transistor/netlist view สำหรับ LVS |
| `.sdf` | Delay annotation |
| `.json` | Yosys-readable representation |

---

## 13.12 สร้าง Pin Order สำหรับ Counter Macro

สร้างไฟล์

```text
blocks/counter_macro/pin_order.cfg
```

เนื้อหา:

```text
#N
clk_i
rst_ni

#E
count_o.*

#S
enable_i

#W
```

แนวคิดการวางขา:

```text
                 North
          clk_i     rst_ni
              +----------+
              |          |
    West      | counter  | count_o[7:0]   East
              | macro    |
              |          |
              +----------+
               enable_i
                 South
```

หลักการวาง Pin:

1. วาง Clock และ Reset ในด้านที่เชื่อมต่อกับ Top-Level ได้สะดวก
2. วาง Input และ Output คนละด้านเพื่อลดการไขว้ของสาย
3. วาง Bus Pins ต่อเนื่องกัน
4. หลีกเลี่ยงการกระจุกตัวของ Pin ในพื้นที่เล็กเกินไป
5. พิจารณาตำแหน่งของ Macro ที่ระดับบนตั้งแต่ก่อน Hardening
6. หลีกเลี่ยงการวาง Pin ในมุม Macro หากไม่จำเป็น
7. เว้น Routing Access ให้เพียงพอ

Pin Placement ของ Macro มีผลโดยตรงต่อ

- Top-Level congestion
- Wirelength
- Timing
- Routing detour
- Macro orientation
- Feedthrough requirement

---

## 13.13 สร้าง SDC สำหรับ Counter Macro

สร้างไฟล์

```text
blocks/counter_macro/constraints.sdc
```

เนื้อหา:

```tcl
create_clock \
    -name core_clk \
    -period 10.000 \
    [get_ports clk_i]

set_clock_uncertainty 0.250 [get_clocks core_clk]
set_clock_transition 0.150 [get_clocks core_clk]

set_input_delay  1.000 -clock core_clk [get_ports rst_ni]
set_input_delay  2.000 -clock core_clk [get_ports enable_i]

set_output_delay 2.000 -clock core_clk [get_ports count_o*]

set_load 0.033442 [get_ports count_o*]

set_false_path -from [get_ports rst_ni]
```

### ความหมายของ Constraint

| Constraint | ความหมาย |
|---|---|
| `create_clock` | สร้าง Clock Constraint |
| `set_clock_uncertainty` | Margin สำหรับ Clock Jitter และ Modeling |
| `set_clock_transition` | กำหนด Input Clock Slew |
| `set_input_delay` | Delay ก่อนสัญญาณเข้าสู่ Macro |
| `set_output_delay` | เวลาที่สงวนให้ระบบภายนอก |
| `set_load` | โหลดที่ต่อกับ Output |
| `set_false_path` | ตัด Timing Path ที่ไม่ต้องวิเคราะห์ |

### ข้อสำคัญเกี่ยวกับ Boundary Timing

Constraint ระดับ Macro ต้องสอดคล้องกับสภาวะที่ Macro จะพบเมื่อถูกนำไปใช้จริง

ตัวอย่างเช่น ถ้า Hardening Macro โดยสมมติว่า Input Delay เท่ากับ 2 ns แต่ในระบบระดับบนสัญญาณเดินทางถึงขา Macro ช้ากว่า 4 ns Macro อาจผ่าน Timing ตอนทำ Block-Level แต่ระบบระดับบนอาจเกิด Setup Violation

ในทางกลับกัน การตรวจสอบ Macro ด้วย Input Delay ที่ไม่สอดคล้องกับระบบจริงอาจซ่อน Hold Violation ที่ Boundary ได้ LibreLane จึงรองรับ Timing Views เช่น Liberty, Gate-Level Netlist และ SPEF เพื่อใช้วิเคราะห์ Macro ในระดับบนแทนการมองเป็น Black Box เพียงอย่างเดียว 

---

## 13.14 สร้าง `config.yaml` สำหรับ Counter Macro

สร้างไฟล์

```text
blocks/counter_macro/config.yaml
```

ตัวอย่างสำหรับ SKY130:

```yaml
DESIGN_NAME: counter_macro

VERILOG_FILES:
  - dir::../../rtl/counter_macro.sv

CLOCK_PORT: clk_i
CLOCK_PERIOD: 10.0

PNR_SDC_FILE: dir::constraints.sdc
SIGNOFF_SDC_FILE: dir::constraints.sdc

FP_PIN_ORDER_CFG: dir::pin_order.cfg

FP_SIZING: absolute
DIE_AREA: [0.0, 0.0, 120.0, 120.0]

CORE_AREA:
  - 10.0
  - 10.0
  - 110.0
  - 110.0

FP_CORE_UTIL: 35

PL_TARGET_DENSITY_PCT: 45

GRT_ALLOW_CONGESTION: false

RUN_HEURISTIC_DIODE_INSERTION: true

MAGIC_DRC:
  enabled: true

KLAYOUT_DRC:
  enabled: true

NETGEN_LVS:
  enabled: true
```

> ชื่อตัวแปรบางรายการอาจต่างกันตาม LibreLane และ PDK Version ที่ติดตั้ง ให้ใช้คำสั่งตรวจสอบ Configuration Variables ของ Environment ที่ใช้งานจริงก่อนเริ่ม Lab

---

## 13.15 รัน Counter Macro Flow

จากไดเรกทอรีรากของ Lab:

```bash
librelane \
    --pdk sky130A \
    blocks/counter_macro/config.yaml
```

หากใช้ Nix Environment:

```bash
nix-shell
```

หรือเข้าสู่ LibreLane Shell ตามวิธีติดตั้งของระบบ แล้วรัน:

```bash
librelane \
    --pdk sky130A \
    blocks/counter_macro/config.yaml
```

ผลลัพธ์จะอยู่ในลักษณะ

```text
blocks/counter_macro/runs/RUN_YYYY-MM-DD_HH-MM-SS/
```

ตรวจสอบ State ล่าสุด:

```bash
find blocks/counter_macro/runs \
    -type f \
    \( -name "*.gds" -o \
       -name "*.lef" -o \
       -name "*.lib" -o \
       -name "*.spef" -o \
       -name "*.nl.v" -o \
       -name "*.spice" \)
```

---

## 13.16 ตรวจสอบผลลัพธ์ Counter Macro

ตรวจสอบอย่างน้อยรายการต่อไปนี้

### 13.16.1 ตรวจสอบ GDS

```bash
find blocks/counter_macro/runs -name "*.gds"
```

เปิดด้วย KLayout:

```bash
klayout path/to/counter_macro.gds
```

ตรวจสอบว่า

- Standard cells อยู่ภายใน Core Area
- มี Power Rails
- มี Signal Routing ครบ
- ไม่มี Geometry ออกนอก Die
- Pin Labels ปรากฏถูกต้อง
- Metal Fill ถูกเพิ่มตาม Flow
- ไม่มีเซลล์ซ้อนกัน

### 13.16.2 ตรวจสอบ LEF

```bash
find blocks/counter_macro/runs -name "*.lef"
```

ตรวจสอบ Header:

```bash
grep -n \
    -E "MACRO|CLASS|ORIGIN|SIZE|PIN|OBS|END" \
    path/to/counter_macro.lef
```

ตัวอย่างข้อมูลที่ควรพบ:

```text
MACRO counter_macro
  CLASS BLOCK ;
  ORIGIN 0.000 0.000 ;
  SIZE 120.000 BY 120.000 ;

  PIN clk_i
  ...
  END clk_i

  PIN rst_ni
  ...
  END rst_ni

  PIN count_o[0]
  ...
  END count_o[0]

  OBS
  ...
END counter_macro
```

### 13.16.3 ตรวจสอบ Timing

ค้นหา Timing Report:

```bash
find blocks/counter_macro/runs \
    -type f \
    \( -iname "*timing*" -o \
       -iname "*setup*" -o \
       -iname "*hold*" \)
```

ตรวจสอบ

- Worst Setup Slack
- Worst Hold Slack
- Total Negative Slack
- Maximum Slew
- Maximum Capacitance
- Maximum Fanout
- Unconstrained Paths
- Clock Skew

เกณฑ์พื้นฐาน:

```text
WNS >= 0
TNS = 0
Setup violations = 0
Hold violations = 0
Unconstrained endpoints = 0
```

### 13.16.4 ตรวจสอบ DRC และ LVS

ตรวจสอบ Metrics:

```bash
find blocks/counter_macro/runs \
    -type f \
    \( -name "metrics.csv" -o \
       -name "metrics.json" -o \
       -iname "*drc*" -o \
       -iname "*lvs*" \)
```

เป้าหมาย:

```text
Magic DRC violations    = 0
KLayout DRC violations  = 0
LVS errors              = 0
Antenna violations      = 0
```

---

# ส่วนที่ 4 Hardening Accumulator Macro

## 13.17 สร้าง Pin Order สำหรับ Accumulator Macro

สร้างไฟล์

```text
blocks/accumulator_macro/pin_order.cfg
```

เนื้อหา:

```text
#N
clk_i
rst_ni

#E
accum_o.*

#S
enable_i

#W
data_i.*
```

แผนผัง:

```text
                clk_i   rst_ni
                     North
               +--------------+
 data_i[7:0]   | accumulator  |  accum_o[7:0]
    West ----->| macro        |------------> East
               |              |
               +--------------+
                   enable_i
                     South
```

---

## 13.18 สร้าง SDC สำหรับ Accumulator Macro

สร้างไฟล์

```text
blocks/accumulator_macro/constraints.sdc
```

เนื้อหา:

```tcl
create_clock \
    -name core_clk \
    -period 10.000 \
    [get_ports clk_i]

set_clock_uncertainty 0.250 [get_clocks core_clk]
set_clock_transition 0.150 [get_clocks core_clk]

set_input_delay 1.000 -clock core_clk [get_ports rst_ni]
set_input_delay 2.000 -clock core_clk [get_ports enable_i]
set_input_delay 2.000 -clock core_clk [get_ports data_i*]

set_output_delay 2.000 -clock core_clk [get_ports accum_o*]

set_load 0.033442 [get_ports accum_o*]

set_false_path -from [get_ports rst_ni]
```

---

## 13.19 สร้าง Configuration สำหรับ Accumulator Macro

สร้างไฟล์

```text
blocks/accumulator_macro/config.yaml
```

เนื้อหา:

```yaml
DESIGN_NAME: accumulator_macro

VERILOG_FILES:
  - dir::../../rtl/accumulator_macro.sv

CLOCK_PORT: clk_i
CLOCK_PERIOD: 10.0

PNR_SDC_FILE: dir::constraints.sdc
SIGNOFF_SDC_FILE: dir::constraints.sdc

FP_PIN_ORDER_CFG: dir::pin_order.cfg

FP_SIZING: absolute
DIE_AREA: [0.0, 0.0, 150.0, 130.0]

CORE_AREA:
  - 10.0
  - 10.0
  - 140.0
  - 120.0

FP_CORE_UTIL: 35

PL_TARGET_DENSITY_PCT: 45

GRT_ALLOW_CONGESTION: false

RUN_HEURISTIC_DIODE_INSERTION: true

MAGIC_DRC:
  enabled: true

KLAYOUT_DRC:
  enabled: true

NETGEN_LVS:
  enabled: true
```

---

## 13.20 รัน Accumulator Macro Flow

```bash
librelane \
    --pdk sky130A \
    blocks/accumulator_macro/config.yaml
```

ตรวจสอบผลลัพธ์:

```bash
find blocks/accumulator_macro/runs \
    -type f \
    \( -name "*.gds" -o \
       -name "*.lef" -o \
       -name "*.lib" -o \
       -name "*.spef" -o \
       -name "*.nl.v" -o \
       -name "*.spice" \)
```

เปิด GDS:

```bash
klayout path/to/accumulator_macro.gds
```

ตรวจสอบ DRC, LVS, Timing และ Pin Accessibility เช่นเดียวกับ Counter Macro

---

# ส่วนที่ 5 การรวบรวม Macro Views

## 13.21 เหตุผลที่ต้องแยก Macro Views ออกจาก Run Directory

ไม่ควรอ้างอิงไฟล์ Macro โดยตรงจากไดเรกทอรีที่มี Timestamp เช่น

```text
runs/RUN_2026-07-20_10-30-10/final/gds/counter_macro.gds
```

เนื่องจากเมื่อรันใหม่ Path จะเปลี่ยน ทำให้ Top-Level Configuration ไม่สามารถนำกลับมาใช้ซ้ำได้

ควรคัดลอกผลลัพธ์ที่ผ่านการตรวจสอบแล้วไปเก็บในตำแหน่งคงที่:

```text
macros/counter_macro/
macros/accumulator_macro/
```

---

## 13.22 สร้าง Script รวบรวม Counter Macro

สร้างไฟล์

```text
scripts/collect_counter_macro.sh
```

เนื้อหา:

```bash
#!/usr/bin/env bash

set -euo pipefail

RUN_DIR="${1:-}"

if [[ -z "${RUN_DIR}" ]]; then
    echo "Usage: $0 <counter_macro_run_directory>"
    exit 1
fi

if [[ ! -d "${RUN_DIR}" ]]; then
    echo "Error: run directory not found: ${RUN_DIR}"
    exit 1
fi

DEST="macros/counter_macro"

mkdir -p \
    "${DEST}/gds" \
    "${DEST}/lef" \
    "${DEST}/lib" \
    "${DEST}/netlist" \
    "${DEST}/spef" \
    "${DEST}/spice"

copy_first_match() {
    local pattern="$1"
    local destination="$2"

    local source_file
    source_file="$(find "${RUN_DIR}" -type f -name "${pattern}" | head -n 1)"

    if [[ -n "${source_file}" ]]; then
        cp -v "${source_file}" "${destination}"
    else
        echo "Warning: no file matching ${pattern}"
    fi
}

copy_first_match "counter_macro.gds" \
    "${DEST}/gds/counter_macro.gds"

copy_first_match "counter_macro.lef" \
    "${DEST}/lef/counter_macro.lef"

copy_first_match "counter_macro*.lib" \
    "${DEST}/lib/counter_macro.lib"

copy_first_match "counter_macro*.spef" \
    "${DEST}/spef/counter_macro.spef"

copy_first_match "counter_macro*.nl.v" \
    "${DEST}/netlist/counter_macro.nl.v"

copy_first_match "counter_macro*.pnl.v" \
    "${DEST}/netlist/counter_macro.pnl.v"

copy_first_match "counter_macro*.spice" \
    "${DEST}/spice/counter_macro.spice"

echo "Counter macro views collected in ${DEST}"
```

เพิ่มสิทธิ์ Execute:

```bash
chmod +x scripts/collect_counter_macro.sh
```

ใช้งาน:

```bash
./scripts/collect_counter_macro.sh \
    blocks/counter_macro/runs/RUN_YYYY-MM-DD_HH-MM-SS
```

---

## 13.23 สร้าง Script รวบรวม Accumulator Macro

สร้างไฟล์

```text
scripts/collect_accumulator_macro.sh
```

เนื้อหา:

```bash
#!/usr/bin/env bash

set -euo pipefail

RUN_DIR="${1:-}"

if [[ -z "${RUN_DIR}" ]]; then
    echo "Usage: $0 <accumulator_macro_run_directory>"
    exit 1
fi

if [[ ! -d "${RUN_DIR}" ]]; then
    echo "Error: run directory not found: ${RUN_DIR}"
    exit 1
fi

DEST="macros/accumulator_macro"

mkdir -p \
    "${DEST}/gds" \
    "${DEST}/lef" \
    "${DEST}/lib" \
    "${DEST}/netlist" \
    "${DEST}/spef" \
    "${DEST}/spice"

copy_first_match() {
    local pattern="$1"
    local destination="$2"

    local source_file
    source_file="$(find "${RUN_DIR}" -type f -name "${pattern}" | head -n 1)"

    if [[ -n "${source_file}" ]]; then
        cp -v "${source_file}" "${destination}"
    else
        echo "Warning: no file matching ${pattern}"
    fi
}

copy_first_match "accumulator_macro.gds" \
    "${DEST}/gds/accumulator_macro.gds"

copy_first_match "accumulator_macro.lef" \
    "${DEST}/lef/accumulator_macro.lef"

copy_first_match "accumulator_macro*.lib" \
    "${DEST}/lib/accumulator_macro.lib"

copy_first_match "accumulator_macro*.spef" \
    "${DEST}/spef/accumulator_macro.spef"

copy_first_match "accumulator_macro*.nl.v" \
    "${DEST}/netlist/accumulator_macro.nl.v"

copy_first_match "accumulator_macro*.pnl.v" \
    "${DEST}/netlist/accumulator_macro.pnl.v"

copy_first_match "accumulator_macro*.spice" \
    "${DEST}/spice/accumulator_macro.spice"

echo "Accumulator macro views collected in ${DEST}"
```

เพิ่มสิทธิ์:

```bash
chmod +x scripts/collect_accumulator_macro.sh
```

รัน:

```bash
./scripts/collect_accumulator_macro.sh \
    blocks/accumulator_macro/runs/RUN_YYYY-MM-DD_HH-MM-SS
```

---

## 13.24 ตรวจสอบ Macro Views

สร้างไฟล์

```text
scripts/check_macro_views.sh
```

เนื้อหา:

```bash
#!/usr/bin/env bash

set -euo pipefail

required_files=(
    "macros/counter_macro/gds/counter_macro.gds"
    "macros/counter_macro/lef/counter_macro.lef"
    "macros/accumulator_macro/gds/accumulator_macro.gds"
    "macros/accumulator_macro/lef/accumulator_macro.lef"
)

optional_files=(
    "macros/counter_macro/lib/counter_macro.lib"
    "macros/counter_macro/netlist/counter_macro.nl.v"
    "macros/counter_macro/spef/counter_macro.spef"
    "macros/accumulator_macro/lib/accumulator_macro.lib"
    "macros/accumulator_macro/netlist/accumulator_macro.nl.v"
    "macros/accumulator_macro/spef/accumulator_macro.spef"
)

status=0

echo "Checking required macro views..."

for file in "${required_files[@]}"; do
    if [[ -s "${file}" ]]; then
        echo "[PASS] ${file}"
    else
        echo "[FAIL] ${file}"
        status=1
    fi
done

echo
echo "Checking optional timing and verification views..."

for file in "${optional_files[@]}"; do
    if [[ -s "${file}" ]]; then
        echo "[PASS] ${file}"
    else
        echo "[WARN] ${file} not found"
    fi
done

exit "${status}"
```

เพิ่มสิทธิ์และรัน:

```bash
chmod +x scripts/check_macro_views.sh
./scripts/check_macro_views.sh
```

ผลลัพธ์ที่ต้องได้อย่างน้อย:

```text
[PASS] macros/counter_macro/gds/counter_macro.gds
[PASS] macros/counter_macro/lef/counter_macro.lef
[PASS] macros/accumulator_macro/gds/accumulator_macro.gds
[PASS] macros/accumulator_macro/lef/accumulator_macro.lef
```

LibreLane กำหนดให้ Macro แต่ละรายการต้องมี GDS และ LEF อย่างน้อยหนึ่งไฟล์ หากขาด View ใด View หนึ่ง การประกาศ Macro จะไม่สมบูรณ์ 

---

# ส่วนที่ 6 การเตรียม Top-Level Design

## 13.25 การ Black-Box Macro ในระดับบน

ในระดับบน ไม่ควรให้ Yosys สังเคราะห์ RTL ภายใน Macro ซ้ำ เนื่องจาก Macro ได้ผ่าน Physical Implementation แล้ว

Top-Level Synthesis ต้องมอง Macro เป็น Black Box โดยอาศัยอย่างใดอย่างหนึ่ง เช่น

- Verilog Header
- Gate-Level Netlist
- Powered Netlist
- Liberty Model

ตัวอย่าง Verilog Header:

```systemverilog
(* blackbox *)
module counter_macro (
    input  logic       clk_i,
    input  logic       rst_ni,
    input  logic       enable_i,
    output logic [7:0] count_o
);
endmodule
```

และ

```systemverilog
(* blackbox *)
module accumulator_macro (
    input  logic       clk_i,
    input  logic       rst_ni,
    input  logic       enable_i,
    input  logic [7:0] data_i,
    output logic [7:0] accum_o
);
endmodule
```

อย่างไรก็ตาม หาก LibreLane ได้รับ Netlist หรือ Header ผ่าน `MACROS` อย่างถูกต้อง อาจไม่จำเป็นต้องเพิ่ม Header ซ้ำใน `VERILOG_FILES`

ข้อควรระวังคือห้ามส่งทั้ง

```text
rtl/counter_macro.sv
```

และ Physical Macro ชื่อ `counter_macro` เข้า Top-Level Synthesis พร้อมกันในลักษณะที่ทำให้ Yosys สังเคราะห์โมดูลภายในอีกครั้ง

---

## 13.26 สร้าง Top-Level Pin Order

สร้างไฟล์

```text
top/pin_order.cfg
```

เนื้อหา:

```text
#N
clk_i
rst_ni

#E
result_o.*

#S
counter_enable_i
accum_enable_i
select_i

#W
data_i.*
```

แผนผัง:

```text
                    clk_i   rst_ni
                         North
                +--------------------+
 data_i[7:0]    |                    | result_o[7:0]
       West --->|    hier_system     |------------> East
                |                    |
                +--------------------+
                  enables, select_i
                         South
```

---

## 13.27 สร้าง Top-Level SDC

สร้างไฟล์

```text
top/constraints.sdc
```

เนื้อหา:

```tcl
create_clock \
    -name core_clk \
    -period 10.000 \
    [get_ports clk_i]

set_clock_uncertainty 0.250 [get_clocks core_clk]
set_clock_transition 0.150 [get_clocks core_clk]

set_input_delay 2.000 \
    -clock core_clk \
    [get_ports counter_enable_i]

set_input_delay 2.000 \
    -clock core_clk \
    [get_ports accum_enable_i]

set_input_delay 2.000 \
    -clock core_clk \
    [get_ports data_i*]

set_input_delay 2.000 \
    -clock core_clk \
    [get_ports select_i]

set_output_delay 4.000 \
    -clock core_clk \
    [get_ports result_o*]

set_load 0.033442 [get_ports result_o*]

set_false_path -from [get_ports rst_ni]
```

---

# ส่วนที่ 7 Macro Placement Planning

## 13.28 หลักการวาง Macro

Macro Placement เป็นหนึ่งในขั้นตอนสำคัญที่สุดของ Hierarchical Physical Design เพราะมีผลต่อ

- Wirelength
- Routing congestion
- Timing
- Clock distribution
- Power distribution
- Pin accessibility
- IR drop
- Placement area ของ Standard Cells
- Feedthrough routing
- Routability หลัง CTS

OpenROAD มี Hier-RTLMP ซึ่งใช้ลำดับชั้นและ Data Flow ของ RTL เพื่อสร้าง Physical Clustering และวาง Macro แบบหลายระดับ โดยสามารถกำหนด Halo, Fence, Target Utilization และน้ำหนักด้าน Wirelength หรือ Boundary ได้ 

ใน Lab นี้จะใช้ Manual Macro Placement เพื่อให้ผู้เรียนเห็นความสัมพันธ์ระหว่าง

```text
RTL hierarchy
      ↓
Macro connectivity
      ↓
Macro pin direction
      ↓
Physical placement
      ↓
Routing congestion
      ↓
Timing result
```

---

## 13.29 กำหนดขนาด Top-Level Die

ขนาด Macro โดยประมาณ:

```text
counter_macro:
    120 µm × 120 µm

accumulator_macro:
    150 µm × 130 µm
```

พื้นที่ Macro รวม:

```text
120 × 120 + 150 × 130
= 14,400 + 19,500
= 33,900 µm²
```

แต่ Top-Level Die ต้องมีพื้นที่สำหรับ

- Standard cells
- Routing channels
- Macro halos
- Clock buffers
- Tie cells
- Tap cells
- Decap/filler cells
- PDN straps
- IO pin access
- Timing repair cells

กำหนด Top-Level Die เริ่มต้น:

```text
DIE_AREA = 400 µm × 300 µm
```

พื้นที่รวม:

```text
400 × 300 = 120,000 µm²
```

จึงมีพื้นที่เพียงพอสำหรับทดลองวาง Macro สองตัวและ Top-Level Logic

---

## 13.30 แผน Macro Placement

กำหนดตำแหน่งเริ่มต้น:

```text
u_counter_macro:
    location    = (40, 90)
    orientation = N

u_accumulator_macro:
    location    = (210, 85)
    orientation = N
```

ภาพแนวคิด:

```text
Top-Level Die: 400 µm × 300 µm

(0,300)
  +--------------------------------------------------+
  |                                                  |
  |      +----------------+      +----------------+  |
  |      |                |      |                |  |
  |      | counter_macro  |      | accumulator    |  |
  |      |                |      | macro          |  |
  |      +----------------+      +----------------+  |
  |                                                  |
  |              Standard-cell region                |
  |                                                  |
  +--------------------------------------------------+
(0,0)                                           (400,0)
```

### เหตุผลของตำแหน่ง

- `data_i` อยู่ด้านซ้าย และ Pin `data_i` ของ Accumulator อยู่ด้าน West
- `result_o` อยู่ด้านขวา
- Output ของ Macro ทั้งสองหันเข้าสู่พื้นที่ Glue Logic
- มีช่องว่างระหว่าง Macro สำหรับ MUX และ Buffer
- Clock และ Reset Pins อยู่ด้าน North และสามารถกระจายจากด้านบน
- มีพื้นที่ด้านล่างสำหรับ Standard Cells และ CTS Buffers

---

## 13.31 Macro Halo และ Channel Spacing

Macro Halo คือพื้นที่ห้ามวาง Standard Cell รอบ Macro

ตัวอย่าง:

```text
+--------------------------------+
|           Macro Halo           |
|    +----------------------+    |
|    |                      |    |
|    |      Hard Macro      |    |
|    |                      |    |
|    +----------------------+    |
|                                |
+--------------------------------+
```

Halo ช่วยให้มีพื้นที่สำหรับ

- Routing เข้าออก Macro Pins
- CTS Buffer ใกล้ Macro Boundary
- Signal Buffering
- DRC spacing
- Power straps
- ลด Routing Pin Access Congestion

ค่าเริ่มต้นสำหรับ Lab:

```text
Horizontal halo = 10 µm
Vertical halo   = 10 µm
```

หาก Macro มี Pin จำนวนมากหรือ Bus ขนาดใหญ่ อาจเพิ่มเป็น

```text
15–25 µm
```

Channel ระหว่าง Macro ควรเพียงพอสำหรับ

- Signal wires
- Clock wires
- Power straps
- Buffer rows
- Routing detours

ไม่ควรวาง Macro ชิดกันจนเหลือช่องแคบ เนื่องจาก Global Router อาจประเมินว่าเดินสายได้ แต่ Detailed Router ไม่สามารถสร้างเส้นทางที่ผ่าน DRC ได้

---

# ส่วนที่ 8 การประกาศ Macro ใน `config.yaml`

## 13.32 รูปแบบของ `MACROS`

LibreLane ใช้ตัวแปร `MACROS` เป็น Dictionary โดย Key ระดับแรกคือชื่อ Macro และภายในประกอบด้วยรายการ Physical/Timing Views รวมถึงชื่อ Instance ตำแหน่ง และ Orientation 

ตัวอย่างโครงสร้าง:

```yaml
MACROS:
  macro_module_name:
    instances:
      instance_name:
        location: [x, y]
        orientation: N

    gds:
      - path/to/macro.gds

    lef:
      - path/to/macro.lef

    nl:
      - path/to/macro.nl.v

    lib:
      "*_tt_*":
        - path/to/macro.lib

    spef:
      "*_tt_*":
        - path/to/macro.spef
```

---

## 13.33 สร้าง Top-Level `config.yaml`

สร้างไฟล์

```text
top/config.yaml
```

ตัวอย่าง:

```yaml
DESIGN_NAME: hier_system

VERILOG_FILES:
  - dir::../rtl/hier_system.sv

CLOCK_PORT: clk_i
CLOCK_PERIOD: 10.0

PNR_SDC_FILE: dir::constraints.sdc
SIGNOFF_SDC_FILE: dir::constraints.sdc

FP_PIN_ORDER_CFG: dir::pin_order.cfg

FP_SIZING: absolute
DIE_AREA: [0.0, 0.0, 400.0, 300.0]

CORE_AREA:
  - 10.0
  - 10.0
  - 390.0
  - 290.0

FP_CORE_UTIL: 35

PL_TARGET_DENSITY_PCT: 45

MACRO_PLACEMENT_CFG: dir::macro_placement.cfg

MACRO_PLACEMENT_HALO:
  - 10.0
  - 10.0

MACRO_PLACEMENT_CHANNEL:
  - 20.0
  - 20.0

MACROS:
  counter_macro:
    instances:
      u_counter_macro:
        location: [40.0, 90.0]
        orientation: N

    gds:
      - dir::../macros/counter_macro/gds/counter_macro.gds

    lef:
      - dir::../macros/counter_macro/lef/counter_macro.lef

    nl:
      - dir::../macros/counter_macro/netlist/counter_macro.nl.v

    lib:
      "*_tt_*":
        - dir::../macros/counter_macro/lib/counter_macro.lib

    spef:
      "*_tt_*":
        - dir::../macros/counter_macro/spef/counter_macro.spef

  accumulator_macro:
    instances:
      u_accumulator_macro:
        location: [210.0, 85.0]
        orientation: N

    gds:
      - dir::../macros/accumulator_macro/gds/accumulator_macro.gds

    lef:
      - dir::../macros/accumulator_macro/lef/accumulator_macro.lef

    nl:
      - dir::../macros/accumulator_macro/netlist/accumulator_macro.nl.v

    lib:
      "*_tt_*":
        - dir::../macros/accumulator_macro/lib/accumulator_macro.lib

    spef:
      "*_tt_*":
        - dir::../macros/accumulator_macro/spef/accumulator_macro.spef

STA_MACRO_PRIORITIZE_NL: true

GRT_ALLOW_CONGESTION: false

RUN_HEURISTIC_DIODE_INSERTION: true

MAGIC_DRC:
  enabled: true

KLAYOUT_DRC:
  enabled: true

NETGEN_LVS:
  enabled: true
```

### หมายเหตุเรื่อง Timing Corners

ตัวอย่าง

```yaml
lib:
  "*_tt_*":
    - dir::macro.lib
```

หมายถึงให้ใช้ Liberty View กับ Timing Corner ที่ชื่อมี `_tt_`

LibreLane รองรับ Wildcard Matching สำหรับจับคู่ Macro Liberty/SPEF กับ Timing Corner เช่น Pattern `*_tt_025C_1v80` สามารถจับคู่ Corner ที่มี Prefix แบบ `min_`, `max_` และ `nom_` ได้ 

ชื่อ Corner จริงขึ้นกับ PDK ดังนั้นควรตรวจสอบ Corner Names ก่อนกำหนด Pattern

---

## 13.34 กรณีไม่มี Liberty หรือ SPEF

หาก Lab Environment ไม่ได้สร้าง `.lib` หรือ `.spef` ของ Macro สามารถเริ่มต้นด้วย Views ขั้นต่ำ:

```yaml
MACROS:
  counter_macro:
    instances:
      u_counter_macro:
        location: [40.0, 90.0]
        orientation: N

    gds:
      - dir::../macros/counter_macro/gds/counter_macro.gds

    lef:
      - dir::../macros/counter_macro/lef/counter_macro.lef

    nl:
      - dir::../macros/counter_macro/netlist/counter_macro.nl.v
```

หรือใช้เพียง GDS, LEF และ Verilog Header สำหรับการทดลองเบื้องต้น

ข้อจำกัดคือ Timing Analysis อาจ

- วิเคราะห์ Macro เป็น Black Box
- ไม่เห็น Internal Timing Arc
- ไม่เห็น Internal Parasitics
- ตรวจสอบ Boundary Timing ได้ไม่สมบูรณ์

จึงไม่ควรใช้ผลดังกล่าวเป็น Signoff Timing สำหรับวงจรจริง

---

# ส่วนที่ 9 Macro Placement File

## 13.35 สร้าง `macro_placement.cfg`

สร้างไฟล์

```text
top/macro_placement.cfg
```

รูปแบบทั่วไป:

```text
u_counter_macro       40.0   90.0   N
u_accumulator_macro  210.0   85.0   N
```

ความหมาย:

```text
<instance-name> <x-coordinate> <y-coordinate> <orientation>
```

Orientation ที่พบบ่อย:

| Orientation | ความหมาย |
|---|---|
| `N` | ไม่หมุน |
| `S` | หมุน 180 องศา |
| `E` | หมุน 90 องศา |
| `W` | หมุน 270 องศา |
| `FN` | Mirror ตามแกน Y |
| `FS` | Mirror และหมุน |
| `FE` | Mirror พร้อม Orientation East |
| `FW` | Mirror พร้อม Orientation West |

### ข้อควรระวัง

เมื่อหมุนหรือ Mirror Macro ตำแหน่ง Pin จะเปลี่ยนตาม Orientation ด้วย

ตัวอย่าง:

```text
Orientation N

Input pins                         Output pins
    ---> +-------------------+ --->
         |       Macro       |
         +-------------------+
```

เมื่อใช้ Orientation `S`:

```text
Output pins                        Input pins
    <--- +-------------------+ <---
         |       Macro       |
         +-------------------+
```

จึงต้องพิจารณา Pin Location จาก LEF ร่วมกับ Orientation เสมอ

---

# ส่วนที่ 10 ตรวจสอบ Top-Level Configuration

## 13.36 ตรวจสอบชื่อ Macro

ตรวจสอบชื่อใน LEF:

```bash
grep "^MACRO" \
    macros/counter_macro/lef/counter_macro.lef

grep "^MACRO" \
    macros/accumulator_macro/lef/accumulator_macro.lef
```

ผลลัพธ์ต้องเป็น:

```text
MACRO counter_macro
MACRO accumulator_macro
```

ตรวจสอบชื่อโมดูลใน Netlist:

```bash
grep -n "^module" \
    macros/counter_macro/netlist/counter_macro.nl.v

grep -n "^module" \
    macros/accumulator_macro/netlist/accumulator_macro.nl.v
```

ตรวจสอบชื่อ Instance ใน RTL:

```bash
grep -n \
    -E "u_counter_macro|u_accumulator_macro" \
    rtl/hier_system.sv
```

ชื่อทั้งสี่ตำแหน่งต้องสอดคล้องกัน:

```text
RTL module name
LEF MACRO name
Netlist module name
MACROS dictionary key
```

และ

```text
RTL instance name
MACROS.instances key
macro_placement.cfg instance name
```

---

## 13.37 ตรวจสอบ Port Consistency

แสดง Port ของ Top-Level RTL:

```bash
grep -n \
    -E "input|output|counter_macro|accumulator_macro" \
    rtl/hier_system.sv
```

แสดง Pin ใน LEF:

```bash
grep -n "^[[:space:]]*PIN " \
    macros/counter_macro/lef/counter_macro.lef

grep -n "^[[:space:]]*PIN " \
    macros/accumulator_macro/lef/accumulator_macro.lef
```

ต้องตรวจสอบว่า

- ชื่อ Pin ตรงกัน
- ตัวพิมพ์เล็ก/ใหญ่ตรงกัน
- Width ของ Bus ตรงกัน
- Bit Ordering ตรงกัน
- Power Pins ตรงกับรูปแบบของ PDK
- ไม่มี Pin หาย
- ไม่มี Pin เกิน

ตัวอย่างปัญหา:

```text
RTL:
count_o[7:0]

LEF:
count[7:0]
```

ชื่อไม่ตรงกัน ทำให้ Top-Level Netlist ไม่สามารถเชื่อมกับ Physical Macro Pins ได้อย่างถูกต้อง

---

## 13.38 ตรวจสอบไฟล์ก่อนรัน

```bash
test -f rtl/hier_system.sv
test -f top/config.yaml
test -f top/constraints.sdc
test -f top/pin_order.cfg
test -f top/macro_placement.cfg

./scripts/check_macro_views.sh
```

ตรวจสอบ YAML Syntax:

```bash
python3 - <<'PY'
from pathlib import Path
import yaml

config_file = Path("top/config.yaml")

with config_file.open("r", encoding="utf-8") as stream:
    config = yaml.safe_load(stream)

print("YAML syntax: PASS")
print("DESIGN_NAME:", config.get("DESIGN_NAME"))
print("Macros:", list(config.get("MACROS", {}).keys()))
PY
```

ผลลัพธ์:

```text
YAML syntax: PASS
DESIGN_NAME: hier_system
Macros: ['counter_macro', 'accumulator_macro']
```

---

# ส่วนที่ 11 รัน Top-Level Hierarchical Flow

## 13.39 เริ่ม Top-Level Flow

รัน:

```bash
librelane \
    --pdk sky130A \
    top/config.yaml
```

OpenROAD Physical Design Flow โดยทั่วไปประกอบด้วย Floorplan, Macro/Standard-Cell Placement, Detailed Placement, Clock Tree Synthesis, Timing Optimization, Global Routing, Detailed Routing, Parasitic Extraction และ Physical Verification 

สำหรับ Hierarchical Design ให้สังเกต Log ในขั้นตอนสำคัญต่อไปนี้

```text
1. Verilog hierarchy checking
2. Macro view loading
3. Synthesis
4. Floorplan initialization
5. Macro placement
6. PDN generation
7. Global placement
8. Detailed placement
9. CTS
10. Global routing
11. Detailed routing
12. Parasitic extraction
13. STA
14. GDS stream-out
15. DRC
16. LVS
17. Antenna checking
```

---

## 13.40 สิ่งที่ควรพบใน Synthesis Log

ตรวจสอบว่า Macro ถูกมองเป็น Black Box หรือ Library Cell:

```text
counter_macro
accumulator_macro
```

ไม่ควรเห็น Internal Registers ของ Macro ถูกสังเคราะห์เป็น Standard Cells ใน Top-Level Netlist อีกครั้ง

ตรวจสอบ Netlist หลัง Synthesis:

```bash
grep -R \
    -n "u_counter_macro" \
    top/runs/*/final 2>/dev/null

grep -R \
    -n "u_accumulator_macro" \
    top/runs/*/final 2>/dev/null
```

ควรยังพบ Instance:

```verilog
counter_macro u_counter_macro (...);

accumulator_macro u_accumulator_macro (...);
```

หาก Instance หาย อาจเกิดจาก

- Macro RTL ถูก Flatten
- Macro ถูก Optimize ทิ้ง
- Output ของ Macro ไม่ได้ใช้งาน
- Black-Box Declaration ไม่สมบูรณ์
- ชื่อโมดูลไม่ตรง
- Netlist ของ Macro ไม่ถูกโหลด

---

# ส่วนที่ 12 ตรวจสอบ Floorplan

## 13.41 เปิด Floorplan ด้วย OpenROAD GUI

ค้นหา OpenDB หรือ DEF หลัง Macro Placement:

```bash
find top/runs \
    -type f \
    \( -name "*.odb" -o -name "*.def" \) \
    | sort
```

เปิด State ที่เหมาะสม:

```bash
openroad -gui path/to/floorplan.odb
```

หรือใช้ LibreLane Interactive Mode ตาม Environment ที่ติดตั้ง

ตรวจสอบ

1. ขนาด Die และ Core
2. ตำแหน่ง Macro
3. Orientation
4. Overlap
5. Macro Halo
6. Standard-cell rows
7. IO pins
8. PDN straps
9. Routing channels
10. Pin accessibility

---

## 13.42 Checklist สำหรับ Macro Placement

### ตำแหน่ง

- Macro อยู่ภายใน Core Area
- Macro ไม่ทับ Core Boundary
- Macro ไม่ทับ Macro อื่น
- Macro ไม่ทับ IO Pin Region
- มีระยะห่างจาก PDN Ring
- มีพื้นที่สำหรับ Standard Cells

### Orientation

- Pin ของ Macro หันไปทาง Logic ที่เชื่อมต่อ
- Clock Pin สามารถเข้าถึงได้
- Power Pins สอดคล้องกับ PDN
- Bus Pins ไม่หันเข้าหา Die Boundary โดยไม่จำเป็น

### Routing

- มี Channel ระหว่าง Macro
- ไม่มี Narrow Channel
- ไม่มี Notch Area ที่วาง Cell ไม่ได้
- Routing Access ของ Pin ไม่ถูกปิด
- ไม่มี Macro ขวางเส้นทางหลักระหว่าง IO กับ Logic

### Timing

- Macro ที่สื่อสารกันบ่อยอยู่ใกล้กัน
- Critical data path มี Wirelength สั้น
- Clock source ไม่อยู่ไกลจาก Macro เกินไป
- Glue logic มีพื้นที่อยู่ใกล้ Macro Boundary

---

# ส่วนที่ 13 ตรวจสอบ Power Distribution Network

## 13.43 ความท้าทายของ PDN ใน Hierarchical Design

Hard Macro มี Power Pins ของตัวเอง เช่น

```text
VPWR
VGND
VDD
VSS
```

Top-Level PDN ต้องเชื่อม Power Network ของระบบเข้ากับ Power Pins ของ Macro

แนวทางทั่วไป:

```text
Top-level power ring
        │
        ├── Vertical straps
        │        │
        │        └── Macro power pins
        │
        └── Horizontal straps
                 │
                 └── Standard-cell rails
```

ตรวจสอบว่า

- ชื่อ Power Net ตรงกัน
- Macro LEF ประกาศ Power Pin ถูกต้อง
- Top-Level Netlist มีการเชื่อม Power Pin หาก Flow ต้องการ
- PDN straps ตัดผ่านหรือต่อถึง Macro Pin
- ไม่มี Floating Power Pin
- ไม่มี Unconnected Standard-Cell Rails
- Macro Obstruction ไม่ปิดกั้น PDN

---

## 13.44 ตรวจสอบ Power Pins ใน LEF

```bash
grep -n \
    -A 12 \
    -E "PIN (VPWR|VGND|VDD|VSS)" \
    macros/counter_macro/lef/counter_macro.lef
```

ตรวจสอบค่า:

```text
DIRECTION INOUT
USE POWER
```

หรือ

```text
DIRECTION INOUT
USE GROUND
```

ตรวจสอบ Accumulator Macro เช่นเดียวกัน:

```bash
grep -n \
    -A 12 \
    -E "PIN (VPWR|VGND|VDD|VSS)" \
    macros/accumulator_macro/lef/accumulator_macro.lef
```

---

## 13.45 ปัญหา PDN ที่พบบ่อย

### ปัญหา: Macro Power Pin ไม่เชื่อมต่อ

อาการ:

```text
Unconnected VPWR
Unconnected VGND
PSM warning
Floating power pin
```

สาเหตุที่เป็นไปได้:

- ชื่อ Power Pin ไม่ตรงกับ PDK
- Powered Netlist ไม่มี Power Connection
- Macro LEF ไม่มี `USE POWER` หรือ `USE GROUND`
- PDN Macro Hook ไม่ถูกกำหนด
- Straps ไม่ตัดผ่าน Macro Pins
- Macro Orientation ทำให้ Pin อยู่ผิดตำแหน่ง
- Macro Obstruction ปิดกั้น Power Routing

แนวทางแก้:

1. ตรวจสอบ LEF Power Pins
2. ตรวจสอบ Powered Netlist
3. ตรวจสอบชื่อ Net ระดับบน
4. เปิด GUI ดู PDN straps
5. ตรวจสอบ Macro Orientation
6. ปรับ PDN Configuration
7. รัน PDN Generation ใหม่

---

# ส่วนที่ 14 Placement และ Congestion Analysis

## 13.46 ตรวจสอบ Standard-Cell Placement

หลัง Global Placement ให้ตรวจสอบ

- Cells ไม่กระจุกตัวที่ Pin ของ Macro
- Buffer ไม่ถูกวางใน Channel ที่แคบ
- ไม่มีพื้นที่ Density สูงเฉพาะจุด
- Glue Logic อยู่ใกล้ Macro ที่เกี่ยวข้อง
- ไม่มี Cell ถูกบีบระหว่าง Macro กับ Core Boundary
- Macro Halo ถูกเคารพ

OpenROAD ใช้ Placement, Routing Estimation และ Timing Analysis ร่วมกันในหลายขั้นตอนเพื่อปรับปรุง Routability และ Timing โดยการวางตำแหน่งที่ดีมีผลโดยตรงต่อ PPA และลดจำนวนรอบแก้ไขภายหลัง

---

## 13.47 วิเคราะห์ Congestion

Congestion เกิดเมื่อความต้องการใช้ Routing Track สูงกว่าความจุของพื้นที่

```text
Routing demand > Routing capacity
```

บริเวณที่เสี่ยง:

```text
1. หน้า Macro Pin จำนวนมาก
2. ช่องระหว่าง Macro
3. Macro กับ Core Boundary
4. บริเวณ Top-Level IO Pins
5. Clock trunk crossing
6. Bus crossing หลายชุด
7. Power straps หนาแน่น
```

อาการใน Log:

```text
Routing congestion detected
Overflow remains
Global routing failed
Insufficient routing resources
Detailed route DRC violations
```

แนวทางแก้:

1. เพิ่มระยะระหว่าง Macro
2. เพิ่ม Halo
3. ย้าย Macro ให้ Pin หันเข้าหา Logic
4. ขยาย Die/Core Area
5. ลด Placement Density
6. กระจาย IO Pins
7. เปลี่ยน Orientation
8. ลดจำนวน Bus ที่ผ่านช่องแคบ
9. ปรับ PDN pitch หรือ width อย่างระมัดระวัง
10. เพิ่ม Routing Layer หาก PDK และ Flow รองรับ

---

# ส่วนที่ 15 Clock Tree Synthesis

## 13.48 Clock Distribution ใน Hierarchical Design

Clock ระดับบนต้องเดินทางไปยัง

- Top-Level Registers
- Counter Macro Clock Pin
- Accumulator Macro Clock Pin

```text
                    Clock input
                         │
                    Clock buffer
                         │
             +-----------+-----------+
             │           │           │
       Top registers  Counter     Accumulator
                       macro         macro
```

มี Clock Tree สองระดับในเชิงกายภาพ:

```text
Top-Level Clock Tree
        │
        └── Macro Clock Pin
                  │
                  └── Internal Macro Clock Tree
```

Clock Tree ภายใน Macro ถูกสร้างไปแล้วตอน Hardening ดังนั้น Top-Level CTS ต้องส่ง Clock ถึง Macro Clock Pin โดยไม่สามารถปรับ Internal CTS ภายใน Macro ได้

---

## 13.49 Timing Components ของ Clock ถึง Macro

Clock Arrival ที่ Register ภายใน Macro อาจประกอบด้วย

```text
Top-level clock insertion delay
+ Macro boundary clock delay
+ Internal macro clock insertion delay
```

ประเด็นสำคัญ:

- Macro Liberty ต้อง Model Clock-to-Q และ Setup/Hold Arc อย่างถูกต้อง
- Clock Latency ระดับ Macro ต้องสอดคล้องกับ Characterization
- Top-Level CTS ต้องสมดุล Clock Arrival ระหว่าง Macro และ Standard Cells
- Macro Clock Pin ไม่ควรอยู่ในตำแหน่งที่เข้าถึงยาก
- Clock Routing ไม่ควรผ่าน Channel ที่มี Congestion สูง

---

## 13.50 ตรวจสอบ CTS Report

ค้นหา Report:

```bash
find top/runs \
    -type f \
    \( -iname "*cts*" -o \
       -iname "*clock*" -o \
       -iname "*skew*" \)
```

ตรวจสอบ:

```text
Clock root
Clock sinks
Clock buffers
Maximum skew
Insertion delay
Clock transition
Unbuffered clock nets
Clock nets entering macros
```

เกณฑ์:

```text
No unconnected clock sink
No max transition violation
No clock routing failure
Acceptable skew
All macro clock pins connected
```

---

# ส่วนที่ 16 Hierarchical Timing Analysis

## 13.51 Timing Paths ที่ต้องตรวจสอบ

Hierarchical Design มี Timing Path หลักสี่ประเภท

### ประเภทที่ 1: Top-Level Register ไป Top-Level Register

```text
Top FF → Combinational Logic → Top FF
```

### ประเภทที่ 2: Top-Level Register ไป Macro

```text
Top FF → Interconnect → Macro Input → Internal Macro FF
```

### ประเภทที่ 3: Macro ไป Top-Level Register

```text
Internal Macro FF → Macro Output → Interconnect → Top FF
```

### ประเภทที่ 4: Macro ไป Macro

```text
Macro A Internal FF
        ↓
Macro A Output
        ↓
Top-Level Interconnect
        ↓
Macro B Input
        ↓
Macro B Internal FF
```

Path ประเภท Macro-to-Macro มักเป็น Path สำคัญ เนื่องจาก Delay ประกอบด้วย

```text
Macro A clock-to-Q
+ Macro A output delay
+ Top-level net delay
+ Buffer delay
+ Macro B input setup requirement
```

---

## 13.52 Black-Box Timing เทียบกับ Modeled Timing

### Black-Box Timing

หากมีเฉพาะ LEF/GDS:

```text
Macro internal timing = ไม่ทราบ
```

STA มองเห็นเพียง Connectivity รอบ Macro และอาจไม่สามารถวิเคราะห์ End-to-End Path ได้ครบถ้วน

### Liberty-Based Timing

หากมี `.lib`:

```text
Input-to-output timing arcs
Clock-to-output timing arcs
Setup/Hold constraints
Pin capacitance
Transition behavior
```

### Netlist + SPEF Timing

หากมี `.nl.v` และ `.spef`:

```text
Macro gate-level connectivity
+ extracted parasitic resistance/capacitance
```

LibreLane สามารถให้ความสำคัญกับ Netlist และ SPEF ผ่าน `STA_MACRO_PRIORITIZE_NL` และใช้ Liberty เป็น Fallback เมื่อ View ที่ต้องการไม่มี 

---

## 13.53 ตรวจสอบ Setup Timing

ค้นหา Report:

```bash
grep -R \
    -n \
    -E "worst.*slack|setup.*slack|tns|wns" \
    top/runs/* 2>/dev/null \
    | tail -n 50
```

หาก Setup Violation เกิดที่ Macro Boundary ให้ตรวจสอบ

1. Macro-to-macro distance
2. Macro orientation
3. Pin location
4. Net delay
5. Output load
6. Input delay assumption
7. Clock skew
8. Liberty timing arc
9. SPEF corner mapping
10. SDC clock relationship

แนวทางแก้:

- ย้าย Macro ให้ใกล้กัน
- หมุน Macro ให้ Pins หันเข้าหากัน
- เพิ่ม Buffer ใน Top-Level Interconnect
- ลด Output Load
- ขยาย Clock Period
- ปรับ Macro Boundary Constraints
- Re-harden Macro ด้วย Timing Budget ที่เหมาะสม
- ปรับ Top-Level Logic ระหว่าง Macro

---

## 13.54 ตรวจสอบ Hold Timing

Hold Violation ที่ Macro Boundary อาจเกิดจาก

- Data path สั้นเกินไป
- Clock ถึง Capture Register ช้ากว่า Launch Register
- Macro Internal Clock Latency ต่างกัน
- Liberty Model ไม่ตรงกับ Physical Implementation
- Top-Level CTS สร้าง Clock Skew ที่ไม่เหมาะสม
- Input Delay Assumption ตอน Hardening ไม่สอดคล้องกับระบบจริง

แนวทางแก้:

- แทรก Delay Buffer
- ปรับ Clock Tree
- ใช้ Hold Repair
- ตรวจสอบ Min Corner
- ตรวจสอบ Macro Hold Constraint
- ตรวจสอบ SPEF ของ Macro
- ตรวจสอบ Clock Latency Model

---

# ส่วนที่ 17 Routing

## 13.55 Global Routing

Global Router จะประเมินเส้นทางระหว่าง

- IO ไป Standard Cells
- IO ไป Macro Pins
- Macro ไป Macro
- Standard Cells ไป Macro
- Clock/Reset distribution
- Power-related control signals

ตรวจสอบ

```text
Global route overflow
Unroutable nets
Macro pin access
High-fanout nets
Long nets
Congested edges
```

OpenROAD Flow วาง Macro และ Standard Cells ก่อนสร้าง Routing Guides จาก Global Routing แล้วจึงทำ Detailed Routing เพื่อสร้างเส้นลวดที่ถูกต้องตาม Design Rules 

---

## 13.56 Detailed Routing

Detailed Router ต้องสร้างเส้นลวดจริงโดยไม่ละเมิดกฎ เช่น

- Minimum spacing
- Minimum width
- Via enclosure
- End-of-line spacing
- Cut spacing
- Min-area
- Pin access
- Macro obstruction
- Antenna rules

Macro LEF มี `OBS` ซึ่งกำหนดพื้นที่ที่ Top-Level Router ห้ามใช้หรือมีข้อจำกัด

ตรวจสอบ:

```bash
grep -n -A 100 "OBS" \
    macros/counter_macro/lef/counter_macro.lef
```

หาก LEF Obstruction ครอบคลุมบริเวณ Pin Access มากเกินไป Router อาจไม่สามารถเชื่อม Pin ได้

---

# ส่วนที่ 18 Physical Verification

## 13.57 DRC Verification

DRC ระดับ Macro และระดับ Top ต้องผ่านแยกกัน

```text
Block-Level DRC:
    counter_macro       = clean
    accumulator_macro   = clean

Top-Level DRC:
    hier_system         = clean
```

แม้ Macro จะผ่าน DRC แล้ว Top-Level ยังอาจเกิด DRC ที่

- Macro boundary
- Top-Level routing เข้า Macro pin
- PDN crossing
- Via near obstruction
- Metal fill boundary
- Abutment
- Macro spacing
- Die boundary

ตรวจสอบ:

```bash
find top/runs \
    -type f \
    -iname "*drc*" \
    | sort
```

---

## 13.58 LVS Verification

LVS เปรียบเทียบ

```text
Extracted Layout Netlist
            กับ
Schematic/Gate-Level Netlist
```

ประเด็นสำคัญใน Hierarchical LVS:

- Macro GDS ต้องถูก Merge ลง Top-Level GDS
- Macro SPICE/Netlist ต้องมีชื่อ Cell ตรงกัน
- Power Nets ต้องตรงกัน
- Macro Pins ต้องเชื่อมถูกต้อง
- ไม่มี Duplicate Cell Name
- ไม่มี Black Box ที่ LVS ไม่รู้จัก
- Bus Pin Naming ต้องตรงกัน

ตรวจสอบ Log:

```bash
find top/runs \
    -type f \
    \( -iname "*lvs*" -o -iname "*netgen*" \) \
    | sort
```

เป้าหมาย:

```text
Circuits match uniquely
Property errors = 0
Net mismatches = 0
Device mismatches = 0
Pin mismatches = 0
```

---

## 13.59 Antenna Verification

Macro Pins ที่เชื่อมกับสายยาวในระดับบนอาจเกิด Antenna Violation แม้ Macro ภายในจะผ่าน Antenna Check แล้ว

ตัวอย่าง:

```text
Top-level long metal
        │
        └── Macro input pin
                  │
                  └── Internal gate
```

แนวทางแก้:

- Diode insertion
- Jumper insertion
- Layer hopping
- Route restructuring
- วาง Macro ใกล้ Driver
- ลด Wirelength

ตรวจสอบ:

```bash
find top/runs \
    -type f \
    -iname "*antenna*" \
    | sort
```

---

# ส่วนที่ 19 ตรวจสอบ Final GDS

## 13.60 เปิด Top-Level GDS

ค้นหา Final GDS:

```bash
find top/runs \
    -type f \
    -name "hier_system.gds"
```

เปิด:

```bash
klayout path/to/hier_system.gds
```

ตรวจสอบ

- Macro ทั้งสองปรากฏใน Top-Level GDS
- Geometry ภายใน Macro แสดงครบ
- Top-Level Routing เชื่อมถึง Macro Pins
- PDN ต่อถึง Macro
- ไม่มี Macro วางผิดตำแหน่ง
- ไม่มี Macro ถูกหมุนผิด
- ไม่มี Cell หลุดออกนอก Core
- IO Pins อยู่ถูกด้าน
- Metal Fill ครอบคลุมอย่างเหมาะสม
- ไม่มี Empty Macro Placeholder

---

## 13.61 ตรวจสอบว่า GDS ถูก Merge จริง

ใช้ KLayout ดู Cell Hierarchy:

```text
hier_system
├── counter_macro
│   ├── standard cells
│   └── routing geometry
├── accumulator_macro
│   ├── standard cells
│   └── routing geometry
└── top-level cells and routing
```

หากเห็นเพียงกรอบว่างของ Macro อาจหมายถึง

- GDS Path ผิด
- Macro GDS ไม่ถูกโหลด
- Cell Name ใน GDS ไม่ตรงกับ LEF
- GDS Merge Step ล้มเหลว
- Top-Level Stream-Out ใช้ Black Box Placeholder

---

# ส่วนที่ 20 การ Debug ปัญหาที่พบบ่อย

## 13.62 Error: Macro LEF Not Found

อาการ:

```text
Macro LEF not found
File does not exist
Cannot read LEF
```

ตรวจสอบ:

```bash
ls -l macros/counter_macro/lef/counter_macro.lef
realpath macros/counter_macro/lef/counter_macro.lef
```

แนวทางแก้:

- ตรวจสอบ Relative Path
- ใช้ `dir::` ให้ถูกต้อง
- ตรวจสอบชื่อไฟล์
- ตรวจสอบสิทธิ์อ่านไฟล์
- ตรวจสอบว่า Script รวบรวมไฟล์ทำงานสำเร็จ

---

## 13.63 Error: Macro GDS Not Found

อาการ:

```text
Missing GDS view
Cannot merge macro GDS
```

แนวทางแก้:

```bash
file macros/counter_macro/gds/counter_macro.gds
ls -lh macros/counter_macro/gds/counter_macro.gds
```

ไฟล์ต้องไม่เป็น Zero Byte และต้องเป็น GDS ที่สมบูรณ์

---

## 13.64 Error: Unknown Macro

อาการ:

```text
Unknown macro counter_macro
Master not found
Cell type not found
```

ตรวจสอบชื่อ:

```bash
grep "^MACRO" \
    macros/counter_macro/lef/counter_macro.lef

grep "^module" \
    macros/counter_macro/netlist/counter_macro.nl.v

grep -n "counter_macro" \
    rtl/hier_system.sv
```

ชื่อทั้งหมดต้องตรงกันแบบ Case-Sensitive

---

## 13.65 Error: Unknown Instance

อาการ:

```text
Instance u_counter_macro not found
Macro placement instance does not exist
```

ตรวจสอบ:

```bash
grep -n "u_counter_macro" rtl/hier_system.sv
grep -n "u_counter_macro" top/config.yaml
grep -n "u_counter_macro" top/macro_placement.cfg
```

หาก Synthesis เปลี่ยนชื่อ Instance ต้องตรวจสอบ Netlist หลัง Synthesis หรือกำหนดให้ Hierarchy Preservation เหมาะสม

---

## 13.66 Error: Macro Overlap

อาการ:

```text
Macro overlap detected
Illegal macro placement
```

คำนวณ Bounding Box

Counter Macro:

```text
x = 40 ถึง 160
y = 90 ถึง 210
```

Accumulator Macro:

```text
x = 210 ถึง 360
y = 85 ถึง 215
```

จึงไม่ทับกัน และมีช่องว่างแนวนอน:

```text
210 - 160 = 50 µm
```

หากรวม Halo ข้างละ 10 µm:

```text
Effective channel = 50 - 10 - 10
                  = 30 µm
```

---

## 13.67 Error: Macro Outside Core

ตรวจสอบ:

```text
Core Area:
x = 10 ถึง 390
y = 10 ถึง 290
```

สำหรับ Macro ที่ตำแหน่ง `(x, y)` และมีขนาด `(width, height)` ต้องเป็นไปตาม

```text
x >= core_lx
y >= core_ly

x + width  <= core_ux
y + height <= core_uy
```

รวม Halo:

```text
x - halo_x >= core_lx
y - halo_y >= core_ly

x + width  + halo_x <= core_ux
y + height + halo_y <= core_uy
```

---

## 13.68 Error: Routing Congestion Near Macro

อาการ:

```text
High congestion near macro edge
Detailed routing failure
Pin access failure
```

แนวทางแก้ตามลำดับ:

1. เปิด Congestion Map
2. ระบุด้านของ Macro ที่เกิด Overflow
3. ตรวจสอบ Pin Density ด้านนั้น
4. เปลี่ยน Orientation
5. ย้าย Macro
6. เพิ่ม Halo
7. เพิ่ม Channel
8. กระจาย IO Pins
9. ขยาย Die
10. ลด Placement Density
11. Re-harden Macro โดยวาง Pin ใหม่

---

## 13.69 Error: Macro Pin Not Connected

อาการ:

```text
Unconnected macro pin
Dangling pin
Open net
```

ตรวจสอบ:

```bash
grep -n "PIN" \
    macros/counter_macro/lef/counter_macro.lef

grep -n "count_o" \
    rtl/hier_system.sv

grep -n "count_o" \
    macros/counter_macro/netlist/counter_macro.nl.v
```

สาเหตุ:

- Pin name mismatch
- Bus notation mismatch
- Port direction mismatch
- Netlist optimization
- Macro black-box declarationไม่ตรง
- LEF มี Pin ไม่ครบ
- Top-Level Connection ขาด

---

## 13.70 Error: Timing Path Through Macro Unconstrained

อาการ:

```text
Unconstrained endpoint
No timing arc
Black-box timing path
```

แนวทางแก้:

- เพิ่ม Liberty View
- ตรวจสอบ Timing Corner Pattern
- เพิ่ม Macro Netlist/SPEF
- ตรวจสอบ Clock Pin ใน Liberty
- ตรวจสอบ `create_clock`
- ตรวจสอบ Input/Output Delays
- ตรวจสอบ Generated Clock หากมี
- ตรวจสอบ `STA_MACRO_PRIORITIZE_NL`

---

## 13.71 Error: LVS Black Box Mismatch

อาการ:

```text
Black box cell mismatch
Subcircuit not found
Incorrect number of ports
```

ตรวจสอบ

- Cell name ใน GDS
- Subcircuit name ใน SPICE
- Module name ใน Netlist
- จำนวนและลำดับ Ports
- Power Pin inclusion
- Bus expansion
- Hierarchy flattening

คำสั่งตัวอย่าง:

```bash
grep -n "^\.subckt" \
    macros/counter_macro/spice/counter_macro.spice

grep -n "^module" \
    macros/counter_macro/netlist/counter_macro.nl.v
```

---

# ส่วนที่ 21 Makefile Automation

## 13.72 สร้าง Makefile

สร้างไฟล์

```text
Makefile
```

เนื้อหา:

```makefile
SHELL := /bin/bash

PDK ?= sky130A
LIBRELANE ?= librelane

RTL_FILES := \
	rtl/counter_macro.sv \
	rtl/accumulator_macro.sv \
	rtl/hier_system.sv

TB_FILE := tb/tb_hier_system.sv

.PHONY: all
all: sim

.PHONY: lint
lint:
	verilator \
		--lint-only \
		--timing \
		-Wall \
		-Wno-fatal \
		$(RTL_FILES)

.PHONY: sim
sim:
	verilator \
		--binary \
		--timing \
		--trace \
		-Wall \
		-Wno-fatal \
		--top-module tb_hier_system \
		$(RTL_FILES) \
		$(TB_FILE)
	./obj_dir/Vtb_hier_system

.PHONY: counter
counter:
	$(LIBRELANE) \
		--pdk $(PDK) \
		blocks/counter_macro/config.yaml

.PHONY: accumulator
accumulator:
	$(LIBRELANE) \
		--pdk $(PDK) \
		blocks/accumulator_macro/config.yaml

.PHONY: check-macros
check-macros:
	./scripts/check_macro_views.sh

.PHONY: top
top: check-macros
	$(LIBRELANE) \
		--pdk $(PDK) \
		top/config.yaml

.PHONY: hierarchy-check
hierarchy-check:
	@echo "Checking macro names..."
	@grep "^MACRO" \
		macros/counter_macro/lef/counter_macro.lef
	@grep "^MACRO" \
		macros/accumulator_macro/lef/accumulator_macro.lef
	@grep -n "u_counter_macro" rtl/hier_system.sv
	@grep -n "u_accumulator_macro" rtl/hier_system.sv

.PHONY: clean-sim
clean-sim:
	rm -rf obj_dir
	rm -f hier_system.vcd

.PHONY: clean
clean: clean-sim
	rm -rf reports/*
```

---

## 13.73 ใช้งาน Makefile

ตรวจสอบ RTL:

```bash
make lint
```

รัน Simulation:

```bash
make sim
```

สร้าง Counter Macro:

```bash
make counter
```

สร้าง Accumulator Macro:

```bash
make accumulator
```

รวบรวม Macro Views โดยใช้ Run Directory ที่สร้างขึ้น:

```bash
./scripts/collect_counter_macro.sh \
    blocks/counter_macro/runs/RUN_...

./scripts/collect_accumulator_macro.sh \
    blocks/accumulator_macro/runs/RUN_...
```

ตรวจสอบ Macro Views:

```bash
make check-macros
```

ตรวจสอบชื่อใน Hierarchy:

```bash
make hierarchy-check
```

รัน Top-Level Flow:

```bash
make top
```

---

# ส่วนที่ 22 ลำดับการทดลองฉบับสมบูรณ์

## 13.74 Step-by-Step Execution

### ขั้นตอนที่ 1 ตรวจสอบเครื่องมือ

```bash
verilator --version
yosys -V
openroad -version
klayout -v
librelane --version
```

### ขั้นตอนที่ 2 ตรวจสอบ RTL

```bash
make lint
```

### ขั้นตอนที่ 3 รัน Functional Simulation

```bash
make sim
```

ต้องผ่านทุก Test Case ก่อนเริ่ม Physical Design

### ขั้นตอนที่ 4 Hardening Counter Macro

```bash
make counter
```

### ขั้นตอนที่ 5 ตรวจสอบ Counter Macro

ตรวจสอบ

```text
GDS
LEF
Timing
DRC
LVS
Antenna
Pin placement
PDN
```

### ขั้นตอนที่ 6 รวบรวม Counter Views

```bash
./scripts/collect_counter_macro.sh \
    blocks/counter_macro/runs/RUN_...
```

### ขั้นตอนที่ 7 Hardening Accumulator Macro

```bash
make accumulator
```

### ขั้นตอนที่ 8 ตรวจสอบ Accumulator Macro

ตรวจสอบเช่นเดียวกับ Counter Macro

### ขั้นตอนที่ 9 รวบรวม Accumulator Views

```bash
./scripts/collect_accumulator_macro.sh \
    blocks/accumulator_macro/runs/RUN_...
```

### ขั้นตอนที่ 10 ตรวจสอบ Macro Views

```bash
make check-macros
```

### ขั้นตอนที่ 11 ตรวจสอบ Hierarchy และชื่อ Instance

```bash
make hierarchy-check
```

### ขั้นตอนที่ 12 ตรวจสอบ Top-Level Configuration

```bash
python3 - <<'PY'
import yaml

with open("top/config.yaml", encoding="utf-8") as f:
    cfg = yaml.safe_load(f)

assert cfg["DESIGN_NAME"] == "hier_system"
assert "counter_macro" in cfg["MACROS"]
assert "accumulator_macro" in cfg["MACROS"]

print("Top-level configuration check: PASS")
PY
```

### ขั้นตอนที่ 13 รัน Top-Level Flow

```bash
make top
```

### ขั้นตอนที่ 14 ตรวจสอบ Macro Placement

เปิด Floorplan/Placement Database ด้วย OpenROAD GUI

ตรวจสอบ

```text
Macro locations
Orientations
Halos
Channels
IO pins
PDN
Congestion
```

### ขั้นตอนที่ 15 ตรวจสอบ CTS

ตรวจสอบ Clock Sink ของ Macro ทั้งสอง

### ขั้นตอนที่ 16 ตรวจสอบ Routing

ตรวจสอบ Global Route Overflow และ Detailed Route DRC

### ขั้นตอนที่ 17 ตรวจสอบ Timing

ตรวจสอบ

```text
Top-to-top paths
Top-to-macro paths
Macro-to-top paths
Macro-to-macro paths
Setup
Hold
Max slew
Max capacitance
```

### ขั้นตอนที่ 18 ตรวจสอบ Signoff

```text
DRC = clean
LVS = clean
Antenna = clean
Setup = clean
Hold = clean
Unconstrained paths = 0
```

### ขั้นตอนที่ 19 เปิด Final GDS

```bash
klayout path/to/hier_system.gds
```

### ขั้นตอนที่ 20 บันทึก Metrics

บันทึกผลลงตารางสรุปของ Lab

---

# ส่วนที่ 23 ตารางบันทึกผลการทดลอง

## 13.75 Block-Level Metrics

| Metric | Counter Macro | Accumulator Macro |
|---|---:|---:|
| Die width | | |
| Die height | | |
| Core utilization | | |
| Standard-cell count | | |
| Sequential-cell count | | |
| Combinational-cell count | | |
| Total area | | |
| WNS setup | | |
| TNS setup | | |
| WNS hold | | |
| TNS hold | | |
| Clock skew | | |
| Wirelength | | |
| DRC violations | | |
| LVS errors | | |
| Antenna violations | | |
| Runtime | | |

---

## 13.76 Top-Level Metrics

| Metric | Result |
|---|---:|
| Die width | |
| Die height | |
| Core utilization | |
| Number of hard macros | 2 |
| Standard-cell count | |
| Clock-buffer count | |
| Total area | |
| WNS setup | |
| TNS setup | |
| WNS hold | |
| TNS hold | |
| Maximum clock skew | |
| Total wirelength | |
| Global-route overflow | |
| Detailed-route violations | |
| DRC violations | |
| LVS errors | |
| Antenna violations | |
| Runtime | |

---

# ส่วนที่ 24 การทดลองเพิ่มเติม

## 13.77 Experiment A: เปลี่ยน Macro Orientation

เปลี่ยน Accumulator Macro จาก

```text
N
```

เป็น

```text
S
```

รัน Top-Level ใหม่ แล้วเปรียบเทียบ

- Wirelength
- Routing congestion
- Setup slack
- Hold slack
- Detailed-route violations
- Pin accessibility

คำถาม:

1. Pin `data_i` และ `accum_o` ย้ายไปด้านใด
2. Wirelength เพิ่มขึ้นหรือลดลง
3. Congestion เกิดบริเวณใด
4. Orientation ใดเหมาะสมกว่า

---

## 13.78 Experiment B: ลด Channel Spacing

ย้าย Accumulator Macro เข้าใกล้ Counter Macro

จาก

```text
x = 210 µm
```

เป็น

```text
x = 175 µm
```

วิเคราะห์

- Global routing overflow
- Detailed routing
- Standard-cell placement
- Clock routing
- DRC

คำนวณ Channel ใหม่:

```text
Counter right edge = 40 + 120 = 160 µm

New accumulator left edge = 175 µm

Physical gap = 175 - 160 = 15 µm
```

เมื่อ Macro ทั้งสองมี Halo ข้างละ 10 µm จะเกิด Halo Overlap:

```text
Effective gap = 15 - 10 - 10
              = -5 µm
```

จึงเป็นตำแหน่งที่ไม่เหมาะสม

---

## 13.79 Experiment C: เพิ่ม Die Area

เปลี่ยนจาก

```yaml
DIE_AREA: [0.0, 0.0, 400.0, 300.0]
```

เป็น

```yaml
DIE_AREA: [0.0, 0.0, 450.0, 350.0]
```

เปรียบเทียบ

- Placement density
- Congestion
- Wirelength
- Timing
- Runtime
- Area overhead

อภิปรายว่า Die ที่ใหญ่ขึ้นอาจช่วย Routability แต่ทำให้

- Wirelength เพิ่มขึ้น
- Clock tree ใหญ่ขึ้น
- Die cost เพิ่มขึ้น
- Power เพิ่มขึ้น
- Timing อาจแย่ลงจากระยะทาง

---

## 13.80 Experiment D: Black-Box Timing

ทดลองนำ `.lib` และ `.spef` ออกจาก Top-Level Configuration ชั่วคราว แล้วรัน STA

เปรียบเทียบ

```text
Case 1: LEF + GDS only
Case 2: LEF + GDS + LIB
Case 3: LEF + GDS + NL + SPEF
```

บันทึก

- จำนวน Timing Paths
- จำนวน Unconstrained Paths
- WNS/TNS
- ความสามารถในการมองเห็น Path ผ่าน Macro
- Runtime

---

## 13.81 Experiment E: เปลี่ยน Boundary Timing Budget

เปลี่ยน Input Delay ของ Counter Macro จาก

```tcl
set_input_delay 2.000
```

เป็น

```tcl
set_input_delay 4.000
```

จากนั้น Re-harden Macro และเปรียบเทียบ

- Cell sizing
- Buffer count
- Area
- Power
- Setup slack
- Top-Level Timing

อภิปรายว่า Timing Budget ระดับบล็อกส่งผลต่อ Physical Implementation อย่างไร

---

# ส่วนที่ 25 คำถามท้ายบทปฏิบัติการ

## 13.82 คำถามทบทวน

1. Hierarchical Physical Design แตกต่างจาก Flat Physical Design อย่างไร
2. Hard Macro คืออะไร
3. เหตุใด LEF และ GDS จึงเป็น Views ที่จำเป็น
4. LEF แตกต่างจาก GDS อย่างไร
5. Liberty มีบทบาทอย่างไรในการวิเคราะห์ Timing ของ Macro
6. SPEF มีข้อมูลประเภทใด
7. เหตุใดชื่อ Macro ใน LEF ต้องตรงกับชื่อ Module
8. เหตุใดชื่อ Instance ใน `MACROS` ต้องตรงกับ Top-Level Netlist
9. Macro Halo มีประโยชน์อย่างไร
10. Channel Spacing มีผลต่อ Routing อย่างไร
11. Orientation ของ Macro มีผลต่อ Pin Access อย่างไร
12. เหตุใด Macro ที่ผ่าน DRC แล้วอาจยังทำให้ Top-Level DRC ไม่ผ่าน
13. Macro-to-Macro Timing Path ประกอบด้วย Delay ส่วนใดบ้าง
14. Black-Box Timing มีข้อจำกัดอย่างไร
15. ทำไม Top-Level CTS ไม่สามารถแก้ Clock Tree ภายใน Hard Macro ได้
16. เหตุใด Power Pins ของ Macro ต้องเชื่อมกับ Top-Level PDN
17. การวาง Macro ใกล้กันเกินไปก่อให้เกิดปัญหาใด
18. การเพิ่ม Die Area ช่วยและส่งผลเสียอย่างไร
19. Hierarchical LVS ต้องใช้ข้อมูลใดบ้าง
20. เมื่อใดควร Re-harden Macro

---

# ส่วนที่ 26 เกณฑ์ผ่านบทปฏิบัติการ

## 13.83 Functional Criteria

```text
Verilator lint errors       = 0
Functional simulation       = PASS
Counter tests               = PASS
Accumulator tests           = PASS
Reset tests                 = PASS
```

## 13.84 Counter Macro Criteria

```text
GDS exists                  = PASS
LEF exists                  = PASS
All pins present            = PASS
Setup timing                = PASS
Hold timing                 = PASS
DRC                          = clean
LVS                          = clean
Antenna                      = clean
```

## 13.85 Accumulator Macro Criteria

```text
GDS exists                  = PASS
LEF exists                  = PASS
All pins present            = PASS
Setup timing                = PASS
Hold timing                 = PASS
DRC                          = clean
LVS                          = clean
Antenna                      = clean
```

## 13.86 Top-Level Criteria

```text
Both macros instantiated    = PASS
Macro positions correct     = PASS
No macro overlap            = PASS
Macro power connected       = PASS
Macro clocks connected      = PASS
Global routing              = PASS
Detailed routing            = PASS
Setup timing                = PASS
Hold timing                 = PASS
DRC                          = clean
LVS                          = clean
Antenna                      = clean
Final GDS generated          = PASS
```

---

# ส่วนที่ 27 สรุปบทปฏิบัติการ

Hierarchical Physical Design เป็นเทคนิคสำคัญสำหรับควบคุมความซับซ้อนของวงจร ASIC ขนาดใหญ่ โดยแบ่งระบบออกเป็นบล็อกย่อยและนำแต่ละบล็อกผ่าน Physical Implementation แยกกันก่อนนำไปประกอบในระดับบน

ลำดับงานหลักคือ

```text
RTL partitioning
      ↓
Block-level verification
      ↓
Block hardening
      ↓
Macro view generation
      ↓
Macro characterization
      ↓
Top-level black-box integration
      ↓
Macro placement
      ↓
Top-level placement and CTS
      ↓
Top-level routing
      ↓
Hierarchical timing verification
      ↓
DRC/LVS/Antenna verification
      ↓
Final GDSII
```

หัวใจสำคัญของ Hierarchical Flow ไม่ใช่เพียงการนำ GDS ของหลายบล็อกมารวมกัน แต่รวมถึงการรักษาความสอดคล้องของข้อมูลทุกมุมมอง ได้แก่

```text
Logical interface
Physical interface
Timing interface
Power interface
Verification interface
```

Macro ที่นำกลับมาใช้ซ้ำได้อย่างมีคุณภาพควรมี

```text
LEF
GDS
Gate-level netlist
Powered netlist
Liberty
SPEF
SPICE
Timing constraints
Verification reports
Version information
```

นอกจากนี้ ต้องกำหนด Boundary Timing Budget, Pin Placement, Macro Orientation, Halo, Channel และ PDN ตั้งแต่ระดับบล็อก เพราะการตัดสินใจเหล่านี้มีผลโดยตรงต่อ Timing Closure และ Routability ในระดับบน

การผ่าน Block-Level Signoff ไม่ได้หมายความว่า Top-Level Design จะผ่าน Signoff โดยอัตโนมัติ ผู้ออกแบบยังต้องตรวจสอบ Macro Boundary, Clock Distribution, Power Connection, Routing Interaction และ Hierarchical Timing Paths ที่เกิดขึ้นหลังการประกอบระบบครบถ้วน
:::

ตัวอย่างนี้กำหนดขนาด Die, Macro และ Timing Constraint เพื่อใช้เป็นจุดเริ่มต้นของ Lab จึงควรปรับค่า `DIE_AREA`, `CORE_AREA`, Timing Corner Patterns และชื่อตัวแปร Configuration ให้ตรงกับ PDK และ LibreLane Version ที่ใช้จริงใน Workshop.