
# Lab 12 Macro Integration ด้วย LibreLane

## 12.1 วัตถุประสงค์

บทปฏิบัติการนี้สาธิตการนำวงจรที่ผ่านกระบวนการ Physical Design และสร้างเป็น **Hard Macro** แล้ว มาประกอบเข้ากับวงจรระดับบน หรือ Top-level Design โดยใช้ LibreLane

เมื่อจบบทปฏิบัติการ ผู้เรียนจะสามารถ:

1. อธิบายความแตกต่างระหว่าง RTL Module และ Hard Macro
2. เตรียมมุมมองต่าง ๆ ของ Macro ได้แก่ LEF, GDS, Verilog Netlist, Liberty และ SPEF
3. เขียน RTL ระดับบนที่ instantiate Hard Macro
4. ประกาศ Macro ในตัวแปร `MACROS` ของ `config.yaml`
5. กำหนดตำแหน่งและทิศทางของ Macro
6. เชื่อมต่อสัญญาณ Power และ Ground ของ Macro
7. กำหนด Halo และ Routing Keep-out รอบ Macro
8. รัน LibreLane ตั้งแต่ RTL ถึง GDSII
9. ตรวจสอบ Macro placement, PDN, routing, timing, DRC และ LVS
10. วิเคราะห์และแก้ไขปัญหาที่พบบ่อยในการรวม Macro

---

# 12.2 แนวคิดของ Macro Integration

ในการออกแบบชิปจริง วงจรทั้งหมดไม่ได้ถูกสังเคราะห์ วางตำแหน่ง และเดินสายในครั้งเดียวเสมอไป ส่วนหนึ่งของระบบมักถูกสร้างเป็นบล็อก Physical Design ที่เสร็จสมบูรณ์ก่อน แล้วนำกลับมาใช้ในวงจรระดับบน

บล็อกที่ผ่านกระบวนการ Physical Design แล้วเรียกว่า:

- Hard Macro
- Hardened Macro
- Physical IP
- Embedded Macro

ตัวอย่างของ Macro ได้แก่:

- SRAM
- ROM
- Register File
- PLL
- ADC/DAC
- CPU Core
- Crypto Accelerator
- DSP Engine
- UART Controller
- Peripheral Subsystem
- Standard-cell-based Macro ที่ harden แยกไว้ก่อน

การใช้ Macro ช่วยลดเวลารัน Place-and-Route ของระบบระดับบน ช่วยให้ใช้บล็อกเดิมซ้ำได้ และช่วยแยกการพัฒนาแต่ละส่วนออกจากกัน LibreLane ระบุว่า LEF และ GDS เป็นมุมมองหลักที่จำเป็นสำหรับ Macro โดย LEF ใช้ระหว่าง Physical Design และ GDS ใช้ในการรวม layout ขั้นสุดท้าย 

---

# 12.3 ความแตกต่างระหว่าง Soft Macro และ Hard Macro

## 12.3.1 Soft Macro

Soft Macro เป็นบล็อกที่ยังอยู่ในรูป RTL เช่น:

```systemverilog
module counter_macro (
    input  logic       clk_i,
    input  logic       rst_ni,
    input  logic       en_i,
    output logic [7:0] count_o
);
```

เมื่อรวม Soft Macro เข้ากับ Top-level LibreLane จะสังเคราะห์ logic ภายในบล็อกดังกล่าวร่วมกับ logic ส่วนอื่น

ข้อดี:

- ปรับ parameter ได้ง่าย
- เปลี่ยน RTL ได้ง่าย
- Tool สามารถ optimize ข้ามขอบเขต module ได้

ข้อจำกัด:

- ใช้เวลาสังเคราะห์และ Place-and-Route มากขึ้น
- ผลลัพธ์ทางกายภาพอาจเปลี่ยนทุกครั้งที่รัน
- ไม่เหมาะกับ SRAM, analog IP หรือบล็อกที่มี layout เฉพาะ

## 12.3.2 Hard Macro

Hard Macro มีรูปร่าง ขนาด ตำแหน่ง pin และ layout ภายในคงที่แล้ว

Top-level flow จะมอง Macro คล้ายกล่องดำที่มี:

- ขนาดคงที่
- ตำแหน่ง pin คงที่
- Routing obstruction ภายใน
- Power pins
- Timing model
- Layout geometry

Tool จะไม่สร้าง placement หรือ routing ภายใน Hard Macro ใหม่ แต่จะวาง Macro เป็นวัตถุขนาดใหญ่และเดินสายเชื่อมต่อระหว่าง Macro กับวงจรภายนอก

---

# 12.4 มุมมองที่ต้องใช้สำหรับ Hard Macro

โครงสร้าง Macro ที่สมบูรณ์อาจประกอบด้วยไฟล์ต่อไปนี้

```text
counter_macro/
├── lef/
│   └── counter_macro.lef
├── gds/
│   └── counter_macro.gds
├── nl/
│   └── counter_macro.nl.v
├── pnl/
│   └── counter_macro.pnl.v
├── lib/
│   ├── counter_macro__tt.lib
│   ├── counter_macro__ss.lib
│   └── counter_macro__ff.lib
├── spef/
│   ├── counter_macro.min.spef
│   ├── counter_macro.nom.spef
│   └── counter_macro.max.spef
├── spice/
│   └── counter_macro.spice
└── sdf/
    └── counter_macro.sdf
```

LibreLane รองรับมุมมองหลายชนิดใน `MACROS` ได้แก่ `gds`, `lef`, `vh`, `nl`, `pnl`, `lib`, `spef`, `spice`, `sdf` และ `json_h` โดย `gds` และ `lef` ต้องมีอย่างน้อยหนึ่งไฟล์ มิฉะนั้นการตรวจสอบ configuration จะเกิดข้อผิดพลาด 

## 12.4.1 LEF

LEF เป็น Physical Abstract ของ Macro ประกอบด้วยข้อมูลสำคัญ เช่น:

- ชื่อ Macro
- ความกว้างและความสูง
- Origin
- Signal pins
- Power pins
- ตำแหน่งและชั้นโลหะของ pin
- Routing obstructions
- Symmetry
- Site หรือ Class ของ Macro

ตัวอย่างบางส่วน:

```lef
VERSION 5.8 ;
BUSBITCHARS "[]" ;
DIVIDERCHAR "/" ;

MACRO counter_macro
  CLASS BLOCK ;
  ORIGIN 0.000 0.000 ;
  FOREIGN counter_macro 0.000 0.000 ;
  SIZE 120.000 BY 100.000 ;
  SYMMETRY X Y R90 ;

  PIN clk_i
    DIRECTION INPUT ;
    USE SIGNAL ;
    PORT
      LAYER met3 ;
        RECT 0.000 48.000 2.000 50.000 ;
    END
  END clk_i

  PIN VPWR
    DIRECTION INOUT ;
    USE POWER ;
    PORT
      LAYER met4 ;
        RECT 0.000 95.000 120.000 97.000 ;
    END
  END VPWR

  PIN VGND
    DIRECTION INOUT ;
    USE GROUND ;
    PORT
      LAYER met4 ;
        RECT 0.000 3.000 120.000 5.000 ;
    END
  END VGND

  OBS
    LAYER met1 ;
      RECT 0.000 0.000 120.000 100.000 ;
    LAYER met2 ;
      RECT 0.000 0.000 120.000 100.000 ;
  END
END counter_macro
```

ระหว่าง Place-and-Route LibreLane ใช้ LEF เพื่อทราบขนาด ตำแหน่ง pin และพื้นที่ที่ห้ามเดินสายภายใน Macro 

## 12.4.2 GDSII

GDSII ประกอบด้วย layout geometry เต็มรูปแบบ เช่น:

- Diffusion
- Well
- Implant
- Polysilicon
- Contacts
- Vias
- Metal layers
- Text labels
- Boundary geometry

ไฟล์ GDS ของ Macro จะถูก merge เข้ากับ GDS ของ Top-level ในช่วง stream-out

## 12.4.3 Verilog Black-box Header

ไฟล์ Black-box Header บอกชื่อ module และ interface ของ Macro โดยไม่ต้องมี logic ภายใน

ตัวอย่าง `counter_macro.vh`:

```systemverilog
(* blackbox *)
module counter_macro (
`ifdef USE_POWER_PINS
    inout wire VPWR,
    inout wire VGND,
`endif
    input  wire       clk_i,
    input  wire       rst_ni,
    input  wire       en_i,
    output wire [7:0] count_o
);
endmodule
```

Header นี้ช่วยให้ Yosys ทราบว่า:

- Module มีอยู่จริง
- Module มี port อะไรบ้าง
- ไม่ต้องสังเคราะห์ logic ภายใน
- Instance ต้องคงอยู่เป็น Macro

## 12.4.4 Gate-level Netlist

ไฟล์ `nl` เป็น gate-level netlist ที่ไม่มี power pins หรืออาจมี power pins ตามรูปแบบ library

ไฟล์นี้สามารถใช้ร่วมกับ SPEF สำหรับ Hierarchical STA ได้ LibreLane อาจเลือกใช้ netlist พร้อม SPEF หรือ Liberty ตามค่า `STA_MACRO_PRIORITIZE_NL` 

## 12.4.5 Powered Netlist

ไฟล์ `pnl` เป็น gate-level netlist ที่ประกอบด้วย power pins เช่น:

```verilog
module counter_macro (
    VPWR,
    VGND,
    clk_i,
    rst_ni,
    en_i,
    count_o
);
```

Powered netlist มีประโยชน์สำหรับ:

- LVS
- Gate-level simulation
- Power-aware connectivity
- Hierarchy checks

## 12.4.6 Liberty Timing Model

Liberty `.lib` ใช้แทน timing behavior ของ Macro เช่น:

- Input capacitance
- Output transition
- Combinational delay
- Setup time
- Hold time
- Recovery/Removal
- Clock-to-Q
- Timing arc
- Power information

หากมี Liberty ที่ผ่าน characterization แล้ว STA ระดับบนจะวิเคราะห์เส้นทางที่ผ่านขอบเขต Macro ได้แม่นยำกว่าการมอง Macro เป็น black box

## 12.4.7 SPEF

SPEF ประกอบด้วย parasitic resistance และ capacitance ภายใน Macro

เมื่อใช้คู่กับ gate-level netlist OpenSTA สามารถวิเคราะห์ timing ภายใน Macro ได้ในลักษณะ hierarchical timing analysis

## 12.4.8 SPICE

SPICE netlist ใช้สำหรับ transistor-level verification หรือ LVS hierarchy ในบาง flow ถึงแม้เอกสาร LibreLane ระบุว่ายังไม่ได้ใช้โดยตรงในทุกขั้นตอน แต่ควรเก็บไว้เป็นส่วนหนึ่งของ Macro deliverables 

---

# 12.5 สถาปัตยกรรมของบทปฏิบัติการ

ใน Lab นี้จะสร้างระบบระดับบนดังนี้

```text
                     +------------------------------+
                     |       macro_wrapper          |
                     |                              |
 clk_i ------------->|                              |
 rst_ni ------------>|    +--------------------+    |
 en_i -------------->|--->|  u_counter_macro   |    |
                     |    |                    |    |
                     |    |   Hard Macro       |    |
                     |    |                    |--->| count_o[7:0]
                     |    +--------------------+    |
                     |                              |
                     +------------------------------+
```

Macro ที่ใช้คือ:

```text
counter_macro
```

Instance ใน Top-level คือ:

```text
u_counter_macro
```

ต้องระวังว่า key ภายใต้ `instances` ต้องเป็น **ชื่อ instance ใน netlist** ไม่ใช่ชื่อ module LibreLane กำหนดให้ชื่อ instance ใน `MACROS` ตรงกับชื่อที่ instantiate ใน Verilog และหาก hierarchy ถูก flatten ชื่ออาจเปลี่ยนเป็นรูปแบบ `instance_a.instance_b` 

---

# 12.6 โครงสร้าง Directory

สร้างโครงสร้างดังนี้

```text
lab12_macro_integration/
├── config.yaml
├── src/
│   └── macro_wrapper.sv
├── constraints/
│   ├── pnr.sdc
│   └── signoff.sdc
├── macros/
│   └── counter_macro/
│       ├── lef/
│       │   └── counter_macro.lef
│       ├── gds/
│       │   └── counter_macro.gds
│       ├── vh/
│       │   └── counter_macro.vh
│       ├── nl/
│       │   └── counter_macro.nl.v
│       ├── pnl/
│       │   └── counter_macro.pnl.v
│       ├── lib/
│       │   └── counter_macro__tt.lib
│       ├── spef/
│       │   └── counter_macro.nom.spef
│       └── spice/
│           └── counter_macro.spice
├── scripts/
│   ├── check_macro_files.sh
│   ├── inspect_lef.py
│   └── run.sh
└── runs/
```

สร้าง directory:

```bash
mkdir -p lab12_macro_integration/{src,constraints,scripts,runs}

mkdir -p lab12_macro_integration/macros/counter_macro/{lef,gds,vh,nl,pnl,lib,spef,spice}

cd lab12_macro_integration
```

---

# 12.7 ตรวจสอบ Macro Deliverables

ก่อนรวม Macro ต้องตรวจสอบว่ามุมมองแต่ละไฟล์สอดคล้องกัน

## 12.7.1 ตรวจสอบชื่อ Macro ใน LEF

```bash
grep -n "^MACRO" macros/counter_macro/lef/counter_macro.lef
```

ผลที่คาดหวัง:

```text
MACRO counter_macro
```

ตรวจสอบขนาด:

```bash
grep -n "SIZE" macros/counter_macro/lef/counter_macro.lef
```

ตัวอย่าง:

```text
SIZE 120.000 BY 100.000 ;
```

ตรวจสอบ pins:

```bash
grep -n "^  PIN" macros/counter_macro/lef/counter_macro.lef
```

ควรพบ:

```text
PIN clk_i
PIN rst_ni
PIN en_i
PIN count_o[0]
...
PIN count_o[7]
PIN VPWR
PIN VGND
```

## 12.7.2 ตรวจสอบชื่อ Top Cell ใน GDS

ใช้ KLayout:

```bash
klayout macros/counter_macro/gds/counter_macro.gds
```

ตรวจสอบว่า Top Cell มีชื่อ:

```text
counter_macro
```

ชื่อ GDS top cell ต้องตรงกับชื่อ Macro ใน LEF และชื่อ module ใน Verilog model

## 12.7.3 ตรวจสอบชื่อ Module ใน Netlist

```bash
grep -n "^module" macros/counter_macro/nl/counter_macro.nl.v
```

ผลที่คาดหวัง:

```text
module counter_macro (...);
```

## 12.7.4 ตรวจสอบ Power Pins

```bash
grep -n -E "VPWR|VGND|VDD|VSS" \
    macros/counter_macro/lef/counter_macro.lef
```

จากนั้นตรวจสอบไฟล์ powered netlist:

```bash
grep -n -E "VPWR|VGND|VDD|VSS" \
    macros/counter_macro/pnl/counter_macro.pnl.v
```

ชื่อ power pins ใน:

- RTL
- Black-box header
- Powered netlist
- LEF
- SPICE
- PDN configuration

ต้องสอดคล้องกัน

---

# 12.8 สคริปต์ตรวจสอบ Macro Files

สร้างไฟล์:

```text
scripts/check_macro_files.sh
```

เนื้อหา:

