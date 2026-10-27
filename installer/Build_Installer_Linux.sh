#!/bin/bash
# Linux / WSL installer builder. Creates a customized Debian 13.7 UEFI ISO for Surface Book 1.
set -euo pipefail
export PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
umask 077
cd "$(dirname "$0")"
PROJECT="$(pwd)"
OUT="${1:-$HOME/SurfaceBook_Installer}"
mkdir -p "$OUT"
# Fallback mirrors with correctly configured HTTPS certificates.
# If one mirror has a TLS or network error, continue with the next one.
ISO_MIRRORS=(
  "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd"
  "https://ftp.be.debian.org/debian-cd/current/amd64/iso-cd"
  "https://mirrors.lug.mtu.edu/debian-cd/current/amd64/iso-cd"
  "https://cloudfront.debian.net/cdimage/release/current/amd64/iso-cd"
)
ISO_NAME="debian-13.7.0-amd64-netinst.iso"
ORIGINAL="$OUT/$ISO_NAME"
MODIFIED="$OUT/SurfaceBook1-Debian13-EDGE-AUTOINSTALL.iso"
SECRETS="$OUT/ACCESS_LOCAL.txt"

printf '\n==============================================\n'
printf ' SURFACE BOOK 1 - RESILIENT EDGE NODE - Debian 13\n'
printf '==============================================\n'
printf 'This tool only creates an ISO; it does not erase your Windows/WSL system or USB stick.\n'
printf 'Cand bootezi Surface si alegi AUTO-INSTALL, sterge DEFINITIV\n'
printf 'SSD-ul intern Toshiba de 256 GB (inclusiv Windows si datele).\n\n'
read -r -p 'Continui cu pregatirea imaginii? Tasteaza DA: ' OK
if [ "$OK" != "DA" ]; then
  echo 'Anulat.'
  exit 0
fi
printf '\n--- LOCAL CONFIGURATION (never committed to Git) ---\n'
read -r -p 'Hostname [surfacebook-node]: ' HOSTNAME
HOSTNAME="${HOSTNAME:-surfacebook-node}"
read -r -p 'Linux username [surfaceadmin]: ' USERNAME
USERNAME="${USERNAME:-surfaceadmin}"
read -r -p 'Time zone [Etc/UTC]: ' TIMEZONE
TIMEZONE="${TIMEZONE:-Etc/UTC}"
read -r -p 'Expected internal SSD model [THNSN5256GPU7]: ' EXPECTED_SSD_MODEL
EXPECTED_SSD_MODEL="${EXPECTED_SSD_MODEL:-THNSN5256GPU7}"
read -r -p 'Wi-Fi SSID: ' WIFI_SSID
read -r -s -p 'Wi-Fi password (hidden): ' WIFI_PASS; printf '\n'
read -r -s -p 'New Linux account password (hidden): ' USER_PASS; printf '\n'
[[ "$HOSTNAME" =~ ^[a-z][a-z0-9-]{1,62}$ ]] || { echo 'Invalid hostname'; exit 1; }
[[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]{0,30}$ ]] || { echo 'Invalid username'; exit 1; }
[[ "$TIMEZONE" =~ ^[A-Za-z0-9_+/-]+$ ]] || { echo 'Invalid timezone'; exit 1; }
[[ "$EXPECTED_SSD_MODEL" =~ ^[A-Za-z0-9_-]+$ ]] || { echo 'Invalid SSD model'; exit 1; }
[ -n "$WIFI_SSID" ] && [ -n "$WIFI_PASS" ] && [ -n "$USER_PASS" ] || { echo 'SSID and passwords are required'; exit 1; }
[ "${#WIFI_SSID}" -le 32 ] && [ "${#WIFI_PASS}" -ge 8 ] && [ "${#WIFI_PASS}" -le 63 ] || { echo 'SSID max 32 chars, WPA passphrase 8–63 chars'; exit 1; }
case "$WIFI_SSID$WIFI_PASS$USER_PASS" in *$'\n'*|*$'\r'*) echo 'Newlines in credentials are not supported'; exit 1;; esac
# The ISO contains Wi-Fi credentials and a password hash. Never share the ISO.
for need in curl xorriso mkfs.fat openssl python3 ssh-keygen sha512sum truncate; do
  if ! command -v "$need" >/dev/null 2>&1; then
    echo "A required tool is missing: $need"
    if ! command -v apt-get >/dev/null 2>&1; then
      echo 'This builder supports Debian/Ubuntu with apt. Install the missing tool manually.'; exit 1
    fi
    echo 'Installing required tools through apt (sudo may ask for your password)...'
    sudo apt-get update
    sudo apt-get install -y curl xorriso dosfstools openssl python3 openssh-client coreutils ca-certificates
    break
  fi
