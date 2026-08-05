# Lab 9 — Global and Detailed Routing with LibreLane
## IHP SG13G2 PDK Edition

ชุดนี้เป็น block-level RTL-to-GDSII lab สำหรับศึกษา FastRoute และ TritonRoute บน PDK `ihp-sg13g2` โดยใช้ `config.yaml` และ LibreLane `Classic` flow

## Routing stack ที่ใช้

```text
Metal1       local rail / low-level metal
Metal2       signal-routing minimum
Metal3
Metal4
Metal5
TopMetal1
TopMetal2    signal-routing maximum
```

`config.yaml` กำหนด clock routing เป็น `Metal3` ถึง `TopMetal2` และไม่ override cell names ของ CTS เพื่อให้ใช้ค่าที่มาจาก PDK configuration โดยตรง

## โครงสร้าง

```text
lab09_global_detailed_routing_ihp_sg13g2/
├── config.yaml
├── Makefile
├── README.md
├── src/routing_demo.sv
├── tb/tb_routing_demo.sv
├── constraints/
│   ├── pnr.sdc
│   └── signoff.sdc
├── scripts/
│   ├── check_environment.sh
│   ├── find_routing_reports.sh
│   ├── report_routing_metrics.py
│   ├── archive_latest_reports.sh
│   └── run_experiments.sh
└── docs/lab09_checklist.md
```

## 1. เข้าสู่ LibreLane environment

ใช้ Nix shell หรือ Docker environment ที่มี LibreLane และ `ihp-sg13g2` PDK จากนั้น:

```bash
cd lab09_global_detailed_routing_ihp_sg13g2
make check
make validate
```

`make validate` รันถึง `Verilator.Lint` เพื่อยืนยันว่า LibreLane โหลด YAML และ PDK ได้

## 2. RTL verification

```bash
make lint
make sim
```

ผล simulation ที่คาดหวัง:

```text
PASS: tb_routing_demo completed successfully
```

## 3. Global Routing

```bash
make grt
```

คำสั่งตรง:

```bash
librelane -j 4 --pdk ihp-sg13g2 \
  --run-tag lab09-ihp-routing-grt \
  --to OpenROAD.GlobalRouting config.yaml
```

## 4. Detailed Routing

```bash
make drt
```

คำสั่งตรง:

```bash
librelane -j 4 --pdk ihp-sg13g2 \
  --run-tag lab09-ihp-routing-drt \
  --to OpenROAD.DetailedRouting config.yaml
```

## 5. Full RTL-to-GDSII

```bash
make run
```

หรือ:

```bash
librelane -j 4 --pdk ihp-sg13g2 \
  --run-tag lab09-ihp-routing-full config.yaml
```

## 6. ตรวจผล

```bash
make metrics
make reports
make archive
make gui
```

ค้นหา routing errors โดยตรง:

```bash
grep -RniE 'overflow|congestion|drc|unrouted|disconnected|antenna' runs | less
```

## 7. Congestion experiments

```bash
make experiments
```

สคริปต์จะทดลอง `GRT_ADJUSTMENT` เท่ากับ `0.20`, `0.30`, `0.45` และรันถึง Detailed Routing

ตัวแปรที่แนะนำให้ทดลองเพิ่มเติม:

```yaml
FP_CORE_UTIL: 55
PL_TARGET_DENSITY_PCT: 62
RT_MAX_LAYER: TopMetal1
DRT_OPT_ITERS: 96
```

เปลี่ยนทีละตัวแปรและใช้ run tag ต่างกันเสมอ

## Acceptance criteria

- Global-routing overflow = 0
- Detailed-routing DRC = 0
- Unrouted nets = 0
- Disconnected pins = 0
- ไม่มี fatal pin-access failure
- Setup/Hold timing อยู่ในเงื่อนไขของ lab
- Full flow ตรวจ antenna, DRC และ LVS สำเร็จ

## หมายเหตุ

IHP SG13G2 เป็น PDK ที่มีการพัฒนาอย่างต่อเนื่อง ควรใช้ LibreLane revision และ PDK revision ที่เข้าคู่กัน หากคำสั่ง `make validate` แจ้งว่าไม่พบ PDK ให้ติดตั้ง/enable revision ตาม environment ของ workshop ก่อน ไม่ควรเปลี่ยน `PDK` เป็นชื่อ library เช่น `sg13g2_stdcell`
