# Lab 9 — Global and Detailed Routing with LibreLane

ชุดทดลองนี้ใช้ `sky130A` เป็นค่าเริ่มต้น และใช้ LibreLane `Classic` flow พร้อมไฟล์กำหนดค่า YAML

## โครงสร้าง

```text
lab09_global_detailed_routing/
├── config.yaml
├── Makefile
├── README.md
├── src/routing_demo.sv
├── tb/tb_routing_demo.sv
├── constraints/pnr.sdc
├── constraints/signoff.sdc
├── scripts/
│   ├── check_environment.sh
│   ├── find_routing_reports.sh
│   ├── report_routing_metrics.py
│   ├── archive_latest_reports.sh
│   └── run_experiments.sh
└── docs/lab09_checklist.md
```

## เริ่มใช้งาน

เข้าสู่ shell ที่ติดตั้ง LibreLane และ PDK แล้ว:

```bash
cd lab09_global_detailed_routing
make check
make lint
make sim
```

รันถึง Global Routing:

```bash
make grt
```

รันถึง Detailed Routing:

```bash
make drt
```

รัน RTL-to-GDSII ครบ flow:

```bash
make run
```

เปิดผลล่าสุดใน OpenROAD GUI:

```bash
make gui
```

สรุป metrics และค้นหารายงาน:

```bash
make metrics
make reports
```

## คำสั่งโดยตรง

```bash
librelane -j 4 --pdk sky130A --run-tag lab09-grt \
  --to OpenROAD.GlobalRouting config.yaml

librelane -j 4 --pdk sky130A --run-tag lab09-drt \
  --to OpenROAD.DetailedRouting config.yaml

librelane -j 4 --pdk sky130A --run-tag lab09-full config.yaml
```

## การทดลอง congestion

สำรอง `config.yaml` แล้วเปลี่ยนทีละตัวแปร เช่น:

```yaml
FP_CORE_UTIL: 60
PL_TARGET_DENSITY_PCT: 70
GRT_ADJUSTMENT: 0.45
RT_MAX_LAYER: met4
```

หรือใช้สคริปต์ทดลองค่า `GRT_ADJUSTMENT`:

```bash
./scripts/run_experiments.sh
```

## Acceptance criteria

- Global-route overflow เท่ากับ 0
- Detailed-routing DRC เท่ากับ 0
- ไม่มี unrouted nets
- ไม่มี disconnected pins
- ตรวจ setup/hold timing หลัง route
- ตรวจ antenna, KLayout/Magic DRC และ LVS ใน full flow

## หมายเหตุ PDK

`RT_MIN_LAYER`, `RT_MAX_LAYER` และชื่อชั้น clock routing ในไฟล์นี้เป็นชื่อของ `sky130A` หากเปลี่ยน PDK ต้องเปลี่ยนชื่อ layer ให้ตรงกับ technology LEF หรือใช้ค่า default ของ PDK โดยลบบรรทัด `RT_*_LAYER` ออก
