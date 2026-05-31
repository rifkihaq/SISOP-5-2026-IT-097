#!/bin/bash
echo "Memulai pembuatan Multi-User Filesystem..."

# 1. Membuat folder dasar
mkdir -p initramfs_multi/{bin,dev,proc,sys,etc,tmp,root}
mkdir -p initramfs_multi/home/{henn,hann,viii,kids}

# 2. Menyalin busybox
cp $(which busybox) initramfs_multi/bin/

# 3. Membuat file passwd (daftar user)
cat << 'EOF' > initramfs_multi/etc/passwd
root:x:0:0:root:/root:/bin/sh
henn:x:1001:1001:henn:/home/henn:/bin/sh
hann:x:1002:1002:hann:/home/hann:/bin/sh
viii:x:1003:1003:viii:/home/viii:/bin/sh
kids:x:1004:1004:kids:/home/kids:/bin/sh
EOF

# 4. Membuat file group (untuk trik hak akses)
cat << 'EOF' > initramfs_multi/etc/group
root:x:0:
henn:x:1001:
hann:x:1002:henn
viii:x:1003:henn,hann
kids:x:1004:henn,hann,viii
EOF

# 5. Membuat file shadow (password default: 12345 untuk semua user agar mudah di-test)
cat << 'EOF' > initramfs_multi/etc/shadow
root:$1$O3JMY.T.$xK1wO8z4.W.rO9xK4.P.Q/:19000:0:99999:7:::
henn:$1$O3JMY.T.$xK1wO8z4.W.rO9xK4.P.Q/:19000:0:99999:7:::
hann:$1$O3JMY.T.$xK1wO8z4.W.rO9xK4.P.Q/:19000:0:99999:7:::
viii:$1$O3JMY.T.$xK1wO8z4.W.rO9xK4.P.Q/:19000:0:99999:7:::
kids:$1$O3JMY.T.$xK1wO8z4.W.rO9xK4.P.Q/:19000:0:99999:7:::
EOF

# 6. Mengatur Hak Akses (Permissions)
chmod 755 initramfs_multi/bin initramfs_multi/etc initramfs_multi/proc initramfs_multi/sys
chmod 777 initramfs_multi/tmp
chmod 700 initramfs_multi/root

chown -R 1001:1001 initramfs_multi/home/henn && chmod 700 initramfs_multi/home/henn
chown -R 1002:1002 initramfs_multi/home/hann && chmod 770 initramfs_multi/home/hann
chown -R 1003:1003 initramfs_multi/home/viii && chmod 770 initramfs_multi/home/viii
chown -R 1004:1004 initramfs_multi/home/kids && chmod 770 initramfs_multi/home/kids

# 7. Membuat Banner Sambutan
cat << 'EOF' > initramfs_multi/etc/profile
clear
echo "=================================================="
echo "  ______                                 _ _      "
echo " |  ____|                               | | |     "
echo " | |__ __ _ _ __ _____      _____  ___  | | |     "
echo " |  __/ _' | '__/ _ \ \ /\ / / _ \/ _ \ | | |     "
echo " | | | (_| | | |  __/\ V  V /  __/  __/ |_|_|     "
echo " |_|  \__,_|_|  \___| \_/\_/ \___|\___| (_)(_)    "
echo "                                                  "
echo "               _____              _ _             "
echo "              |  __ \            | | |            "
echo "              | |__) |__ _ _ __  | | |_ _   _     "
echo "              |  ___/ _' | '__|  | | __| | | |    "
echo "              | |  | (_| | |     | | |_| |_| |    "
echo "              |_|   \__,_|_|     |_|\__|\__, |    "
echo "                                         __/ |    "
echo "                                        |___/     "
echo "=================================================="
echo "Welcome, $USER"
echo ""
EOF

# 8. Membuat program init (Yang pertama kali jalan)
cat << 'EOF' > initramfs_multi/init
#!/bin/busybox sh
/bin/busybox --install -s /bin
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs dev /dev

# Pengaturan Jaringan (Opsional untuk soal no 8)
ip link set lo up
ip link set eth0 up
udhcpc -i eth0 > /dev/null 2>&1

# Memulai program login berulang-ulang
while true; do
    /bin/login
done
EOF

chmod +x initramfs_multi/init

# =================================================================
# TAMBAHAN FITUR: NOMOR 8, 9, DAN 10
# =================================================================

# --- NOMOR 8: Bypass TLS untuk wget ---
echo "Menambahkan bypass TLS untuk wget..."
echo "alias wget='wget --no-check-certificate'" >> initramfs_multi/etc/profile


# --- NOMOR 9: Membuat Package Manager 'party' ---
echo "Membuat package manager party..."
cat << 'EOF' > initramfs_multi/bin/party
#!/bin/busybox sh

if [ "$1" == "install" ] && [ -n "$2" ]; then
    echo "Mencari paket $2..."
    # Contoh download package dari internet (sesuaikan URL jika ada dari modul)
    wget -qO /tmp/pkg.tar.gz "http://contoh-server-lab.com/$2.tar.gz"
    
    if [ $? -eq 0 ]; then
        echo "Mengekstrak paket $2..."
        tar -xzf /tmp/pkg.tar.gz -C /
        echo "Paket $2 berhasil diinstall!"
    else
        echo "Gagal mengunduh paket $2."
    fi
else
    echo "Penggunaan: party install <nama_paket>"
fi
EOF

chmod +x initramfs_multi/bin/party


# --- NOMOR 10: Memasukkan Program FUSE dan Shared Libraries ---
echo "Memasukkan program FUSE dan dependencies-nya..."

# PENTING: Pastikan kamu sudah meng-compile file FUSE-mu di host 
# dengan nama 'program_fuse' di folder yang sama sebelum menjalankan script ini!
if [ -f "program_fuse" ]; then
    cp program_fuse initramfs_multi/bin/
    
    # Membuat folder untuk library pendukung
    mkdir -p initramfs_multi/lib initramfs_multi/lib64
    
    # Copy library otomatis (.so) milik program_fuse dan busybox ke dalam OS kustom
    ldd initramfs_multi/bin/program_fuse | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v '{}' initramfs_multi/lib/
    ldd initramfs_multi/bin/program_fuse | grep "ld-linux" | awk '{print $1}' | xargs -I '{}' cp -v '{}' initramfs_multi/lib64/ || true
    ldd initramfs_multi/bin/busybox | grep "ld-linux" | awk '{print $1}' | xargs -I '{}' cp -v '{}' initramfs_multi/lib64/ || true
    
    # Membuat device node untuk FUSE agar dikenali kernel
    mknod -m 666 initramfs_multi/dev/fuse c 10 229
else
    echo "⚠️ Peringatan: file 'program_fuse' tidak ditemukan di folder host!"
    echo "Silakan compile dulu program FUSE C kamu dengan nama 'program_fuse' agar bisa dimasukkan."
fi

# =================================================================

# 9. Membungkus folder menjadi file multi.gz
echo "Membungkus OS..."
cd initramfs_multi
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../osboot/multi.gz
cd ..

# Membersihkan sisa folder kerja
rm -rf initramfs_multi

echo "Selesai! File multi.gz siap digunakan."
