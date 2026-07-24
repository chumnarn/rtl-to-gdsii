# รวมคำสั่งสำคัญของ LibreLane

LibreLane ใช้รูปแบบหลักดังนี้:

```bash
librelane [OPTIONS] config.yaml
```

ถ้าไม่ระบุ `--flow` LibreLane จะใช้ flow ชื่อ `Classic` โดยอัตโนมัติ ส่วนการควบคุมช่วงการทำงานสามารถใช้ `--from`, `--to`, `--skip` และ `--only` ได้ ([LibreLane][1])

---

## 1. ตรวจสอบการติดตั้ง

```bash
librelane --version
```

```bash
librelane --help
```

ตรวจเครื่องมือที่ LibreLane เรียกใช้:

```bash
yosys -V
openroad -version
klayout -v
magic --version
netgen -batch version
verilator --version
```

ตรวจ Python environment:

```bash
which librelane
which python3
python3 --version
```

สำหรับ LibreLane ที่ติดตั้งด้วย Nix:

```bash
nix-shell /path/to/librelane/shell.nix
```

ตัวอย่าง:

```bash
cd ~/librelane
nix-shell shell.nix
```

LibreLane แนะนำ Nix เป็นวิธีหลัก เพราะช่วยตรึงเวอร์ชันของ Yosys, OpenROAD, KLayout, Magic และ Netgen ให้เข้ากัน ส่วนการติดตั้งเครื่องมือแยกเองอาจเกิดปัญหาเวอร์ชันไม่ตรงกัน ([LibreLane][1])

---

# 2. ตรวจสอบไฟล์โครงการ

โครงสร้างพื้นฐาน:

```text
project/
├── config.yaml
├── rtl/
│   └── counter.sv
├── constraints/
│   ├── pnr.sdc
│   └── signoff.sdc
└── runs/
```

ตรวจไฟล์:

```bash
find . -maxdepth 3 -type f | sort
```

ตรวจ syntax ของ YAML:

```bash
python3 - <<'PY'
import yaml

with open("config.yaml", encoding="utf-8") as f:
    data = yaml.safe_load(f)

print(data)
PY
```

ดูค่าหลัก:

```bash
grep -nE \
'DESIGN_NAME|VERILOG_FILES|CLOCK_PORT|CLOCK_PERIOD|PDK|STD_CELL_LIBRARY|DIE_AREA|CORE_AREA|FP_CORE_UTIL' \
config.yaml
```

---

# 3. ตัวอย่าง `config.yaml` ขั้นต่ำ

```yaml
DESIGN_NAME: counter

VERILOG_FILES:
  - "dir::rtl/counter.sv"

CLOCK_PORT: clk
CLOCK_PERIOD: 20.0

PNR_SDC_FILE: "dir::constraints/pnr.sdc"
SIGNOFF_SDC_FILE: "dir::constraints/signoff.sdc"

FP_CORE_UTIL: 40
```

ตัวแปรพื้นฐานที่สำคัญคือ `DESIGN_NAME`, `VERILOG_FILES`, `CLOCK_PORT`, `CLOCK_PERIOD` และ `FP_CORE_UTIL` โดยค่า utilization ประมาณ 25–60% เป็นช่วงเริ่มต้นที่พบได้ทั่วไป และ 40% เหมาะสำหรับเริ่มทดลอง ([LibreLane][2])

---

# 4. รัน Classic flow

## ใช้ PDK เริ่มต้น

```bash
librelane config.yaml
```

## ระบุ Classic flow ชัดเจน

```bash
librelane \
  --flow Classic \
  config.yaml
```

## ใช้ IHP SG13G2

```bash
librelane \
  --pdk ihp-sg13g2 \
  --flow Classic \
  config.yaml
```

## ใช้ SKY130A

```bash
librelane \
  --pdk sky130A \
  --flow Classic \
  config.yaml
```

## ใช้ GF180MCU

ชื่อ PDK ต้องตรงกับ PDK configuration ที่ติดตั้งใน environment เช่น:

```bash
librelane \
  --pdk gf180mcuD \
  --flow Classic \
  config.yaml
```

LibreLane เลือก PDK ตามลำดับความสำคัญจาก configuration, `--pdk`, environment variable `PDK` และ default PDK ส่วน standard-cell library เลือกได้ด้วย config, `--scl` หรือ `STD_CELL_LIBRARY` ([LibreLane][3])