```bash
#!/usr/bin/env bash

set -euo pipefail

MACRO_NAME="counter_macro"
MACRO_ROOT="macros/${MACRO_NAME}"

required_files=(
    "${MACRO_ROOT}/lef/${MACRO_NAME}.lef"
    "${MACRO_ROOT}/gds/${MACRO_NAME}.gds"
    "${MACRO_ROOT}/vh/${MACRO_NAME}.vh"
)

optional_files=(
    "${MACRO_ROOT}/nl/${MACRO_NAME}.nl.v"
    "${MACRO_ROOT}/pnl/${MACRO_NAME}.pnl.v"
    "${MACRO_ROOT}/lib/${MACRO_NAME}__tt.lib"
    "${MACRO_ROOT}/spef/${MACRO_NAME}.nom.spef"
    "${MACRO_ROOT}/spice/${MACRO_NAME}.spice"
)

echo "========================================"
echo "Checking required macro files"
echo "========================================"

for file in "${required_files[@]}"; do
    if [[ ! -f "${file}" ]]; then
        echo "[ERROR] Missing required file: ${file}"
        exit 1
    fi

    if [[ ! -s "${file}" ]]; then
        echo "[ERROR] Empty required file: ${file}"
        exit 1
    fi

    echo "[OK] ${file}"
done

echo
echo "========================================"
echo "Checking optional macro files"
echo "========================================"

for file in "${optional_files[@]}"; do
    if [[ -s "${file}" ]]; then
        echo "[OK] ${file}"
    else
        echo "[WARN] Missing optional file: ${file}"
    fi
done

echo
echo "========================================"
echo "Checking names"
echo "========================================"

if ! grep -qE "^[[:space:]]*MACRO[[:space:]]+${MACRO_NAME}" \
    "${MACRO_ROOT}/lef/${MACRO_NAME}.lef"; then
    echo "[ERROR] LEF does not contain MACRO ${MACRO_NAME}"
    exit 1
fi

if ! grep -qE "^[[:space:]]*module[[:space:]]+${MACRO_NAME}" \
    "${MACRO_ROOT}/vh/${MACRO_NAME}.vh"; then
    echo "[ERROR] Verilog header does not contain module ${MACRO_NAME}"
    exit 1
fi

echo "[OK] Macro and module names are consistent."
echo
echo "Macro preflight check completed."
```

กำหนด permission:

```bash
chmod +x scripts/check_macro_files.sh
```

รัน:

```bash
./scripts/check_macro_files.sh
```

---

# 12.9 เขียน Black-box Header

สร้างไฟล์:

```text
macros/counter_macro/vh/counter_macro.vh
```

```systemverilog
`default_nettype none

(* blackbox *)
module counter_macro (
`ifdef USE_POWER_PINS
    inout wire VPWR,
    inout wire VGND,
`endif
    input  wire       clk_i,
    input  wire       rst_ni,
    input  wire       en_i,
    output wire [7:0] count_o
);

endmodule

`default_nettype wire
```

จุดสำคัญ:

1. ชื่อ module ต้องตรงกับ LEF Macro
2. ชื่อ port ต้องตรงกับ LEF pins
3. ความกว้างของ bus ต้องตรงกัน
4. Direction ต้องถูกต้อง
5. Power pins อยู่ภายใต้ `USE_POWER_PINS`
6. ห้ามใส่ behavioral logic ใน Black-box Header

เอกสาร LibreLane แนะนำรูปแบบการ instantiate Macro โดยครอบ power pins ด้วย `USE_POWER_PINS` เพื่อให้ flow สร้างและเชื่อม hierarchy ของ power nets ได้ถูกต้อง 

---

# 12.10 เขียน Top-level RTL

สร้างไฟล์:

```text
src/macro_wrapper.sv
```

```systemverilog
`default_nettype none

module macro_wrapper (
`ifdef USE_POWER_PINS
    inout wire VPWR,
    inout wire VGND,
`endif

    input  wire       clk_i,
    input  wire       rst_ni,
    input  wire       en_i,
    output wire [7:0] count_o
);

    counter_macro u_counter_macro (
`ifdef USE_POWER_PINS
        .VPWR   (VPWR),
        .VGND   (VGND),
`endif
        .clk_i  (clk_i),
        .rst_ni (rst_ni),
        .en_i   (en_i),
        .count_o(count_o)
    );

endmodule

`default_nettype wire
```

ชื่อ instance คือ:

```text
u_counter_macro
```

ดังนั้นภายใน `config.yaml` ต้องใช้:

```yaml
instances:
  u_counter_macro:
```

ไม่ใช่:

```yaml
instances:
  counter_macro:
```

---

# 12.11 สร้าง Timing Constraints

สร้างไฟล์:

```text
constraints/pnr.sdc
```

```tcl
# ============================================================
# Lab 12: Macro Integration
# PnR timing constraints
# ============================================================

set clk_port [get_ports clk_i]

create_clock \
    -name core_clk \
    -period 20.000 \
    -waveform {0.000 10.000} \
    $clk_port

set_clock_uncertainty 0.250 [get_clocks core_clk]
set_clock_transition  0.150 [get_clocks core_clk]

set non_clock_inputs \
    [remove_from_collection [all_inputs] $clk_port]

set_input_delay \
    -clock core_clk \
    -max 2.000 \
    $non_clock_inputs

set_input_delay \
    -clock core_clk \
    -min 0.000 \
    $non_clock_inputs

set_output_delay \
    -clock core_clk \
    -max 4.000 \
    [all_outputs]

set_output_delay \
    -clock core_clk \
    -min 0.000 \
    [all_outputs]

set_load 0.033442 [all_outputs]

set_max_fanout 16 [current_design]
```

สร้างไฟล์:

```text
constraints/signoff.sdc
```

```tcl
# ============================================================
# Lab 12: Macro Integration
# Signoff timing constraints
# ============================================================

set clk_port [get_ports clk_i]

create_clock \
    -name core_clk \
    -period 20.000 \
    -waveform {0.000 10.000} \
    $clk_port

set_clock_uncertainty 0.250 [get_clocks core_clk]
set_clock_transition  0.150 [get_clocks core_clk]

set non_clock_inputs \
    [remove_from_collection [all_inputs] $clk_port]

set_input_delay \
    -clock core_clk \
    -max 2.000 \
    $non_clock_inputs

set_input_delay \
    -clock core_clk \
    -min 0.000 \
    $non_clock_inputs

set_output_delay \
    -clock core_clk \
    -max 4.000 \
    [all_outputs]

set_output_delay \
    -clock core_clk \
    -min 0.000 \
    [all_outputs]

set_load 0.033442 [all_outputs]
```

การแยก `PNR_SDC_FILE` และ `SIGNOFF_SDC_FILE` ทำให้สามารถใช้ข้อกำหนดสำหรับ optimization และ signoff ต่างกันได้ ซึ่งเป็นแนวทางที่ LibreLane รองรับสำหรับการวิเคราะห์ timing ระหว่างและหลัง PnR 

---

# 12.12 เขียน config.yaml

ตัวอย่างต่อไปนี้ใช้ PDK `sky130A` และ Standard Cell Library `sky130_fd_sc_hd`

สร้างไฟล์:

```text
config.yaml
```

