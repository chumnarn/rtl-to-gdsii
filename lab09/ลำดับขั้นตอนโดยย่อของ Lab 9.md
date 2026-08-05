## ลำดับขั้นตอนโดยย่อของ Lab 9

### Global and Detailed Routing ด้วย LibreLane

1. เตรียม LibreLane environment และตรวจสอบว่าใช้งาน `ihp-sg13g2` PDK ได้
2. เข้าโฟลเดอร์ Lab และตรวจสอบไฟล์ `config.yaml`, RTL และ SDC
3. รัน RTL lint ด้วย Verilator
4. รัน self-checking simulation เพื่อตรวจสอบฟังก์ชันของวงจร
5. ตรวจสอบ routing layers ใน `config.yaml`
6. รัน LibreLane ถึงขั้น Synthesis
7. รัน Floorplan และ Placement
8. รัน Clock Tree Synthesis
9. รัน Global Routing
10. ตรวจสอบ congestion, routing overflow, wire length และ via count
11. เปิดผล Global Routing ใน OpenROAD GUI
12. รัน Detailed Routing
13. ตรวจสอบ Routing DRC, unrouted nets, disconnected pins และ shorts
14. ตรวจสอบ antenna violations และการซ่อม antenna
15. ตรวจสอบ post-route timing ได้แก่ setup และ hold
16. รัน RTL-to-GDSII flow แบบครบขั้นตอน
17. ตรวจผล Signoff ได้แก่ DRC, LVS และ antenna
18. เปิดผล Layout ด้วย OpenROAD GUI หรือ KLayout
19. สรุป Routing metrics และจัดเก็บรายงาน
20. ทดลองปรับ `GRT_ADJUSTMENT`, placement density หรือ routing layers แล้วเปรียบเทียบผล

ลำดับคำสั่งหลัก:

```bash
make check
make validate
make lint
make sim
make grt
make metrics
make drt
make metrics
make run
make reports
make archive
make gui
```

เกณฑ์ผลลัพธ์สำคัญ:

```text
Global Routing Overflow      = 0
Routing DRC Errors           = 0
Unrouted Nets                = 0
Disconnected Pins            = 0
Short Circuits               = 0
Antenna Violations           = 0 หรือซ่อมครบ
Setup/Hold Timing            = ผ่านข้อกำหนด
```
