ด้านล่างคือชุดคำสั่งทั้งหมดของ **Lab 9: Global and Detailed Routing** เรียงตามลำดับ สำหรับ **IHP SG13G2 PDK** โดยใช้ `config.yaml`

# ชุดคำสั่ง Lab 9: Global and Detailed Routing

## LibreLane + IHP SG13G2 PDK

---

## 1. เตรียม LibreLane Environment

เข้าสู่ LibreLane environment ที่ติดตั้ง IHP SG13G2 PDK แล้ว

กรณีใช้ Nix:

```bash
cd ~/LibreLane
nix-shell
```

หรือกรณีใช้ LibreLane package environment:

```bash
librelane --version
```

ตรวจสอบว่าเรียก LibreLane ได้:

```bash
which librelane
librelane --version
```

ตรวจสอบเครื่องมือที่เกี่ยวข้อง:

```bash
which openroad
which yosys
which verilator
which klayout
which magic
```

---

## 2. ดาวน์โหลดและแตกไฟล์ Lab

สมมติว่าไฟล์ ZIP อยู่ในโฟลเดอร์ `~/Downloads`

```bash
cd ~/Downloads
```

แตกไฟล์:

```bash
unzip lab09_global_detailed_routing_ihp_sg13g2.zip
```

เข้าสู่โฟลเดอร์ Lab:

```bash
cd lab09_global_detailed_routing_ihp_sg13g2
```

ตรวจสอบโครงสร้างไฟล์:

```bash
find . -maxdepth 3 -type f | sort
```

ผลที่ควรพบ:

```text
./Makefile
./README.md
./config.yaml
./constraints/pnr.sdc
./constraints/signoff.sdc
./docs/lab09_checklist.md
./scripts/archive_latest_reports.sh
./scripts/check_environment.sh
./scripts/find_routing_reports.sh
./scripts/report_routing_metrics.py
./scripts/run_experiments.sh
./src/routing_demo.sv
./tb/tb_routing_demo.sv
```

---

## 3. กำหนด Permission ให้สคริปต์

```bash
chmod +x scripts/*.sh
chmod +x scripts/*.py
```

ตรวจสอบ:

```bash
ls -l scripts
```

---

## 4. ตรวจสอบ PDK Environment

ตรวจสอบตัวแปร `PDK_ROOT`:

```bash
echo "$PDK_ROOT"
```

ค้นหา IHP SG13G2 PDK:

```bash
find "${PDK_ROOT:-$HOME/.ciel}" \
    -maxdepth 5 \
    -type d \
    -iname "*ihp*sg13g2*" \
    2>/dev/null | head -20
```

ตรวจสอบว่า LibreLane รู้จัก PDK:

```bash
librelane \
    --pdk ihp-sg13g2 \
    --version
```

ตรวจสอบ environment ด้วยสคริปต์ของ Lab:

```bash
make check
```

หรือรันโดยตรง:

```bash
./scripts/check_environment.sh
```

---

## 5. ตรวจสอบ `config.yaml`

แสดงไฟล์ configuration:

```bash
cat config.yaml
```

ตรวจสอบค่า PDK-specific routing layers:

```bash
grep -nE \
    'DESIGN_NAME|CLOCK_PORT|CLOCK_PERIOD|RT_MIN_LAYER|RT_MAX_LAYER|RT_CLOCK_MIN_LAYER|RT_CLOCK_MAX_LAYER' \
    config.yaml
```

ค่าหลักควรมีลักษณะดังนี้:

```yaml
DESIGN_NAME: routing_demo

CLOCK_PORT: clk
CLOCK_PERIOD: 20.0

RT_MIN_LAYER: Metal2
RT_MAX_LAYER: TopMetal2

RT_CLOCK_MIN_LAYER: Metal3
RT_CLOCK_MAX_LAYER: TopMetal2
```

ตรวจสอบค่า Global Routing:

```bash
grep -nE \
    'GRT_ADJUSTMENT|GRT_ALLOW_CONGESTION|GRT_OVERFLOW_ITERS|GRT_MACRO_EXTENSION' \
    config.yaml
```

ตรวจสอบค่า Detailed Routing:

```bash
grep -nE \
    'DRT_THREADS|DRT_OPT_ITERS|ERROR_ON_TR_DRC|ERROR_ON_DISCONNECTED_PINS' \
    config.yaml
```

---

## 6. ตรวจสอบ YAML Syntax

ใช้ Python:

```bash
python3 - <<'PY'
from pathlib import Path

try:
    import yaml
except ImportError:
    raise SystemExit(
        "PyYAML is not installed. Install it with: python3 -m pip install --user pyyaml"
    )

path = Path("config.yaml")

with path.open("r", encoding="utf-8") as file:
    config = yaml.safe_load(file)

print("YAML syntax: PASS")
print("DESIGN_NAME:", config.get("DESIGN_NAME"))
print("CLOCK_PORT:", config.get("CLOCK_PORT"))
print("CLOCK_PERIOD:", config.get("CLOCK_PERIOD"))
print("RT_MIN_LAYER:", config.get("RT_MIN_LAYER"))
print("RT_MAX_LAYER:", config.get("RT_MAX_LAYER"))
PY
```

หากไม่มี PyYAML:

```bash
python3 -m pip install --user pyyaml
```

จากนั้นตรวจใหม่:

```bash
make validate
```

---

## 7. ตรวจสอบ RTL Source

แสดง RTL:

```bash
sed -n '1,240p' src/routing_demo.sv
```

ตรวจ syntax และ lint ด้วย Verilator:

```bash
make lint
```

หรือรันโดยตรง:

```bash
verilator \
    --lint-only \
    --Wall \
    --Wno-fatal \
    --timing \
    src/routing_demo.sv \
    tb/tb_routing_demo.sv
```

ผลที่ต้องการ:

```text
ไม่มี %Error
```

ตรวจเฉพาะ synthesizable RTL:

```bash
verilator \
    --lint-only \
    --Wall \
    --Wno-fatal \
    src/routing_demo.sv
```

---

## 8. รัน RTL Simulation

```bash
make sim
```

หากต้องการล้างผล simulation ก่อน:

```bash
make sim-clean
make sim
```

หรือรันด้วย Verilator โดยตรง:

```bash
rm -rf obj_dir

verilator \
    --binary \
    --timing \
    --Wall \
    --Wno-fatal \
    --top-module tb_routing_demo \
    src/routing_demo.sv \
    tb/tb_routing_demo.sv

./obj_dir/Vtb_routing_demo
```

ผลที่ควรได้:

```text
PASS
```

หรือข้อความลักษณะ:

```text
PASS: routing_demo testbench completed successfully
```

---

## 9. ตรวจสอบ SDC Constraints

แสดง PnR constraints:

```bash
cat constraints/pnr.sdc
```

แสดง signoff constraints:

```bash
cat constraints/signoff.sdc
```

ตรวจ clock constraint:

```bash
grep -n "create_clock" constraints/*.sdc
```

ตรวจ input/output delay:

```bash
grep -nE \
    'set_input_delay|set_output_delay|set_clock_uncertainty|set_clock_transition|set_load' \
    constraints/*.sdc
```

ค่าหลักควรสอดคล้องกับ:

```text
Clock period       = 20.0 ns
Clock frequency    = 50 MHz
Clock uncertainty  = 0.25 ns
Clock transition   = 0.15 ns
Input delay        = 2.0 ns
Output delay       = 4.0 ns
```

---

## 10. ล้างผลการรันเดิม

```bash
make clean
```

หรือ:

```bash
rm -rf runs
rm -rf reports
rm -rf obj_dir
mkdir -p runs reports
```

---

