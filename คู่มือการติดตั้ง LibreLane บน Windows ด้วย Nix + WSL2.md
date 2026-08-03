**คู่มือการติดตั้ง LibreLane บน Windows ด้วย Nix + WSL2** แบบ Step-by-Step สำหรับใช้เป็นเอกสารประกอบ Workshop / Lab ได้ทันที โดยอิงจากเอกสารทางการของ LibreLane ซึ่งระบุว่า **Nix เป็นวิธีที่แนะนำมากที่สุด** และบน Windows ต้องใช้งานผ่าน **WSL2** ([librelane.readthedocs.io][1])

---

# คู่มือการติดตั้ง LibreLane บน Windows ด้วย Nix + WSL2

## 1. ภาพรวม

**LibreLane** เป็นโฟลว์สำหรับงาน Digital ASIC Implementation / RTL-to-GDSII ที่ใช้เครื่องมือ Open Source EDA เช่น Yosys, OpenROAD, OpenSTA, Magic, KLayout และ Netgen ผ่านระบบจัดการ Environment แบบ reproducible

สำหรับ Windows วิธีที่เหมาะสมคือ:

```text
Windows 10/11
   ↓
WSL2
   ↓
Ubuntu Linux
   ↓
Nix Package Manager
   ↓
LibreLane Environment
   ↓
Run RTL-to-GDSII Flow
```

เอกสารทางการของ LibreLane แนะนำ Nix เพราะช่วยให้ toolchain มีความสอดคล้อง ทำซ้ำได้ และลดปัญหา dependency mismatch เมื่อเทียบกับการติดตั้งเครื่องมือ EDA ทีละตัวเอง ([librelane.readthedocs.io][1])

---

## 2. ความต้องการของระบบ

### ขั้นต่ำ

```text
Windows 10 version 2004 / Build 19041 ขึ้นไป
CPU 4 cores ความเร็วประมาณ 2.0 GHz ขึ้นไป
RAM 8 GB
WSL2
Ubuntu บน WSL
Internet connection
```

### แนะนำสำหรับ Workshop

```text
Windows 11
CPU Intel Core Gen 6 ขึ้นไป หรือ AMD Ryzen 1000 series ขึ้นไป
RAM 16 GB หรือมากกว่า
SSD พื้นที่ว่างอย่างน้อย 30–50 GB
```

LibreLane ระบุขั้นต่ำเป็น Windows 10 Build 19041 ขึ้นไป, CPU quad-core, RAM 8 GiB และแนะนำ Windows 11 กับ RAM 16 GiB ([librelane.readthedocs.io][2])

---

## 3. ติดตั้ง WSL2 และ Ubuntu

เปิด **Windows PowerShell แบบ Administrator** แล้วรันคำสั่ง:

```powershell
wsl --install -d Ubuntu
```

จากนั้น Restart เครื่องถ้าระบบแจ้งให้ Restart

เมื่อติดตั้งเสร็จ ให้ตรวจสอบว่า Ubuntu ใช้ WSL version 2:

```powershell
wsl --list --verbose
```

ผลลัพธ์ควรคล้ายแบบนี้:

```text
  NAME      STATE           VERSION
* Ubuntu    Running         2
```

LibreLane ต้องการ WSL2 และเอกสารทางการให้ตรวจสอบด้วย `wsl --list --verbose` หลังติดตั้ง Ubuntu ([librelane.readthedocs.io][2])

---

## 4. เปิด Ubuntu และอัปเดตระบบ

เปิดโปรแกรม **Ubuntu** จาก Start Menu แล้วตั้งค่า username/password ตามที่ระบบถาม

จากนั้นรันคำสั่งใน Ubuntu Terminal:

```bash
sudo apt update
sudo apt upgrade -y
```

ติดตั้งเครื่องมือพื้นฐาน:

```bash
sudo apt install -y git curl wget build-essential ca-certificates
```

ตรวจสอบเวอร์ชัน:

```bash
git --version
curl --version
```

---

## 5. ติดตั้ง Nix สำหรับ LibreLane

> ห้ามติดตั้ง Nix ด้วย `apt install nix` เพราะเอกสาร LibreLane ระบุว่า Nix จาก apt มักเก่าเกินไปและอาจเกิดปัญหาได้ ([librelane.readthedocs.io][2])

ติดตั้ง `curl` ถ้ายังไม่มี:

```bash
sudo apt-get install -y curl
```

