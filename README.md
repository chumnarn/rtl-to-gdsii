# RTL-to-GDSII Workshop 2026 — คู่มือฉบับย่อ

## Short Reference Guide: LibreLane \+ IHP SG13G2 PDK

> คู่มือนี้เป็นฉบับย่อของ Lab 1–15 ครอบคลุมวัตถุประสงค์ ขั้นตอนสำคัญ คำสั่งหลัก และเกณฑ์ผ่านของทุก Lab  
> เครื่องมือหลัก: **LibreLane · Yosys · OpenROAD · OpenSTA · Magic · KLayout · Netgen · Verilator**

---

## ตารางสรุป Lab ทั้ง 15

| Lab | หัวข้อ | เครื่องมือหลัก | ผลลัพธ์สำคัญ |
| :---- | :---- | :---- | :---- |
| 01 | Environment Setup & Tool Verification | Nix, LibreLane, Git | สภาพแวดล้อมพร้อมใช้, smoke test ผ่าน |
| 02 | Counter RTL Simulation & Verification | Verilator, GTKWave | Waveform FST, self-checking testbench PASS |
| 03 | First RTL-to-GDSII Implementation | LibreLane Classic Flow | GDSII ครั้งแรก, DRC/LVS ผ่าน |
| 04 | LibreLane Configuration Variables | config.yaml, LibreLane | เข้าใจตัวแปร FP/PL/PDN และผลลัพธ์ |
| 05 | Floorplan and Pin Placement | OpenROAD, LibreLane | Die/Core กำหนดขนาดได้, Pin ตรงตำแหน่ง |
| 06 | Synthesis and Static Timing Analysis | Yosys, OpenSTA | Netlist \+ timing report, WNS/TNS |
| 07 | Placement Optimization | OpenROAD, LibreLane | Global+Detailed Placement ผ่าน legality |
| 08 | Clock Tree Synthesis | OpenROAD CTS | Clock tree สร้างสำเร็จ, skew ยอมรับได้ |
| 09 | Global and Detailed Routing | OpenROAD, LibreLane | Routed DEF, DRC=0, overflow=0 |
| 10 | Physical Verification – DRC & LVS | Magic, KLayout, Netgen | DRC=0, LVS "Circuits match" |
| 11 | Controlling & Debugging the Flow | LibreLane CLI | ควบคุม Step ได้, debug อย่างเป็นระบบ |
| 12 | Macro Integration | LibreLane, OpenROAD | Top-level \+ Hard Macro, GDSII รวม |
| 13 | Hierarchical Physical Design | LibreLane, OpenROAD | Block hardening \+ Top-level integration |
| 14 | LibreLane Python API | Python, LibreLane | Parameter sweep, custom flow จาก script |
| 15 | Full-Chip Design with IO Pads | LibreLane Chip Flow | Full-chip GDSII พร้อม pad ring |

---

## Lab 1: Environment Setup and Tool Verification

### วัตถุประสงค์

ติดตั้งและตรวจสอบสภาพแวดล้อมสำหรับ RTL-to-GDSII ด้วย LibreLane บน Ubuntu / WSL2

ผู้เรียนจะสามารถ:

1. ตรวจสอบ hardware (CPU ≥4 cores, RAM ≥8 GB, Disk ≥30 GB)  
2. ติดตั้ง Nix package manager  
3. Clone Workshop repository  
4. เข้า LibreLane environment ด้วย `nix-shell`  
5. ตรวจสอบเครื่องมือทั้งหมด (LibreLane, Yosys, OpenROAD, KLayout, Magic, Verilator ฯลฯ)  
6. รัน smoke test เพื่อยืนยันสภาพแวดล้อม

### ขั้นตอนสำคัญ

1. ตรวจสอบระบบ  
2. ติดตั้ง Nix  
3. Clone repo และเข้า nix-shell  
4. ตรวจสอบเครื่องมือแต่ละตัว  
5. รัน smoke test  
6. สร้าง environment report

### คำสั่งหลัก

\# ติดตั้ง Nix

curl \-L https://nixos.org/nix/install | sh \-s \-- \--daemon

\# Clone repository

git clone https://github.com/chumnarn/heichips26-digital-workshop.git

cd heichips26-digital-workshop

\# เข้า environment

nix-shell

\# ตรวจสอบ LibreLane

librelane \--version

librelane \--smoke-test

\# ตรวจสอบเครื่องมือทั้งหมด

./verify\_tools.sh

### เกณฑ์ผ่าน

- [ ] `IN_NIX_SHELL` มีค่า  
- [ ] `librelane --version` ทำงาน  
- [ ] `librelane --smoke-test` คืน exit code 0  (Smoke test passed)
- [ ] เครื่องมือหลักทุกตัวแสดง `[PASS]` (Yosys, OpenROAD, KLayout, Magic, Verilator, Netgen)  
- [ ] PDK เข้าถึงได้

