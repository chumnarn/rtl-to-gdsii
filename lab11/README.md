
# Lab 11: Controlling and Debugging the Flow

## 11.1 วัตถุประสงค์ของบทปฏิบัติการ

เมื่อจบบทปฏิบัติการนี้ ผู้เรียนจะสามารถ

1. อธิบายความสัมพันธ์ระหว่าง Flow, Step, State และ Configuration ของ LibreLane ได้
2. ใช้ไฟล์ `config.yaml` ควบคุม Classic Flow ได้
3. กำหนดชื่อ run เพื่อแยกการทดลองแต่ละชุดออกจากกันได้
4. ตรวจสอบรายการ Step ที่ LibreLane เรียกใช้งานจริงได้
5. รัน Flow เต็มรูปแบบและรันเฉพาะช่วงที่สนใจได้
6. หยุด Flow ที่ตำแหน่งหนึ่งเพื่อวิเคราะห์ intermediate result ได้
7. ปิดหรือแทนที่ Step ผ่านส่วน `meta` ของ `config.yaml` ได้
8. อ่าน `error.log`, `warning.log`, step log และ report ได้
9. ใช้ `resolved.json` เพื่อทำซ้ำผลการทดลองได้
10. จำแนกปัญหา RTL, constraint, floorplan, placement, CTS, routing, timing, DRC และ LVS ได้
11. สร้าง Debug Matrix เพื่อเปรียบเทียบผลจาก configuration หลายชุดได้
12. ใช้กระบวนการแก้ปัญหาแบบเปลี่ยนตัวแปรครั้งละหนึ่งกลุ่มได้

---

## 11.2 ความรู้พื้นฐานที่ต้องมี

ผู้เรียนควรผ่านบทปฏิบัติการก่อนหน้านี้ ได้แก่

- การติดตั้ง LibreLane และ PDK
- การจำลอง RTL
- Logic synthesis
- Static timing analysis
- Floorplanning
- Placement
- Clock tree synthesis
- Global routing และ detailed routing
- DRC และ LVS เบื้องต้น

ตัวอย่างใน Lab นี้ใช้วงจร synchronous counter ขนาด 8 บิต โดยมี

- Top module: `counter`
- Clock port: `clk_i`
- Reset port: `rst_ni`
- Output port: `count_o[7:0]`
- Target clock period: 20 ns
- Target frequency: 50 MHz
- PDK ตัวอย่าง: `sky130A`
- Standard-cell library ตัวอย่าง: `sky130_fd_sc_hd`

---

## 11.3 แนวคิดของ LibreLane Flow

### 11.3.1 Flow

Flow คือชุดของขั้นตอนที่ใช้เปลี่ยน RTL ให้กลายเป็น layout สำหรับผลิตชิป ตัวอย่าง Flow มาตรฐาน ได้แก่

- `Classic` สำหรับ hard macro หรือ digital core
- `Chip` สำหรับงานระดับชิปที่มี I/O pad และองค์ประกอบระดับ top-level

หากไม่ได้ระบุ Flow LibreLane จะใช้ `Classic` เป็นค่าเริ่มต้นในหลาย installation แต่ควรเขียน `meta.flow` ลงใน `config.yaml` อย่างชัดเจนเพื่อให้ configuration อ่านง่ายและทำซ้ำได้

### 11.3.2 Step

Step คือหน่วยการทำงานย่อย เช่น

- `Verilator.Lint`
- `Yosys.Synthesis`
- `OpenROAD.CheckSDCFiles`
- `OpenROAD.Floorplan`
- `OpenROAD.GlobalPlacement`
- `OpenROAD.CTS`
- `OpenROAD.GlobalRouting`
- `OpenROAD.DetailedRouting`
- `OpenROAD.STAPostPNR`
- `KLayout.DRC`
- `Magic.DRC`
- `Netgen.LVS`

ชื่อและลำดับของ Step อาจแตกต่างตาม LibreLane version, PDK และ configuration ที่เลือกใช้

### 11.3.3 State

State คือชุดไฟล์ design view ที่มีอยู่หลังจบ Step หนึ่ง เช่น

- RTL source
- Yosys JSON
- Gate-level Verilog
- SDC
- ODB
- DEF
- LEF
- SPEF
- SDF
- GDS
- SPICE netlist

แนวคิดสำคัญคือ

```text
State(i) = Step(i)(State(i-1), Configuration)
```

ดังนั้น เมื่อ Step ใดล้มเหลว ต้องตรวจทั้ง

1. Configuration ที่ Step นั้นได้รับ
2. State ที่มาจาก Step ก่อนหน้า
3. Log และ report ของ Step ที่ล้มเหลว

### 11.3.4 Configuration

Configuration คือค่าควบคุม Flow เช่น

- RTL input
- PDK และ standard-cell library
- Clock constraint
- Floorplan utilization
- Placement density
- Routing layers
- Timing optimization
- DRC/LVS controls

LibreLane จะ validate ชนิดข้อมูลและชื่อ configuration variable ก่อนหรือระหว่างเริ่ม Flow หากสะกดชื่อตัวแปรผิด LibreLane อาจแจ้งว่าเป็น unknown variable หรือ deprecated variable

---

## 11.4 โครงสร้างโฟลเดอร์ Lab

สร้างโครงสร้างดังนี้

```text
lab11_control_debug/
├── config.yaml
├── config_baseline.yaml
├── config_debug.yaml
├── config_fast.yaml
├── src/
│   └── counter.sv
├── scripts/
│   ├── inspect_run.sh
│   ├── find_errors.sh
│   ├── compare_metrics.py
│   └── clean_runs.sh
├── runs/
└── README.md
```

สร้างไดเรกทอรีด้วยคำสั่ง

```bash
mkdir -p lab11_control_debug/{src,scripts,runs}
cd lab11_control_debug
```

ตรวจสอบ

```bash
find . -maxdepth 2 -type d | sort
```

ผลที่คาดหวัง

```text
.
./runs
./scripts
./src
```

---

## 11.5 สร้าง RTL สำหรับการทดลอง

สร้างไฟล์ `src/counter.sv`

```systemverilog
module counter #(
    parameter int unsigned WIDTH = 8
) (
    input  logic             clk_i,
    input  logic             rst_ni,
    output logic [WIDTH-1:0] count_o
);

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            count_o <= '0;
        end else begin
            count_o <= count_o + 1'b1;
        end
    end

endmodule
```

ตรวจสอบว่า top module ตรงกับค่า `DESIGN_NAME`

```bash
grep -n "module counter" src/counter.sv
```

---

## 11.6 ตรวจสอบ LibreLane Environment

### ขั้นตอนที่ 1: ตรวจสอบ executable

```bash
which librelane
```

### ขั้นตอนที่ 2: ตรวจสอบ version

```bash
librelane --version
```

บันทึก version ลงในไฟล์

```bash
librelane --version | tee librelane-version.txt
```

### ขั้นตอนที่ 3: ตรวจสอบ command-line options

```bash
librelane --help | less
```

ค้นหาตัวเลือกที่เกี่ยวข้องกับ

```text
--pdk
--scl
--flow
--run-tag
--from
--to
--skip
--overwrite
--dockerized
```

ชื่อ option บางตัวอาจแตกต่างตาม release ที่ติดตั้ง ให้ยึด output จาก `librelane --help` เป็นหลัก

### ขั้นตอนที่ 4: ตรวจสอบ PDK root

```bash
echo "${PDK_ROOT:-$HOME/.ciel}"
```

หากใช้ Nix installation โดยทั่วไป LibreLane จะจัดการ environment และ dependency ให้

หากใช้ Docker ให้เพิ่ม `--dockerized` หลังคำสั่ง `librelane` เช่น

```bash
librelane --dockerized --version
```

---

## 11.7 สร้าง Baseline Configuration

สร้างไฟล์ `config_baseline.yaml`

```yaml
meta:
  version: 2
  flow: Classic

DESIGN_NAME: counter

VERILOG_FILES:
  - dir::src/counter.sv

CLOCK_PORT: clk_i
CLOCK_PERIOD: 20.0

FP_SIZING: relative
FP_CORE_UTIL: 35
FP_ASPECT_RATIO: 1.0
FP_CORE_MARGIN: 5

PL_TARGET_DENSITY_PCT: 45

RT_MAX_LAYER: met4

RUN_LINTER: true
RUN_HEURISTIC_DIODE_INSERTION: true

MAGIC_DRC:
  enabled: true

KLAYOUT_DRC:
  enabled: true
```

> Configuration variable แบบ nested เช่น `MAGIC_DRC.enabled` หรือชื่อ switch บางรายการขึ้นกับ LibreLane release หาก version ที่ใช้อยู่ไม่รู้จักรูปแบบนี้ ให้ลบบล็อกดังกล่าวและใช้ค่า default ของ Classic Flow ก่อน

สำหรับ configuration ที่เน้น compatibility สูงสุด สามารถเริ่มจากไฟล์ขั้นต่ำดังนี้

