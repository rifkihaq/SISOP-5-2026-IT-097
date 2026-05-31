#!/bin/bash
mkdir -p isodir/boot/grub
cp osboot/bzImage isodir/boot/
cp osboot/single.gz isodir/boot/
cp osboot/multi.gz isodir/boot/

# Buat menu GRUB
cat << 'EOF' > isodir/boot/grub/grub.cfg
menuentry "Farewell Party - Single User" {
    linux /boot/bzImage console=ttyS0
    initrd /boot/single.gz
}
menuentry "Farewell Party - Multi User" {
    linux /boot/bzImage console=ttyS0
    initrd /boot/multi.gz
}
EOF

grub-mkrescue -o osboot/farewell.iso isodir
rm -rf isodir
echo "ISO berhasil dibuat!"
