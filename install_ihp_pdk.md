สำหรับติดตั้ง **IHP Open PDK เพื่อใช้กับ LibreLane** บน Ubuntu/WSL2 แนะนำใช้ repository ทางการของ IHP แล้วชี้ `PDK_ROOT` ไปยังตำแหน่งนั้นครับ IHP มีทั้ง `ihp-sg13g2` และ `ihp-sg13cmos5l`; ใน LibreLane มี template รองรับทั้งสอง PDK โดยตรง [GitHub](https://github.com/IHP-GmbH/IHP-Open-PDK?utm_source=chatgpt.com)

ใช้ขั้นตอนนี้:

```bash
# 1. ไปยัง directory ที่จะเก็บ PDK
mkdir -p ~/eda
cd ~/eda

# 2. Clone IHP Open PDK
git clone https://github.com/IHP-GmbH/IHP-Open-PDK.git

cd IHP-Open-PDK

# 3. ตรวจว่า PDK มีอยู่
ls
ls ihp-sg13g2
```

จากนั้นตั้ง environment:

```bash
export PDK_ROOT=$HOME/eda/IHP-Open-PDK
export PDK=ihp-sg13g2
```

IHP แนะนำให้ตั้ง `PDK_ROOT`, `PDK` และ KLayout environment variables ไว้ใน shell configuration ด้วย [ihp-open-pdk-docs.readthedocs.io](https://ihp-open-pdk-docs.readthedocs.io/en/latest/install/installation.html?utm_source=chatgpt.com)

```bash
echo 'export PDK_ROOT=$HOME/eda/IHP-Open-PDK' >> ~/.bashrc
echo 'export PDK=ihp-sg13g2' >> ~/.bashrc
echo 'export KLAYOUT_PATH="$HOME/.klayout:$PDK_ROOT/$PDK/libs.tech/klayout"' >> ~/.bashrc
echo 'export KLAYOUT_HOME=$HOME/.klayout' >> ~/.bashrc

source ~/.bashrc
```

ตรวจสอบ:

```bash
echo $PDK_ROOT
echo $PDK

ls $PDK_ROOT/$PDK
```

ควรเห็นโครงสร้างประมาณ:

```text
libs.ref/
libs.tech/
libs.tech/librelane/
```

จุดสำคัญสำหรับ LibreLane คือ PDK ต้องมีไฟล์ config ที่:

```text
$PDK_ROOT/ihp-sg13g2/libs.tech/librelane/config.tcl
```

LibreLane ระบุว่า PDK แบบ manual ต้องมี LibreLane PDK configuration ในตำแหน่งนี้ [LibreLane](https://librelane.readthedocs.io/en/latest/usage/about_pdks.html?utm_source=chatgpt.com)

ตรวจด้วย:

```bash
ls $PDK_ROOT/ihp-sg13g2/libs.tech/librelane/
```

จากนั้นเข้า LibreLane:

```bash
cd ~/librelane
nix-shell
```

แล้วลอง:

```bash
librelane \
  --manual-pdk \
  --pdk-root $HOME/eda/IHP-Open-PDK \
  --pdk ihp-sg13g2 \
  config.yaml
```

`--manual-pdk` สำคัญเมื่อใช้ PDK ที่ clone/build เอง แทนการให้ LibreLane/Ciel download PDK ให้อัตโนมัติ [LibreLane](https://librelane.readthedocs.io/en/latest/usage/about_pdks.html?utm_source=chatgpt.com)

ถ้าต้องการ **รันโดย skip DRC** ตามที่ถามก่อนหน้า:

```bash
librelane \
  --manual-pdk \
  --pdk-root $HOME/eda/IHP-Open-PDK \
  --pdk ihp-sg13g2 \
  config.yaml \
  --skip Magic.DRC \
  --skip Klayout.DRC
```

ผมแนะนำให้ตรวจ installation ก่อนด้วยชุดนี้:

```bash
echo "=== PDK_ROOT ==="
echo $PDK_ROOT

echo "=== PDK ==="
echo $PDK

echo "=== LibreLane config ==="
ls -l \
$PDK_ROOT/ihp-sg13g2/libs.tech/librelane/config.tcl

echo "=== Standard cells ==="
ls \
$PDK_ROOT/ihp-sg13g2/libs.ref/sg13g2_stdcell

echo "=== KLayout ==="
ls \
$PDK_ROOT/ihp-sg13g2/libs.tech/klayout
```

ถ้าทั้งหมดผ่าน สำหรับ environment ของอาจารย์ผมแนะนำ layout นี้:

```text
~/eda/
├── librelane/
└── IHP-Open-PDK/
    ├── ihp-sg13g2/
    └── ihp-sg13cmos5l/
```

แล้วใช้งาน SG13G2 ด้วย:

```bash
export PDK_ROOT=$HOME/eda/IHP-Open-PDK
export PDK=ihp-sg13g2

cd ~/librelane
nix-shell

librelane \
  --manual-pdk \
  --pdk-root $PDK_ROOT \
  --pdk $PDK \
  config.yaml
```

ข้อสังเกต: IHP ระบุ `SG13G2` open PDK ปัจจุบันเป็น **early access** และ `SG13CMOS5L` เป็น **preview** จึงควร pin Git commit ของ PDK สำหรับงานอบรมหรือ ASIC project ที่ต้องการ reproducibility ไม่ควรดึง `main` ใหม่กลางงานโดยไม่บันทึก revision [GitHub](https://github.com/IHP-GmbH/IHP-Open-PDK/blob/main/README.md?utm_source=chatgpt.com).
