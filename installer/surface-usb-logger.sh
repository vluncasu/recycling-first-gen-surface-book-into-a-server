#!/bin/sh
# Debian Installer USB logger for v5. Writes to independent FAT32 partition
# SURFACELOG, embedded in the same USB image as the read-only installer.
# Best-effort, NON-FATAL. Starts when preseed becomes available.
set +e
M=/tmp/surface-log-stick
PID=/tmp/surface-usb-logger.pid

find_volume() {
  if [ -b /dev/disk/by-label/SURFACELOG ]; then
    echo /dev/disk/by-label/SURFACELOG
    return 0
  fi
  # Debian Installer BusyBox may not offer /dev/disk/by-label.
  for dev in /dev/sd[a-z][1-9] /dev/nvme*n*p[1-9]; do
    [ -b "$dev" ] || continue
    label="$(blkid -s LABEL -o value "$dev" 2>/dev/null)"
    [ "$label" = SURFACELOG ] && { echo "$dev"; return 0; }
  done
  return 1
}

mount_volume() {
  [ -d "$M" ] || mkdir -p "$M"
  grep -q " $M " /proc/mounts && return 0
  dev="$(find_volume)" || return 1
  modprobe fat >/dev/null 2>&1 || :
  modprobe vfat >/dev/null 2>&1 || :
  mount -t vfat -o rw,sync "$dev" "$M" >/dev/null 2>&1 || return 1
  return 0
}

snapshot() {
  # If FAT32 was briefly absent, it can be rediscovered on the next pass.
  mount_volume || return 1
  {
    echo 'SURFACE BOOK 1 - DEBIAN INSTALLER USB LOGGER'
    echo "UTC: $(date -u)"
    echo "PHASE: ${1:-running}"
    echo "Installer syslog: ${2:-/var/log/syslog}"
    echo 'Output is best-effort, every ~15 seconds. Last writes may be lost on hard freeze.'
  } > "$M/STATUS.TXT"
  if [ -f /var/log/syslog ]; then
    tail -n 8000 /var/log/syslog > "$M/INSTALLER.LOG.tmp" && mv -f "$M/INSTALLER.LOG.tmp" "$M/INSTALLER.LOG"
  fi
  if [ -f /var/log/syslog ]; then
    grep -iE 'error|failed|failure|grub|efi|partman|no space|mount' /var/log/syslog | tail -n 300 > "$M/ERORI.TXT.tmp"
    mv -f "$M/ERORI.TXT.tmp" "$M/ERORI.TXT"
  fi
  if [ -f /var/log/partman ]; then
    tail -n 4000 /var/log/partman > "$M/PARTMAN.LOG.tmp" && mv -f "$M/PARTMAN.LOG.tmp" "$M/PARTMAN.LOG"
  fi
  dmesg 2>/dev/null | tail -n 1500 > "$M/DMESG.LOG.tmp" && mv -f "$M/DMESG.LOG.tmp" "$M/DMESG.LOG"
  {
    echo 'EFI presence:'; ls -ld /sys/firmware/efi 2>&1
    echo 'USB logs mounted:'; grep " $M " /proc/mounts
    echo 'Target mount:'; grep ' /target ' /proc/mounts
    echo 'Devices:'; ls /dev/nvme* /dev/sd* 2>/dev/null
  } > "$M/HARDWARE.TXT"
  sync
}

case "${1:-}" in
  start)
    snapshot 'preseed-loaded' || {
      echo 'SURFACELOG could not be mounted; USB logger disabled' >> /var/log/syslog 2>/dev/null
      exit 0
    }
    if [ -f "$PID" ] && kill -0 "$(cat "$PID")" 2>/dev/null; then exit 0; fi
    (
      trap '' HUP
      while :; do
        /bin/sh /cdrom/surface-usb-logger.sh snapshot >/dev/null 2>&1
        sleep 15
      done
    ) </dev/null >/dev/null 2>&1 &
    echo $! > "$PID"
    ;;
  snapshot)
    snapshot 'installer-running'
    ;;
  success)
    snapshot 'installer-configured' || :
    if mount_volume; then
       echo 'Debian installer completed late_command. Boot and network SSH NOT YET verified.' > "$M/INSTALL_CONFIGURED.txt"
       sync
    fi
    ;;
  *)
    echo 'Usage: surface-usb-logger.sh start|snapshot|success' >&2
    exit 1
    ;;
esac
exit 0