---

# 5. กำหนดชื่อ run

```bash
librelane \
  --pdk ihp-sg13g2 \
  --flow Classic \
  --run-tag test_01 \
  config.yaml
```

ผลจะอยู่ใน:

```text
runs/test_01/
```

ใช้ชื่อที่บอกวัตถุประสงค์:

```bash
librelane \
  --pdk ihp-sg13g2 \
  --run-tag baseline \
  config.yaml
```

```bash
librelane \
  --pdk ihp-sg13g2 \
  --run-tag timing_fix_01 \
  config.yaml
```

```bash
librelane \
  --pdk ihp-sg13g2 \
  --run-tag density_45 \
  config.yaml
```

---

# 6. กำหนด Standard Cell Library

```bash
librelane \
  --pdk sky130A \
  --scl sky130_fd_sc_hd \
  config.yaml
```

หรือใช้ environment variable:

```bash
export PDK=sky130A
export STD_CELL_LIBRARY=sky130_fd_sc_hd

librelane config.yaml
```

ตรวจค่าที่ตั้ง:

```bash
echo "$PDK"
echo "$STD_CELL_LIBRARY"
```

---

# 7. รันตัวอย่างที่มากับ LibreLane

```bash
librelane --run-example spm
```

พร้อมกำหนด PDK:

```bash
librelane \
  --pdk sky130A \
  --run-example spm
```

คำสั่ง `--run-example spm` จะคัดลอกตัวอย่างมายัง current directory แล้วรัน flow ([LibreLane][1])

---

# 8. รันเฉพาะช่วงของ flow

LibreLane ระบุแต่ละขั้นด้วย Step ID เช่น:

```text
Yosys.Synthesis
OpenROAD.Floorplan
OpenROAD.GlobalPlacement
OpenROAD.CTS
OpenROAD.GlobalRouting
OpenROAD.DetailedRouting
OpenROAD.STAPostPNR
KLayout.DRC
Netgen.LVS
```

ชื่อจริงอาจแตกต่างเล็กน้อยตาม LibreLane version และ flow ที่ใช้ จึงควรดูชื่อจาก output ของ run หรือใช้:

```bash
librelane --help
```

## รันตั้งแต่ขั้นที่กำหนด

```bash
librelane \
  --pdk ihp-sg13g2 \
  --from OpenROAD.Floorplan \
  config.yaml
```

## รันถึงขั้นที่กำหนด

```bash
librelane \
  --pdk ihp-sg13g2 \
  --to OpenROAD.GlobalPlacement \
  config.yaml
```

## รันเป็นช่วง

```bash
librelane \
  --pdk ihp-sg13g2 \
  --from OpenROAD.Floorplan \
  --to OpenROAD.CTS \
  config.yaml
```

## รันเพียงขั้นเดียว

```bash
librelane \
  --pdk ihp-sg13g2 \
  --only Yosys.Synthesis \
  config.yaml
```

ตัวอย่าง:

```bash
librelane \
  --pdk ihp-sg13g2 \
  --only OpenROAD.STAPostPNR \
  config.yaml
```

## ข้ามบางขั้น

```bash
librelane \
  --pdk ihp-sg13g2 \
  --skip Magic.DRC \
  config.yaml
```

ข้ามหลายขั้น:

```bash
librelane \
  --pdk ihp-sg13g2 \
  --skip Magic.DRC \
  --skip OpenROAD.IRDropReport \
  config.yaml
```

ตัวเลือก `--from`, `--to`, `--skip` และ `--only` เป็นความสามารถหลักสำหรับควบคุม flow และกลับมารันจาก state ของ design ได้ ([LibreLane][1])

> ไม่ควรข้าม DRC, LVS, antenna หรือ STA สำหรับผลที่ต้องนำไป signoff

---

# 9. เปิดผลล่าสุดใน OpenROAD GUI

```bash
librelane \
  --last-run \
  --flow openinopenroad \
  --pdk ihp-sg13g2 \
  config.yaml
```

หากมีปัญหา OpenGL ใน WSL2:

```bash
LIBGL_ALWAYS_SOFTWARE=1 \
QT_QPA_PLATFORM=xcb \
QT_OPENGL=software \
librelane \
  --last-run \
  --flow openinopenroad \
  --pdk ihp-sg13g2 \
  config.yaml
```

