# คำสั่ง Linux พื้นฐาน

## 1. ตรวจสอบตำแหน่งและไฟล์

| คำสั่ง   | ความหมาย                 | ตัวอย่าง           |
| -------- | ------------------------ | ------------------ |
| `pwd`    | แสดง directory ปัจจุบัน  | `pwd`              |
| `ls`     | แสดงรายการไฟล์           | `ls`               |
| `ls -l`  | แสดงรายละเอียดไฟล์       | `ls -l`            |
| `ls -a`  | แสดงไฟล์ซ่อน             | `ls -a`            |
| `ls -lh` | แสดงขนาดไฟล์แบบอ่านง่าย  | `ls -lh`           |
| `tree`   | แสดงโครงสร้าง directory  | `tree`             |
| `file`   | ตรวจสอบชนิดไฟล์          | `file config.yaml` |
| `stat`   | แสดงข้อมูลไฟล์โดยละเอียด | `stat design.v`    |

ตัวเลือกที่ใช้บ่อย:

```bash
ls -alh
```

---

## 2. เปลี่ยน Directory

| คำสั่ง         | ความหมาย                |
| -------------- | ----------------------- |
| `cd directory` | เข้า directory          |
| `cd ..`        | ย้อนกลับหนึ่งระดับ      |
| `cd ~`         | กลับ home directory     |
| `cd -`         | กลับ directory ก่อนหน้า |
| `cd /`         | ไป root directory       |

ตัวอย่าง:

```bash
cd ~/labs/psu
cd ..
cd -
```

---

## 3. สร้างไฟล์และ Directory

| คำสั่ง     | ความหมาย                   | ตัวอย่าง                     |
| ---------- | -------------------------- | ---------------------------- |
| `mkdir`    | สร้าง directory            | `mkdir lab1`                 |
| `mkdir -p` | สร้าง directory หลายระดับ  | `mkdir -p rtl/tb`            |
| `touch`    | สร้างไฟล์ว่าง              | `touch README.md`            |
| `echo`     | เขียนข้อความ               | `echo "Hello" > file.txt`    |
| `printf`   | เขียนข้อความแบบกำหนดรูปแบบ | `printf "A\nB\n" > file.txt` |

ตัวอย่าง:

```bash
mkdir -p project/{rtl,tb,scripts,config}
touch project/README.md
```

---

## 4. คัดลอก ย้าย และเปลี่ยนชื่อ

| คำสั่ง  | ความหมาย                | ตัวอย่าง               |
| ------- | ----------------------- | ---------------------- |
| `cp`    | คัดลอกไฟล์              | `cp source.v backup.v` |
| `cp -r` | คัดลอก directory        | `cp -r rtl rtl_backup` |
| `mv`    | ย้ายหรือเปลี่ยนชื่อ     | `mv old.v new.v`       |
| `rsync` | คัดลอกและซิงโครไนซ์ไฟล์ | `rsync -av src/ dst/`  |

ตัวอย่าง:

```bash
cp config.yaml config.yaml.bak
cp -r project project_backup
mv counter_old.v counter.v
```

---

## 5. ลบไฟล์และ Directory

| คำสั่ง             | ความหมาย                    |
| ------------------ | --------------------------- |
| `rm file`          | ลบไฟล์                      |
| `rm -i file`       | ถามก่อนลบ                   |
| `rm -r directory`  | ลบ directory และข้อมูลภายใน |
| `rm -rf directory` | บังคับลบโดยไม่ถาม           |
| `rmdir directory`  | ลบ directory ว่าง           |

ตัวอย่าง:

```bash
rm report.log
rm -i config.yaml
rm -r build
```

ควรระวังอย่างมากกับ:

```bash
rm -rf
```

โดยเฉพาะอย่าใช้กับ `/`, `~` หรือ path ที่ยังไม่ได้ตรวจสอบ

---

## 6. อ่านเนื้อหาไฟล์

