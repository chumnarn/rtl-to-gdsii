# Lab 10 — Physical Verification: DRC and LVS  
## LibreLane + IHP SG13G2 PDK

โปรเจกต์นี้เป็นชุดโค้ดพร้อมรันสำหรับศึกษาการตรวจสอบ Physical Verification
ของวงจร counter 8 บิต โดยใช้ LibreLane Classic Flow และ PDK `ihp-sg13g2`

## โครงสร้าง

```text
lab10_physical_verification_ihp_sg13g2/
├── config.yaml
├── Makefile
├── pin_order.cfg
├── src/
│   └── counter.sv
├── tb/
│   └── tb_counter.sv
├── constraints/
│   ├── pnr.sdc
│   └── signoff.sdc
└── scripts/
    ├── check_project.py
    ├── check_ihp_environment.sh
    ├── find_reports.sh
    └── pv_summary.py
```

## 1. เข้า LibreLane environment

ใช้ LibreLane environment ที่มี PDK `ihp-sg13g2` ติดตั้งแล้ว เช่น
Nix environment ของ LibreLane หรือ container ที่รองรับ IHP Open PDK

ตรวจสอบ:

```bash
make env
```

## 2. ตรวจไฟล์และ RTL

```bash
make check
make lint
make sim
```

ผล simulation ที่คาดหวัง:

```text
PASS: counter RTL simulation completed successfully.
```

## 3. รัน RTL-to-GDSII

```bash
make run
```

คำสั่งที่ Makefile เรียก:

```bash
librelane --pdk ihp-sg13g2 config.yaml
```

ไม่จำเป็นต้องกำหนด `STD_CELL_LIBRARY` ในไฟล์ Lab เพราะให้ PDK configuration
เลือก SG13G2 standard-cell library ที่เข้ากับ revision ที่ติดตั้ง

## 4. ตรวจ DRC และ LVS

```bash
make reports
make pv-summary
```

ตรวจแบบ strict:

```bash
make pv-check
```

สคริปต์รองรับชื่อขั้น LVS สองแบบ:

- `*-klayout-lvs` — LibreLane รุ่นใหม่ที่มี KLayout LVS สำหรับ IHP SG13G2
- `*-netgen-lvs` — flow/environment รุ่นก่อนหรือแบบทางเลือก

ผลเป้าหมาย:

```text
Magic DRC count     : 0
KLayout DRC count   : 0
LVS result          : PASS
CORE PV STATUS      : PASS
```

## 5. เปิด GDS

```bash
make open-gds
```

## หมายเหตุเฉพาะ IHP SG13G2

1. ไม่กำหนด CTS buffer cell เอง เพราะชื่อเซลล์ที่ใช้ได้ขึ้นกับ PDK/SCL revision
2. ไม่กำหนด routing layers เอง เพราะ PDK configuration มีค่าเทคโนโลยีที่เหมาะสม
3. IHP Open PDK ยังมีสถานะ preview จึงควรบันทึก LibreLane และ PDK revision
   ทุกครั้งที่จัดทำรายงาน
4. ถ้า Magic DRC กับ KLayout DRC ให้จำนวนต่างกัน ให้ตรวจ rule deck,
   layer mapping และรายงานทั้งสองชุด ไม่ควรลบหรือ waive โดยไม่มีเหตุผล
5. DRC/LVS clean ยังไม่แทน timing, antenna, density และ power-integrity signoff

## ล้างผลลัพธ์

```bash
make clean
make distclean
```
