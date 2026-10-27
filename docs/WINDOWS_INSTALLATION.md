# Windows installation: build the same Debian ISO without a Mac

This is a **real Windows entry point**, but not a Windows-native ISO remastering engine. It uses Microsoft Windows Subsystem for Linux (WSL) to run the Linux build tools. The result is the same Debian installer workflow, not Windows installed on the Surface Book.

## Prerequisites (one time)

- Windows 11 or supported Windows 10, with administrator rights **only if you need to install WSL**.
- Internet access and roughly 3 GB of free disk space plus a USB drive of at least 4 GB (16+ GB recommended).
- Microsoft OpenSSH Client (usually included with modern Windows).
- balenaEtcher **or** Rufus.

If you do not already have an initialized Ubuntu or Debian distribution in WSL, open **PowerShell as Administrator**:

```powershell
wsl --install -d Ubuntu
```

Windows may ask for a restart. Open Ubuntu once and create the WSL Linux user and password. This is a **separate password** from the account that will later be installed on the Surface Book. These first-time setup steps cannot reliably be bypassed by a portable script. See [Microsoft WSL installation instructions](https://learn.microsoft.com/en-us/windows/wsl/install).

## Build in three steps

1. Download the repository source ZIP or a Windows asset from [GitHub Releases](RELEASES.md). Extract it to a **local folder** (for example, Downloads). Do **not** run inside the compressed ZIP.
2. Double-click `windows/START_WINDOWS.cmd`. It launches `Build_Installer_Windows.ps1`, checks WSL, creates/reuses a **Windows SSH key**, then opens the same local-config prompts for hostname, username, Wi-Fi name/password and the Debian account password.
3. On success, find **`output/SurfaceBook1-Debian13-EDGE-AUTOINSTALL.iso`** in the extracted folder. Use [USB flashing instructions](USB_FLASHING.md). **Do not upload this private generated ISO to GitHub**.

The builder downloads and verifies the official Debian 13.7 netinst ISO, installs its build tools within WSL if needed (you may be asked for the WSL `sudo` password), creates a writable `SURFACELOG` FAT partition, and checks the result. The `output/` directory also contains sensitive installation metadata and must not be committed.

## After installation

On Windows PowerShell:

```powershell
ssh your-user@your-hostname.local
```

Replace the examples with the credentials and hostname selected locally. On some Windows networks `.local` resolution is unavailable; find the assigned DHCP IP in your router and connect to that IP instead. After login, use `windows/Postconfigure_from_Windows.ps1` for optional service setup. Verify the SSH host fingerprint before accepting it.

## If it fails

- If `wsl --list --quiet` shows no Ubuntu or Debian: initialize WSL as described above.
- If Linux cannot install dependencies: ensure the WSL distribution can reach the internet and your Linux user can use `sudo`.
- If PowerShell execution policy blocks launching a `.ps1` directly: use the included `START_WINDOWS.cmd`, not an untrusted internet one-liner.
- If `wslpath` fails: extract the project to a normal local disk folder such as `C:\Users\...\Downloads`, rather than a network share.
- If the generated ISO does not end with the builder's success message: **do not flash**.

**Not yet hardware validated:** the Windows wrapper and WSL builder pass syntax and static checks, but this variant has not completed a Windows-hosted build + real Surface Book installation in our tests. Please report the WSL version, logs with credentials removed and exact point of failure.
