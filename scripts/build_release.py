#!/usr/bin/env python3
"""Build credential-free release assets. No ISO, local credentials or raw log files."""
from pathlib import Path
import argparse, hashlib, os, zipfile
R=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--version',default='v0.2.0-beta.1')
a=parser.parse_args()
assert a.version.startswith('v') and all(c.isalnum() or c in '._-' for c in a.version)
dist=R/'dist'; dist.mkdir(exist_ok=True)
COMMON=[
  'README.md','START_HERE.md','LICENSE','CONTRIBUTING.md',
  'installer/WiFi.nmconnection.template','installer/preseed.cfg.template',
  'installer/surface-disk-guard.sh','installer/surface-postinstall.sh',
  'installer/surface-usb-logger.sh','installer/verify_surfacelog.py',
  'docs/INSTALLATION.md','docs/WINDOWS_INSTALLATION.md',
  'docs/USB_FLASHING.md','docs/SECURITY.md','docs/POST_INSTALL.md',
  'docs/TROUBLESHOOTING.md','docs/VALIDATION.md','docs/RELEASE_NOTES.md',
  'scripts/postconfigure-remote.sh','scripts/audit-node.sh',
]
platforms={
  'macOS':['installer/Build_Installer.command','scripts/Configure_from_Mac.command'],
  'Windows':['installer/Build_Installer_Linux.sh','windows/START_WINDOWS.cmd','windows/Build_Installer_Windows.ps1','windows/Postconfigure_from_Windows.ps1'],
}
# Ship complete user documentation/media in both platform bundles, so links work offline.
COMMON += [str(p.relative_to(R)) for base in ('docs','assets','examples') for p in (R/base).rglob('*') if p.is_file()]
for platform,additional in platforms.items():
    name=f'SurfaceBook-Installer-{platform}-{a.version}.zip'
    dest=dist/name
    with zipfile.ZipFile(dest,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for rel in sorted(set(COMMON+additional)):
            src=R/rel
            if not src.is_file(): raise FileNotFoundError(src)
            # Store project root as folder, but not any generated secrets.
            zi=zipfile.ZipInfo('SurfaceBook-Installer/'+rel,(2026,10,27,0,0,0))
            zi.compress_type=zipfile.ZIP_DEFLATED
            zi.external_attr=(0o755 if src.suffix in {'.sh','.command','.cmd'} else 0o644)<<16
            z.writestr(zi,src.read_bytes())
    print(f'Created: {dest.name}, {dest.stat().st_size:,} bytes')
files=sorted(dist.glob(f'SurfaceBook-Installer-*-{a.version}.zip'))
with (dist/'SHA256SUMS.txt').open('w') as out:
    for f in files:
        out.write(f'{hashlib.sha256(f.read_bytes()).hexdigest()}  {f.name}\n')
print('Created SHA256SUMS.txt')
