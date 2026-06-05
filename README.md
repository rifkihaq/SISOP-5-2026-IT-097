# Praktikum Sistem Operasi — Modul 5

---

| NRP | Nama |
|-----|------|
| `5027251097` | Muhammad Salman Rifki Haq |

---

## 📁 Struktur Repository

```
SISOP-5-2026-IT-097/
├── soal1/
│   ├── kernel.sh
│   ├── single.sh
│   ├── multi.sh
│   ├── iso.sh
│   ├── qemu.sh
│   └── backup.sh
└── soal2/
    └── template/
        ├── bootloader.asm      # Bootloader 512-byte (MBR)
        ├── kernel.asm          # Entry point kernel + fungsi getChar
        ├── kernel.c            # Logika utama OS & command handler
        ├── util.c              # Library utilitas (print, read, string)
        ├── Makefile            # Build & run dengan Bochs (Linux)
        ├── build.sh            # Build script alternatif via Docker (macOS)
        ├── bochsrc.txt         # Konfigurasi emulator Bochs
        └── floppy.img          # Image floppy disk hasil build
```

---

## 📝 Soal 1 — Custom Linux OS "Farewell Party"
### Deskripsi
Membuat sistem operasi Linux minimal dari nol menggunakan **Linux Kernel 6.1.1** dan **BusyBox**, yang dapat berjalan di emulator **QEMU**. OS ini memiliki dua mode: *single-user* dan *multi-user*, serta dilengkapi bootable ISO menggunakan GRUB.

---

### 🔧 Urutan Penggunaan

Jalankan script secara berurutan dari folder `soal1/`:

```bash
cd soal1
```

#### 1️⃣ `kernel.sh` — Download & Kompilasi Kernel

```bash
bash kernel.sh
```

**Yang dilakukan script ini:**
- Mengunduh source code **Linux Kernel versi 6.1.1** dari kernel.org
- Mengekstrak dan menghasilkan konfigurasi default dengan `make defconfig`
- Mengkompilasi kernel (`bzImage`) menggunakan semua core CPU yang tersedia (`-j$(nproc)`)
- Menyalin hasil build ke folder `osboot/bzImage`

> ⏳ Proses kompilasi kernel memakan waktu cukup lama (bisa 15–60 menit tergantung spesifikasi mesin).

---

#### 2️⃣ `single.sh` — Build Single-User Filesystem

```bash
bash single.sh
```

**Yang dilakukan script ini:**
- Membuat struktur direktori minimal initramfs: `bin`, `dev`, `proc`, `sys`, `etc`, `tmp`, `root`
- Menyalin **BusyBox** dari sistem host sebagai pengganti utilitas Linux standar
- Membuat script `init` yang:
  - Menginstall semua symlink BusyBox
  - Me-mount filesystem virtual (`proc`, `sysfs`, `devtmpfs`)
  - Menyiapkan jaringan (`lo` dan `eth0` via `udhcpc`)
  - Menjalankan shell interaktif (`/bin/sh`)
- Membungkus semua file menjadi `osboot/single.gz` menggunakan `cpio` + `gzip`

---

#### 3️⃣ `multi.sh` — Build Multi-User Filesystem

```bash
bash multi.sh
```

**Yang dilakukan script ini:**

- Membuat struktur direktori initramfs lengkap beserta home directory untuk setiap user
- Mendefinisikan **5 user** dengan hierarki grup:

| User  | UID  | Grup yang diikuti        | Permission Home |
|-------|------|--------------------------|-----------------|
| root  | 0    | root                     | `700`           |
| henn  | 1001 | henn                     | `700`           |
| hann  | 1002 | hann (+ henn bisa akses) | `770`           |
| viii  | 1003 | viii (+ henn, hann)      | `770`           |
| kids  | 1004 | kids (+ henn, hann, viii)| `770`           |

- Membuat file `passwd`, `group`, dan `shadow` (password default semua user: `12345`)
- Menampilkan **ASCII Art Banner "Farewell Party"** saat login melalui `/etc/profile`
- Menjalankan `/bin/login` secara loop agar user bisa login berulang kali
- Membungkus semua file menjadi `osboot/multi.gz`

**Fitur tambahan yang disertakan di `multi.sh`:**

- **Nomor 8** — Bypass TLS untuk `wget` via alias `--no-check-certificate` di `/etc/profile`
- **Nomor 9** — Package manager sederhana bernama `party` dengan perintah `party install <nama_paket>`
- **Nomor 10** — Integrasi program **FUSE** beserta shared library-nya (`.so`) dan pembuatan device node `/dev/fuse`

> ⚠️ Untuk fitur Nomor 10, compile dahulu program FUSE (`program_fuse`) di folder `soal1/` sebelum menjalankan `multi.sh`.

---

#### 4️⃣ `iso.sh` — Buat Bootable ISO

```bash
bash iso.sh
```

