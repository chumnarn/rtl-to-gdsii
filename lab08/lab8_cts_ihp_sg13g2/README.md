# Lab 8 — Clock Tree Synthesis with LibreLane and IHP SG13G2

ชุดนี้เป็น block-level CTS lab สำหรับ PDK `ihp-sg13g2` ประกอบด้วย RTL,
self-checking testbench, SDC, `config.yaml`, Makefile, PDK installer และ
scripts สำหรับสรุปผล CTS

## โครงสร้าง

```text
lab8_cts_ihp_sg13g2/
├── config.yaml
├── config_baseline.yaml
├── Makefile
├── README.md
├── constraints/
│   ├── pnr.sdc
│   └── signoff.sdc
├── scripts/
│   ├── check_tools.sh
│   ├── cts_summary.sh
│   ├── find_latest_run.sh
│   ├── list_clock_cells.sh
│   └── list_cts_artifacts.sh
├── src/
│   └── cts_demo.sv
└── tb/
    └── tb_cts_demo.sv
```

## 1. เข้า LibreLane environment

ติดตั้ง LibreLane ตามวิธี Nix/AppImage/Docker ที่ใช้อยู่ แล้วเปิด shell ที่มี:

```bash
librelane
ciel
openroad
yosys
verilator
iverilog
```

ตรวจสอบ:

```bash

chmod +x scripts/*.sh

make check
```

## 2. ติดตั้ง IHP SG13G2 PDK

```bash
make pdk
```

Makefile ใช้:

```text
PDK=ihp-sg13g2
PDK_ROOT=<project>/IHP-Open-PDK
PDK_COMMIT=3b5a704ba6738aa686b08706187830e6284d2a10
```

และเรียก:

```bash
ciel enable <PDK_COMMIT> \
  --pdk-root ./IHP-Open-PDK \
  --pdk-family ihp-sg13g2
```

ตรวจสอบ PDK:

```bash
make pdk-info
make clock-cells
```

## 3. ตรวจ RTL

```bash
make lint
make sim
make synth
```

ผล simulation ที่ถูกต้อง:

```text
PASS: functional simulation completed
```

## 4. ตรวจ config.yaml

```bash
make config-check
```

## 5. รัน LibreLane

```bash
make run
```

คำสั่งหลัก:

```bash
librelane config.yaml \
  --pdk ihp-sg13g2 \
  --pdk-root ./IHP-Open-PDK \
  --manual-pdk \
  --save-views-to final/
```

## 6. Baseline fallback

หาก LibreLane revision ที่ใช้อยู่มีปัญหากับ CTS tuning option ใด:

```bash
make run-baseline
```

`config_baseline.yaml` ปล่อยค่ารายละเอียด CTS ให้ PDK/LibreLane เลือกเกือบทั้งหมด

## 7. ตรวจผล CTS

```bash
make summary
make artifacts
make openroad
```

ประเด็นสำคัญ:

- จำนวน clock roots และ sinks
- clock buffer cells ที่เลือกจริง
- buffer count และ clock subnets
- clock skew และ insertion delay
- post-CTS setup/hold slack
- max slew/max capacitance
- legalization และ congestion

## 8. หมายเหตุสำคัญสำหรับ SG13G2

`config.yaml` ไม่กำหนด `CTS_ROOT_BUFFER` หรือ `CTS_CLK_BUFFERS` แบบตายตัว
เพราะ PDK revision และ standard-cell library ต้องเป็นผู้ระบุ cell ที่มีจริง
วิธีนี้ช่วยหลีกเลี่ยง error เช่น:

```text
CTS-0127 clock buffer cell ... not found
```

หากต้องการทดลองจำกัด buffer list ให้รัน:

```bash
make clock-cells
```

แล้วตรวจทั้ง Liberty และ LEF ก่อนเพิ่มชื่อ cell ลงใน config

## 9. ทดลอง CTS clustering

Baseline:

```yaml
CTS_SINK_CLUSTERING_SIZE: 16
CTS_SINK_CLUSTERING_MAX_DIAMETER: 50
```

Small clusters:

```yaml
CTS_SINK_CLUSTERING_SIZE: 8
CTS_SINK_CLUSTERING_MAX_DIAMETER: 30
```

Large clusters:

```yaml
CTS_SINK_CLUSTERING_SIZE: 24
CTS_SINK_CLUSTERING_MAX_DIAMETER: 80
```

เปรียบเทียบ clock buffers, skew, latency, setup WNS, hold WNS,
cell area และ routing congestion
