#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")/.."
bash -n installer/Build_Installer.command
bash -n installer/surface-postinstall.sh
bash -n scripts/audit-node.sh
bash -n scripts/postconfigure-remote.sh
bash -n scripts/Configure_from_Mac.command
sh -n installer/surface-disk-guard.sh
sh -n installer/surface-usb-logger.sh
python3 - <<'PY'
from pathlib import Path
import ast,re
root=Path('installer')
ast.parse((root/'verify_surfacelog.py').read_text())
pre=(root/'preseed.cfg.template').read_text()
assert 'passwd/user-password-crypted password __USER_PASSWORD_HASH__' in pre
assert '/cdrom/WiFi.nmconnection' in pre
assert '/cdrom/surface-disk-guard.sh' in pre
assert 'grub-installer/update-nvram boolean false' in pre
assert 'partman/confirm boolean true' in pre
assert 'preseed/early_command' in pre
assert 'surface-root ::' in pre
assert '__EXPECTED_SSD_MODEL__' in (root/'surface-disk-guard.sh').read_text()
for fn in ['README.md','docs/INSTALLATION.md','installer/preseed.cfg.template','installer/Build_Installer.command']:
    txt=Path(fn).read_text()
    for forbidden in ['BEGIN OPENSSH PRIVATE KEY','BEGIN RSA PRIVATE KEY','tailscale.com/a/']:
        assert forbidden not in txt,(fn,forbidden)
print('PASS — syntax and basic redaction invariants')
PY

# Platform and release distribution checks (non-executing; no hardware is erased).
bash -n installer/Build_Installer_Linux.sh
python3 - <<'PY'
from pathlib import Path
p=Path('windows/Build_Installer_Windows.ps1').read_text()
assert 'wsl.exe' in p and 'Build_Installer_Linux.sh' in p
assert 'SURFACE_PUBLIC_KEY_PATH' in p
assert 'output' in p
q=Path('docs/USB_FLASHING.md').read_text()
assert 'DD Image mode' in q and 'balenaEtcher' in q
w=Path('.github/workflows/release.yml').read_text()
assert 'scripts/build_release.py' in w and '--prerelease' in w
l=Path('installer/Build_Installer_Linux.sh').read_text()
assert 'mkfs.fat' in l and '-append_partition 4' in l
assert 'verify_surfacelog.py' in l
for d in ('docs/RELEASES.md','docs/WINDOWS_INSTALLATION.md','docs/FIELD_NOTES.md'):
    assert Path(d).is_file()
print('PASS — Windows/WSL, USB flashing and release pipeline source invariants')
PY