**Yang dilakukan script ini:**
- Membuat struktur direktori ISO (`isodir/boot/grub/`)
- Menyalin `bzImage`, `single.gz`, dan `multi.gz` ke dalam ISO
- Membuat konfigurasi **GRUB** dengan dua menu boot:
  - `Farewell Party - Single User`
  - `Farewell Party - Multi User`
- Menghasilkan `osboot/farewell.iso` menggunakan `grub-mkrescue`

---

#### 5️⃣ `qemu.sh` — Jalankan OS di QEMU

```bash
# Mode Single User
bash qemu.sh --single

# Mode Multi User
bash qemu.sh --multi

# Mode ISO (Bootable ISO dengan GRUB)
bash qemu.sh --all
```

| Argumen    | Deskripsi                                      |
|------------|------------------------------------------------|
| `--single` | Boot kernel langsung dengan `single.gz`        |
| `--multi`  | Boot kernel langsung dengan `multi.gz`         |
| `--all`    | Boot dari ISO `farewell.iso` (menampilkan GRUB)|

---

#### 6️⃣ `backup.sh` — Backup File Build

```bash
bash backup.sh
```

**Yang dilakukan script ini:**
- Membuat arsip ZIP bernama `farewell_backup_<DDMMYYYY-HHMMSS>.zip`
- Menyimpan `bzImage`, `single.gz`, `multi.gz`, dan `farewell.iso` ke dalam ZIP
- Menghapus file asli setelah backup berhasil

---

### 🛠️ Prasyarat

Pastikan paket berikut sudah terinstall di sistem host sebelum menjalankan script:

```bash
sudo apt update
sudo apt install -y build-essential wget tar busybox-static \
    qemu-system-x86 grub-pc-bin grub-efi-amd64-bin mtools \
    libfuse-dev fuse
```

---
# revisi
## ⚠️ Kendala & Solusi

| Kendala | Solusi |
|---------|--------|
| Kompilasi kernel sangat lama | Gunakan `make -j$(nproc)` (sudah diterapkan) |
| Program FUSE tidak terbaca di dalam OS | Pastikan semua `.so` library ikut di-copy via `ldd` |
| Login tidak bisa masuk | Cek file `/etc/shadow` — pastikan hash password benar |
| `grub-mkrescue` gagal | Install `mtools` dan `grub-pc-bin` di host |

---


---

## 📝 Soal 2 — Bare-Metal OS dengan Assembly & C

### Deskripsi

Membangun sistem operasi sederhana dari nol tanpa bantuan kernel Linux, menggunakan **Assembly x86 16-bit** dan **C bare-metal** (bcc). OS ini berjalan langsung di atas hardware melalui emulator **Bochs**, dimuat dari floppy disk image, dan menyediakan antarmuka command-line interaktif bernama **"Assistant's Last Gift"**.

---

### 🏗️ Arsitektur Sistem

```
[ Bochs Emulator ]
        |
        v
[ floppy.img ] <-- dibaca dari sektor 0
        |
        v
[ bootloader.asm ]  → Sektor 0 (MBR, 512 byte)
   - Mode Real 16-bit
   - Load kernel ke alamat 0x1000:0000
   - Far jump ke kernel
        |
        v
[ kernel.asm ]      → Entry point _start
   - Setup segment register (CS, DS, ES)
   - Panggil fungsi _main() di kernel.c
   - Implementasi _getChar() via BIOS int 0x16
        |
        v
[ kernel.c ]        → Logika utama & command handler
        |
[ util.c ]          → Library: print, read, string, math
```

---

### 💻 Fitur Command-Line OS

OS menyediakan prompt interaktif `> ` dengan perintah berikut:

| Perintah | Contoh | Output |
|----------|--------|--------|
| `help` | `help` | Menampilkan daftar perintah |
| `check` | `check` | Menampilkan `ok` |
| `clear` | `clear` | Membersihkan layar |
| `add <a> <b>` | `add 3 5` | `8` |
| `sub <a> <b>` | `sub 10 4` | `6` |
| `fac <n>` | `fac 5` | `120` (maks n=7) |
| `season <nama>` | `season winter` | Ganti warna teks |
| `triangle <n>` | `triangle 4` | Segitiga bintang `x` |

#### 🎨 Mode Warna (`season`)

| Season | Warna Teks |
|--------|------------|
| `winter` | Biru (`0x09`) |
| `spring` | Hijau (`0x0A`) |
| `summer` | Kuning (`0x0E`) |
| `fall` | Merah (`0x0C`) |
| `radiant` | Magenta (`0x0D`) |

---

### 📄 Penjelasan File

#### `bootloader.asm`
Bootloader 512-byte yang dimuat BIOS dari sektor pertama floppy:
- Inisialisasi segment register dan stack pointer ke `0x7C00`
- Memuat **15 sektor kernel** ke memori di alamat `0x1000:0000` via BIOS interrupt `int 0x13`
- Melakukan **far jump** ke kernel setelah berhasil dimuat
- Menampilkan pesan `DISK ERROR` jika pembacaan disk gagal
- Diakhiri dengan boot signature `0xAA55`