---

## Lab 2: Counter RTL Simulation and Verification

### วัตถุประสงค์

ตรวจสอบการทำงานของวงจรเคาน์เตอร์ 8 บิตก่อนเข้าสู่กระบวนการ Physical Design

ผู้เรียนจะสามารถ:

1. สร้าง clock/reset stimulus ใน SystemVerilog testbench  
2. สร้าง self-checking testbench ที่ตรวจสอบผลอัตโนมัติ  
3. คอมไพล์และรัน simulation ด้วย Verilator  
4. สร้างและวิเคราะห์ waveform ด้วย GTKWave  
5. ตรวจสอบ normal count, reset, overflow (0xFF→0x00)

### ขั้นตอนสำคัญ

1. ตรวจสอบ RTL interface (`clk_i`, `rst_ni`, `count_o[7:0]`)  
2. เขียน testbench สร้าง clock 10 ns, assert reset ตอนต้น  
3. เพิ่ม reference model และ error counter  
4. คอมไพล์ด้วย Verilator \+ lint check  
5. รัน simulation สร้าง FST waveform  
6. เปิด GTKWave ตรวจสอบ sequence `FE→FF→00`

### คำสั่งหลัก

\# Lint check

verilator \--lint-only \--Wall \--sv rtl/counter.sv

\# คอมไพล์และรัน simulation

verilator \--binary \--trace-fst \--sv \\

  rtl/counter.sv tb/counter\_tb.sv \\

  \-o sim/counter\_sim

./sim/counter\_sim

\# เปิด waveform

gtkwave waves/counter.fst

\# ใช้ Makefile

make lint

make run

### เกณฑ์ผ่าน

- [ ] `make lint` ไม่มี error  
- [ ] `make run` แสดง `LAB RESULT: PASS`  
- [ ] exit code \= 0  
- [ ] มีไฟล์ `waves/counter.fst`  
- [ ] เห็นลำดับ `FE → FF → 00` ใน waveform  
- [ ] Reset ระหว่างทำงานทำให้ count กลับเป็น 0

---

## Lab 3: First RTL-to-GDSII Implementation

### วัตถุประสงค์

นำวงจร Counter ผ่าน RTL-to-GDSII Flow ครั้งแรกด้วย LibreLane Classic Flow และ IHP SG13G2 PDK

ผู้เรียนจะสามารถ:

1. สร้าง `config.yaml` สำหรับ LibreLane  
2. รัน LibreLane Classic Flow ตั้งแต่ synthesis จนถึง signoff  
3. ตรวจสอบ log, warning, metrics ของแต่ละขั้นตอน  
4. เปิด physical design ด้วย OpenROAD GUI และ KLayout  
5. ตรวจสอบว่า DRC, LVS, Timing ผ่าน

### ขั้นตอนสำคัญ

1. ตรวจสอบ RTL ด้วย Verilator lint  
2. สร้าง `config.yaml` กำหนด DESIGN\_NAME, CLOCK\_PORT, CLOCK\_PERIOD  
3. รัน LibreLane เต็ม flow  
4. ตรวจสอบ run directory และผลลัพธ์  
5. เปิด GDSII ด้วย KLayout

### คำสั่งหลัก

\# ตรวจสอบ RTL ก่อน

verilator \--lint-only \--Wall \--sv counter.sv

yosys \-p "read\_verilog \-sv counter.sv; hierarchy \-check \-top counter; check"

\# รัน LibreLane

librelane \--pdk ihp-sg13g2 config.yaml

\# เปิด GDSII

klayout runs/\<tag\>/final/gds/counter.gds

**ตัวอย่าง `config.yaml`:**

DESIGN\_NAME: counter

VERILOG\_FILES:

  \- dir::rtl/counter.sv

CLOCK\_PORT: clk\_i

CLOCK\_PERIOD: 10   \# 10 ns \= 100 MHz

### เกณฑ์ผ่าน

- [ ] LibreLane flow จบโดยไม่มี fatal error  
- [ ] พบ GDSII, DEF, ODB, SPEF, SDF ใน run directory  
- [ ] Setup timing ผ่าน (WNS ≥ 0\)  
- [ ] Hold timing ผ่าน  
- [ ] DRC \= 0, LVS ผ่าน, Antenna ผ่าน  
- [ ] OpenROAD GUI และ KLayout เปิด design ได้

---

## Lab 4: LibreLane Configuration Variables

### วัตถุประสงค์

เข้าใจและทดลองตัวแปร Configuration ของ LibreLane เพื่อควบคุมผลลัพธ์ทางกายภาพ

ผู้เรียนจะสามารถ:

1. แยกแยะ Design / Flow / Step Configuration  
2. กำหนด Die Area, Core Area, Core Utilization, Placement Density  
3. กำหนดตำแหน่ง I/O pin ด้วย `pins.cfg`  
4. ใช้ DEF template บังคับขนาดและตำแหน่งขา  
5. สร้าง Placement Obstruction  
6. ใช้ prefix `dir::`, `ref::`, `expr::`, `pdk::` ใน config