กำหนด cursor:

```bash
export XCURSOR_THEME=Adwaita
export XCURSOR_SIZE=32
export LIBGL_ALWAYS_SOFTWARE=1
export QT_QPA_PLATFORM=xcb
export QT_OPENGL=software

librelane \
  --last-run \
  --flow openinopenroad \
  --pdk ihp-sg13g2 \
  config.yaml
```

---

# 10. เปิดผลล่าสุดใน KLayout

```bash
librelane \
  --last-run \
  --flow openinklayout \
  --pdk ihp-sg13g2 \
  config.yaml
```

เอกสาร LibreLane ใช้ `--last-run --flow openinklayout` สำหรับเปิด final GDSII ของ run ล่าสุด ([LibreLane][4])

หรือเปิด GDS โดยตรง:

```bash
klayout runs/RUN_NAME/final/gds/*.gds
```

หา GDS ก่อน:

```bash
find runs -type f \
  \( -name "*.gds" -o -name "*.gdsii" \) \
  | sort
```

เปิดไฟล์ล่าสุด:

```bash
GDS=$(find runs -type f \
  \( -name "*.gds" -o -name "*.gdsii" \) \
  -printf '%T@ %p\n' \
  | sort -n \
  | tail -1 \
  | cut -d' ' -f2-)

klayout "$GDS"
```

---

# 11. หา run ล่าสุด

```bash
ls -dt runs/RUN_* | head -1
```

กำหนดเป็นตัวแปร:

```bash
RUN=$(ls -dt runs/RUN_* | head -1)
echo "$RUN"
```

กรณีใช้ `--run-tag`:

```bash
RUN="runs/timing_fix_01"
```

ดูรายการทุก run:

```bash
find runs -mindepth 1 -maxdepth 1 -type d | sort
```

---

# 12. ดู resolved configuration

LibreLane สร้างไฟล์:

```text
runs/RUN_NAME/resolved.json
```

เปิดดู:

```bash
cat "$RUN/resolved.json"
```

จัดรูปแบบด้วย `jq`:

```bash
jq . "$RUN/resolved.json" | less
```

ดูตัวแปรเฉพาะ:

```bash
jq '{
  DESIGN_NAME,
  PDK,
  STD_CELL_LIBRARY,
  CLOCK_PORT,
  CLOCK_PERIOD,
  DIE_AREA,
  CORE_AREA,
  FP_CORE_UTIL
}' "$RUN/resolved.json"
```

ค้นหาค่า SDC:

```bash
jq '{
  PNR_SDC_FILE,
  SIGNOFF_SDC_FILE
}' "$RUN/resolved.json"
```

`resolved.json` คือ configuration หลังรวมค่า default, ค่า PDK, user configuration และ command-line overrides แล้ว และสามารถนำกลับมารันใหม่ได้ ([LibreLane][1])

รันจาก resolved configuration:

```bash
librelane \
  --pdk ihp-sg13g2 \
  "$RUN/resolved.json"
```

---

# 13. ดู metrics

หา metrics:

```bash
find "$RUN" -type f \
  \( -name "metrics.csv" -o -name "metrics.json" \) \
  | sort
```

ดู final metrics:

```bash
cat "$RUN/final/metrics.csv"
```

ค้นหาค่าที่สำคัญ:

```bash
grep -Ei \
'area|instance|wirelength|slack|tns|overflow|drc|antenna|lvs' \
"$RUN/final/metrics.csv"
```

ดู JSON metrics:

```bash
jq . "$RUN/final/metrics.json" | less
```

แสดงชื่อ metric ทั้งหมด:

```bash
cut -d, -f1 "$RUN/final/metrics.csv" | sort
```

---

# 14. ดูพื้นที่ Die และ Core

## Die area จาก DEF

```bash
DEF=$(find "$RUN/final" -type f -name "*.def" | head -1)

grep '^UNITS DISTANCE MICRONS' "$DEF"
grep '^DIEAREA' "$DEF"
```

## จำนวน instances

```bash
grep '^COMPONENTS ' "$DEF"
```

## Core area จาก log และ metrics

```bash
grep -RniE \
'core area|core_area|design__core' \
"$RUN" \
--include="*.log" \
--include="*.rpt" \
--include="metrics.csv"
```

---

# 15. ดู timing reports

