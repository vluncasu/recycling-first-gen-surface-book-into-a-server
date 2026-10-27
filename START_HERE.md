# Start here — turn a first-gen Surface Book into an SSH server

This project rebuilds a **first-generation Microsoft Surface Book** with Debian 13, automatic Wi-Fi setup and SSH access. It is designed for a laptop whose display no longer serves as a reliable interface, not for a healthy computer you still need for daily work.

**Read this first:** the unattended install option deletes the internal SSD matched by the disk safety check. If you are not sure what is on that SSD, do not continue. The builder does **not** erase your Mac or Windows computer; writing the resulting ISO erases the chosen USB stick.

## Pick your computer

| You are preparing the stick on... | Start here | What you get |
|---|---|---|
| **macOS** | `installer/Build_Installer.command` | ISO on Desktop → flash using balenaEtcher |
| **Windows 10/11** | `windows/START_WINDOWS.cmd` | ISO in `output/` → flash using Etcher or Rufus DD mode |

Windows requires a working WSL Linux distribution. The first-time WSL setup may need administrator access and a Windows restart. [Windows step-by-step](docs/WINDOWS_INSTALLATION.md).

## Six small steps

1. **Save your data.** The Surface Book's installed OS and files will be destroyed by AUTO-INSTALL.
2. **Build the image.** Open the platform-specific builder. Enter a new hostname, Linux account name and password, Wi-Fi SSID/password and expected SSD model **on your own computer**. There are no universal default credentials.
3. **Wait for success.** Do not flash an image if the builder reports any error. The builder verifies its downloaded Debian ISO and its modified image structures.
4. **Flash the right file.** Choose `SurfaceBook1-Debian13-EDGE-AUTOINSTALL.iso`, **not** the original Debian netinst file. Use [balenaEtcher/Rufus directions](docs/USB_FLASHING.md).
5. **Boot the Surface and choose AUTO-INSTALL.** Connect reliable power; USB-Ethernet is recommended during netinst. Inspect the target-model warning. The automatic installer formats the matched internal SSD.
6. **Connect with SSH.** When installation has completed successfully, remove the USB, start the Surface Book, and connect from your Mac or PC:

```bash
ssh YOUR_USERNAME@YOUR_HOSTNAME.local
```

Enter the Linux password you chose when building the ISO. No characters appear as you type — this is normal. Confirm the SSH host fingerprint using a trusted channel before typing `yes`.

## After first login

The installed Debian image enables SSH, Docker, a local Cockpit web console and Wi-Fi for the profile you entered. The optional post-configuration scripts can be run afterward from macOS or Windows. To enroll with Tailscale, run `sudo tailscale up` on the Surface and approve the login in your own account. A stable numeric IP is obtained by reserving DHCP on the router for the correct network adapter's MAC address; the builder does not guess an IP for your network.

**Not included:** a pre-created public Docker application, functioning dual-internet failover, database replication, a verified number of hours of battery backup, or an automatically connected Tailscale account. Those are integration tasks and operational tests, not consequences of installing Debian.

## Tip: use any LLM to walk you through it

You can hand the downloaded ZIP to ChatGPT, Claude or any capable language model. It can read the scripts, ask for your Wi-Fi SSID and password, and guide you step by step through the build, flash and SSH connection — no manual reading required. The scripts do the real work; the LLM just helps you fill in the blanks.

## If the installer fails

Find the USB's `SURFACELOG` partition and read the diagnostics (if the logger had time to start). Do not share private ISO files or raw logs; they may contain Wi-Fi credentials and local identifiers. See [Troubleshooting](docs/TROUBLESHOOTING.md) and [what happened in our own installation](docs/FIELD_NOTES.md).