### ขั้นตอนสำคัญ

1. สร้าง baseline `config.yaml` และรัน  
2. ทดลองเปลี่ยน `FP_CORE_UTIL` และ `PL_TARGET_DENSITY_PCT`  
3. สร้าง `pins.cfg` กำหนดตำแหน่ง pin  
4. ทดลอง DEF template  
5. เก็บ metrics เปรียบเทียบแต่ละ experiment

### คำสั่งหลัก

\# รัน baseline

librelane \--pdk ihp-sg13g2 config.yaml

\# ตัวอย่างตัวแปรสำคัญใน config.yaml

FP\_SIZING: absolute

DIE\_AREA: \[0.0, 0.0, 300.0, 300.0\]

CORE\_AREA: \[20.0, 20.0, 280.0, 280.0\]

FP\_CORE\_UTIL: 40

PL\_TARGET\_DENSITY\_PCT: 55

FP\_PIN\_ORDER\_CFG: dir::pins.cfg

FP\_DEF\_TEMPLATE: dir::template.def

### เกณฑ์ผ่าน

- [ ] `config.yaml` ถูกต้อง syntax  
- [ ] Flow รันได้ทุก experiment  
- [ ] เข้าใจ relative vs. absolute sizing  
- [ ] เปรียบเทียบ metrics ≥3 configuration  
- [ ] Custom pin placement ถูกต้อง  
- [ ] เก็บผล Area, Timing, Congestion ครบ

---

## Lab 5: Floorplan and Pin Placement

### วัตถุประสงค์

ศึกษาการสร้าง Floorplan และกำหนดตำแหน่ง I/O Pin ด้วย LibreLane

ผู้เรียนจะสามารถ:

1. กำหนดขนาด Die และ Core แบบ Absolute  
2. คำนวณ Core Margin และ Core Utilization  
3. กำหนด Pin ทั้ง 4 ด้าน (North/South/East/West) ด้วย `pin_order.cfg`  
4. ใช้ Regular Expression สำหรับ Bus pins  
5. ตรวจสอบผลด้วย OpenROAD GUI

### ขั้นตอนสำคัญ

1. กำหนด DIE\_AREA และ CORE\_AREA ใน config.yaml  
2. สร้าง `pin_order.cfg` กำหนด pin แต่ละด้าน  
3. รัน LibreLane ถึงขั้น Floorplan  
4. ตรวจสอบ ODB/DEF ว่า pin ครบและไม่ซ้อนกัน  
5. เปรียบเทียบ Density 35% vs. 65%

### คำสั่งหลัก

\# รัน LibreLane ถึง floorplan เท่านั้น

librelane \--pdk ihp-sg13g2 config.yaml \--to OpenROAD.IOPlacement

\# ตรวจสอบ pin

make pins    \# แสดง pin ครบ 21 ขา

\# เปิด GUI

openroad \-gui

**ตัวอย่าง `pin_order.cfg`:**

\#N

clk rst\_n enable\_i load\_i

\#E

data\_i\[0\] data\_i\[1\] data\_i\[2\] data\_i\[3\] data\_i\[4\] data\_i\[5\] data\_i\[6\] data\_i\[7\]

\#S

terminal\_o

\#W

count\_o\[0\] count\_o\[1\] count\_o\[2\] count\_o\[3\] count\_o\[4\] count\_o\[5\] count\_o\[6\] count\_o\[7\]

### เกณฑ์ผ่าน

- [ ] Die ≈ 300×300 µm, Core ≈ 260×260 µm  
- [ ] Pin ทุกตัวอยู่ด้านที่กำหนด ไม่ซ้อนกัน  
- [ ] Synthesis และ Floorplan ผ่าน  
- [ ] เปิด ODB/DEF ตรวจสอบได้

---

## Lab 6: Synthesis and Static Timing Analysis

### วัตถุประสงค์

เข้าใจ Logic Synthesis และ Static Timing Analysis โดยใช้ Yosys และ OpenSTA ผ่าน LibreLane

ผู้เรียนจะสามารถ:

1. รัน synthesis และ pre-PnR STA  
2. อ่าน synthesized netlist และ cell statistics  
3. วิเคราะห์ WNS, TNS และ critical path  
4. เขียน SDC constraint ที่ถูกต้อง  
5. ทดลองปรับ clock period และสังเกตผล

### ขั้นตอนสำคัญ

1. สร้าง `config.yaml` ระบุ VERILOG\_FILES, CLOCK\_PORT, CLOCK\_PERIOD  
2. สร้าง `pnr.sdc` และ `signoff.sdc`  
3. รัน LibreLane ถึงขั้น STA  
4. อ่าน timing report: WNS, TNS, critical path  
5. เปรียบเทียบผลที่ 10 ns vs. 5 ns