Classic flow ทำ STA หลายช่วง ได้แก่ pre-PnR, mid-PnR และ post-PnR โดย post-PnR ใช้ parasitics จาก final layout และเป็นผลที่แม่นยำที่สุดสำหรับ design สุดท้าย ([LibreLane][5])

หา STA reports:

```bash
find "$RUN" -type f \
  \( -name "summary.rpt" \
     -o -name "wns*.rpt" \
     -o -name "tns*.rpt" \
     -o -name "*timing*.rpt" \) \
  | sort
```

ดูทุก summary:

```bash
find "$RUN" -name "summary.rpt" \
  -print \
  -exec cat {} \;
```

## Worst slack

```bash
grep -RniE \
'worst.*slack|setup.*wns|slack.*VIOLATED' \
"$RUN" \
--include="*.rpt" \
--include="*.log"
```

## Total negative slack

```bash
grep -RniE \
'total negative slack|setup.*tns' \
"$RUN" \
--include="*.rpt" \
--include="*.log"
```

## Setup violation

```bash
grep -RniB10 -A50 \
'VIOLATED' \
"$RUN" \
--include="*.rpt"
```

## Hold violation

```bash
grep -RniE \
'hold.*violation|hold.*slack|hold.*tns' \
"$RUN" \
--include="*.rpt" \
--include="*.log"
```

## Max slew

```bash
grep -RniE \
'max slew|max_slew|slew violation' \
"$RUN" \
--include="*.rpt" \
--include="*.log"
```

## Max capacitance

```bash
grep -RniE \
'max capacitance|max cap|max_cap' \
"$RUN" \
--include="*.rpt" \
--include="*.log"
```

---

# 16. ดู synthesis report

หา synthesis step:

```bash
find "$RUN" -maxdepth 1 -type d \
  -iname "*yosys*" \
  | sort
```

ดู report:

```bash
find "$RUN" -path "*yosys*" -type f \
  \( -name "*.rpt" -o -name "*.log" \) \
  | sort
```

ตรวจ Yosys check:

```bash
grep -RniE \
'Warning|ERROR|Found and reported|multiple conflicting drivers|undriven' \
"$RUN"/*yosys* \
2>/dev/null
```

ดู synthesis statistics:

```bash
grep -RniA30 \
'Printing statistics' \
"$RUN"/*yosys* \
2>/dev/null
```

ไฟล์ตรวจ synthesis มักอยู่ในไดเรกทอรีของ `Yosys.Synthesis` เช่น `reports/pre_synth_chk.rpt` และ `reports/chk.rpt` ([LibreLane][6])

---

# 17. ตรวจ floorplan และ placement

```bash
grep -RniE \
'die area|core area|utilization|density|placement' \
"$RUN"/*floorplan* \
"$RUN"/*placement* \
2>/dev/null
```

ดู utilization:

```bash
grep -RniE \
'utilization|design__instance__area|core.*area' \
"$RUN" \
--include="metrics.csv" \
--include="*.rpt" \
--include="*.log"
```

ดู unplaced instances:

```bash
grep -RniE \
'unplaced|not placed|placement violations' \
"$RUN"/*placement* \
2>/dev/null
```

---

# 18. ตรวจ Clock Tree Synthesis

หา CTS step:

```bash
find "$RUN" -maxdepth 1 -type d \
  -iname "*cts*" \
  | sort
```

ค้นหา clock buffers:

```bash
grep -RniE \
'clock buffer|clock inverter|inserted.*buffer|clock tree' \
"$RUN"/*cts* \
2>/dev/null
```

ดู clock skew และ latency:

```bash
grep -RniE \
'clock skew|clock latency|insertion delay|clock tree' \
"$RUN" \
--include="*.rpt" \
--include="*.log"
```

---

# 19. ตรวจ Global Routing

```bash
grep -RniE \
'overflow|congestion|global routing|routing congestion' \
"$RUN"/*globalrouting* \
"$RUN"/*global-routing* \
2>/dev/null
```

ค้นหา overflow จากทั้ง run:

```bash
grep -RniE \
'route__overflow|routing.*overflow|total overflow' \
"$RUN" \
--include="metrics.csv" \
--include="*.rpt" \
--include="*.log"
```

ค่าที่ต้องการ:

```text
Global routing overflow = 0
```

---

# 20. ตรวจ Detailed Routing

