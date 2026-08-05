# Lab 9 Routing Checklist — IHP SG13G2

## Environment
- [ ] `librelane --version` ทำงาน
- [ ] `make validate` โหลด `ihp-sg13g2` สำเร็จ
- [ ] `RT_MIN_LAYER` คือ `Metal2`
- [ ] `RT_MAX_LAYER` คือ `TopMetal2`

## RTL
- [ ] Verilator lint ผ่าน
- [ ] Self-checking simulation แสดง PASS
- [ ] Clock period = 20 ns
- [ ] Reset false path ถูกกำหนด

## Global Routing
- [ ] Step `OpenROAD.GlobalRouting` สำเร็จ
- [ ] Overflow = 0
- [ ] ไม่มี fatal congestion
- [ ] ตรวจ congestion map ใน OpenROAD GUI
- [ ] ตรวจ layer usage ของ Metal2–TopMetal2

## Detailed Routing
- [ ] Step `OpenROAD.DetailedRouting` สำเร็จ
- [ ] TritonRoute DRC = 0
- [ ] Unrouted nets = 0
- [ ] Disconnected pins = 0
- [ ] ไม่มี pin-access failure
- [ ] ตรวจ via และ routing detour

## Post-route / Signoff
- [ ] Setup timing ตรวจแล้ว
- [ ] Hold timing ตรวจแล้ว
- [ ] Antenna report ตรวจแล้ว
- [ ] KLayout/Magic DRC ตรวจแล้ว
- [ ] LVS ตรวจแล้ว
