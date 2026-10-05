"""Prove allocation loss in UNLZEXE 0.90 headers. Research references only.

Never transforms compiler output. TPALLOC.EXE is a separate oracle experiment.
"""
import json
import struct
from pathlib import Path
from mz import MZ, sha, compare
ROOT=Path(__file__).resolve().parents[1]

def prepare():
    m=MZ(ROOT/'oracle/ARABELA.EXE')
    needed=(m.h['ss']*16+m.h['sp']+15)//16-(len(m.image)+15)//16
    assert needed==1162
    # TP6 default heap maximum: 655360 bytes, i.e. 40960 paragraphs.
    h=m.words.copy();h[5]=needed;h[6]=needed+40960
    raw=struct.pack('<14H',*h)+m.raw[28:]
    (ROOT/'oracle/TPALLOC.EXE').write_bytes(raw)
    report=dict(canonical_minalloc=m.h['minalloc'],compiler_minalloc=needed,
                canonical_maxalloc=m.h['maxalloc'],compiler_maxalloc=h[6],
                discrepancy_paragraphs=m.h['minalloc']-needed,
                canonical_header_size=m.header_size,load_module_unchanged=raw[m.header_size:]==m.image,
                allocation_reference_sha256=sha(raw),
                method='SS:SP end minus rounded load-image size; maximum adds TP6 default heap size',
                warning='Allocation-corrected research oracle, not modified compiler output')
    (ROOT/'oracle/allocation.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))

if __name__=='__main__':prepare()
