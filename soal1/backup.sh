#!/bin/bash
TIMESTAMP=$(date +"%d%m%Y-%H%M%S")
FILENAME="farewell_backup_${TIMESTAMP}.zip"

cd osboot
zip $FILENAME bzImage single.gz multi.gz farewell.iso
rm bzImage single.gz multi.gz farewell.iso
echo "Backup berhasil disimpan di osboot/$FILENAME"
