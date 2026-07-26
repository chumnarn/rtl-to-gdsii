# Lab 3: First RTL-to-GDSII Implementation — GF180MCU

ชุดทดลองพร้อมรันสำหรับนำวงจร Counter จาก SystemVerilog RTL ไปจนถึง GDSII ด้วย LibreLane และ GF180MCU PDK

## โครงสร้าง

```text
.
├── config.yaml
├── pin_order.cfg
├── Makefile
├── rtl/counter.sv
├── tb/tb_counter.sv
├── constraints/pnr.sdc
├── constraints/signoff.sdc
└── scripts/
```

## PDK identifier

Makefile ใช้ `gf180mcuD` เป็นค่าเริ่มต้น เพราะเป็นชื่อ installation ที่พบบ่อยใน Volare/Open_PDKs ปัจจุบัน หาก environment ของท่านติดตั้งชื่ออื่น ให้ตรวจด้วยคำสั่งของ PDK manager แล้ว override เช่น

```bash
make pnr PDK=gf180mcuC
```

ค่า `pdk::gf180mcu*` ใน `config.yaml` รองรับชื่อ variant ที่ขึ้นต้นด้วย `gf180mcu`

## เริ่มใช้งาน

```bash
unzip lab3_gf180mcu_rtl_to_gdsii.zip
cd lab3_gf180mcu_rtl_to_gdsii
```

เปิด environment ที่มี LibreLane และ PDK แล้วตรวจเครื่องมือ

```bash
make tools
make preflight
```

ตรวจ RTL และ simulation

```bash
make lint
make sim
make synth
```

หรือ

```bash
make all
```

รัน RTL-to-GDSII

```bash
make pnr
```

ใช้ CPU เพิ่มเติม

```bash
make pnr JOBS=4
```

ระบุ PDK variant เอง

```bash
make pnr PDK=gf180mcuD JOBS=4
```

คำสั่ง LibreLane โดยตรง

```bash
librelane -j 1 --pdk gf180mcuD --flow Classic config.yaml
```

ตรวจผลลัพธ์

```bash
make reports
```

เปิด layout

```bash
make openroad
make klayout
```

## ผล simulation ที่คาดหวัง

```text
PASS: self-checking counter simulation completed
```

## ค่าออกแบบหลัก

- Top module: `counter`
- Clock: `clk_i`
- Clock period: 24 ns
- Target frequency: ประมาณ 41.67 MHz
- Reset: synchronous active-low
- Counter width: 8 bits
- PDK family: GF180MCU
- Default installation name: `gf180mcuD`

## หมายเหตุ

GF180MCU มีหลาย variant และ standard-cell library ตาม installation ของ PDK จึงควรใช้ชื่อ `--pdk` ที่ปรากฏจริงใน environment ของเครื่อง หาก LibreLane แจ้งว่าไม่พบ `gf180mcuD` ให้เปลี่ยนค่า `PDK` โดยไม่ต้องแก้ RTL หรือ `config.yaml`