done
for need in curl xorriso mkfs.fat openssl python3 ssh-keygen sha512sum truncate; do
  command -v "$need" >/dev/null 2>&1 || { echo "Still missing: $need"; exit 1; }
done

# The logging partition is a real writable FAT32 partition within the flashed image.
# macOS builds it using mkfile and mkfs.fat. This is NOT a folder on the read-only ISO.
MKFS_FAT="$(command -v mkfs.fat)"
printf 'OK - mkfs.fat found: %s\n' "$MKFS_FAT"
echo 'Descarc Debian 13.7 oficial (netinst, ~800 MB) si verific SHA512...'
VERIFIED=0
for ISO_URL in "${ISO_MIRRORS[@]}"; do
  echo "Incerc serverul: $ISO_URL"
  rm -f "$OUT/SHA512SUMS.partial"
  if ! curl -fLsS --retry 2 --connect-timeout 20 -o "$OUT/SHA512SUMS.partial" "$ISO_URL/SHA512SUMS"; then
    echo 'Serverul de checksum nu este accesibil; incerc urmatorul.'
    continue
  fi
  mv "$OUT/SHA512SUMS.partial" "$OUT/SHA512SUMS"
  # Reuse only an ISO with the correct checksum; never trust a partial file.
  EXPECTED="$(awk -v f="$ISO_NAME" '$2==f || $2=="*"f {print $1; exit}' "$OUT/SHA512SUMS")"
  if [ -z "$EXPECTED" ]; then
    echo 'Numele ISO-ului nu se regaseste in SHA512SUMS; incerc alt server.'
    continue
  fi
  if [ -f "$ORIGINAL" ]; then
    ACTUAL="$(sha512sum "$ORIGINAL" | awk '{print $1}')"
    if [ "$ACTUAL" != "$EXPECTED" ]; then
      echo 'ISO-ul existent nu trece verificarea SHA512; il descarc din nou.'
      rm -f "$ORIGINAL"
    fi
  fi
  if [ ! -f "$ORIGINAL" ]; then
    rm -f "$ORIGINAL.partial"
    if ! curl -fLsS --retry 2 --connect-timeout 20 -o "$ORIGINAL.partial" "$ISO_URL/$ISO_NAME"; then
      rm -f "$ORIGINAL.partial"
      echo 'Descarcarea a esuat; incerc alt server.'
      continue
    fi
    mv "$ORIGINAL.partial" "$ORIGINAL"
  fi
  ACTUAL="$(sha512sum "$ORIGINAL" | awk '{print $1}')"
  if [ "$ACTUAL" = "$EXPECTED" ]; then
    echo 'OK - ISO original verificat SHA512.'
    VERIFIED=1
    break
  fi
  echo 'Checksum gresit, sterg ISO-ul si incerc alt server.'
  rm -f "$ORIGINAL"
done
if [ "$VERIFIED" -ne 1 ]; then
  echo 'EROARE: ISO-ul Debian nu s-a descarcat/verificat. Nu crea stickul.'
  read -r -p 'Apasa ENTER pentru a inchide...' _
  exit 1
