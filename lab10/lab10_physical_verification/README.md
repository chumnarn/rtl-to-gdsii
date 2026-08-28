# Lab 10 — Physical Verification: DRC and LVS

โปรเจกต์ตัวอย่างสำหรับรัน RTL-to-GDSII และตรวจสอบ Physical Verification ด้วย
LibreLane Classic Flow โดยใช้ `config.yaml`

## เนื้อหา

- `src/counter.sv` — RTL counter 8 บิต
- `tb/tb_counter.sv` — self-checking testbench
- `constraints/pnr.sdc` — timing constraints สำหรับ PnR
- `constraints/signoff.sdc` — timing constraints สำหรับ signoff STA
- `pin_order.cfg` — custom I/O pin placement
- `config.yaml` — LibreLane Classic Flow configuration
- `scripts/pv_summary.py` — สรุปผล Magic DRC, KLayout DRC, XOR และ Netgen LVS
- `scripts/find_reports.sh` — ค้นหารายงานและ final artifacts
- `Makefile` — คำสั่งรันทั้งหมด

## 1. ตรวจสอบโปรเจกต์

```bash
ls -l scripts

chmod +x scripts/*.py
chmod +x scripts/*.sh

make check
```

## 2. RTL lint

```bash
make lint
```

## 3. Functional simulation

```bash
make sim
```

ผลที่คาดหวัง:

```text
PASS: counter RTL simulation completed successfully.
```

Waveform:

```text
build/counter.vcd
```

## 4. รัน LibreLane

ค่าเริ่มต้นใช้ `sky130A`:

```bash
make run
```

ระบุ PDK อื่น:

```bash
make run PDK=gf180mcuD
```

```bash
make run PDK=ihp-sg13g2
```

> PDK ต้องถูกติดตั้งและรองรับโดย LibreLane environment ที่ใช้งานอยู่  
> ผลลัพธ์หรือค่าพารามิเตอร์ PDK-specific อาจต้องปรับตาม revision ของ PDK

คำสั่งตรง:

```bash
librelane --pdk sky130A config.yaml
```

## 5. ตรวจรายงาน

```bash
make reports
make pv-summary
```

ตรวจแบบ strict:

```bash
make pv-check
```

เกณฑ์หลัก:

```text
Magic DRC count   : 0
KLayout DRC count : 0
Netgen LVS        : PASS
CORE PV STATUS    : PASS
```

Netgen report ที่ผ่านควรมี:

```text
Final result: Circuits match uniquely.
```

## 6. เปิด final GDS

```bash
make open-gds
```

หรือค้นหาเอง:

```bash
find runs -path '*/final/gds/*.gds' -type f
```

## 7. ล้างผลการรัน

ล้าง simulation:

```bash
make clean
```

ล้าง simulation และ LibreLane runs:

```bash
make distclean
```

## หมายเหตุสำคัญ

1. Script ค้นหา step จาก suffix เช่น `-magic-drc` และ `-netgen-lvs`
   จึงไม่ผูกกับหมายเลข step ซึ่งเปลี่ยนได้ตาม LibreLane version
2. การที่ flow จบโดยไม่รัน DRC/LVS ไม่ถือว่า physical verification ผ่าน
3. การผ่าน DRC/LVS ยังไม่ใช่ tapeout signoff ทั้งหมด ต้องตรวจ timing,
   antenna, density, IR drop และข้อกำหนดเฉพาะของโรงงานเพิ่มเติม