ติดตั้ง Nix พร้อมตั้งค่า cache ของ FOSSi Foundation และเปิดใช้ `nix-command` กับ `flakes`:

```bash
curl --proto '=https' --tlsv1.2 -fsSL https://artifacts.nixos.org/nix-installer | sh -s -- install --no-confirm --extra-conf "
    extra-substituters = https://nix-cache.fossi-foundation.org
    extra-trusted-public-keys = nix-cache.fossi-foundation.org:3+K59iFwXqKsL7BNu6Guy0v+uTlwsxYQxjspXzqLYQs=
    extra-experimental-features = nix-command flakes
"
```

หลังติดตั้งเสร็จ ให้ปิด Ubuntu Terminal แล้วเปิดใหม่อีกครั้ง

ตรวจสอบ Nix:

```bash
nix --version
```

ทดสอบ Nix:

```bash
nix-shell --version
```

---

## 6. Clone LibreLane Repository

สร้างโฟลเดอร์สำหรับเก็บโปรเจกต์:

```bash
mkdir -p ~/eda
cd ~/eda
```

Clone LibreLane:

```bash
git clone https://github.com/librelane/librelane
cd librelane
```

เอกสารทางการระบุว่าเมื่อ clone repository แล้ว ให้เข้าไปที่ root ของ LibreLane และใช้ `nix-shell` เพื่อเข้าสู่ environment ของ LibreLane ([librelane.readthedocs.io][2])

---

## 7. เข้า LibreLane Environment ด้วย Nix

จากโฟลเดอร์ `~/eda/librelane` รัน:

```bash
nix-shell
```

ครั้งแรก Nix จะดาวน์โหลด binary และ dependency จำนวนมากจาก cache อาจใช้เวลาพอสมควร เอกสาร LibreLane ระบุว่าครั้งแรกอาจใช้เวลาประมาณ 10 นาทีเพื่อดึง binaries จาก cache ([librelane.readthedocs.io][2])

เมื่อเข้าสู่ environment สำเร็จ prompt อาจเปลี่ยนไป และสามารถใช้คำสั่ง LibreLane ได้

ตรวจสอบคำสั่ง:

```bash
librelane --version
```

หรือ:

```bash
librelane --help
```

---

## 8. ทดสอบการติดตั้งด้วย Smoke Test

ภายใน `nix-shell` ให้รัน:

```bash
librelane --smoke-test
```

ถ้าการติดตั้งถูกต้อง ระบบควรรัน test ได้โดยไม่ error สำคัญ เอกสารทางการของ LibreLane แนะนำให้ใช้ `librelane --smoke-test` เพื่อทดสอบการติดตั้งอย่างรวดเร็ว ([librelane.readthedocs.io][2])

---

## 9. Workflow การใช้งานประจำวัน

ทุกครั้งที่ต้องการใช้ LibreLane:

```bash
cd ~/eda/librelane
nix-shell
```

จากนั้นจึงรัน flow หรือ lab project เช่น:

```bash
librelane --help
```

หรือในอนาคตเมื่อมีไฟล์ config:

```bash
librelane --pdk-root <path-to-pdk> <path-to-config>
```

ตัวอย่างโครงสร้างการทำงานที่แนะนำ:

```text
~/eda/
 ├── librelane/
 ├── labs/
 │   ├── lab1_counter/
 │   ├── lab2_uart/
 │   └── lab3_picorv32/
 └── pdks/
```

---

## 10. ข้อแนะนำสำคัญสำหรับ Windows + WSL2

ควรเก็บไฟล์โปรเจกต์ไว้ใน Linux filesystem เช่น:

```bash
/home/<username>/eda
```

ไม่แนะนำให้รันโปรเจกต์หนัก ๆ จาก path ของ Windows เช่น:

```bash
/mnt/c/Users/...
```

เพราะ I/O ผ่าน `/mnt/c` ช้ากว่า และอาจเกิดปัญหากับ permission หรือ symbolic link ได้ง่ายกว่า โดยเฉพาะงาน EDA ที่มีไฟล์จำนวนมาก

---

## 11. การแก้ปัญหาที่พบบ่อย

### ปัญหา 1: WSL ยังเป็น Version 1

ตรวจสอบ:

```powershell
wsl --list --verbose
```

ถ้า Ubuntu เป็น version 1 ให้เปลี่ยนเป็น WSL2:

```powershell
wsl --set-version Ubuntu 2
```

