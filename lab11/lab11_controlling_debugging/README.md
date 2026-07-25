# Lab 11 — Controlling and Debugging the LibreLane Flow

โปรเจกต์ตัวอย่างพร้อมรันสำหรับฝึกควบคุม Step, หยุด Flow, ตรวจ log/report,
เปรียบเทียบ configuration และทำ root-cause analysis ด้วย LibreLane `config.yaml`.

## 1. โครงสร้าง

```text
.
├── config.yaml
├── configs/
│   ├── config_floorplan.yaml
│   ├── config_density40.yaml
│   ├── config_util30.yaml
│   ├── config_clk25.yaml
│   └── config_bad_clock.yaml
├── src/counter.sv
├── tb/tb_counter.sv
├── scripts/
├── docs/debug_report_template.md
└── Makefile
```

## 2. ตรวจสภาพแวดล้อม

```bash
make env
make validate
```

`make validate` ต้องใช้ PyYAML:

```bash
python3 -m pip install pyyaml
```

## 3. ตรวจ RTL ก่อน PnR

```bash
make lint
make sim
make synth
```

Simulation เป็น self-checking testbench และต้องแสดง:

```text
PASS: counter self-checking simulation completed.
```

## 4. รัน LibreLane เต็ม Flow

ค่าเริ่มต้นคือ `sky130A` และ `sky130_fd_sc_hd`:

```bash
make flow RUN_TAG=baseline
```

กำหนด PDK/SCL อื่นผ่าน command line ได้:

```bash
make flow RUN_TAG=baseline PDK=sky130A SCL=sky130_fd_sc_hd
```

สำหรับ Docker installation ให้เรียกโดยตรงหรือแก้ `scripts/run_flow.sh` เพื่อเพิ่ม
`--dockerized` หลังคำสั่ง `librelane`.

## 5. หยุดหลัง Floorplan

```bash
make floorplan
```

คำสั่งภายในใช้:

```bash
librelane --to OpenROAD.Floorplan ... configs/config_floorplan.yaml
```

## 6. Parameter Experiments

```bash
make density40
make util30
make clk25
```

แต่ละ target ใช้ run tag แยก จึงไม่เขียนทับ baseline.

## 7. Intentional Failure

```bash
make bad-clock
```

Target นี้ตั้ง `CLOCK_PORT` เป็นชื่อที่ไม่มีใน RTL และ **ควรล้มเหลว** เพื่อใช้ฝึก:

```bash
make inspect RUN_TAG=bad_clock
make errors  RUN_TAG=bad_clock
```

บันทึกผลใน `docs/debug_report_template.md`.

## 8. ตรวจ Run

```bash
make inspect RUN_TAG=baseline
make errors  RUN_TAG=baseline
make metrics RUN_TAG=baseline
```

หรือเรียก script โดยตรง:

```bash
./scripts/inspect_run.sh runs/baseline
./scripts/find_errors.sh runs/baseline
python3 scripts/summarize_resolved.py runs/baseline/resolved.json
```

## 9. เปรียบเทียบ Metrics

หลังรัน baseline และ experiment สำเร็จ:

```bash
python3 scripts/compare_metrics.py \
  runs/baseline/final/metrics.json \
  runs/density40/final/metrics.json
```

## 10. รันซ้ำจาก Resolved Configuration

```bash
make reproduce RUN_TAG=baseline
```

`resolved.json` บันทึก configuration หลังรวม default, PDK และค่าจากผู้ใช้แล้ว.

## 11. เปิด Layout

```bash
make open-klayout RUN_TAG=baseline
make open-openroad RUN_TAG=baseline
```

## 12. ทำความสะอาด

```bash
make clean       # ลบ build และ console logs
make distclean   # ลบ run directories เพิ่มเติม
```

## 13. Debug Workflow

1. ระบุ Step ล่าสุดหรือ Step ที่ล้มเหลว
2. อ่าน `error.log` และ log ใน Step directory
3. หา error แรกที่มีความหมาย
4. ตรวจ State/output จาก Step ก่อนหน้า
5. ตั้ง hypothesis หนึ่งข้อ
6. เปลี่ยน configuration เพียงหนึ่งกลุ่ม
7. สร้าง run tag ใหม่
8. เปรียบเทียบ `resolved.json` และ metrics
9. บันทึก root cause และ corrective action

## หมายเหตุเรื่อง Version

LibreLane รองรับ YAML configuration, Classic flow, `--from`, `--to`, `--skip`,
`--only`, run directories แยกตาม Step และ `resolved.json`. รายชื่อ Step และ
configuration variables บางรายการอาจเปลี่ยนตาม release จึงควรตรวจ:

```bash
librelane --version
librelane --help
```
