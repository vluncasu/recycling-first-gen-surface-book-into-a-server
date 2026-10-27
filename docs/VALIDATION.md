# Validation and acceptance matrix

## Evidence classification

- **Observed in the field:** directly supported by actual command output/screenshots in this case.
- **Implemented in scripts:** behavior visible in the source but requiring target execution to confirm.
- **Proposed:** architecture element not yet implemented end to end.

| Test | Evidence | Status |
|---|---|---|
| Debian boots from internal SSD | Successful SSH login prompt and kernel banner | **Observed** |
| SSH works from Mac | SSH session screenshot / console transcript | **Observed** |
| Root uses most internal disk | `lsblk`, `df` post-install report | **Observed** |
| Docker and Compose installed | `docker` version, compose version and service status | **Observed** |
| Cockpit active | Service report and login web link | **Observed** |
| Wi-Fi connected | `nmcli` report | **Observed** |
| `tailscaled` installed | Service report | **Observed** |
| Tailscale enrolled | Status originally showed logged out | **Not confirmed** |
| Continuous USB logger | Script implementation + static validation | **Implemented; not physically validated** |
| Public redacted installer refactor | Bash/static checks | **Not physically validated** |
| Smartphone hotspot connected | Discussed planned use, no field network report | **Not confirmed** |
| Secondary internet independent | Intended architecture; no traceroute/carrier test | **Not confirmed** |
| Battery-backed runtime under load | Capacity reported, not discharge test | **Not confirmed** |
| WeParty application deployed | No runtime containers/app health outputs provided | **Not confirmed** |
| Automatic failover to node | No health-check/cutover experiment | **Not confirmed** |
| NVIDIA dGPU on Linux | Physical dGPU in base per specs; `lspci` doesn't show it | **Not active/detected** |

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