| คำสั่ง    | ความหมาย                   | ตัวอย่าง              |
| --------- | -------------------------- | --------------------- |
| `cat`     | แสดงเนื้อหาไฟล์ทั้งหมด     | `cat config.yaml`     |
| `less`    | เปิดอ่านไฟล์แบบเลื่อนหน้า  | `less synthesis.log`  |
| `more`    | อ่านไฟล์ทีละหน้า           | `more report.txt`     |
| `head`    | แสดงบรรทัดแรก              | `head -n 20 file.log` |
| `tail`    | แสดงบรรทัดท้าย             | `tail -n 20 file.log` |
| `tail -f` | ติดตามไฟล์ที่กำลังถูกเขียน | `tail -f run.log`     |
| `nl`      | แสดงไฟล์พร้อมเลขบรรทัด     | `nl -ba config.yaml`  |

ตัวอย่าง:

```bash
head -n 50 synthesis.log
tail -n 100 openroad.log
tail -f run.log
```

---

## 7. แก้ไขไฟล์ข้อความ

| คำสั่ง      | โปรแกรม                     |
| ----------- | --------------------------- |
| `nano file` | Text editor ใช้งานง่าย      |
| `vim file`  | Text editor ขั้นสูง         |
| `vi file`   | Editor มาตรฐาน Unix         |
| `code file` | เปิดด้วย Visual Studio Code |

ตัวอย่าง:

```bash
nano config.yaml
vim counter.v
code .
```

---

## 8. ค้นหาไฟล์

### ใช้ `find`

```bash
find . -name "config.yaml"
find . -name "*.v"
find . -type f
find . -type d
```

ค้นหาไฟล์ที่แก้ไขภายใน 1 วัน:

```bash
find . -type f -mtime -1
```

ค้นหาไฟล์ขนาดมากกว่า 100 MB:

```bash
find . -type f -size +100M
```

ลบไฟล์ `.log` ที่ค้นพบ:

```bash
find . -type f -name "*.log" -delete
```

ควรตรวจด้วย `-print` ก่อนใช้ `-delete`:

```bash
find . -type f -name "*.log" -print
```

---

## 9. ค้นหาข้อความในไฟล์

### ใช้ `grep`

```bash
grep "ERROR" run.log
grep -i "error" run.log
grep -n "ERROR" run.log
grep -R "CLOCK_PORT" .
```

ตัวเลือกสำคัญ:

| ตัวเลือก | ความหมาย                        |
| -------- | ------------------------------- |
| `-i`     | ไม่สนใจตัวพิมพ์เล็กใหญ่         |
| `-n`     | แสดงเลขบรรทัด                   |
| `-R`     | ค้นหาแบบ recursive              |
| `-v`     | แสดงบรรทัดที่ไม่ตรง             |
| `-E`     | ใช้ extended regular expression |
| `-H`     | แสดงชื่อไฟล์                    |
| `-w`     | ตรงทั้งคำ                       |

ตัวอย่างสำหรับ log LibreLane:

```bash
grep -RniE "error|warning|failed|violation" runs/
```

ค้นหาเฉพาะ Error:

```bash
grep -Rni "ERROR" runs/
```

---

## 10. จัดเรียงและกรองข้อมูล

| คำสั่ง | ความหมาย                 |
| ------ | ------------------------ |
| `sort` | เรียงข้อมูล              |
| `uniq` | ลบบรรทัดซ้ำ              |
| `wc`   | นับบรรทัด คำ และตัวอักษร |
| `cut`  | เลือก column             |
| `tr`   | แทนที่ตัวอักษร           |
| `sed`  | แก้ไขและกรองข้อความ      |
| `awk`  | ประมวลผลข้อมูลแบบ column |

ตัวอย่าง:

```bash
sort names.txt
sort names.txt | uniq
sort names.txt | uniq -c
wc -l run.log
```