```yaml
# ============================================================
# Lab 12: Macro Integration with LibreLane
# ============================================================

DESIGN_NAME: macro_wrapper

VERILOG_FILES:
  - dir::src/macro_wrapper.sv

CLOCK_PORT: clk_i
CLOCK_PERIOD: 20.0

PNR_SDC_FILE: dir::constraints/pnr.sdc
SIGNOFF_SDC_FILE: dir::constraints/signoff.sdc

# ------------------------------------------------------------
# Floorplan
# ------------------------------------------------------------

FP_SIZING: absolute

DIE_AREA:
  - 0
  - 0
  - 400
  - 400

CORE_AREA:
  - 20
  - 20
  - 380
  - 380

# Standard-cell utilization applies to the available
# standard-cell region, excluding macro blockages.
FP_CORE_UTIL: 35

# ------------------------------------------------------------
# I/O pin placement
# ------------------------------------------------------------

FP_PIN_ORDER_CFG: null

# ------------------------------------------------------------
# Macro definition
# ------------------------------------------------------------

MACROS:
  counter_macro:
    instances:
      u_counter_macro:
        location:
          - 140
          - 140
        orientation: N

    gds:
      - dir::macros/counter_macro/gds/counter_macro.gds

    lef:
      - dir::macros/counter_macro/lef/counter_macro.lef

    vh:
      - dir::macros/counter_macro/vh/counter_macro.vh

    nl:
      - dir::macros/counter_macro/nl/counter_macro.nl.v

    pnl:
      - dir::macros/counter_macro/pnl/counter_macro.pnl.v

    lib:
      "*_tt_025C_1v80":
        - dir::macros/counter_macro/lib/counter_macro__tt.lib

    spef:
      "nom_*":
        - dir::macros/counter_macro/spef/counter_macro.nom.spef

    spice:
      - dir::macros/counter_macro/spice/counter_macro.spice

    sdf: {}

# ------------------------------------------------------------
# Macro keep-out region
# ------------------------------------------------------------

FP_MACRO_HORIZONTAL_HALO: 10
FP_MACRO_VERTICAL_HALO: 10

# ------------------------------------------------------------
# Power distribution network
# ------------------------------------------------------------

VDD_NETS:
  - VPWR

GND_NETS:
  - VGND

VDD_PIN: VPWR
GND_PIN: VGND

FP_PDN_CORE_RING: true

FP_PDN_CORE_RING_VWIDTH: 3.1
FP_PDN_CORE_RING_HWIDTH: 3.1
FP_PDN_CORE_RING_VSPACING: 1.7
FP_PDN_CORE_RING_HSPACING: 1.7
FP_PDN_CORE_RING_VOFFSET: 12.45
FP_PDN_CORE_RING_HOFFSET: 12.45

# Explicit macro power connection.
#
# Format:
# <instance_regex> <macro_vdd_pin> <macro_gnd_pin>
# <top_vdd_net> <top_gnd_net>
PDN_MACRO_CONNECTIONS:
  - u_counter_macro VPWR VGND VPWR VGND

# ------------------------------------------------------------
# Placement
# ------------------------------------------------------------

PL_TARGET_DENSITY_PCT: 40

# ------------------------------------------------------------
# Clock Tree Synthesis
# ------------------------------------------------------------

CTS_CLK_PORT: clk_i

# ------------------------------------------------------------
# Routing
# ------------------------------------------------------------

RT_MAX_LAYER: met5

GRT_ALLOW_CONGESTION: false

# ------------------------------------------------------------
# Timing optimization
# ------------------------------------------------------------

RUN_POST_CTS_RESIZER_TIMING: true
RUN_POST_GRT_RESIZER_TIMING: true

PL_RESIZER_SETUP_SLACK_MARGIN: 0.10
PL_RESIZER_HOLD_SLACK_MARGIN: 0.05

GRT_RESIZER_SETUP_SLACK_MARGIN: 0.10
GRT_RESIZER_HOLD_SLACK_MARGIN: 0.05

# ------------------------------------------------------------
# Signoff
# ------------------------------------------------------------

RUN_MAGIC: true
RUN_KLAYOUT: true
RUN_NETGEN: true

# Prioritize macro gate-level netlist + SPEF for STA.
STA_MACRO_PRIORITIZE_NL: true
```

---

# 12.13 ทำความเข้าใจโครงสร้าง MACROS

โครงสร้างหลักคือ:

```yaml
MACROS:
  <macro-module-name>:
    instances:
      <instance-name>:
        location: [x, y]
        orientation: N

    gds:
      - <gds-path>

    lef:
      - <lef-path>
```

LibreLane กำหนดให้ key ชั้นแรกเป็น **ชื่อ Macro** ส่วน key ใต้ `instances` เป็น **ชื่อ instance** 

ตัวอย่าง:

```yaml
MACROS:
  counter_macro:
```

หมายถึง Macro module:

```systemverilog
module counter_macro (...);
```

ส่วน:

```yaml
instances:
  u_counter_macro:
```

หมายถึง instance:

```systemverilog
counter_macro u_counter_macro (...);
```

---

# 12.14 พิกัดของ Macro

ตัวอย่าง:

```yaml
location:
  - 140
  - 140
```

หมายถึงวาง origin ของ Macro ที่:

```text
X = 140 µm
Y = 140 µm
```

พิกัดอ้างอิงจาก origin ของ die หรือ floorplan ตามระบบพิกัดของ DEF

LibreLane ระบุว่า `location` เป็นคู่พิกัดหน่วยไมโครเมตร และสามารถเว้นไว้เพื่อให้ automatic macro placement ทำงานได้ 

## 12.14.1 ตรวจสอบว่า Macro อยู่ใน Core Area

Core Area คือ:

```yaml
CORE_AREA:
  - 20
  - 20
  - 380
  - 380
```

สมมติ Macro มีขนาด:

```text
120 µm × 100 µm
```

วางที่:

```text
(140, 140)
```

ขอบเขต Macro จะเป็น:

```text
Xmin = 140
Ymin = 140
Xmax = 140 + 120 = 260
Ymax = 140 + 100 = 240
```

จึงอยู่ภายใน Core Area:

```text
20 ≤ X ≤ 380
20 ≤ Y ≤ 380
```

## 12.14.2 ตรวจสอบ Halo

กำหนด Halo:

```yaml
FP_MACRO_HORIZONTAL_HALO: 10
FP_MACRO_VERTICAL_HALO: 10
```

พื้นที่รวม Halo จะเป็น:

```text
Xmin = 140 - 10 = 130
Ymin = 140 - 10 = 130
Xmax = 260 + 10 = 270
Ymax = 240 + 10 = 250
```

พื้นที่ดังกล่าวต้องไม่ชน:

- Core boundary
- Macro อื่น
- PDN ring
- IO pin access region
- Placement blockage สำคัญ

---

# 12.15 Macro Orientation

ค่า orientation ที่ใช้บ่อย ได้แก่:

| Orientation | ความหมายโดยย่อ |
|---|---|
| `N` | ไม่หมุน |
| `S` | หมุน 180 องศา |
| `E` | หมุน 90 องศา |
| `W` | หมุน 270 องศา |
| `FN` | Mirror |
| `FS` | Mirror และหมุน |
| `FE` | Mirror และหมุน |
| `FW` | Mirror และหมุน |

LibreLane รับ orientation ตามนิยาม LEF/DEF และค่าเริ่มต้นของ instance คือทิศทางปกติ `N` หรือ `R0` 

ในการทดลองเริ่มต้นควรใช้:

```yaml
orientation: N
```

การเปลี่ยน orientation ต้องตรวจสอบ:

- Pin access
- Power rail alignment
- Macro symmetry ใน LEF
- Routing congestion
- ระยะทางจาก Macro pins ไปยัง Top-level pins
- ตำแหน่ง clock pin
- ทิศทาง bus pins

---

# 12.16 Macro Halo

Macro Halo คือพื้นที่กันชนรอบ Macro ซึ่งไม่อนุญาตให้วาง standard cells

```yaml
FP_MACRO_HORIZONTAL_HALO: 10
FP_MACRO_VERTICAL_HALO: 10
```

LibreLane ใช้ค่าดังกล่าวระหว่างการตัด placement rows รอบ Macro และช่วยป้องกันการวาง tap cells, endcap cells หรือ standard cells ชิด Macro มากเกินไป 

ประโยชน์ของ Halo:

- เพิ่มพื้นที่ให้ router เข้าถึง Macro pins
- ลด congestion ที่ขอบ Macro
- ลด DRC จาก via และ metal spacing
- ป้องกัน standard cells ขวาง pin access
- เพิ่มพื้นที่สำหรับ PDN straps
- เพิ่มพื้นที่สำหรับ clock/data buffers

แนวทางเริ่มต้น:

```text
Macro ขนาดเล็ก:     5–10 µm
Macro ขนาดกลาง:    10–20 µm
SRAM หรือ Macro ใหญ่: 15–30 µm
```

ค่าจริงขึ้นกับ:

- PDK
- Routing pitch
- Pin density
- จำนวน routing layers
- จำนวน signal pins
- ตำแหน่ง power pins
- Congestion รอบ Macro

---

# 12.17 การเชื่อมต่อ Power Pins

มีสองแนวทางหลัก

## 12.17.1 เชื่อมต่อผ่าน USE_POWER_PINS

ใน Top-level:

```systemverilog
counter_macro u_counter_macro (
`ifdef USE_POWER_PINS
    .VPWR(VPWR),
    .VGND(VGND),
`endif
    ...
);
```

และกำหนด:

```yaml
VDD_NETS:
  - VPWR

GND_NETS:
  - VGND
```

แนวทางนี้ทำให้ power connectivity ปรากฏอยู่ใน hierarchy ของ netlist

## 12.17.2 ใช้ PDN_MACRO_CONNECTIONS

```yaml
PDN_MACRO_CONNECTIONS:
  - u_counter_macro VPWR VGND VPWR VGND
```

ความหมาย:

```text
u_counter_macro
│
├── Macro power pin  VPWR → Top-level net VPWR
└── Macro ground pin VGND → Top-level net VGND
```

