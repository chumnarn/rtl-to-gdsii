
# Lab 1  
# การติดตั้งสภาพแวดล้อมและตรวจสอบเครื่องมือ  
## Environment Setup and Tool Verification

---

## 1.1 วัตถุประสงค์ของบทปฏิบัติการ

บทปฏิบัติการนี้เตรียมระบบคอมพิวเตอร์สำหรับการออกแบบวงจรรวมดิจิทัลด้วยกระบวนการ **RTL-to-GDSII** โดยใช้ LibreLane และเครื่องมือ EDA แบบโอเพนซอร์ส

เมื่อจบบทปฏิบัติการ ผู้เรียนจะสามารถ

1. ตรวจสอบทรัพยากรฮาร์ดแวร์และระบบปฏิบัติการ
2. เตรียม Ubuntu หรือ WSL2 สำหรับงานออกแบบ ASIC
3. ติดตั้งโปรแกรมพื้นฐาน เช่น Git, Make และ Curl
4. ติดตั้ง Nix package manager
5. ดาวน์โหลด Repository ของ Workshop
6. เข้าสู่ LibreLane development environment ด้วย `nix-shell`
7. ตรวจสอบเครื่องมือหลัก เช่น LibreLane, Yosys, OpenROAD, OpenSTA, Verilator, KLayout และ Magic
8. ตรวจสอบว่า Process Design Kit หรือ PDK สามารถเข้าถึงได้
9. รัน LibreLane smoke test
10. บันทึกข้อมูลสภาพแวดล้อมเพื่อใช้วิเคราะห์ปัญหาใน Lab ถัดไป

---

## 1.2 ภาพรวมของสภาพแวดล้อม

กระบวนการออกแบบที่จะใช้ใน Workshop มีโครงสร้างโดยสรุปดังนี้

```text
SystemVerilog RTL
        │
        ▼
      Yosys
 Logic Synthesis
        │
        ▼
    OpenROAD
Floorplan / Placement
CTS / Routing / STA
        │
        ▼
 Magic / KLayout / Netgen
 DRC / LVS / GDSII
```

LibreLane ทำหน้าที่เป็นระบบควบคุม Flow โดยเรียกใช้เครื่องมือแต่ละตัวตามลำดับ พร้อมจัดการ configuration, intermediate files, reports, logs และผลลัพธ์ของการออกแบบ

Repository ของ Workshop มีไฟล์ `flake.nix`, `flake.lock` และ `shell.nix` สำหรับสร้างสภาพแวดล้อมที่กำหนดรุ่นของ LibreLane และเครื่องมือที่เกี่ยวข้องไว้อย่างเป็นระบบ ผู้ใช้ต้องรัน `nix-shell` ที่ root directory ของ Repository ทุกครั้งที่เปิด Terminal ใหม่ 

---

## 1.3 เครื่องมือที่ใช้ในบทปฏิบัติการ

| เครื่องมือ | หน้าที่หลัก |
|---|---|
| Git | ดาวน์โหลดและจัดการ source code |
| Nix | สร้างสภาพแวดล้อมซอฟต์แวร์ที่ทำซ้ำได้ |
| LibreLane | ควบคุม RTL-to-GDSII Flow |
| Yosys | Logic synthesis |
| ABC | Technology mapping และ logic optimization |
| OpenROAD | Floorplanning, placement, CTS และ routing |
| OpenSTA | Static Timing Analysis |
| Verilator | RTL lint และ simulation |
| Icarus Verilog | Event-driven Verilog simulation |
| KLayout | Layout viewer และ DRC |
| Magic | Layout editor และ physical verification |
| Netgen | LVS |
| Python | LibreLane runtime และ automation |
| Tcl | Scripting สำหรับ EDA tools |
| Make | Automation ของคำสั่งใน Workshop |

Nix เป็นวิธีติดตั้งหลักที่ LibreLane แนะนำ เนื่องจากช่วยควบคุม dependency และสร้างสภาพแวดล้อมที่ทำซ้ำได้ โดยดาวน์โหลดเฉพาะส่วนที่จำเป็นจาก binary cache 

---

# ส่วนที่ 1: ตรวจสอบระบบก่อนติดตั้ง

## 1.4 ความต้องการของระบบ

LibreLane ระบุความต้องการขั้นต่ำสำหรับ Linux ดังนี้

- CPU อย่างน้อย 4 cores ความเร็วประมาณ 2 GHz
- RAM อย่างน้อย 8 GiB
- แนะนำ RAM 16 GiB
- Ubuntu 22.04 หรือใหม่กว่าเป็นระบบที่รองรับหลัก 

สำหรับ Workshop แนะนำทรัพยากรดังนี้

| ทรัพยากร | ขั้นต่ำ | แนะนำ |
|---|---:|---:|
| CPU | 4 cores | 8 cores หรือมากกว่า |
| RAM | 8 GB | 16–32 GB |
| Disk ว่าง | 30 GB | 60 GB หรือมากกว่า |
| OS | Ubuntu 22.04 | Ubuntu 24.04 หรือ WSL2 |
| Internet | จำเป็นในครั้งแรก | Broadband |

> **หมายเหตุ:** การออกแบบขนาดเล็ก เช่น Counter สามารถรันบน RAM 8 GB ได้ แต่การออกแบบที่มี macro, I/O pads หรือ full-chip integration จะใช้หน่วยความจำและพื้นที่จัดเก็บมากกว่า

---

## 1.5 ตรวจสอบระบบปฏิบัติการ

เปิด Terminal แล้วรัน

```bash
uname -a
```

ตัวอย่างผลลัพธ์

```text
Linux workstation 6.8.0-xx-generic #xx-Ubuntu SMP x86_64 GNU/Linux
```

ตรวจสอบ Distribution

```bash
cat /etc/os-release
```

ตัวอย่าง

```text
NAME="Ubuntu"
VERSION="24.04 LTS (Noble Numbat)"
ID=ubuntu
VERSION_ID="24.04"
```
หรือ
```bash
lsb_release -a
```
ตัวอย่าง

```text
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 26.04 LTS
Release:        26.04
Codename:       resolute
```

ตรวจสอบสถาปัตยกรรม CPU

```bash
uname -m
```

ผลลัพธ์ที่คาดหวังสำหรับเครื่อง PC ทั่วไป

```text
x86_64
```

ถ้าแสดง `aarch64` หมายถึงกำลังใช้ระบบ ARM64 เครื่องมือบางตัวอาจต้องใช้ package หรือ binary คนละชุดกับ x86-64

---

## 1.6 ตรวจสอบจำนวน CPU cores

```bash
nproc
```

หรือดูรายละเอียดเพิ่มเติม

```bash
lscpu
```

ข้อมูลสำคัญที่ควรตรวจสอบ ได้แก่

```text
Architecture:        x86_64
CPU(s):              8
Model name:          ...
Virtualization:      VT-x หรือ AMD-V
```

บันทึกจำนวน logical CPUs

```bash
CPU_COUNT=$(nproc)
echo "Available CPUs: $CPU_COUNT"
```

LibreLane สามารถใช้หลาย threads ในบางขั้นตอน แต่ไม่ควรกำหนดจำนวน threads สูงเกินกว่าทรัพยากรของเครื่อง

---

## 1.7 ตรวจสอบหน่วยความจำ

```bash
free -h
```

ตัวอย่าง

