# คู่มือ Lab 14 — LibreLane Python API Programming
## อธิบายรายละเอียดการทำงานของ Python Scripts ทั้ง 11 ไฟล์
### RTL-to-GDSII Workshop ด้วย IHP SG13G2 PDK

ผมตรวจสอบ Source Code จริงจาก GitHub Repository ของอาจารย์ครบทั้ง 11 ไฟล์แล้ว ประกอบด้วย Python Scripts หมายเลข 01–10 และไฟล์ `common.py` ซึ่งใช้เป็น Shared Library

แหล่งข้อมูล: [chumnarn/rtl-to-gdsii — Lab 14 Python Scripts](https://github.com/chumnarn/rtl-to-gdsii/tree/main/lab14/lab14_librelane_python_api/scripts?utm_source=chatgpt.com)

เนื้อหาต่อไปนี้สามารถใช้ประกอบ **คู่มืออบรม Lab 14 — LibreLane Python API** โดยจะอธิบายหลักการทำงาน โครงสร้างโปรแกรม API ที่ใช้ ลำดับการประมวลผล ผลลัพธ์ และข้อควรระวังในการนำไปประยุกต์ใช้กับ ASIC Physical Design

---

# 1. ภาพรวม LibreLane Python API

## 1.1 การควบคุม LibreLane ด้วย Python

โดยทั่วไป การใช้งาน LibreLane ผ่าน Command Line Interface (CLI) มีรูปแบบดังนี้

```bash
librelane --pdk ihp-sg13g2 config.yaml
```

คำสั่งนี้ให้ LibreLane อ่าน Configuration และดำเนินการตาม Flow ที่กำหนด

สำหรับ Lab 14 เราจะเปลี่ยนวิธีควบคุม LibreLane มาใช้ Python API เช่น

```python
from librelane.flows import Flow

flow_class = Flow.factory.get("Classic")

flow = flow_class(
    "config.yaml",
    pdk="ihp-sg13g2",
    design_dir=".",
)

state = flow.start(
    tag="lab14_demo",
    overwrite=True,
)
```

ข้อดีคือสามารถใช้ Python สร้างระบบ Automation ที่ซับซ้อนกว่าการเรียก CLI เพียงครั้งเดียว เช่น

- เลือกและประกอบ EDA Steps ตามต้องการ
- ตรวจสอบ Configuration ก่อนเริ่ม Flow
- หยุดการทำงานที่ขั้นตอน Synthesis
- อ่าน Metrics หลังแต่ละการทดลอง
- ทดลอง Placement Density หลายค่า
- จัดเก็บผลลัพธ์เป็น JSON หรือ CSV
- สร้าง Custom RTL-to-GDSII Flow

## 1.2 องค์ประกอบหลักของ LibreLane Python API

Lab นี้ใช้แนวคิดหลัก 5 ส่วน

| องค์ประกอบ | API / Object | หน้าที่ |
|---|---|---|
| Flow Factory | `Flow.factory` | ค้นหาและเลือก Flow |
| Step Factory | `Step.factory` | ค้นหา EDA Steps ที่ลงทะเบียน |
| Flow Class | `Classic`, `SequentialFlow` | กำหนดลำดับการประมวลผล |
| Configuration | `flow.config` | เข้าถึงค่าที่ Resolve แล้ว |
| State | `state`, `state.metrics` | เก็บผลลัพธ์และ Metrics |

ความสัมพันธ์ขององค์ประกอบเหล่านี้คือ

```text
                  Python Application
                          |
                          v
                    Flow Factory
                          |
                          v
                     Classic Flow
                          |
                          v
                     Configuration
                          |
                          v
                 Sequential EDA Steps
                          |
             +------------+------------+
             |            |            |
             v            v            v
          Yosys       OpenROAD       Signoff
             |            |            |
             +------------+------------+
                          |
                          v
                       State
                          |
                   +------+------+
                   |             |
                   v             v
                Design         Metrics
                 Views
                   |             |
                   v             v
               Netlist/      JSON/CSV/
               DEF/GDS       Reports
```

ข้อสำคัญคือ **State ของ LibreLane ไม่ได้หมายถึงสถานะ PASS/FAIL เพียงอย่างเดียว** แต่เป็นข้อมูลที่เชื่อมโยง Design Views และ Metrics ระหว่าง EDA Steps

---

# 2. โครงสร้างโครงการ Lab 14

จาก Repository พบโครงสร้างสำคัญดังนี้

```text
lab14_librelane_python_api/
│
├── Makefile
├── config.yaml
├── constraints.sdc
│
├── rtl/
│   └── counter.sv
│
├── tb/
│   └── tb_counter.sv
│
├── scripts/
│   ├── 01_check_environment.py
│   ├── 02_show_flows.py
│   ├── 03_show_steps.py
│   ├── 04_validate_config.py
│   ├── 05_run_classic.py
│   ├── 06_run_to_synthesis.py
│   ├── 07_export_state.py
│   ├── 08_parameter_sweep.py
│   ├── 09_custom_synthesis_flow.py
│   ├── 10_compare_exported_states.py
│   └── common.py
│
├── reports/
│
└── runs/
```

`reports/` และ `runs/` ใช้เก็บผลลัพธ์ที่สร้างระหว่างการทดลอง และอาจยังไม่มีข้อมูลจนกว่าจะรันขั้นตอนที่เกี่ยวข้อง

## 2.1 Configuration ที่ใช้ใน Lab

ไฟล์ `config.yaml` กำหนด:

```yaml
meta:
  version: 3
  flow: Classic

DESIGN_NAME: counter

VERILOG_FILES:
  - dir::rtl/counter.sv

USE_SLANG: true

CLOCK_PORT: clk
CLOCK_PERIOD: 20.0

FP_SIZING: absolute
DIE_AREA: [0, 0, 180, 180]
CORE_AREA: [20, 20, 160, 160]

PL_TARGET_DENSITY_PCT: 35
```

นอกจากนี้ยังมี SDC Files, Power Nets และ GDS Streamout Configuration

จุดที่ควรเข้าใจคือ

**Clock Period = 20 ns**

หมายถึง Design มี Target Clock Frequency เท่ากับ 50 MHz

**Placement Density = 35%**

หมายถึงการตั้งค่า Target Placement Density สำหรับขั้นตอน Placement ไม่ใช่การยืนยันว่า Standard Cells ใช้พื้นที่จริงเท่ากับ 35% ของ Core

**Die Area = 180 × 180 µm²**

เป็นขอบเขต Die ที่กำหนดไว้ใน Configuration

**Core Area = 140 × 140 µm²**

เป็นพื้นที่ภายในพิกัด `[20,20]` ถึง `[160,160]`

ค่าดังกล่าวใช้เป็น Baseline สำหรับการทดลอง Parameter Sweep ใน Script 08

---

# 3. ตารางสรุปหน้าที่ Python Scripts ทั้งหมด

| Script | ชื่อการทดลอง | API สำคัญ | ผลลัพธ์ |
|---|---|---|---|
| 01 | Environment Check | `import librelane`, `shutil.which()` | รายงาน Environment |
| 02 | Flow Discovery | `Flow.factory.list()` | รายชื่อ Flow |
| 03 | Step Discovery | `Step.factory.list()` | รายชื่อและลำดับ Steps |
| 04 | Configuration Validation | `flow.config` | Resolved Configuration |
| 05 | Classic Flow Execution | `flow.start()` | Full RTL-to-GDSII Run |
| 06 | Partial Flow | `flow.start(to=...)` | Synthesis-stage Run |
| 07 | State Export | `state.to_raw_dict()` | JSON และ Metrics |
| 08 | Parameter Sweep | `make_flow([config, overlay])` | CSV เปรียบเทียบการทดลอง |
| 09 | Custom Flow | `SequentialFlow` | Custom Synthesis Flow |
| 10 | State Inspection | `json.load()`, `flatten()` | รายงาน Metrics จาก JSON |
| `common.py` | Shared Utilities | `make_flow()`, `resolve_step_id()` | Infrastructure สำหรับ Scripts |

**ข้อสังเกตจาก Code Review:** Script 08 มีจุดเสี่ยงเรื่อง `pathlib.Path` ในรายการ Configuration Sources ส่วน Script 10 ยังไม่ได้เปรียบเทียบผลระหว่าง Run อย่างแท้จริง แต่เป็นการแสดง Metrics จากไฟล์ State JSON หลายไฟล์

ผมจะอธิบายสองประเด็นนี้โดยละเอียดในหัวข้อที่เกี่ยวข้อง

---

# 4. Script 01 — `01_check_environment.py`

## 4.1 วัตถุประสงค์

ไฟล์นี้ใช้ตรวจสอบความพร้อมของ Development Environment ก่อนเริ่มใช้งาน LibreLane Python API

โดยตรวจสอบทั้ง Python Interpreter, LibreLane Package, Configuration File, PDK Settings และคำสั่ง EDA Tools

คำสั่งเรียกใช้งาน:

```bash
python3 scripts/01_check_environment.py
```

หรือ

```bash
make check
```

## 4.2 การตรวจสอบ LibreLane Package

โค้ดสำคัญ:

```python
try:
    import librelane
except ImportError as exc:
    print(
        "ERROR: Python cannot import the 'librelane' package.",
        file=sys.stderr
    )
    return 1
```

หลักการทำงาน:

Python พยายาม Import Package `librelane`

หาก Import ไม่สำเร็จ จะเข้าสู่ `except ImportError`

ตัวอย่าง Error ที่อาจเกิดขึ้น:

```text
ModuleNotFoundError: No module named 'librelane'
```

ปัญหานี้อาจเกิดจากการใช้ Python Interpreter ที่ไม่ได้ติดตั้ง LibreLane หรือไม่ได้เข้าสู่ Nix Environment ที่ถูกต้อง

คำสั่งตรวจสอบเพิ่มเติม:

```bash
python3 -c "import librelane; print(librelane.__file__)"
```

## 4.3 การอ่านข้อมูล Python Environment

โค้ด:

```python
print(f"Python executable : {sys.executable}")
print(f"Python version    : {sys.version.split()[0]}")
print(f"LibreLane module  : {librelane.__file__}")
```

คำสั่ง `sys.executable` ใช้ระบุตำแหน่ง Python Interpreter ที่กำลังทำงานจริง

ใน Nix Environment อาจได้ Path ลักษณะนี้:

```text
/nix/store/...-python3-3.13.9-env/bin/python3
```

ข้อมูลนี้สำคัญ เพราะเครื่องเดียวกันอาจมี Python หลาย Environment เช่น

```text
/usr/bin/python3
/home/user/.venv/bin/python
/nix/store/.../bin/python3
```

การมีคำสั่ง `python3` ไม่ได้หมายความว่า Interpreter นั้นมี LibreLane Package เสมอไป

## 4.4 ตรวจสอบ EDA Tools

Script ใช้:

```python
shutil.which(command)
```

ตัวอย่าง:

```python
required = ["python3", "librelane"]

optional = [
    "iverilog",
    "vvp",
    "verilator",
    "yosys",
    "openroad",
    "klayout",
]
```

`shutil.which()` ค้นหา Executable จาก `PATH`

หากพบจะคืนตำแหน่งไฟล์ หากไม่พบจะคืน `None`

ตัวอย่างผลลัพธ์:

```text
python3     : /nix/store/.../bin/python3
librelane   : /nix/store/.../bin/librelane
iverilog    : /nix/store/.../bin/iverilog
verilator   : /nix/store/.../bin/verilator
```

ในโค้ดจริง `python3` และ `librelane` เป็น Required Commands ส่วนเครื่องมืออื่นเป็น Optional

ดังนั้น **Script 01 ผ่านไม่ได้หมายความว่า EDA Environment พร้อมสำหรับ Full RTL-to-GDSII Flow ทุกขั้นตอน** เพราะ Script ไม่ได้ทดสอบการเปิด PDK หรือทดลองใช้งานทุกเครื่องมือจริง

## 4.5 Exit Codes

Script กำหนดผลลัพธ์ดังนี้

| Exit Code | ความหมาย |
|---|---|
| `0` | ตรวจสอบรายการ Required ผ่าน |
| `1` | Import LibreLane ไม่สำเร็จ หรือไม่พบ Required Command |
| `2` | ไม่พบ `config.yaml` |

## 4.6 ประโยชน์ในการใช้งานจริง

ไฟล์นี้เหมาะสำหรับใช้เป็น **Preflight Check** ของ ASIC Design Workshop

ก่อนเริ่ม Lab ทุกครั้งสามารถรัน:

```bash
make check
```

เพื่อแยกปัญหา Environment ออกจากปัญหา RTL และ Physical Implementation

---

# 5. Script 02 — `02_show_flows.py`

## 5.1 วัตถุประสงค์

ใช้ค้นหา LibreLane Flows ที่ถูกลงทะเบียนไว้ใน Runtime

ตัวอย่าง Flow ที่อาจพบ ได้แก่ Classic และ Flow เฉพาะงานอื่น ทั้งนี้ขึ้นอยู่กับ LibreLane Version ที่ติดตั้ง

คำสั่ง:

```bash
python3 scripts/02_show_flows.py
```

หรือ:

```bash
make flows
```

## 5.2 Flow Factory

โค้ด:

```python
from librelane.flows import Flow
```

เป็นการ Import Base Flow Class

จากนั้น:

```python
Flow.factory.list()
```

ใช้เรียกดูชื่อ Flow ที่ลงทะเบียน

ตัวอย่าง:

```python
for index, name in enumerate(
    sorted(Flow.factory.list()),
    start=1
):
    ...
```

แยกการทำงานได้ดังนี้

`Flow.factory.list()` คืนรายชื่อ Flow

`sorted()` เรียงชื่อตามลำดับ

`enumerate(..., start=1)` เพิ่มหมายเลขลำดับเริ่มจาก 1

## 5.3 การค้นหา Flow Class

โค้ด:

```python
flow_class = Flow.factory.get(name)
```

ใช้ค้นหา Python Class ที่สอดคล้องกับชื่อ Flow

ตัวอย่าง:

```python
classic_class = Flow.factory.get("Classic")
```

จากนั้น:

```python
print(classic_class)
```

จะได้ Python Class ของ Classic Flow หากมีการลงทะเบียนไว้

## 5.4 แสดงชื่อ Module และ Class

โค้ด:

```python
qualified = (
    f"{flow_class.__module__}.{flow_class.__name__}"
    if flow_class is not None
    else "<unresolved>"
)
```

มีหน้าที่แสดง Fully Qualified Class Name

ตัวอย่างรูปแบบผลลัพธ์:

```text
Registered LibreLane flows
================================================================================
  1. Classic              librelane.flows.classic.Classic
```

รายชื่อจริงขึ้นอยู่กับ Runtime

## 5.5 สิ่งที่ผู้เรียนควรเข้าใจ

แนวคิดสำคัญคือ **Factory Pattern**

Factory ทำหน้าที่ค้นหา Class ที่ตรงกับชื่อที่ร้องขอ โดยไม่จำเป็นต้องเขียน Import ของทุก Flow ด้วยตนเอง

ตัวอย่างเชิงแนวคิด:

```python
flow_name = "Classic"

flow_class = Flow.factory.get(flow_name)

if flow_class is None:
    raise RuntimeError("Flow not found")
```

แนวทางนี้มีประโยชน์สำหรับระบบ EDA Automation ที่ต้องเลือก Flow จาก Configuration หรือ Command Line

---

# 6. Script 03 — `03_show_steps.py`

## 6.1 วัตถุประสงค์

ใช้ตรวจสอบสองเรื่องที่แตกต่างกัน

1. ลำดับ Steps ที่ Classic Flow ใช้จริง
2. Steps ทั้งหมดที่ลงทะเบียนอยู่ใน LibreLane

คำสั่ง:

```bash
python3 scripts/03_show_steps.py
```

หรือ:

```bash
make steps
```

## 6.2 การอ่าน Classic Flow Sequence

โค้ด:

```python
from common import classic_step_ids
```

เรียก Shared Function จาก `common.py`

ภายในฟังก์ชันนี้มีหลักการ:

```python
flow_class = get_flow_class("Classic")

return [
    str(getattr(step, "id", step.__name__))
    for step in flow_class.Steps
]
```

`flow_class.Steps` เป็นลำดับ Step Classes ที่ Classic Flow กำหนดไว้

ตัวอย่าง Steps ที่เกี่ยวข้องกับ ASIC Flow:

```text
Yosys.Synthesis
OpenROAD.Floorplan
OpenROAD.GlobalPlacement
OpenROAD.CTS
OpenROAD.GlobalRouting
OpenROAD.DetailedRouting
OpenROAD.RCX
```

นี่เป็นเพียงตัวอย่างชื่อ Steps ไม่ใช่ลำดับทั้งหมดที่ยืนยันจาก Runtime ของอาจารย์

## 6.3 การค้นหา Registered Steps

Script ใช้:

```python
from librelane.steps import Step
```

และ:

```python
Step.factory.list()
```

เพื่อดึงชื่อของ Step Classes ทั้งหมดที่ลงทะเบียนอยู่

จากนั้นใช้:

```python
Step.factory.get(name)
```

เพื่อค้นหา Step Class

## 6.4 ความแตกต่างที่สำคัญ

**Registered Steps ไม่เท่ากับ Steps ที่ Classic Flow ใช้**

ตัวอย่างเช่น LibreLane อาจมี Step Class สำหรับการตรวจสอบประเภทหนึ่ง แต่ Classic Flow ที่กำลังใช้งานไม่ได้ใส่ Step นั้นไว้ในลำดับการทำงาน

จุดนี้เชื่อมโยงกับปัญหาที่อาจารย์พบใน Lab 11:

```text
Failed to process 'KLayout.Antenna':
no step(s) with ID 'KLayout.Antenna' found in flow.
```

การมี Step อยู่ใน Factory ไม่ได้ยืนยันว่า Classic Flow สามารถใช้ `--skip` กับ Step นั้นได้

## 6.5 การประยุกต์ใช้กับ Debugging

สามารถตรวจสอบว่า Classic Flow มี Step ที่ต้องการหรือไม่:

```bash
python3 scripts/03_show_steps.py |
grep -E 'Yosys.Synthesis|OpenROAD.RCX|Magic.DRC'
```

ใน Makefile ของ Lab 14 ยังเก็บรายการ Steps ลงไฟล์:

```text
reports/steps.txt
```

เพราะ Target `steps` ใช้ `tee`

วิธีนี้เหมาะสำหรับเก็บหลักฐานว่า Lab ใช้ Flow Sequence ของ LibreLane เวอร์ชันใด

---

# 7. Script 04 — `04_validate_config.py`

## 7.1 วัตถุประสงค์

ไฟล์นี้ใช้ตรวจสอบว่า LibreLane สามารถอ่านและ Resolve `config.yaml` เป็น Configuration Object ได้หรือไม่ โดยยังไม่เริ่มกระบวนการ RTL-to-GDSII

คำสั่ง:

```bash
python3 scripts/04_validate_config.py
```

หรือ:

```bash
make validate
```

## 7.2 การสร้าง Flow Object

โค้ดหลัก:

```python
from common import DEFAULT_PDK, make_flow

def main() -> None:
    flow = make_flow()
```

`make_flow()` เป็น Shared Function ซึ่งสร้าง Classic Flow Object พร้อมโหลด Configuration

ลำดับการทำงาน:

```text
04_validate_config.py
         |
         v
     make_flow()
         |
         v
   ensure_project_layout()
         |
         v
   get_flow_class("Classic")
         |
         v
   Classic(config.yaml)
         |
         v
   Config.load()
         |
         v
   Resolved Configuration
```

เมื่อทำงานสำเร็จ Script จะสามารถอ่านค่าจาก:

```python
flow.config
```

## 7.3 การเข้าถึง Configuration

ตัวอย่าง:

```python
print(flow.config["DESIGN_NAME"])
```

ได้ค่า:

```text
counter
```

การอ่าน Clock Period:

```python
print(flow.config["CLOCK_PERIOD"])
```

ได้ค่าที่คาดหวังจาก Configuration:

```text
20.0
```

การอ่าน Placement Density:

```python
print(flow.config["PL_TARGET_DENSITY_PCT"])
```

ได้:

```text
35
```

## 7.4 การแก้ปัญหา `PathLike AssertionError`

ก่อนหน้านี้อาจารย์พบ:

```text
AssertionError

assert not isinstance(config_in, os.PathLike)
```

สาเหตุเกิดจาก `make_flow()` ส่ง `pathlib.Path` ให้ LibreLane ในตำแหน่งที่ต้องการ Configuration Source ประเภทที่รองรับ

ใน GitHub เวอร์ชันที่ตรวจสอบล่าสุด พบว่า `common.py` แก้ไขกรณี Default Configuration แล้ว:

```python
sources = str(CONFIG_FILE) if config_sources is None else config_sources
```

จึงสามารถหลีกเลี่ยงปัญหาเดิมเมื่อเรียก:

```python
flow = make_flow()
```

อย่างไรก็ตาม ต้องระวังกรณี Script อื่นส่งรายการ Configuration ที่มี `Path` อยู่ภายใน ซึ่งจะกล่าวถึงใน Script 08

## 7.5 Configuration Validation ตรวจสอบอะไรบ้าง?

จากพฤติกรรมของ Script นี้ สามารถแบ่งการตรวจสอบเป็นสองกลุ่ม

**สิ่งที่ตรวจสอบได้**

- Python สามารถสร้าง Flow Object ได้
- LibreLane สามารถอ่าน Configuration Source
- การ Resolve Configuration และ PDK ผ่านตามเงื่อนไขของ API
- สามารถอ่านค่าที่ Script ต้องการจาก `flow.config`

**สิ่งที่ยังไม่ได้พิสูจน์**

- RTL Compile ผ่าน
- Synthesis ผ่าน
- SDC ใช้งานกับ OpenSTA ได้ครบทุกคำสั่ง
- Floorplan และ PDN ถูกต้อง
- Routing ผ่าน
- DRC/LVS ผ่าน
- Timing Closure สำเร็จ

ตัวอย่างที่ชัดเจนคือปัญหา `remove_from_collection` ใน `constraints.sdc` ที่อาจารย์พบก่อนหน้านี้ Configuration อาจโหลดได้ แต่เมื่อ OpenSTA ประมวลผล SDC ในขั้นตอน STA จึงเกิด Error

ดังนั้น **Configuration Validation ไม่เท่ากับ Functional หรือ Physical Verification**

---

# 8. Script 05 — `05_run_classic.py`

## 8.1 วัตถุประสงค์

Script นี้ใช้ควบคุม **Full Classic RTL-to-GDSII Flow** ด้วย Python API

เป็น Script หลักที่แสดงวิธีแทนการเรียก LibreLane CLI ด้วย Python

คำสั่ง:

```bash
python3 scripts/05_run_classic.py
```

หรือ:

```bash
make run
```

สามารถกำหนด Run Tag ได้:

```bash
python3 scripts/05_run_classic.py --tag experiment01
```

หรือผ่าน Makefile:

```bash
make run TAG=experiment01
```

## 8.2 การใช้ `argparse`

โค้ด:

```python
def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run LibreLane Classic Flow."
    )

    parser.add_argument(
        "--tag",
        default="lab14_ihp_full"
    )

    parser.add_argument(
        "--no-overwrite",
        action="store_true"
    )

    return parser.parse_args()
```

`argparse` เป็น Python Standard Library สำหรับอ่าน Command Line Arguments

ใน Script นี้มี Arguments สองรายการ

| Argument | หน้าที่ |
|---|---|
| `--tag` | กำหนดชื่อ Run |
| `--no-overwrite` | ไม่อนุญาตให้เขียนทับ Run Directory เดิม |

## 8.3 การเริ่ม Classic Flow

โค้ดหลัก:

```python
flow = make_flow()
```

และ:

```python
final_state = flow.start(
    tag=args.tag,
    overwrite=not args.no_overwrite,
)
```

เมธอด `flow.start()` เริ่มประมวลผล Steps ตามลำดับที่กำหนดใน Classic Flow

สำหรับ Full Flow จะครอบคลุมกระบวนการสำคัญ เช่น

```text
RTL
 |
 v
Elaboration
 |
 v
Synthesis
 |
 v
Static Timing Analysis
 |
 v
Floorplanning
 |
 v
Power Distribution Network
 |
 v
Placement
 |
 v
Clock Tree Synthesis
 |
 v
Global Routing
 |
 v
Detailed Routing
 |
 v
Parasitics Extraction
 |
 v
Signoff Checks
 |
 v
Final Design Views + Metrics
```

ลำดับจริงและ Steps ที่เปิดใช้งานขึ้นอยู่กับ LibreLane Version และ Configuration ของ Design

## 8.4 ความหมายของ `overwrite`

จากโค้ด:

```python
overwrite=not args.no_overwrite
```

ถ้าไม่ได้ระบุ `--no-overwrite`:

```python
args.no_overwrite == False
```

ดังนั้น:

```python
overwrite=True
```

หมายความว่า Script อนุญาตให้เขียนทับ Run Directory ของ Tag เดิมตามพฤติกรรมของ LibreLane

**ข้อควรระวัง:** Default ของ Script 05 จึงไม่เหมาะกับการเก็บผลการทดลองหลายครั้งภายใต้ Tag เดียวกัน

สำหรับการฝึกอบรม ควรตั้งชื่อ Run แยกกัน เช่น:

```bash
make run TAG=baseline
make run TAG=clock_15ns
make run TAG=density_40
```

ถ้าต้องการเก็บ Run เดิม ให้ใช้:

```bash
python3 scripts/05_run_classic.py \
    --tag baseline \
    --no-overwrite
```

## 8.5 การอ่านผลลัพธ์หลัง Flow

เมื่อ Flow สำเร็จ Script จะแสดง:

```python
print(f"Run directory   : {flow.run_dir}")
print(f"Resolved config : {flow.config_resolved_path}")
print(f"Executed steps  : {len(flow.step_objects)}")
print(f"Metric count    : {len(final_state.metrics)}")
```

ตัวแปรแต่ละตัวมีความหมายดังนี้

**`flow.run_dir`**

ตำแหน่ง Directory ที่ LibreLane ใช้เก็บผลการรัน

**`flow.config_resolved_path`**

ตำแหน่ง Configuration หลังผ่านกระบวนการ Resolve

**`flow.step_objects`**

รายการ Step Objects ที่ Flow สร้างขึ้นระหว่างการทำงาน

**`final_state.metrics`**

Metrics ที่สะสมอยู่ใน Final State

ตัวอย่าง Metrics ที่อาจมี ได้แก่ Cell Area, Setup WNS, Setup TNS และ DRC Violations

ชื่อ Metric และจำนวน Metrics จริงขึ้นอยู่กับ LibreLane Version และ Steps ที่ทำงาน

## 8.6 การจัดการ Error

Script มี Exception Handling สองระดับ:

```python
except FlowError as exc:
    print(f"LibreLane flow failed: {exc}", file=sys.stderr)
    return 2
```

ใช้จัดการ Error ที่ LibreLane รายงานเป็น `FlowError`

และ:

```python
except Exception as exc:
    print(f"Unexpected error: {exc}", file=sys.stderr)
    traceback.print_exc()
    return 3
```

ใช้จัดการ Error อื่น ๆ

จึงกำหนด Exit Codes ได้ดังนี้

| Exit Code | ความหมาย |
|---|---|
| `0` | Flow เสร็จสมบูรณ์ |
| `2` | LibreLane FlowError |
| `3` | Unexpected Exception |

## 8.7 ความสำคัญสำหรับ ASIC Automation

Script 05 สามารถนำไปต่อยอดเป็นระบบอัตโนมัติ เช่น

```text
Python
  |
  +--> Read experiment configuration
  |
  +--> Create LibreLane Flow
  |
  +--> Run RTL-to-GDSII
  |
  +--> Collect metrics
  |
  +--> Check design constraints
  |
  +--> Generate reports
```

ตัวอย่างการตรวจเกณฑ์ Timing หลัง Flow ผ่าน:

```python
metrics = final_state.metrics

print("Available metrics:")
for name, value in sorted(metrics.items()):
    print(name, value)
```

การตรวจชื่อ Metrics ก่อนใช้งานมีความสำคัญ เพราะชื่ออาจแตกต่างกันระหว่าง Release

---

# 9. Script 06 — `06_run_to_synthesis.py`

## 9.1 วัตถุประสงค์

Script นี้สาธิตการควบคุม **Partial Flow Execution** โดยให้ LibreLane ทำงานตั้งแต่ต้นจนถึง Yosys Synthesis

คำสั่ง:

```bash
python3 scripts/06_run_to_synthesis.py
```

หรือ:

```bash
make synth
```

## 9.2 การค้นหา Target Step

โค้ด:

```python
target = resolve_step_id(
    "Yosys.Synthesis",
    contains=("yosys", "synthesis"),
)
```

`resolve_step_id()` เป็น Shared Function ที่ใช้ค้นหา Step ID จาก Classic Flow

หลักการคือ

1. ตรวจสอบว่ามี Step ID `Yosys.Synthesis` หรือไม่
2. หากไม่มี จะค้นหา Step ID ที่มีคำว่า `yosys` และ `synthesis`
3. หากพบเพียงหนึ่งรายการ จะเลือก Step นั้น
4. หากพบหลายรายการหรือไม่พบเลย จะเกิด Error

แนวทางนี้ช่วยลดปัญหาจากการกำหนด Step Name แบบตายตัว เมื่อชื่อ Step แตกต่างกันระหว่าง LibreLane Releases

## 9.3 การใช้ `flow.start(to=...)`

โค้ด:

```python
flow = make_flow()

state = flow.start(
    tag="lab14_ihp_synthesis",
    to=target,
    overwrite=True,
)
```

Parameter ที่สำคัญคือ:

```python
to=target
```

เป็นการกำหนด Stop Point ของ Flow

ตัวอย่าง:

```text
Start
  |
  v
RTL Preparation
  |
  v
Elaboration
  |
  v
Synthesis
  |
  v
STOP
```

Script จะไม่ดำเนินการไปจนถึง Placement, CTS หรือ Routing

## 9.4 ข้อแตกต่างระหว่าง Synthesis และ Full Flow

| รายการ | Synthesis-only | Full Flow |
|---|---|---|
| RTL Elaboration | มี |
| Synthesis | มี |
| Technology Mapping | มีตาม Flow |
| Placement | ไม่มี |
| CTS | ไม่มี |
| Global Routing | ไม่มี |
| Detailed Routing | ไม่มี |
| Final GDS | ไม่มี |

หมายเหตุ: รายละเอียดของขั้นตอนก่อน Synthesis ขึ้นอยู่กับลำดับ Steps ของ Classic Flow ที่ใช้งานจริง

## 9.5 ประโยชน์สำหรับการออกแบบ ASIC

Synthesis-only Flow เหมาะสำหรับตรวจสอบ RTL อย่างรวดเร็วก่อนเข้าสู่ Physical Design

ตัวอย่างการใช้งาน ได้แก่ การเปรียบเทียบ Area หลังเปลี่ยน RTL, การประเมินผลของ Synthesis Constraints และการตรวจว่า RTL มี Unmapped Cells หรือไม่

อย่างไรก็ตาม Script นี้หยุดที่ Synthesis Step จึงไม่รับประกันว่าการตรวจ Post-synthesis ทุกอย่าง เช่น Checker Steps ที่อยู่หลัง Synthesis จะทำงานครบ

หากต้องการรวม Checks เหล่านั้น ต้องเลือก Stop Point ให้เหมาะสม

---

# 10. Script 07 — `07_export_state.py`

## 10.1 วัตถุประสงค์

Script นี้ใช้สาธิตการเข้าถึง LibreLane State และส่งออกผลลัพธ์เป็นไฟล์สำหรับนำไปวิเคราะห์ภายนอก

ผลลัพธ์หลักคือ

```text
reports/final_state.json
reports/metrics.txt
```

คำสั่ง:

```bash
python3 scripts/07_export_state.py
```

หรือ:

```bash
make state
```

## 10.2 การรัน Flow

โค้ด:

```python
flow = make_flow()

state = flow.start(
    tag="lab14_ihp_state",
    overwrite=True,
)
```

**จุดสำคัญ:** Script 07 ไม่ได้โหลด Final State จาก Run ที่เคยสร้างไว้ แต่เริ่ม Classic Flow ใหม่

ดังนั้น `make state` ไม่ใช่เพียงการ Export Report จาก `make run` ที่ผ่านมา

หาก Full Flow ใช้เวลาหรือทรัพยากรสูง ต้องคำนึงถึงพฤติกรรมนี้

## 10.3 การแปลง State เป็น Dictionary

โค้ด:

```python
raw = state.to_raw_dict(metrics=True)
```

ฟังก์ชันนี้ใช้แปลง State เป็นโครงสร้างข้อมูลที่สามารถนำไป Serialize ได้

Parameter:

```python
metrics=True
```

กำหนดให้รวม Metrics ไว้ในข้อมูลที่ส่งออก

ตัวอย่างโครงสร้างเชิงแนวคิด:

```json
{
  "metrics": {
    "example__setup_wns": 0.0,
    "example__design_area": 100.0
  }
}
```

ตัวอย่างนี้ใช้แสดงรูปแบบ JSON เท่านั้น ไม่ใช่ชื่อ Metrics หรือผลจริงของ LibreLane Run

## 10.4 การสร้าง JSON File

โค้ด:

```python
with output.open("w", encoding="utf-8") as stream:
    json.dump(
        raw,
        stream,
        indent=2,
        default=json_default
    )
```

`json.dump()` ใช้บันทึก Python Object เป็น JSON

`indent=2` ทำให้ข้อมูลอ่านง่าย

`default=json_default` ใช้จัดการ Objects ที่ JSON Serializer ไม่รองรับโดยตรง

โดยใน Script กำหนด:

```python
def json_default(value: Any) -> str:
    return str(value)
```

จึงแปลง Object ที่ Serialize ไม่ได้ให้เป็น String

ข้อควรระวังคือการแปลงเป็น String อาจทำให้สูญเสียข้อมูลชนิดเดิม จึงไม่ควรสมมติว่า JSON ที่ส่งออกสามารถนำกลับมาสร้าง LibreLane State ได้อย่างสมบูรณ์ทุกกรณี

## 10.5 การสร้าง Metrics Text Report

โค้ด:

```python
with metrics_output.open(
    "w",
    encoding="utf-8"
) as stream:

    for name in sorted(state.metrics):
        stream.write(
            f"{name} = {state.metrics[name]}\n"
        )
```

ใช้สร้างรายงานในรูปแบบ:

```text
metric_name_1 = value_1
metric_name_2 = value_2
metric_name_3 = value_3
```

ประโยชน์คือสามารถใช้เครื่องมือ Linux เช่น `grep`, `awk` และ Python อ่านผลได้ง่าย

ตัวอย่าง:

```bash
grep -Ei 'wns|tns|area|drc' reports/metrics.txt
```

## 10.6 การประยุกต์ใช้

Script 07 เป็นพื้นฐานสำหรับสร้างระบบ EDA Metrics Database

ตัวอย่างการนำไปต่อยอด:

```text
LibreLane State
       |
       v
   Export JSON
       |
       v
 Python Parser
       |
       v
 DataFrame / CSV
       |
       v
 Dashboard / Report
```

สามารถใช้กับการสอนเรื่อง Timing Closure, Area Optimization และการเปรียบเทียบผล Physical Implementation ได้

---

# 11. Script 08 — `08_parameter_sweep.py`

## 11.1 วัตถุประสงค์

Script 08 เป็นหนึ่งในตัวอย่างสำคัญที่สุดของ Lab นี้ เพราะแสดงการใช้ Python API ทำ **Design Space Exploration (DSE)**

ในโครงการกำหนดให้ทดลอง Placement Density จำนวน 3 ค่า ได้แก่ 30%, 35% และ 40%

คำสั่ง:

```bash
python3 scripts/08_parameter_sweep.py
```

หรือ:

```bash
make sweep
```

## 11.2 หลักการ Parameter Sweep

ในการออกแบบ ASIC ค่าของ Physical Design Configuration อาจส่งผลต่อหลาย Metrics เช่น

- Cell Placement และ Congestion
- Wirelength
- Timing
- Buffer Insertion
- Routing Difficulty
- DRC Violations

ดังนั้นการใช้ Configuration เพียงค่าเดียวอาจไม่เพียงพอต่อการเลือก Physical Implementation ที่เหมาะสม

Parameter Sweep คือการรัน Flow หลายครั้ง โดยเปลี่ยนค่าตัวแปรที่ต้องการศึกษา และคงเงื่อนไขอื่นให้เหมือนกันมากที่สุด

สำหรับ Lab 14:

```text
                    Baseline Configuration
                              |
              +---------------+---------------+
              |               |               |
              v               v               v
        Density 30%      Density 35%      Density 40%
              |               |               |
              v               v               v
         LibreLane       LibreLane       LibreLane
              |               |               |
              v               v               v
          Metrics A       Metrics B       Metrics C
              |               |               |
              +---------------+---------------+
                              |
                              v
                     parameter_sweep.csv
```

## 11.3 การกำหนด Experiments

โค้ด:

```python
EXPERIMENTS = [
    ("density_30", 30),
    ("density_35", 35),
    ("density_40", 40),
]
```

เป็นรายการ Tuple โดยแต่ละรายการประกอบด้วย

```python
(experiment_name, density_value)
```

ตัวอย่าง:

```python
("density_35", 35)
```

หมายถึงทดลองค่า:

```yaml
PL_TARGET_DENSITY_PCT: 35
```

## 11.4 การสร้าง Configuration Overlay

โค้ด:

```python
for name, density in EXPERIMENTS:

    overlay = {
        "PL_TARGET_DENSITY_PCT": density
    }

    flow = make_flow([CONFIG_FILE, overlay])
```

แนวคิดสำคัญคือ **Configuration Overlay**

แทนที่จะสร้าง YAML Configuration แยกกันสามไฟล์ Script ใช้ Base Configuration ร่วมกับ Dictionary ที่เปลี่ยนเฉพาะค่าที่ต้องการทดลอง

ตัวอย่าง:

```python
overlay = {
    "PL_TARGET_DENSITY_PCT": 30
}
```

ทำให้ Flow สามารถใช้ Baseline Configuration พร้อมปรับค่า Density เป็น 30%

### จุดที่ต้องแก้ไขใน Source Code

จากการตรวจสอบ GitHub พบว่า:

```python
CONFIG_FILE = PROJECT_ROOT / "config.yaml"
```

ใน `common.py` มีชนิดข้อมูลเป็น `pathlib.Path`

แต่ Script 08 ส่ง:

```python
make_flow([CONFIG_FILE, overlay])
```

และ `make_flow()` เวอร์ชันปัจจุบันแปลง `CONFIG_FILE` เป็น String เฉพาะกรณีไม่ได้ส่ง `config_sources` เท่านั้น

ดังนั้น Script 08 มีความเสี่ยงที่จะเกิด `PathLike AssertionError` คล้ายกับปัญหาที่อาจารย์เคยพบใน Script 04

**แนะนำให้แก้ไขเป็น:**

```python
flow = make_flow([str(CONFIG_FILE), overlay])
```

หรือปรับ `make_flow()` ให้รองรับ `Path` ภายใน List ตามที่อธิบายในหัวข้อ `common.py`

## 11.5 การรันแต่ละ Experiment

โค้ด:

```python
state = flow.start(
    tag=f"lab14_ihp_{name}",
    overwrite=True,
)
```

ตัวอย่าง Run Tags:

```text
lab14_ihp_density_30
lab14_ihp_density_35
lab14_ihp_density_40
```

การกำหนด Tag แตกต่างกันช่วยป้องกันไม่ให้ผลการทดลองแต่ละค่าทับกัน

อย่างไรก็ตาม การรันซ้ำด้วย Tag เดิมยังสามารถเขียนทับผลเดิมได้ เพราะกำหนด `overwrite=True`

## 11.6 การอ่าน Metrics

โค้ด:

```python
metrics = state.metrics
```

จากนั้น:

```python
find_metric(metrics, "design", "area")
find_metric(metrics, "setup", "wns")
find_metric(metrics, "setup", "tns")
find_metric(metrics, "drc")
```

ฟังก์ชัน `find_metric()` มาจาก `common.py`

มีหน้าที่ค้นหา Metric Name ที่ประกอบด้วย Keywords ที่กำหนด

ตัวอย่างเช่น:

```python
find_metric(metrics, "setup", "wns")
```

จะค้นหา Metric Keys ที่มีคำว่า `setup` และ `wns`

### ข้อควรระวัง

โค้ดปัจจุบันไม่ได้ระบุ Timing Corner อย่างชัดเจน

หาก Metrics มีค่า Setup WNS หลาย Corner ฟังก์ชันจะคืนค่ารายการแรกที่ตรง Keywords ตามลำดับการวนอ่าน Dictionary

จึงไม่ควรตีความว่าเป็น Worst-case Setup WNS โดยอัตโนมัติ

สำหรับงาน STA ที่ต้องการความถูกต้อง ควรระบุ Corner และชนิด Metric ให้ชัดเจน

## 11.7 การจัดเก็บผลการทดลอง

Script สร้าง Dictionary สำหรับแต่ละ Experiment:

```python
rows.append(
    {
        "experiment": name,
        "density_pct": density,
        "status": "PASS",
        "design_area": find_metric(metrics, "design", "area"),
        "setup_wns": find_metric(metrics, "setup", "wns"),
        "setup_tns": find_metric(metrics, "setup", "tns"),
        "drc": find_metric(metrics, "drc"),
        "run_dir": str(flow.run_dir),
        "error": "",
    }
)
```

จากนั้นใช้:

```python
csv.DictWriter()
```

สร้างไฟล์:

```text
reports/parameter_sweep.csv
```

ตัวอย่างรูปแบบข้อมูล:

```csv
experiment,density_pct,status,design_area,setup_wns,setup_tns,drc,run_dir,error
density_30,30,PASS,...
density_35,35,PASS,...
density_40,40,PASS,...
```

ข้อมูลนี้เป็นตัวอย่างโครงสร้าง ไม่ใช่ผลการวัดจากการรันจริง

## 11.8 การจัดการ Experiment Failure

Script มี:

```python
except Exception as exc:
```

หาก Experiment ใดล้มเหลว จะบันทึก:

```python
"status": "FAIL"
```

พร้อมข้อความ Error

ข้อดีคือ Script สามารถดำเนินการ Experiment ถัดไปได้ โดยไม่หยุดทั้งหมดเพียงเพราะ Run หนึ่งล้มเหลว

อย่างไรก็ตาม มีข้อจำกัดสองประการที่ควรแก้ไข

**ข้อแรก:** `make_flow()` ถูกเรียกก่อนเข้า `try`

```python
flow = make_flow([CONFIG_FILE, overlay])

try:
    state = flow.start(...)
```

ถ้า `make_flow()` ล้มเหลว Script จะหยุดโดยไม่บันทึก Failure Row ลง CSV

**ข้อที่สอง:** Script ไม่ตรวจสอบว่าค่า Metric ที่ต้องการมีอยู่ครบหรือไม่

ดังนั้น `status="PASS"` หมายถึง Flow ทำงานจบโดยไม่เกิด Exception ไม่ได้ยืนยันว่า Timing Closure ผ่านหรือ DRC เท่ากับศูนย์

## 11.9 แนวทางปรับปรุงสำหรับ Design Space Exploration

สำหรับการอบรมขั้นสูง แนะนำให้เพิ่ม Metrics ดังต่อไปนี้

| Metric | ความหมาย |
|---|---|
| Cell Area | พื้นที่ Standard Cells |
| Setup WNS | Worst Negative Slack |
| Setup TNS | Total Negative Slack |
| Hold WNS | Worst Hold Slack |
| Wirelength | ความยาวสายรวม |
| Routing DRC | Routing Violations |
| Signoff DRC | Physical DRC |
| Power | ค่าประมาณ Power Consumption |

จากนั้นอาจสร้าง Objective Function เช่น:

```python
def timing_pass(wns):
    return wns is not None and wns >= 0
```

สำหรับเลือก Experiment ที่ผ่านข้อกำหนดด้าน Timing ก่อนนำมาเปรียบเทียบ Area

**ข้อสำคัญ:** ไม่ควรเลือก Density ที่ให้ Area ต่ำที่สุดโดยไม่ตรวจสอบ Timing, Congestion, Routing และ DRC ร่วมกัน

---

# 12. Script 09 — `09_custom_synthesis_flow.py`

## 12.1 วัตถุประสงค์

ใช้สาธิตการสร้าง **Custom LibreLane Flow** ผ่าน `SequentialFlow`

ต่างจาก Script 06 ซึ่งใช้ Classic Flow แล้วกำหนด Stop Point โดย Script 09 สร้าง Flow Class ใหม่ขึ้นมาเอง

คำสั่ง:

```bash
python3 scripts/09_custom_synthesis_flow.py
```

หรือ:

```bash
make custom
```

## 12.2 การ Import `SequentialFlow`

โค้ด:

```python
from librelane.flows import SequentialFlow
```

`SequentialFlow` ใช้สำหรับสร้าง Flow ที่มีลำดับ EDA Steps ตามที่กำหนด

แนวคิดคือ:

```text
Custom Flow
     |
     v
 Step 1
     |
     v
 Step 2
     |
     v
 Step 3
     |
     v
  Final State
```

ผู้พัฒนาสามารถกำหนดรายการ Steps เองได้

## 12.3 การใช้ Classic Flow เป็น Template

โค้ด:

```python
classic = get_flow_class("Classic")
```

อ่าน Classic Flow Class

จากนั้นค้นหา Target Step:

```python
target = resolve_step_id(
    "Yosys.Synthesis",
    contains=("yosys", "synthesis"),
)
```

ต่อมา:

```python
selected_steps = []

for step_class in classic.Steps:
    selected_steps.append(step_class)

    identifier = str(
        getattr(step_class, "id", step_class.__name__)
    )

    if identifier == target:
        break
```

หลักการทำงานคือคัดลอก Steps จาก Classic Flow ตั้งแต่ต้นจนถึง `Yosys.Synthesis`

วิธีนี้มีข้อดีกว่าการเลือกเฉพาะ `Yosys.Synthesis` มาใส่ใน Flow เพราะ Synthesis อาจต้องใช้ข้อมูลและผลลัพธ์จาก Prerequisite Steps

## 12.4 การสร้าง Flow Class ใหม่

โค้ด:

```python
class Lab14SynthesisFlow(SequentialFlow):
    name = "Lab14SynthesisFlow"
    Steps = selected_steps
```

เป็นการใช้ Python Class Inheritance

โดยสร้าง Class ใหม่ที่สืบทอดจาก `SequentialFlow`

กำหนด:

```python
name = "Lab14SynthesisFlow"
```

เป็นชื่อของ Flow

และ:

```python
Steps = selected_steps
```

เป็นรายการ Steps ที่ Custom Flow จะใช้

## 12.5 การสร้าง Instance

โค้ด:

```python
flow = Lab14SynthesisFlow(
    "config.yaml",
    pdk="ihp-sg13g2",
    design_dir=".",
)
```

ใช้สร้าง Custom Flow Object

จุดที่ต้องระวังคือ `"config.yaml"` และ `"."` เป็น Relative Paths

ดังนั้น Script นี้เหมาะกับการรันจาก Root Directory ของ Lab 14 ตาม Makefile

หากเรียกจาก Directory อื่น อาจไม่พบ Configuration File

แนวทางปรับปรุง:

```python
from common import CONFIG_FILE, PROJECT_ROOT

flow = Lab14SynthesisFlow(
    str(CONFIG_FILE),
    pdk="ihp-sg13g2",
    design_dir=str(PROJECT_ROOT),
)
```

## 12.6 การรัน Custom Flow

โค้ด:

```python
state = flow.start(
    tag="lab14_ihp_custom_synthesis",
    overwrite=True,
)
```

ผลที่ได้คือ Run ของ Custom Flow ที่มี Steps ถึง Synthesis ตามรายการที่เลือก

## 12.7 เปรียบเทียบ Script 06 กับ Script 09

| ประเด็น | Script 06 | Script 09 |
|---|---|---|
| Flow Class | Classic | Custom SequentialFlow |
| การกำหนด Steps | ใช้ Classic ทั้งชุด | เลือกบาง Steps |
| Stop Point | `to=target` | สิ้นสุดตาม `Steps` |
| สร้าง Flow Class ใหม่ | ไม่ | ใช่ |
| เหมาะสำหรับ | Partial Flow | Custom Flow Development |
| ความซับซ้อน | ต่ำกว่า | สูงกว่า |

## 12.8 การประยุกต์ใช้ใน ASIC Design

Custom Flow เหมาะสำหรับการพัฒนาระบบ EDA Research เช่น

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
Custom Netlist Checker
 |
 v
Custom Metrics Extraction
 |
 v
Research Report
```

แต่ต้องระวังว่าเมื่อสร้าง Custom Flow แล้ว ผู้พัฒนาต้องรับผิดชอบเรื่อง Dependency และลำดับ Steps เอง

สำหรับ Lab 14 โค้ดเลือกใช้ Steps จาก Classic Flow จึงช่วยลดความเสี่ยงจากการละเลย Prerequisite Steps

---

# 13. Script 10 — `10_compare_exported_states.py`

## 13.1 วัตถุประสงค์

Script นี้ใช้ค้นหา State JSON Files ใน `reports/` แล้วดึงข้อมูลที่เกี่ยวข้องกับ Timing, Area, DRC และ LVS ออกมาแสดง

คำสั่ง:

```bash
python3 scripts/10_compare_exported_states.py
```

หรือ:

```bash
make compare
```

## 13.2 การค้นหา JSON Files

โค้ด:

```python
state_files = sorted(
    REPORTS_DIR.glob("*state*.json")
)
```

ใช้ค้นหาไฟล์ที่ชื่อประกอบด้วยคำว่า `state`

ตัวอย่าง:

```text
final_state.json
baseline_state.json
density_30_state.json
density_40_state.json
```

หากไม่มีไฟล์:

```python
if not state_files:
    raise SystemExit(
        "No exported state JSON found. Run 'make state' first."
    )
```

Script จะหยุดและแสดงข้อความให้รัน `make state` ก่อน

## 13.3 การอ่าน JSON

โค้ด:

```python
with path.open(
    "r",
    encoding="utf-8"
) as stream:

    data = json.load(stream)
```

ใช้แปลง JSON File เป็น Python Data Structure

โดยทั่วไป JSON Object จะถูกอ่านเป็น Dictionary

## 13.4 การทำ Flatten Dictionary

โค้ด:

```python
def flatten(
    prefix: str,
    value: Any,
    output: dict[str, Any]
) -> None:

    if isinstance(value, dict):

        for key, child in value.items():

            child_prefix = (
                f"{prefix}.{key}"
                if prefix
                else str(key)
            )

            flatten(
                child_prefix,
                child,
                output
            )

    else:
        output[prefix] = value
```

ฟังก์ชันนี้ใช้ Recursive Programming เพื่อแปลง Nested Dictionary เป็น Dictionary แบบแบน

ตัวอย่างข้อมูลก่อน Flatten:

```json
{
  "metrics": {
    "timing": {
      "setup_wns": -0.12,
      "setup_tns": -1.50
    },
    "physical": {
      "area": 2000
    }
  }
}
```

หลัง Flatten:

```text
metrics.timing.setup_wns = -0.12
metrics.timing.setup_tns = -1.50
metrics.physical.area = 2000
```

ตัวเลขนี้เป็นตัวอย่างสำหรับอธิบาย Algorithm เท่านั้น

## 13.5 การเลือก Metrics

โค้ด:

```python
if any(
    token in lowered
    for token in (
        "wns",
        "tns",
        "area",
        "drc",
        "lvs"
    )
):
    print(f"{key} = {value}")
```

Script ตรวจสอบว่าชื่อ Key มี Keyword ที่ต้องการหรือไม่

หากพบจะพิมพ์ Key และ Value

ตัวอย่างผลลัพธ์:

```text
baseline_state.json
================================================================================
metrics.setup_wns = ...
metrics.setup_tns = ...
metrics.design_area = ...
```

## 13.6 ข้อจำกัดของ Script ปัจจุบัน

แม้ไฟล์ชื่อ `10_compare_exported_states.py` แต่จาก Source Code จริง **Script ยังไม่ได้คำนวณความแตกต่างระหว่างสอง Run**

สิ่งที่ Script ทำคือ:

1. ค้นหา JSON Files
2. อ่านข้อมูล
3. Flatten Nested Dictionary
4. แสดง Metrics ที่ตรง Keywords

ยังไม่มีการคำนวณ:

```text
Delta Area
Delta WNS
Delta TNS
Delta DRC
```

และยังไม่มีการระบุว่า Run ใดดีกว่า Run ใด

นอกจากนี้ ฟังก์ชัน `flatten()` ไม่ Flatten โครงสร้าง List ภายใน JSON จึงอาจไม่แสดงข้อมูลบางรายการที่ถูกจัดเก็บอยู่ใน List

## 13.7 ตัวอย่างการเพิ่ม Delta Comparison

สามารถเพิ่มฟังก์ชัน:

```python
def calculate_delta(
    baseline: float,
    experiment: float
) -> float:

    return experiment - baseline
```

ตัวอย่าง:

```python
baseline_wns = -0.20
experiment_wns = 0.05

delta_wns = calculate_delta(
    baseline_wns,
    experiment_wns
)

print(f"Delta WNS = {delta_wns:+.3f} ns")
```

ผล:

```text
Delta WNS = +0.250 ns
```

กรณีนี้ WNS เพิ่มขึ้น 0.250 ns ซึ่งโดยทั่วไปถือว่าดีขึ้นเมื่อเปรียบเทียบภายใต้ Constraints และ Corner เดียวกัน

สำหรับการเปรียบเทียบจริง ควรตรวจสอบให้แน่ใจว่าเป็น Metric เดียวกันและใช้ Timing Corner เดียวกัน

---

# 14. `common.py` — Shared Utilities สำหรับ LibreLane Python API

ไฟล์ `common.py` เป็นองค์ประกอบสำคัญของ Lab 14 เพราะใช้รวบรวมฟังก์ชันที่ Python Scripts อื่นเรียกใช้ร่วมกัน

หากไม่มี `common.py` แต่ละ Script จะต้องเขียนโค้ดสำหรับสร้าง Flow, กำหนด PDK, ค้นหา Steps และอ่าน Metrics ซ้ำกัน

ไฟล์นี้จึงเป็นตัวอย่างของแนวคิด **Modular Programming และ Code Reusability** ในการพัฒนาระบบ EDA Automation

## 14.1 การกำหนด Project Paths

โค้ด:

```python
PROJECT_ROOT = Path(__file__).resolve().parents[1]

CONFIG_FILE = PROJECT_ROOT / "config.yaml"

REPORTS_DIR = PROJECT_ROOT / "reports"

DEFAULT_PDK = os.environ.get(
    "PDK",
    "ihp-sg13g2"
)
```

### `PROJECT_ROOT`

```python
Path(__file__).resolve().parents[1]
```

ใช้ค้นหา Root Directory ของ Lab โดยอ้างอิงตำแหน่งไฟล์ `common.py`

ตัวอย่าง:

```text
lab14_librelane_python_api/
    scripts/
        common.py
```

`parents[0]` คือ `scripts/`

`parents[1]` คือ `lab14_librelane_python_api/`

ข้อดีคือไม่ต้อง Hardcode Absolute Path ของเครื่องผู้เรียน

### `CONFIG_FILE`

```python
CONFIG_FILE = PROJECT_ROOT / "config.yaml"
```

สร้าง Path ไปยัง Configuration File

### `REPORTS_DIR`

```python
REPORTS_DIR = PROJECT_ROOT / "reports"
```

ใช้เป็นตำแหน่งกลางในการเก็บ Reports

### `DEFAULT_PDK`

```python
DEFAULT_PDK = os.environ.get("PDK", "ihp-sg13g2")
```

อ่าน Environment Variable `PDK`

หากไม่ได้กำหนด จะใช้:

```text
ihp-sg13g2
```

ผู้เรียนสามารถเปลี่ยนค่าได้ก่อนรัน Script:

```bash
export PDK=ihp-sg13g2
```

การเปลี่ยน PDK ไม่ได้หมายความว่า Design จะ Port ไปใช้ PDK ใหม่ได้ทันที เพราะยังต้องตรวจสอบ Standard Cells, Constraints, Physical Rules และ Configuration ที่เกี่ยวข้อง

---

## 14.2 ฟังก์ชัน `ensure_project_layout()`

โค้ด:

```python
def ensure_project_layout() -> None:

    if not CONFIG_FILE.is_file():
        raise FileNotFoundError(
            f"Configuration not found: {CONFIG_FILE}"
        )

    REPORTS_DIR.mkdir(
        parents=True,
        exist_ok=True
    )
```

มีหน้าที่ตรวจสอบว่า `config.yaml` มีอยู่จริง

หากไม่พบจะเกิด:

```text
FileNotFoundError
```

หลังจากนั้นสร้าง Directory `reports/` หากยังไม่มี

การใช้:

```python
exist_ok=True
```

ทำให้ไม่เกิด Error หาก Directory มีอยู่แล้ว

---

## 14.3 ฟังก์ชัน `get_flow_class()`

โค้ด:

```python
def get_flow_class(name: str = "Classic"):

    from librelane.flows import Flow

    flow_class = Flow.factory.get(name)

    if flow_class is None:

        available = ", ".join(
            sorted(Flow.factory.list())
        )

        raise RuntimeError(
            f"LibreLane flow '{name}' is unavailable. "
            f"Available flows: {available}"
        )

    return flow_class
```

มีหน้าที่ค้นหา Flow Class ตามชื่อ

ตัวอย่าง:

```python
flow_class = get_flow_class("Classic")
```

หากไม่พบจะรายงาน Available Flows

แนวทางนี้ช่วยให้ Error Message อ่านเข้าใจง่ายกว่าการปล่อยให้โปรแกรมล้มเหลวในขั้นตอนถัดไป

---

## 14.4 ฟังก์ชัน `make_flow()`

โค้ดใน Repository:

```python
def make_flow(
    config_sources: Any = None,
    *,
    pdk: str | None = None,
):
    ensure_project_layout()

    flow_class = get_flow_class("Classic")

    sources = (
        str(CONFIG_FILE)
        if config_sources is None
        else config_sources
    )

    return flow_class(
        sources,
        pdk=pdk or DEFAULT_PDK,
        design_dir=str(PROJECT_ROOT),
    )
```

เป็นฟังก์ชันหลักที่ Scripts 04–08 เรียกใช้

ทำหน้าที่:

1. ตรวจสอบ Configuration File
2. ค้นหา Classic Flow Class
3. เตรียม Configuration Sources
4. กำหนด PDK
5. กำหนด Design Directory
6. สร้าง Flow Object

### ข้อเสนอแนะในการปรับปรุง

จากปัญหา `PathLike AssertionError` ที่อาจารย์เคยพบ แนะนำให้รองรับทั้ง `str`, `Path` และ List ของ Configuration Sources

```python
def make_flow(
    config_sources: Any = None,
    *,
    pdk: str | None = None,
):
    ensure_project_layout()

    flow_class = get_flow_class("Classic")

    sources = (
        CONFIG_FILE
        if config_sources is None
        else config_sources
    )

    if isinstance(sources, os.PathLike):
        sources = os.fspath(sources)

    elif isinstance(sources, (list, tuple)):
        sources = [
            os.fspath(item)
            if isinstance(item, os.PathLike)
            else item
            for item in sources
        ]

    return flow_class(
        sources,
        pdk=pdk or DEFAULT_PDK,
        design_dir=str(PROJECT_ROOT),
    )
```

การเปลี่ยนแปลงนี้ช่วยป้องกันการส่ง `PathLike` เข้าไปโดยตรง โดยยังคง Dictionary Overlay ไว้ในรายการ Configuration Sources

---

## 14.5 ฟังก์ชัน `classic_step_ids()`

```python
def classic_step_ids() -> list[str]:

    flow_class = get_flow_class("Classic")

    return [
        str(getattr(step, "id", step.__name__))
        for step in flow_class.Steps
    ]
```

ใช้คืนรายการ Step IDs ตามลำดับของ Classic Flow

ตัวอย่างการใช้งาน:

```python
for step in classic_step_ids():
    print(step)
```

เหมาะสำหรับตรวจสอบลำดับขั้นตอนก่อนสร้าง Custom Flow

---

## 14.6 ฟังก์ชัน `resolve_step_id()`

โค้ดสำคัญ:

```python
def resolve_step_id(
    preferred: str,
    *,
    contains: Iterable[str] = (),
) -> str:
```

ฟังก์ชันนี้ใช้ค้นหา Step ID โดยรับสอง Parameters

**`preferred`**

ชื่อ Step ที่ต้องการโดยตรง

**`contains`**

Keywords สำหรับค้นหาเมื่อไม่พบชื่อที่ต้องการ

ตัวอย่าง:

```python
resolve_step_id(
    "Yosys.Synthesis",
    contains=("yosys", "synthesis"),
)
```

ถ้าพบ `Yosys.Synthesis` จะคืนชื่อนั้นทันที

หากไม่พบ จะค้นหาชื่อที่มี Keywords ครบทุกคำ

กรณีพบมากกว่าหนึ่งรายการ ฟังก์ชันจะไม่เลือกโดยพลการ แต่รายงาน Error เพื่อให้ผู้ใช้ตรวจสอบ

นี่เป็นแนวทางที่ดีสำหรับ EDA Automation เพราะการเลือก Step ผิดอาจทำให้ Flow หยุดผิดตำแหน่งหรือข้าม Verification ที่สำคัญ

---

## 14.7 ฟังก์ชัน `find_metric()`

โค้ด:

```python
def find_metric(
    metrics: Any,
    *keywords: str
) -> Any:

    required = [
        keyword.lower()
        for keyword in keywords
    ]

    for name, value in metrics.items():

        lowered = str(name).lower()

        if all(
            keyword in lowered
            for keyword in required
        ):
            return value

    return None
```

ฟังก์ชันนี้ใช้ค้นหา Metrics จาก Keywords

ตัวอย่าง:

```python
wns = find_metric(
    state.metrics,
    "setup",
    "wns"
)
```

หลักการทำงาน:

```text
Metrics Dictionary
        |
        v
   Read Metric Key
        |
        v
   Convert to Lowercase
        |
        v
   Match Keywords
        |
    +---+---+
    |       |
   YES      NO
    |       |
    v       v
  Return   Next Key
```

### จุดที่ควรปรับปรุง

สำหรับงาน Multi-corner STA ไม่ควรใช้การค้นหาแบบ Keyword เพียงอย่างเดียว เพราะอาจมีหลาย Metric Names ที่ตรงกัน

แนะนำให้เพิ่มการตรวจสอบ Matching Keys:

```python
def find_metrics(metrics, *keywords):

    required = [
        keyword.lower()
        for keyword in keywords
    ]

    return {
        name: value
        for name, value in metrics.items()
        if all(
            keyword in str(name).lower()
            for keyword in required
        )
    }
```

จากนั้น:

```python
matches = find_metrics(
    state.metrics,
    "setup",
    "wns"
)

for name, value in matches.items():
    print(name, value)
```

วิธีนี้ช่วยให้ผู้เรียนมองเห็น Metrics ทุก Corner ก่อนเลือกค่าที่จะนำไปเปรียบเทียบ

---

# 15. Code Review — ประเด็นที่ควรปรับปรุงใน Lab 14

จากการอ่าน Source Code ทั้ง 11 ไฟล์ พบประเด็นที่ควรพิจารณาก่อนนำไปใช้เป็นชุดฝึกอบรมอย่างสมบูรณ์

| ไฟล์ | ประเด็น | แนวทางปรับปรุง |
|---|---|---|
| `01_check_environment.py` | ตรวจพบเครื่องมือ แต่ไม่ทดสอบการทำงานจริง | เพิ่ม PDK และ Tool Smoke Tests |
| `02_show_flows.py` | แสดง Flow Classes เท่านั้น | เพิ่ม Flow Metadata ตาม API ที่รองรับ |
| `03_show_steps.py` | แสดง Step IDs แต่ไม่แสดง Dependencies | เพิ่มข้อมูล Inputs/Outputs ของ Steps |
| `04_validate_config.py` | ไม่ได้ตรวจ SDC ด้วย OpenSTA | เพิ่ม SDC Validation |
| `05_run_classic.py` | Default เขียนทับ Run เดิม | ใช้ Unique Run Tags หรือ `--no-overwrite` |
| `06_run_to_synthesis.py` | หยุดที่ Synthesis Step | เพิ่ม Post-synthesis Checks หากต้องการ |
| `07_export_state.py` | เริ่ม Full Flow ใหม่ก่อน Export | เพิ่มโหมดอ่าน State จาก Run ที่มีอยู่ |
| `08_parameter_sweep.py` | มีความเสี่ยง PathLike และ Metric Matching | แก้ Configuration Sources และเลือก Metrics แบบเจาะจง |
| `09_custom_synthesis_flow.py` | ใช้ Relative Paths | ใช้ Absolute Project Paths |
| `10_compare_exported_states.py` | ยังไม่คำนวณ Delta Comparison | เพิ่มการเปรียบเทียบ Metrics ระหว่าง Runs |
| `common.py` | รองรับ `Path` ไม่ครบทุกกรณี | Normalize Configuration Sources |

## 15.1 ประเด็นสำคัญที่สุด: Script 08

ควรแก้ไข:

```python
flow = make_flow([CONFIG_FILE, overlay])
```

เป็น:

```python
flow = make_flow([str(CONFIG_FILE), overlay])
```

และย้ายการสร้าง Flow เข้าไปอยู่ภายใน `try` เพื่อให้จับ Error ระหว่างการสร้าง Flow ได้

## 15.2 ประเด็นสำคัญสำหรับ Script 05 และ 07

ทั้งสอง Script สามารถเริ่ม Full Classic Flow ได้

ดังนั้น:

```bash
make run
make state
```

ไม่ได้หมายความว่า `make state` จะนำผลของ `make run` มา Export โดยอัตโนมัติ

ปัจจุบันเป็นการรัน Flow สองครั้งภายใต้ Run Tags ต่างกัน

หากต้องการลดเวลาการประมวลผล ควรออกแบบระบบให้ Export State จาก Run ที่สร้างเสร็จแล้ว โดยใช้ State และ Artifacts ที่ LibreLane Release นั้นรองรับ

---

# 16. ลำดับการทดลองที่แนะนำสำหรับผู้เรียน

แนะนำให้แบ่ง Lab 14 เป็น 4 ช่วง

### Part A — Python API Fundamentals

เรียนรู้การเชื่อมต่อ Python กับ LibreLane

```bash
make check
make flows
make steps
make validate
```

**ผลลัพธ์ที่ต้องการ:** ผู้เรียนเข้าใจ Environment, Flow Factory, Step Factory และ Configuration

### Part B — Flow Execution

ทดลองสร้าง Flow Object และรัน EDA Steps

```bash
make synth
make run TAG=baseline
```

**ผลลัพธ์ที่ต้องการ:** สร้าง Synthesis Results และ Full RTL-to-GDSII Run

### Part C — State และ Metrics

เรียนรู้การอ่านผลลัพธ์จาก LibreLane

```bash
make state
make compare
```

**ผลลัพธ์ที่ต้องการ:** เข้าใจ State Object, Design Views และ Metrics

### Part D — Advanced Automation

ทดลอง Design Space Exploration และ Custom Flow

```bash
make sweep
make custom
```

**ผลลัพธ์ที่ต้องการ:** เข้าใจ Configuration Overlay, Parameter Sweep และการสร้าง SequentialFlow

ก่อนรัน Full Flow ควรตรวจสอบว่า `constraints.sdc` ได้แก้ปัญหา `remove_from_collection` ที่เคยทำให้ OpenSTA ล้มเหลวแล้ว

---

# 17. คำถามท้าย Lab 14 พร้อมแนวทางประเมิน

สำหรับการนำไปใช้สอน ผมแนะนำคำถาม 10 ข้อดังนี้

| ข้อ | คำถาม | ประเด็นที่ต้องตอบได้ |
|---|---|---|
| 1 | LibreLane CLI แตกต่างจาก Python API อย่างไร? | Automation และการควบคุม Flow |
| 2 | `Flow.factory.get()` มีหน้าที่อะไร? | Factory Pattern |
| 3 | Registered Steps ต่างจาก Classic Flow Steps อย่างไร? | Step Registry กับ Flow Sequence |
| 4 | `flow.config` แตกต่างจาก `config.yaml` อย่างไร? | Resolved Configuration |
| 5 | `flow.start(to=...)` ใช้ทำอะไร? | Partial Flow |
| 6 | `state.metrics` เก็บข้อมูลประเภทใด? | EDA Metrics |
| 7 | Configuration Overlay มีประโยชน์อย่างไร? | Design Space Exploration |
| 8 | `SequentialFlow` แตกต่างจาก Classic Flow อย่างไร? | Custom Flow Construction |
| 9 | ทำไมการเปรียบเทียบ WNS ต้องระบุ Timing Corner? | STA Correctness |
| 10 | ทำไมต้องเก็บ Resolved Configuration และ State? | Reproducibility |

---

# 18. สรุปภาพรวมของ Lab 14

Lab 14 สาธิตการเปลี่ยนจากการใช้ LibreLane เป็นเครื่องมือผ่าน Command Line มาเป็นการควบคุม **RTL-to-GDSII Flow ด้วย Python Programming**

สามารถแบ่งองค์ความรู้ที่ได้รับเป็นสามระดับ

**ระดับพื้นฐาน — LibreLane API User**

ผู้เรียนสามารถตรวจสอบ Environment, ค้นหา Flows, อ่าน Configuration และเริ่ม Classic Flow ได้

**ระดับกลาง — EDA Automation Developer**

ผู้เรียนสามารถหยุด Flow ที่ Step ที่กำหนด อ่าน Metrics, Export State และทำ Parameter Sweep ได้

**ระดับสูง — EDA Flow Developer**

ผู้เรียนสามารถสร้าง Custom SequentialFlow จัดการ Step Sequence และพัฒนาระบบ Design Space Exploration สำหรับ ASIC Implementation ได้

### ข้อเสนอแนะสำหรับการปรับปรุง Lab 14

จากการตรวจสอบโค้ด ผมแนะนำให้ให้ความสำคัญกับสามเรื่องก่อน ได้แก่

1. **แก้ `common.py` และ Script 08** ให้รองรับ Configuration Sources ประเภท `Path`, `str` และ Dictionary Overlay อย่างถูกต้อง
2. **ปรับปรุง Script 07 และ 10** ให้สามารถนำ State จากหลาย Runs มาเปรียบเทียบแบบ Delta Metrics โดยไม่ต้องรัน Full Flow ซ้ำโดยไม่จำเป็น
3. **เพิ่มการตรวจสอบ SDC และ Multi-corner STA Metrics** เพื่อให้ Parameter Sweep สะท้อนคุณภาพ Physical Design มากกว่าการตรวจว่า Flow ทำงานจบเพียงอย่างเดียว

เมื่อปรับปรุงทั้งสามส่วนนี้ Lab 14 จะเป็นพื้นฐานที่ดีสำหรับการพัฒนา **Python-based ASIC Design Automation, Design Space Exploration และ Custom EDA Flow Research** ด้วย LibreLane และ IHP SG13G2 ได้อย่างเป็นระบบ
