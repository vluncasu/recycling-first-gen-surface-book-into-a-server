#!/bin/sh
# Runs immediately before Debian autopartition; fail closed on any mismatch.
set -eu
FAIL=/var/log/surface-disk-guard-error.txt
bad() {
    printf 'ABORT INSTALL: %s\n' "$1" | tee "$FAIL" >/dev/console
    /bin/sh /cdrom/surface-usb-logger.sh snapshot || :
    exit 1
}
[ -d /sys/firmware/efi ] || bad 'Firmware UEFI not detected'
[ -b /dev/nvme0n1 ] || bad 'Expected internal /dev/nvme0n1 not found'
MODEL="$(cat /sys/class/nvme/nvme0/model 2>/dev/null || cat /sys/block/nvme0n1/device/model 2>/dev/null || true)"
case "$MODEL" in
  *__EXPECTED_SSD_MODEL__*) ;;
  *) bad "SSD model mismatch (actual: $MODEL)" ;;
esac
BYTES="$(cat /sys/block/nvme0n1/size 2>/dev/null || echo 0)"
# /sys/block/.../size is in 512-byte sectors; Validated SSD capacity range, originally ~256 GB.
[ "$BYTES" -ge 460000000 ] && [ "$BYTES" -le 530000000 ] || bad 'Unexpected SSD capacity'
# In case multiple NVMe disk namespaces exist, do not continue unattended.
CNT=0
for d in /sys/block/nvme*n*; do [ -e "$d" ] && CNT=$((CNT+1)); done
[ "$CNT" -eq 1 ] || bad "Unexpected number of NVMe block devices: $CNT"
echo "GUARD OK: $(date) /dev/nvme0n1 [$MODEL] $BYTES sectors" >/var/log/surface-disk-guard-ok.txt
/bin/sh /cdrom/surface-usb-logger.sh snapshot || :