```yaml
meta:
  version: 2
  flow: Classic

DESIGN_NAME: counter

VERILOG_FILES:
  - dir::src/counter.sv

CLOCK_PORT: clk_i
CLOCK_PERIOD: 20.0

FP_CORE_UTIL: 35
FP_ASPECT_RATIO: 1.0
FP_CORE_MARGIN: 5

PL_TARGET_DENSITY_PCT: 45
RT_MAX_LAYER: met4
```

คัดลอกเป็นไฟล์ทำงานหลัก

```bash
cp config_baseline.yaml config.yaml
```

---

## 11.8 ความหมายของ Prefix `dir::`

ใน `config.yaml`

```yaml
VERILOG_FILES:
  - dir::src/counter.sv
```

`dir::` หมายถึงให้ resolve path โดยอ้างอิงจากไดเรกทอรีที่เก็บ configuration file ไม่ใช่ไดเรกทอรีที่ผู้ใช้ยืนอยู่ขณะเรียกคำสั่ง

ข้อดีคือสามารถเรียก LibreLane จากไดเรกทอรีอื่นได้ เช่น

```bash
cd ..
librelane lab11_control_debug/config.yaml
```

โดย path ของ RTL ยังคงถูก resolve เป็น

```text
lab11_control_debug/src/counter.sv
```

วิธีนี้เหมาะกว่าการใช้ relative path ธรรมดาใน project ที่ต้องรันจาก CI/CD หรือเครื่องหลายเครื่อง

---

## 11.9 ตรวจสอบ YAML ก่อนรัน

YAML ไวต่อ indentation ห้ามใช้ tab และควรใช้ space จำนวนคงที่

ตรวจสอบไฟล์ด้วย Python

```bash
python3 - <<'PY'
from pathlib import Path
import yaml

config_file = Path("config.yaml")

try:
    with config_file.open("r", encoding="utf-8") as f:
        config = yaml.safe_load(f)
except Exception as exc:
    raise SystemExit(f"YAML error: {exc}")

print("YAML syntax: OK")
print("DESIGN_NAME :", config.get("DESIGN_NAME"))
print("CLOCK_PORT :", config.get("CLOCK_PORT"))
print("CLOCK_PERIOD:", config.get("CLOCK_PERIOD"))
print("FLOW        :", config.get("meta", {}).get("flow"))
PY
```

หากไม่มี PyYAML

```bash
python3 -m pip install pyyaml
```

ตรวจ tab character

```bash
grep -nP '\t' config.yaml
```

หากไม่มี output หมายความว่าไม่พบ tab

ตรวจ path ของ RTL

```bash
test -f src/counter.sv && echo "RTL file: FOUND" || echo "RTL file: MISSING"
```

---

## 11.10 รัน Baseline Flow

### Nix หรือ native environment

```bash
librelane \
  --pdk sky130A \
  --scl sky130_fd_sc_hd \
  --run-tag baseline \
  config.yaml
```

### Docker installation

```bash
librelane \
  --dockerized \
  --pdk sky130A \
  --scl sky130_fd_sc_hd \
  --run-tag baseline \
  config.yaml
```

หาก LibreLane version ที่ติดตั้งไม่รองรับ `--run-tag` ให้ตรวจสอบชื่อ option ที่เทียบเท่าจาก

```bash
librelane --help
```

หรือปล่อยให้ LibreLane สร้างชื่อ run อัตโนมัติ

---

## 11.11 ตรวจสอบโครงสร้าง Run Directory

หลังเริ่ม Flow ให้ตรวจสอบ

```bash
find runs/baseline -maxdepth 1 -type d | sort
```

โครงสร้างโดยประมาณ

```text
runs/baseline/
├── 01-verilator-lint/
├── 02-checker-linttimingconstructs/
├── 03-checker-linterrors/
├── 04-yosys-jsonheader/
├── 05-yosys-synthesis/
├── ...
├── final/
├── tmp/
├── error.log
├── info.log
├── resolved.json
└── warning.log
```

เลขลำดับและชื่อ Step อาจไม่เหมือนตัวอย่างทุกประการ

หลักการสำคัญคือ

- แต่ละ Step มีไดเรกทอรีของตนเอง
- ผลลัพธ์ของ Step ไม่ควรถูกเขียนทับใน Step ก่อนหน้า
- Step ที่มีเลขมากกว่าจะใช้ State จาก Step ก่อนหน้า
- ไฟล์ใน `final/` คือ final views ที่ Flow เลือกไว้
- `resolved.json` คือ configuration ที่ LibreLane resolve แล้ว

---

## 11.12 ตรวจสอบ Global Log

### แสดง Error ทั้งหมด

```bash
cat runs/baseline/error.log
```

### แสดง Warning ทั้งหมด

```bash
cat runs/baseline/warning.log
```

บาง release อาจใช้ชื่อ `warnings.log` ให้ตรวจสอบด้วย

```bash
find runs/baseline -maxdepth 1 \
  \( -name "*error*.log" -o -name "*warning*.log" \) \
  -print
```

### อ่านข้อมูลการรัน

```bash
less runs/baseline/info.log
```

### ค้นหาข้อความสำคัญ

```bash
grep -RniE \
  "error|fatal|failed|violation|unmapped|overflow|congestion" \
  runs/baseline \
  --include="*.log" \
  --include="*.rpt" \
  | head -100
```

ข้อควรระวัง: คำว่า `error` อาจปรากฏในชื่อ metric หรือข้อความอธิบายที่ไม่ใช่ fatal error จึงต้องเปิดดูบริบทเสมอ

```bash
grep -RniC 3 "ERROR" runs/baseline
```

---

## 11.13 ค้นหา Step ที่ล้มเหลว

แสดง Step ทั้งหมด

```bash
find runs/baseline \
  -maxdepth 1 \
  -mindepth 1 \
  -type d \
  -printf "%f\n" \
  | sort
```

ดู Step ล่าสุด

```bash
find runs/baseline \
  -maxdepth 1 \
  -mindepth 1 \
  -type d \
  -printf "%f\n" \
  | sort -V \
  | tail
```

หาก Flow หยุดที่

```text
31-openroad-detailedrouting
```

ให้ตรวจสอบไฟล์ใน Step นี้ก่อน

```bash
find runs/baseline/31-openroad-detailedrouting \
  -maxdepth 2 \
  -type f \
  | sort
```

ค้นหา log

```bash
find runs/baseline/31-openroad-detailedrouting \
  -type f \
  \( -name "*.log" -o -name "*.rpt" \) \
  -print
```

เปิดไฟล์ log หลัก

```bash
less runs/baseline/31-openroad-detailedrouting/*.log
```

หาก wildcard ตรงกับหลายไฟล์ ให้ใช้

```bash
for f in runs/baseline/31-openroad-detailedrouting/*.log; do
    echo "===== $f ====="
    tail -80 "$f"
done
```

---

## 11.14 ทำความเข้าใจ Step ID

LibreLane ใช้ Step ID เช่น

```text
Yosys.Synthesis
OpenROAD.Floorplan
OpenROAD.GlobalPlacement
OpenROAD.CTS
OpenROAD.GlobalRouting
OpenROAD.DetailedRouting
Netgen.LVS
```

แต่ชื่อไดเรกทอรีจะถูก normalize เป็น lower-case เช่น

```text
05-yosys-synthesis
10-openroad-floorplan
31-openroad-detailedrouting
```

เมื่อใช้ตัวเลือกควบคุม Flow เช่น `--from`, `--to` หรือ `--skip` โดยทั่วไปต้องใช้ **Step ID** ไม่ใช่ชื่อโฟลเดอร์

ตัวอย่าง

```bash
librelane \
  --from OpenROAD.Floorplan \
  --to OpenROAD.DetailedPlacement \
  config.yaml
```

ไม่ควรใช้

```bash
librelane \
  --from 10-openroad-floorplan \
  config.yaml
```

ตรวจสอบ syntax ที่ LibreLane version ของผู้เรียนรองรับด้วย

```bash
librelane --help
```

---

## 11.15 การหยุด Flow ที่ Step ที่กำหนด

ในขั้น debug ไม่ควรรันถึง GDS ทุกครั้ง ตัวอย่างเช่น หากต้องการตรวจเฉพาะ synthesis และ floorplan ให้หยุดหลัง floorplan

```bash
librelane \
  --pdk sky130A \
  --scl sky130_fd_sc_hd \
  --run-tag debug_floorplan \
  --to OpenROAD.Floorplan \
  config.yaml
```

หลังจบให้ตรวจสอบ

```bash
find runs/debug_floorplan -maxdepth 1 -type d | sort
```

ตรวจ floorplan output

```bash
find runs/debug_floorplan \
  -path "*floorplan*" \
  -type f \
  \( -name "*.def" -o -name "*.odb" -o -name "*.lef" \) \
  -print
```

ประโยชน์ของ `--to`

- ลดเวลารอ
- ลดการสร้าง output ที่ยังไม่จำเป็น
- แยกปัญหาเป็นช่วง
- ตรวจสอบ hypothesis ได้เร็ว
- เหมาะสำหรับ parameter sweep