```bash
grep -RniE \
'DRC|violation|detailed routing|route__drc_errors' \
"$RUN"/*detailedrouting* \
"$RUN"/*detailed-routing* \
2>/dev/null
```

ดู final routing DRC:

```bash
grep -RniE \
'route__drc_errors|drc errors|number of violations' \
"$RUN" \
--include="metrics.csv" \
--include="*.rpt" \
--include="*.log"
```

ค่าที่ต้องการ:

```text
Detailed-routing DRC = 0
```

---

# 21. ตรวจ Wire Length

```bash
grep -RniE \
'wirelength|wire length|route__wirelength' \
"$RUN" \
--include="metrics.csv" \
--include="metrics.json" \
--include="*.rpt" \
--include="*.log"
```

ดู long-wire checker:

```bash
grep -RniE \
'long wire|wire length threshold|Threshold-surpassing' \
"$RUN" \
--include="*.log" \
--include="*.rpt"
```

---

# 22. ตรวจ Antenna

```bash
find "$RUN" -maxdepth 1 -type d \
  -iname "*antenna*" \
  | sort
```

ดู antenna violations:

```bash
grep -RniE \
'antenna.*violation|violating nets|violating pins|antenna errors clear' \
"$RUN"/*antenna* \
2>/dev/null
```

ผลผ่านมักพบ:

```text
Check for KLayout antenna errors clear.
```

---

# 23. ตรวจ DRC

## รายงานทั้งหมด

```bash
find "$RUN" -type f \
  \( -iname "*drc*.rpt" \
     -o -iname "*drc*.xml" \
     -o -iname "*drc*.json" \
     -o -iname "*drc*.log" \) \
  | sort
```

## KLayout DRC

```bash
grep -RniE \
'drc|violation|error count|total violations' \
"$RUN"/*klayout*drc* \
2>/dev/null
```

## Magic DRC

```bash
grep -RniE \
'drc|violation|error count|total violations' \
"$RUN"/*magic*drc* \
2>/dev/null
```

---

# 24. ตรวจ LVS

```bash
find "$RUN" -type f \
  \( -iname "*lvs*.rpt" \
     -o -iname "*lvs*.log" \
     -o -iname "*lvs*.json" \) \
  | sort
```

ค้นหาผล:

```bash
grep -RniE \
'circuits match|netlists match|lvs.*pass|lvs.*fail|mismatch' \
"$RUN"/*lvs* \
"$RUN"/*netgen* \
2>/dev/null
```

ผลผ่านโดยทั่วไปควรมีข้อความ:

```text
Circuits match uniquely.
```

---

# 25. ตรวจ IR drop

```bash
find "$RUN" -maxdepth 1 -type d \
  -iname "*irdrop*" \
  -o -iname "*ir-drop*" \
  | sort
```

```bash
grep -RniE \
'voltage drop|ir drop|worst voltage|maximum drop|PSM-' \
"$RUN" \
--include="*.rpt" \
--include="*.log"
```

ตรวจ warning ของ voltage source:

```bash
grep -Rni \
'VSRC_LOC_FILES' \
"$RUN" \
--include="*.log"
```

---

# 26. ตรวจไฟล์ SPEF และ parasitics

```bash
find "$RUN" -type f -name "*.spef" | sort
```

ดูขนาดไฟล์:

```bash
find "$RUN" -type f -name "*.spef" \
  -exec ls -lh {} \;
```

ดู header:

```bash
SPEF=$(find "$RUN" -type f -name "*.spef" | head -1)
head -40 "$SPEF"
```

---

# 27. ตรวจ final outputs

```bash
find "$RUN/final" -type f | sort
```

แยกตามชนิด:

```bash
find "$RUN/final" -type f -name "*.gds"   | sort
find "$RUN/final" -type f -name "*.lef"   | sort
find "$RUN/final" -type f -name "*.def"   | sort
find "$RUN/final" -type f -name "*.v"     | sort
find "$RUN/final" -type f -name "*.spef"  | sort
find "$RUN/final" -type f -name "*.lib"   | sort
find "$RUN/final" -type f -name "*.sdf"   | sort
find "$RUN/final" -type f -name "*.spice" | sort
```

ดูขนาด final artifacts:

```bash
du -ah "$RUN/final" | sort -h
```

---

# 28. ตรวจว่า flow สำเร็จหรือไม่

