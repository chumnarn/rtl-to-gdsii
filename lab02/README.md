
# Lab 2  
# Counter RTL Simulation and Verification

## 2.1 วัตถุประสงค์ของบทปฏิบัติการ

บทปฏิบัติการนี้มีเป้าหมายให้ผู้เรียนสามารถตรวจสอบการทำงานของวงจรนับเลขดิจิทัลก่อนนำ RTL เข้าสู่กระบวนการสังเคราะห์และ RTL-to-GDSII โดยใช้ Verilator เป็นเครื่องมือจำลอง SystemVerilog และใช้ GTKWave สำหรับวิเคราะห์สัญญาณในรูปแบบ waveform

เมื่อจบบทปฏิบัติการ ผู้เรียนจะสามารถ:

1. อธิบายโครงสร้างของวงจรเคาน์เตอร์แบบ synchronous ได้
2. วิเคราะห์ความหมายของ active-low reset ได้
3. สร้าง clock และ reset stimulus ใน SystemVerilog testbench ได้
4. สร้าง self-checking testbench ที่ตรวจสอบผลโดยอัตโนมัติได้
5. คอมไพล์ SystemVerilog ด้วย Verilator ได้
6. สร้างไฟล์ waveform รูปแบบ FST ได้
7. เปิดและวิเคราะห์ waveform ด้วย GTKWave ได้
8. ตรวจสอบการนับ การ reset และการ overflow ของเคาน์เตอร์ได้
9. แยกความแตกต่างระหว่าง syntax error, lint warning และ functional error ได้
10. สร้าง Makefile เพื่อควบคุม simulation workflow ได้

---

## 2.2 ความสัมพันธ์กับกระบวนการ RTL-to-GDSII

ก่อนนำ RTL ไปสังเคราะห์ นักออกแบบต้องตรวจสอบก่อนว่า RTL มีพฤติกรรมตรงกับข้อกำหนดหรือไม่ ขั้นตอนนี้เรียกว่า **RTL Functional Verification**

ลำดับการทำงานพื้นฐานคือ

```text
Design Specification
        │
        ▼
SystemVerilog RTL
        │
        ▼
Lint and Compile
        │
        ▼
RTL Simulation
        │
        ▼
Waveform and Self-checking Verification
        │
        ▼
Logic Synthesis
        │
        ▼
Physical Design
```

การที่ RTL สามารถคอมไพล์ได้ไม่ได้หมายความว่าวงจรทำงานถูกต้องเสมอไป ตัวอย่างเช่น เคาน์เตอร์อาจนับผิดทิศทาง เริ่มต้นผิดค่า หรือ reset ผิดขอบสัญญาณ แม้ตัวโค้ดจะไม่มี syntax error ก็ตาม

ดังนั้น verification ใน Lab นี้จะตรวจสอบสามระดับ ได้แก่

```text
ระดับที่ 1  Syntax และ Lint
ระดับที่ 2  ตรวจสอบ waveform ด้วยสายตา
ระดับที่ 3  ตรวจสอบอัตโนมัติด้วย self-checking testbench
```

---

## 2.3 วงจรที่ใช้ในบทปฏิบัติการ

วงจรที่ใช้คือเคาน์เตอร์ไบนารีขนาด 8 บิต โดยมีอินเทอร์เฟซดังนี้

| Port | Direction | Width | Description |
|---|---:|---:|---|
| `clk_i` | Input | 1 บิต | สัญญาณนาฬิกา |
| `rst_ni` | Input | 1 บิต | Reset แบบ active-low |
| `count_o` | Output | 8 บิต | ค่าปัจจุบันของเคาน์เตอร์ |

พฤติกรรมที่ต้องการคือ:

1. เมื่อ `rst_ni = 0` และเกิดขอบขาขึ้นของ clock ค่า `count_o` ต้องเป็นศูนย์
2. เมื่อ `rst_ni = 1` ค่า `count_o` ต้องเพิ่มขึ้นหนึ่งทุกขอบขาขึ้นของ clock
3. เมื่อค่าถึง `8'hFF` รอบถัดไปต้องวนกลับเป็น `8'h00`
4. ค่าเอาต์พุตต้องเปลี่ยนเฉพาะที่ขอบขาขึ้นของ clock เท่านั้น

ข้อกำหนดจาก repository กำหนดให้ clock period เท่ากับ 10 ns หรือความถี่ 100 MHz สำหรับการนำวงจรไปใช้ใน LibreLane 

ความสัมพันธ์ระหว่างคาบและความถี่คือ

$$f = \frac{1}{T}$$

เมื่อ

$$
T = 10\ \text{ns}$$

จะได้

$$f = \frac{1}{10 \times 10^{-9}}  = 100 \times 10^6   = 100\ \text{MHz}$$

---

## 2.4 อุปกรณ์และซอฟต์แวร์ที่ใช้

บทปฏิบัติการนี้ใช้ซอฟต์แวร์ดังต่อไปนี้

- Git
- GNU Make
- Verilator
- GTKWave
- Text editor เช่น Visual Studio Code, Vim หรือ Nano
- Linux, Ubuntu, WSL2 หรือ Nix shell ของ workshop

ตรวจสอบเครื่องมือด้วยคำสั่ง

```bash
git --version
make --version
verilator --version
gtkwave --version
```

ตัวอย่างผลลัพธ์ที่คาดหวัง

```text
git version 2.x.x
GNU Make 4.x
Verilator 5.x
GTKWave Analyzer v3.x
```

หมายเลขเวอร์ชันจริงอาจแตกต่างกันได้ แต่คำสั่งทุกคำสั่งต้องทำงานโดยไม่แสดงข้อความ `command not found`

---

## 2.5 เตรียมสภาพแวดล้อม

### 2.5.1 เข้า Nix shell ของ workshop

เปิด Terminal และไปยัง root directory ของ repository

```bash
cd ~/heichips26-digital-workshop
```

เข้าสู่ environment ที่เตรียมเครื่องมือไว้

```bash
nix-shell
```

repository ของ workshop ระบุให้เรียก `nix-shell` ที่ root directory เพื่อเปิดใช้งานเครื่องมือที่จำเป็น และต้องทำใหม่เมื่อเปิด shell ใหม่  

ตรวจสอบตำแหน่งของโปรแกรม

```bash
which verilator
which make
which gtkwave
```

ผลลัพธ์ควรเป็น path ของ executable เช่น

```text
/nix/store/.../bin/verilator
/nix/store/.../bin/make
/nix/store/.../bin/gtkwave
```

---

