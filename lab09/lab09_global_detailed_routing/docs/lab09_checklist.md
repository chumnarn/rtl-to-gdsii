# Lab 9 Result Sheet

## Run information

- Date:
- LibreLane version:
- PDK and revision:
- Run tag:
- Host CPU/RAM:

## Configuration

| Parameter | Value |
|---|---:|
| CLOCK_PERIOD | 20.0 ns |
| FP_CORE_UTIL | 40 |
| PL_TARGET_DENSITY_PCT | 50 |
| RT_MIN_LAYER | met1 |
| RT_MAX_LAYER | met5 |
| GRT_ADJUSTMENT | 0.30 |
| GRT_OVERFLOW_ITERS | 50 |
| DRT_OPT_ITERS | 64 |

## Routing results

| Metric | Result | Pass criterion |
|---|---:|---:|
| Global routing overflow | | 0 |
| Detailed routing DRC | | 0 |
| Unrouted nets | | 0 |
| Disconnected pins | | 0 |
| Antenna violations | | 0 |
| Total wire length | | Record |
| Via count | | Record |
| Setup WNS | | >= 0 ns |
| Hold WNS | | >= 0 ns |
| Peak memory | | Record |
| Runtime | | Record |

## GUI inspection

- [ ] ตรวจ congestion heatmap
- [ ] ตรวจบริเวณ I/O pins
- [ ] ตรวจ clock route
- [ ] ตรวจ routing detours
- [ ] ตรวจ DRC markers
- [ ] ตรวจ long/high-fanout nets
- [ ] ตรวจ PDN obstruction interaction

## Analysis

1. ตำแหน่ง congestion สูงสุดอยู่บริเวณใด
2. ชั้นโลหะใดมี routing usage สูงสุด
3. มี detour หรือ via stack ผิดปกติหรือไม่
4. Post-route timing ต่างจาก post-CTS อย่างไร
5. การปรับ floorplan หรือ placement ใดน่าจะช่วยได้มากที่สุด