fi

SSH_PUBLIC_KEY="${SURFACE_PUBLIC_KEY_PATH:-$HOME/.ssh/id_ed25519.pub}"
if [ ! -f "$SSH_PUBLIC_KEY" ]; then
  echo 'No SSH public key found; generating one inside Linux. Use a passphrase if possible.'
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -f "$HOME/.ssh/id_ed25519" -C 'surface-edge-install'
  SSH_PUBLIC_KEY="$HOME/.ssh/id_ed25519.pub"
fi
# SHA-512 crypt password, generated locally (the plaintext is never saved in source files).
SSL_BIN="$(command -v openssl)"
USER_HASH="$(printf '%s\n' "$USER_PASS" | "$SSL_BIN" passwd -6 -stdin)"
unset USER_PASS
case "$USER_HASH" in '$6$'*) ;; *) echo 'Password hash generation failed'; exit 1;; esac
umask 077
chmod 700 "$OUT"
{
  echo 'SURFACE BOOK - DATE DE ACCES (PASTREAZA PRIVAT!)'
  echo "Hostname: ${HOSTNAME}.local"
  echo "Username: ${USERNAME}"
  echo "Parola de utilizator: cea aleasa de tine (deja inclusa ca hash in configuratie)"
  echo "SSH: ssh ${USERNAME}@${HOSTNAME}.local"
  echo 'Public SSH key source: ${SSH_PUBLIC_KEY}'
  echo "Wi-Fi: ${WIFI_SSID} (password is not stored in this text file)"
  echo 'IMPORTANT: the GENERATED ISO and USB stick contain the Wi-Fi password; keep them private.'
  echo 'IP FIX: Pentru un IP numeric permanent, creeaza rezervare DHCP in router.'
  echo 'Find adapter MAC addresses with ip link on the Debian machine after boot.'
} > "$SECRETS"

TMP="$(mktemp -d "${TMPDIR:-/tmp/}surface-install.XXXXXXXX")"
trap 'rm -rf "$TMP"' EXIT
# Render all sensitive settings only into private temporary files (umask 077).
WIFI_PASS="$WIFI_PASS" WIFI_SSID="$WIFI_SSID" USER_HASH="$USER_HASH" \
HOSTNAME="$HOSTNAME" USERNAME="$USERNAME" TIMEZONE="$TIMEZONE" \
python3 - "$PROJECT/preseed.cfg.template" "$TMP/preseed.cfg" <<'PYRENDER'
import os, sys
from pathlib import Path
s=Path(sys.argv[1]).read_text()
for key,value in {'__WIFI_PASSWORD__':os.environ['WIFI_PASS'],
                  '__WIFI_SSID__':os.environ['WIFI_SSID'],
                  '__HOSTNAME__':os.environ['HOSTNAME'],
                  '__USERNAME__':os.environ['USERNAME'],
                  '__TIMEZONE__':os.environ['TIMEZONE'],
                  '__USER_PASSWORD_HASH__':os.environ['USER_HASH']}.items(): s=s.replace(key,value)