---

## 11.16 การเริ่ม Flow จาก Step ที่กำหนด

การเริ่มจาก Step กลาง Flow ต้องมี State ที่ Step นั้นต้องการ เช่น การเริ่มจาก placement ต้องมี floorplan state ที่ถูกต้อง

แนวคิดคำสั่ง

```bash
librelane \
  --from OpenROAD.GlobalPlacement \
  config.yaml
```

อย่างไรก็ตาม ไม่ควรสมมติว่า LibreLane สามารถค้นหา State จาก run เก่าได้โดยอัตโนมัติทุก version ผู้เรียนต้องตรวจสอบว่า command-line interface ต้องการ option สำหรับ

- run directory เดิม
- initial state
- state file
- latest run
- overwrite หรือ resume

ตรวจสอบด้วย

```bash
librelane --help | grep -iE \
  "from|to|state|resume|last|run|overwrite"
```

แนวทางที่ปลอดภัยสำหรับการเรียนคือ

1. ใช้ `--to` เพื่อหยุด Flow ที่ Step ที่ต้องการ
2. ตรวจสอบ output ของ Step นั้น
3. แก้ configuration
4. สร้าง run ใหม่
5. รันตั้งแต่ต้นจนถึง Step ที่สนใจ

แม้จะใช้เวลามากกว่า resume แต่ช่วยป้องกันการใช้ State เก่าร่วมกับ configuration ใหม่ที่ไม่สอดคล้องกัน

---

## 11.17 เหตุผลที่ไม่ควรใช้ State เก่าหลังเปลี่ยน Configuration บางประเภท

ตัวแปรบางกลุ่มส่งผลต่อโครงสร้าง design ตั้งแต่ช่วงต้น เช่น

### กลุ่ม Synthesis

```yaml
SYNTH_STRATEGY: AREA 0
SYNTH_BUFFERING: true
SYNTH_SIZING: true
```

เมื่อเปลี่ยนค่ากลุ่มนี้ ต้องเริ่มใหม่ตั้งแต่ synthesis

### กลุ่ม Floorplan

```yaml
FP_CORE_UTIL: 35
FP_ASPECT_RATIO: 1.0
FP_CORE_MARGIN: 5
DIE_AREA: [0, 0, 200, 200]
```

เมื่อเปลี่ยนค่ากลุ่มนี้ ต้องเริ่มใหม่อย่างน้อยตั้งแต่ floorplan

### กลุ่ม Placement

```yaml
PL_TARGET_DENSITY_PCT: 45
```

ควรเริ่มใหม่อย่างน้อยตั้งแต่ global placement

### กลุ่ม CTS

```yaml
CTS_CLK_BUFFERS:
  - sky130_fd_sc_hd__clkbuf_2
  - sky130_fd_sc_hd__clkbuf_4
```

ควรเริ่มใหม่ตั้งแต่ CTS และต้องมั่นใจว่า clock tree จาก run เก่าไม่ถูก reuse

### กลุ่ม Routing

```yaml
RT_MIN_LAYER: met1
RT_MAX_LAYER: met4
GRT_ADJUSTMENT: 0.3
```

ควรเริ่มใหม่ตั้งแต่ global routing

### กลุ่ม Signoff

การเปลี่ยน DRC rule deck หรือ LVS setup อาจรันเฉพาะ signoff ใหม่ได้ หาก routed layout และ extracted netlist ไม่เปลี่ยน

---

## 11.18 การสร้าง Fast Debug Configuration

สร้าง `config_fast.yaml`

```yaml
meta:
  version: 2
  flow: Classic

DESIGN_NAME: counter

VERILOG_FILES:
  - dir::src/counter.sv

CLOCK_PORT: clk_i
CLOCK_PERIOD: 20.0

FP_CORE_UTIL: 30
FP_ASPECT_RATIO: 1.0
FP_CORE_MARGIN: 5

PL_TARGET_DENSITY_PCT: 40

RT_MAX_LAYER: met4
```

ใช้ไฟล์นี้สำหรับรันถึง synthesis หรือ floorplan

```bash
librelane \
  --pdk sky130A \
  --scl sky130_fd_sc_hd \
  --run-tag fast_floorplan \
  --to OpenROAD.Floorplan \
  config_fast.yaml
```

แนวคิดของ fast configuration คือ

- ใช้ design ขนาดเล็ก
- ใช้ utilization ที่ไม่ aggressive
- ไม่เพิ่ม optimization ที่ซับซ้อน
- หยุดก่อนขั้นตอนที่ใช้เวลานาน
- เน้นตรวจความถูกต้องของ input และ constraint ก่อน

---

## 11.19 สร้าง Custom Flow ด้วย `meta.flow`

LibreLane รองรับการระบุรายการ Step ผ่าน configuration ได้โดยตรง ตัวอย่าง custom flow สำหรับตรวจ RTL, synthesis และ floorplan

สร้าง `config_debug.yaml`

```yaml
meta:
  version: 2
  flow:
    - Verilator.Lint
    - Yosys.Synthesis
    - OpenROAD.CheckSDCFiles
    - OpenROAD.STAPrePNR
    - OpenROAD.Floorplan

DESIGN_NAME: counter

VERILOG_FILES:
  - dir::src/counter.sv

CLOCK_PORT: clk_i
CLOCK_PERIOD: 20.0

FP_CORE_UTIL: 35
FP_ASPECT_RATIO: 1.0
FP_CORE_MARGIN: 5
```

รัน

```bash
librelane \
  --pdk sky130A \
  --scl sky130_fd_sc_hd \
  --run-tag custom_debug \
  config_debug.yaml
```

ข้อดี

- Flow สั้นและทำงานเร็ว
- ระบุ Step ที่ต้องการเรียนได้ชัดเจน
- เหมาะสำหรับ debug และสอนรายขั้นตอน
- ลดการพึ่งพาตัวเลือก CLI ที่อาจแตกต่างระหว่าง release

ข้อควรระวัง

- Step ต้องเรียงตาม dependency
- State ที่ Step ต้องการต้องถูกสร้างจาก Step ก่อนหน้า
- ชื่อ Step ต้องตรงกับ registry ของ LibreLane version นั้น
- การตัด checker บางตัวออกอาจทำให้ปัญหาถูกส่งต่อไปยัง Step หลัง

---

## 11.20 การลบ Step จาก Classic Flow

สามารถใช้ `substituting_steps` เพื่อแก้รายการ Step ของ Flow เดิม

ตัวอย่างปิด Magic DRC ชั่วคราวเพื่อทดลอง KLayout DRC เพียงตัวเดียว

```yaml
meta:
  version: 2
  flow: Classic
  substituting_steps:
    "Magic.DRC": null

DESIGN_NAME: counter

VERILOG_FILES:
  - dir::src/counter.sv

CLOCK_PORT: clk_i
CLOCK_PERIOD: 20.0

FP_CORE_UTIL: 35
PL_TARGET_DENSITY_PCT: 45
RT_MAX_LAYER: met4
```

`null` หมายถึงนำ Step นั้นออกจาก Flow

ไม่ควรใช้ configuration นี้เป็น final signoff โดยไม่เข้าใจข้อกำหนดของโครงการ เพราะ DRC engine ต่างตัวอาจตรวจ rule หรือ layout representation แตกต่างกัน

---

## 11.21 การแทนที่ Step

ตัวอย่างเชิงแนวคิด

```yaml
meta:
  version: 2
  flow: Classic
  substituting_steps:
    "Magic.DRC": "KLayout.DRC"
```

ความหมายคือแทนที่ `Magic.DRC` ด้วย `KLayout.DRC`

ในทางปฏิบัติ Classic Flow อาจมี KLayout DRC อยู่แล้ว การแทนที่เช่นนี้จึงอาจทำให้ KLayout DRC ถูกเรียกซ้ำ ตัวอย่างนี้ใช้เพื่ออธิบาย syntax เท่านั้น

---

## 11.22 การเพิ่ม Step ก่อนหรือหลัง Step เป้าหมาย

LibreLane รองรับแนวคิดการเพิ่ม Step ก่อนหรือหลัง target Step ผ่าน substitution syntax

- Prefix `-` หมายถึงวางก่อน target
- Prefix `+` หมายถึงวางหลัง target

การใช้งานนี้เหมาะกับ custom plugin หรือ custom checker มากกว่าการใช้งานพื้นฐาน

ก่อนใช้ต้องตรวจเอกสารของ LibreLane version และตรวจว่า Step ที่ต้องการเพิ่มถูก register แล้ว

---

## 11.23 ตรวจสอบ Resolved Configuration

หลังเริ่ม run LibreLane จะสร้าง

```text
runs/<run-tag>/resolved.json
```

ตรวจสอบ

```bash
python3 -m json.tool \
  runs/baseline/resolved.json \
  | less
```

ค้นหาค่าที่สำคัญ

```bash
grep -nE \
  '"PDK"|"STD_CELL_LIBRARY"|"CLOCK_PERIOD"|"FP_CORE_UTIL"|"PL_TARGET_DENSITY"' \
  runs/baseline/resolved.json
```