#### `kernel.asm`
Entry point kernel dalam Assembly 16-bit:
- Label `_start`: setup segment register (`DS`, `ES`) dari `CS`, lalu memanggil `_main()` dari `kernel.c`
- Fungsi `_putInMemory`: menulis byte ke alamat memori absolut (digunakan untuk menulis ke VGA buffer `0xB800`)
- Fungsi `_getChar`: membaca karakter dari keyboard via **BIOS interrupt `int 0x16`** (service `0x00`), mengembalikan kode ASCII di `AL`

#### `kernel.c`
Logika utama OS menggunakan sintaks **C lama (K&R style)** kompatibel dengan compiler `bcc`:
- `main()`: Loop utama yang membaca input user dan memanggil `handleCommand()`
- `handleCommand()`: Router perintah menggunakan `strcmp` dan `startsWith`
- `doAddSub()`: Parsing dua angka dari string perintah, lalu operasi penjumlahan/pengurangan
- `doFac()`: Menghitung faktorial (dibatasi `n ≤ 7` untuk menghindari overflow)
- `doSeason()` / `doSeasonPart2()`: Mengubah variabel global `color` sesuai musim yang dipilih
- `doTriangle()`: Mencetak segitiga karakter `x` sebanyak `n` baris

#### `util.c`
Library utilitas yang berinteraksi langsung dengan hardware VGA dan keyboard:
- `printChar(c)`: Menulis karakter + atribut warna ke **VGA text buffer** (`0xB800`) menggunakan `putInMemory`
- `printString(str)`: Loop `printChar` untuk setiap karakter string
- `newline()`: Memindahkan `cursor` ke baris berikutnya (setiap baris = 160 byte)
- `clearScreen()`: Mengisi seluruh VGA buffer dengan spasi, reset cursor ke 0
- `readString(buf)`: Membaca input keyboard karakter per karakter, mendukung **backspace** dan batas 63 karakter
- `strcmp()`: Perbandingan dua string, return `1` jika sama
- `startsWith()`: Cek apakah string diawali prefix tertentu
- `atoi()`: Konversi string angka ke integer
- `intToString()`: Konversi integer ke string (mendukung negatif, maks 3 digit)
- `factorial(n)`: Iteratif, return `n!`

---

### 🛠️ Cara Build & Menjalankan

#### Prasyarat

**Linux:**
```bash
sudo apt install -y nasm bcc bin86 bochs bochs-x
```

**macOS:** Gunakan `build.sh` yang sudah menyertakan Docker.

---

#### Build & Run (Linux — via Makefile)

```bash
cd soal2/template

# Build semua (buat floppy.img, compile bootloader & kernel)
make build

# Jalankan di emulator Bochs
make run
```

Makefile menjalankan langkah-langkah berikut secara otomatis:

| Target | Perintah | Keterangan |
|--------|----------|------------|
| `prepare` | `dd if=/dev/zero ...` | Buat floppy.img kosong 1.44MB |
| `bootloader` | `nasm -f bin` + `dd` | Compile & tulis bootloader ke sektor 0 |
| `kernel` | `nasm` + `bcc` + `ld86` + `dd` | Compile & tulis kernel ke sektor 1–15 |
| `run` | `bochs -f bochsrc.txt` | Jalankan OS di Bochs |

---

#### Build (macOS — via Docker)

```bash
cd soal2/template
bash build.sh
```

Script ini otomatis menjalankan Docker container Ubuntu 22.04 yang berisi `nasm`, `bcc`, dan `bin86` untuk melakukan kompilasi lintas platform.

---

### ⚙️ Konfigurasi Bochs (`bochsrc.txt`)

| Parameter | Nilai | Keterangan |
|-----------|-------|------------|
| `megs` | `32` | RAM virtual 32 MB |
| `romimage` | SeaBIOS | BIOS firmware |
| `boot` | `floppy` | Boot dari floppy disk |
| `floppya` | `floppy.img` | File image floppy 1.44MB |
| `display_library` | `term` | Output di terminal (tidak butuh GUI) |
| `log` | `bochslog.txt` | Log debug emulator |

---

### ⚠️ Kendala & Solusi

| Kendala | Solusi |
|---------|--------|
| `bcc` tidak tersedia di macOS | Gunakan `build.sh` dengan Docker |
| Bochs tidak bisa tampil tanpa GUI | Pastikan `display_library: term` di `bochsrc.txt` |
| Kernel tidak termuat (disk error) | Pastikan `KERNEL_SECTORS` di `bootloader.asm` sesuai ukuran kernel |
| Overflow pada `intToString` | Fungsi hanya mendukung bilangan maks 3 digit; `fac` dibatasi `n ≤ 7` |
| `ld86` error saat linking | Gunakan flag `-0 -d` dan urutkan `kernel-asm.o` sebelum `kernel.o` |

---