### คำสั่งหลัก

\# รัน synthesis และ STA

librelane \--pdk ihp-sg13g2 config.yaml \--to OpenROAD.STAPrePNR

\# อ่าน timing report

cat runs/\<tag\>/\*/reports/sta/max.rpt | head \-60

**ตัวอย่าง `pnr.sdc`:**

create\_clock \-name clk \-period 10.0 \[get\_ports clk\_i\]

set\_input\_delay  \-clock clk \-max 2.0 \[all\_inputs\]

set\_output\_delay \-clock clk \-max 2.0 \[all\_outputs\]

set\_load 0.01 \[all\_outputs\]

set\_clock\_uncertainty 0.25 \[get\_clocks clk\]

**เกณฑ์ timing:**

WNS \>= 0   (positive slack \= pass)

TNS  \= 0   (ไม่มี violating endpoint)

### เกณฑ์ผ่าน

- [ ] Synthesis จบไม่มี fatal error  
- [ ] Gate-level netlist ถูกสร้าง  
- [ ] ไม่มี inferred latch  
- [ ] Clock ถูกสร้างสำเร็จ  
- [ ] อ่าน WNS/TNS และ critical path ได้  
- [ ] เปรียบเทียบ timing ที่ 2 clock period

---

## Lab 7: Placement Optimization

### วัตถุประสงค์

เข้าใจ Global Placement และ Detailed Placement พร้อมปรับ configuration เพื่อ QoR ที่ดีที่สุด

ผู้เรียนจะสามารถ:

1. กำหนด Core Utilization และ Placement Density  
2. เปิดใช้ Timing-driven และ Routability-driven Placement  
3. ตรวจสอบ HPWL, Congestion, Density และ Timing หลัง placement  
4. เปรียบเทียบ placement ≥3 configuration  
5. ระบุสาเหตุ Placement Failure

### ขั้นตอนสำคัญ

1. สร้าง baseline config (FP\_CORE\_UTIL=40, PL\_TARGET\_DENSITY\_PCT=55)  
2. รัน LibreLane ถึง Detailed Placement  
3. เปิด OpenROAD GUI ตรวจสอบ density map  
4. ทดลอง density ต่ำ (35%) vs. สูง (65%)  
5. เปรียบเทียบ HPWL, Timing, Congestion

### คำสั่งหลัก

\# รันถึง Detailed Placement

librelane \--pdk ihp-sg13g2 config.yaml \--to OpenROAD.DetailedPlacement

\# ตัวแปรสำคัญ

FP\_CORE\_UTIL: 40

PL\_TARGET\_DENSITY\_PCT: 55

PL\_TIMING\_DRIVEN: true

PL\_ROUTABILITY\_DRIVEN: true

### เกณฑ์ผ่าน

- [ ] Global Placement สำเร็จ  
- [ ] Detailed Placement สำเร็จ  
- [ ] ไม่มี Unplaced Instance หรือ Illegal Overlap  
- [ ] Placement ผ่าน Legality Check  
- [ ] เปรียบเทียบ ≥3 configuration ได้  
- [ ] Flow เดินหน้าสู่ CTS ได้

---

## Lab 8: Clock Tree Synthesis

### วัตถุประสงค์

เข้าใจและตรวจสอบ Clock Tree Synthesis (CTS) ด้วย OpenROAD TritonCTS

ผู้เรียนจะสามารถ:

1. อธิบาย clock source, sink, latency, insertion delay, clock skew  
2. กำหนด CTS configuration ใน `config.yaml`  
3. รัน LibreLane ถึง CTS  
4. วิเคราะห์ clock skew, latency, transition violations  
5. เปิดดู clock tree ใน OpenROAD GUI  
6. ปรับแต่ง CTS เพื่อแก้ skew สูง หรือ hold violation

### ขั้นตอนสำคัญ

1. ยืนยัน placement สำเร็จและ utilization ไม่สูงเกิน  
2. กำหนด CTS variables ใน config  
3. รัน LibreLane ถึง Post-CTS Optimization  
4. ตรวจสอบ clock skew report  
5. เปรียบเทียบ setup/hold timing ก่อนและหลัง CTS

### คำสั่งหลัก

\# รันถึง CTS

librelane \--pdk ihp-sg13g2 config.yaml \--to OpenROAD.CTS

\# ตัวแปร CTS ใน config.yaml

CTS\_TARGET\_SKEW: 200        \# target skew (ps)

CTS\_MAX\_CAP: 0.25           \# max capacitance (pF)

CTS\_CLK\_BUFFER\_LIST:

  \- sg13g2\_buf\_2

  \- sg13g2\_buf\_4

  \- sg13g2\_buf\_8

**เกณฑ์ CTS สำหรับ Workshop:**