### 2.5.2 ตรวจสอบ repository

ตรวจสอบตำแหน่งปัจจุบัน

```bash
pwd
```

แสดงรายการไฟล์

```bash
ls
```

ควรพบ directory อย่างน้อยดังนี้

```text
bonus
exercise_1
exercise_2
exercise_3
exercise_4
exercise_5
flake.nix
shell.nix
README.md
```

ตรวจสอบไฟล์ใน `exercise_1`

```bash
ls -la exercise_1
```

repository ต้นฉบับมีไฟล์หลัก ได้แก่

```text
README.md
config.yaml
counter.sv
img/
```

Lab นี้จะเพิ่ม testbench และ Makefile เพื่อใช้ตรวจสอบ RTL ก่อนเข้าสู่ LibreLane

---

## 2.6 สร้างพื้นที่ทำงานสำหรับ Lab 2

ไม่ควรแก้ไขไฟล์ต้นฉบับโดยตรงในระหว่างการทดลอง ให้สร้าง directory ใหม่เพื่อแยก simulation artifacts ออกจาก physical-design flow

จาก root directory ให้สร้างโครงสร้างต่อไปนี้

```bash
mkdir -p labs/lab02_counter_sim/{rtl,tb,sim,waves}
```

คัดลอก RTL จาก exercise เดิม

```bash
cp exercise_1/counter.sv labs/lab02_counter_sim/rtl/
```

เข้า directory ของ Lab

```bash
cd labs/lab02_counter_sim
```

ตรวจสอบโครงสร้าง

```bash
find . -maxdepth 2 -type d | sort
```

ผลลัพธ์ที่คาดหวัง

```text
.
./rtl
./sim
./tb
./waves
```

โครงสร้างสุดท้ายของ Lab จะเป็นดังนี้

```text
lab02_counter_sim/
├── Makefile
├── rtl/
│   └── counter.sv
├── tb/
│   └── counter_tb.sv
├── sim/
└── waves/
```

ความหมายของแต่ละ directory:

| Directory | หน้าที่ |
|---|---|
| `rtl/` | เก็บ synthesizable RTL |
| `tb/` | เก็บ testbench และ verification code |
| `sim/` | เก็บไฟล์ที่ Verilator สร้างขึ้น |
| `waves/` | เก็บ waveform เช่น `.fst` หรือ `.vcd` |

---

## 2.7 ศึกษา RTL ของวงจร Counter

เปิดไฟล์

```bash
nano rtl/counter.sv
```

หรือ

```bash
code rtl/counter.sv
```

โค้ด RTL มีโครงสร้างดังนี้

```systemverilog
// A simple 8-bit counter
module counter (
    input  logic       clk_i,
    input  logic       rst_ni,
    output logic [7:0] count_o
);

    always_ff @(posedge clk_i) begin
        if (!rst_ni) begin
            count_o <= '0;
        end else begin
            count_o <= count_o + 1;
        end
    end

endmodule
```

---

## 2.8 วิเคราะห์ RTL ทีละส่วน

### 2.8.1 การประกาศโมดูล

```systemverilog
module counter (
```

คำสั่งนี้เริ่มต้นการประกาศโมดูลชื่อ `counter`

ชื่อโมดูลต้องตรงกับ top-level design name ที่จะใช้ใน simulation และ synthesis

---

### 2.8.2 สัญญาณ Clock

```systemverilog
input logic clk_i,
```

`clk_i` เป็นสัญญาณ clock ขาเข้า

รูปแบบการตั้งชื่อใช้ suffix `_i` เพื่อสื่อว่าเป็น input signal

ในวงจรนี้ state จะเปลี่ยนเมื่อเกิด

```text
0 → 1
```

หรือขอบขาขึ้นของ clock ซึ่งเรียกว่า **positive edge** หรือ **rising edge**

---

### 2.8.3 สัญญาณ Reset

```systemverilog
input logic rst_ni,
```

ชื่อ `rst_ni` สื่อความหมายว่า

```text
rst  = reset
n    = active-low หรือถูก assert เมื่อค่าเป็น 0
i    = input
```

ดังนั้น

```text
rst_ni = 0  หมายถึง reset ทำงาน
rst_ni = 1  หมายถึงวงจรทำงานตามปกติ
```

---

### 2.8.4 เอาต์พุตของเคาน์เตอร์

```systemverilog
output logic [7:0] count_o
```

`count_o` มีขนาด 8 บิต

ช่วงค่าที่สามารถแทนได้คือ

$$0 \text{ ถึง } 2^8 - 1$$

หรือ

$$0 \text{ ถึง } 255$$

ในเลขฐานสิบหกคือ

```text
8'h00 ถึง 8'hFF
```

---

### 2.8.5 Sequential Process

```systemverilog
always_ff @(posedge clk_i) begin
```

`always_ff` ใช้สำหรับอธิบายพฤติกรรมของวงจร sequential เช่น register และ flip-flop

process นี้ทำงานเมื่อเกิดขอบขาขึ้นของ `clk_i`

เนื่องจาก reset ไม่ได้อยู่ใน sensitivity expression จึงสรุปได้ว่า reset นี้เป็น **synchronous reset**

กล่าวคือ การเปลี่ยน `rst_ni` จาก 1 เป็น 0 จะยังไม่ทำให้ `count_o` เปลี่ยนทันที แต่ต้องรอขอบขาขึ้นของ clock ก่อน

---

### 2.8.6 เงื่อนไข Reset

```systemverilog
if (!rst_ni) begin
    count_o <= '0;
end
```

เครื่องหมาย `!` คือ logical NOT

เมื่อ

```text
rst_ni = 0
```

จะได้

```text
!rst_ni = 1
```

จึงเข้าสู่ reset branch และกำหนด

```systemverilog
count_o <= '0;
```

`'0` หมายถึงกำหนดทุกบิตของสัญญาณเป้าหมายเป็นศูนย์ โดย compiler จะปรับขนาดให้ตรงกับ `count_o` อัตโนมัติ

ในกรณีนี้มีค่าเท่ากับ

```systemverilog
count_o <= 8'b0000_0000;
```

หรือ

```systemverilog
count_o <= 8'h00;
```

---

### 2.8.7 การนับ

```systemverilog
count_o <= count_o + 1;
```

เมื่อ reset ไม่ทำงาน ค่า register จะเพิ่มขึ้นหนึ่งในทุกขอบขาขึ้นของ clock

ตัวดำเนินการ `<=` คือ nonblocking assignment ซึ่งเป็นรูปแบบที่ควรใช้ภายใน sequential logic