เปรียบเทียบค่าที่เขียนกับค่าที่ resolve แล้ว

```bash
python3 - <<'PY'
import json
from pathlib import Path

p = Path("runs/baseline/resolved.json")
data = json.loads(p.read_text(encoding="utf-8"))

keys = [
    "DESIGN_NAME",
    "PDK",
    "STD_CELL_LIBRARY",
    "CLOCK_PORT",
    "CLOCK_PERIOD",
    "FP_CORE_UTIL",
    "FP_ASPECT_RATIO",
    "PL_TARGET_DENSITY_PCT",
    "RT_MIN_LAYER",
    "RT_MAX_LAYER",
]

for key in keys:
    print(f"{key:25s}: {data.get(key, '<not present>')}")
PY
```

`resolved.json` มีประโยชน์สำหรับ

- ตรวจ default ที่ PDK เพิ่มเข้ามา
- ตรวจ alias หรือค่าที่ถูก migrate
- บันทึก configuration สำหรับ reproducibility
- เปรียบเทียบ run
- ส่งให้ผู้ดูแล Flow วิเคราะห์ปัญหา

---

## 11.24 รันซ้ำจาก `resolved.json`

LibreLane รองรับการใช้ resolved configuration เป็น input สำหรับ Flow เดิม

```bash
librelane \
  --run-tag reproduce_baseline \
  runs/baseline/resolved.json
```

หากใช้ Docker

```bash
librelane \
  --dockerized \
  --run-tag reproduce_baseline \
  runs/baseline/resolved.json
```

หลังรัน เปรียบเทียบ metric

```bash
diff -u \
  runs/baseline/final/metrics.csv \
  runs/reproduce_baseline/final/metrics.csv
```

ผลอาจมีความแตกต่างเล็กน้อยจาก

- LibreLane version
- tool version
- PDK revision
- absolute path
- timestamp
- platform
- thread scheduling
- nondeterministic behavior บางส่วนของ EDA tool

ดังนั้นการทำซ้ำที่ดีต้องบันทึกทั้ง

- `resolved.json`
- LibreLane version
- PDK revision
- operating environment
- container image หรือ Nix lock
- RTL revision
- SDC revision

---

## 11.25 ตรวจ Metrics

ไฟล์หลัก

```text
runs/<run-tag>/final/metrics.csv
runs/<run-tag>/final/metrics.json
```

ตรวจ JSON

```bash
python3 -m json.tool \
  runs/baseline/final/metrics.json \
  | less
```

ค้นหา metric สำคัญ

```bash
grep -iE \
  "area|utilization|wns|tns|violation|drc|lvs|wirelength|power" \
  runs/baseline/final/metrics.csv
```

ตัวอย่าง metric ที่ควรบันทึก

| กลุ่ม | Metric |
|---|---|
| Synthesis | cell count, sequential cell count, combinational area |
| Floorplan | die area, core area, core utilization |
| Placement | placement density, displacement violations |
| CTS | clock latency, clock skew, number of clock buffers |
| Routing | wire length, vias, congestion, routing violations |
| Timing | setup WNS, setup TNS, hold WNS, hold TNS |
| Signoff | Magic DRC, KLayout DRC, antenna violations, LVS errors |

ชื่อ metric จริงอาจแตกต่างตาม version

---

## 11.26 สร้าง Script ตรวจ Run

สร้าง `scripts/inspect_run.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

RUN_DIR="${1:-}"

if [[ -z "$RUN_DIR" ]]; then
    echo "Usage: $0 runs/<run-tag>" >&2
    exit 1
fi

if [[ ! -d "$RUN_DIR" ]]; then
    echo "ERROR: run directory not found: $RUN_DIR" >&2
    exit 1
fi

echo "============================================================"
echo "Run directory: $RUN_DIR"
echo "============================================================"

echo
echo "[1] Step directories"
find "$RUN_DIR" \
    -maxdepth 1 \
    -mindepth 1 \
    -type d \
    -printf "%f\n" \
    | sort -V

echo
echo "[2] Global error logs"
find "$RUN_DIR" \
    -maxdepth 1 \
    -type f \
    -iname "*error*.log" \
    -print \
    -exec tail -50 {} \;

echo
echo "[3] Global warning logs"
find "$RUN_DIR" \
    -maxdepth 1 \
    -type f \
    -iname "*warning*.log" \
    -print \
    -exec tail -50 {} \;

echo
echo "[4] Final output files"
if [[ -d "$RUN_DIR/final" ]]; then
    find "$RUN_DIR/final" -maxdepth 2 -type f | sort
else
    echo "No final directory found."
fi

echo
echo "[5] Metrics summary"
if [[ -f "$RUN_DIR/final/metrics.csv" ]]; then
    grep -iE \
      "area|utilization|wns|tns|drc|lvs|antenna|wirelength|power" \
      "$RUN_DIR/final/metrics.csv" \
      || true
else
    echo "metrics.csv not found."
fi

echo
echo "[6] Last step"
find "$RUN_DIR" \
    -maxdepth 1 \
    -mindepth 1 \
    -type d \
    -printf "%f\n" \
    | sort -V \
    | tail -1
```

ให้สิทธิ์ execute

```bash
chmod +x scripts/inspect_run.sh
```

ใช้งาน

```bash
scripts/inspect_run.sh runs/baseline
```

---

## 11.27 สร้าง Script ค้นหา Error

สร้าง `scripts/find_errors.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

RUN_DIR="${1:-}"

if [[ -z "$RUN_DIR" || ! -d "$RUN_DIR" ]]; then
    echo "Usage: $0 runs/<run-tag>" >&2
    exit 1
fi

PATTERN='ERROR|FATAL|failed|unmapped|overflow|short|violation|congestion'

find "$RUN_DIR" \
    -type f \
    \( -name "*.log" -o -name "*.rpt" -o -name "*.txt" \) \
    -print0 \
    | xargs -0 grep -niE "$PATTERN" \
    || true
```

ให้สิทธิ์

```bash
chmod +x scripts/find_errors.sh
```

ใช้งาน

```bash
scripts/find_errors.sh runs/baseline | less
```

บันทึกผล

```bash
scripts/find_errors.sh runs/baseline \
  > runs/baseline/debug-summary.txt
```

---

## 11.28 Debugging Workflow มาตรฐาน

ใช้กระบวนการต่อไปนี้ทุกครั้งที่ Flow ล้มเหลว

### ขั้นที่ 1: ระบุ Step ที่ล้มเหลว

ดูบรรทัดท้ายของ terminal และ run directory

```bash
scripts/inspect_run.sh runs/<run-tag>
```

### ขั้นที่ 2: อ่าน Global Error

```bash
cat runs/<run-tag>/error.log
```

### ขั้นที่ 3: อ่าน Step Log

```bash
find runs/<run-tag>/<failed-step> \
  -type f \
  \( -name "*.log" -o -name "*.rpt" \) \
  -print
```

### ขั้นที่ 4: ค้นหา Error แรก

อย่าเริ่มแก้จาก error บรรทัดสุดท้ายเสมอ เพราะ error ช่วงท้ายอาจเป็นผลต่อเนื่องจาก error แรก

```bash
grep -RniE "ERROR|FATAL" \
  runs/<run-tag>/<failed-step> \
  | head -20
```

### ขั้นที่ 5: จำแนกประเภทปัญหา

- Tool/environment
- YAML/configuration
- RTL/lint
- Synthesis
- SDC/timing constraint
- Floorplan/PDN
- Placement
- CTS
- Routing
- Extraction
- DRC
- LVS

### ขั้นที่ 6: ตรวจ Input ของ Step

ตรวจไฟล์ State จาก Step ก่อนหน้า เช่น

```bash
find runs/<run-tag>/<previous-step> \
  -type f \
  \( -name "*.v" -o -name "*.def" -o -name "*.odb" -o -name "*.sdc" \)
```

### ขั้นที่ 7: ตั้ง Hypothesis

ตัวอย่าง

```text
Hypothesis:
Detailed routing ล้มเหลวเพราะ placement density สูงเกินไป
```

### ขั้นที่ 8: เปลี่ยนค่าครั้งละหนึ่งกลุ่ม

```yaml
PL_TARGET_DENSITY_PCT: 40
```

อย่าเปลี่ยนทั้ง utilization, clock period, routing layer และ CTS buffer พร้อมกัน เพราะจะไม่ทราบว่าค่าใดแก้ปัญหาได้จริง

### ขั้นที่ 9: สร้าง Run ใหม่

```bash
librelane \
  --run-tag density40 \
  config_density40.yaml
```

### ขั้นที่ 10: เปรียบเทียบ Metric

```bash
python3 scripts/compare_metrics.py \
  runs/baseline/final/metrics.json \
  runs/density40/final/metrics.json
```

### ขั้นที่ 11: บันทึกผล

| Run | ตัวแปรที่เปลี่ยน | ผลลัพธ์ |
|---|---|---|
| baseline | ไม่มี | Detailed routing failed |
| density40 | density 45 → 40 | Routing completed |
| density35 | density 40 → 35 | Routing completed, area unchanged |

