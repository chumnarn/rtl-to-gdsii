# Lab 11 — Controlling and Debugging LibreLane for IHP SG13G2

ชุดทดลองพร้อมรันสำหรับควบคุม Step, หยุด Flow, เปรียบเทียบ run และวิเคราะห์
log/report โดยใช้ `config.yaml` กับ PDK `ihp-sg13g2`.

## 1. ข้อกำหนด

แนะนำให้ใช้ LibreLane แบบ Nix ตามคู่มือ LibreLane และ template ทางการของ IHP.
จาก root ของ Lab ให้เข้าสู่ environment ที่มี `librelane` และ `ciel` ก่อน.

```bash
make env
make clone-pdk
make validate
```

ค่าเริ่มต้น:

```text
PDK=ihp-sg13g2
PDK_ROOT=<lab>/IHP-Open-PDK
PDK commit=3b5a704ba6738aa686b08706187830e6284d2a10
Top module=counter
Clock=20 ns (50 MHz)
Power/Ground=VDD/VSS
```

เปลี่ยน PDK root ได้ เช่น:

```bash
make clone-pdk PDK_ROOT=$HOME/.ciel
make flow PDK_ROOT=$HOME/.ciel RUN_TAG=baseline
```

## 2. ตรวจ RTL

```bash
make lint
make sim
make synth
```

Simulation ต้องแสดง:

```text
PASS: counter self-checking simulation completed.
```

## 3. รันเต็ม Flow

```bash
make flow RUN_TAG=baseline
```

คำสั่ง LibreLane ที่ script เรียกโดยสรุป:

```bash
librelane config.yaml \
  --pdk ihp-sg13g2 \
  --pdk-root ./IHP-Open-PDK \
  --manual-pdk \
  --run-tag baseline
```

PDK เป็นผู้เลือก standard-cell library และ routing-layer defaults จึงไม่ส่ง
`--scl` แบบ SKY130.

## 4. ควบคุมจุดหยุด

```bash
make synthesis-only
make floorplan
make placement
make cts
make routing
```

ตรวจสอบชื่อ Step จริงของ release ที่ติดตั้งด้วย:

```bash
librelane --version
librelane --help
find runs/<tag> -maxdepth 1 -type d | sort -V
```

## 5. Parameter experiments

```bash
make density25
make small-core
make clk25
```

เปรียบเทียบผล:

```bash
make compare A=baseline B=density25
```

## 6. Intentional failure

```bash
make bad-clock
make inspect RUN_TAG=bad_clock
make errors  RUN_TAG=bad_clock
```

`config_bad_clock.yaml` ตั้ง clock port ที่ไม่มีจริงเพื่อฝึกหา first meaningful error.

## 7. ควบคุม Signoff Checks

เพื่อการ debug เท่านั้น:

```bash
make nodrc
make magic-drc
make klayout-drc
```

`nodrc` ไม่ใช่ผล signoff และห้ามนำไปสรุปว่า layout ผ่าน DRC.

## 8. ตรวจ Run

```bash
make inspect RUN_TAG=baseline
make errors  RUN_TAG=baseline
make metrics RUN_TAG=baseline
```

เปิด layout ล่าสุด:

```bash
make open-klayout
make open-openroad
```

## 9. Reproduce

```bash
make reproduce RUN_TAG=baseline
```

ควรเก็บ `resolved.json`, LibreLane version, PDK commit และ RTL revision ทุกครั้ง.

## 10. หมายเหตุ IHP SG13G2

- SG13G2 digital logic ใช้ thin-gate 1.2 V standard cells; net names ใน Lab คือ `VDD`/`VSS`.
- PDK มีชื่อโลหะและข้อกำหนดต่างจาก SKY130 จึงปล่อย routing defaults ให้ PDK กำหนด.
- Open-source PDK ยังมีสถานะ preview/early-access; ผล DRC และ tool warnings ต้องอ่านตาม PDK/tool revision ที่ใช้งาน.
- หากชื่อ Step เปลี่ยนใน LibreLane release ใหม่ ให้ดู run directory และ `librelane --help` แล้วแก้ target `--to` ใน Makefile.

## 11. โครงสร้าง

```text
.
├── config.yaml
├── constraints/
├── configs/
├── src/counter.sv
├── tb/tb_counter.sv
├── scripts/
├── docs/debug_report_template.md
└── Makefile
```