พฤติกรรมของเคาน์เตอร์เป็นดังนี้

```text
00 → 01 → 02 → 03 → ... → FE → FF → 00
```

เมื่อค่า `8'hFF` บวกหนึ่ง ผลลัพธ์ทางคณิตศาสตร์คือ `9'h100` แต่เนื่องจาก `count_o` มีขนาดเพียง 8 บิต บิตที่เกินออกมาจะถูกตัดทิ้ง จึงได้ `8'h00`

---

## 2.9 ความแตกต่างระหว่าง Synchronous และ Asynchronous Reset

วงจรใน Lab นี้ใช้ synchronous reset

```systemverilog
always_ff @(posedge clk_i)
```

หากเป็น asynchronous reset มักเขียนเป็น

```systemverilog
always_ff @(posedge clk_i or negedge rst_ni)
```

ความแตกต่างคือ

| คุณสมบัติ | Synchronous reset | Asynchronous reset |
|---|---|---|
| ตอบสนองต่อ reset | ที่ขอบ clock | ทันทีเมื่อ reset เปลี่ยน |
| Reset อยู่ใน sensitivity list | ไม่อยู่ | อยู่ |
| การควบคุม timing | ง่ายกว่าในบาง flow | ต้องตรวจ recovery/removal |
| RTL ของ Lab นี้ | ใช่ | ไม่ใช่ |

ประเด็นสำคัญในการสร้าง testbench คือ ต้องตรวจสอบค่า `count_o` หลังขอบขาขึ้นของ clock ไม่ใช่ทันทีหลังเปลี่ยน `rst_ni`

---

## 2.10 ตรวจสอบ RTL ด้วย Verilator Lint

ก่อนสร้าง testbench ให้ตรวจสอบ syntax และ lint warning ของ RTL

รันคำสั่ง

```bash
verilator \
  --lint-only \
  --Wall \
  --Wno-fatal \
  --top-module counter \
  rtl/counter.sv
```

ความหมายของ option:

| Option | ความหมาย |
|---|---|
| `--lint-only` | ตรวจสอบโค้ดโดยไม่สร้าง simulator |
| `--Wall` | เปิด warning ที่สำคัญ |
| `--Wno-fatal` | ไม่ให้ warning ทั่วไปหยุดการทำงาน |
| `--top-module counter` | ระบุ top-level module |
| `rtl/counter.sv` | RTL source file |

หาก RTL ถูกต้อง คำสั่งควรจบโดยไม่มี error

ตรวจสอบ exit status ด้วย

```bash
echo $?
```

หากสำเร็จควรได้

```text
0
```

---

## 2.11 สร้าง Testbench

สร้างไฟล์

```bash
nano tb/counter_tb.sv
```

ใส่โค้ดต่อไปนี้

```systemverilog
`timescale 1ns/1ps