---

## 11.29 Debug ปัญหา YAML และ Configuration

### อาการ: YAML Parser Error

ตัวอย่างข้อความ

```text
mapping values are not allowed here
```

สาเหตุที่พบบ่อย

- indentation ผิด
- ใช้ tab
- ลืม `:`
- list ไม่ขึ้นต้นด้วย `-`
- string มี `:` แต่ไม่ใส่ quote

ตัวอย่างผิด

```yaml
VERILOG_FILES:
- dir::src/counter.sv
 CLOCK_PORT: clk_i
```

ตัวอย่างถูก

```yaml
VERILOG_FILES:
  - dir::src/counter.sv

CLOCK_PORT: clk_i
```

### อาการ: Unknown Configuration Variable

ตัวอย่าง

```text
Unknown key FP_CORE_UTL
```

ตรวจ spelling

```yaml
FP_CORE_UTIL: 35
```

ไม่ใช่

```yaml
FP_CORE_UTL: 35
```

### อาการ: Path Not Found

ตรวจ

```bash
realpath src/counter.sv
```

ใช้

```yaml
VERILOG_FILES:
  - dir::src/counter.sv
```

ไม่ควรใช้ path ที่อ้างอิงเครื่องส่วนตัว เช่น

```yaml
VERILOG_FILES:
  - /home/user/project/src/counter.sv
```

ยกเว้นมีเหตุผลที่ชัดเจน

---

## 11.30 Debug ปัญหา RTL และ Lint

### อาการทั่วไป

- syntax error
- unsupported construct
- width mismatch
- latch inference
- multiple drivers
- undriven signal
- unused signal
- combinational loop
- top module not found

### ตรวจ RTL แยกจาก Flow

```bash
verilator \
  --lint-only \
  --Wall \
  -Wno-fatal \
  --top-module counter \
  src/counter.sv
```

### ตรวจด้วย Yosys

```bash
yosys -p '
  read_verilog -sv src/counter.sv
  hierarchy -check -top counter
  proc
  check
  stat
'
```

### ปัญหา Top Module

ค่าใน `config.yaml`

```yaml
DESIGN_NAME: counter
```

ต้องตรงกับ

```systemverilog
module counter (...);
```

### ปัญหาไฟล์หลายไฟล์

เรียง package ก่อน module ที่ import package

```yaml
VERILOG_FILES:
  - dir::src/counter_pkg.sv
  - dir::src/counter_core.sv
  - dir::src/counter.sv
```

---

## 11.31 Debug ปัญหา Synthesis

ค้นหา synthesis step

```bash
find runs/baseline \
  -maxdepth 1 \
  -type d \
  -iname "*yosys*synthesis*"
```

ตรวจ log

```bash
grep -RniE \
  "error|warning|unmapped|latch|multiple driver|not found" \
  runs/baseline/*yosys*synthesis*
```

### ปัญหา Unmapped Cell

สาเหตุ

- instantiate primitive ที่ library ไม่มี
- black-box module ไม่มี definition
- macro ไม่มี Liberty/LEF/GDS
- unsupported RTL construct
- technology mapping ไม่สมบูรณ์

ตรวจ netlist

```bash
find runs/baseline/*yosys*synthesis* \
  -type f \
  -name "*.v" \
  -print
```

ค้นหา cell ที่ไม่รู้จัก

```bash
grep -Rni '\$_' runs/baseline/*yosys*synthesis*/*.v
```

### ปัญหา Design ถูก Optimize หาย

ตรวจว่า output ไม่ได้เป็น constant

```bash
grep -n "assign count_o" \
  runs/baseline/*yosys*synthesis*/*.v
```

สาเหตุที่เป็นไปได้

- input ถูก tie constant
- output ไม่เชื่อมต่อ
- parameter ผิด
- top module ผิด
- black-box declaration ผิด

---

## 11.32 Debug ปัญหา Clock และ SDC

ตรวจค่า clock ใน configuration

```yaml
CLOCK_PORT: clk_i
CLOCK_PERIOD: 20.0
```

ตรวจ RTL port

```bash
grep -n "clk_i" src/counter.sv
```

ค้นหา clock report

```bash
find runs/baseline \
  -type f \
  \( -iname "*clock*.rpt" -o -iname "*sdc*.rpt" \) \
  -print
```

### อาการ Clock Port Not Found

สาเหตุ

- `CLOCK_PORT` สะกดไม่ตรง RTL
- clock ถูก rename
- top module ผิด
- clock อยู่ภายใน hierarchy
-ใช้ bus syntax ผิด

### อาการ No Clock Found

ตรวจ

```bash
grep -RniE \
  "no clock|clock.*not found|unconstrained" \
  runs/baseline
```

### อาการ Unconstrained Path

ควรตรวจ

- input delay
- output delay
- false path
- generated clock
- asynchronous reset
- clock-domain crossing

สำหรับ design หลาย clock domain ควรใช้ SDC file โดยตรงแทนการพึ่ง `CLOCK_PORT` เพียงตัวเดียว

---

## 11.33 Debug ปัญหา Floorplan

ค้นหา floorplan step

```bash
find runs/baseline \
  -maxdepth 1 \
  -type d \
  -iname "*floorplan*"
```

ตรวจ log

```bash
grep -RniE \
  "error|utilization|die|core|row|site|overlap" \
  runs/baseline/*floorplan*
```

### อาการ Core Area เล็กเกินไป

ลด utilization

```yaml
FP_CORE_UTIL: 25
```

หรือเพิ่ม margin

```yaml
FP_CORE_MARGIN: 10
```

### อาการ Core ใหญ่เกินไป

เพิ่ม utilization อย่างระมัดระวัง

```yaml
FP_CORE_UTIL: 40
```

อย่าเพิ่มสูงเกินไปเพียงเพื่อให้ area เล็ก เพราะอาจทำให้

- placement congestion
- CTS buffer ไม่มีที่วาง
- routing overflow
- DRC เพิ่ม
- timing closure ยากขึ้น

### Debug ด้วย Absolute Die Area

สำหรับทดลอง สามารถกำหนดพื้นที่ตายตัว

```yaml
FP_SIZING: absolute
DIE_AREA: [0, 0, 150, 150]
```

หน่วยโดยทั่วไปเป็นไมโครเมตร แต่ต้องตรวจข้อกำหนด PDK และ LibreLane version

---

## 11.34 Debug ปัญหา PDN

ค้นหา PDN step

```bash
find runs/baseline \
  -maxdepth 1 \
  -type d \
  -iname "*pdn*"
```

ตรวจ log

```bash
grep -RniE \
  "error|power|ground|strap|ring|pitch|offset|channel" \
  runs/baseline/*pdn*
```

ปัญหาที่พบบ่อย

- core เล็กเกินไปสำหรับ stripe
- PDN pitch มากกว่าพื้นที่ core
- offset ทำให้ stripe อยู่นอก core
- power/ground net ไม่ตรงกับ cell pin
- macro block PDN
- routing layer ไม่รองรับ
- core ring ชนกับ macro หรือ boundary

แนวทางแก้

1. เพิ่ม core area
2. ตรวจ power/ground net names
3. ลด stripe width หรือ pitch ตามข้อกำหนด PDK
4. ปิด core ring เฉพาะกรณีที่ flow architecture อนุญาต
5. ตรวจ macro obstruction
6. เปิด layout ดู PDN ก่อน placement

---

## 11.35 Debug ปัญหา Placement

ค้นหา placement steps

```bash
find runs/baseline \
  -maxdepth 1 \
  -type d \
  -iname "*placement*"
```

ตรวจ

```bash
grep -RniE \
  "error|density|overflow|overlap|legal|displacement|congestion" \
  runs/baseline/*placement*
```

### ปัญหา Placement Density สูง

ลดค่า

```yaml
PL_TARGET_DENSITY_PCT: 40
```

หากเดิมเป็น 50

### ปัญหา Detailed Placement ไม่ Legal

แนวทาง

- ลด `FP_CORE_UTIL`
- ลด `PL_TARGET_DENSITY_PCT`
- เพิ่ม core area
- ตรวจ macro halo
- ตรวจ row/site
- ตรวจ cell padding
- ตรวจ fixed instances
- ตรวจ power-grid obstruction

### ความแตกต่างระหว่าง Utilization และ Density

`FP_CORE_UTIL` ใช้กำหนดขนาด core จากพื้นที่ standard cell

`PL_TARGET_DENSITY_PCT` ใช้ควบคุมเป้าหมายความหนาแน่นของ global placement

ไม่ควรกำหนดสองค่านี้สูงพร้อมกันใน design ที่มี congestion

---

## 11.36 Debug ปัญหา CTS

ค้นหา CTS step

```bash
find runs/baseline \
  -maxdepth 1 \
  -type d \
  -iname "*cts*"
```

ตรวจ

```bash
grep -RniE \
  "error|clock|buffer|sink|skew|latency|transition" \
  runs/baseline/*cts*
```

