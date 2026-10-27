#!/usr/bin/env python3
"""Verify a flashed ISO contains a visible, writable FAT32 SURFACELOG partition.
Supports MBR and GPT hybrid ISO partition tables; read only; no disk writes.
"""
import os
import struct
import sys
import uuid
from pathlib import Path

FAT32_LABEL = b'SURFACELOG'
MIN_SIZE = 256 * 1024 * 1024
BASIC_DATA_GUID = uuid.UUID('EBD0A0A2-B9E5-4433-87C0-68B6B72699C7')


def verify(iso_path: str) -> str:
    path = Path(iso_path)
    size = path.stat().st_size
    with path.open('rb') as f:
        mbr = f.read(512)
        if len(mbr) != 512 or mbr[510:512] != b'\x55\xaa':
            raise ValueError('ISO-ul nu contine semnatura MBR valida')

        candidates = []
        for i in range(4):
            entry = mbr[446+16*i:446+16*(i+1)]
            ptype = entry[4]
            first, sectors = struct.unpack_from('<II', entry, 8)
            if ptype in (0x0B, 0x0C) and sectors * 512 >= MIN_SIZE:
                candidates.append((f'MBR partition {i+1}', first * 512, sectors * 512))

        # Some hybrid ISOs mark appended partitions in GPT, not directly in MBR.
        f.seek(512)
        header = f.read(512)
        if header[:8] == b'EFI PART':
            entries_lba = struct.unpack_from('<Q', header, 72)[0]
            count = struct.unpack_from('<I', header, 80)[0]
            entry_size = struct.unpack_from('<I', header, 84)[0]
            if 128 <= entry_size <= 1024 and 1 <= count <= 256:
                for i in range(count):
                    offset = entries_lba * 512 + i * entry_size
                    if offset + entry_size > size:
                        break
                    f.seek(offset)
                    entry = f.read(entry_size)
                    try:
                        guid = uuid.UUID(bytes_le=entry[:16])
                    except ValueError:
                        continue
                    if guid != BASIC_DATA_GUID:
                        continue
                    first, last = struct.unpack_from('<QQ', entry, 32)
                    if last < first:
                        continue
                    length = (last - first + 1) * 512
                    if length >= MIN_SIZE:
                        candidates.append((f'GPT partition {i+1}', first * 512, length))

        for label, start, length in candidates:
            if start < 0 or start + 512 > size or length < MIN_SIZE or start + length > size:
                continue
            f.seek(start)
            boot = f.read(512)
            if (boot[510:512] == b'\x55\xaa'
                    and boot[82:90] == b'FAT32   '
                    and boot[71:82].rstrip(b' ') == FAT32_LABEL):
                return label

    raise ValueError('Partitia SURFACELOG FAT32 (256 MiB) nu este prezenta sau nu poate fi verificata. NU SCRIE ISO PE STICK!')


if __name__ == '__main__':
    try:
        located = verify(sys.argv[1])
        print('OK - SURFACELOG FAT32 verificat: ' + located)
    except (OSError, ValueError, IndexError) as err:
        print('EROARE - ' + str(err), file=sys.stderr)
        sys.exit(1)
