# Flashing the custom Surface Book installer to USB

The **generated custom ISO** is the correct file to flash. **Do not flash** the original `debian-13.7.0-amd64-netinst.iso`: that image contains no project-specific settings, disk guard, SSH key or USB logging partition.

> [!CAUTION]
> Flashing erases the entire **selected USB drive**. Booting the customized USB and selecting **AUTO-INSTALL** later erases the internal SSD matched by the disk guard. These are two separate destructive operations. Double-check both targets.

## balenaEtcher (macOS, Windows, Linux)

1. Download [balenaEtcher](https://etcher.balena.io/) from its official website, and connect the USB stick to the computer preparing the installer.
2. Choose **Flash from file** and select `SurfaceBook1-Debian13-EDGE-AUTOINSTALL.iso` from the builder's output folder.
3. Choose **Select target**. Check its make and size carefully. **Never select your Mac/Windows system drive.**
4. Select **Flash!**, approve system permissions if requested, and allow Etcher to complete validation.
5. Eject the USB safely. You may see an “unreadable disk” warning: do **not** initialize or format it; that often means Windows/macOS does not understand the Linux installer partitions.

balenaEtcher writes the raw image layout to the stick, including the appended `SURFACELOG` partition. The drive's remaining capacity may appear unavailable until the stick is reformatted for ordinary use.

## Rufus (Windows)

1. Download [Rufus](https://rufus.ie/) from its official website.
2. Insert the USB and carefully select it under **Device**.
3. For **Boot selection**, choose **Disk or ISO image** → **SELECT** → your *generated custom ISO*.
4. Press **START**. **If Rufus asks to choose between ISO Image mode and DD Image mode, choose `DD Image mode`.** This is important: we want the exact hybrid ISO partition layout, including `SURFACELOG`, not a rebuilt boot stick.
5. Confirm the warning about erasing the selected **USB**, allow completion, and eject the drive safely.

If your installed Rufus version offers no raw/DD option for this particular image, use balenaEtcher. Do not assume ISO mode preserves appended partitions.

## On the Surface Book

1. Back up any data still present on the Surface's internal SSD.
2. Connect power and preferably a USB-Ethernet adapter for Debian netinst. If you have a damaged display, use a known-working external screen only for the initial boot.
3. Insert the prepared stick. With the Surface powered down, hold **Volume Down** and press **Power** for USB boot. Release Volume Down when the boot process begins.
4. Choose the visibly labeled **AUTO-INSTALL** entry **only** after confirming the intended SSD is the one documented in the disk guard.
5. Once installation finishes, power the machine on without the installer USB. Connect by SSH from macOS or Windows.

If it stalls, power off only after determining that it truly has not progressed, then inspect the `SURFACELOG` partition on the installer USB from a suitable computer. Logs can contain private network identifiers and must be scrubbed before sharing.

**References:** [Debian image FAQ](https://www.debian.org/CD/faq/), [Rufus](https://rufus.ie/), [balenaEtcher](https://etcher.balena.io/).