### ปัญหา Clock Buffer Cell ไม่มี

ตรวจ standard-cell library

```bash
grep -Rni "clkbuf" \
  "${PDK_ROOT:-$HOME/.ciel}" \
  2>/dev/null \
  | head
```

อย่ากำหนดชื่อ buffer จาก PDK อื่น เช่นนำชื่อ Sky130 ไปใช้กับ IHP SG13G2

### ปัญหา CTS ไม่มี Sink

ตรวจว่า

- sequential cells ถูก synthesize จริง
- clock port เชื่อมถึง flip-flop
- clock ไม่ถูก optimize หาย
- design ไม่ใช่ combinational logic ล้วน
- clock net name ถูกต้อง

### ปัญหา Skew สูง

แนวทาง

- ลด utilization
- ปรับ placement
- กระจาย macro ใหม่
- จำกัดชุด clock buffer ที่เหมาะสม
- ตรวจ long detour
- เพิ่ม whitespace
- ตรวจ high fanout control nets

---

## 11.37 Debug ปัญหา Global Routing

ค้นหา global routing step

```bash
find runs/baseline \
  -maxdepth 1 \
  -type d \
  -iname "*globalrouting*"
```

ค้น congestion

```bash
grep -RniE \
  "overflow|congestion|unroutable|error|capacity" \
  runs/baseline/*globalrouting*
```

### อาการ Routing Overflow

แนวทางตามลำดับ

1. ลด placement density
2. ลด floorplan utilization
3. เพิ่ม core area
4. ปรับ aspect ratio
5. ตรวจ macro placement
6. เพิ่ม routing layers หาก PDK อนุญาต
7. ตรวจ PDN obstruction
8. ลด cell padding หากมากเกินไป
9. ลด buffer explosion จาก timing optimization
10. แก้ high-fanout net

ตัวอย่าง

```yaml
FP_CORE_UTIL: 30
PL_TARGET_DENSITY_PCT: 40
RT_MAX_LAYER: met5
```

ห้ามกำหนด `RT_MAX_LAYER` สูงกว่าชั้นโลหะที่ PDK รองรับ

---

## 11.38 Debug ปัญหา Detailed Routing

ค้นหา

```bash
find runs/baseline \
  -maxdepth 1 \
  -type d \
  -iname "*detailedrouting*"
```

ตรวจ violations

```bash
grep -RniE \
  "violation|short|spacing|unrouted|error|failed" \
  runs/baseline/*detailedrouting*
```

อาการสำคัญ

- short violations
- spacing violations
- minimum-area violations
- cut spacing violations
- pin-access failure
- unrouted net
- routing loop
- maximum iteration reached

แนวทาง

- แก้ congestion ตั้งแต่ placement/global routing
- ลด utilization
- เพิ่ม core area
- ตรวจ pin accessibility
- ปรับ macro orientation
- ตรวจ routing layer range
- ตรวจ PDN obstruction
- หลีกเลี่ยง macro channel ที่แคบ
- เพิ่มช่องว่างระหว่าง macro

อย่าพยายามแก้ detailed routing ด้วยการเพิ่ม iteration เพียงอย่างเดียว หากสาเหตุจริงคือ floorplan ไม่ routable

---

## 11.39 Debug ปัญหา Timing

LibreLane ทำ STA หลายช่วง ได้แก่ก่อน PnR, ระหว่าง PnR และหลัง PnR

ค้นหา STA step

```bash
find runs/baseline \
  -maxdepth 1 \
  -type d \
  -iname "*sta*"
```

ค้น WNS/TNS

```bash
grep -RniE \
  "WNS|TNS|worst negative slack|total negative slack" \
  runs/baseline/*sta*
```

ค้น timing report

```bash
find runs/baseline \
  -type f \
  \( -name "max.rpt" \
     -o -name "min.rpt" \
     -o -name "summary.rpt" \
     -o -name "wns*.rpt" \
     -o -name "tns*.rpt" \) \
  -print
```

### Setup Violation

แนวทาง

- เพิ่ม `CLOCK_PERIOD`
- ลด logic depth
- pipeline datapath
- ใช้ synthesis strategy ที่เน้น delay
- ปรับ cell sizing
- ลด fanout
- ปรับ placement
- ลด congestion
- ตรวจ false path และ multicycle path

### Hold Violation

แนวทาง

- ตรวจ clock skew
- ตรวจ hold fixer
- ตรวจ minimum-delay constraint
- เพิ่ม delay buffer
- ปรับ CTS
- อย่าแก้ด้วยการเพิ่ม clock period เพราะ hold ไม่ขึ้นกับ period ในลักษณะเดียวกับ setup

### Timing Debug Rule

อ่าน path report ไม่ใช่ดู WNS อย่างเดียว โดยตรวจ

- Startpoint
- Endpoint
- Path group
- Data arrival time
- Data required time
- Cell delay
- Net delay
- Clock latency
- Uncertainty
- Slack
- PVT corner

---

## 11.40 Debug ปัญหา DRC

ค้นหา DRC steps

```bash
find runs/baseline \
  -maxdepth 1 \
  -type d \
  -iname "*drc*"
```

ตรวจ report

```bash
find runs/baseline \
  -path "*drc*" \
  -type f \
  \( -name "*.rpt" -o -name "*.log" -o -name "*.xml" \) \
  -print
```

ค้น violation count

```bash
grep -RniE \
  "violation|count|total|error" \
  runs/baseline/*drc*
```

### DRC ไม่เท่ากันระหว่าง Magic และ KLayout

สาเหตุที่เป็นไปได้

- ใช้ rule deck คนละชุด
- layer mapping ต่างกัน
- fill หรือ seal ring ถูกอ่านต่างกัน
- waiver ต่างกัน
- hierarchy flattening ต่างกัน
- label/text interpretation ต่างกัน
- tool version ต่างกัน

ควรบันทึกผลแยก

```text
Magic DRC count:
KLayout DRC count:
Waived violations:
Unwaived violations:
```

DRC count เป็นศูนย์จึงจะถือว่า clean เว้นแต่โครงการมี waiver ที่ผ่านการอนุมัติอย่างเป็นทางการ

---

## 11.41 Debug ปัญหา LVS

ค้นหา LVS

```bash
find runs/baseline \
  -maxdepth 1 \
  -type d \
  -iname "*lvs*"
```

ตรวจ report

```bash
grep -RniE \
  "match|mismatch|net|device|property|pin|error" \
  runs/baseline/*lvs*
```

ปัญหาที่พบบ่อย

- top-cell name ไม่ตรง
- power pin ไม่ตรง
- ground pin ไม่ตรง
- missing label
- shorted nets
- open nets
- missing device
- extra device
- transistor parameter mismatch
- black-box macro setup ไม่ครบ
- source netlist และ extracted netlist คนละ revision

### LVS Debug Order

1. ตรวจ top-cell name
2. ตรวจจำนวน ports
3. ตรวจชื่อ ports
4. ตรวจ power/ground
5. ตรวจ unmatched nets
6. ตรวจ unmatched devices
7. ตรวจ property mismatch
8. ตรวจ macro black-box
9. ตรวจ source netlist revision
10. ตรวจ extraction log

อย่าเริ่มจาก transistor mismatch หาก report แสดงว่า top-level port ไม่ตรง เพราะ mismatch ระดับบนอาจสร้าง error ต่อเนื่องจำนวนมาก

---

## 11.42 เปรียบเทียบ Configuration สอง Run

ใช้ `resolved.json` เพื่อหาความแตกต่างที่ LibreLane ใช้งานจริง

```bash
diff -u \
  runs/baseline/resolved.json \
  runs/density40/resolved.json \
  | less
```

ใช้ `jq` เรียง key ก่อนเปรียบเทียบ

```bash
jq -S . runs/baseline/resolved.json \
  > /tmp/baseline-resolved.json

jq -S . runs/density40/resolved.json \
  > /tmp/density40-resolved.json

diff -u \
  /tmp/baseline-resolved.json \
  /tmp/density40-resolved.json
```

วิธีนี้ช่วยแยกว่า metric เปลี่ยนเพราะ

- configuration ที่ผู้เรียนตั้งใจเปลี่ยน
- default จาก PDK
- standard-cell library
- LibreLane version
- flow selection
- environment override

---

## 11.43 Script เปรียบเทียบ Metrics

สร้าง `scripts/compare_metrics.py`

