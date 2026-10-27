# v0.2.0-beta.1 — Public installer beta

This prerelease turns the one-off Surface Book 1 recycling experiment into a documented, reusable project.

### Included

- Credential-free public source; operator enters hostname, login and Wi-Fi credentials locally at build time.
- macOS `.command` builder and Windows `.cmd` / PowerShell builder (Windows uses WSL).
- Debian 13.7 installer templates, UEFI partitioning, model-specific disk guard and USB diagnostic logging.
- Installation steps for balenaEtcher and Rufus (DD image mode).
- SSH and post-install guides; Docker, Cockpit and optional Tailscale integration.
- Real-world, privacy-edited photos and troubleshooting lessons from the original build.

### Read before use

**This is a beta, not a certified installer.** The macOS private field build worked on one Surface Book 1; the generic public refactor and Windows path have not been hardware-retested. The automatic install mode **permanently erases the matched internal SSD**. The generated private ISO **contains a Wi-Fi password and Linux account password hash**. Never post generated ISO files or raw logs publicly.

Do not mistake an independent internet path for automatic application failover. That requires replication, routing, health checks and power for the phone/router as well.