ตัวแปรนี้มีประโยชน์เมื่อไม่ต้องการหรือไม่สามารถใช้ `USE_POWER_PINS` โดย LibreLane ระบุให้ใช้ `PDN_MACRO_CONNECTIONS` สำหรับการเชื่อม power ของ instance แบบ explicit 

ต้องตรวจสอบว่าชื่อ instance ตรงกับ synthesized netlist อย่างสมบูรณ์

---

# 12.18 กรณี Macro ใช้ชื่อ VDD/VSS

หาก Macro มี pins:

```text
VDD
VSS
```

แต่ Top-level ใช้:

```text
VPWR
VGND
```

กำหนด:

```yaml
PDN_MACRO_CONNECTIONS:
  - u_counter_macro VDD VSS VPWR VGND
```

ความหมาย:

```text
Macro VDD → Top VPWR
Macro VSS → Top VGND
```

ไม่ควรแก้ชื่อใน LEF โดยพลการ เพราะต้องสอดคล้องกับ:

- GDS labels
- Powered netlist
- SPICE
- LVS extraction
- Liberty pg_pin
- Original macro signoff

---

# 12.19 การเลือก Timing Model

## 12.19.1 ใช้ Liberty

```yaml
STA_MACRO_PRIORITIZE_NL: false
```

ลำดับโดยทั่วไป:

1. ใช้ `.lib`
2. หากไม่มี ให้ใช้ `.nl.v` และ `.spef`
3. หากไม่มีทั้งหมด ให้ทำ STA แบบ black-box

เหมาะกับ Macro ที่:

- Characterize ด้วย commercial characterization tool
- มี Liberty หลาย PVT corners
- มี timing arc สมบูรณ์
- ผ่าน timing validation แล้ว

## 12.19.2 ใช้ Netlist และ SPEF

```yaml
STA_MACRO_PRIORITIZE_NL: true
```

ลำดับโดยทั่วไป:

1. ใช้ `.nl.v` ร่วมกับ `.spef`
2. หากไม่มี ให้ใช้ `.lib`
3. หากไม่มี ให้ทำ STA แบบ black-box

LibreLane ใช้ `STA_MACRO_PRIORITIZE_NL` เพื่อเลือกระหว่าง Liberty กับ netlist-plus-SPEF และเตือนว่าการวิเคราะห์แบบ black-box อาจซ่อน timing violation บริเวณขอบเขต Macro 

---

# 12.20 Timing Corner Mapping

ตัวอย่าง:

```yaml
lib:
  "*_tt_025C_1v80":
    - dir::macros/counter_macro/lib/counter_macro__tt.lib
```

Wildcard นี้สามารถจับ corner เช่น:

```text
nom_tt_025C_1v80
min_tt_025C_1v80
max_tt_025C_1v80
```

LibreLane รองรับ dictionary ที่ใช้ wildcard จับชื่อ timing corner สำหรับ `lib`, `spef` และ `sdf` 

ตัวอย่างหลาย corner:

```yaml
lib:
  "*_ss_100C_1v60":
    - dir::macros/counter_macro/lib/counter_macro__ss.lib

  "*_tt_025C_1v80":
    - dir::macros/counter_macro/lib/counter_macro__tt.lib

  "*_ff_n40C_1v95":
    - dir::macros/counter_macro/lib/counter_macro__ff.lib
```

ชื่อ corner ต้องตรงกับ corner ที่ PDK configuration ใช้จริง

---

# 12.21 รัน Configuration Preflight

ตรวจสอบ YAML:

```bash
python3 - <<'PY'
import yaml

with open("config.yaml", "r", encoding="utf-8") as f:
    config = yaml.safe_load(f)

print("DESIGN_NAME =", config["DESIGN_NAME"])
print("CLOCK_PORT =", config["CLOCK_PORT"])
print("MACROS =", list(config["MACROS"].keys()))
PY
```

ผลที่คาดหวัง:

```text
DESIGN_NAME = macro_wrapper
CLOCK_PORT = clk_i
MACROS = ['counter_macro']
```

ตรวจสอบไฟล์:

```bash
./scripts/check_macro_files.sh
```

---

# 12.22 รัน LibreLane

สำหรับ SKY130:

```bash
librelane \
    --pdk sky130A \
    --scl sky130_fd_sc_hd \
    --run-tag lab12_macro \
    config.yaml
```

หรือหากใช้ environment ที่กำหนด PDK และ SCL ไว้แล้ว:

```bash
librelane \
    --run-tag lab12_macro \
    config.yaml
```

สร้าง `scripts/run.sh`:

```bash
#!/usr/bin/env bash

set -euo pipefail

RUN_TAG="${1:-lab12_macro}"

./scripts/check_macro_files.sh

librelane \
    --pdk sky130A \
    --scl sky130_fd_sc_hd \
    --run-tag "${RUN_TAG}" \
    config.yaml
```

กำหนด permission:

```bash
chmod +x scripts/run.sh
```

รัน:

```bash
./scripts/run.sh
```

หรือกำหนด run tag ใหม่:

```bash
./scripts/run.sh lab12_macro_v2
```

---

# 12.23 ลำดับการทำงานที่เกี่ยวข้องกับ Macro

ระหว่าง flow จะเกิดขั้นตอนสำคัญดังนี้

## ขั้นที่ 1 อ่าน RTL และ Macro Header

Yosys อ่าน:

```text
src/macro_wrapper.sv
macros/counter_macro/vh/counter_macro.vh
```

ผลลัพธ์:

- `macro_wrapper` ถูกสังเคราะห์
- `u_counter_macro` คงอยู่เป็น black-box cell
- Logic ภายใน Macro ไม่ถูกสร้างใหม่

## ขั้นที่ 2 อ่าน Macro LEF

OpenROAD อ่าน LEF เพื่อสร้าง Macro master ซึ่งมี:

- Width
- Height
- Pins
- Obstructions
- Symmetry
- Power ports

## ขั้นที่ 3 สร้าง Floorplan

LibreLane สร้าง:

- Die area
- Core area
- Placement rows
- IO pins
- PDN boundary

## ขั้นที่ 4 วาง Macro

Macro ถูกวางที่:

```text
(140 µm, 140 µm)
```

ด้วย orientation:

```text
N
```

## ขั้นที่ 5 ตัด Rows รอบ Macro

พื้นที่ placement row ที่ทับกับ Macro และ Halo จะถูกตัดออก เพื่อไม่ให้ standard cells ถูกวางซ้อนกับ Macro

## ขั้นที่ 6 เชื่อม Power

ระบบเชื่อม:

```text
u_counter_macro/VPWR → VPWR
u_counter_macro/VGND → VGND
```

## ขั้นที่ 7 สร้าง PDN

PDN generator สร้าง:

- Core ring
- Horizontal straps
- Vertical straps
- Via connections
- Macro power connections

## ขั้นที่ 8 วาง Standard Cells

Standard cells ถูกวางในพื้นที่ว่างรอบ Macro

## ขั้นที่ 9 CTS

Clock Tree Synthesis สร้าง clock network ไปยัง:

- Standard-cell sequential elements
- Clock input ของ Macro

## ขั้นที่ 10 Global Routing

Global router ประเมินเส้นทางรอบ Macro obstruction และพื้นที่ Halo

## ขั้นที่ 11 Detailed Routing

Detailed router เชื่อม signal pins และ power-related geometry ตาม design rules

## ขั้นที่ 12 Stream-out

GDS ของ Macro ถูก merge กับ GDS ของ Top-level

## ขั้นที่ 13 Signoff

ตรวจสอบ:

- STA
- DRC
- LVS
- Antenna
- Connectivity
- Power grid

---

# 12.24 ตรวจสอบ Synthesis Netlist

ค้นหา synthesized netlist:

```bash
find runs/lab12_macro -type f \
    \( -name "*.nl.v" -o -name "*.v" \) | sort
```

ค้นหา instance:

```bash
grep -R "u_counter_macro" runs/lab12_macro \
    --include="*.v"
```

ควรยังพบ:

```verilog
counter_macro u_counter_macro (
    ...
);
```

หากไม่พบ อาจเกิดจาก:

- Instance ถูก optimize ทิ้ง
- Black-box header ไม่ถูกอ่าน
- Module name ไม่ตรง
- Output ไม่ถูกใช้งาน
- Hierarchy ถูกเปลี่ยนชื่อ
- Macro RTL ถูกใส่ใน `VERILOG_FILES` ผิดไฟล์