# ส่วนที่ 1: Global Routing

## 11. รัน Flow ถึง Synthesis

```bash
make synth
```

คำสั่ง LibreLane โดยตรง:

```bash
librelane \
    -j 4 \
    --pdk ihp-sg13g2 \
    --run-tag lab09-ihp-synth \
    --to Yosys.Synthesis \
    config.yaml
```

ตรวจ run directory:

```bash
find runs -mindepth 1 -maxdepth 1 -type d | sort
```

ตรวจ synthesis log:

```bash
grep -RniE \
    'error|warning|cell|area|stat' \
    runs/lab09-ihp-synth \
    | head -100
```

---

## 12. รัน Flow ถึง Floorplan

```bash
librelane \
    -j 4 \
    --pdk ihp-sg13g2 \
    --run-tag lab09-ihp-floorplan \
    --to OpenROAD.Floorplan \
    config.yaml
```

ตรวจผล:

```bash
find runs/lab09-ihp-floorplan \
    -type f \
    \( -name "*.odb" -o -name "*.def" -o -name "*.log" \) \
    | sort
```

---

## 13. รัน Flow ถึง Placement

```bash
librelane \
    -j 4 \
    --pdk ihp-sg13g2 \
    --run-tag lab09-ihp-placement \
    --to OpenROAD.DetailedPlacement \
    config.yaml
```

ตรวจ placement reports:

```bash
grep -RniE \
    'utilization|density|overflow|placement|error|warning' \
    runs/lab09-ihp-placement \
    | head -200
```

---

## 14. รัน Flow ถึง Clock Tree Synthesis

```bash
librelane \
    -j 4 \
    --pdk ihp-sg13g2 \
    --run-tag lab09-ihp-cts \
    --to OpenROAD.CTS \
    config.yaml
```

ตรวจ CTS log:

```bash
grep -RniE \
    'clock|buffer|skew|latency|insertion|error|warning' \
    runs/lab09-ihp-cts \
    | head -200
```

---

## 15. รัน Global Routing

คำสั่งแนะนำ:

```bash
make grt
```

คำสั่ง LibreLane โดยตรง:

```bash
librelane \
    -j 4 \
    --pdk ihp-sg13g2 \
    --run-tag lab09-ihp-routing-grt \
    --to OpenROAD.GlobalRouting \
    config.yaml
```

กรณีต้องการใช้ CPU 8 threads:

```bash
make grt JOBS=8
```

หรือ:

```bash
librelane \
    -j 8 \
    --pdk ihp-sg13g2 \
    --run-tag lab09-ihp-routing-grt-j8 \
    --to OpenROAD.GlobalRouting \
    config.yaml
```

---

## 16. ตรวจสอบว่า Global Routing รันสำเร็จ

ตรวจ run directory:

```bash
ls -lah runs
```

กำหนดตัวแปร run directory:

```bash
GRT_RUN="runs/lab09-ihp-routing-grt"
```

ตรวจว่ามี directory:

```bash
test -d "$GRT_RUN" && echo "Global Routing run found"
```

ค้นหา Global Routing step:

```bash
find "$GRT_RUN" \
    -type d \
    -iname "*globalrouting*" \
    | sort
```

ค้นหาไฟล์ผลลัพธ์:

```bash
find "$GRT_RUN" \
    -type f \
    \( \
        -name "*.odb" \
        -o -name "*.def" \
        -o -name "*.log" \
        -o -name "*.rpt" \
        -o -name "metrics*.json" \
        -o -name "metrics*.csv" \
    \) \
    | sort
```

---

## 17. ตรวจ Global Routing Overflow

```bash
grep -RniE \
    'overflow|congestion|global route|global routing|routing congestion' \
    "$GRT_RUN" \
    | head -300
```

ตรวจเฉพาะ log:

```bash
find "$GRT_RUN" -type f -name "*.log" -print0 |
xargs -0 grep -niE \
    'overflow|congestion|wire length|wirelength|vias|unrouted'
```