```python
#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


INTERESTING_WORDS = (
    "area",
    "utilization",
    "density",
    "wns",
    "tns",
    "slack",
    "drc",
    "lvs",
    "antenna",
    "wire",
    "via",
    "power",
    "clock",
    "skew",
    "cell",
)


def load_json(path: Path) -> dict[str, Any]:
    try:
        with path.open("r", encoding="utf-8") as file:
            data = json.load(file)
    except FileNotFoundError as exc:
        raise SystemExit(f"File not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Invalid JSON in {path}: {exc}") from exc

    if not isinstance(data, dict):
        raise SystemExit(f"Expected a JSON object in {path}")

    return data


def is_interesting(key: str) -> bool:
    lower_key = key.lower()
    return any(word in lower_key for word in INTERESTING_WORDS)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Compare two LibreLane metrics.json files."
    )
    parser.add_argument("baseline", type=Path)
    parser.add_argument("experiment", type=Path)
    args = parser.parse_args()

    baseline = load_json(args.baseline)
    experiment = load_json(args.experiment)

    keys = sorted(set(baseline) | set(experiment))

    print(
        f"{'Metric':60s} "
        f"{'Baseline':>18s} "
        f"{'Experiment':>18s}"
    )
    print("-" * 100)

    for key in keys:
        if not is_interesting(key):
            continue

        base_value = baseline.get(key, "<missing>")
        exp_value = experiment.get(key, "<missing>")

        if base_value == exp_value:
            continue

        print(
            f"{key[:60]:60s} "
            f"{str(base_value)[:18]:>18s} "
            f"{str(exp_value)[:18]:>18s}"
        )


if __name__ == "__main__":
    main()
```

ให้สิทธิ์

```bash
chmod +x scripts/compare_metrics.py
```

ใช้งาน

```bash
python3 scripts/compare_metrics.py \
  runs/baseline/final/metrics.json \
  runs/density40/final/metrics.json
```

---

## 11.44 สร้าง Configuration สำหรับ Parameter Experiment

### Experiment A: ลด Utilization

สร้าง `config_util30.yaml`

```yaml
meta:
  version: 2
  flow: Classic

DESIGN_NAME: counter

VERILOG_FILES:
  - dir::src/counter.sv

CLOCK_PORT: clk_i
CLOCK_PERIOD: 20.0

FP_CORE_UTIL: 30
FP_ASPECT_RATIO: 1.0
FP_CORE_MARGIN: 5

PL_TARGET_DENSITY_PCT: 45
RT_MAX_LAYER: met4
```

รัน

```bash
librelane \
  --run-tag util30 \
  --pdk sky130A \
  --scl sky130_fd_sc_hd \
  config_util30.yaml
```

### Experiment B: ลด Placement Density

สร้าง `config_density40.yaml`

```yaml
meta:
  version: 2
  flow: Classic

DESIGN_NAME: counter

VERILOG_FILES:
  - dir::src/counter.sv

CLOCK_PORT: clk_i
CLOCK_PERIOD: 20.0

FP_CORE_UTIL: 35
FP_ASPECT_RATIO: 1.0
FP_CORE_MARGIN: 5

PL_TARGET_DENSITY_PCT: 40
RT_MAX_LAYER: met4
```

รัน

```bash
librelane \
  --run-tag density40 \
  --pdk sky130A \
  --scl sky130_fd_sc_hd \
  config_density40.yaml
```

### Experiment C: ผ่อนคลาย Clock

สร้าง `config_clk25.yaml`

```yaml
meta:
  version: 2
  flow: Classic

DESIGN_NAME: counter

VERILOG_FILES:
  - dir::src/counter.sv

CLOCK_PORT: clk_i
CLOCK_PERIOD: 25.0

FP_CORE_UTIL: 35
FP_ASPECT_RATIO: 1.0
FP_CORE_MARGIN: 5

PL_TARGET_DENSITY_PCT: 45
RT_MAX_LAYER: met4
```

รัน

```bash
librelane \
  --run-tag clk25 \
  --pdk sky130A \
  --scl sky130_fd_sc_hd \
  config_clk25.yaml
```

---

## 11.45 Debug Matrix

ให้บันทึกผลลงตาราง

| Run | Clock | Core Util. | Place Density | Routing | Setup WNS | Hold WNS | DRC | LVS |
|---|---:|---:|---:|---|---:|---:|---:|---|
| baseline | 20 ns | 35% | 45% |  |  |  |  |  |
| util30 | 20 ns | 30% | 45% |  |  |  |  |  |
| density40 | 20 ns | 35% | 40% |  |  |  |  |  |
| clk25 | 25 ns | 35% | 45% |  |  |  |  |  |

วิเคราะห์

1. การลด utilization เพิ่ม die/core area เท่าใด
2. routing congestion ลดลงหรือไม่
3. wire length เพิ่มขึ้นหรือไม่
4. setup slack ดีขึ้นหรือแย่ลง
5. hold slack เปลี่ยนหรือไม่
6. จำนวน buffer เพิ่มหรือลด
7. DRC count เปลี่ยนหรือไม่
8. ค่าใดให้ trade-off ที่ดีที่สุด

---

## 11.46 การเก็บ Terminal Output

ใช้ `tee` เพื่อเก็บ output

```bash
mkdir -p logs

librelane \
  --run-tag baseline \
  --pdk sky130A \
  --scl sky130_fd_sc_hd \
  config.yaml \
  2>&1 | tee logs/baseline-console.log
```

หากต้องการเก็บ exit status ที่ถูกต้องเมื่อใช้ pipe

```bash
set -o pipefail

librelane \
  --run-tag baseline \
  --pdk sky130A \
  --scl sky130_fd_sc_hd \
  config.yaml \
  2>&1 | tee logs/baseline-console.log

status=${PIPESTATUS[0]}
echo "LibreLane exit status: $status"
exit "$status"
```

---

## 11.47 การใช้ Exit Code

หลังคำสั่ง LibreLane

```bash
echo $?
```

โดยทั่วไป

- `0` หมายถึงคำสั่งสำเร็จ
- ค่าอื่นหมายถึงมีข้อผิดพลาด

ตัวอย่าง script

```bash
#!/usr/bin/env bash
set -uo pipefail

if librelane \
    --run-tag baseline \
    --pdk sky130A \
    --scl sky130_fd_sc_hd \
    config.yaml
then
    echo "FLOW STATUS: PASS"
else
    status=$?
    echo "FLOW STATUS: FAIL"
    echo "EXIT CODE : $status"
    exit "$status"
fi
```

วิธีนี้เหมาะกับ CI/CD

---

## 11.48 ทำความสะอาด Run อย่างปลอดภัย

สร้าง `scripts/clean_runs.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

RUN_ROOT="${1:-runs}"

if [[ "$RUN_ROOT" != "runs" ]]; then
    echo "Refusing to remove unexpected path: $RUN_ROOT" >&2
    exit 1
fi

if [[ ! -d "$RUN_ROOT" ]]; then
    echo "No runs directory."
    exit 0
fi

echo "Run directories:"
find "$RUN_ROOT" \
    -maxdepth 1 \
    -mindepth 1 \
    -type d \
    -printf "  %f\n" \
    | sort

read -r -p "Delete all run directories? Type DELETE: " answer

if [[ "$answer" != "DELETE" ]]; then
    echo "Cancelled."
    exit 0
fi

find "$RUN_ROOT" \
    -maxdepth 1 \
    -mindepth 1 \
    -type d \
    -exec rm -rf -- {} +

echo "Runs removed."
```

ให้สิทธิ์

```bash
chmod +x scripts/clean_runs.sh
```

ใช้งาน

```bash
scripts/clean_runs.sh
```

ไม่ควรใช้

```bash
rm -rf *
```

เพราะอาจลบ RTL และ configuration ทั้งหมด

---

## 11.49 แผนผังการ Debug

```text
Flow failed
    |
    v
Identify failed Step
    |
    v
Read global error.log
    |
    v
Read failed Step log/report
    |
    v
Find first meaningful error
    |
    v
Classify problem
    |
    +--> Environment / tool
    |
    +--> YAML / configuration
    |
    +--> RTL / synthesis
    |
    +--> SDC / timing
    |
    +--> Floorplan / PDN
    |
    +--> Placement / CTS
    |
    +--> Routing
    |
    +--> DRC / LVS
    |
    v
Form one hypothesis
    |
    v
Change one variable group
    |
    v
Create a new run tag
    |
    v
Compare resolved.json and metrics
    |
    +--> Fixed: document root cause
    |
    +--> Not fixed: form next hypothesis
```

---

## 11.50 Root-Cause Analysis Template

ใช้ template ต่อไปนี้ทุกครั้ง

```text
Run tag:
LibreLane version:
PDK:
SCL:
RTL revision:
Configuration file:

Failed step:
First meaningful error:
Related warnings:

Expected behavior:
Actual behavior:

Evidence:
1.
2.
3.

Hypothesis:

Configuration change:

New run tag:

Result:

Root cause:

Permanent corrective action:

Regression check:
```

ตัวอย่าง

```text
Run tag:
baseline

Failed step:
OpenROAD.DetailedRouting

First meaningful error:
Routing congestion remained after maximum iterations.

Evidence:
1. Global routing reported overflow near the center of the core.
2. Placement density was 55%.
3. No macro was present, so the congestion came from standard-cell placement.

Hypothesis:
Placement density was too aggressive for the available routing resources.

Configuration change:
PL_TARGET_DENSITY_PCT changed from 55 to 40.

New run tag:
density40

Result:
Detailed routing completed with zero unrouted nets.

Root cause:
Insufficient routing whitespace.

Permanent corrective action:
Use 40–45% placement density as the initial range for this design.
```

