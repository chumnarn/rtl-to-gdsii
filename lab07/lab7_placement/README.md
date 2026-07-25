# Lab 7: Placement Optimization with LibreLane

ชุดทดลองนี้ใช้ SKY130A PDK และ `sky130_fd_sc_hd` standard-cell library เพื่อศึกษา
Global Placement, Detailed Placement และผลของ core utilization/target density
ต่อคุณภาพการวางเซลล์

## สิ่งที่ต้องมี

- Linux, WSL2 หรือ LibreLane container
- LibreLane ที่เรียกด้วยคำสั่ง `librelane`
- SKY130A PDK
- Python 3 (สคริปต์ทดลองใช้เฉพาะ Python standard library)

ตรวจสอบเบื้องต้น:

```bash
librelane --version
python3 --version
```

## รัน Baseline

จากโฟลเดอร์ `lab7_placement`:

```bash
chmod +x scripts/*.sh
./scripts/run_baseline.sh
```

สคริปต์หยุดที่ `OpenROAD.DetailedPlacement` เพื่อให้โฟกัสที่เนื้อหา Lab 7

## รันชุดทดลอง

```bash
./scripts/run_low_density.sh
./scripts/run_balanced.sh
./scripts/run_high_density.sh
```

| Run | FP_CORE_UTIL | PL_TARGET_DENSITY_PCT | Run tag |
|---|---:|---:|---|
| Baseline | 45 | 60 | `lab7_baseline` |
| Low density | 35 | 50 | `lab7_low_density` |
| Balanced | 45 | 58 | `lab7_balanced` |
| High density | 60 | 72 | `lab7_high_density` |

สคริปต์ทดลองสร้าง YAML ชั่วคราวโดยไม่แก้ไข `config.yaml` ต้นฉบับ และลบไฟล์ชั่วคราว
อัตโนมัติเมื่อจบงาน

## รันคำสั่ง LibreLane โดยตรง

```bash
librelane --run-tag lab7_baseline \
  --to OpenROAD.DetailedPlacement \
  config.yaml
```

หากต้องการรัน Classic Flow จนจบ:

```bash
librelane --run-tag lab7_full_flow config.yaml
```

หาก PDK อยู่ในตำแหน่งที่ติดตั้งเอง ให้ส่ง `--pdk-root` ตามการติดตั้ง LibreLane
ของเครื่อง เช่น:

```bash
librelane --pdk-root /path/to/pdks \
  --run-tag lab7_baseline \
  --to OpenROAD.DetailedPlacement \
  config.yaml
```

## ตรวจผล

ผลจะอยู่ใต้ `runs/<run-tag>/` ค้นหาไฟล์สำคัญได้ด้วย:

```bash
find runs/lab7_baseline -type f \
  \( -name '*.odb' -o -name '*.def' -o -name 'metrics.json' \) \
  | sort
```

ค้นหาข้อมูล placement:

```bash
grep -RniE 'HPWL|density|overflow|legal|overlap|wirelength|slack' \
  runs/lab7_baseline | head -n 100
```

ควรตรวจสอบ:

- Detailed Placement สำเร็จและ placement legal
- ไม่มี unplaced instance หรือ overlapping cell
- HPWL/estimated wirelength
- setup WNS/TNS
- density hotspot และพื้นที่ว่างสำหรับ CTS
- ความแตกต่างระหว่าง low, balanced, baseline และ high density

บันทึกตารางสรุปหรือภาพหน้าจอในโฟลเดอร์ `reports/`

## หมายเหตุ

ชื่อ step และรูปแบบ log อาจต่างเล็กน้อยตาม LibreLane/OpenROAD version
แต่ run scripts ใช้ชื่อ step `OpenROAD.DetailedPlacement` ของ Classic Flow
