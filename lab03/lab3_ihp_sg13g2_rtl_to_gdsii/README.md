# Lab 3 — First RTL-to-GDSII Implementation

ชุดทดลองพร้อมรันสำหรับ **LibreLane Classic Flow** และ **IHP SG13G2 OpenPDK** โดยใช้ `config.yaml`

## โครงสร้างไฟล์

```text
lab3_ihp_sg13g2_rtl_to_gdsii/
├── config.yaml
├── pin_order.cfg
├── Makefile
├── README.md
├── rtl/counter.sv
├── tb/tb_counter.sv
├── scripts/synth.ys
├── scripts/preflight.sh
├── scripts/check_results.py
├── build/
└── waves/
```

## 1. เตรียม LibreLane environment

ใช้ environment จาก repository ของ workshop หรือ LibreLane installation ที่รองรับ Nix:

```bash
nix-shell
cd lab3_ihp_sg13g2_rtl_to_gdsii
make tools
```

หากเครื่องมี RAM จำกัด ให้คง `JOBS=1` ซึ่งเป็นค่าเริ่มต้นของ Lab นี้

## 2. ตรวจสอบ RTL

```bash
make lint
make sim
make synth
```

หรือรันทั้งหมด:

```bash
make all
```

ผล simulation ที่คาดหวัง:

```text
PASS: self-checking counter simulation completed
```

เปิด waveform:

```bash
make wave
```

## 3. ตรวจ configuration อย่างรวดเร็ว

```bash
make check-config
```

คำสั่งนี้ให้ LibreLane เริ่มเฉพาะขั้น Verilator lint เพื่อยืนยันว่า PDK และ configuration อ่านได้

## 4. รัน RTL-to-GDSII

```bash
make pnr
```

คำสั่งเต็ม:

```bash
librelane -j 1 --pdk ihp-sg13g2 --flow Classic config.yaml
```

ใช้ CPU หลาย process ได้ เช่น:

```bash
make pnr JOBS=4
```

LibreLane จะสร้างผลลัพธ์ใน:

```text
runs/RUN_<date>_<time>/
```

ผลลัพธ์สุดท้ายอยู่ใต้:

```text
runs/RUN_<date>_<time>/final/
```

## 5. ตรวจผลลัพธ์

```bash
make reports
```

ตรวจโดยตรง:

```bash
LATEST_RUN=$(ls -1dt runs/* | head -1)
echo "$LATEST_RUN"
find "$LATEST_RUN/final" -maxdepth 2 -type f | sort
cat "$LATEST_RUN/final/metrics.csv"
```

ค้นหา STA summary:

```bash
find "$LATEST_RUN" -path '*openroad-stapostpnr*' -name summary.rpt -print
```

ค้นหา DRC/LVS/Antenna reports:

```bash
find "$LATEST_RUN" -type f \
  \( -iname '*drc*' -o -iname '*lvs*' -o -iname '*antenna*' \) | sort
```

## 6. เปิด Layout GUI

OpenROAD:

```bash
make openroad
```

KLayout:

```bash
make klayout
```

คำสั่งเต็ม:

```bash
librelane --pdk ihp-sg13g2 --last-run \
  --flow OpenInOpenROAD config.yaml

librelane --pdk ihp-sg13g2 --last-run \
  --flow OpenInKLayout config.yaml
```

## 7. Resume flow

เมื่อ run ถูกหยุดและต้องการทำต่อจาก run ล่าสุด:

```bash
make pnr-resume
```

หาก failure เกิดจาก RTL หรือ configuration ต้องแก้สาเหตุก่อน แล้วเริ่ม run ใหม่เพื่อให้ผลลัพธ์ชัดเจน

## 8. ไฟล์สำคัญ

- `config.yaml` — LibreLane configuration สำหรับ `ihp-sg13g2`
- `pin_order.cfg` — กำหนด clock/reset/enable ทางตะวันออก และ output bus ทางตะวันตก
- `rtl/counter.sv` — RTL แบบ parameterized 8-bit counter
- `tb/tb_counter.sv` — self-checking testbench
- `scripts/check_results.py` — สรุป GDSII, ODB, DEF, SPEF, SDF, STA และ metrics

## 9. เกณฑ์ตรวจรับเบื้องต้น

- RTL lint และ simulation ผ่าน
- Yosys ไม่มี unmapped RTL construct
- LibreLane แสดง `Flow complete.`
- พบ GDSII, DEF/ODB, netlist, SPEF/SDF และ metrics
- ไม่มี unrouted nets
- ตรวจ setup/hold slack จาก `OpenROAD.STAPostPNR`
- ตรวจ DRC, LVS และ antenna reports ตาม steps ที่ PDK/flow เปิดใช้งาน

## 10. ทำความสะอาด

```bash
make clean
```

ลบ runs ทั้งหมด:

```bash
make clean-runs
```

คำสั่งหลังจะลบผล PnR ทุก run ภายใน Lab นี้