Clock skew \< 400 ps   → ดี

Clock skew \< 600 ps   → ยอมรับได้

Clock skew \>= 600 ps  → ต้องปรับแต่ง

### เกณฑ์ผ่าน

- [ ] CTS สร้าง clock tree สำเร็จ  
- [ ] มี clock buffer ถูกเพิ่มใน design  
- [ ] ไม่มี unconnected clock sinks  
- [ ] Setup WNS/TNS ยอมรับได้  
- [ ] ไม่มี transition/capacitance violations รุนแรง  
- [ ] OpenROAD GUI แสดง clock tree ได้

---

## Lab 9: Global and Detailed Routing

### วัตถุประสงค์

เชื่อมต่อสายสัญญาณทางกายภาพหลัง CTS ด้วย OpenROAD Router

ผู้เรียนจะสามารถ:

1. อธิบาย GCell, Routing Capacity, Congestion, Overflow  
2. กำหนด Routing Layer และ Routing Capacity ใน config  
3. รัน Global Routing และ Detailed Routing  
4. ตรวจสอบ overflow, DRC violation, antenna violation  
5. แก้ congestion โดยปรับ floorplan หรือ routing configuration

### ขั้นตอนสำคัญ

1. รัน Global Routing และตรวจ congestion map  
2. แก้ overflow ถ้ามี (ลด utilization หรือปรับ layer)  
3. รัน Detailed Routing  
4. ตรวจสอบ Routing DRC \= 0  
5. ตรวจสอบ antenna violation

### คำสั่งหลัก

\# รัน routing ทั้งหมด

librelane \--pdk ihp-sg13g2 config.yaml \--to OpenROAD.DetailedRouting

\# ตัวแปรสำคัญ

GRT\_ADJUSTMENT: 0.25         \# reserve routing resources

RT\_MAX\_LAYER: met5           \# สูงสุดที่ router ใช้ได้

GRT\_ALLOW\_CONGESTION: false  \# ห้ามข้ามเมื่อ overflow \> 0

DRT\_OPT\_ITERS: 64            \# iteration ของ detailed router

**Signoff checklist routing:**

Global routing overflow  \= 0

Detailed routing DRC     \= 0

Unrouted nets            \= 0

Disconnected pins        \= 0

### เกณฑ์ผ่าน

- [ ] Global routing overflow \= 0  
- [ ] Detailed routing DRC \= 0  
- [ ] Unrouted nets \= 0  
- [ ] Antenna violations \= 0 หรือมีแผนซ่อม  
- [ ] Setup/Hold timing ผ่านหลัง routing

---

## Lab 10: Physical Verification – DRC and LVS

### วัตถุประสงค์

ตรวจสอบความถูกต้องทางกายภาพของ layout ก่อน tapeout

ผู้เรียนจะสามารถ:

1. รัน Magic DRC และ KLayout DRC  
2. รัน Netgen LVS เปรียบเทียบ layout netlist กับ schematic  
3. ตรวจสอบ GDS stream-out จาก Magic และ KLayout  
4. ระบุตำแหน่ง DRC violation ใน GUI  
5. จัดทำ Signoff Report

### ขั้นตอนสำคัญ

1. รัน LibreLane full flow (รวม DRC/LVS steps)  
2. ตรวจ Magic DRC report: `reports/drc_violations.magic.rpt`  
3. ตรวจ KLayout DRC: `reports/drc_violations.klayout.json`  
4. ตรวจ Netgen LVS: หา `Circuits match uniquely`  
5. เปิด KLayout ตรวจสอบ layout ด้วยตา

### คำสั่งหลัก

\# รัน full flow รวม verification

librelane \--pdk ihp-sg13g2 config.yaml

\# ตรวจสอบผล DRC

find runs/ \-name '\*-magic-drc' | sort | tail \-1 | xargs ls

cat .../reports/drc\_violations.magic.rpt

\# ตรวจสอบ LVS

find runs/ \-name '\*-netgen-lvs' | sort | tail \-1 | xargs ls

grep \-i "match\\|mismatch" .../reports/lvs.rpt

\# เปิด layout

klayout runs/\<tag\>/final/gds/counter.gds

### เกณฑ์ผ่าน

- [ ] Magic DRC violations \= 0  
- [ ] KLayout DRC violations \= 0  
- [ ] Netgen LVS: `Circuits match uniquely`  
- [ ] GDS stream-out สำเร็จ (Magic \+ KLayout)  
- [ ] KLayout XOR ผ่าน หรือมีคำอธิบาย  
- [ ] Signoff Report ครบ

---

## Lab 11: Controlling and Debugging the Flow

### วัตถุประสงค์

ควบคุม LibreLane Flow ในระดับ Step และแก้ปัญหาอย่างเป็นระบบ

ผู้เรียนจะสามารถ:

1. เข้าใจโครงสร้าง Flow → Step → State  
2. รัน Flow เฉพาะช่วง (`--from`, `--to`, `--skip`)  
3. อ่าน `error.log`, `warning.log`, step logs, `resolved.json`  
4. ใช้ run tag แยก experiment  
5. สร้าง Debug Matrix เปรียบเทียบผลหลาย configuration  
6. แก้ปัญหา RTL, timing, DRC/LVS อย่างเป็นลำดับ

### ขั้นตอนสำคัญ

1. รัน `librelane --help` ตรวจสอบ options  
2. รัน partial flow เพื่อตรวจสอบ intermediate result  
3. หยุดที่ Step ที่สงสัย วิเคราะห์ State  
4. เปลี่ยน config ทีละ 1 ตัวแปร ตั้ง run tag ใหม่  
5. เปรียบเทียบ `resolved.json` ระหว่าง runs

### คำสั่งหลัก

\# ดูรายการ options

librelane \--help

\# หยุดที่ step ที่ต้องการ

librelane \--pdk ihp-sg13g2 config.yaml \\

  \--to OpenROAD.Floorplan

\# รันจาก step ที่กำหนด

librelane \--pdk ihp-sg13g2 config.yaml \\

  \--from OpenROAD.GlobalPlacement \\

  \--to OpenROAD.DetailedPlacement

\# ข้าม step

librelane \--pdk ihp-sg13g2 config.yaml \\

  \--skip KLayout.DRC

\# ดู resolved config

cat runs/\<tag\>/resolved.json | python3 \-m json.tool | head \-40

### เกณฑ์ผ่าน

- [ ] รัน partial flow (`--from`/`--to`) ได้  
- [ ] อ่าน error.log และระบุ root cause ได้  
- [ ] ใช้ run tag แยก experiment  
- [ ] มี `resolved.json` สำหรับ reproducibility  
- [ ] เปรียบเทียบ metrics ≥2 configuration

---

## Lab 12: Macro Integration

### วัตถุประสงค์

นำ Hard Macro มาประกอบกับ Top-level Design ใน LibreLane

ผู้เรียนจะสามารถ:

1. เตรียม Macro views: LEF, GDS, Verilog netlist, Liberty, SPEF  
2. เขียน RTL top-level ที่ instantiate Hard Macro  
3. ประกาศ Macro ด้วย `MACROS` ใน `config.yaml`  
4. กำหนดตำแหน่ง, orientation, Halo และ PDN connection ของ Macro  
5. ตรวจสอบ Macro placement, routing, timing, DRC, LVS

### ขั้นตอนสำคัญ

1. เตรียม directory structure ของ Macro views  
2. เขียน top-level RTL instantiate Macro  
3. กำหนด `MACROS` section ใน config.yaml  
4. รัน LibreLane full flow  
5. ตรวจสอบว่า Macro ถูก placed และ routed ถูกต้อง

### คำสั่งหลัก

\# รัน LibreLane พร้อม Macro

librelane \--pdk ihp-sg13g2 config.yaml

**ตัวอย่าง `config.yaml` ส่วน MACROS:**

DESIGN\_NAME: soc\_top

VERILOG\_FILES:

  \- dir::rtl/soc\_top.sv

MACROS:

  counter\_macro:

    gds:

      \- dir::macros/counter\_macro/gds/counter\_macro.gds

    lef:

      \- dir::macros/counter\_macro/lef/counter\_macro.lef

    instances:

      u\_counter\_macro:

        location: \[50.0, 50.0\]

        orientation: N

FP\_MACRO\_HORIZONTAL\_HALO: 10

FP\_MACRO\_VERTICAL\_HALO: 10

### เกณฑ์ผ่าน

- [ ] LEF และ GDS โหลดสำเร็จ  
- [ ] Macro instance ปรากฏใน synthesized netlist  
- [ ] Macro ถูกวางตำแหน่งที่กำหนด, ไม่ทับ standard cells  
- [ ] Power/Ground ของ Macro เชื่อมต่อ  
- [ ] Signal routing เข้าถึง Macro pins  
- [ ] DRC \= 0, LVS ผ่าน

---

## Lab 13: Hierarchical Physical Design

### วัตถุประสงค์

ออกแบบวงจรขนาดใหญ่โดยแบ่งเป็น Hard Macro หลายบล็อกและประกอบที่ Top-level

ผู้เรียนจะสามารถ:

1. แบ่งระบบออกเป็น block-level (Counter Macro \+ Accumulator Macro)  
2. Harden แต่ละ block แยกกันด้วย LibreLane  
3. Export Macro views (LEF, GDS, Liberty, SPEF)  
4. ประกอบ block ที่ Top-level พร้อม floorplan, PDN, routing  
5. ตรวจสอบ DRC/LVS/Timing ของ full system

### ขั้นตอนสำคัญ

