ปัญหา Nix หา `<nixpkgs>` ไม่พบ เนื่องจาก **channel ยังไม่ได้ติดตั้ง/อัปเดต หรือค่า `NIX_PATH` ว่างหรือผิด** 

เมื่อ `NIX_PATH` ว่าง การอ้าง `<nixpkgs>` ล้มเหลว

ให้ออกจาก `nix-shell` ก่อน แล้วทำตามนี้ใน Ubuntu/WSL terminal ปกติ:

```bash
exit
```

ตรวจสอบสถานะ:

```bash
echo "NIX_PATH=$NIX_PATH"
nix-channel --list
ls -la ~/.nix-defexpr/channels 2>/dev/null
cat ~/.nix-channels 2>/dev/null
```

จากนั้นเพิ่ม channel ใหม่ให้ถูกต้อง:

```bash
nix-channel --remove nixpkgs 2>/dev/null || true

nix-channel --add \
  https://nixos.org/channels/nixpkgs-unstable \
  nixpkgs

nix-channel --update
```

โหลด environment ของ Nix ใหม่:

```bash
if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    source "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi
```

ตรวจสอบว่า `<nixpkgs>` ใช้งานได้แล้ว:

```bash
nix-instantiate --find-file nixpkgs
```

ผลลัพธ์ควรเป็น path ประมาณ:

```text
/home/semi09/.nix-defexpr/channels/nixpkgs
```

หรือ:

```text
/nix/store/...-nixpkgs-.../nixpkgs
```

แล้วทดสอบ:

```bash
nix-shell -p hello
```

เมื่อเข้า shell ได้ ให้ลอง LibreLane อีกครั้ง:

```bash
nix-shell ~/eda/librelane/shell.nix
```

หรือวิธีที่เหมาะกว่า คือเข้าไปใน repository ก่อน:

```bash
cd ~/eda/librelane
nix-shell
```

### หากยังพบ error เดิม

มีโอกาสว่าใน `~/.bashrc` มีการกำหนด `NIX_PATH` เป็นค่าว่าง ตรวจสอบด้วย:

```bash
grep -n "NIX_PATH" \
  ~/.bashrc ~/.profile ~/.bash_profile 2>/dev/null
```

หากพบข้อความลักษณะนี้:

```bash
export NIX_PATH=
```

หรือ:

```bash
export NIX_PATH=""
```

ให้ลบหรือ comment:

```bash
# export NIX_PATH=
```

แล้วเปิด terminal ใหม่ หรือรัน:

```bash
unset NIX_PATH
source ~/.bashrc
```

จากนั้นทดสอบอีกครั้ง:

```bash
nix-instantiate --find-file nixpkgs
nix-shell -p hello
```

### วิธีแก้ชั่วคราวด้วย `-I`

ถ้า channel อัปเดตสำเร็จแต่ Nix ยังไม่เห็น สามารถระบุ path โดยตรง:

```bash
nix-shell \
  -I nixpkgs="$HOME/.nix-defexpr/channels/nixpkgs" \
  ~/eda/librelane/shell.nix
```

แต่แนะนำให้แก้ channel และ `NIX_PATH` ให้ถูกต้องก่อน เพราะ `nix-shell` ใช้ `<nixpkgs>` เพื่อเลือก shell ที่จะเปิดด้วย ([Nix][2])

ชุดคำสั่งรวบรัดที่ควรแก้ปัญหาได้คือ:

```bash
exit 2>/dev/null || true
unset NIX_PATH

nix-channel --remove nixpkgs 2>/dev/null || true
nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs
nix-channel --update

source "$HOME/.nix-profile/etc/profile.d/nix.sh"

nix-instantiate --find-file nixpkgs
nix-shell -p hello

cd ~/eda/librelane
nix-shell
```

[1]: https://nix.dev/manual/nix/2.35/command-ref/nix-channel.html?utm_source=chatgpt.com "nix-channel - Nix 2.35.2 Reference Manual"
[2]: https://nix.dev/manual/nix/2.35/command-ref/nix-shell.html?search=shell.nix&utm_source=chatgpt.com "nix-shell - Nix 2.35.2 Reference Manual"