ตั้งค่า default ให้เป็น WSL2:

```powershell
wsl --set-default-version 2
```

---

### ปัญหา 2: คำสั่ง `nix` ไม่พบ

ปิด Ubuntu Terminal แล้วเปิดใหม่

ถ้ายังไม่เจอ ให้ลอง:

```bash
source ~/.profile
```

แล้วตรวจสอบ:

```bash
nix --version
```

---

### ปัญหา 3: ติดตั้ง Nix ด้วย apt ไปแล้ว

ถ้าเคยติดตั้งด้วย:

```bash
sudo apt install nix
```

อาจเกิดปัญหา version เก่า แนะนำให้ลบก่อน แล้วติดตั้งตามวิธีของ LibreLane:

```bash
sudo apt remove -y nix-bin nix
sudo apt autoremove -y
```

จากนั้นติดตั้งใหม่ด้วยคำสั่ง installer ในหัวข้อที่ 5

---

### ปัญหา 4: `nix-shell` ช้ามากในครั้งแรก

เป็นเรื่องปกติ เพราะ Nix ต้องดาวน์โหลด toolchain, binary cache และ dependency จำนวนมาก

ตรวจสอบว่าใช้ cache ของ FOSSi แล้ว:

```bash
cat /etc/nix/nix.conf
```

ควรมีบรรทัดประมาณนี้:

```text
extra-substituters = https://nix-cache.fossi-foundation.org
extra-trusted-public-keys = nix-cache.fossi-foundation.org:3+K59iFwXqKsL7BNu6Guy0v+uTlwsxYQxjspXzqLYQs=
extra-experimental-features = nix-command flakes
```

---

## 12. สรุปคำสั่งแบบรวบรัด

### PowerShell

```powershell
wsl --install -d Ubuntu
wsl --list --verbose
```

### Ubuntu / WSL2

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y git curl wget build-essential ca-certificates

curl --proto '=https' --tlsv1.2 -fsSL https://artifacts.nixos.org/nix-installer | sh -s -- install --no-confirm --extra-conf "
    extra-substituters = https://nix-cache.fossi-foundation.org
    extra-trusted-public-keys = nix-cache.fossi-foundation.org:3+K59iFwXqKsL7BNu6Guy0v+uTlwsxYQxjspXzqLYQs=
    extra-experimental-features = nix-command flakes
"
```

ปิด Ubuntu แล้วเปิดใหม่ จากนั้น:

```bash
mkdir -p ~/eda
cd ~/eda
git clone https://github.com/librelane/librelane
cd librelane
nix-shell
librelane --smoke-test
```

---

## 13. Checklist หลังติดตั้ง

```text
[ ] Windows ใช้ WSL2 แล้ว
[ ] Ubuntu เปิดใช้งานได้
[ ] git / curl ติดตั้งแล้ว
[ ] Nix ติดตั้งแล้ว
[ ] nix --version ใช้งานได้
[ ] LibreLane repository clone แล้ว
[ ] เข้า nix-shell ได้
[ ] librelane --help ใช้งานได้
[ ] librelane --smoke-test ผ่าน
```

---

## 14. หมายเหตุสำหรับใช้ใน Workshop

สำหรับห้องอบรม ควรให้ผู้เรียนติดตั้งล่วงหน้าก่อนวันอบรม เพราะขั้นตอน `nix-shell` ครั้งแรกต้องดาวน์โหลดข้อมูลจำนวนมาก และขึ้นกับความเร็ว Internet

รูปแบบที่เหมาะสมสำหรับ Lab:

```text
Lab 0: Install WSL2 + Ubuntu
Lab 1: Install Nix
Lab 2: Clone LibreLane
Lab 3: Enter nix-shell
Lab 4: Run smoke test
Lab 5: Run simple RTL-to-GDSII demo
```

สรุปคือ **Windows + WSL2 + Ubuntu + Nix** เป็นแนวทางที่เหมาะสำหรับการสอน LibreLane เพราะได้ environment ใกล้เคียง Linux จริง และ Nix ช่วยควบคุม version ของ toolchain ให้สอดคล้องกันในแต่ละเครื่องของผู้เรียน.

[1]: https://librelane.readthedocs.io/en/stable/installation/index.html "Installation - LibreLane Documentation"
[2]: https://librelane.readthedocs.io/en/latest/installation/nix_installation/installation_win.html "Windows 10+ - LibreLane Documentation"
