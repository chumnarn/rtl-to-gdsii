# Lab 14 — LibreLane Python API with IHP SG13G2

โปรเจกต์นี้เป็น Lab แบบพร้อมรันสำหรับศึกษา LibreLane ผ่าน Python API โดยใช้
`config.yaml`, Classic Flow และ PDK `ihp-sg13g2`

## โครงสร้าง

```text
.
├── config.yaml
├── constraints.sdc
├── Makefile
├── run_all.sh
├── rtl/counter.sv
├── tb/tb_counter.sv
├── scripts/
└── reports/
```

## สิ่งที่ Lab สาธิต

- ตรวจสอบ Python/LibreLane environment
- ค้นหา Flow และ Step ผ่าน factory
- resolve และ validate `config.yaml`
- รัน Classic Flow จาก Python
- หยุด Flow หลัง synthesis
- export Final State และ metrics
- ทำ placement-density parameter sweep
- สร้าง custom `SequentialFlow`
- เปิดผลด้วย OpenROAD GUI หรือ KLayout

## ข้อกำหนด

ต้องติดตั้ง LibreLane และ IHP Open PDK ไว้แล้ว โดย environment ต้องสามารถรัน:

```bash
librelane --pdk ihp-sg13g2 --help
python3 -c "import librelane; print(librelane.__file__)"
```

แนะนำให้เข้า LibreLane Nix shell หรือ container ที่ติดตั้ง PDK ก่อนรัน Lab

## เริ่มต้นอย่างเร็ว

```bash
cd lab14_librelane_python_api_ihp_sg13g2
chmod +x run_all.sh scripts/*.py

export PDK=ihp-sg13g2

make check
make sim
make flows
make steps
make validate
make synth
make run TAG=lab14_ihp_full
make state
```

หรือรันส่วนตรวจสอบและ synthesis ต่อเนื่อง:

```bash
./run_all.sh
```

## คำสั่งหลัก

### 1. ตรวจสอบ environment

```bash
make check
```

### 2. RTL simulation

```bash
make sim
```

ผลที่คาดหวัง:

```text
PASS: counter RTL simulation
```

### 3. ดู Flow และ Steps

```bash
make flows
make steps
```

### 4. Validate configuration

```bash
make validate
```

### 5. รันถึง synthesis

```bash
make synth
```

สคริปต์จะค้นหา Step ID ของ Yosys synthesis จาก Classic Flow จริง เพื่อลดปัญหา
ชื่อ Step แตกต่างระหว่าง LibreLane releases

### 6. Full RTL-to-GDSII

```bash
make run TAG=lab14_ihp_full
```

### 7. Export State และ metrics

```bash
make state
```

ผลลัพธ์:

```text
reports/final_state.json
reports/metrics.txt
```

### 8. Parameter sweep

```bash
make sweep
column -s, -t reports/parameter_sweep.csv
```

ทดลองค่า:

```text
PL_TARGET_DENSITY_PCT = 30, 35, 40
```

### 9. Custom flow

```bash
make custom
```

สคริปต์จะคัดลอกลำดับ Steps จาก Classic Flow ตั้งแต่ต้นจนถึง synthesis
แทนการเดา prerequisite Steps เอง

### 10. เปิดผลลัพธ์

```bash
make gui
make klayout
```

## Configuration สำคัญ

```yaml
meta:
  version: 3
  flow: Classic

DESIGN_NAME: counter
CLOCK_PORT: clk
CLOCK_PERIOD: 20.0

FP_SIZING: absolute
DIE_AREA: [0, 0, 180, 180]
CORE_AREA: [20, 20, 160, 160]
PL_TARGET_DENSITY_PCT: 35
```

`constraints.sdc` กำหนด clock 20 ns หรือ 50 MHz พร้อม clock uncertainty,
input/output delays และ output load

## การแก้ปัญหา

### Import LibreLane ไม่ได้

```bash
python3 -c "import librelane"
```

หากล้มเหลว ต้องเข้า Nix shell/container ของ LibreLane ก่อน

### ไม่พบ PDK

```bash
echo "$PDK_ROOT"
librelane --pdk ihp-sg13g2 --help
```

ตรวจสอบว่า PDK ถูกติดตั้งใน PDK root ที่ LibreLane ใช้งาน

### `USE_SLANG` ไม่รองรับใน release เก่า

ลบบรรทัดต่อไปนี้ออกจาก `config.yaml`:

```yaml
USE_SLANG: true
```

RTL ของ Lab ใช้ SystemVerilog; ในกรณีนั้นอาจเปลี่ยน RTL เป็น Verilog-2005
หรือใช้ LibreLane release ที่มี Slang frontend

### Floorplan ใหญ่เกินไปหรือเล็กเกินไป

ปรับ:

```yaml
DIE_AREA: [0, 0, 180, 180]
CORE_AREA: [20, 20, 160, 160]
```

counter มีขนาดเล็กมาก ค่าเริ่มต้นเน้นความเสถียรและการสังเกตผล ไม่ได้เน้น area ต่ำสุด

## Cleanup

```bash
make clean
```

## หมายเหตุเรื่อง reproducibility

หลัง Flow เริ่มทำงาน LibreLane จะสร้าง resolved configuration ใน run directory
ควรเก็บ resolved config, State JSON, metrics, LibreLane version และ PDK revision
ร่วมกับรายงาน Lab ทุกครั้ง