---

# 12.25 ตรวจสอบชื่อ Instance หลัง Synthesis

หาก Macro อยู่ใน hierarchy เช่น:

```systemverilog
wrapper u_wrapper (
    ...
);
```

และภายใน `wrapper` มี:

```systemverilog
counter_macro u_counter_macro (
    ...
);
```

เมื่อ synthesis flatten hierarchy ชื่ออาจกลายเป็น:

```text
u_wrapper.u_counter_macro
```

ดังนั้น configuration อาจต้องเป็น:

```yaml
instances:
  u_wrapper.u_counter_macro:
    location: [140, 140]
    orientation: N
```

LibreLane ระบุว่าเมื่อ flatten hierarchy ซึ่งเป็นพฤติกรรมปกติ Yosys อาจเปลี่ยนชื่อ instance ภายในให้เป็น dot notation เช่น `instance_a.instance_b` 

วิธีค้นหาชื่อจริง:

```bash
grep -R "counter_macro" runs/lab12_macro \
    --include="*.v" \
    --include="*.def"
```

---

# 12.26 ตรวจสอบ Macro Placement ใน DEF

ค้นหา DEF:

```bash
find runs/lab12_macro -type f -name "*.def" | sort
```

ค้นหา Macro instance:

```bash
grep -R "u_counter_macro" runs/lab12_macro \
    --include="*.def"
```

ตัวอย่างผล:

```def
- u_counter_macro counter_macro
  + PLACED ( 140000 140000 ) N ;
```

หาก DEF ใช้ 1000 database units ต่อไมโครเมตร:

```text
140000 DBU = 140 µm
```

หลัง legal placement อาจเป็น:

```def
+ FIXED ( 140000 140000 ) N ;
```

---

# 12.27 ตรวจสอบด้วย OpenROAD GUI

เปิด run:

```bash
librelane --last-run --flow open-in-openroad config.yaml
```

หรือใช้คำสั่งที่ environment รองรับสำหรับเปิด final ODB/DEF

ใน GUI ตรวจสอบ:

1. Macro อยู่ภายใน Core Area
2. Macro ไม่ทับ Standard Cells
3. Halo รอบ Macroมีพื้นที่ว่าง
4. Signal pins เข้าถึงได้
5. PDN straps เชื่อม Macro power pins
6. ไม่มี route ผ่าน OBS ของ Macro
7. Clock route ไปถึง Macro clock pin
8. ไม่มี congestion รุนแรงที่มุม Macro
9. Macro ไม่บัง IO pin access
10. Macro orientation ถูกต้อง

---

# 12.28 ตรวจสอบ GDS ด้วย KLayout

ค้นหา final GDS:

```bash
find runs/lab12_macro -type f -name "*.gds" | sort
```

เปิด:

```bash
klayout <path-to-final-gds>
```

ตรวจสอบ Cell Hierarchy:

```text
macro_wrapper
└── counter_macro
```

หากไม่พบ `counter_macro` ใน hierarchy อาจเกิดจาก:

- GDS path ผิด
- Top cell ใน Macro GDS ชื่อไม่ตรง
- Merge GDS ไม่สำเร็จ
- Macro instance ถูกลบ
- Macro GDS ว่าง
- Macro ถูก flatten ตอน stream-out อย่างไม่คาดคิด

---

# 12.29 ตรวจสอบ LEF/GDS Alignment

LEF และ GDS ต้องสอดคล้องกันในเรื่อง:

- Cell name
- Origin
- Width
- Height
- Pin locations
- Boundary
- Orientation
- Power labels
- Manufacturing grid

หาก LEF ระบุ:

```lef
SIZE 120.000 BY 100.000 ;
```

GDS bounding box ควรใกล้เคียง:

```text
120 µm × 100 µm
```

หากขนาดไม่ตรง อาจเกิด:

- GDS overlap
- DRC error
- Route เข้าไปใน Macro geometry
- Pin misalignment
- LVS mismatch
- Incorrect stream-out placement

---

# 12.30 ตรวจสอบ PDN Connectivity

ค้นหา log ที่เกี่ยวข้อง:

```bash
grep -R -i \
    -E "macro.*connection|power.*connection|VPWR|VGND|PDN" \
    runs/lab12_macro \
    --include="*.log" \
    --include="*.rpt"
```

ตรวจสอบ:

```text
u_counter_macro/VPWR connected to VPWR
u_counter_macro/VGND connected to VGND
```

ใน OpenROAD GUI เปิดเฉพาะ nets:

```text
VPWR
VGND
```

พิจารณาว่า:

- Ring เชื่อมกับ straps
- Straps ผ่านบริเวณ Macro pins
- Via stack ถูกสร้าง
- Macro power pins อยู่บน layer ที่ PDN เข้าถึงได้
- ไม่มี disconnected island

---

# 12.31 ตรวจสอบ Timing

ค้นหารายงาน:

```bash
find runs/lab12_macro -type f \
    \( -name "max.rpt" \
    -o -name "min.rpt" \
    -o -name "wns*.rpt" \
    -o -name "tns*.rpt" \) | sort
```

ค้นหาเส้นทางที่ผ่าน Macro:

```bash
grep -R "u_counter_macro" runs/lab12_macro \
    --include="*max*.rpt" \
    --include="*min*.rpt" \
    --include="*.rpt"
```

ประเภท timing path ที่ควรตรวจสอบ:

```text
Top-level register → Macro input
Macro output       → Top-level register
Top-level input    → Macro input
Macro output       → Top-level output
Macro internal path
Clock              → Macro clock pin
```

หากรายงานแสดงเพียง:

```text
black-box
```

แสดงว่า STA ยังไม่มี Liberty หรือ netlist-plus-SPEF ที่ใช้งานได้

---

# 12.32 ตรวจสอบ DRC

ค้นหา DRC summary:

```bash
grep -R -i \
    -E "drc.*violation|violations|drc count" \
    runs/lab12_macro \
    --include="*.rpt" \
    --include="*.log"
```

DRC ที่พบบ่อยรอบ Macro:

- Metal spacing
- Via enclosure
- Minimum area
- Pin access
- Off-grid geometry
- Macro boundary overlap
- PDN spacing
- Routing obstruction violation
- Well or implant spacingหลัง GDS merge
- Density-related violation

ตรวจสอบทั้ง:

- KLayout DRC
- Magic DRC
- OpenROAD routing DRC

---

# 12.33 ตรวจสอบ LVS

LVS เปรียบเทียบ:

```text
Extracted layout netlist
          vs.
Schematic/gate-level netlist
```

สำหรับ Macro Integration ต้องตรวจสอบว่า:

1. Macro instance มีทั้งใน layout และ netlist
2. ชื่อ Macro cell ตรงกัน
3. Power pins ตรงกัน
4. Bus pins ตรงกัน
5. ไม่มี dangling signal
6. ไม่มี short ระหว่าง VPWR และ VGND
7. SPICE subcircuit ตรงกับ extracted cell
8. Top-level hierarchy ตรงกัน

ค้นหา LVS report:

```bash
find runs/lab12_macro -type f \
    \( -iname "*lvs*.log" \
    -o -iname "*lvs*.rpt" \
    -o -iname "*netgen*" \) | sort
```

ค้นหา mismatch:

```bash
grep -R -i \
    -E "mismatch|property error|net mismatch|device mismatch|not equivalent" \
    runs/lab12_macro \
    --include="*.log" \
    --include="*.rpt"
```

---

# 12.34 ปัญหาที่พบบ่อยและวิธีแก้

## ปัญหา 1: Macro ไม่พบใน LEF

ข้อความลักษณะ:

```text
Macro counter_macro not found
```

สาเหตุ:

- LEF path ผิด
- ชื่อใน LEF ไม่ตรงกับ module
- LEF ไม่ถูกอ่าน
- ใช้ชื่อ instance แทนชื่อ Macro

ตรวจสอบ:

```bash
grep "^MACRO" macros/counter_macro/lef/counter_macro.lef
```

ต้องได้:

```text
MACRO counter_macro
```

---

## ปัญหา 2: Macro GDS ไม่ถูก merge

สาเหตุ:

- GDS path ผิด
- GDS ว่าง
- Top cell ใน GDS ชื่อไม่ตรง
- GDS เสียหาย
- GDS ใช้ database unit ผิดปกติ

ตรวจสอบ:

```bash
ls -lh macros/counter_macro/gds/counter_macro.gds
klayout macros/counter_macro/gds/counter_macro.gds
```

---

## ปัญหา 3: Instance name ไม่ตรง

Configuration:

```yaml
instances:
  u_counter_macro:
```

แต่ synthesized netlist เป็น:

```text
u_wrapper.u_counter_macro
```

แก้เป็น:

```yaml
instances:
  u_wrapper.u_counter_macro:
    location: [140, 140]
    orientation: N
```

---

## ปัญหา 4: Macro ถูกวางนอก Core

ข้อความลักษณะ:

```text
macro placement outside core
```

คำนวณ:

```text
macro_xmax = macro_x + macro_width
macro_ymax = macro_y + macro_height
```

ต้องเป็น:

```text
core_xmin ≤ macro_x
core_ymin ≤ macro_y
macro_xmax ≤ core_xmax
macro_ymax ≤ core_ymax
```

รวม Halo ด้วย

---

## ปัญหา 5: Macro ทับ PDN Ring

สาเหตุ:

- วาง Macro ใกล้ core boundary เกินไป
- Core ring offset ใหญ่
- Halo ไม่เพียงพอ
- Macro ใหญ่เกิน floorplan

แนวทางแก้:

- ขยับ Macro เข้าด้านใน
- ขยาย Die/Core Area
- ลด ring width หรือ offset อย่างระมัดระวัง
- ปรับ Macro orientation

---

## ปัญหา 6: Macro Power Pins ไม่เชื่อม

ข้อความลักษณะ:

```text
Macro power pin VPWR is not connected
```

ตรวจสอบ:

```yaml
PDN_MACRO_CONNECTIONS:
  - u_counter_macro VPWR VGND VPWR VGND
```

ตรวจสอบชื่อ pin ใน LEF:

```bash
grep -n -E "PIN VPWR|PIN VGND" \
    macros/counter_macro/lef/counter_macro.lef
```

ตรวจสอบว่า pin มี:

```lef
USE POWER ;
```

หรือ:

```lef
USE GROUND ;
```

---

## ปัญหา 7: Routing congestion รอบ Macro

อาการ:

- Global routing overflow
- Detailed routing ล้มเหลว
- Via congestion ที่มุม Macro
- Signal detour ยาวมาก

แนวทางแก้:

1. เพิ่ม Halo
2. ลด `FP_CORE_UTIL`
3. ลด `PL_TARGET_DENSITY_PCT`
4. ขยาย Core Area
5. หมุน Macro
6. วาง Macro ใกล้ pin ที่เชื่อมต่อ
7. กระจาย Macro ออกจากกัน
8. เปิด routing layers เพิ่ม หาก PDK อนุญาต
9. หลีกเลี่ยงการวาง pin-dense side ชิด boundary

ตัวอย่าง:

```yaml
FP_MACRO_HORIZONTAL_HALO: 20
FP_MACRO_VERTICAL_HALO: 20

FP_CORE_UTIL: 30
PL_TARGET_DENSITY_PCT: 35
```

---

## ปัญหา 8: STA ไม่เห็น Delay ของ Macro

อาการ:

```text
Macro analyzed as black-box
```

ตรวจสอบ:

- Liberty path
- SPEF path
- Netlist path
- Corner wildcard
- Module name
- Pin names
- `STA_MACRO_PRIORITIZE_NL`

ทดลองใช้ Liberty:

```yaml
STA_MACRO_PRIORITIZE_NL: false
```

หรือ Netlist และ SPEF:

```yaml
STA_MACRO_PRIORITIZE_NL: true
```

---

## ปัญหา 9: Bus Pin Naming ไม่ตรง

ตัวอย่าง LEF:

```text
count_o[0]
```

แต่ Verilog model ใช้:

```text
count_o<0>
```

ทำให้ pin mapping ผิด

ต้องทำให้ตรงกันทั้ง:

- LEF
- Netlist
- Liberty
- SPEF
- RTL header
- GDS labels

---

## ปัญหา 10: LVS พบ Macro Black Box ไม่ตรง

ตรวจสอบ:

- `.subckt` name ใน SPICE
- Module name ใน powered netlist
- Macro name ใน LEF
- Cell name ใน GDS
- Power pin order
- Signal pin order
- Bus expansion
- Global net definitions

---

# 12.35 การรวม Macro มากกว่าหนึ่ง Instance

ตัวอย่างมี Macro ชนิดเดียวสอง instance:

```systemverilog
counter_macro u_counter_0 (...);
counter_macro u_counter_1 (...);
```

Configuration:

```yaml
MACROS:
  counter_macro:
    instances:
      u_counter_0:
        location: [80, 140]
        orientation: N

      u_counter_1:
        location: [240, 140]
        orientation: N

    gds:
      - dir::macros/counter_macro/gds/counter_macro.gds

    lef:
      - dir::macros/counter_macro/lef/counter_macro.lef

    vh:
      - dir::macros/counter_macro/vh/counter_macro.vh
```

Power connections:

```yaml
PDN_MACRO_CONNECTIONS:
  - u_counter_0 VPWR VGND VPWR VGND
  - u_counter_1 VPWR VGND VPWR VGND
```

ไม่ต้องประกาศ GDS และ LEF ซ้ำ เพราะทั้งสอง instance ใช้ Macro master เดียวกัน

---

# 12.36 การรวม Macro หลายชนิด

ตัวอย่าง:

```yaml
MACROS:
  counter_macro:
    instances:
      u_counter:
        location: [60, 100]
        orientation: N

    gds:
      - dir::macros/counter_macro/gds/counter_macro.gds

    lef:
      - dir::macros/counter_macro/lef/counter_macro.lef

    vh:
      - dir::macros/counter_macro/vh/counter_macro.vh

  register_file_macro:
    instances:
      u_regfile:
        location: [220, 100]
        orientation: FN

    gds:
      - dir::macros/register_file_macro/gds/register_file_macro.gds

    lef:
      - dir::macros/register_file_macro/lef/register_file_macro.lef

    vh:
      - dir::macros/register_file_macro/vh/register_file_macro.vh
```

Power connections:

```yaml
PDN_MACRO_CONNECTIONS:
  - u_counter VPWR VGND VPWR VGND
  - u_regfile VPWR VGND VPWR VGND
```

---

# 12.37 แนวทางการวาง Macro ที่ดี

## 12.37.1 วางตาม Dataflow

ตัวอย่าง:

```text
Input Pins
   │
   ▼
Macro A
   │
   ▼
Macro B
   │
   ▼
Output Pins
```

ควรวาง Macro A ใกล้ input side และ Macro B ใกล้ output side

## 12.37.2 ลดระยะ Clock

หาก Macro มี timing-critical clock pin ควรวางให้:

- Clock trunk เข้าถึงง่าย
- ไม่ต้องอ้อม Macro อื่น
- ไม่อยู่ใน congestion hotspot
- ไม่อยู่ไกลจาก clock source มากเกินไป

## 12.37.3 จัดด้านที่มี Pin จำนวนมากเข้าหาพื้นที่ Routing

หากด้านตะวันออกมี bus pins จำนวนมาก ไม่ควรวางด้านนั้นชิด Core boundary

## 12.37.4 หลีกเลี่ยงช่อง Routing แคบ

ไม่ควรวาง Macro สองตัวใกล้กันจนเกิดช่องแคบ เช่น:

```text
+-----------+  4 µm  +-----------+
| Macro A   |        | Macro B   |
+-----------+        +-----------+
```

ช่องดังกล่าวอาจไม่เพียงพอสำหรับ:

- Signal tracks
- PDN straps
- Via arrays
- Clock buffers
- Standard cells

## 12.37.5 ระวัง Notch

การจัด Macro อาจสร้างพื้นที่เว้าหรือ notch ซึ่ง router เข้าไปทำงานยาก

---

# 12.38 Experiment 1: เปลี่ยนตำแหน่ง Macro

รันกรณี A:

```yaml
location: [60, 140]
```

รันกรณี B:

```yaml
location: [140, 140]
```

รันกรณี C:

```yaml
location: [220, 140]
```

เปรียบเทียบ:

- Wire length
- WNS
- TNS
- Routing overflow
- DRC count
- Clock skew
- Total power
- Final die utilization

ตารางบันทึกผล:

| Run | Macro Location | WNS | TNS | Overflow | DRC | หมายเหตุ |
|---|---:|---:|---:|---:|---:|---|
| A | (60,140) | | | | | |
| B | (140,140) | | | | | |
| C | (220,140) | | | | | |

---

# 12.39 Experiment 2: เปลี่ยน Orientation

ทดลอง:

```yaml
orientation: N
```

```yaml
orientation: S
```

```yaml
orientation: FN
```

เปรียบเทียบ:

- Pin access
- Wire length
- Congestion
- Timing
- DRC
- PDN connectivity

ตาราง:

| Orientation | WNS | Routed Wire Length | DRC | Congestion | หมายเหตุ |
|---|---:|---:|---:|---:|---|
| N | | | | | |
| S | | | | | |
| FN | | | | | |

---

# 12.40 Experiment 3: เปลี่ยน Halo

ทดลอง:

```yaml
FP_MACRO_HORIZONTAL_HALO: 5
FP_MACRO_VERTICAL_HALO: 5
```

จากนั้น:

```yaml
FP_MACRO_HORIZONTAL_HALO: 10
FP_MACRO_VERTICAL_HALO: 10
```

และ:

```yaml
FP_MACRO_HORIZONTAL_HALO: 20
FP_MACRO_VERTICAL_HALO: 20
```

วิเคราะห์ trade-off:

- Halo เล็ก: ใช้พื้นที่ดี แต่ congestion สูง
- Halo ใหญ่: routing ง่ายขึ้น แต่พื้นที่ standard cells ลดลง

---

# 12.41 Experiment 4: Liberty กับ Netlist+SPEF

กรณี A:

```yaml
STA_MACRO_PRIORITIZE_NL: false
```

กรณี B:

```yaml
STA_MACRO_PRIORITIZE_NL: true
```

เปรียบเทียบ:

- Runtime
- WNS
- TNS
- Path detail
- Boundary timing
- Macro internal paths
- Corner coverage

---

# 12.42 เกณฑ์ผ่านบทปฏิบัติการ

ถือว่าผ่าน Lab เมื่อ:

- [ ] LibreLane อ่าน `config.yaml` ได้
- [ ] LEF และ GDS ของ Macro ถูกโหลด
- [ ] Macro instance ปรากฏใน synthesized netlist
- [ ] Macro ถูกวางในตำแหน่งที่กำหนด
- [ ] Orientation ถูกต้อง
- [ ] Standard cells ไม่ทับ Macro
- [ ] มี Halo รอบ Macro
- [ ] Power และ Ground ของ Macro เชื่อมต่อ
- [ ] Signal routing เข้าถึง Macro pins
- [ ] Clock เชื่อมถึง Macro clock pin
- [ ] Final GDS มี Macro cell
- [ ] STA ไม่มี setup/hold violation ที่ยอมรับไม่ได้
- [ ] Global routing ไม่มี overflow
- [ ] Detailed routing สำเร็จ
- [ ] DRC ผ่านตามเกณฑ์
- [ ] LVS ผ่าน
- [ ] ไม่มี unresolved black box ที่ไม่ตั้งใจ

---

# 12.43 คำถามท้ายบท

1. เหตุใด LEF และ GDS จึงต้องใช้ร่วมกันในการรวม Macro?
2. LEF มีข้อมูลอะไรที่ OpenROAD ใช้ระหว่าง Place-and-Route?
3. เหตุใด GDS เพียงอย่างเดียวจึงไม่เพียงพอสำหรับ PnR?
4. Key ชั้นแรกของ `MACROS` ต้องเป็นชื่อ module หรือชื่อ instance?
5. Key ภายใต้ `instances` ต้องตรงกับข้อมูลส่วนใดของ netlist?
6. `FP_MACRO_HORIZONTAL_HALO` และ `FP_MACRO_VERTICAL_HALO` มีผลอย่างไร?
7. Macro placement ที่ไม่ดีส่งผลต่อ timing อย่างไร?
8. เหตุใด routing congestion จึงมักเกิดบริเวณมุม Macro?
9. `PDN_MACRO_CONNECTIONS` ใช้ในกรณีใด?
10. หาก Macro ใช้ `VDD/VSS` แต่ Top-level ใช้ `VPWR/VGND` ต้องกำหนดอย่างไร?
11. Liberty ต่างจาก SPEF อย่างไร?
12. เหตุใด STA แบบ black-box จึงอาจไม่พบ boundary violation?
13. ถ้า synthesized instance name เปลี่ยนจาก `u_macro` เป็น `u_sub.u_macro` ต้องแก้ configuration อย่างไร?
14. จะตรวจสอบได้อย่างไรว่า Macro GDS ถูก merge เข้า final GDS แล้ว?
15. เหตุใดชื่อ pin ใน LEF, Liberty, Verilog และ SPICE ต้องตรงกัน?

---

# 12.44 แบบฝึกหัดเพิ่มเติม

## แบบฝึกหัด 1

เพิ่ม Macro ตัวที่สอง:

```text
u_counter_macro_1
```

กำหนดตำแหน่งและ PDN connection ให้ครบ

## แบบฝึกหัด 2

สร้าง Macro placement สามรูปแบบ:

- วางตรงกลาง
- วางชิดด้านซ้าย
- วางชิดด้านขวา

เปรียบเทียบ QoR

## แบบฝึกหัด 3

ทดลองหมุน Macro และวิเคราะห์ pin accessibility

## แบบฝึกหัด 4

นำ Liberty ออกจาก `MACROS` และสังเกตผลของ STA

## แบบฝึกหัด 5

นำ SPEF ออก แล้วเปรียบเทียบรายงาน timing

## แบบฝึกหัด 6

ลด Halo จนเกิด congestion จากนั้นปรับแก้ให้ flow ผ่าน

## แบบฝึกหัด 7

เปลี่ยนชื่อ power pin ของ Macro เป็น `VDD/VSS` และกำหนด `PDN_MACRO_CONNECTIONS` ให้เชื่อมกับ `VPWR/VGND`

---

# 12.45 สรุป

Macro Integration เป็นขั้นตอนสำคัญของการออกแบบระบบ ASIC แบบลำดับชั้น ผู้พัฒนาต้องดูแลความสอดคล้องของข้อมูลทั้งด้าน Logical, Physical, Timing และ Power

องค์ประกอบสำคัญที่สุด ได้แก่:

```text
Logical Interface
├── Verilog Header
├── Gate-level Netlist
└── Powered Netlist

Physical Interface
├── LEF
└── GDS

Timing Interface
├── Liberty
├── SPEF
└── SDF

Electrical Interface
├── Power Pins
├── Ground Pins
└── SPICE

Integration Configuration
├── MACROS
├── instances
├── location
├── orientation
├── halo
└── PDN_MACRO_CONNECTIONS
```

การรวม Macro ที่สำเร็จไม่ได้หมายถึงเพียงการทำให้ flow รันจนจบ แต่ต้องยืนยันว่า:

- Layout ถูกต้อง
- Macro อยู่ในตำแหน่งเหมาะสม
- Pins เข้าถึงได้
- Power เชื่อมต่อครบ
- Timing model ถูกใช้งาน
- Routing ไม่ congestion
- Final GDS มี geometry ของ Macro
- DRC และ LVS ผ่าน
- ผลลัพธ์พร้อมใช้เป็นส่วนหนึ่งของระบบระดับสูงขึ้น

ด้วยโครงสร้าง `MACROS` ใน `config.yaml` LibreLane สามารถรวบรวมข้อมูล Macro ทั้งด้าน Physical, Logical และ Timing ไว้ใน configuration เดียว ทำให้การพัฒนา Hierarchical ASIC Design มีความเป็นระบบ ตรวจสอบซ้ำได้ และนำ Macro กลับมาใช้ใหม่ได้สะดวก
:::

จุดที่ต้องปรับตาม Macro และ PDK จริงเป็นหลักคือชื่อ power pins, timing-corner wildcard, routing layer, ค่า PDN และชื่อ instance หลัง synthesis flatten hierarchy.