ผลที่ต้องการ:

```text
Final overflow = 0
```

หรือ metric ที่สื่อว่าไม่มี unresolved congestion

---

## 18. ตรวจ Wire Length และ Via Count

```bash
grep -RniE \
    'wire.?length|total wire|via count|total vias' \
    "$GRT_RUN" \
    | head -200
```

---

## 19. ตรวจ Antenna หลัง Global Routing

```bash
grep -RniE \
    'antenna|diode|jumper' \
    "$GRT_RUN" \
    | head -200
```

---

## 20. สรุปรายงาน Global Routing

```bash
make reports
```

หรือ:

```bash
./scripts/find_routing_reports.sh
```

สรุป metrics:

```bash
make metrics
```

หรือ:

```bash
python3 scripts/report_routing_metrics.py
```

---

# ส่วนที่ 2: Detailed Routing

## 21. รัน Detailed Routing

คำสั่งแนะนำ:

```bash
make drt
```

คำสั่ง LibreLane โดยตรง:

```bash
librelane \
    -j 4 \
    --pdk ihp-sg13g2 \
    --run-tag lab09-ihp-routing-drt \
    --to OpenROAD.DetailedRouting \
    config.yaml
```

ใช้ 8 threads:

```bash
make drt JOBS=8
```

หรือ:

```bash
librelane \
    -j 8 \
    --pdk ihp-sg13g2 \
    --run-tag lab09-ihp-routing-drt-j8 \
    --to OpenROAD.DetailedRouting \
    config.yaml
```

---

## 22. ตรวจ Detailed Routing Run

```bash
DRT_RUN="runs/lab09-ihp-routing-drt"
```

ตรวจ directory:

```bash
test -d "$DRT_RUN" && echo "Detailed Routing run found"
```

ค้นหา Detailed Routing step:

```bash
find "$DRT_RUN" \
    -type d \
    -iname "*detailedrouting*" \
    | sort
```

ค้นหา routed database:

```bash
find "$DRT_RUN" \
    -type f \
    \( -name "*.odb" -o -name "*.def" \) \
    | sort
```

---

## 23. ตรวจ Routing DRC

```bash
grep -RniE \
    'route__drc|routing drc|drc violation|violations' \
    "$DRT_RUN" \
    | head -300
```

ตรวจ Detailed Router log:

```bash
find "$DRT_RUN" -type f -name "*.log" -print0 |
xargs -0 grep -niE \
    'drc|violation|short|spacing|minimum area|enclosure'
```

ผลที่ต้องการ:

```text
Routing DRC errors = 0
```

---

## 24. ตรวจ Unrouted Nets

```bash
grep -RniE \
    'unrouted|failed to route|not routed' \
    "$DRT_RUN" \
    | head -200
```

ผลที่ต้องการ:

```text
Unrouted nets = 0
```

---

## 25. ตรวจ Disconnected Pins

```bash
grep -RniE \
    'disconnected|open pin|open net|connectivity' \
    "$DRT_RUN" \
    | head -200
```

ผลที่ต้องการ:

```text
Critical disconnected pins = 0
```

---

## 26. ตรวจ Short Circuits

```bash
grep -RniE \
    'short circuit|shorted|shorts' \
    "$DRT_RUN" \
    | head -200
```

ผลที่ต้องการ:

```text
Short circuits = 0
```

---

## 27. ตรวจ Pin Access

```bash
grep -RniE \
    'pin access|access point|no access|failed.*pin' \
    "$DRT_RUN" \
    | head -200
```

ไม่ควรพบ fatal pin-access failure

---

## 28. ตรวจจำนวน Detailed Routing Iterations

```bash
grep -RniE \
    'iteration|search and repair|optimization' \
    "$DRT_RUN" \
    | head -300
```

---