```text
               total        used        free      shared  buff/cache   available
Mem:            15Gi        2.1Gi       9.8Gi       120Mi       3.1Gi        12Gi
Swap:          4.0Gi          0B       4.0Gi
```

ค่าที่ควรสนใจคือ

- `total` — RAM ทั้งหมด
- `available` — RAM ที่โปรแกรมสามารถใช้งานได้
- `Swap` — พื้นที่สำรองเมื่อ RAM ไม่เพียงพอ

ตรวจสอบ Swap

```bash
swapon --show
```

หากระบบมี RAM 8 GB หรือน้อยกว่า ควรมี Swap อย่างน้อย 4–8 GB เพื่อลดโอกาสที่ OpenROAD จะถูกระบบปิดเนื่องจากหน่วยความจำไม่พอ

---

## 1.8 ตรวจสอบพื้นที่จัดเก็บ

```bash
df -h
```

ตรวจสอบพื้นที่ของ home directory โดยตรง

```bash
df -h "$HOME"
```

ตัวอย่าง

```text
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda2       200G   80G  110G  43% /
```

ควรมีพื้นที่ว่างอย่างน้อย 30 GB ก่อนเริ่มติดตั้ง เนื่องจาก

- Nix store เก็บ package และ dependencies
- PDK มีไฟล์ LEF, Liberty, GDSII และ technology files จำนวนมาก
- LibreLane เก็บ log และ intermediate result ของทุก Step
- แต่ละ design run อาจใช้พื้นที่ตั้งแต่หลักร้อย MB ถึงหลาย GB

---

## 1.9 ตรวจสอบการเชื่อมต่อเครือข่าย

ตรวจสอบ DNS และ Internet

```bash
ping -c 4 github.com
```

ตรวจสอบ HTTPS

```bash
curl -I https://github.com
```

หากทำงานถูกต้อง ควรพบ HTTP response เช่น

```text
HTTP/2 200
```

ในเครือข่ายองค์กรที่ใช้ Proxy อาจต้องตั้งค่า

```bash
export http_proxy=http://proxy.example:8080
export https_proxy=http://proxy.example:8080
```

ค่าจริงต้องสอบถามผู้ดูแลเครือข่ายขององค์กร

---

# ส่วนที่ 2: เตรียม Windows Subsystem for Linux

## 1.10 การติดตั้ง WSL2 สำหรับผู้ใช้ Windows

ผู้ใช้ Windows ต้องรัน LibreLane ภายใน WSL2 ไม่ใช่จาก Windows Command Prompt โดยตรง เอกสาร LibreLane ระบุว่าระบบ Windows ต้องใช้ WSL2 และแนะนำ Windows 11 หรือ Windows 10 ที่อัปเดตแล้ว 
### 1.10.1 เปิด PowerShell แบบ Administrator

กดปุ่ม Start แล้วค้นหา

```text
PowerShell
```

คลิกขวาและเลือก

```text
Run as administrator
```

### 1.10.2 ติดตั้ง Ubuntu

ใน PowerShell รัน

```powershell
wsl --install -d Ubuntu
```

จากนั้น Restart Windows เมื่อระบบร้องขอ

### 1.10.3 ตรวจสอบ WSL version

```powershell
wsl --list --verbose
```

ผลลัพธ์ควรมีลักษณะดังนี้

```text
  NAME      STATE           VERSION
* Ubuntu   Running         2
```

ค่าคอลัมน์ `VERSION` ต้องเป็น `2`

หากยังเป็น WSL1 ให้เปลี่ยนเป็น WSL2

```powershell
wsl --set-version Ubuntu 2
```

กำหนด WSL2 เป็นค่าเริ่มต้น

```powershell
wsl --set-default-version 2
```

### 1.10.4 ตรวจสอบ systemd ภายใน WSL2

เปิด Ubuntu Terminal แล้วรัน

```bash
systemctl --version
```

จากนั้นตรวจสอบสถานะ

```bash
systemctl is-system-running
```

อาจแสดง

```text
running
```

หรือ

```text
degraded
```

ค่า `degraded` อาจเกิดจาก service บางตัวที่ไม่จำเป็นใน WSL และไม่ได้หมายความว่า LibreLane ใช้งานไม่ได้เสมอไป

LibreLane ระบุว่า WSL2 รุ่นที่ติดตั้งตั้งแต่ช่วงกลางปี 2023 เป็นต้นมาเปิดใช้ systemd โดยปริยาย ส่วน installation เก่าอาจต้องเปิดเอง 

### 1.10.5 เปิด systemd ด้วยตนเองเมื่อจำเป็น

แก้ไขไฟล์

```bash
sudo nano /etc/wsl.conf
```

เพิ่มเนื้อหา

```ini
[boot]
systemd=true
```

บันทึกไฟล์ แล้วกลับไป PowerShell

```powershell
wsl --shutdown
```

เปิด Ubuntu ใหม่และตรวจสอบอีกครั้ง

```bash
systemctl is-system-running
```

---

## 1.11 ตำแหน่งจัดเก็บ Project สำหรับ WSL2

ควรเก็บ Repository ใน Linux filesystem เช่น

```text
/home/<username>/workshop
```

ไม่แนะนำให้เก็บ design ที่กำลังรันใน

```text
/mnt/c/Users/<username>/...
```

เนื่องจากการเข้าถึงไฟล์จำนวนมากระหว่าง Linux และ Windows filesystem อาจช้ากว่า และบางโปรแกรมอาจพบความแตกต่างด้าน permission หรือ symbolic link

ตัวอย่างพื้นที่ทำงานที่แนะนำ

```bash
mkdir -p "$HOME/workshop"
cd "$HOME/workshop"
```

ตรวจสอบตำแหน่ง

```bash
pwd
```

ผลลัพธ์ควรอยู่ใต้ `/home`

```text
/home/student/workshop
```

---

# ส่วนที่ 3: เตรียม Ubuntu Packages

## 1.12 อัปเดตรายการ Package

```bash
sudo apt-get update
```

อัปเดต package ที่ติดตั้งอยู่

```bash
sudo apt-get upgrade -y
```

> ในระบบของสถาบันหรือ Virtual Machine ที่ผู้สอนเตรียมไว้ อาจไม่จำเป็นต้องรัน `upgrade` เพื่อหลีกเลี่ยงการเปลี่ยนรุ่น package ระหว่างการอบรม

---

## 1.13 ติดตั้งโปรแกรมพื้นฐาน

```bash
sudo apt-get install -y \
    git \
    curl \
    wget \
    make \
    gcc \
    g++ \
    unzip \
    zip \
    xz-utils \
    file \
    tree \
    jq \
    nano \
    vim \
    ca-certificates
```

ตรวจสอบ Git

```bash
git --version
```

ตรวจสอบ Curl

```bash
curl --version
```

ตรวจสอบ Make

```bash
make --version
```

ตรวจสอบ Compiler

```bash
gcc --version
g++ --version
```

ไม่จำเป็นต้องได้เลขรุ่นเดียวกับตัวอย่างในคู่มือ แต่ทุกคำสั่งต้องทำงานโดยไม่แสดงข้อความ `command not found`

---

## 1.14 ตั้งค่า Git เบื้องต้น

กำหนดชื่อผู้ใช้

```bash
git config --global user.name "Your Name"
```

กำหนดอีเมล

```bash
git config --global user.email "your.email@example.com"
```

