"""UNLZEXE algorithm port, preserving its canonical header policy.

Reference: tools/unlzexe.c (Mitugu Kurizono et al.). This is an analysis
tool, never part of the reconstructed program or its build output.
"""
import re
import struct
from pathlib import Path
from mz import MZ, sha

def unpack(path, output):
    mz = MZ(path)
    raw = mz.raw
    source = (Path(__file__).resolve().parents[1]/'tools/unlzexe.c').read_text()
    entry = mz.header_size + mz.h['cs'] * 16 + mz.h['ip']
    version = None
    for name in ('90','91'):
        body = re.search(r'sig'+name+r'\s*\[\]\s*=\s*\{(.*?)\}', source, re.S).group(1)
        sig = bytes(int(x,16) for x in re.findall(r'0x([0-9A-Fa-f]{2})\b', body))
        if raw[entry:entry+len(sig)] == sig:
            version = int(name)
    if version != 90:
        raise ValueError(f'Expected verified LZEXE 0.90 loader, found {version}')
    csbase = mz.header_size + mz.h['cs'] * 16
    info = struct.unpack_from('<8H', raw, csbase)
    relocs = []
    pos = csbase + 0x19d
    for seg in range(0, 0x10000, 0x1000):
        count, = struct.unpack_from('<H', raw, pos); pos += 2
        for _ in range(count):
            off, = struct.unpack_from('<H', raw, pos); pos += 2
            relocs.append((off,seg))
    pos = mz.header_size + (mz.h['cs'] - info[4]) * 16
    def byte():
        nonlocal pos
        v = raw[pos]; pos += 1
        return v
    def word():
        return byte() | byte() << 8
    bits = word(); count = 16
    def bit():
        nonlocal bits,count
        v = bits & 1; count -= 1
        if count == 0:
            bits = word(); count = 16
        else:
            bits >>= 1
        return v
    image = bytearray()
    while True:
        if bit():
            image.append(byte()); continue
        if not bit():
            length = (bit() << 1 | bit()) + 2
            span = byte() - 256
        else:
            lo,hi = byte(),byte()
            span = (lo | (hi & 0xf8) << 5 | 0xe000) - 65536
            length = (hi & 7) + 2
            if length == 2:
                length = byte()
                if length == 0:
                    break
                if length == 1:
                    continue
                length += 1
        if not -len(image) <= span < 0:
            raise ValueError('Invalid back reference')
        for _ in range(length):
            image.append(image[span])
    h = mz.words.copy()
    h[10],h[11],h[8],h[7] = info[:4]
    h[3] = len(relocs); h[12] = 28
    header_size = (28 + len(relocs)*4 + 511) & ~511
    h[4] = header_size // 16
    if h[6]:
        delta = info[5] + (info[6]+15)//16 + 9
        h[5] = (h[5]-delta) & 65535
        if h[6] != 65535:
            h[6] = (h[6]-delta) & 65535
    h[1] = (header_size + len(image)) % 512
    h[2] = (header_size + len(image) + 511)//512
    header = struct.pack('<14H',*h[:14]) + b''.join(struct.pack('<HH',*r) for r in relocs)
    result = header.ljust(header_size,b'\0') + image
    Path(output).write_bytes(result)
    return dict(lzexe_version='0.90',loader_signature_bytes=len(sig),info=list(info),
                sha256=sha(result),size=len(result),load_size=len(image),relocations=len(relocs),
                consumed_stream_end=pos,entry_file_offset=entry,loader_base=csbase)
