#!/bin/bash
echo "Mendownload Kernel 6.1.1..."
wget -nc https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.1.1.tar.xz
tar -xf linux-6.1.1.tar.xz
cd linux-6.1.1

# Generate konfigurasi default
make defconfig

echo "Mengkompilasi Kernel (ini memakan waktu agak lama)..."
make -j$(nproc) bzImage

echo "Memindahkan hasil build..."
cp arch/x86/boot/bzImage ../osboot/bzImage
echo "Selesai!"