กำหนด branch เริ่มต้น

```bash
git config --global init.defaultBranch main
```

ตรวจสอบค่า

```bash
git config --global --list
```

ตัวอย่าง

```text
user.name=Your Name
user.email=your.email@example.com
init.defaultbranch=main
```

การตั้งค่านี้จำเป็นเมื่อผู้เรียนต้อง commit การแก้ไข Lab แต่ไม่มีผลต่อการ clone หรือรัน LibreLane โดยตรง

---

# ส่วนที่ 4: ติดตั้ง Nix

## 1.15 หลักการของ Nix Environment

การติดตั้งเครื่องมือ EDA แบบแยกทีละโปรแกรมอาจเกิดปัญหา เช่น

- โปรแกรมแต่ละตัวต้องการ library คนละรุ่น
- OpenROAD เวอร์ชันหนึ่งอาจไม่เข้ากันกับ LibreLane อีกเวอร์ชันหนึ่ง
- Python package บนเครื่องผู้ใช้แตกต่างกัน
- ผลลัพธ์จากเครื่องสองเครื่องไม่เหมือนกัน
- การอัปเดตระบบอาจทำให้ Flow เดิมรันไม่ได้

Nix แก้ปัญหานี้โดยเก็บ package ใน Nix store และสร้าง environment จาก dependency ที่ระบุไว้ใน configuration

```text
Repository
 ├── flake.nix
 ├── flake.lock
 └── shell.nix
        │
        ▼
      Nix
        │
        ▼
Reproducible EDA Environment
 ├── LibreLane
 ├── Yosys
 ├── OpenROAD
 ├── OpenSTA
 ├── KLayout
 └── PDK support
```

---

## 1.16 ข้อควรระวังก่อนติดตั้ง Nix

ห้ามติดตั้ง Nix ด้วยคำสั่ง

```bash
sudo apt install nix
```

เอกสาร LibreLane เตือนว่า Nix ใน Ubuntu package repository มักเก่าเกินไปและอาจทำให้เกิดปัญหากับ LibreLane

ตรวจสอบก่อนว่าเคยติดตั้ง Nix หรือไม่

```bash
command -v nix
```

หรือ

```bash
nix --version
```

กรณียังไม่ติดตั้ง จะพบข้อความลักษณะนี้

```text
nix: command not found
```

---

## 1.17 ติดตั้ง Nix ตามวิธีที่ LibreLane แนะนำ

ตรวจสอบว่ามี Curl

```bash
sudo apt-get install -y curl
```

รัน installer

```bash
curl --proto '=https' \
     --tlsv1.2 \
     -fsSL \
     https://artifacts.nixos.org/nix-installer |
sh -s -- install --no-confirm --extra-conf "
extra-substituters = https://nix-cache.fossi-foundation.org
extra-trusted-public-keys = nix-cache.fossi-foundation.org:3+K59iFwXqKsL7BNu6Guy0v+uTlwsxYQxjspXzqLYQs=
extra-experimental-features = nix-command flakes
"
```

คำสั่งนี้ทำงานสำคัญสามส่วน

1. ติดตั้ง Nix
2. เปิดใช้ `nix-command` และ `flakes`
3. เพิ่ม LibreLane/FOSSi binary cache

Binary cache ช่วยให้ระบบดาวน์โหลด binary ที่สร้างไว้แล้ว แทนการ compile เครื่องมือ EDA ทั้งหมดบนเครื่องผู้เรียน

คำสั่งติดตั้งและค่าของ binary cache ข้างต้นเป็นค่าที่เอกสาร LibreLane ระบุสำหรับ Ubuntu และ WSL2 

---

## 1.18 เปิด Terminal ใหม่

เมื่อ installer ทำงานเสร็จ ให้ปิด Terminal ทุกหน้าต่างแล้วเปิดใหม่

หรือโหลด environment ชั่วคราวด้วย

