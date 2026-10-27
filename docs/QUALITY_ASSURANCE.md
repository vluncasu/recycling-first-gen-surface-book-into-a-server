# Quality assurance and publication checklist

This report distinguishes **checks that were run in our packaging environment** from installation steps that depend on hardware, Windows and router configuration.

## Checks completed in the packaging environment

- Shell syntax checks with `bash -n` and `sh -n` for the current source.
- Static checks of Preseed placeholders, SSH key references, `SURFACELOG` validation invocation, SSD guard and GRUB fallback settings.
- Python parsing of `verify_surfacelog.py` plus local release generator execution.
- Both platform ZIPs generated and their contents inspected; their checksums recorded in `SHA256SUMS.txt`.
- Source text scanned for the known private password/SSID, private user login, local IP/MAC and private SSH fingerprint; no matches in source files.
- Included photos and screenshots verified without EXIF metadata.
- Local Markdown relative paths checked for missing referenced files.
- GitHub workflows created for Linux static checks, Windows PowerShell syntax parsing and prerelease packaging.

## Not verified yet

- **Windows end-to-end:** WSL installation/initialization, actual PowerShell execution, ISO creation on a real Windows machine, Rufus DD writing, real Surface boot and SSH login.
- **Public macOS refactor end-to-end:** build and flash on a new machine after credentials were extracted into interactive inputs. Earlier private field automation worked, but this generic public refactor is not byte-identical.
- **Two-uplink app failover:** phone hotspot, independent routing, battery runtime, application state replication and automated traffic switching need separate tests.
- **External tools and release creation:** GitHub Actions will run after upload/tag; a source ZIP does not create a live release.

## Release gate

The first public tag is explicitly a **beta / prerelease**. Avoid guaranteeing unattended installation on all Surface Book revisions. Before calling it stable, test both operating-system builders and the flashing procedure on disposable hardware, verify SSH login using both password and key, inspect `SURFACELOG` after a deliberately induced installer failure and demonstrate recovery without depending on the local screen.

A hardware-specific automated installer is inherently destructive. Its disk guard must never be casually bypassed to support a different SSD without operator review.
