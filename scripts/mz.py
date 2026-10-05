"""Strict MZ inspection and comparisons. Addresses are load-module relative."""
import hashlib
import struct
from pathlib import Path

FIELDS = 'magic last_page pages relocations header_paragraphs minalloc maxalloc ss sp checksum ip cs relocation_offset overlay'.split()

def sha(data):
    return hashlib.sha256(data).hexdigest()

class MZ:
    def __init__(self, path):
        self.path = Path(path)
        self.raw = self.path.read_bytes()
        if len(self.raw) < 28:
            raise ValueError('Truncated MZ')
        self.words = list(struct.unpack_from('<14H', self.raw))
        self.h = dict(zip(FIELDS, self.words))
        if self.h['magic'] not in (0x5a4d, 0x4d5a):
            raise ValueError('Not MZ')
        self.header_size = self.h['header_paragraphs'] * 16
        self.declared_size = (self.h['pages'] - bool(self.h['last_page'])) * 512 + self.h['last_page']
        if not 28 <= self.header_size <= self.declared_size <= len(self.raw):
            raise ValueError('Invalid MZ sizes')
        end = self.h['relocation_offset'] + 4 * self.h['relocations']
        if end > self.header_size:
            raise ValueError('Relocations outside header')
        self.relocs = [struct.unpack_from('<HH', self.raw, i) for i in range(self.h['relocation_offset'], end, 4)]
        self.linear_relocs = [off + seg * 16 for off, seg in self.relocs]
        self.image = self.raw[self.header_size:self.declared_size]
        self.header = self.raw[:self.header_size]

    def report(self):
        return dict(path=str(self.path), size=len(self.raw), sha256=sha(self.raw), header=self.h,
                    header_size=self.header_size, load_size=len(self.image), overlay_bytes=len(self.raw)-self.declared_size,
                    entry=f"{self.h['cs']:04X}:{self.h['ip']:04X}", stack=f"{self.h['ss']:04X}:{self.h['sp']:04X}",
                    relocations=[dict(offset=o, segment=s, linear=o+s*16) for o,s in self.relocs])

def diff(a, b):
    n = max(len(a), len(b))
    ranges = []
    start = None
    equal = 0
    for i in range(n):
        same = i < len(a) and i < len(b) and a[i] == b[i]
        equal += same
        if not same and start is None:
            start = i
        if same and start is not None:
            ranges.append([start, i]); start = None
    if start is not None:
        ranges.append([start, n])
    return dict(exact=a == b, reference_size=len(a), candidate_size=len(b), equal_bytes=equal,
                differing_bytes=n-equal, first_difference=ranges[0][0] if ranges else None,
                range_count=len(ranges), differing_ranges=ranges)

def compare(reference, candidate):
    a,b = MZ(reference),MZ(candidate)
    return dict(reference=a.report(), candidate=b.report(),
                file=diff(a.raw,b.raw), header=diff(a.header,b.header), load_module=diff(a.image,b.image),
                header_fields={k:[a.h[k],b.h[k]] for k in FIELDS if a.h[k] != b.h[k]},
                relocation_pairs_exact=a.relocs == b.relocs,
                relocation_linear_order_exact=a.linear_relocs == b.linear_relocs,
                relocation_linear_multiset_exact=sorted(a.linear_relocs) == sorted(b.linear_relocs))
