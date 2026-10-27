# Contributing

Contributions are welcome, especially well-documented Surface Book hardware test reports, safe Debian Installer improvements, battery/thermal measurements and independent-uplink failure tests.

- Open an issue describing exact hardware generation, kernel, Debian installer version and observed behavior. **Redact** serials, SSIDs, public IPs, login links, username/path identifiers and passwords.
- Test modifications with `bash scripts/test-static.sh`, then use sacrificial hardware for destructive partitioning tests.
- Separate **observations** from **hypotheses**; never claim universal success based on one device.
- Keep changes in English for consistent international documentation, with clear beginner-friendly explanations.
- Never include generated `.iso`, `*.nmconnection`, SSH private keys or raw installer logs in PRs.
