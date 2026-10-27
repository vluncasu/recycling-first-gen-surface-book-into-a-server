#!/usr/bin/env bash
# Read-only, no credentials: run on Debian as normal user.
set -u
printf '%s\n' '=== EDGE NODE AUDIT (PRIVATE OUTPUT: REDACT BEFORE SHARING) ==='
printf 'Time UTC: '; date -u +%FT%TZ
printf '\n=== SYSTEM ===\n'; cat /etc/os-release | grep -E '^(PRETTY_NAME|VERSION_CODENAME)='; uname -r
printf '\n=== STORAGE ===\n'; lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL; df -hT /; swapon --show
printf '\n=== SERVICES ===\n'
for s in ssh docker cockpit.socket avahi-daemon NetworkManager tailscaled fstrim.timer; do
  printf '%-24s %s\n' "$s" "$(systemctl is-active "$s" 2>/dev/null || true)"
done
printf '\n=== NETWORK (private; no Wi-Fi credentials) ===\n'; ip -br -4 a; ip -4 route show default
printf '\n=== CONTAINERS ===\n'; docker ps --format '{{.Names}}\t{{.Status}}' 2>/dev/null || true
printf '\n=== BATTERIES ===\n'
for p in /sys/class/power_supply/*; do
  [[ -d "$p" ]] || continue
  echo "-- $(basename "$p") --"
  for k in type scope status capacity energy_now energy_full energy_full_design; do
    [[ ! -r "$p/$k" ]] || printf '%s: %s\n' "$k" "$(cat "$p/$k")"
  done
done
printf '\n=== TAILSCALE ===\n'; tailscale status 2>&1 | head -n 8 || true
printf '\nNOTE: This output may reveal local addresses. Redact before publishing.\n'
