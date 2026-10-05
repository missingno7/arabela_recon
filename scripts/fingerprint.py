"""Compare standard-unit procedure bodies from the controlled RTL probe."""
import json
import sys
from pathlib import Path
from mz import MZ, diff
from map_binary import mapfile

ROOT=Path(__file__).resolve().parents[1]
reference=MZ(ROOT/'oracle/ARABELA.EXE')
candidate=MZ(ROOT/'build/probes/RTL.EXE')
symbols=mapfile(ROOT/'build/probes/RTL.MAP')
rows=[]
for name,segment,start,end in [('GETDATE',0x756,0,0x22),('GETTIME',0x756,0x36,0x5b),
                              ('SOUND',0x764,0x2c7,0x2f4),('NOSOUND',0x764,0x2f4,0x2fb),
                              ('DELAY',0x764,0x29c,0x2c7)]:
    seg,off=symbols[name]
    comparison=diff(reference.image[segment*16+start:segment*16+end],
                    candidate.image[seg*16+off:seg*16+off+end-start])
    rows.append(dict(name=name,reference_segment=segment,reference_offset=start,
                     candidate_segment=seg,candidate_offset=off,**comparison))
    print(name,comparison['equal_bytes'],'/',end-start,'raw exact:',comparison['exact'])
assert all(row['exact'] for row in rows[:4]), 'Confirmed standard-unit fingerprint changed'
(ROOT/'build/probes/fingerprint.json').write_text(json.dumps(rows,indent=2)+'\n')
allocations=[]
for path in (ROOT/'build/probes').glob('*.EXE'):
    m=MZ(path)
    minimum=(m.h['ss']*16+m.h['sp']+15)//16-(len(m.image)+15)//16
    assert m.h['minalloc']==minimum, f'TP6 allocation formula changed: {path}'
    assert m.h['maxalloc']==minimum+40960, f'TP6 default maximum heap changed: {path}'
    allocations.append(dict(name=path.name,minalloc=minimum,maxalloc=m.h['maxalloc']))
(ROOT/'build/probes/allocations.json').write_text(json.dumps(allocations,indent=2)+'\n')