นับจำนวน error:

```bash
grep -i "error" run.log | wc -l
```

แสดง column แรก:

```bash
awk '{print $1}' report.txt
```

แทนข้อความ:

```bash
sed 's/old_name/new_name/g' config.yaml
```

แก้ไฟล์จริง:

```bash
sed -i 's/old_name/new_name/g' config.yaml
```

---

## 11. Redirect และ Pipe

### Redirect

```bash
command > file
```

เขียนทับไฟล์:

```bash
ls -l > file_list.txt
```

เพิ่มต่อท้ายไฟล์:

```bash
echo "new line" >> file.txt
```

ส่ง error ไปยังไฟล์:

```bash
make 2> error.log
```

ส่งทั้ง output และ error:

```bash
make > build.log 2>&1
```

รูปแบบ Bash แบบย่อ:

```bash
make &> build.log
```

### Pipe

ส่ง output จากคำสั่งหนึ่งไปยังอีกคำสั่ง:

```bash
ls -l | less
grep "ERROR" run.log | wc -l
find . -name "*.v" | sort
```

---

## 12. สิทธิ์การใช้งานไฟล์

| คำสั่ง  | ความหมาย                  |
| ------- | ------------------------- |
| `chmod` | เปลี่ยน permission        |
| `chown` | เปลี่ยนเจ้าของไฟล์        |
| `chgrp` | เปลี่ยน group             |
| `umask` | กำหนด permission เริ่มต้น |

ทำ script ให้รันได้:

```bash
chmod +x run.sh
```

กำหนด permission:

```bash
chmod 644 config.yaml
chmod 755 scripts/run.sh
```

ความหมายทั่วไป:

| ค่า | Permission             |
| --: | ---------------------- |
| `7` | read + write + execute |
| `6` | read + write           |
| `5` | read + execute         |
| `4` | read                   |

เปลี่ยนเจ้าของ:

```bash
sudo chown user:user file.txt
```

---

## 13. รันคำสั่งด้วยสิทธิ์ผู้ดูแล

```bash
sudo command
```

ตัวอย่าง:

```bash
sudo apt update
sudo apt install git
```

เข้าสู่ root shell:

```bash
sudo -i
```

ควรใช้สิทธิ์ root เฉพาะเมื่อจำเป็น

---

## 14. ตรวจสอบ Process

| คำสั่ง   | ความหมาย                   |
| -------- | -------------------------- |
| `ps`     | แสดง process               |
| `ps aux` | แสดง process ทั้งหมด       |
| `top`    | ดูการใช้ CPU และ RAM       |
| `htop`   | ดู process แบบ interactive |
| `pgrep`  | ค้นหา process              |
| `kill`   | หยุด process               |
| `pkill`  | หยุด processตามชื่อ        |
| `jobs`   | แสดง background jobs       |
| `fg`     | นำ job กลับ foreground     |
| `bg`     | ให้ job ทำงาน background   |

ค้นหา process LibreLane:

```bash
ps aux | grep librelane
pgrep -af openroad
```

หยุด process:

```bash
kill 12345
```

บังคับหยุด:

```bash
kill -9 12345
```

หยุดตามชื่อ:

```bash
pkill openroad
```

---

## 15. รันงานเบื้องหลัง

รัน command เบื้องหลัง:

```bash
command &
```

ตัวอย่าง:

```bash
librelane config.yaml > run.log 2>&1 &
```

ดู jobs:

```bash
jobs
```

รันต่อแม้ปิด terminal:

```bash
nohup librelane config.yaml > run.log 2>&1 &
```

ดู PID ของ command ล่าสุด:

```bash
echo $!
```

---

## 16. ตรวจสอบพื้นที่ Disk และ Memory