## 29. ตรวจ Antenna หลัง Detailed Routing

```bash
grep -RniE \
    'antenna|jumper|diode|repair' \
    "$DRT_RUN" \
    | head -300
```

---

## 30. ตรวจ Routing Metrics

```bash
make metrics
```

หรือระบุ run โดยค้นหา metrics:

```bash
find "$DRT_RUN" \
    -type f \
    \( -name "metrics*.json" -o -name "metrics*.csv" \) \
    | sort
```

แสดง JSON metrics:

```bash
find "$DRT_RUN" \
    -type f \
    -name "metrics*.json" \
    -exec sh -c '
        echo "================================================"
        echo "$1"
        python3 -m json.tool "$1"
    ' sh {} \;
```

---

# ส่วนที่ 3: รัน RTL-to-GDSII ครบ Flow

## 31. ล้างผลเดิมก่อน Full Flow

```bash
make clean
```

---

## 32. รัน Full Classic Flow

```bash
make run
```

คำสั่ง LibreLane โดยตรง:

```bash
librelane \
    -j 4 \
    --pdk ihp-sg13g2 \
    --run-tag lab09-ihp-routing-full \
    config.yaml
```

ใช้ 8 threads:

```bash
make run JOBS=8
```

หรือ:

```bash
librelane \
    -j 8 \
    --pdk ihp-sg13g2 \
    --run-tag lab09-ihp-routing-full-j8 \
    config.yaml
```

---

## 33. ตรวจสถานะ Full Flow

```bash
FULL_RUN="runs/lab09-ihp-routing-full"
```

ตรวจ error:

```bash
grep -RniE \
    '(^|[^a-z])error([^a-z]|$)|fatal|traceback|failed' \
    "$FULL_RUN" \
    | head -300
```

ตรวจ warnings:

```bash
grep -RniE \
    'warning|warn' \
    "$FULL_RUN" \
    | head -300
```

---

## 34. ตรวจ GDSII

```bash
find "$FULL_RUN" \
    -type f \
    \( -name "*.gds" -o -name "*.gdsii" \) \
    | sort
```

กำหนด GDS ล่าสุด:

```bash
GDS_FILE=$(
    find "$FULL_RUN" \
        -type f \
        \( -name "*.gds" -o -name "*.gdsii" \) \
        | sort \
        | tail -1
)

echo "$GDS_FILE"
```

---

## 35. ตรวจ DEF และ ODB Final

```bash
find "$FULL_RUN" \
    -type f \
    \( -name "*.def" -o -name "*.odb" \) \
    | sort \
    | tail -20
```

---

## 36. ตรวจ SPEF

```bash
find "$FULL_RUN" \
    -type f \
    \( -name "*.spef" -o -name "*.spef.gz" \) \
    | sort
```

---

## 37. ตรวจ Gate-Level Netlist

```bash
find "$FULL_RUN" \
    -type f \
    \( -name "*.v" -o -name "*.nl.v" \) \
    | sort \
    | tail -20
```

---

## 38. ตรวจ Post-Route Timing

```bash
grep -RniE \
    'setup|hold|wns|tns|slack|timing violation' \
    "$FULL_RUN" \
    | head -400
```

ตรวจ setup:

```bash
grep -RniE \
    'setup.*wns|setup.*tns|setup violation' \
    "$FULL_RUN" \
    | head -100
```

ตรวจ hold:

```bash
grep -RniE \
    'hold.*wns|hold.*tns|hold violation' \
    "$FULL_RUN" \
    | head -100
```

---

## 39. ตรวจ Maximum Transition และ Capacitance

```bash
grep -RniE \
    'max.*slew|max.*transition|max.*capacitance|electrical violation' \
    "$FULL_RUN" \
    | head -200
```

---

## 40. ตรวจ DRC

ตรวจ KLayout DRC:

```bash
grep -RniE \
    'klayout.*drc|drc violations|drc errors' \
    "$FULL_RUN" \
    | head -300
```

