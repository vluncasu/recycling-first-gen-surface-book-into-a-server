#!/bin/bash
# Executed once by Debian Installer chroot. Essential failures abort installation.
set -euo pipefail
exec >> /var/log/surface-postinstall.log 2>&1
printf "Beginning Surface setup at %s\n" "$(date -u)"
# Ensure prerequisites (already installed by pkgsel/include).
for cmd in /usr/sbin/usermod /usr/bin/systemctl /usr/sbin/sshd /usr/bin/nmcli /usr/bin/docker; do
  test -x "$cmd" || { echo "Missing prerequisite: $cmd"; exit 1; }
done
/usr/sbin/usermod -aG sudo,docker __USERNAME__
# Ensure credentials/user are actually present before we claim completion.
id __USERNAME__ >/dev/null
getent group docker >/dev/null
mkdir -p /run/sshd
chmod 0755 /run/sshd
/usr/sbin/sshd -t
mkdir -p /etc/systemd/logind.conf.d /etc/ssh/sshd_config.d
cat >/etc/systemd/logind.conf.d/10-surface-server.conf <<'END'
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
IdleAction=ignore
END
cat >/etc/ssh/sshd_config.d/55-weparty.conf <<'END'
PermitRootLogin no
PasswordAuthentication yes
KbdInteractiveAuthentication no
END
/usr/sbin/sshd -t
# NetworkManager owns both wired and wireless (avoids ifupdown conflicts).
cat >/etc/network/interfaces <<'END'
auto lo
iface lo inet loopback
END
mkdir -p /etc/NetworkManager/system-connections
cat >/etc/NetworkManager/system-connections/Wired-primary.nmconnection <<'END'
[connection]
id=Wired-primary
type=ethernet
autoconnect=true
autoconnect-priority=10

[ethernet]

[ipv4]
method=auto
route-metric=100

[ipv6]
method=auto
route-metric=100
END
chmod 600 /etc/NetworkManager/system-connections/*.nmconnection
# No sleep on lid close or when the AC power is lost.
/usr/bin/systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target || true
for unit in ssh.service avahi-daemon.service docker.service NetworkManager.service cockpit.socket; do
  /usr/bin/systemctl enable "$unit"
done
# Make first-boot inspection/report automatic.
mkdir -p /usr/local/sbin /var/lib/__HOSTNAME__
cat >/usr/local/sbin/surface-firstboot-check <<'END'
#!/bin/bash
set -u
LOG=/var/log/surface-firstboot.log
exec >"$LOG" 2>&1
echo "Surface Book edge node check: $(date -u -Is)"
echo '--- system ---'
uname -a
hostnamectl || true
echo '--- disks ---'
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS,MODEL || true
df -h / /boot/efi || true
echo '--- network ---'
nmcli device status || true
ip -brief address || true
ip route || true
echo '--- services ---'
for unit in ssh avahi-daemon docker NetworkManager cockpit.socket; do
  printf '%s: ' "$unit"; systemctl is-active "$unit" 2>&1 || true
done
echo '--- software ---'
docker --version || true
docker compose version || true
echo '--- addresses for DHCP reservation ---'
for dev in /sys/class/net/*; do
  [ -f "$dev/address" ] || continue
  printf '%s: %s\n' "$(basename "$dev")" "$(cat "$dev/address")"
done
echo '--- battery ---'
for f in /sys/class/power_supply/BAT*/capacity; do
  if test -f "$f"; then echo "$f: $(cat "$f")%"; fi
done
echo '--- access ---'
echo 'SSH: ssh __USERNAME__@__HOSTNAME__.local'
echo 'Cockpit: https://__HOSTNAME__.local:9090'
echo '--- status ---'
if systemctl is-active -q ssh && systemctl is-active -q NetworkManager && systemctl is-active -q docker && systemctl is-active -q avahi-daemon; then
  echo 'OK - core services active. Boot/kernel/Wi-Fi/hardware still require real-world verification.'
else
  echo 'ATTENTION - check service status above.'
fi
END
chmod 755 /usr/local/sbin/surface-firstboot-check
cat >/etc/systemd/system/surface-firstboot-check.service <<'END'
[Unit]
Description=Surface Book edge node first-boot diagnostics
After=network-online.target docker.service ssh.service
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/surface-firstboot-check

[Install]
WantedBy=multi-user.target
END
/usr/bin/systemctl enable surface-firstboot-check.service
# Swapfile on ext4 for a machine with 8 GB RAM.
if ! grep -q '^/swapfile ' /etc/fstab; then
  if fallocate -l 2G /swapfile; then
    chmod 600 /swapfile
    mkswap /swapfile
    printf '/swapfile none swap sw 0 0\n' >> /etc/fstab
  else
    echo 'Warning: swapfile allocation failed; installation can continue'
  fi
fi
mkdir -p /srv/edge
chown __USERNAME__:__USERNAME__ /srv/edge
# Confirm all critical daemons are present.
for bin in /usr/sbin/sshd /usr/bin/docker /usr/bin/nmcli /usr/sbin/avahi-daemon; do
  [ -x "$bin" ] || { echo "FATAL missing $bin"; exit 1; }
done
/usr/sbin/sshd -t

printf 'Surface postinstall completed: %s\n' "$(date -u)"
