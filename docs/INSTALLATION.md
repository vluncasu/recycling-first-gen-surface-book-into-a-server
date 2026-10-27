# Installation — from Mac to a headless Surface Book

> **Data loss warning:** the automatic entry reformats the internal SSD. Ensure you have permission to erase it, possess a verified backup and have disconnected any unrelated drives. No step here claims universal Surface Book compatibility.

## Required materials

- First-generation Surface Book with working CPU, SSD, firmware boot and power.
- Mac with internet access, Homebrew and sufficient free space.
- USB flash drive (16+ GB; the field run used a 64 GB SanDisk).
- balenaEtcher to flash the generated ISO.
- USB Ethernet adapter *recommended during Debian netinst*.
- Keyboard accessible during boot (some damaged-display units need a temporary external display).

For the equivalent Windows workflow, use [Windows installation](WINDOWS_INSTALLATION.md). To see exact balenaEtcher and Rufus steps, see [Flashing the USB](USB_FLASHING.md).

## Quick-start checklist

1. Clone this repository or download source ZIP.
2. Open Terminal on macOS in the project folder.
3. Run `bash installer/Build_Installer.command`.
4. Provide a hostname, username, time zone, target SSD model and *your own* Wi-Fi / Linux passwords. Inputs are not tracked by Git.
5. Wait for `GATA - ISO PERSONALIZAT CREAT`. **Do not flash on any failure.**
6. In balenaEtcher choose **Flash from file** and select the generated `SurfaceBook1-Debian13-EDGE-AUTOINSTALL.iso` on the Desktop. Choose only the intended USB drive.
7. If using Rufus on Windows instead, choose **DD Image mode**, never ISO extraction mode; see [USB guide](USB_FLASHING.md). Boot the Surface from that USB, choose `AUTO-INSTALL EDGE NODE - ERASES INTERNAL SSD!` and let Debian perform the installation. It should halt after the late-installation stage; power on after removing USB.
8. Connect from the Mac: `ssh <username>@<hostname>.local` after verifying the SSH host fingerprint.

**Additional notes:**
- `Build_Installer.command` currently targets pinned **Debian 13.7** installation media. Pinning supports repeatability, but a newer Debian point release can make the `current` download URLs no longer match the pinned filename. In that case deliberately update the version and hashes/source rather than disabling verification.
- macOS dependencies: `xorriso`, `dosfstools` / `mkfs.fat`, `openssl@3`, Python 3 and system tools. The builder can install missing Homebrew packages.
- The default SSD guard expects a Toshiba `THNSN5256GPU7` with 256 GB capacity. A mismatch causes a safe installation stop; review the real hardware and guard logic before retargeting.
- The public refactor has passed static tests; the original **private** variant achieved a bootable Debian install. These are not identical artifacts, so run a disposable/dedicated-hardware validation before reliance.

## How unattended installation works

1. The builder downloads a Debian amd64 netinst ISO from an HTTPS mirror and verifies the upstream SHA-512 value.
2. It creates a local SHA-512-crypt password hash and a NetworkManager Wi-Fi profile using the credentials supplied by the operator.
3. `xorriso` inserts `preseed.cfg`, setup scripts, the public SSH key and a GRUB menu entry, **replaying EFI and BIOS boot structures** from the source ISO.
4. A **separate appended FAT32 partition** named `SURFACELOG` is created for writing logs. ISO9660 itself is typically read-only.
5. During boot, Debian Installer reads the preseed and runs the disk guard before destructive partitioning. The log snapshot mechanism is best effort.
6. It creates GPT / EFI / ext4, installs a headless Debian system, deploys the authorized public key and Wi-Fi settings, and enables basic services.
7. It stops rather than immediately rebooting, so you can remove the destructive USB.

## Storage layout

The successful field run used EFI + a single ext4 root filesystem, **not LVM**:

```text
/dev/nvme0n1           256 GB nominal Toshiba NVMe
├─ nvme0n1p1         ~731 MiB  FAT /boot/efi
└─ nvme0n1p2         ~237.8 GiB ext4 /
/swapfile               2 GiB swap on ext4
```

This avoids an overly small root logical volume. The exact sizes depend on installer releases and disk geometry; do not copy them blindly to a different disk. For later adjustment use `lsblk`, `findmnt`, `df -hT` and test growth on backup media first.

## Install credentials and SSH

The builder requests a new Linux password without echoing it, hashes it locally and embeds the hash in the generated *private* installer. The Wi-Fi password remains present inside the generated configuration. **Never upload that ISO, temporary files or USB dump to GitHub**. Prefer per-host SSH key pairs protected with a passphrase. The build script uses a local public key and never copies the Mac's private key to the Surface.

On the first successful login:

```bash
ssh surfaceadmin@surfacebook-node.local
```

These are **example values**, not live credentials.

## IP stability

A `.local` hostname is resolved using mDNS where supported. For a stable numeric address, assign a **DHCP reservation on the actual router** to the MAC address of the active Wi-Fi or Ethernet adapter. A static Linux IP guessed from a sample subnet is not safe.

## Installation logs

When detectable, `SURFACELOG` is mounted in the installer and receives periodic snapshots (approximately 15 seconds apart) including `INSTALLER.LOG`, `ERORI.TXT`, `PARTMAN.LOG`, `DMESG.LOG` and `STATUS.TXT`. Hard freezes can lose recent writes; a hang before preseed loads cannot be captured by the user-space logger. Logs may contain serials, network details and credentials; scrub before publishing.

## Additional UEFI considerations

The field installation initially failed to install GRUB and systemd-boot; the eventual automated version used an EFI partition and GRUB fallback path. That sequence suggests boot setup compatibility mattered, but **does not establish a single definitive root cause** for the original failure. Don't disable Secure Boot or rewrite NVRAM without understanding the consequences. `grub-installer/update-nvram=false` and the EFI removable fallback path are deliberate in this design, not universal requirements.

Official reference: [Debian 13 Preseed](https://www.debian.org/releases/trixie/amd64/apbs04.en.html).