ตรวจ Magic DRC:

```bash
grep -RniE \
    'magic.*drc|total drc' \
    "$FULL_RUN" \
    | head -300
```

ค้นหา DRC reports:

```bash
find "$FULL_RUN" \
    -type f \
    \( \
        -iname "*drc*.rpt" \
        -o -iname "*drc*.xml" \
        -o -iname "*drc*.lyrdb" \
        -o -iname "*drc*.log" \
    \) \
    | sort
```

---

## 41. ตรวจ LVS

```bash
grep -RniE \
    'lvs|netlists match|mismatch|property errors' \
    "$FULL_RUN" \
    | head -300
```

ผลที่ต้องการ:

```text
Netlists match
```

---

## 42. ตรวจ Antenna Signoff

```bash
grep -RniE \
    'antenna.*violation|antenna.*error|antenna.*pass' \
    "$FULL_RUN" \
    | head -300
```

---

# ส่วนที่ 4: เปิดผลด้วย GUI

## 43. เปิดผลล่าสุดใน OpenROAD GUI

```bash
make gui
```

หาก Makefile รองรับการระบุ run tag:

```bash
make gui RUN_TAG=lab09-ihp-routing-full
```

---

## 44. เปิด ODB ด้วย OpenROAD โดยตรง

ค้นหา ODB ล่าสุด:

```bash
ODB_FILE=$(
    find "$FULL_RUN" \
        -type f \
        -name "*.odb" \
        | sort \
        | tail -1
)

echo "$ODB_FILE"
```

เปิด OpenROAD GUI:

```bash
openroad -gui
```

ใน OpenROAD Tcl console:

```tcl
read_db /absolute/path/to/final.odb
```

สามารถหา absolute path ด้วย:

```bash
realpath "$ODB_FILE"
```

---

## 45. เปิด GDS ด้วย KLayout

```bash
klayout "$GDS_FILE"
```

หรือ:

```bash
klayout "$(realpath "$GDS_FILE")"
```

---

# ส่วนที่ 5: เก็บและสรุปรายงาน

## 46. ค้นหารายงาน Routing ทั้งหมด

```bash
make reports
```

หรือ:

```bash
./scripts/find_routing_reports.sh
```

---

## 47. สรุป Metrics

```bash
make metrics
```

หรือ:

```bash
python3 scripts/report_routing_metrics.py
```

---

## 48. Archive รายงานล่าสุด

```bash
make archive
```

หรือ:

```bash
./scripts/archive_latest_reports.sh
```

ตรวจ archive:

```bash
find reports -maxdepth 3 -type f | sort
```

---

## 49. สร้างไฟล์ Log Summary

```bash
mkdir -p reports/manual-summary
```

สรุป routing errors:

```bash
grep -RniE \
    'overflow|congestion|route__drc|unrouted|disconnected|antenna|setup|hold' \
    "$FULL_RUN" \
    > reports/manual-summary/routing_summary.txt
```

เปิดอ่าน:

```bash
less reports/manual-summary/routing_summary.txt
```

---

# ส่วนที่ 6: การทดลอง Global Routing Adjustment

## 50. รันชุดการทดลองอัตโนมัติ

```bash
make experiments
```

หรือ:

```bash
./scripts/run_experiments.sh
```

กำหนด threads:

```bash
JOBS=8 ./scripts/run_experiments.sh
```

---

## 51. ตรวจ Run Tags ของการทดลอง

```bash
find runs \
    -mindepth 1 \
    -maxdepth 1 \
    -type d \
    -iname "*adjust*" \
    | sort
```

---

## 52. เปรียบเทียบ Overflow

```bash
for run in runs/*adjust*; do
    echo "================================================"
    echo "$run"

    grep -RhiE \
        'final overflow|total overflow|routing congestion' \
        "$run" \
        | tail -10
done
```