---

## 11.51 ลำดับการแก้ปัญหาที่แนะนำ

เมื่อพบหลาย error พร้อมกัน ให้แก้ตามลำดับ

1. Environment และ executable
2. PDK และ standard-cell library
3. YAML syntax
4. File path
5. RTL syntax และ lint
6. Top-module hierarchy
7. Synthesis unmapped cells
8. Clock และ SDC
9. Floorplan
10. PDN
11. Placement legality
12. CTS
13. Global routing congestion
14. Detailed routing
15. Timing
16. Antenna
17. DRC
18. LVS

เหตุผลคือปัญหาต้น Flow มักสร้าง error ต่อเนื่องในขั้นตอนปลาย Flow

---

## 11.52 สิ่งที่ไม่ควรทำระหว่าง Debug

### ไม่ควรแก้หลายตัวแปรพร้อมกัน

ผิด

```yaml
CLOCK_PERIOD: 30
FP_CORE_UTIL: 20
PL_TARGET_DENSITY_PCT: 30
RT_MAX_LAYER: met5
```

หาก Flow ผ่าน จะไม่ทราบว่าตัวแปรใดเป็นสาเหตุ

### ไม่ควรลบ checker เพื่อให้ Flow ผ่าน

เช่น ปิด lint, DRC หรือ LVS โดยไม่แก้ root cause

### ไม่ควรใช้ `resolved.json` จากคนละ RTL revision

State และ configuration อาจไม่ตรงกับ source ปัจจุบัน

### ไม่ควรแก้ไฟล์ภายใน Step Directory แล้วถือเป็น solution ถาวร

เมื่อรันใหม่ไฟล์เหล่านั้นจะถูกสร้างใหม่ ควรแก้ที่

- RTL
- SDC
- `config.yaml`
- macro source
- custom script หรือ plugin

### ไม่ควรตัดสินจาก Terminal บรรทัดสุดท้ายเพียงอย่างเดียว

ต้องหา first meaningful error

### ไม่ควรถือว่า Warning ทั้งหมดไม่สำคัญ

Warning เช่น unconstrained path, unmapped cell, clock not propagated หรือ missing power pin อาจทำให้ final result ใช้ไม่ได้แม้ Flow จบ

---

## 11.53 Pass Criteria ของ Lab

ถือว่าผ่าน Lab เมื่อ

### Environment

- LibreLane ทำงานได้
- PDK โหลดได้
- version ถูกบันทึก

### RTL และ Synthesis

- Lint ไม่มี fatal error
- Synthesis สำเร็จ
- ไม่มี unmapped cell ที่ไม่ตั้งใจ
- top module ถูกต้อง

### Physical Design

- Floorplan สำเร็จ
- Placement legal
- CTS สำเร็จ
- ไม่มี unrouted net
- Detailed routing สำเร็จ

### Timing

- Setup slack เป็นไปตามโจทย์
- Hold slack ไม่มี violation
- ไม่มี unconstrained path ที่ไม่ตั้งใจ

### Verification

- DRC ผ่านตามเกณฑ์
- LVS match
- Antenna ผ่านหรือมี documented repair

### Reproducibility

- มี `resolved.json`
- มี LibreLane version
- มี run tag แยกการทดลอง
- มี metric comparison
- มี root-cause report อย่างน้อยหนึ่งกรณี

---

## 11.54 แบบฝึกหัดท้าย Lab

### แบบฝึกหัดที่ 1: Controlled Stop

รัน Flow ถึง `OpenROAD.Floorplan` แล้วบันทึก

- core area
- die area
- utilization
- ชื่อ Step directory
- output DEF/ODB

### แบบฝึกหัดที่ 2: Placement Experiment

ทดลอง

```yaml
PL_TARGET_DENSITY_PCT: 35
```

และ

```yaml
PL_TARGET_DENSITY_PCT: 50
```

เปรียบเทียบ

- runtime
- congestion
- wire length
- timing
- routing violations

### แบบฝึกหัดที่ 3: Clock Experiment

ทดลอง clock period

- 25 ns
- 20 ns
- 15 ns
- 10 ns

สร้างตาราง

| Period | Frequency | Pre-PnR WNS | Post-PnR WNS | Cell Area |
|---:|---:|---:|---:|---:|
| 25 ns | 40 MHz |  |  |  |
| 20 ns | 50 MHz |  |  |  |
| 15 ns | 66.67 MHz |  |  |  |
| 10 ns | 100 MHz |  |  |  |

### แบบฝึกหัดที่ 4: Intentional RTL Error

แก้ RTL ชั่วคราวเป็น

```systemverilog
count_o <= count_o + ;
```

รัน Flow และบันทึก

- failed Step
- error message
- log file
- exit code

จากนั้นแก้ RTL และรันใหม่ด้วย run tag ใหม่

### แบบฝึกหัดที่ 5: Incorrect Clock Port

แก้

```yaml
CLOCK_PORT: clock
```

วิเคราะห์ว่า error เกิดใน Step ใด และเหตุใด lint อาจไม่ตรวจพบปัญหานี้

### แบบฝึกหัดที่ 6: Reproducibility

รันจาก

```text
runs/baseline/resolved.json
```

แล้วเปรียบเทียบ metrics กับ baseline

### แบบฝึกหัดที่ 7: Custom Flow

สร้าง Flow ที่มีเพียง

1. Verilator lint
2. Yosys synthesis
3. SDC check
4. Pre-PnR STA
5. Floorplan

บันทึกเวลาเทียบกับ Classic Flow เต็มรูปแบบ

### แบบฝึกหัดที่ 8: Root-Cause Analysis

สร้าง congestion โดยเพิ่ม utilization และ placement density จากนั้นแก้โดยเปลี่ยนตัวแปรครั้งละหนึ่งค่า พร้อมเขียน root-cause report

---

## 11.55 คำถามทบทวน

1. Flow, Step และ State แตกต่างกันอย่างไร
2. เพราะเหตุใดแต่ละ Step จึงมีไดเรกทอรีแยกกัน
3. `config.yaml` ต่างจาก `resolved.json` อย่างไร
4. เหตุใดจึงควรเปลี่ยน configuration ครั้งละหนึ่งกลุ่ม
5. เมื่อเปลี่ยน `FP_CORE_UTIL` ควรเริ่ม Flow ใหม่จากช่วงใด
6. เมื่อเปลี่ยน routing rule deck สามารถ reuse routed DEF ได้หรือไม่
7. Error แรกสำคัญกว่า error สุดท้ายอย่างไร
8. ทำไม setup violation และ hold violation จึงต้องแก้ต่างวิธีกัน
9. ทำไม Flow จบไม่เท่ากับ design พร้อมผลิต
10. เพราะเหตุใด DRC count จาก Magic และ KLayout อาจไม่เท่ากัน
11. ทำไม `dir::` จึงเหมาะกับ portable configuration
12. การปิด checker มีความเสี่ยงอย่างไร
13. เมื่อใดควรใช้ custom flow
14. อะไรคือหลักฐานขั้นต่ำสำหรับ reproducibility
15. ทำไม run tag จึงสำคัญต่อการทดลองทางวิศวกรรม

---

## 11.56 สรุป

การ debug LibreLane ที่มีประสิทธิภาพไม่ใช่การสุ่มเปลี่ยน configuration จน Flow ผ่าน แต่เป็นกระบวนการทางวิศวกรรมที่ประกอบด้วย

1. ระบุ Step ที่ล้มเหลว
2. อ่าน error แรกที่มีความหมาย
3. ตรวจ State จาก Step ก่อนหน้า
4. จำแนกประเภทปัญหา
5. ตั้ง hypothesis
6. เปลี่ยนตัวแปรครั้งละหนึ่งกลุ่ม
7. สร้าง run tag ใหม่
8. เปรียบเทียบ `resolved.json`
9. เปรียบเทียบ metrics
10. บันทึก root cause และ corrective action

การใช้ `config.yaml`, Step directory, report, metrics และ `resolved.json` อย่างเป็นระบบ ทำให้ LibreLane เปลี่ยนจากเครื่องมือที่ทำงานแบบ black box ไปเป็น flow ที่สามารถตรวจสอบ ควบคุม ทำซ้ำ และพัฒนาให้เหมาะกับ design แต่ละประเภทได้
:::

LibreLane รองรับ YAML เป็น configuration input โดยตรง และ custom sequential flow สามารถระบุรายการ Step หรือใช้ `substituting_steps` ภายในส่วน `meta` ได้  ส่วน `resolved.json` ที่สร้างใน run directory สามารถใช้เป็น configuration เพื่อรันซ้ำด้วยค่าที่ resolve แล้วได้ 

เอกสาร timing closure ของ LibreLane แนะนำให้ตรวจรายงาน STA หลายช่วงของ Flow โดยเฉพาะ `STAPrePNR`, `STAMidPNR` และ `STAPostPNR`; report กลุ่ม `max.rpt` ใช้วิเคราะห์ setup path และ `min.rpt` ใช้วิเคราะห์ hold path 