```bash
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

ตรวจสอบ Nix

```bash
nix --version
```

ตัวอย่างผลลัพธ์

```text
nix (Nix) 2.x.x
```

ตรวจสอบคำสั่ง Flake

```bash
nix flake --help >/dev/null
echo $?
```

ถ้าทำงานถูกต้องควรแสดง

```text
0
```

---

## 1.19 Clone LibreLane Repository

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

## 1.20 เข้า LibreLane Environment ด้วย Nix

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

## 1.21 ตรวจสอบ Nix daemon

```bash
systemctl status nix-daemon --no-pager
```

ควรพบข้อความ

```text
Active: active (running)
```

หรือทดสอบด้วย

```bash
nix store ping
```

ผลลัพธ์ที่คาดหวัง

```text
Store URL: daemon
Version: ...
Trusted: ...
```

ถ้าแก้ไข `/etc/nix/nix.conf` ภายหลัง ให้ Restart daemon

```bash
sudo pkill nix-daemon
```

เอกสาร LibreLane แนะนำให้ Restart `nix-daemon` หลังเปลี่ยน binary cache หรือ experimental features 

---

## 1.22 ตรวจสอบไฟล์ Configuration ของ Nix

```bash
cat /etc/nix/nix.conf
```

ค้นหาบรรทัดที่เกี่ยวข้อง

```bash
grep -E \
"extra-substituters|extra-trusted-public-keys|extra-experimental-features" \
/etc/nix/nix.conf
```

ควรพบค่าลักษณะนี้

```text
extra-substituters = https://nix-cache.fossi-foundation.org
extra-trusted-public-keys = nix-cache.fossi-foundation.org:...
extra-experimental-features = nix-command flakes
```

หากไม่พบและ LibreLane ดาวน์โหลด binary cache ไม่ได้ ให้ตรวจสอบ installation log หรือเพิ่มค่าเหล่านี้ตามเอกสารอย่างระมัดระวัง

---

# ส่วนที่ 5: ดาวน์โหลด Workshop Repository

## 1.23 สร้าง Working Directory

```bash
mkdir -p "$HOME/workshop"
cd "$HOME/workshop"
```

ตรวจสอบ

```bash
pwd
```

---

## 1.24 Clone Repository

```bash
git clone https://github.com/chumnarn/heichips26-digital-workshop.git
```

เข้าสู่ Repository

```bash
cd heichips26-digital-workshop
```

ตรวจสอบสถานะ

```bash
git status
```

ผลลัพธ์ควรมีลักษณะดังนี้

```text
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
```

---

## 1.25 ตรวจสอบโครงสร้าง Repository

```bash
ls -la
```

ควรพบไฟล์และ directory สำคัญ เช่น

```text
.
├── bonus
├── exercise_1
├── exercise_2
├── exercise_3
├── exercise_4
├── exercise_5
├── flake.lock
├── flake.nix
├── README.md
└── shell.nix
```

Repository ประกอบด้วย Exercise 1–5 และ Bonus full-chip design รวมทั้งไฟล์ Nix environment ที่ root directory 

แสดงโครงสร้างไม่เกินสองระดับ

```bash
tree -L 2
```

---

## 1.26 ตรวจสอบ Remote Repository

```bash
git remote -v
```

ผลลัพธ์ตัวอย่าง

```text
origin  https://github.com/chumnarn/heichips26-digital-workshop.git (fetch)
origin  https://github.com/chumnarn/heichips26-digital-workshop.git (push)
```

ตรวจสอบ Commit ปัจจุบัน

```bash
git log -1 --oneline
```

บันทึก Commit hash สำหรับใช้อ้างอิงเมื่อผลลัพธ์ต่างจากเครื่องอื่น

```bash
git rev-parse HEAD
```

---

## 1.27 อัปเดต Repository

หาก Clone ไว้ก่อนวันอบรม ให้รัน

```bash
git pull --ff-only
```

ไม่ควรรัน `git pull` ทันทีเมื่อมีไฟล์ที่แก้ไขค้างอยู่ ให้ตรวจสอบก่อนด้วย

```bash
git status
```

หากต้องการเก็บการแก้ไขไว้ชั่วคราว

```bash
git stash push -m "work before workshop update"
git pull --ff-only
git stash pop
```

---

# ส่วนที่ 6: เข้าสู่ LibreLane Environment

## 1.28 เรียกใช้ nix-shell

ต้องรันคำสั่งนี้จาก root directory ของ Repository

```bash
cd "$HOME/workshop/heichips26-digital-workshop"
nix-shell
```

การเข้า environment ครั้งแรกอาจมีการดาวน์โหลดเครื่องมือและ dependency จำนวนมาก

Prompt อาจเปลี่ยนเป็นลักษณะนี้

```text
[nix-shell:~/workshop/heichips26-digital-workshop]$
```

Repository ของ Workshop กำหนดให้ใช้ `nix-shell` ที่ root directory และต้องเรียกใหม่ทุกครั้งที่เปิด shell ใหม่ โดย Nix flake ของ Repository เลือก LibreLane development branch สำหรับ Workshop นี้ 

---

## 1.29 ยืนยันว่าอยู่ใน Nix shell

ตรวจสอบตัวแปร environment

```bash
echo "$IN_NIX_SHELL"
```

ผลลัพธ์อาจเป็น

```text
impure
```

หรือ

```text
pure
```

ตรวจสอบตำแหน่ง executable

```bash
which librelane
which yosys
which openroad
```

Path ควรชี้ไปยัง `/nix/store/...`

ตัวอย่าง

```text
/nix/store/xxxxxxxx-librelane/bin/librelane
/nix/store/xxxxxxxx-yosys/bin/yosys
/nix/store/xxxxxxxx-openroad/bin/openroad
```

ถ้า Path ชี้ไป `/usr/bin` อาจกำลังเรียกใช้โปรแกรมจาก Ubuntu แทนโปรแกรมที่กำหนดโดย Nix

---

## 1.30 ออกจาก Nix shell

```bash
exit
```

เมื่อออกแล้ว ให้ตรวจสอบ

```bash
command -v librelane
```

ในหลายระบบจะไม่พบ LibreLane นอก Nix shell ซึ่งเป็นพฤติกรรมปกติ

เข้าสู่ Environment ใหม่อีกครั้ง

```bash
cd "$HOME/workshop/heichips26-digital-workshop"
nix-shell
```

> ทุกคำสั่ง LibreLane ใน Lab ต่อไปต้องรันภายใน Nix shell เว้นแต่คู่มือระบุเป็นอย่างอื่น

---

# ส่วนที่ 7: ตรวจสอบ LibreLane

## 1.31 ตรวจสอบคำสั่ง LibreLane

ภายใน Nix shell รัน

```bash
librelane --help
```

ตรวจสอบ version

```bash
librelane --version
```

เนื่องจาก Workshop Repository อาจอ้างอิง development revision เลขรุ่นที่แสดงอาจแตกต่างจาก stable release

บันทึกข้อมูล

```bash
librelane --version | tee lab1_librelane_version.txt
```

---

## 1.32 รัน Smoke Test

```bash
librelane --smoke-test
```

Smoke test ใช้ตรวจสอบองค์ประกอบพื้นฐานของ LibreLane installation เอกสาร LibreLane แนะนำคำสั่งนี้เป็นการทดสอบอย่างรวดเร็วหลัง Clone และเข้า Nix shell 

เมื่อสำเร็จ ควรจบโดยไม่มี Python traceback หรือข้อความ error ร้ายแรง

บันทึกทั้ง standard output และ standard error

```bash
librelane --smoke-test 2>&1 | tee lab1_smoke_test.log
```

ตรวจสอบ return code ทันที

```bash
echo "${PIPESTATUS[0]}"
```

ผลลัพธ์ที่คาดหวัง

```text
0
```

ค่า `0` หมายถึงคำสั่งทำงานสำเร็จ

---

# ส่วนที่ 8: ตรวจสอบเครื่องมือ EDA

## 1.33 สร้าง Directory สำหรับผลการตรวจสอบ

```bash
mkdir -p lab1_results
```

---

## 1.34 ตรวจสอบ Yosys

```bash
yosys -V
```

ตัวอย่างผลลัพธ์

```text
Yosys ... (git sha1 ...)
```

ตรวจสอบตำแหน่ง

```bash
which yosys
```

ทดสอบการเปิดและปิด Yosys

```bash
yosys -p "help; exit"
```

หน้าที่ของ Yosys ใน Flow ได้แก่

- อ่าน Verilog/SystemVerilog RTL
- Elaborate hierarchy
- Process conversion
- Logic optimization
- Technology mapping
- สร้าง gate-level netlist

บันทึก version

```bash
yosys -V | tee lab1_results/yosys_version.txt
```

---

## 1.35 ตรวจสอบ OpenROAD

```bash
openroad -version
```

หาก option นี้ไม่รองรับ ให้ใช้

```bash
openroad -help | head
```

ตรวจสอบ Path

```bash
which openroad
```

ทดสอบ Tcl interpreter ภายใน OpenROAD

```bash
printf 'puts "OpenROAD Tcl is working"\nexit\n' |
openroad
```

ผลลัพธ์ควรมีข้อความ

```text
OpenROAD Tcl is working
```

OpenROAD ทำหน้าที่หลัก เช่น

- Floorplanning
- Power Distribution Network generation
- Global placement
- Detailed placement
- Clock Tree Synthesis
- Global routing
- Detailed routing
- Parasitic estimation
- Timing-driven optimization

บันทึก version

```bash
openroad -version 2>&1 |
tee lab1_results/openroad_version.txt
```

---

## 1.36 ตรวจสอบ OpenSTA

```bash
sta -version
```

ถ้า executable ใช้ชื่ออื่น ให้ค้นหา

```bash
command -v sta
command -v opensta
```

ทดสอบ Tcl

```bash
printf 'puts "OpenSTA is working"\nexit\n' |
sta
```

OpenSTA ใช้สำหรับ

- อ่าน Liberty timing library
- อ่าน synthesized netlist
- อ่าน SDC constraints
- วิเคราะห์ setup และ hold timing
- รายงาน slack
- ตรวจสอบ timing paths

---

## 1.37 ตรวจสอบ Verilator

```bash
verilator --version
```

ตรวจสอบ Help

```bash
verilator --help >/dev/null
echo $?
```

ผลลัพธ์ควรเป็น

```text
0
```

Verilator ใช้ใน Workshop สำหรับ

- RTL lint
- ตรวจสอบ syntax
- Compile SystemVerilog เป็น C++
- สร้าง simulation model
- รัน testbench แบบ cycle-based

บันทึก version

```bash
verilator --version |
tee lab1_results/verilator_version.txt
```

---

## 1.38 ตรวจสอบ Icarus Verilog

```bash
iverilog -V
```

ตรวจสอบ Runtime

```bash
vvp -V
```

บางข้อความของ `iverilog -V` อาจเขียนไปยัง standard error จึงสามารถบันทึกด้วย

```bash
iverilog -V 2>&1 |
tee lab1_results/iverilog_version.txt
```

---

## 1.39 ตรวจสอบ KLayout

```bash
klayout -v
```

หรือ

```bash
klayout -b -v
```

Option `-b` หมายถึง batch mode ซึ่งไม่ต้องเปิด GUI

ตรวจสอบ Path

```bash
which klayout
```

KLayout ใช้สำหรับ

- เปิดดู GDSII
- ตรวจสอบ layer
- รัน DRC deck
- เปรียบเทียบ layout
- ตรวจสอบผลลัพธ์ final GDS

### ทดสอบ GUI

บน Linux Desktop

```bash
klayout
```

บน WSL2 ที่รองรับ WSLg โปรแกรมควรเปิดหน้าต่างบน Windows ได้

ปิดโปรแกรมก่อนดำเนินการขั้นต่อไป

---

## 1.40 ตรวจสอบ Magic

```bash
magic --version
```

หากคำสั่งเปิด GUI ให้ใช้ batch mode

```bash
magic -dnull -noconsole <<'EOF'
puts "Magic is working"
quit -noprompt
EOF
```

Magic ใช้สำหรับ

- เปิดและแก้ไข layout
- รัน DRC
- Extract circuit
- สร้าง SPICE netlist
- ช่วยในขั้นตอน LVS

---

## 1.41 ตรวจสอบ Netgen

```bash
netgen -version
```

หาก option ไม่รองรับ

```bash
netgen -batch <<'EOF'
puts "Netgen is working"
quit
EOF
```

Netgen ใช้เปรียบเทียบ

```text
Schematic/Netlist
        versus
