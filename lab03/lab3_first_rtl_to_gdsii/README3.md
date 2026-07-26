# Lab 3 — First RTL-to-GDSII Implementation

ชุดทดลองนี้นำวงจร Counter ขนาด 8 บิตจาก SystemVerilog ไปสู่ GDSII ด้วย LibreLane Classic Flow และ IHP SG13G2 PDK โดยใช้ `config.yaml`

## โครงสร้าง

```text
lab3_first_rtl_to_gdsii/
├── config.yaml
├── pin_order.cfg
├── Makefile
├── README.md
├── rtl/
│   └── counter.sv
├── tb/
│   └── tb_counter.sv
├── scripts/
│   ├── synth.ys
│   └── check_results.py
├── build/
└── waves/
```

## 1. เปิดสภาพแวดล้อมเครื่องมือ

ใน workshop repository ให้เข้า Nix shell ก่อน หรือใช้ LibreLane environment ที่ติดตั้งไว้แล้ว

```bash
nix-shell
cd lab3_first_rtl_to_gdsii
```

ตรวจเครื่องมือ

```bash
make tools
```

## 2. ตรวจสอบ RTL

```bash
make lint
```

## 3. Functional simulation

```bash
make sim
```

ผลที่คาดหวัง

```text
PASS: counter RTL simulation completed successfully
```

ไฟล์ waveform อยู่ที่

```text
waves/counter.vcd
```

เปิดด้วย GTKWave เมื่อมีโปรแกรมติดตั้ง

```bash
gtkwave waves/counter.vcd
```

## 4. Generic synthesis ด้วย Yosys

```bash
make synth
```

ผลลัพธ์

```text
build/counter_generic_netlist.v
build/yosys.log
```

## 5. รัน RTL-to-GDSII ด้วย LibreLane

```bash
make pnr
```

คำสั่งที่ Makefile เรียกคือ

```bash
librelane --pdk ihp-sg13g2 config.yaml
```

LibreLane จะสร้าง run directory ใต้ `runs/` หรือ `run/` ตามเวอร์ชันที่ใช้งาน

## 6. ตรวจผลลัพธ์

```bash
make reports
```

สคริปต์จะค้นหา run ล่าสุดและรายงานตำแหน่งของ GDSII, DEF, ODB, netlist, SPEF, SDF และ metrics

## 7. เปิด GUI

OpenROAD

```bash
make openroad
```

KLayout

```bash
make klayout
```

## 8. รันส่วนตรวจ RTL ทั้งหมด

```bash
make all
```

เป้าหมายนี้รัน `lint`, `sim` และ `synth` แต่ไม่เริ่ม PnR

## 9. ทำความสะอาด

ลบผล simulation และ Yosys

```bash
make clean
```

ลบ LibreLane runs ทั้งหมด

```bash
make clean-runs
```

> ระวัง: `make clean-runs` ลบข้อมูล implementation ทุก run ในโฟลเดอร์ Lab นี้

## หมายเหตุด้านความเข้ากันได้

- `config.yaml` ใช้ `USE_SLANG: true` เพื่อรองรับ SystemVerilog frontend ที่สมบูรณ์ขึ้น
- หาก LibreLane รุ่นเก่าไม่รู้จักตัวแปรใด ให้ดูข้อความ validation และลบเฉพาะตัวแปรเสริมนั้น โดยคงตัวแปรหลัก `DESIGN_NAME`, `VERILOG_FILES`, `CLOCK_PORT`, `CLOCK_PERIOD`
- PDK ต้องพร้อมใช้งานใน LibreLane/Ciel environment
- ผล timing, area และ physical verification อาจต่างกันตาม LibreLane, OpenROAD และ PDK revision