| คำสั่ง                | ความหมาย                  |
| --------------------- | ------------------------- |
| `df -h`               | แสดงพื้นที่ filesystem    |
| `du -sh`              | แสดงขนาด directory        |
| `du -h --max-depth=1` | ขนาดแต่ละ directory       |
| `free -h`             | แสดง RAM                  |
| `lsblk`               | แสดง disk และ partition   |
| `mount`               | แสดง filesystem ที่ mount |

ตัวอย่าง:

```bash
df -h
du -sh runs/
du -h --max-depth=1 .
free -h
```

ค้นหา directory ที่ใช้พื้นที่มาก:

```bash
du -h --max-depth=1 . | sort -h
```

---

## 17. ข้อมูลระบบ

| คำสั่ง     | ความหมาย                   |
| ---------- | -------------------------- |
| `uname -a` | ข้อมูล kernel              |
| `hostname` | ชื่อเครื่อง                |
| `whoami`   | ชื่อผู้ใช้ปัจจุบัน         |
| `id`       | UID, GID และ groups        |
| `date`     | วันที่และเวลา              |
| `uptime`   | ระยะเวลาที่ระบบเปิด        |
| `lscpu`    | ข้อมูล CPU                 |
| `env`      | แสดง environment variables |

ตัวอย่าง:

```bash
uname -a
whoami
hostname
lscpu
```

ตรวจสอบ Linux distribution:

```bash
cat /etc/os-release
```

---

## 18. Environment Variables

แสดงค่า variable:

```bash
echo $HOME
echo $PATH
echo $PDK_ROOT
```

กำหนดค่าแบบชั่วคราว:

```bash
export PDK_ROOT="$HOME/pdks"
export PDK=ihp-sg13g2
```

เพิ่ม directory เข้า `PATH`:

```bash
export PATH="$HOME/tools/bin:$PATH"
```

ดู environment ทั้งหมด:

```bash
printenv
```

ค้นหา variable:

```bash
printenv | grep PDK
```

---

## 19. Archive และ Compression

### tar

สร้างไฟล์ archive:

```bash
tar -cvf project.tar project/
```

แตกไฟล์:

```bash
tar -xvf project.tar
```

บีบอัดด้วย gzip:

```bash
tar -czvf project.tar.gz project/
```

แตก `.tar.gz`:

```bash
tar -xzvf project.tar.gz
```

### zip

```bash
zip -r project.zip project/
unzip project.zip
```

ดูเนื้อหาโดยไม่แตก:

```bash
tar -tvf project.tar.gz
unzip -l project.zip
```

---

## 20. Network พื้นฐาน

| คำสั่ง     | ความหมาย                |
| ---------- | ----------------------- |
| `ip addr`  | แสดง IP address         |
| `ip route` | แสดง routing table      |
| `ping`     | ทดสอบการเชื่อมต่อ       |
| `curl`     | รับส่งข้อมูลผ่าน URL    |
| `wget`     | ดาวน์โหลดไฟล์           |
| `ssh`      | เชื่อมต่อเครื่องระยะไกล |
| `scp`      | คัดลอกไฟล์ผ่าน SSH      |
| `ss`       | ตรวจสอบ port และ socket |

ตัวอย่าง:

```bash
ip addr
ping github.com
curl -I https://github.com
wget https://example.com/file.tar.gz
```

เชื่อมต่อเครื่องอื่น:

```bash
ssh username@192.168.1.100
```

คัดลอกไฟล์:

```bash
scp config.yaml username@192.168.1.100:/home/username/
```

คัดลอก directory:

```bash
scp -r project/ username@192.168.1.100:/home/username/
```

---

## 21. Package Management บน Ubuntu/Debian

อัปเดตรายการ package:

```bash
sudo apt update
```

อัปเกรด package:

```bash
sudo apt upgrade
```

ติดตั้ง package:

```bash
sudo apt install git make gcc
```

ลบ package:

```bash
sudo apt remove package_name
```

ค้นหา package:

```bash
apt search package_name
```

ดู package ที่ติดตั้ง:

```bash
dpkg -l
```

ตรวจสอบตำแหน่ง package:

```bash
dpkg -L package_name
```

---

## 22. Git พื้นฐาน

```bash
git clone https://github.com/user/repository.git
git status
git add .
git commit -m "Update project"
git pull
git push
```

ดูประวัติ:

```bash
git log --oneline --graph --all
```

ดูความแตกต่าง:

```bash
git diff
```

สร้าง branch:

```bash
git switch -c new-feature
```

---

## 23. คำสั่งสำหรับ Build และ Compile

```bash
make
make clean
make all
make -j4
```

ใช้ทุก CPU core:

```bash
make -j"$(nproc)"
```

ดูจำนวน CPU core:

```bash
nproc
```

รัน Python:

```bash
python3 script.py
```

รัน Shell script:

```bash
bash run.sh
```

หรือ:

```bash
chmod +x run.sh
./run.sh
```

---

## 24. ตรวจสอบคำสั่งและขอความช่วยเหลือ

ดูคู่มือ:

```bash
man grep
man find
```

ดู help แบบย่อ:

```bash
grep --help
find --help
```

ค้นหาตำแหน่ง executable:

```bash
which python3
which librelane
```

ดู executable และ alias:

```bash
type python3
type ll
```

ค้นหาคำสั่งจากคำอธิบาย:

```bash
apropos "search files"
```

---

# ชุดคำสั่งที่ใช้บ่อยกับ LibreLane

กำหนด run directory:

```bash
RUN="librelane/runs/RUN_2026-08-07_05-23-55"
```

ค้นหา error และ warning:

```bash
grep -RniE "error|warning|failed|violation" "$RUN"
```

ค้นหารายงานทั้งหมด:

```bash
find "$RUN" -type f \( -name "*.rpt" -o -name "*.log" \)
```

ดู log ล่าสุด:

```bash
find "$RUN" -type f -name "*.log" -printf '%T@ %p\n' |
sort -n |
tail
```

ค้นหา DRC, LVS และ Antenna:

```bash
grep -RniE "DRC|LVS|Antenna|illegal overlap|density" "$RUN"
```

นับ error:

```bash
grep -Rhi "ERROR" "$RUN" | wc -l
```

ดูขนาด run:

```bash
du -sh "$RUN"
```

ดูไฟล์ผลลัพธ์สุดท้าย:

```bash
find "$RUN/final" -type f
```

ติดตาม log ขณะรัน:

```bash
tail -f run.log
```

รัน LibreLane พร้อมบันทึก log:

```bash
librelane config.yaml 2>&1 | tee run.log
```

## Cheat Sheet สั้น

```bash
pwd                         # ตำแหน่งปัจจุบัน
ls -alh                     # แสดงไฟล์ทั้งหมด
cd directory                # เข้า directory
cd ..                       # ย้อนหนึ่งระดับ
mkdir -p directory          # สร้าง directory
cp -r source destination    # คัดลอก
mv old new                  # ย้ายหรือเปลี่ยนชื่อ
rm -r directory             # ลบ directory
cat file                    # อ่านไฟล์
less file                   # อ่านไฟล์ยาว
tail -f file.log            # ติดตาม log
grep -Rni "ERROR" .         # ค้นหา error
find . -name "*.v"          # ค้นหาไฟล์ Verilog
chmod +x script.sh          # ทำ script ให้รันได้
ps aux                      # ดู process
kill PID                    # หยุด process
df -h                       # ดูพื้นที่ disk
du -sh directory            # ดูขนาด directory
free -h                     # ดู RAM
tar -czvf backup.tar.gz dir # บีบอัด
tar -xzvf backup.tar.gz     # แตกไฟล์
ssh user@host               # เข้าเครื่องระยะไกล
sudo apt install package    # ติดตั้ง package
command --help              # ดูวิธีใช้
man command                 # เปิดคู่มือ
```