Path(sys.argv[2]).write_text(s)
PYRENDER
WIFI_PASS="$WIFI_PASS" WIFI_SSID="$WIFI_SSID" \
python3 - "$PROJECT/WiFi.nmconnection.template" "$TMP/WiFi.nmconnection" <<'PYRENDER'
import os, sys
from pathlib import Path
s=Path(sys.argv[1]).read_text().replace('__WIFI_PASSWORD__',os.environ['WIFI_PASS']).replace('__WIFI_SSID__',os.environ['WIFI_SSID'])
Path(sys.argv[2]).write_text(s)
PYRENDER
unset WIFI_PASS WIFI_SSID USER_HASH
USERNAME="$USERNAME" HOSTNAME="$HOSTNAME" python3 - "$PROJECT/surface-postinstall.sh" "$TMP/surface-postinstall.sh" <<'PYRENDER'
import os,sys
from pathlib import Path
s=Path(sys.argv[1]).read_text().replace('__USERNAME__',os.environ['USERNAME']).replace('__HOSTNAME__',os.environ['HOSTNAME'])
Path(sys.argv[2]).write_text(s)
PYRENDER
cp "$PROJECT/surface-usb-logger.sh" "$TMP/surface-usb-logger.sh"
EXPECTED_SSD_MODEL="$EXPECTED_SSD_MODEL" python3 - "$PROJECT/surface-disk-guard.sh" "$TMP/surface-disk-guard.sh" <<'PYRENDER'
import os,sys
from pathlib import Path
s=Path(sys.argv[1]).read_text().replace('__EXPECTED_SSD_MODEL__',os.environ['EXPECTED_SSD_MODEL'])
Path(sys.argv[2]).write_text(s)
PYRENDER
cp "$SSH_PUBLIC_KEY" "$TMP/surface-key.pub"
unset WIFI_PASS

# Ensure no placeholders remain in the generated installer files.
for f in "$TMP/preseed.cfg" "$TMP/WiFi.nmconnection" "$TMP/surface-postinstall.sh" "$TMP/surface-disk-guard.sh"; do
  if grep -Eq '__[A-Z_]+__' "$f"; then echo "ERROR: unfilled placeholder in $f"; exit 1; fi
done
xorriso -osirrox on -indev "$ORIGINAL" -extract /boot/grub/grub.cfg "$TMP/grub-orig.cfg" >/dev/null
cat > "$TMP/entry.cfg" <<'ENTRY'
set default=0
set timeout=-1
menuentry --hotkey=a 'AUTO-INSTALL EDGE NODE - ERASES INTERNAL SSD!' {
    set background_color=black
    linux /install.amd/vmlinuz auto=true priority=critical preseed/file=/cdrom/preseed.cfg locale=en_US.UTF-8 keyboard-configuration/xkb-keymap=us --- quiet
    initrd /install.amd/initrd.gz
}
ENTRY
awk -v file="$TMP/entry.cfg" '
  !inserted && /^menuentry / { while ((getline line < file) > 0) print line; close(file); inserted=1 }
  { print }
  END { if (!inserted) exit 44 }
' "$TMP/grub-orig.cfg" > "$TMP/grub.cfg"
if ! grep -q 'AUTO-INSTALL EDGE NODE' "$TMP/grub.cfg"; then
  echo 'Eroare: intrarea de boot nu a putut fi inserata. Nu folosi ISO.'
  exit 1
fi
# Prepare a dedicated 256 MiB writable FAT32 image on the SAME flash drive.
# It is appended as a partition by xorriso; balenaEtcher writes both partitions.
LOG_PART="$TMP/SURFACELOG.fat"
echo 'Pregatesc partitia FAT32 SURFACELOG (256 MiB)...'
truncate -s 268435456 "$LOG_PART"
"$MKFS_FAT" -F 32 -n SURFACELOG "$LOG_PART"
# Validate the FAT volume label before embedding it.
if [ "$(dd if="$LOG_PART" bs=1 skip=71 count=11 2>/dev/null | tr -d ' ')" != 'SURFACELOG' ]; then
  echo 'EROARE: eticheta FAT32 nu a putut fi verificata.'; exit 1
fi
rm -f "$MODIFIED"
echo 'Generez ISO + partitia SURFACELOG pe acelasi stick...'

xorriso -indev "$ORIGINAL" -outdev "$MODIFIED" \
  -map "$TMP/preseed.cfg" /preseed.cfg \
  -map "$TMP/WiFi.nmconnection" /WiFi.nmconnection \
  -map "$TMP/surface-postinstall.sh" /surface-postinstall.sh \
  -map "$TMP/surface-usb-logger.sh" /surface-usb-logger.sh \
  -map "$TMP/surface-disk-guard.sh" /surface-disk-guard.sh \
  -map "$TMP/surface-key.pub" /surface-key.pub \
  -map "$TMP/grub.cfg" /boot/grub/grub.cfg \
  -boot_image any replay \
  -append_partition 4 0x0c "$LOG_PART" \
  -padding included