Extracted Layout Netlist
```

กระบวนการนี้เรียกว่า Layout Versus Schematic หรือ LVS

---

## 1.42 ตรวจสอบ Python

```bash
python3 --version
```

ตรวจสอบ Python executable

```bash
which python3
```

ภายใน Nix shell Path ควรอยู่ใต้ `/nix/store`

ตรวจสอบว่า import LibreLane ได้

```bash
python3 - <<'PY'
import librelane
print("LibreLane Python package:", librelane)
print("Python executable loaded successfully")
PY
```

ถ้าทำงานถูกต้อง จะไม่มีข้อความ

```text
ModuleNotFoundError
```

---

## 1.43 ตรวจสอบ Tcl

```bash
tclsh <<'EOF'
puts "Tcl version: [info patchlevel]"
puts "Tcl interpreter is working"
EOF
```

ตัวอย่างผลลัพธ์

```text
Tcl version: 8.6.x
Tcl interpreter is working
```

Tcl ถูกใช้เป็นภาษาสคริปต์ใน OpenROAD, OpenSTA, Yosys และเครื่องมือ physical design หลายตัว

---

## 1.44 ตรวจสอบ GNU Make

```bash
make --version
```

สร้างไฟล์ทดสอบชั่วคราว

```bash
cat > /tmp/Makefile.lab1 <<'EOF'
all:
	@echo "GNU Make is working"
EOF
```

รัน

```bash
make -f /tmp/Makefile.lab1
```

ผลลัพธ์

```text
GNU Make is working
```

ลบไฟล์

```bash
rm -f /tmp/Makefile.lab1
```

---

# ส่วนที่ 9: ตรวจสอบ Graphical Environment

## 1.45 ตรวจสอบ DISPLAY

```bash
echo "$DISPLAY"
```

บน Linux Desktop อาจได้

```text
:0
```

บน WSLg อาจได้

```text
:0
```

หรือค่าอื่นที่ระบบจัดให้

ตรวจสอบ Wayland

```bash
echo "$WAYLAND_DISPLAY"
```

บน WSLg อาจพบ

```text
wayland-0
```

---

## 1.46 ทดสอบ GUI เบื้องต้น

ติดตั้ง X11 test utility เฉพาะกรณีจำเป็น

```bash
sudo apt-get install -y x11-apps
```

ทดสอบ

```bash
xclock
```

หรือ

```bash
xeyes
```

หากหน้าต่างปรากฏ แสดงว่า Linux GUI สามารถส่งออกไปยัง Desktop ได้

> การรัน LibreLane แบบ command line ไม่จำเป็นต้องมี GUI แต่การตรวจสอบ GDSII ด้วย KLayout หรือ Magic จะสะดวกขึ้นเมื่อ GUI ทำงาน

---

# ส่วนที่ 10: ตรวจสอบ Process Design Kit

## 1.47 ความหมายของ PDK

Process Design Kit หรือ PDK คือชุดข้อมูลที่เชื่อมโยงกระบวนการออกแบบกับเทคโนโลยีการผลิต Semiconductor

องค์ประกอบทั่วไปประกอบด้วย

```text
PDK
├── Technology LEF
├── Standard-cell LEF
├── Liberty timing files
├── GDSII cell layouts
├── SPICE models
├── Layer map
├── DRC rules
├── LVS rules
└── RC extraction data
```

Workshop อาจใช้ PDK เช่น

- SKY130
- GF180MCU
- IHP SG13G2

LibreLane มี template หรือการรองรับสำหรับ PDK หลายตระกูล รวมทั้ง `gf180mcu`, `ihp-sg13g2` และ `sky130` 

---

## 1.48 ตรวจสอบตัวแปร PDK

ภายใน Nix shell รัน

```bash
env | grep -E 'PDK|PDK_ROOT'
```

ตัวแปรอาจยังไม่ปรากฏจนกว่า LibreLane จะ resolve PDK จาก configuration ซึ่งไม่จำเป็นต้องถือเป็น error ทันที

ค้นหา directory ที่เกี่ยวข้องใน Nix store

```bash
find /nix/store \
    -maxdepth 1 \
    -type d \
    \( -iname '*sky130*' \
       -o -iname '*gf180*' \
       -o -iname '*sg13*' \) \
    2>/dev/null |
head -30
```

---

## 1.49 ตรวจสอบ LibreLane PDK options

```bash
librelane --help | grep -i pdk
```

LibreLane มักรับชื่อ PDK ผ่าน option ลักษณะนี้

```bash
librelane --pdk <PDK_NAME> <CONFIG_FILE>
```

ตัวอย่างชื่อที่อาจใช้ใน Workshop

```text
sky130A
gf180mcuD
ihp-sg13g2
```

ชื่อ PDK ต้องตรงกับ provider และ configuration ของ environment ไม่ควรคาดเดาชื่อจากชื่อเทคโนโลยีเพียงอย่างเดียว

---

# ส่วนที่ 11: สร้าง Script ตรวจสอบอัตโนมัติ

## 1.50 สร้างไฟล์ `verify_tools.sh`

จาก root directory ของ Workshop รัน

```bash
cat > verify_tools.sh <<'EOF'
#!/usr/bin/env bash

set -u

RESULT_DIR="lab1_results"
mkdir -p "${RESULT_DIR}"

REPORT="${RESULT_DIR}/tool_verification.txt"

check_command() {
    local cmd="$1"

    if command -v "${cmd}" >/dev/null 2>&1; then
        printf "[PASS] %-15s %s\n" \
            "${cmd}" \
            "$(command -v "${cmd}")"
    else
        printf "[FAIL] %-15s command not found\n" "${cmd}"
    fi
}

