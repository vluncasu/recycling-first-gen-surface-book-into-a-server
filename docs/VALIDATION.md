# Validation and acceptance matrix

## What's tested

| Test | How we know | Status |
|---|---|---|
| Debian boots from internal SSD | SSH login + kernel banner | **Works** |
| SSH works from Mac | SSH session screenshot | **Works** |
| Root uses most internal disk | `lsblk`, `df` output | **Works** |
| Docker and Compose installed | `docker version`, service status | **Works** |
| Cockpit active | Service running, web login | **Works** |
| Wi-Fi connected | `nmcli` output | **Works** |
| Tailscale installed and connected | `tailscale status` shows connected | **Works** |
| Continuous USB logger | Script in source, static checks pass | **In code; not yet tested on hardware** |
| Public installer (this repo) | Bash/static checks pass | **Not yet tested on hardware** |
| Smartphone hotspot as second uplink | Planned, not yet connected | **Todo** |
| Independent secondary internet | Architecture only, no routing test | **Todo** |
| Battery runtime under load | BAT2 capacity known, no discharge test | **Todo** |
| Application deployed on the node | No containers running yet | **Todo** |
| Automatic failover | No health-check or cutover test | **Todo** |
| NVIDIA dGPU | In the base per specs — not tested, we don't need it | **Skipped** |

## Suggested repeatable acceptance test

1. Record `lsblk`, `df`, `systemctl is-active` and SSH access from a separate device.
2. Add Tailscale and confirm reachability after disabling local Wi-Fi on the administrator's device.
3. Connect smartphone hotspot; record local IP, public egress and the network operator (avoid publishing it).
4. Simulate a main-router/ISP outage and observe whether the Surface remains reachable over cellular. Confirm that it doesn't rely on a router with lost power.
5. Unplug Surface external power safely; record battery Wh and runtime under representative server load, with a shutdown threshold.
6. Run a selected **stateless** Docker workload with a health endpoint, then rehearse external traffic cutover.
7. Add database replication/fencing only after data consistency and rollback procedures are tested.
8. Capture results including timestamp, system version, RTO/RPO and pass/fail. Publish only redacted samples.

## Acceptance vs claims

Do not claim "100% availability", "perfect install on all Surface Books", or "automatic failover" based only on a functioning SSH shell. Such claims require representative multi-failure testing and ongoing measurement.
