# Post-install operation and maintenance

## First boot verification

After booting Debian, connect from a separate machine and verify:

```bash
ssh <username>@<hostname>.local
hostnamectl
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINTS,MODEL
df -hT /
systemctl is-active ssh docker avahi-daemon
```

SSH may prompt for the host fingerprint on first connection. Verify it through a trusted channel; never accept a changed host key blindly. If mDNS is unavailable, find the IP in the router's DHCP client list.

## Docker

The prototype used Debian's `docker.io` and Docker Compose package; the official Docker repository is an alternative, but don't mix the two families of Docker packages without a migration plan. Check:

```bash
sudo docker version
sudo docker compose version
sudo systemctl is-active docker
```

Docker does **not** mean the application is deployed. Containers must be supplied separately and given environment files, secret management, health probes, data volumes and backups. Running a container with a published port can bypass naïve firewall assumptions; review Docker's [firewall guidance](https://docs.docker.com/engine/install/debian/#firewall-limitations).

## Tailscale

If installed but not authenticated:

```bash
sudo tailscale up
tailscale status
tailscale ip -4
```

Follow the account login URL privately. Do not commit auth URLs, auth keys, state files, or tailnet details. Tailscale creates a private-management path; it does **not** automatically publish an application on the public internet.

## Cockpit

Cockpit typically listens on `9090` over HTTPS and may use a local certificate that the browser doesn't recognize. Reach it only from a trusted LAN or through a correctly restricted private VPN. Do not forward port `9090` on a public router.

## Disk and memory

```bash
lsblk -f
df -hT /
swapon --show
systemctl status fstrim.timer
```

The tested node showed a root filesystem occupying nearly the whole SSD. Growing partitions automatically on an already running remote host can be hazardous; don't resize if there is no remaining unallocated disk space.

## Battery

Surface Book 1 contains batteries in separate parts of the assembly. Linux may expose them inconsistently depending on firmware, ACPI, driver and hardware state. A `scope: Device` battery may instead belong to an attached keyboard/peripheral.

```bash
for p in /sys/class/power_supply/*; do
  echo "== $(basename "$p") =="
  for k in type scope status energy_full energy_full_design energy_now power_now; do
    [ ! -r "$p/$k" ] || { printf '%s: ' "$k"; cat "$p/$k"; }
  done
done
```

For the documented example, a 51 Wh design-capacity battery reported 40.455 Wh usable capacity (~79.3% of original). This is a reported charge-capacity estimate, not a calibrated runtime test. Estimated theoretical runtime = usable Wh / average W. Reserve margin and measure real load with the screen off.

**Fire and longevity:** Inspect for swelling, unusual warmth, failed fans, blocked vents and aging batteries. Battery control remains a firmware function; Linux reporting 100% does not prove a particular battery-preservation charge limit. Use a temperature alarm, shutdown threshold and proper mount location before 24/7 use.

## NVIDIA and Intel media hardware

Intel HD Graphics 520 was detected with `i915`. The base contains a 1 GB NVIDIA GPU according to Microsoft's specs, but no NVIDIA PCI device appeared in Linux. It is not safe to assume that installing the proprietary driver will magically enumerate a powered-off PCI device. The 1 GB GM108 version is not a useful NVENC transcoder; test Intel VA-API/Quick Sync support before choosing a video worker.

For a limited media worker, start with metadata extraction and one FFmpeg job at a time. Measure encoding quality, CPU load, temperature, watts and latency. If the node assumes backup application duties, pause noncritical transcoding.

## Networking and unattended operation

Prefer a stable DHCP reservation, monitor Wi-Fi signal, disable automatic suspend, and validate that the system reconnects after a power cut. A phone tether can disappear or change its Wi-Fi/USB profile; plan a recovery route and ensure the phone itself remains powered. Most critically, **test actual connectivity** rather than merely observing the interface is UP.
