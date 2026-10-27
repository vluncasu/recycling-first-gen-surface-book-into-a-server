#!/usr/bin/env bash
# Debian 13 optional post-provisioning, run under sudo after first successful SSH boot.
# Keeps original bootloader, active IP/routing and running Docker installation unchanged.
set -Eeuo pipefail
[ "$(id -u)" = 0 ] || { echo 'Run using sudo'; exit 1; }
. /etc/os-release
[ "${VERSION_CODENAME:-}" = trixie ] || { echo 'This script targets Debian 13 trixie'; exit 1; }
export DEBIAN_FRONTEND=noninteractive
mkdir -p /var/log/surface-edge
chmod 700 /var/log/surface-edge
log="/var/log/surface-edge/setup-$(date -u +%Y%m%dT%H%M%SZ).log"
exec > >(tee -a "$log") 2>&1
printf '\n=== EDGE POST-CONFIGURE %s ===\n' "$(date -u)"
apt-get update
apt-get install -y ca-certificates curl gnupg openssh-server sudo avahi-daemon \
  cockpit network-manager pciutils jq ffmpeg vainfo i965-va-driver \
  firmware-libertas unattended-upgrades smartmontools
if ! command -v docker >/dev/null 2>&1; then
  apt-get install -y docker.io docker-compose
fi
if ! docker compose version >/dev/null 2>&1; then
  apt-get install -y docker-compose
fi
# Signed Tailscale apt repository, not unreviewed curl|sh.
if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://pkgs.tailscale.com/stable/debian/trixie.noarmor.gpg \
    -o /usr/share/keyrings/tailscale-archive-keyring.gpg
  curl -fsSL https://pkgs.tailscale.com/stable/debian/trixie.tailscale-keyring.list \
    -o /etc/apt/sources.list.d/tailscale.list
  apt-get update
  apt-get install -y tailscale
fi
mkdir -p /etc/systemd/logind.conf.d
cat > /etc/systemd/logind.conf.d/10-edge-node.conf <<'EOF'
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
IdleAction=ignore
EOF
for s in ssh.service avahi-daemon.service cockpit.socket docker.service tailscaled.service fstrim.timer; do
  systemctl enable --now "$s" || echo "WARN: could not enable $s"
done
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target || true
systemctl enable --now unattended-upgrades.service 2>/dev/null || true
sshd -t
printf '\n=== SERVICES ===\n'
for s in ssh docker cockpit.socket avahi-daemon tailscaled fstrim.timer; do
  printf '%s = %s\n' "$s" "$(systemctl is-active "$s" 2>/dev/null || true)"
done
printf '\n=== DISK ===\n'; lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS; df -hT /
printf '\n=== TAILSCALE ===\n'
if tailscale status >/dev/null 2>&1; then tailscale status | head -n 8; else echo 'Not enrolled. Run: sudo tailscale up'; fi
printf '\nFinished; no reboot, partition resize or IP change was performed.\n'
printf 'Detailed log: %s\n' "$log"
