# Lab 8: Clock Tree Synthesis

โปรเจกต์พร้อมรันสำหรับศึกษา Clock Tree Synthesis (CTS) ด้วย LibreLane
Classic flow และ IHP SG13G2 Open PDK

## Requirements

- Linux environment (native Linux, WSL2, or a Linux VM)
- LibreLane พร้อม OpenROAD, Yosys และ Ciel
- IHP SG13G2 PDK

สคริปต์รายงานใช้ GNU `find`, `grep`, `sort`, `head` และ Bash

## Project structure

```text
lab8_cts/
├── config.yaml
├── src/
│   └── cts_counter.sv
├── constraint/
│   ├── pnr.sdc
│   └── signoff.sdc
├── scripts/
│   ├── find_cts_reports.sh
│   └── summarize_cts.sh
└── README.md
```

## 1. Enter the LibreLane environment

ใช้ environment ตามวิธีติดตั้ง LibreLane ของเครื่อง ตัวอย่าง:

```bash
nix-shell
librelane --version
ciel --version
```

## 2. Install/enable IHP SG13G2

กำหนด directory สำหรับ PDK:

```bash
export PDK_ROOT="$(pwd)/IHP-Open-PDK"
mkdir -p "$PDK_ROOT"
```

ติดตั้ง revision ที่ LibreLane/IHP environment ของคุณกำหนด หากมี PDK อยู่แล้ว
ให้ข้ามขั้นตอนนี้ได้ ตรวจสอบ path ก่อนรัน:

```bash
find "$PDK_ROOT" -maxdepth 3 -type d -name 'ihp-sg13g2'
```

## 3. Validate the input files

```bash
python3 - <<'PY'
import yaml
with open("config.yaml", encoding="utf-8") as f:
    cfg = yaml.safe_load(f)
assert cfg["meta"]["flow"] == "Classic"
assert cfg["DESIGN_NAME"] == "cts_counter"
assert cfg["CLOCK_PORT"] == "clk_i"
print("PASS: config.yaml")
PY

bash -n scripts/find_cts_reports.sh
bash -n scripts/summarize_cts.sh
chmod +x scripts/*.sh
```

ตรวจ RTL เพิ่มเติม (ถ้ามี Verilator):

```bash
verilator --lint-only --Wall -Wno-fatal \
  --top-module cts_counter src/cts_counter.sv
```

## 4. Run LibreLane

จาก directory `lab8_cts/`:

```bash
librelane config.yaml \
  --pdk ihp-sg13g2 \
  --pdk-root "$PDK_ROOT" \
  --manual-pdk \
  --save-views-to final/
```

`config.yaml` ไม่กำหนด `CTS_ROOT_BUFFER` หรือ `CTS_CLK_BUFFERS` แบบตายตัว
เพื่อให้ configuration ของ PDK เลือก clock cells ที่มีจริง

## 5. Inspect CTS results

```bash
scripts/find_cts_reports.sh
scripts/summarize_cts.sh
```

หรือระบุ run directory:

```bash
scripts/find_cts_reports.sh runs/RUN_NAME
scripts/summarize_cts.sh runs/RUN_NAME | tee cts_summary.txt
```

ตรวจสอบอย่างน้อย:

- จำนวน clock roots, sinks, subnets และ buffers
- clock skew และ insertion latency
- setup WNS/TNS และ hold slack
- transition, capacitance และ fanout violations
- placement legalization และ routing congestion

## 6. Open the latest run in OpenROAD

```bash
librelane config.yaml \
  --pdk ihp-sg13g2 \
  --pdk-root "$PDK_ROOT" \
  --manual-pdk \
  --last-run \
  --flow OpenInOpenROAD
```

## Notes

- Clock period คือ 20 ns หรือ 50 MHz
- PnR และ signoff SDC แยกจากกัน
- ค่า CTS tuning อาจขึ้นกับ LibreLane release หาก validator แจ้งว่าตัวแปร
  ใดไม่รองรับ ให้ตรวจ configuration reference ของ release ที่ติดตั้ง
- อย่าใช้ผลของ CTS เพียงค่า skew ค่าเดียว ควรพิจารณา setup/hold,
  electrical violations, area และ routability ร่วมกัน