---

## 53. เปรียบเทียบ Wire Length

```bash
for run in runs/*adjust*; do
    echo "================================================"
    echo "$run"

    grep -RhiE \
        'total wire.?length|wire.?length' \
        "$run" \
        | tail -10
done
```

---

## 54. เปรียบเทียบ Routing DRC

```bash
for run in runs/*adjust*; do
    echo "================================================"
    echo "$run"

    grep -RhiE \
        'route__drc|routing drc|drc violations' \
        "$run" \
        | tail -10
done
```

---

# ส่วนที่ 7: การทดลองด้วยไฟล์ Configuration แยก

## 55. สร้าง Configuration สำหรับ `GRT_ADJUSTMENT = 0.20`

```bash
cp config.yaml config_grt_adjust_020.yaml
```

แก้ค่า:

```bash
python3 - <<'PY'
from pathlib import Path

path = Path("config_grt_adjust_020.yaml")
text = path.read_text(encoding="utf-8")
text = text.replace(
    "GRT_ADJUSTMENT: 0.30",
    "GRT_ADJUSTMENT: 0.20",
)
path.write_text(text, encoding="utf-8")
PY
```

รัน:

```bash
librelane \
    -j 4 \
    --pdk ihp-sg13g2 \
    --run-tag lab09-ihp-adjust-020 \
    --to OpenROAD.DetailedRouting \
    config_grt_adjust_020.yaml
```

---

## 56. สร้าง Configuration สำหรับ `GRT_ADJUSTMENT = 0.45`

```bash
cp config.yaml config_grt_adjust_045.yaml
```

แก้ค่า:

```bash
python3 - <<'PY'
from pathlib import Path

path = Path("config_grt_adjust_045.yaml")
text = path.read_text(encoding="utf-8")
text = text.replace(
    "GRT_ADJUSTMENT: 0.30",
    "GRT_ADJUSTMENT: 0.45",
)
path.write_text(text, encoding="utf-8")
PY
```

รัน:

```bash
librelane \
    -j 4 \
    --pdk ihp-sg13g2 \
    --run-tag lab09-ihp-adjust-045 \
    --to OpenROAD.DetailedRouting \
    config_grt_adjust_045.yaml
```

---

## 57. เปรียบเทียบผลทั้งสามค่า

```bash
for run in \
    runs/lab09-ihp-adjust-020 \
    runs/lab09-ihp-routing-drt \
    runs/lab09-ihp-adjust-045
do
    echo
    echo "================================================"
    echo "RUN: $run"
    echo "================================================"

    grep -RhiE \
        'overflow|route__drc|routing drc|wire.?length|total vias|unrouted|disconnected' \
        "$run" \
        | tail -30
done
```

---

# ส่วนที่ 8: Debug Detailed Routing

## 58. สร้าง Debug Configuration

```bash
cp config.yaml config_drt_debug.yaml
```

แก้ค่า:

```bash
python3 - <<'PY'
from pathlib import Path

path = Path("config_drt_debug.yaml")
text = path.read_text(encoding="utf-8")

text = text.replace(
    "DRT_OPT_ITERS: 64",
    "DRT_OPT_ITERS: 16",
)

text = text.replace(
    "DRT_SAVE_SNAPSHOTS: false",
    "DRT_SAVE_SNAPSHOTS: true",
)

text = text.replace(
    "DRT_SAVE_DRC_REPORT_ITERS: null",
    "DRT_SAVE_DRC_REPORT_ITERS: 1",
)

path.write_text(text, encoding="utf-8")
PY
```

ตรวจไฟล์:

```bash
grep -nE \
    'DRT_OPT_ITERS|DRT_SAVE_SNAPSHOTS|DRT_SAVE_DRC_REPORT_ITERS' \
    config_drt_debug.yaml
```

---

## 59. รัน Detailed Routing Debug