module counter_tb;

    localparam time CLK_PERIOD = 10ns;

    logic       clk_i;
    logic       rst_ni;
    logic [7:0] count_o;

    logic [7:0] expected_count;
    int unsigned error_count;

    counter dut (
        .clk_i   (clk_i),
        .rst_ni  (rst_ni),
        .count_o (count_o)
    );

    initial begin
        clk_i = 1'b0;
        forever #(CLK_PERIOD / 2) clk_i = ~clk_i;
    end

    task automatic check_count(
        input logic [7:0] expected,
        input string      test_name
    );
        if (count_o !== expected) begin
            $error(
                "[FAIL] %s: expected count_o=0x%02h, actual count_o=0x%02h",
                test_name,
                expected,
                count_o
            );
            error_count++;
        end else begin
            $display(
                "[PASS] %s: count_o=0x%02h",
                test_name,
                count_o
            );
        end
    endtask

    initial begin
        $dumpfile("waves/counter.fst");
        $dumpvars(0, counter_tb);

        rst_ni         = 1'b0;
        expected_count = 8'h00;
        error_count    = 0;

        $display("==========================================");
        $display(" Counter RTL Simulation and Verification");
        $display("==========================================");

        repeat (2) begin
            @(posedge clk_i);
            #1;
            check_count(8'h00, "Reset assertion");
        end

        @(negedge clk_i);
        rst_ni = 1'b1;

        repeat (10) begin
            @(posedge clk_i);
            expected_count++;
            #1;
            check_count(expected_count, "Normal counting");
        end

        @(negedge clk_i);
        rst_ni = 1'b0;

        @(posedge clk_i);
        #1;
        expected_count = 8'h00;
        check_count(expected_count, "Reset during operation");

        @(negedge clk_i);
        rst_ni = 1'b1;

        repeat (256) begin
            @(posedge clk_i);
            expected_count++;
            #1;
            check_count(expected_count, "Overflow test");
        end

        $display("------------------------------------------");

        if (error_count == 0) begin
            $display("LAB RESULT: PASS");
            $display("All counter tests completed successfully.");
        end else begin
            $display("LAB RESULT: FAIL");
            $display("Number of errors: %0d", error_count);
            $fatal(1, "Counter verification failed.");
        end

        $display("------------------------------------------");

        $finish;
    end

endmodule
```

---

## 2.12 วิเคราะห์โครงสร้าง Testbench

### 2.12.1 Time Unit และ Time Precision

```systemverilog
`timescale 1ns/1ps
```

กำหนดให้

```text
Time unit      = 1 ns
Time precision = 1 ps
```

ดังนั้น delay

```systemverilog
#5;
```

หมายถึง 5 ns

---

### 2.12.2 การประกาศ Clock Period

```systemverilog
localparam time CLK_PERIOD = 10ns;
```

ใช้ parameter เพื่อหลีกเลี่ยงการเขียนค่าคาบ clock ซ้ำหลายตำแหน่ง

หากต้องการเปลี่ยนความถี่ในภายหลัง สามารถแก้เพียงบรรทัดเดียว

สำหรับ clock 100 MHz:

```text
CLK_PERIOD = 10 ns
Half period = 5 ns
```

---

### 2.12.3 สัญญาณที่เชื่อมต่อกับ DUT

```systemverilog
logic       clk_i;
logic       rst_ni;
logic [7:0] count_o;
```

testbench ทำหน้าที่ขับค่าให้ input ของ DUT ได้แก่

```text
clk_i
rst_ni
```

และอ่านค่า output ได้แก่

```text
count_o
```

---

### 2.12.4 Reference Model

```systemverilog
logic [7:0] expected_count;
```

`expected_count` ทำหน้าที่เป็นแบบจำลองอ้างอิงอย่างง่าย

ทุกครั้งที่ DUT ควรนับ ค่า reference model จะเพิ่มขึ้นหนึ่งเช่นกัน จากนั้น testbench จะเปรียบเทียบ

```text
count_o เทียบกับ expected_count
```

แนวทางนี้เรียกว่า **scoreboard-based checking** ในรูปแบบพื้นฐาน

---

### 2.12.5 การสร้าง DUT Instance

```systemverilog
counter dut (
    .clk_i   (clk_i),
    .rst_ni  (rst_ni),
    .count_o (count_o)
);
```

`counter` คือชื่อโมดูล

`dut` คือชื่อ instance

DUT ย่อมาจาก

```text
Design Under Test
```

การใช้ named port connection ช่วยลดความผิดพลาดจากลำดับ port

---

### 2.12.6 Clock Generator

```systemverilog
initial begin
    clk_i = 1'b0;
    forever #(CLK_PERIOD / 2) clk_i = ~clk_i;
end
```

เริ่มต้น clock ที่ศูนย์ และกลับค่าทุกครึ่งคาบ

ลำดับค่าจะเป็น

```text
เวลา 0 ns   clk_i = 0
เวลา 5 ns   clk_i = 1
เวลา 10 ns  clk_i = 0
เวลา 15 ns  clk_i = 1
```

ดังนั้น positive edge เกิดที่

```text
5 ns, 15 ns, 25 ns, 35 ns, ...
```

---

### 2.12.7 Task สำหรับตรวจสอบผล

```systemverilog
task automatic check_count(
    input logic [7:0] expected,
    input string      test_name
);
```

task นี้รับค่าที่คาดหวังและชื่อการทดสอบ

เงื่อนไขตรวจสอบคือ

```systemverilog
if (count_o !== expected)
```

ใช้ case inequality operator `!==` แทน `!=` เพื่อให้ตรวจจับค่า `X` และ `Z` ได้ด้วย

ตัวอย่าง:

```text
count_o = 8'h03, expected = 8'h03 → PASS
count_o = 8'h04, expected = 8'h03 → FAIL
count_o = 8'hxx, expected = 8'h03 → FAIL
```

---

### 2.12.8 การสร้าง Waveform

```systemverilog
$dumpfile("waves/counter.fst");
$dumpvars(0, counter_tb);
```

`$dumpfile` ระบุชื่อไฟล์ waveform

`$dumpvars` ระบุ scope ที่ต้องบันทึก

เลข `0` หมายถึงบันทึก hierarchy ทุกระดับภายใต้ `counter_tb`

---

### 2.12.9 การ Assert Reset

```systemverilog
rst_ni = 1'b0;
```

เนื่องจาก reset เป็น active-low การกำหนดค่าเป็นศูนย์คือการสั่ง reset

testbench รอ positive edge สองครั้ง

```systemverilog
repeat (2) begin
    @(posedge clk_i);
    #1;
    check_count(8'h00, "Reset assertion");
end
```

delay `#1` หลัง positive edge มีไว้ให้ nonblocking assignment ใน DUT ถูกประมวลผลเสร็จก่อนอ่านค่า

---

### 2.12.10 การปล่อย Reset

```systemverilog
@(negedge clk_i);
rst_ni = 1'b1;
```

testbench ปล่อย reset ที่ negative edge เพื่อให้สัญญาณ `rst_ni` มีเวลาคงที่ก่อนถึง positive edge ถัดไป

การเปลี่ยน control signal ที่ negative edge ช่วยหลีกเลี่ยง race condition ระหว่าง testbench กับ DUT

---

### 2.12.11 การตรวจสอบการนับ

```systemverilog
repeat (10) begin
    @(posedge clk_i);
    expected_count++;
    #1;
    check_count(expected_count, "Normal counting");
end
```

ทดสอบการนับจำนวน 10 clock cycles

ผลที่คาดหวังคือ

```text
01, 02, 03, 04, 05, 06, 07, 08, 09, 0A
```

---

### 2.12.12 การ Reset ระหว่างทำงาน

หลังเคาน์เตอร์นับไปแล้ว testbench assert reset อีกครั้ง

```systemverilog
@(negedge clk_i);
rst_ni = 1'b0;

@(posedge clk_i);
#1;
expected_count = 8'h00;
check_count(expected_count, "Reset during operation");
```

การทดสอบนี้ยืนยันว่า reset สามารถล้าง state ของวงจรกลับเป็นศูนย์ได้

---

### 2.12.13 การตรวจสอบ Overflow

```systemverilog
repeat (256) begin
    @(posedge clk_i);
    expected_count++;
    #1;
    check_count(expected_count, "Overflow test");
end
```

การนับ 256 รอบจะตรวจสอบค่าทั้งหมดของเคาน์เตอร์ 8 บิต

```text
00 → 01 → ... → FE → FF → 00
```

เนื่องจาก `expected_count` เป็น 8 บิต จึง overflow ด้วยกฎเดียวกับ DUT

---

## 2.13 ตรวจสอบทั้ง RTL และ Testbench ด้วย Lint

รันคำสั่ง

```bash
verilator \
  --lint-only \
  --Wall \
  --Wno-fatal \
  --timing \
  --top-module counter_tb \
  rtl/counter.sv \
  tb/counter_tb.sv
```

จำเป็นต้องใช้ `--timing` เนื่องจาก testbench มี delay และ event control เช่น

```systemverilog
#1
@(posedge clk_i)
@(negedge clk_i)
```

หากลืม `--timing` Verilator อาจรายงานว่า simulation ต้องเลือกระหว่าง `--timing` และ `--no-timing`


หาก รัน verilator แล้วมีรานงานข้อผิดพลาด ให้ทำการแก้ไขไฟล์ที่เกี่ยวข้อง ให้ถูกต้อง เช่นไฟล์ counter.sv

```systemverilog
%Warning-TIMESCALEMOD: rtl/counter.sv:3:8: Timescale missing on this module as other modules have it (IEEE 1800-2023 3.14.2.3)
    3 | module counter (
      |        ^~~~~~~
                       tb/counter_tb.sv:3:8: ... Location of module with timescale
    3 | module counter_tb;
      |        ^~~~~~~~~~
                       ... For warning description see https://verilator.org/warn/TIMESCALEMOD?v=5.044
                       ... Use "/* verilator lint_off TIMESCALEMOD */" and lint_on around source to disable this message
```


---

## 2.14 คอมไพล์ Simulation ด้วย Verilator

สร้าง simulator ด้วยคำสั่ง

```bash
verilator \
  --binary \
  --timing \
  --trace-fst \
  --Wall \
  --Wno-fatal \
  --top-module counter_tb \
  --Mdir sim/obj_dir \
  -o counter_sim \
  rtl/counter.sv \
  tb/counter_tb.sv
```

ความหมายของ option:

| Option | ความหมาย |
|---|---|
| `--binary` | สร้าง executable simulation โดยอัตโนมัติ |
| `--timing` | รองรับ delay และ event timing |
| `--trace-fst` | เปิดการสร้าง waveform แบบ FST |
| `--Wall` | เปิด warning |
| `--Wno-fatal` | ไม่หยุดเพราะ warning ทั่วไป |
| `--top-module counter_tb` | กำหนด testbench เป็น top module |
| `--Mdir sim/obj_dir` | กำหนด directory สำหรับ generated files |
| `-o counter_sim` | กำหนดชื่อ executable |

หลังคอมไพล์เสร็จ ตรวจสอบไฟล์

```bash
find sim -maxdepth 3 -type f | head
```

ตรวจสอบ executable

```bash
ls -l sim/obj_dir/counter_sim
```

---

## 2.15 รัน Simulation

สร้าง directory สำหรับ waveform หากยังไม่มี

```bash
mkdir -p waves
```

รัน simulator

```bash
./sim/obj_dir/counter_sim
```

ตัวอย่างผลลัพธ์ส่วนต้น

```text
==========================================
 Counter RTL Simulation and Verification
==========================================
[PASS] Reset assertion: count_o=0x00
[PASS] Reset assertion: count_o=0x00
[PASS] Normal counting: count_o=0x01
[PASS] Normal counting: count_o=0x02
[PASS] Normal counting: count_o=0x03
...
```

ตัวอย่างผลลัพธ์ส่วนท้าย

```text
[PASS] Overflow test: count_o=0xfe
[PASS] Overflow test: count_o=0xff
[PASS] Overflow test: count_o=0x00
------------------------------------------
LAB RESULT: PASS
All counter tests completed successfully.
------------------------------------------
```

ตรวจสอบ exit code

```bash
echo $?
```

ผลที่คาดหวัง

```text
0
```

ตรวจสอบ waveform

```bash
ls -lh waves/counter.fst
```

ควรพบไฟล์ที่มีขนาดมากกว่าศูนย์

---

## 2.16 เปิด Waveform ด้วย GTKWave

รันคำสั่ง

```bash
gtkwave waves/counter.fst
```

ภายใน GTKWave ให้เพิ่มสัญญาณต่อไปนี้

```text
counter_tb.clk_i
counter_tb.rst_ni
counter_tb.count_o
counter_tb.expected_count
counter_tb.error_count
```

ขั้นตอนทั่วไป:

1. เลือก module `counter_tb` จาก SST hierarchy
2. เลือกชื่อสัญญาณ
3. กด Insert หรือดับเบิลคลิกเพื่อเพิ่มสัญญาณ
4. เลือก `count_o`
5. คลิกขวา
6. เลือก `Data Format`
7. เลือก `Hex`
8. ทำเช่นเดียวกันกับ `expected_count`
9. กด Zoom Fit เพื่อแสดง waveform ทั้งหมด

---

## 2.17 สิ่งที่ต้องสังเกตจาก Waveform

### ช่วงที่ 1: เริ่มต้น Simulation

ช่วงเริ่มต้นควรเห็น

```text
rst_ni = 0
count_o = 00
```

แม้ clock จะทำงาน แต่ `count_o` ต้องคงค่าเป็นศูนย์ทุก positive edge ขณะที่ reset ยังถูก assert

---

### ช่วงที่ 2: ปล่อย Reset

เมื่อ `rst_ni` เปลี่ยนจาก 0 เป็น 1 ที่ negative edge ค่า `count_o` ยังไม่เปลี่ยนทันที

เมื่อถึง positive edge ถัดไปจึงเปลี่ยนจาก

```text
00 → 01
```

แสดงว่า reset เป็น synchronous reset

---

### ช่วงที่ 3: การนับปกติ

ตรวจสอบว่า `count_o` เปลี่ยนเฉพาะ positive edge

ตัวอย่าง

```text
positive edge 1 → 01
positive edge 2 → 02
positive edge 3 → 03
positive edge 4 → 04
```

ค่าต้องไม่เปลี่ยนที่ negative edge

---

### ช่วงที่ 4: Reset ระหว่างการทำงาน

สมมติค่าปัจจุบันเป็น

```text
count_o = 0A
```

เมื่อ `rst_ni` ถูกกำหนดเป็นศูนย์ ค่า `count_o` ต้องยังคงเป็น `0A` จนกว่าจะถึง positive edge

หลัง positive edge จึงเปลี่ยนเป็น

```text
count_o = 00
```

---

### ช่วงที่ 5: Overflow

ซูม waveform บริเวณท้ายการนับและตรวจสอบลำดับ

```text
FC → FD → FE → FF → 00 → 01
```

ลำดับดังกล่าวยืนยันพฤติกรรม modulo-256 ของวงจร

---

## 2.18 สร้าง Makefile

เพื่อไม่ต้องพิมพ์คำสั่งยาวซ้ำ ให้สร้างไฟล์

```bash
nano Makefile
```

ใส่เนื้อหาต่อไปนี้

```makefile
TOP       := counter_tb
RTL       := rtl/counter.sv
TB        := tb/counter_tb.sv

SIM_DIR   := sim
OBJ_DIR   := $(SIM_DIR)/obj_dir
SIM_BIN   := $(OBJ_DIR)/counter_sim

WAVE_DIR  := waves
WAVE_FILE := $(WAVE_DIR)/counter.fst

VERILATOR := verilator
GTKWAVE   := gtkwave

VERILATOR_FLAGS := \
	--timing \
	--trace-fst \
	--Wall \
	--Wno-fatal \
	--top-module $(TOP)

.PHONY: all help lint build run wave clean distclean

all: run

help:
	@echo "Available targets:"
	@echo "  make lint      - Run Verilator lint"
	@echo "  make build     - Build the simulation executable"
	@echo "  make run       - Build and run the testbench"
	@echo "  make wave      - Open waveform in GTKWave"
	@echo "  make clean     - Remove generated simulation files"
	@echo "  make distclean - Remove all generated files"

lint:
	$(VERILATOR) \
		--lint-only \
		$(VERILATOR_FLAGS) \
		$(RTL) \
		$(TB)

build: $(SIM_BIN)

$(SIM_BIN): $(RTL) $(TB)
	@mkdir -p $(SIM_DIR)
	@mkdir -p $(WAVE_DIR)
	$(VERILATOR) \
		--binary \
		$(VERILATOR_FLAGS) \
		--Mdir $(OBJ_DIR) \
		-o counter_sim \
		$(RTL) \
		$(TB)

run: build
	@mkdir -p $(WAVE_DIR)
	./$(SIM_BIN)

wave: $(WAVE_FILE)
	$(GTKWAVE) $(WAVE_FILE)

$(WAVE_FILE): run
	@test -f $(WAVE_FILE)

clean:
	rm -rf $(OBJ_DIR)
	rm -f $(WAVE_FILE)

distclean:
	rm -rf $(SIM_DIR)
	rm -rf $(WAVE_DIR)
```

ข้อควรระวัง: บรรทัดคำสั่งภายใต้ target ของ Makefile ต้องขึ้นต้นด้วยอักขระ Tab ไม่ใช่ Space

---

## 2.19 ใช้งาน Makefile

แสดงคำสั่งที่รองรับ

```bash
make help
```

ตรวจสอบ lint

```bash
make lint
```

สร้าง simulator

```bash
make build
```

รัน simulation

```bash
make run
```

เปิด waveform

```bash
make wave
```

ล้าง generated files

```bash
make clean
```

ล้าง directory ที่สร้างจาก simulation ทั้งหมด

```bash
make distclean
```

รัน workflow ใหม่ตั้งแต่ต้น

```bash
make distclean
make lint
make run
make wave
```

---

## 2.20 ลำดับการทำงานของ Simulation

เมื่อเรียก

```bash
make run
```

ระบบจะทำงานตามลำดับดังนี้

```text
counter.sv + counter_tb.sv
            │
            ▼
      Verilator Front-end
            │
            ├── Parse SystemVerilog
            ├── Elaborate hierarchy
            ├── Perform lint checks
            └── Translate design to C++
            │
            ▼
        C++ Compilation
            │
            ▼
      counter_sim Executable
            │
            ▼
      Execute Testbench
            │
            ├── Generate clock
            ├── Apply reset
            ├── Apply test sequences
            ├── Compare actual/expected
            └── Generate FST waveform
            │
            ▼
        PASS or FAIL
```

---

## 2.21 การตรวจสอบ Race Condition

Testbench เปลี่ยน reset ที่ negative edge

```systemverilog
@(negedge clk_i);
rst_ni = 1'b1;
```

และตรวจ output หลัง positive edge พร้อม delay เล็กน้อย

```systemverilog
@(posedge clk_i);
#1;
check_count(...);
```

แนวทางนี้ช่วยลด race condition เพราะ DUT ทำงานที่ positive edge ส่วน testbench เปลี่ยน stimulus ที่ negative edge

รูปแบบที่ควรหลีกเลี่ยงคือ

```systemverilog
@(posedge clk_i);
rst_ni = 1'b1;
```

เพราะ DUT และ testbench อาจอ่านหรือแก้สัญญาณใน simulation time slot เดียวกัน ทำให้พฤติกรรมขึ้นอยู่กับ scheduling order

---

## 2.22 Event Scheduling และ Nonblocking Assignment

เมื่อเกิด positive edge Verilog simulator จะประมวลผลโดยสรุปดังนี้

```text
1. ตรวจพบ posedge clk_i
2. เรียก always_ff ของ DUT
3. ประเมินค่าด้านขวาของ nonblocking assignment
4. กำหนดการอัปเดต count_o ใน NBA region
5. อัปเดต count_o
6. Testbench อ่านค่าหลัง #1
```

ดังนั้นถ้าตรวจค่าทันทีใน event เดียวกันโดยไม่จัดลำดับให้ดี testbench อาจอ่านค่าเก่าได้

การใช้

```systemverilog
#1;
```

ใน Lab นี้เป็นวิธีง่ายสำหรับผู้เริ่มต้น อย่างไรก็ตาม ใน verification environment ขนาดใหญ่ควรใช้ clocking block, assertion หรือ structured sampling scheme

---

## 2.23 เพิ่ม SystemVerilog Assertions

สามารถเพิ่ม assertion เพื่อยืนยันว่า reset ทำงานถูกต้องได้

เพิ่มโค้ดต่อไปนี้ใน `counter_tb.sv` หลัง DUT instance

```systemverilog
property p_reset_clears_counter;
    @(posedge clk_i)
    !rst_ni |=> count_o == 8'h00;
endproperty

assert property (p_reset_clears_counter)
else $error("Reset did not clear count_o");
```

และ assertion สำหรับการนับ

```systemverilog
property p_counter_increments;
    @(posedge clk_i)
    disable iff (!rst_ni)
    count_o == $past(count_o) + 8'h01;
endproperty

assert property (p_counter_increments)
else $error("Counter did not increment correctly");
```

หมายเหตุ: การรองรับ assertion บางรูปแบบอาจขึ้นกับเวอร์ชันและ option ของ simulator หากเกิด compatibility issue ให้ใช้ self-checking task เป็นกลไกหลักของ Lab

---

## 2.24 การทดสอบ Negative Test

Negative test คือการจงใจใส่ข้อผิดพลาดใน RTL เพื่อยืนยันว่า testbench สามารถตรวจพบได้

### 2.24.1 สำรอง RTL

```bash
cp rtl/counter.sv rtl/counter.sv.good
```

### 2.24.2 สร้างข้อผิดพลาด

แก้บรรทัด

```systemverilog
count_o <= count_o + 1;
```

เป็น

```systemverilog
count_o <= count_o + 2;
```

รัน

```bash
make clean
make run
```

ผลที่คาดหวัง

```text
[FAIL] Normal counting: expected count_o=0x01, actual count_o=0x02
```

และตอนท้ายควรได้

```text
LAB RESULT: FAIL
```

รวมถึง non-zero exit status

```bash
echo $?
```

ค่าต้องไม่เป็นศูนย์

### 2.24.3 คืนค่า RTL

```bash
mv rtl/counter.sv.good rtl/counter.sv
```

รันอีกครั้ง

```bash
make clean
make run
```

ผลต้องกลับมาเป็น

```text
LAB RESULT: PASS
```

ขั้นตอนนี้สำคัญ เพราะ testbench ที่แสดง PASS ตลอดเวลา แม้ RTL ผิด ไม่ใช่ testbench ที่มีประสิทธิภาพ

---

## 2.25 การทดลอง: เปลี่ยนความกว้างของ Counter

RTL ต้นฉบับกำหนดความกว้างคงที่ 8 บิต สามารถปรับให้เป็น parameterized counter ได้ดังนี้

```systemverilog
module counter #(
    parameter int unsigned WIDTH = 8
) (
    input  logic             clk_i,
    input  logic             rst_ni,
    output logic [WIDTH-1:0] count_o
);

    always_ff @(posedge clk_i) begin
        if (!rst_ni) begin
            count_o <= '0;
        end else begin
            count_o <= count_o + 1'b1;
        end
    end

endmodule
```

แก้ testbench instance เป็น

```systemverilog
localparam int WIDTH = 8;

logic [WIDTH-1:0] count_o;

counter #(
    .WIDTH(WIDTH)
) dut (
    .clk_i   (clk_i),
    .rst_ni  (rst_ni),
    .count_o (count_o)
);
```

ทดลองเปลี่ยน

```systemverilog
localparam int WIDTH = 4;
```

เคาน์เตอร์ 4 บิตต้องวนรอบทุก 16 clock cycles

```text
0 → 1 → ... → E → F → 0
```

---

## 2.26 การทดลอง: เพิ่ม Enable

แก้ interface ให้มีสัญญาณ enable

```systemverilog
input logic en_i,
```

แก้ sequential logic เป็น

```systemverilog
always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
        count_o <= '0;
    end else if (en_i) begin
        count_o <= count_o + 1'b1;
    end
end
```

ข้อกำหนดเพิ่มเติม:

```text
en_i = 1 → counter เพิ่มขึ้น
en_i = 0 → counter คงค่าเดิม
```

เพิ่ม test case ใน testbench:

1. ปล่อย reset
2. กำหนด `en_i = 1`
3. ตรวจสอบว่าค่าเพิ่ม
4. กำหนด `en_i = 0`
5. รออย่างน้อย 5 clock cycles
6. ตรวจสอบว่าค่าคงเดิม
7. กำหนด `en_i = 1`
8. ตรวจสอบว่าเริ่มนับต่อจากค่าเดิม

---

## 2.27 ปัญหาที่พบบ่อยและแนวทางแก้ไข

### ปัญหา 1: `verilator: command not found`

สาเหตุ:

- ยังไม่ได้เข้า Nix shell
- Verilator ไม่ได้ติดตั้ง
- PATH ไม่ถูกต้อง

ตรวจสอบด้วย

```bash
which verilator
```

หากใช้ workshop repository ให้กลับไป root directory และรัน

```bash
nix-shell
```

---

### ปัญหา 2: `Unsupported: timing control`

สาเหตุ:

testbench ใช้ `#delay` หรือ `@event` แต่ไม่ได้เปิด timing support

แก้โดยเพิ่ม

```bash
--timing
```

---

### ปัญหา 3: หา top module ไม่พบ

ตัวอย่างข้อความ

```text
Can't find definition of variable/module: counter_tb
```

ตรวจสอบว่า

```text
ชื่อ module ในไฟล์ = counter_tb
--top-module       = counter_tb
```

และระบุไฟล์ testbench ในคำสั่งแล้ว

---

### ปัญหา 4: หาโมดูล `counter` ไม่พบ

ตรวจสอบว่าคำสั่งมี RTL source

```bash
rtl/counter.sv
```

ตัวอย่างที่ถูกต้อง

```bash
verilator --binary ... rtl/counter.sv tb/counter_tb.sv
```

---

### ปัญหา 5: Waveform ไม่ถูกสร้าง

ตรวจสอบว่าใช้

```bash
--trace-fst
```

และ testbench มี

```systemverilog
$dumpfile("waves/counter.fst");
$dumpvars(0, counter_tb);
```

ตรวจสอบ directory

```bash
mkdir -p waves
```

---

### ปัญหา 6: GTKWave เปิดไฟล์ไม่ได้

ตรวจสอบว่าไฟล์มีอยู่จริง

```bash
ls -lh waves/counter.fst
```

ตรวจชนิดไฟล์

```bash
file waves/counter.fst
```

ลองสร้างใหม่

```bash
make clean
make run
```

---

### ปัญหา 7: `count_o` เป็นค่า X

สาเหตุที่เป็นไปได้:

- ไม่มีการ assert reset ตอนเริ่ม simulation
- ตรวจค่าก่อน positive edge แรก
- RTL ไม่ได้กำหนดค่า register ครบทุกกรณี
- เชื่อม port ผิด

ตรวจสอบว่า testbench มี

```systemverilog
rst_ni = 1'b0;
```

ก่อน clock edge แรก

---

### ปัญหา 8: ค่า expected ช้าหรือเร็วกว่า DUT หนึ่ง clock

สาเหตุ:

- อัปเดต reference model ผิดลำดับ
- อ่านค่า DUT ก่อน NBA update
- ปล่อย reset ที่ positive edge

แนวทางแก้:

```systemverilog
@(posedge clk_i);
expected_count++;
#1;
check_count(expected_count, "Normal counting");
```

และเปลี่ยน stimulus ที่ negative edge

---

### ปัญหา 9: Makefile แสดง `missing separator`

สาเหตุ:

บรรทัดคำสั่งใน Makefile ขึ้นต้นด้วย Space แทน Tab

ตัวอย่างที่ผิด

```makefile
run:
    ./sim/obj_dir/counter_sim
```

ตัวอย่างที่ถูกต้องต้องใช้ Tab ก่อนคำสั่ง

```makefile
run:
	./sim/obj_dir/counter_sim
```

---

### ปัญหา 10: Build เดิมยังถูกใช้หลังแก้ RTL

ล้าง generated files ก่อน

```bash
make clean
make run
```

หรือบังคับ rebuild

```bash
make -B run
```

---

## 2.28 Checklist การตรวจสอบผล

ก่อนถือว่า Lab ผ่าน ให้ตรวจสอบรายการต่อไปนี้

### ด้านเครื่องมือ

- [ ] `verilator --version` ทำงาน
- [ ] `make --version` ทำงาน
- [ ] `gtkwave --version` ทำงาน

### ด้าน RTL

- [ ] โมดูลชื่อ `counter`
- [ ] `count_o` มีขนาด 8 บิต
- [ ] ใช้ `always_ff`
- [ ] ใช้ nonblocking assignment
- [ ] Reset เป็น active-low
- [ ] Reset เป็น synchronous reset

### ด้าน Testbench

- [ ] สร้าง clock คาบ 10 ns
- [ ] Assert reset ตอนเริ่มต้น
- [ ] ปล่อย reset ที่ negative edge
- [ ] ตรวจสอบ normal counting
- [ ] ตรวจสอบ reset ระหว่างทำงาน
- [ ] ตรวจสอบ overflow
- [ ] มี reference model
- [ ] มี error counter
- [ ] สร้าง waveform
- [ ] แสดง PASS หรือ FAIL อย่างชัดเจน

### ด้านผลลัพธ์

- [ ] `make lint` ผ่าน
- [ ] `make run` ผ่าน
- [ ] แสดง `LAB RESULT: PASS`
- [ ] Exit code เท่ากับศูนย์
- [ ] มีไฟล์ `waves/counter.fst`
- [ ] เปิด waveform ด้วย GTKWave ได้
- [ ] เห็นลำดับ `FE → FF → 00`
- [ ] Negative test สามารถทำให้ testbench รายงาน FAIL ได้

---

## 2.29 คำถามท้ายบทปฏิบัติการ

1. เหตุใด `rst_ni` จึงเรียกว่า active-low reset?
2. Reset ของวงจรนี้เป็น synchronous หรือ asynchronous reset?
3. หาก `rst_ni` เปลี่ยนจาก 1 เป็น 0 ระหว่าง clock edges ค่า `count_o` จะเปลี่ยนทันทีหรือไม่?
4. เหตุใด sequential logic จึงควรใช้ nonblocking assignment?
5. Counter ขนาด 8 บิตสามารถเก็บค่าได้กี่ค่าที่แตกต่างกัน?
6. หลังจาก `8'hFF` ค่าถัดไปคืออะไร เพราะเหตุใด?
7. เหตุใด testbench จึงเปลี่ยน reset ที่ negative edge?
8. เหตุใดจึงใช้ `!==` แทน `!=` ใน checker?
9. Reference model มีหน้าที่อะไร?
10. ความแตกต่างระหว่าง waveform-based verification กับ self-checking verification คืออะไร?
11. หาก clock period ลดจาก 10 ns เป็น 5 ns ความถี่จะเปลี่ยนเป็นเท่าใด?
12. การที่ lint ผ่านยืนยันได้หรือไม่ว่า RTL ทำงานถูกต้อง?
13. Negative test มีประโยชน์อย่างไร?
14. เหตุใดจึงต้องทดสอบ reset ระหว่างที่วงจรกำลังนับ?
15. เหตุใดจึงต้องตรวจสอบ overflow แม้ RTL มีเพียงคำสั่งบวกหนึ่ง?

---

## 2.30 แบบฝึกหัดเพิ่มเติม

### แบบฝึกหัด 2.1

แก้เคาน์เตอร์ให้มีขนาด 16 บิต และปรับ testbench ให้รองรับ

### แบบฝึกหัด 2.2

เพิ่มสัญญาณ `en_i` และตรวจสอบว่าเมื่อ `en_i = 0` เคาน์เตอร์ต้องคงค่าเดิม

### แบบฝึกหัด 2.3

เพิ่มสัญญาณ `load_i` และ `data_i` เพื่อให้โหลดค่าเริ่มต้นเข้าสู่เคาน์เตอร์ได้

ลำดับความสำคัญให้เป็น

```text
Reset > Load > Enable > Hold
```

### แบบฝึกหัด 2.4

เปลี่ยนวงจรเป็น down-counter

```text
FF → FE → FD → ... → 01 → 00 → FF
```

### แบบฝึกหัด 2.5

สร้าง up/down counter โดยเพิ่มสัญญาณ `up_i`

```text
up_i = 1 → นับขึ้น
up_i = 0 → นับลง
```

### แบบฝึกหัด 2.6

เพิ่ม assertion ที่ตรวจว่าค่าเคาน์เตอร์คงที่ขณะ `en_i = 0`

### แบบฝึกหัด 2.7

เปลี่ยน waveform จาก FST เป็น VCD และเปรียบเทียบขนาดไฟล์

### แบบฝึกหัด 2.8

สร้าง testbench ที่สุ่มค่า reset และ enable อย่างน้อย 1,000 clock cycles และเปรียบเทียบกับ reference model

---

## 2.31 สิ่งที่ต้องส่ง

ผู้เรียนต้องส่งไฟล์ต่อไปนี้

```text
lab02_counter_sim/
├── Makefile
├── rtl/
│   └── counter.sv
├── tb/
│   └── counter_tb.sv
├── waves/
│   └── counter.fst
├── simulation.log
└── report.md
```

สร้าง simulation log ด้วยคำสั่ง

```bash
make clean
make lint 2>&1 | tee lint.log
make run 2>&1 | tee simulation.log
```

เนื้อหาใน `report.md` ต้องประกอบด้วย:

1. วัตถุประสงค์ของการทดลอง
2. Block diagram ของ testbench
3. คำอธิบาย RTL
4. คำอธิบาย test sequence
5. ภาพ waveform ช่วง reset
6. ภาพ waveform ช่วง normal counting
7. ภาพ waveform ช่วง overflow
8. ผลจาก self-checking testbench
9. ผลจาก negative test
10. สรุปผลและปัญหาที่พบ

---

## 2.32 สรุปบทปฏิบัติการ

บทปฏิบัติการนี้แสดงกระบวนการ verification พื้นฐานของวงจร sequential ตั้งแต่การอ่าน RTL specification การสร้าง clock และ reset การเขียน self-checking testbench การใช้ reference model การตรวจสอบ overflow และการวิเคราะห์ waveform

แนวคิดสำคัญที่ได้จาก Lab นี้คือ:

```text
RTL ที่คอมไพล์ผ่าน ไม่ได้หมายความว่าทำงานถูกต้อง
```

การตรวจสอบที่น่าเชื่อถือควรประกอบด้วยทั้ง

```text
Lint
+ Directed Test
+ Automatic Checking
+ Waveform Inspection
+ Negative Test
```

เมื่อ simulation แสดง `LAB RESULT: PASS` และ negative test สามารถตรวจพบ RTL ที่ถูกแก้ให้ผิดได้ จึงถือว่า verification environment มีความน่าเชื่อถือในระดับพื้นฐาน และสามารถนำ RTL ไปใช้ในขั้นตอน Logic Synthesis และ RTL-to-GDSII ต่อไปได้


โครงสร้างนี้ตั้งใจแยก **functional simulation** ออกจาก `config.yaml` ของ LibreLane ซึ่งใน repository กำหนด top module เป็น `counter`, ใช้ `counter.sv`, clock port `clk_i` และ clock period 10 ns  