xorriso -osirrox on -indev "$MODIFIED" -extract /preseed.cfg "$TMP/check-preseed.cfg" >/dev/null
cmp "$TMP/preseed.cfg" "$TMP/check-preseed.cfg"
xorriso -osirrox on -indev "$MODIFIED" -extract /boot/grub/grub.cfg "$TMP/check-grub.cfg" >/dev/null
cmp "$TMP/grub.cfg" "$TMP/check-grub.cfg"
xorriso -osirrox on -indev "$MODIFIED" -extract /surface-usb-logger.sh "$TMP/check-logger.sh" >/dev/null
cmp "$TMP/surface-usb-logger.sh" "$TMP/check-logger.sh"
xorriso -osirrox on -indev "$MODIFIED" -extract /surface-disk-guard.sh "$TMP/check-guard.sh" >/dev/null
cmp "$TMP/surface-disk-guard.sh" "$TMP/check-guard.sh"

for REQUIRED in 'grub-installer/update-nvram boolean false' 'partman-auto/choose_recipe select surface-root' 'partman/early_command string /bin/sh /cdrom/surface-usb-logger.sh snapshot; /bin/sh /cdrom/surface-disk-guard.sh' 'partman-basicfilesystems/no_swap boolean false' "passwd/username string $USERNAME" 'preseed/early_command string /bin/sh /cdrom/surface-usb-logger.sh start'; do
  grep -Fq "$REQUIRED" "$TMP/check-preseed.cfg" || { echo "EROARE preseed: $REQUIRED"; exit 1; }
done
xorriso -indev "$MODIFIED" -report_system_area plain > "$OUT/VERIFICARE_PARTITII_USB.txt" 2>&1
# A dedicated verifier checks both MBR and GPT partitions, and the FAT32 label.
# v5.1/v6 had a Python indentation error: the file was closed before seeking.
python3 "$PROJECT/verify_surfacelog.py" "$MODIFIED"
xorriso -indev "$MODIFIED" -report_el_torito plain > "$OUT/VERIFICARE_BOOT.txt" 2>&1
if ! grep -Eqi 'EFI|UEFI|0xef' "$OUT/VERIFICARE_BOOT.txt"; then
  echo 'ATENTIE: nu s-a confirmat structura EFI. Nu scrie ISO-ul pe stick!'
  exit 1
fi

printf '\n==============================================\n'
printf '    GATA - ISO PERSONALIZAT CREAT\n'
printf '==============================================\n'
printf 'ISO: %s\n' "$MODIFIED"
printf 'Local access summary: %s\n' "$SECRETS"
printf '\nPASUL URMATOR: RESCRIE STICKUL IN BALENAETCHER!\n'
printf '1. Select the new ISO using balenaEtcher / Rufus (DD image mode).\n'
printf '2. Select target -> verify your intended USB drive.\n'
printf '3. Flash -> asteapta validarea.\n'
printf '4. Surface Book -> porneste de pe USB -> alege AUTO-INSTALL.\n'
printf '5. La blocare/eroare, stinge Surface-ul, apoi citeste SURFACELOG pe Mac.\n'
printf '   Fisiere: INSTALLER.LOG, ERORI.TXT, DMESG.LOG, STATUS.TXT (~15 sec).\n'
printf '6. Daca instalarea reuseste, la final se opreste. Scoate USB-ul.\n'
printf '7. Boot the installed system; connect over SSH using your selected account.\n'
printf '\nNu se garanteaza repararea erorii GRUB; este o noua configuratie EFI.\n'
printf "\nISO output: %s\n" "$OUT"
