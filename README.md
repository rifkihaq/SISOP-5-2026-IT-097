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
│   ├── kernel.sh       # Download & kompilasi Linux Kernel 6.1.1
│   ├── single.sh       # Build single-user initramfs
│   ├── multi.sh        # Build multi-user initramfs (+ fitur nomor 8, 9, 10)
│   ├── iso.sh          # Buat bootable ISO dengan GRUB
│   ├── qemu.sh         # Jalankan OS di QEMU
│   └── backup.sh       # Backup semua file build ke ZIP
└── .gitignore
```

---

## 📝 Soal 1 — Membangun Custom Linux OS "Farewell Party"

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

