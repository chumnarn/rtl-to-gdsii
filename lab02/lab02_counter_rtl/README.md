# Lab 2 — Counter RTL Simulation and Verification

ชุด Lab พร้อมรันสำหรับวงจร synchronous 8-bit up-counter

## โครงสร้าง

```text
lab02_counter_rtl/
├── config.yaml
├── Makefile
├── README.md
├── rtl/
│   └── counter.sv
├── tb/
│   └── counter_tb.sv
├── yosys/
│   └── synth.ys
├── scripts/
│   ├── check_tools.sh
│   └── run_all.sh
├── build/
├── logs/
└── waves/
```

## คุณสมบัติที่ตรวจสอบ

- active-low synchronous reset
- reset hold
- normal increment
- reset during operation
- complete 8-bit wraparound `8'hFF -> 8'h00`
- continued operation after overflow
- automatic PASS/FAIL and non-zero exit status on failure
- FST waveform generation

## เริ่มต้นอย่างรวดเร็ว

```bash
cd lab02_counter_rtl
make check-tools
make lint
make sim
```

ผลสำเร็จต้องมีข้อความ:

```text
LAB RESULT      : PASS
```

ไฟล์ waveform:

```text
waves/counter.fst
```

เปิดด้วย:

```bash
make wave
```

หรือรัน workflow ทั้งหมด:

```bash
./scripts/run_all.sh
```

## Yosys synthesis

```bash
make yosys
```

ผลลัพธ์:

```text
build/counter_synth.v
logs/yosys.log
```

## LibreLane ด้วย config.yaml

เข้าสู่ environment ที่มี LibreLane แล้วรัน:

```bash
make librelane
```

คำสั่งที่ Makefile เรียกคือ:

```bash
librelane --pdk ihp-sg13g2 config.yaml
```

เปิดผลล่าสุด:

```bash
make openroad
make klayout
```

เปลี่ยน PDK ได้ผ่านตัวแปร `PDK` เช่น:

```bash
make librelane PDK=sky130A
```

อย่างไรก็ตาม configuration ชุดนี้ออกแบบและตรวจแนวทางหลักกับ `ihp-sg13g2`

## Negative test

เพื่อพิสูจน์ว่า testbench ตรวจจับข้อผิดพลาดได้ ให้แก้ชั่วคราวใน
`rtl/counter.sv`:

```systemverilog
count_o <= count_o + 8'd2;
```

จากนั้นรัน:

```bash
make clean
make sim
```

testbench ต้องรายงาน `FAIL` และคำสั่งต้องคืนค่า exit status ที่ไม่เป็นศูนย์
จากนั้นคืนโค้ดเป็น `+ 8'd1`

## ทำความสะอาด

```bash
make clean
```

ลบผล LibreLane ด้วย:

```bash
make distclean
```