1. ตรวจสอบ RTL ทั้งสองบล็อกด้วย Verilator  
2. Harden `counter_macro` ด้วย LibreLane (Classic flow)  
3. Harden `accumulator_macro` ด้วย LibreLane  
4. Export views จากทั้งสอง block  
5. สร้าง Top-level RTL ที่ instantiate ทั้งสอง Macro  
6. รัน LibreLane Top-level พร้อม MACROS section

### คำสั่งหลัก

\# Harden block แต่ละตัว

cd blocks/counter\_macro

librelane \--pdk ihp-sg13g2 config.yaml

cd blocks/accumulator\_macro

librelane \--pdk ihp-sg13g2 config.yaml

\# Copy views ไปยัง macros directory

cp runs/\<tag\>/final/gds/counter\_macro.gds ../../macros/counter\_macro/gds/

cp runs/\<tag\>/final/lef/counter\_macro.lef ../../macros/counter\_macro/lef/

\# รัน Top-level

cd top

librelane \--pdk ihp-sg13g2 config.yaml

### เกณฑ์ผ่าน

- [ ] Counter Macro: GDS, LEF, DRC clean, LVS clean  
- [ ] Accumulator Macro: GDS, LEF, DRC clean, LVS clean  
- [ ] Top-level: ทั้ง 2 Macro instantiated และวางถูกต้อง  
- [ ] Macro power/clock เชื่อมต่อ  
- [ ] Routing, DRC, LVS, Timing ผ่านที่ Top-level

---

## Lab 14: การควบคุม LibreLane ด้วย Python API

### วัตถุประสงค์

ใช้ LibreLane Python API เพื่อ automate, sweep, และสร้าง custom flow

ผู้เรียนจะสามารถ:

1. โหลด config.yaml และเรียก Classic Flow จาก Python script  
2. อ่าน Final State, Design Views และ metrics  
3. รัน partial flow ด้วย `frm` และ `to`  
4. ทำ parameter sweep อัตโนมัติ  
5. สร้าง Sequential Flow แบบกำหนดเอง

### ขั้นตอนสำคัญ

1. ตรวจสอบ `import librelane` สำเร็จ  
2. สร้าง script เรียก Classic Flow  
3. อ่าน final\_state และ metrics  
4. สร้าง sweep loop เปลี่ยน CLOCK\_PERIOD  
5. เปรียบเทียบผลจากหลาย runs

### คำสั่งหลัก

from librelane.flows import Flow, FlowError

\# เรียก Classic Flow

classic\_class \= Flow.factory.get("Classic")

flow \= classic\_class("config.yaml", pdk="sky130A")

final\_state \= flow.start(tag="lab14\_run", overwrite=True)

\# อ่านผล

print(flow.run\_dir)

print(flow.config\_resolved\_path)

print(final\_state.metrics)

\# Partial flow

final\_state \= flow.start(

    tag="synth\_only",

    frm="Yosys.Synthesis",

    to="OpenROAD.STAPrePNR",

    overwrite=True,

)

\# Parameter sweep

for period in \[10, 8, 6\]:

    flow \= classic\_class("config.yaml", pdk="sky130A",

                         config\_override={"CLOCK\_PERIOD": period})

    state \= flow.start(tag=f"period\_{period}", overwrite=True)

    print(period, state.metrics.get("design\_\_instance\_\_count"))

\# ตรวจสอบ API

make check    \# import librelane

make flows    \# list registered flows

make steps    \# list registered steps

make run      \# run Classic Flow

### เกณฑ์ผ่าน

- [ ] `import librelane` สำเร็จ  
- [ ] Classic Flow รันจาก Python script ได้  
- [ ] อ่าน metrics จาก Final State ได้  
- [ ] Parameter sweep ≥3 runs สำเร็จ  
- [ ] มี resolved config สำหรับ reproducibility

---

## Lab 15: Full-Chip Design with IO Pads

### วัตถุประสงค์

สร้าง Full-chip GDSII ที่มี I/O pad ring ด้วย LibreLane Chip Flow

ผู้เรียนจะสามารถ:

1. อธิบายความแตกต่างระหว่าง core-level และ chip-level design  
2. สร้าง RTL wrapper (`chip_top`) เชื่อม core กับ I/O pads  
3. กำหนด pad instances รอบ die ใน `padframe.cfg`  
4. รัน LibreLane Chip Flow  
5. ตรวจสอบ pad ring, PDN, routing, DRC, LVS ของ full chip

### ขั้นตอนสำคัญ

1. ตรวจสอบ I/O pad cells ที่มีใน PDK  
2. เขียน `chip_top.sv` wrapper ที่ instantiate core \+ pads  
3. สร้าง `padframe.cfg` กำหนด pad ทั้ง 4 ด้าน  
4. สร้าง `config.yaml` ระบุ `FLOW_CONFIG: Chip`  
5. รัน LibreLane Chip Flow  
6. ตรวจสอบ GDSII มี pad, core, filler, seal ring ครบ