{
    echo "=================================================="
    echo " Lab 1: Environment and Tool Verification"
    echo "=================================================="
    echo
    echo "Date       : $(date --iso-8601=seconds)"
    echo "Hostname   : $(hostname)"
    echo "User       : $(id -un)"
    echo "Directory  : $(pwd)"
    echo "Kernel     : $(uname -r)"
    echo "Machine    : $(uname -m)"
    echo "CPU count  : $(nproc)"
    echo "Nix shell  : ${IN_NIX_SHELL:-not-set}"
    echo

    echo "---------------- Commands ----------------"
    check_command git
    check_command nix
    check_command librelane
    check_command yosys
    check_command openroad
    check_command sta
    check_command verilator
    check_command iverilog
    check_command vvp
    check_command klayout
    check_command magic
    check_command netgen
    check_command python3
    check_command tclsh
    check_command make

    echo
    echo "---------------- Versions ----------------"

    git --version 2>&1 || true
    nix --version 2>&1 || true
    librelane --version 2>&1 || true
    yosys -V 2>&1 || true
    openroad -version 2>&1 || true
    sta -version 2>&1 || true
    verilator --version 2>&1 || true
    iverilog -V 2>&1 | head -5 || true
    klayout -v 2>&1 || true
    magic --version 2>&1 || true
    netgen -version 2>&1 || true
    python3 --version 2>&1 || true
    make --version 2>&1 | head -1 || true

    echo
    echo "---------------- Memory ----------------"
    free -h

    echo
    echo "---------------- Disk ----------------"
    df -h "$(pwd)"

    echo
    echo "---------------- Git ----------------"
    git status --short 2>&1 || true
    git rev-parse HEAD 2>&1 || true

    echo
    echo "=================================================="
    echo " Verification completed"
    echo "=================================================="
} | tee "${REPORT}"
EOF
```

---

## 1.51 กำหนด Permission

```bash
chmod +x verify_tools.sh
```

ตรวจสอบ

```bash
ls -l verify_tools.sh
```

ควรพบ `x` ใน permission

```text
-rwxr-xr-x ... verify_tools.sh
```

---

## 1.52 รัน Script

```bash
./verify_tools.sh
```

ผลลัพธ์ตัวอย่าง

```text
[PASS] git             /nix/store/.../bin/git
[PASS] nix             /nix/var/nix/profiles/default/bin/nix
[PASS] librelane       /nix/store/.../bin/librelane
[PASS] yosys           /nix/store/.../bin/yosys
[PASS] openroad        /nix/store/.../bin/openroad
[PASS] verilator       /nix/store/.../bin/verilator
...
```

ตรวจสอบ Report

```bash
cat lab1_results/tool_verification.txt
```

---

# ส่วนที่ 12: ทดสอบ RTL Toolchain ขั้นพื้นฐาน

## 1.53 สร้าง Workspace สำหรับ Mini Test

```bash
mkdir -p lab1_tool_test
cd lab1_tool_test
```

---

## 1.54 สร้าง RTL ตัวอย่าง

สร้างไฟล์ `simple_counter.sv`

```bash
cat > simple_counter.sv <<'EOF'
module simple_counter #(
    parameter int WIDTH = 4
) (
    input  logic             clk_i,
    input  logic             rst_ni,
    input  logic             en_i,
    output logic [WIDTH-1:0] count_o
);

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            count_o <= '0;
        else if (en_i)
            count_o <= count_o + 1'b1;
    end

endmodule
EOF
```

ตรวจสอบไฟล์

```bash
sed -n '1,120p' simple_counter.sv
```

---

## 1.55 รัน Verilator Lint

```bash
verilator \
    --lint-only \
    --Wall \
    --Wno-fatal \
    simple_counter.sv
```

ตรวจสอบ return code

```bash
echo $?
```

ผลลัพธ์ที่คาดหวัง

```text
0
```

ถ้าไม่มีข้อความใดแสดงออกมาและ return code เป็น 0 หมายถึง Verilator ไม่พบปัญหาที่ทำให้ lint ล้มเหลว

---

## 1.56 รัน Yosys Synthesis Test

สร้าง Yosys script

```bash
cat > synth.ys <<'EOF'
read_verilog -sv simple_counter.sv
hierarchy -check -top simple_counter
proc
opt
check
stat
write_verilog -noattr simple_counter_netlist.v
EOF
```

รัน

```bash
yosys -s synth.ys 2>&1 | tee yosys.log
```

ตรวจสอบ Netlist

```bash
ls -lh simple_counter_netlist.v
```

เปิดดู

```bash
sed -n '1,160p' simple_counter_netlist.v
```

ตรวจสอบ Error ใน Log

```bash
grep -n -E "ERROR|Error|error" yosys.log
```

หากไม่พบข้อความ error และมีไฟล์ `simple_counter_netlist.v` แสดงว่า RTL parsing และ synthesis ขั้นพื้นฐานทำงานได้

---

## 1.57 ตรวจสอบสถิติการสังเคราะห์

ค้นหา Section สถิติ

```bash
grep -A20 "=== simple_counter ===" yosys.log
```

ตัวอย่างข้อมูลที่อาจพบ

```text
Number of wires:
Number of wire bits:
Number of public wires:
Number of cells:
```

จำนวน cell อาจแตกต่างตาม Yosys revision และ optimization pass จึงไม่ควรใช้ตัวเลขตายตัวเป็นเกณฑ์ผ่าน

เกณฑ์ที่สำคัญคือ

- อ่าน SystemVerilog ได้
- Elaborate top module ได้
- ไม่มี hierarchy error
- `check` ไม่พบปัญหาร้ายแรง
- สร้าง netlist ได้

---

## 1.58 กลับไปที่ Root Directory

```bash
cd ..
```

ตรวจสอบ

```bash
pwd
```

ควรได้

```text
.../heichips26-digital-workshop
```

---

# ส่วนที่ 13: เก็บข้อมูล Environment

## 1.59 บันทึกข้อมูลระบบ

```bash
{
    echo "Date: $(date --iso-8601=seconds)"
    echo
    echo "===== OS ====="
    cat /etc/os-release
    echo
    echo "===== Kernel ====="
    uname -a
    echo
    echo "===== CPU ====="
    lscpu
    echo
    echo "===== Memory ====="
    free -h
    echo
    echo "===== Disk ====="
    df -h
    echo
    echo "===== Nix ====="
    nix --version
    echo
    echo "===== LibreLane ====="
    librelane --version
    echo
    echo "===== Git Commit ====="
    git rev-parse HEAD
} > lab1_results/environment_report.txt
```

ตรวจสอบ

```bash
less lab1_results/environment_report.txt
```

ออกจาก `less` ด้วยปุ่ม

```text
q
```

---

## 1.60 สร้างรายการ Tool Paths

```bash
for tool in \
    git nix librelane yosys openroad sta \
    verilator iverilog vvp klayout magic \
    netgen python3 tclsh make
do
    printf "%-12s : " "$tool"
    command -v "$tool" || echo "NOT FOUND"
