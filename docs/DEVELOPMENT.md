# Development and reproducibility

## Provenance

The initial private experiment iterated through multiple builder versions. The latest supplied version was v6.1 and its installation produced a working Debian machine with SSH. The public repository is based on v6.1 but was **redacted and parameterized** to avoid releasing credentials. It has not been physically re-run on a Surface Book after that refactor.

## Project structure

```text
installer/Build_Installer.command     # macOS build + ISO customization
installer/preseed.cfg.template        # Debian Installer answers (placeholders only)
installer/WiFi.nmconnection.template  # Wi-Fi profile skeleton (no secrets)
installer/surface-postinstall.sh      # target first-boot/late install setup
installer/surface-disk-guard.sh       # fail-closed target SSD identity check
installer/surface-usb-logger.sh       # installer snapshots to SURFACELOG
installer/verify_surfacelog.py        # FAT partition validation
scripts/                           # optional post-install and audit helpers
assets/                            # privacy-scrubbed project images
examples/                          # synthetic and anonymized output
```

## Checks for contributors

```bash
bash -n installer/Build_Installer.command
bash -n installer/surface-postinstall.sh
sh -n installer/surface-disk-guard.sh
sh -n installer/surface-usb-logger.sh
python3 -m py_compile installer/verify_surfacelog.py
bash scripts/test-static.sh
```

These are syntax/static tests, not a substitute for **real UEFI installation**. For hardware changes, arrange recovery, disk backup and a second administrator route. The builder uses GPT/EFI + ext4 rather than LVM; do not edit the recipe without checking the Debian Installer format. Keep `xorriso` boot replay after modified ISO files have been inserted.

## Release discipline

- Record upstream Debian image version and hashes.
- Treat generated ISO and private Wi-Fi profile as **build artifacts**, never commit them.
- Keep explicit traceability from issues to fixes (TLS host mismatch, Homebrew sbin path, Python verifier, UEFI failures).
- Do not silently imply the private field ISO and the sanitized public ISO were byte-for-byte identical.
- Run lint/static checks and at least one physical boot/disk/SSH test before labeling a new builder version as validated.

## Citation and licenses

Debian manual: https://www.debian.org/releases/trixie/amd64/apbs04.en.html  
xorriso: https://manpages.debian.org/trixie/xorriso/xorriso.1.en.html  
Surface hardware: https://support.microsoft.com/en-us/surface/models/surface-book-1st-gen-specs-and-features  
linux-surface: https://github.com/linux-surface/linux-surface  
Docker: https://docs.docker.com/engine/install/debian/  
Tailscale: https://tailscale.com/docs/install/linux  

The project is independently developed. Product marks remain the property of their owners.
