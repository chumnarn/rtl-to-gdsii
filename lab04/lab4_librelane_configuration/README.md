# Lab 4 — LibreLane Configuration Variables

แพ็กเกจนี้ใช้วงจร Counter ขนาด 8 บิตเพื่อทดลองตัวแปรสำคัญใน `config.yaml` ได้แก่ RTL input, clock constraint, relative/absolute floorplanning, core utilization, placement density, custom pin placement และ placement obstructions

## โครงสร้าง

```text
lab4_librelane_configuration/
├── config.yaml
├── pins.cfg
├── Makefile
├── rtl/lab4_counter.sv
├── tb/tb_lab4_counter.sv
├── scripts/
│   ├── check_config.py
│   ├── make_experiments.py
│   ├── run_experiments.sh
│   └── summarize_runs.py
├── experiments/
└── reports/
```

## 1. ตรวจสอบ Configuration

```bash
make check
```

หากไม่มี PyYAML:

```bash
python3 -m pip install pyyaml
```

## 2. RTL lint และ simulation

```bash
make lint
make sim
```

Testbench เป็น self-checking และต้องจบด้วยข้อความ:

```text
LAB4 TEST PASS
```

## 3. Generic synthesis ด้วย Yosys

```bash
make synth
```

## 4. รัน LibreLane ด้วยไฟล์หลัก `config.yaml`

SKY130:

```bash
make run PDK=sky130A
```

IHP SG13G2 เมื่อ PDK ถูกติดตั้งและชื่อ PDK ในระบบเป็นดังกล่าว:

```bash
make run PDK=ihp-sg13g2
```

หรือเรียกโดยตรง:

```bash
librelane --pdk sky130A config.yaml
```

## 5. การทดลอง Density และ Die Area

สร้างไฟล์ทดลองโดยไม่แก้ Baseline:

```bash
python3 scripts/make_experiments.py
ls experiments
```

รันทั้งหมด:

```bash
make experiments PDK=sky130A
```

## 6. สรุป Metrics

หลังจากมีผลใน `runs/`:

```bash
make summary
```

ผลลัพธ์:

```text
reports/run_summary.csv
```

## หมายเหตุสำคัญ

- `config.yaml` ใช้ `dir::` ทำให้ Path อ้างอิงจาก Design Directory
- ค่า `CLOCK_PERIOD: 20.0` เท่ากับ 50 MHz
- เริ่มจาก `FP_SIZING: relative` เพื่อสร้าง Baseline
- การใช้ `FP_SIZING: absolute` ต้องกำหนด `DIE_AREA`
- เปลี่ยนตัวแปรทีละค่าและเก็บ Metrics ทุก Run
- ไฟล์ทดลองทั้งหมดใช้ YAML ไม่ใช้ JSON หรือ Tcl