done | tee lab1_results/tool_paths.txt
```

ไฟล์นี้มีประโยชน์เมื่อสงสัยว่าระบบเรียกใช้เครื่องมือผิด environment

---

## 1. เก็บ Nix Environment Summary

```bash
{
    echo "IN_NIX_SHELL=${IN_NIX_SHELL:-}"
    echo "PATH=$PATH"
    echo
    echo "NIX_PROFILES=${NIX_PROFILES:-}"
    echo "NIX_PATH=${NIX_PATH:-}"
} > lab1_results/nix_environment.txt
```

---

# ส่วนที่ 14: Troubleshooting

## 1.61 ปัญหา `nix: command not found`

อาการ

```text
bash: nix: command not found
```

สาเหตุที่เป็นไปได้

- ยังไม่ได้ติดตั้ง Nix
- ติดตั้งแล้วแต่ยังไม่ได้เปิด Terminal ใหม่
- Shell profile ยังไม่โหลด Nix environment

แนวทางแก้ไข

```bash
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
nix --version
```

ถ้ายังไม่สำเร็จ ให้ตรวจสอบ

```bash
ls -l /nix
ls -l /nix/var/nix/profiles/default/bin/nix
```

---

## 1.62 ปัญหา `experimental Nix feature 'flakes' is disabled`

อาการ

```text
error: experimental Nix feature 'flakes' is disabled
```

ตรวจสอบไฟล์

```bash
grep experimental /etc/nix/nix.conf
```

ควรมี

```text
extra-experimental-features = nix-command flakes
```

หลังแก้ไขให้ Restart daemon

```bash
sudo pkill nix-daemon
```

จากนั้นปิดและเปิด Terminal ใหม่

---

## 1.63 ปัญหา Binary Cache ไม่ทำงาน

อาการ

- Nix พยายาม compile OpenROAD หรือเครื่องมือขนาดใหญ่เอง
- ดาวน์โหลดช้ามาก
- พบข้อความเกี่ยวกับ untrusted substituter

ตรวจสอบ

```bash
grep -E \
"substituters|trusted-public-keys" \
/etc/nix/nix.conf
```

ควรมี FOSSi cache และ public key ตามค่าที่ LibreLane ระบุ 

ตรวจสอบการเชื่อมต่อ

```bash
curl -I https://nix-cache.fossi-foundation.org
```

---

## 1.64 ปัญหา `librelane: command not found`

ตรวจสอบ Directory

```bash
pwd
ls flake.nix shell.nix
```

เข้าสู่ Nix shell ใหม่

```bash
nix-shell
```

ตรวจสอบ

```bash
command -v librelane
```

ห้ามเรียก LibreLane จาก Terminal ที่ออกจาก `nix-shell` แล้ว

---

## 1.65 ปัญหา Nix shell เปิดจาก Directory ผิด

อาการ

```text
error: getting status of .../shell.nix: No such file or directory
```

แก้ไขโดยเข้าสู่ root ของ Repository

```bash
cd "$HOME/workshop/heichips26-digital-workshop"
ls shell.nix flake.nix
nix-shell
```

---

## 1.66 ปัญหา WSL เป็น Version 1

ตรวจสอบใน PowerShell

```powershell
wsl --list --verbose
```

หากแสดง

```text
Ubuntu    Stopped    1
```

เปลี่ยนเป็น WSL2

```powershell
wsl --set-version Ubuntu 2
```

LibreLane กำหนดให้ Windows environment ใช้ WSL2 

---

## 1.67 ปัญหา GUI ไม่เปิดบน WSL2

ตรวจสอบ

```bash
echo "$DISPLAY"
echo "$WAYLAND_DISPLAY"
```

ตรวจสอบ WSL version ใน PowerShell

```powershell
wsl --version
```

อัปเดต WSL

```powershell
wsl --update
wsl --shutdown
```

เปิด Ubuntu ใหม่แล้วทดสอบ

```bash
klayout
```

หากใช้ Windows/WSL รุ่นเก่าที่ไม่มี WSLg อาจต้องใช้ X server ภายนอก แต่สำหรับ Windows 11 และ WSL รุ่นใหม่ควรใช้ WSLg ที่มากับระบบก่อน

---

## 1.68 ปัญหา Permission ใน Repository

อาการ

```text
Permission denied
```

ตรวจสอบ owner

```bash
ls -ld .
```

หาก Repository ถูกสร้างด้วย `sudo` อาจเป็นของ root

แก้ไข

```bash
sudo chown -R "$USER":"$USER" \
"$HOME/workshop/heichips26-digital-workshop"
```

ไม่ควรรัน LibreLane ด้วย

```bash
sudo librelane ...
```

เพราะจะทำให้ output files เป็นของ root และอาจทำให้ environment ของ Nix ผิดไปจากที่กำหนด

---

## 1.69 ปัญหา Disk เต็ม

ตรวจสอบ

```bash
df -h
du -sh /nix/store
du -sh "$HOME/workshop/heichips26-digital-workshop"
```

ตรวจสอบ Nix garbage

```bash
nix store gc --dry-run
```

ไม่ควรลบ Nix store ด้วย `rm -rf` โดยตรง

ลบ output ของ design run ที่ไม่ใช้แล้วเฉพาะเมื่อเข้าใจโครงสร้าง เช่น directory `runs` ภายใน Exercise

---

## 1.70 ปัญหา OpenROAD ถูกปิดระหว่างทำงาน

อาการ

```text
Killed
```

หรือ process หายไปโดยไม่มี stack trace

ตรวจสอบ kernel log

```bash
dmesg | tail -50
```

ค้นหา Out-of-Memory

```bash
dmesg | grep -i -E "out of memory|killed process"
```

ตรวจสอบ RAM

```bash
free -h
```

สำหรับ WSL2 อาจต้องเพิ่ม RAM หรือ Swap ผ่านไฟล์ `.wslconfig` ฝั่ง Windows

ตัวอย่างแนวคิด

```ini
[wsl2]
memory=16GB
processors=8
swap=8GB
```

หลังแก้ไขรันใน PowerShell

```powershell
wsl --shutdown
```

ค่าต้องปรับให้เหมาะกับ RAM จริงของเครื่อง ไม่ควรกำหนดเกินทรัพยากรที่มี

---

## 1.71 ปัญหา Repository มีไฟล์แก้ไขค้างอยู่

ตรวจสอบ

```bash
git status
```

ดูความแตกต่าง

```bash
git diff
```

เก็บการเปลี่ยนแปลง

```bash
git add .
git commit -m "Save Lab 1 work"
```

หรือเก็บชั่วคราว

```bash
git stash
```

ไม่ควรรัน

```bash
git reset --hard
```

โดยไม่ตรวจสอบ เพราะคำสั่งนี้จะลบการแก้ไขที่ยังไม่ได้ commit

---

# ส่วนที่ 15: เกณฑ์การผ่าน Lab

## 1.72 Checklist

ผู้เรียนต้องตรวจสอบรายการต่อไปนี้

| รายการ | สถานะ |
|---|:---:|
| Ubuntu หรือ WSL2 ทำงานได้ | ☐ |
| WSL เป็น Version 2 | ☐ |
| มี CPU อย่างน้อย 4 cores | ☐ |
| มี RAM อย่างน้อย 8 GB | ☐ |
| มีพื้นที่ว่างอย่างน้อย 30 GB | ☐ |
| Git ทำงานได้ | ☐ |
| Nix ทำงานได้ | ☐ |
| `nix flake` ทำงานได้ | ☐ |
| Clone Workshop Repository สำเร็จ | ☐ |
| เข้า `nix-shell` สำเร็จ | ☐ |
| พบคำสั่ง `librelane` | ☐ |
| LibreLane smoke test ผ่าน | ☐ |
| Yosys ทำงานได้ | ☐ |
| OpenROAD ทำงานได้ | ☐ |
| OpenSTA ทำงานได้ | ☐ |
| Verilator ทำงานได้ | ☐ |
| KLayout ทำงานได้ | ☐ |
| Magic ทำงานได้ | ☐ |
| Netgen ทำงานได้ | ☐ |
| Python import LibreLane ได้ | ☐ |
| Verilator lint ตัวอย่างผ่าน | ☐ |
| Yosys สร้าง Netlist ได้ | ☐ |
| สร้าง Environment Report แล้ว | ☐ |

---

## 1.73 คำสั่งตรวจสอบขั้นสุดท้าย

จาก root directory ของ Repository และภายใน Nix shell ให้รัน

```bash
pwd
echo "$IN_NIX_SHELL"
git status
librelane --version
librelane --smoke-test
./verify_tools.sh
```

เกณฑ์ผ่านหลักคือ

```text
1. อยู่ใน root directory ของ Workshop
2. IN_NIX_SHELL มีค่า
3. LibreLane command ทำงานได้
4. Smoke test คืนค่า exit code 0
5. เครื่องมือหลักแสดง [PASS]
6. Verilator lint ผ่าน
7. Yosys สร้าง netlist ได้
```

---

# ส่วนที่ 16: แบบฝึกหัดท้าย Lab

## แบบฝึกหัดที่ 1: วิเคราะห์ระบบ

บันทึกข้อมูลต่อไปนี้

```text
Operating System:
Kernel Version:
CPU Model:
Number of CPU Cores:
Total RAM:
Available Disk Space:
Nix Version:
LibreLane Version:
Workshop Git Commit:
```

อธิบายว่าระบบของผู้เรียนอยู่ในระดับ

- ต่ำกว่าขั้นต่ำ
- ผ่านขั้นต่ำ
- ผ่านระดับแนะนำ

---

## แบบฝึกหัดที่ 2: วิเคราะห์ Path

รัน

```bash
which yosys
which openroad
which python3
```

ตอบคำถาม

1. Path ของเครื่องมืออยู่ใต้ `/nix/store` หรือไม่
2. เหตุใด Path ของเครื่องมือใน Nix shell จึงต่างจากนอก Nix shell
3. ถ้ามี Yosys ใน `/usr/bin` และ `/nix/store` พร้อมกัน ควรใช้ตัวใดสำหรับ Workshop

---

## แบบฝึกหัดที่ 3: ตรวจสอบ Return Code

รัน

```bash
librelane --version
echo $?
```

จากนั้นรันคำสั่งที่ไม่มีอยู่จริง

```bash
command_that_does_not_exist
echo $?
```

อธิบายความหมายของ

```text
Exit code 0
Exit code ที่ไม่ใช่ 0
```

---

## แบบฝึกหัดที่ 4: ตรวจสอบ Synthesis Log

จากไฟล์

```text
lab1_tool_test/yosys.log
```

ค้นหาข้อมูล

```bash
grep -n "Number of cells" lab1_tool_test/yosys.log
grep -n "Number of wires" lab1_tool_test/yosys.log
```

บันทึกจำนวน wire และ cell ที่ Yosys รายงาน

---

## แบบฝึกหัดที่ 5: สร้างหลักฐานการทำ Lab

ส่งไฟล์ต่อไปนี้

```text
lab1_results/
├── environment_report.txt
├── nix_environment.txt
├── tool_paths.txt
├── tool_verification.txt
├── yosys_version.txt
├── openroad_version.txt
└── verilator_version.txt

