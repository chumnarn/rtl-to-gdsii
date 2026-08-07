จากภาพ ปัญหาหลักคือ

```text
fatal error: zlib.h: No such file or directory
```

Verilator ใช้ตัวเลือก `--trace-fst` ทำให้ต้อง compile ส่วน FST ของ GTKWave ซึ่งพึ่งพา **zlib development headers** แต่ environment ใน `nix-shell` ยังไม่มี `zlib.h` จึงสร้าง `counter_sim` ไม่สำเร็จ และเกิด error ต่อเนื่อง:

```text
./build/obj_dir/counter_sim: No such file or directory
```

Verilator ระบุว่า `--trace-fst` ใช้สำหรับสร้าง waveform แบบ FST โดยตรง ดังนั้น dependency ของ FST ต้องพร้อมใน build environment. ([verilator.org][1])

## วิธีแก้เร็วที่สุด

ออกจาก LibreLane shell เดิม:

```bash
exit
```

จากนั้นเข้า shell โดยเพิ่ม `zlib` และเครื่องมือ compile:

```bash
nix-shell ~/eda/librelane/shell.nix \
  -p zlib pkg-config gcc gnumake
```

ตรวจสอบว่าเห็น `zlib.h`:

```bash
find "$NIX_STORE" -path '*/include/zlib.h' 2>/dev/null | head
```

หรือทดสอบผ่าน compiler:

```bash
echo '#include <zlib.h>' | gcc -E -x c - >/dev/null &&
echo "zlib header: OK"
```

แล้วกลับไปรัน Lab 2:

```bash
cd ~/psu/rtl-to-gdsii/lab02/lab02_counter_rtl
make clean
make sim
```

## วิธีแก้ถาวรใน `shell.nix`

เปิดไฟล์:

```bash
nano ~/eda/librelane/shell.nix
```

หากไฟล์มี `mkShell` และ `buildInputs` ให้เพิ่ม `zlib` และ `pkg-config`:

```nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    pkg-config
    gcc
    gnumake
  ];

  buildInputs = with pkgs; [
    zlib
  ];
}
```

หาก `shell.nix` เดิมมี package จำนวนมากอยู่แล้ว ให้เพิ่มเฉพาะ:

```nix
nativeBuildInputs = with pkgs; [
  pkg-config
];

buildInputs = with pkgs; [
  zlib
];
```

จากนั้นออกแล้วเข้า shell ใหม่:

```bash
exit
cd ~/eda/librelane
nix-shell
```

ตรวจสอบ:

```bash
pkg-config --modversion zlib
pkg-config --cflags zlib
pkg-config --libs zlib
```

ควรได้ผลประมาณ:

```text
1.3.x
-I/nix/store/...-zlib-...-dev/include
-L/nix/store/...-zlib-.../lib -lz
```

ใน Nix การใส่ library ใน `buildInputs` และ `pkg-config` ใน `nativeBuildInputs` จะช่วยตั้งค่า include และ `PKG_CONFIG_PATH` สำหรับการ compile. ([NixOS Discourse][2])

## ทางเลือก: เปลี่ยนจาก FST เป็น VCD

หาก Lab นี้ไม่จำเป็นต้องใช้ FST สามารถแก้ `Makefile` จาก:

```make
--trace-fst
```

เป็น:

```make
--trace
```

หรือ:

```make
--trace-vcd
```

ตัวอย่าง:

```make
verilator \
    --binary \
    --timing \
    --trace \
    --Wall \
    -Wno-fatal \
    --top-module counter_tb \
    --Mdir build/obj_dir \
    -o counter_sim \
    rtl/counter.sv \
    tb/counter_tb.sv
```

จากนั้น:

```bash
make clean
make sim
```

วิธีนี้สร้าง VCD และโดยทั่วไปไม่ผ่านส่วน `fstapi` ที่กำลังเรียก `zlib.h` อย่างไรก็ตาม หากต้องการไฟล์ `.fst` ให้ติดตั้ง `zlib` ใน Nix shell เป็นวิธีที่ถูกต้องกว่า

## ปรับ Makefile ไม่ให้รันต่อเมื่อ compile ล้มเหลว

จาก log เห็นว่า command ถูก pipe ผ่าน `tee`:

```bash
2>&1 | tee logs/verilator_build.log
```

หากไม่ได้เปิด `pipefail` สถานะผิดพลาดอาจไม่ถูกส่งต่ออย่างถูกต้อง ควรแก้ recipe เป็น:

```make
sim:
	@mkdir -p build/obj_dir logs
	@set -o pipefail; verilator \
		--binary \
		--timing \
		--trace-fst \
		--Wall \
		-Wno-fatal \
		--top-module counter_tb \
		--Mdir build/obj_dir \
		-o counter_sim \
		rtl/counter.sv \
		tb/counter_tb.sv \
		2>&1 | tee logs/verilator_build.log
	./build/obj_dir/counter_sim
```

และกำหนด shell ด้านบน Makefile:

```make
SHELL := /usr/bin/env bash
```

ชุดคำสั่งแนะนำสำหรับแก้ทันที:

```bash
exit

nix-shell ~/eda/librelane/shell.nix \
  -p zlib pkg-config gcc gnumake

cd ~/psu/rtl-to-gdsii/lab02/lab02_counter_rtl

pkg-config --modversion zlib
echo '#include <zlib.h>' | gcc -E -x c - >/dev/null &&
echo "zlib header: OK"

make clean
make sim
```

[1]: https://verilator.org/guide/latest/faq.html?utm_source=chatgpt.com "FAQ/Frequently Asked Questions — Verilator 5.050 ..."
[2]: https://discourse.nixos.org/t/when-we-are-in-a-nix-develop-shell-how-does-it-make-the-libraries-available-to-the-binaries/18870?utm_source=chatgpt.com "When we are in a `nix develop` shell, how does it make ..."