```bash
grep -RniE \
'Flow complete|Flow completed|deferred errors|flow failed|ERROR.*encountered' \
"$RUN" \
--include="*.log"
```

ตรวจ final GDS:

```bash
if find "$RUN/final" -type f \
  \( -name "*.gds" -o -name "*.gdsii" \) \
  | grep -q .; then
    echo "Final GDS: FOUND"
else
    echo "Final GDS: NOT FOUND"
fi
```

ตรวจ deferred error:

```bash
if grep -RqiE \
  'deferred errors|flow failed|one or more deferred errors' \
  "$RUN" \
  --include="*.log"; then
    echo "Flow completed: NO — errors reported"
else
    echo "No deferred flow errors found"
fi
```

---

# 29. ค้นหา error และ warning ทั้งหมด

## Errors

```bash
grep -Rni \
'ERROR' \
"$RUN" \
--include="*.log" \
--include="*.rpt"
```

## Warnings

```bash
grep -Rni \
'WARNING' \
"$RUN" \
--include="*.log" \
--include="*.rpt"
```

## เฉพาะ error สำคัญ

```bash
grep -RniE \
'ERROR|deferred errors|VIOLATED|flow failed|mismatch|DRC.*[1-9]|antenna.*[1-9]' \
"$RUN" \
--include="*.log" \
--include="*.rpt"
```

## ดูท้าย log

```bash
find "$RUN" -type f -name "*.log" \
  -exec sh -c '
    echo "===== $1 ====="
    tail -20 "$1"
  ' _ {} \;
```

---

# 30. เก็บ output เป็น log

```bash
librelane \
  --pdk ihp-sg13g2 \
  --flow Classic \
  --run-tag run_01 \
  config.yaml \
  2>&1 | tee librelane_run_01.log
```

บันทึกพร้อม timestamp:

```bash
TAG="RUN_$(date +%Y-%m-%d_%H-%M-%S)"

librelane \
  --pdk ihp-sg13g2 \
  --flow Classic \
  --run-tag "$TAG" \
  config.yaml \
  2>&1 | tee "${TAG}.log"
```

---

# 31. รันแบบ Docker

```bash
librelane \
  --dockerized \
  config.yaml
```

รันตัวอย่าง:

```bash
librelane \
  --dockerized \
  --run-example spm
```

เพิ่ม directory mount:

```bash
librelane \
  --dockerized \
  --docker-mount /path/to/pdk \
  --docker-mount /path/to/macros \
  config.yaml
```

Docker mode เปิด current directory, home directory และ PDK root ให้ container โดยสามารถเพิ่ม directory ด้วย `--docker-mount` ([LibreLane][1])

---

# 32. คำสั่งพื้นฐานสำหรับ Lab

## เริ่ม flow

```bash
librelane \
  --pdk ihp-sg13g2 \
  --flow Classic \
  --run-tag lab03 \
  config.yaml
```

## ตั้ง run directory

```bash
RUN="runs/lab03"
```

## ตรวจผลรวม

```bash
grep -Ei \
'area|instance|wirelength|slack|tns|overflow|drc|antenna' \
"$RUN/final/metrics.csv"
```

## ตรวจ timing

```bash
find "$RUN" -name "summary.rpt" \
  -print \
  -exec cat {} \;
```

## ตรวจ DRC/LVS/antenna

```bash
grep -RniE \
'drc|circuits match|mismatch|antenna.*violation|antenna errors clear' \
"$RUN" \
--include="*.rpt" \
--include="*.log"
```

## เปิด OpenROAD

```bash
librelane \
  --last-run \
  --flow openinopenroad \
  --pdk ihp-sg13g2 \
  config.yaml
```

## เปิด KLayout

```bash
librelane \
  --last-run \
  --flow openinklayout \
  --pdk ihp-sg13g2 \
  config.yaml
```

---

# 33. Script สรุปผล run ที่สำคัญ

สร้างไฟล์:

```bash
cat > check_run.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

RUN="${1:-$(ls -dt runs/* 2>/dev/null | head -1)}"

if [[ -z "${RUN:-}" || ! -d "$RUN" ]]; then
    echo "Usage: $0 runs/RUN_NAME"
    exit 1
fi

echo "============================================================"
echo "LibreLane Run: $RUN"
echo "============================================================"

echo
echo "[1] Final files"
find "$RUN/final" -type f 2>/dev/null | sort || true

echo
echo "[2] Important metrics"
if [[ -f "$RUN/final/metrics.csv" ]]; then
    grep -Ei \
    'die|core|area|instance|wirelength|slack|tns|overflow|drc|antenna|lvs' \
    "$RUN/final/metrics.csv" || true
fi

echo
echo "[3] Timing summaries"
find "$RUN" -name "summary.rpt" \
    -print \
    -exec cat {} \; 2>/dev/null || true

echo
echo "[4] Errors"
grep -RniE \
'ERROR|deferred errors|flow failed|VIOLATED' \
"$RUN" \
--include="*.log" \
--include="*.rpt" \
2>/dev/null | tail -100 || true

echo
echo "[5] DRC, LVS and antenna"
grep -RniE \
'route__drc_errors|drc violations|circuits match|mismatch|antenna.*violation|antenna errors clear' \
"$RUN" \
--include="*.log" \
--include="*.rpt" \
2>/dev/null | tail -100 || true

echo
echo "[6] Flow status"
GDS=$(find "$RUN/final" -type f \
    \( -name "*.gds" -o -name "*.gdsii" \) \
    2>/dev/null | head -1 || true)

if [[ -z "$GDS" ]]; then
    echo "Flow completed: NO — final GDS not found"
elif grep -RqiE \
    'deferred errors|flow failed|one or more deferred errors' \
    "$RUN" \
    --include="*.log" 2>/dev/null; then
    echo "Flow completed: PARTIAL — GDS exists but errors were reported"
    echo "GDS: $GDS"
else
    echo "Flow completed: YES"
    echo "GDS: $GDS"
fi
EOF

chmod +x check_run.sh
```

ใช้งาน:

```bash
./check_run.sh runs/lab03
```

หรือใช้ run ล่าสุด:

```bash
./check_run.sh
```

---

## ชุดคำสั่งสั้นที่ควรจำ

```bash
# ดู help
librelane --help

# รัน full RTL-to-GDSII
librelane --pdk ihp-sg13g2 --flow Classic config.yaml

# กำหนดชื่อ run
librelane --pdk ihp-sg13g2 --run-tag baseline config.yaml

# รันช่วงหนึ่ง
librelane --pdk ihp-sg13g2 \
  --from OpenROAD.Floorplan \
  --to OpenROAD.CTS \
  config.yaml

# รันขั้นเดียว
librelane --pdk ihp-sg13g2 \
  --only Yosys.Synthesis \
  config.yaml

# เปิด OpenROAD
librelane --last-run \
  --flow openinopenroad \
  --pdk ihp-sg13g2 \
  config.yaml

# เปิด KLayout
librelane --last-run \
  --flow openinklayout \
  --pdk ihp-sg13g2 \
  config.yaml

# หา run ล่าสุด
RUN=$(ls -dt runs/* | head -1)

# ดู final metrics
cat "$RUN/final/metrics.csv"

# ดู timing summary
find "$RUN" -name summary.rpt -print -exec cat {} \;

# ค้นหา errors
grep -RniE 'ERROR|deferred errors|VIOLATED|flow failed' \
  "$RUN" --include="*.log" --include="*.rpt"

# ดู final outputs
find "$RUN/final" -type f | sort
```

[1]: https://librelane.readthedocs.io/en/latest/getting_started/migrants/?utm_source=chatgpt.com "Migrating from OpenLane - LibreLane Documentation"
[2]: https://librelane.readthedocs.io/en/stable/additional_material/caravel/macro_first_hardening/index.html?utm_source=chatgpt.com "Option 1 — Macro-First Hardening strategy - LibreLane ..."
[3]: https://librelane.readthedocs.io/en/latest/usage/about_pdks.html?utm_source=chatgpt.com "Process Design Kits - LibreLane Documentation"
[4]: https://librelane.readthedocs.io/en/latest/additional_material/caravel/top_level_integration/index.html?utm_source=chatgpt.com "Option 3 — Top-Level Integration Strategy - LibreLane Documentation"
[5]: https://librelane.readthedocs.io/en/stable/usage/timing_closure/index.html?utm_source=chatgpt.com "Achieving Timing Closure - LibreLane Documentation"
[6]: https://librelane.readthedocs.io/en/stable/additional_material/caravel/flattened_wrapper/index.html?utm_source=chatgpt.com "Option 2 — Full-Wrapper Flattening strategy"