lab1_tool_test/
├── simple_counter.sv
├── synth.ys
├── yosys.log
└── simple_counter_netlist.v
```

สร้าง Archive

```bash
tar -czf lab1_submission.tar.gz \
    lab1_results \
    lab1_tool_test \
    verify_tools.sh
```

ตรวจสอบ

```bash
tar -tzf lab1_submission.tar.gz
```

---

# ส่วนที่ 17: คำถามทบทวน

1. LibreLane แตกต่างจาก OpenROAD อย่างไร
2. เหตุใด Workshop จึงใช้ Nix แทนการติดตั้งเครื่องมือด้วย `apt`
3. `flake.lock` มีความสำคัญต่อ reproducibility อย่างไร
4. เหตุใดต้องรัน `nix-shell` ทุกครั้งที่เปิด Terminal ใหม่
5. Yosys ทำหน้าที่ใดใน RTL-to-GDSII Flow
6. OpenSTA แตกต่างจาก RTL simulation อย่างไร
7. KLayout และ Magic ใช้ในขั้นตอนใด
8. DRC และ LVS ตรวจสอบสิ่งใด
9. PDK ประกอบด้วยข้อมูลประเภทใดบ้าง
10. เหตุใดควรบันทึก Git commit และ tool versions เมื่อรายงานปัญหา
11. เหตุใดไม่ควรเก็บ Project ที่กำลังรันไว้ใต้ `/mnt/c` ใน WSL2
12. Smoke test บอกอะไรได้ และบอกอะไรไม่ได้
13. เหตุใดการพบคำสั่งใน PATH ยังไม่เพียงพอที่จะยืนยันว่า Flow ทำงานได้
14. Exit code 0 มีความหมายอย่างไร
15. ถ้า OpenROAD แสดงเพียงคำว่า `Killed` ควรตรวจสอบอะไรเป็นลำดับแรก

---

# ส่วนที่ 18: สรุปบทปฏิบัติการ

ใน Lab นี้ ผู้เรียนได้เตรียมสภาพแวดล้อมสำหรับ RTL-to-GDSII Flow โดยเริ่มจากการตรวจสอบระบบปฏิบัติการ CPU RAM และพื้นที่จัดเก็บ จากนั้นติดตั้ง Nix และเปิดใช้ FOSSi binary cache ก่อนดาวน์โหลด Workshop Repository และเข้าสู่ environment ด้วย `nix-shell`

ผู้เรียนได้ตรวจสอบเครื่องมือหลัก ได้แก่ LibreLane, Yosys, OpenROAD, OpenSTA, Verilator, Icarus Verilog, KLayout, Magic, Netgen, Python, Tcl และ Make รวมถึงรัน LibreLane smoke test และทดสอบ RTL toolchain ด้วย Verilator lint และ Yosys synthesis

ผลลัพธ์จาก Lab นี้ทำหน้าที่เป็น baseline ของทุก Lab ถัดไป หากเกิดข้อผิดพลาดในขั้นตอน Synthesis, Floorplanning, Placement, CTS, Routing, DRC หรือ LVS ควรตรวจสอบก่อนเสมอว่า

```text
1. อยู่ใน Repository ที่ถูกต้อง
2. เข้าสู่ Nix shell แล้ว
3. ใช้ Git commit ที่ถูกต้อง
4. เครื่องมือมาจาก /nix/store
5. มี PDK ที่ Flow ต้องการ
6. มีทรัพยากรระบบเพียงพอ
7. Smoke test ทำงานได้
```

เมื่อผ่านเกณฑ์ทั้งหมดแล้ว ระบบพร้อมสำหรับ **Lab 2: Counter RTL Simulation and Verification** และการใช้งาน LibreLane ในขั้นตอนต่อไป