```bash
librelane \
    -j 4 \
    --pdk ihp-sg13g2 \
    --run-tag lab09-ihp-drt-debug \
    --to OpenROAD.DetailedRouting \
    config_drt_debug.yaml
```

---

## 60. ตรวจ DRC ต่อ Iteration

```bash
grep -RniE \
    'iteration|drc violations|markers|search and repair' \
    runs/lab09-ihp-drt-debug \
    | head -500
```

ค้นหา snapshot:

```bash
find runs/lab09-ihp-drt-debug \
    -type f \
    \( -name "*.odb" -o -name "*drc*.rpt" \) \
    | sort
```

---

# ส่วนที่ 9: ตรวจรับผล Lab

## 61. รันคำสั่งตรวจผลทั้งหมด

```bash
make metrics
make reports
make archive
```

ตรวจ checklist:

```bash
cat docs/lab09_checklist.md
```

---

## 62. เกณฑ์ผลลัพธ์ที่ต้องผ่าน

ตรวจ Global Routing overflow:

```bash
grep -RniE \
    'final overflow|total overflow' \
    runs/lab09-ihp-routing-full \
    | tail -20
```

ตรวจ Routing DRC:

```bash
grep -RniE \
    'route__drc_errors|routing drc errors' \
    runs/lab09-ihp-routing-full \
    | tail -20
```

ตรวจ disconnected pins:

```bash
grep -RniE \
    'disconnected pins|critical disconnected' \
    runs/lab09-ihp-routing-full \
    | tail -20
```

ตรวจ unrouted nets:

```bash
grep -RniE \
    'unrouted nets|failed to route' \
    runs/lab09-ihp-routing-full \
    | tail -20
```

ค่าที่ต้องการ:

```text
Global-routing overflow       = 0
Routing DRC errors            = 0
Critical disconnected pins   = 0
Unrouted signal nets          = 0
Short circuits               = 0
Open circuits                = 0
```

---

# ชุดคำสั่งแบบย่อสำหรับรันต่อเนื่อง

กรณีต้องการรัน Lab ตั้งแต่ต้นจนจบ:

```bash
unzip lab09_global_detailed_routing_ihp_sg13g2.zip
cd lab09_global_detailed_routing_ihp_sg13g2

chmod +x scripts/*.sh
chmod +x scripts/*.py

make check
make validate
make lint
make sim

make clean
make grt JOBS=4
make metrics
make reports

make drt JOBS=4
make metrics
make reports

make clean
make run JOBS=4
make metrics
make reports
make archive
make gui
```

---

# ชุดคำสั่ง LibreLane โดยตรงแบบย่อ

Global Routing:

```bash
librelane \
    -j 4 \
    --pdk ihp-sg13g2 \
    --run-tag lab09-ihp-routing-grt \
    --to OpenROAD.GlobalRouting \
    config.yaml
```

Detailed Routing:

```bash
librelane \
    -j 4 \
    --pdk ihp-sg13g2 \
    --run-tag lab09-ihp-routing-drt \
    --to OpenROAD.DetailedRouting \
    config.yaml
```

Full RTL-to-GDSII:

```bash
librelane \
    -j 4 \
    --pdk ihp-sg13g2 \
    --run-tag lab09-ihp-routing-full \
    config.yaml
```

---

# คำสั่งล้างผลทั้งหมด

```bash
make clean
```

หรือล้างด้วยตนเอง:

```bash
rm -rf runs
rm -rf reports
rm -rf obj_dir
rm -f config_grt_adjust_020.yaml
rm -f config_grt_adjust_045.yaml
rm -f config_drt_debug.yaml

mkdir -p runs reports
```

ไฟล์ชุดทดลองที่ใช้กับคำสั่งเหล่านี้: [ดาวน์โหลด Lab 9 สำหรับ IHP SG13G2](sandbox:/mnt/data/lab09_global_detailed_routing_ihp_sg13g2.zip)