### คำสั่งหลัก

\# ตรวจสอบ IO pad cells ใน PDK

grep \-R "^module .\*Pad\\|^module .\*PAD" $PDK\_ROOT/

\# รัน Chip Flow

librelane \--pdk ihp-sg13g2 \--flow Chip config.yaml

\# Validate configuration ก่อนรัน

librelane \--pdk ihp-sg13g2 \--flow Chip config.yaml \--validate-only

\# เปิด GDSII

klayout runs/\<tag\>/final/gds/chip\_top.gds

**ตัวอย่าง `config.yaml` สำหรับ Chip Flow:**

DESIGN\_NAME: chip\_top

VERILOG\_FILES:

  \- dir::src/counter.sv

  \- dir::src/chip\_top.sv

CLOCK\_PORT: clk\_PAD

CLOCK\_PERIOD: 10

PAD\_CFG: dir::pad/padframe.cfg

DIE\_AREA: \[0.0, 0.0, 1000.0, 1000.0\]

CORE\_AREA: \[200.0, 200.0, 800.0, 800.0\]

### เกณฑ์ผ่าน

| รายการ | เกณฑ์ |
| :---- | :---- |
| RTL lint | ไม่มี error |
| Synthesis | ไม่มี unmapped logic |
| Pad instances | อยู่ครบ, ไม่ overlap |
| Floorplan | Core และ pad ring ไม่ชนกัน |
| Routing DRC | 0 violation |
| Antenna | 0 unresolved violation |
| LVS | Circuits match |
| Magic/KLayout DRC | 0 violation |
| GDSII | มี pad, core, filler, seal ring ครบ |

---

## ภาคผนวก: ข้อมูลอ้างอิงด่วน

### โครงสร้าง config.yaml พื้นฐาน

\# Design identification

DESIGN\_NAME: counter

VERILOG\_FILES:

  \- dir::rtl/counter.sv

\# Clock

CLOCK\_PORT: clk\_i

CLOCK\_PERIOD: 10          \# ns

\# Floorplan

FP\_SIZING: absolute       \# หรือ relative

DIE\_AREA: \[0, 0, 300, 300\]

CORE\_AREA: \[20, 20, 280, 280\]

FP\_CORE\_UTIL: 40          \# % (ใช้เมื่อ FP\_SIZING: relative)

\# Placement

PL\_TARGET\_DENSITY\_PCT: 55

PL\_TIMING\_DRIVEN: true

\# SDC

PNR\_SDC\_FILE: dir::constraints/pnr.sdc

SIGNOFF\_SDC\_FILE: dir::constraints/signoff.sdc

\# IO

FP\_PIN\_ORDER\_CFG: dir::pins.cfg

### ลำดับขั้นตอน RTL-to-GDSII

SystemVerilog RTL

    ↓ Yosys (Lab 6\)

Gate-Level Netlist

    ↓ OpenROAD Floorplan (Lab 5\)

    ↓ OpenROAD Placement (Lab 7\)

    ↓ OpenROAD CTS (Lab 8\)

    ↓ OpenROAD Routing (Lab 9\)

Routed DEF \+ ODB

    ↓ Magic / KLayout DRC (Lab 10\)

    ↓ Netgen LVS (Lab 10\)

GDSII

### คำสั่ง LibreLane สำคัญ

librelane \--version                           \# ตรวจสอบ version

librelane \--smoke-test                        \# smoke test

librelane \--pdk ihp-sg13g2 config.yaml        \# รัน full flow

librelane \--pdk ihp-sg13g2 config.yaml \\

  \--to OpenROAD.Floorplan                     \# หยุดที่ step

librelane \--pdk ihp-sg13g2 config.yaml \\

  \--from OpenROAD.GlobalPlacement \\

  \--to OpenROAD.DetailedPlacement             \# รันช่วงที่ระบุ

librelane \--pdk ihp-sg13g2 config.yaml \\

  \--skip KLayout.DRC                          \# ข้าม step

librelane \--pdk ihp-sg13g2 \--flow Chip \\

  config.yaml                                 \# Chip flow

### Metrics สำคัญที่ต้องตรวจสอบ

| Metric | เกณฑ์ |
| :---- | :---- |
| Setup WNS | ≥ 0 ns |
| Hold WNS | ≥ 0 ns |
| Routing Overflow | \= 0 |
| Routing DRC | \= 0 |
| Magic DRC | \= 0 |
| KLayout DRC | \= 0 |
| LVS | Circuits match uniquely |
| Unrouted Nets | \= 0 |
| Clock Skew | \< 400 ps (Workshop guideline) |

---

*คู่มือฉบับย่อนี้ครอบคลุม Lab 1–15 ของ RTL-to-GDSII Workshop 2026*  
*สำหรับรายละเอียดเต็มให้ดูไฟล์ Lab ต้นฉบับ*  
