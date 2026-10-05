# LZEXE 0.90 round trip

The 17,966-byte archive from DiscMaster's MAX_PROGRAMMERS CD contains actual
LZEXE 0.90, with the version documented in its accompanying files:
https://discmaster.textfiles.com/browse/16184/MAX_PROGRAMMERS.iso/PROGRAMS/UTILS/COMPRESS/LZEXE.ZIP

The packed loader's full 232-byte signature independently identifies 0.90.
The Python unpacker follows UNLZEXE's stream and relocation reconstruction;
it reproduces the supplied canonical hash. DOS UNLZEXE 0.8 independently
agrees. Canonical unpacking is retained unchanged in `oracle/ARABELA.EXE`.

Packing the canonical unpack with original LZEXE 0.90 gives identical packed
payload, but four different header bytes: minimum/maximum allocation.
The raw failed comparison is retained at `build/roundtrip/comparison.json`.
Canonical unpacking uses a memory correction appropriate to another packing
layout and adds 922 paragraphs here.

The original stack end is `099F:4000`; the load image is 37,200 bytes. Required
extra paragraphs from those values are:

```text
099F + 4000/16 - ceil(37200/16) = 1162
maximum = 1162 + 655360/16 = 42122
```

Canonical unpacking instead reports 2084 and 43044. `scripts/roundtrip.py`
generates **a separate research reference**, `oracle/TPALLOC.EXE`, changing
only these two allocation fields. The canonical header's 512-byte alignment,
relocations and complete load image remain untouched. Original LZEXE 0.90
then produces 20,837 byte-identical bytes, with the original SHA-256.
The full successful comparison is `build/roundtp/comparison.json`.

This experiment corrects information lost during unpacking. It does not
modify any compiler output and is never part of the source build path.
TP6's actual MZ header is paragraph-aligned, unlike the canonical UNLZEXE
header. Final source closure must compare load image and linear relocation
locations and then demand raw packed-file identity. Literal equality to the
canonical reconstructed MZ header is not necessarily literal compiler output.

## Source closure

The unmodified TP6 source build is 39,552 bytes, with a 2,352-byte MZ header.
Its complete 37,200-byte load image and 580 ordered linear relocation positions
equal the canonical unpack. Its allocation values naturally are 1162/42122.
Packing this compiler-produced executable with original LZEXE 0.90 gives a
raw byte-identical 20,837-byte executable and the original SHA-256.
See `build/comparison.json` and `build/packed/comparison.json`.
No allocation correction or any other patch is applied to compiler output.
