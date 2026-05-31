#!/bin/bash
mkdir -p initramfs_single/{bin,dev,proc,sys,etc,tmp,root}

# Copy busybox dari sistem host
cp $(which busybox) initramfs_single/bin/

# Membuat script 'init' (program pertama yang dijalankan kernel)
cat << 'EOF' > initramfs_single/init
#!/bin/busybox sh
/bin/busybox --install -s /bin
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs dev /dev
# Setup Jaringan (Untuk soal no 8)
ip link set lo up
ip link set eth0 up
udhcpc -i eth0
exec /bin/sh
EOF

chmod +x initramfs_single/init

# Membungkus menjadi single.gz
cd initramfs_single
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../osboot/single.gz
cd ..
rm -rf initramfs_single # Hapus sisa file
echo "Single filesystem selesai di-build!"
