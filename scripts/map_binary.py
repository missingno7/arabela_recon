"""Candidate procedure map plus routine comparisons, never modifies binaries."""
import json
import re
import sys
from pathlib import Path
from mz import MZ, diff
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools/pylib'))
import capstone

EARLY=[('Zahraj',0,0x71),('JmenoSouboru',0x76,0xd1),('NactiSkore',0xd1,0x123),
       ('UlozSkore',0x123,0x15b),('ZapisSkore',0x1ad,0x328),('Cas',0x328,0x36a),
       ('JePrazdne',0x36a,0x388),('VymazPredmet',0x388,0x396),('StejnaPoloha',0x396,0x3dc),
       ('Vypis',0x3e0,0x4d6),('ProhledejMistnost',0x4d6,0x5d9),
       ('Rozdej',0x5d9,0x6bc),('VolneMisto',0x6bc,0x738),
       ('Rozmisteni',0x749,0xb37),('PopisMistnosti',0xfaf,0x17ab),
       ('VypisPrikaz',0x17af,0x1823),('MoznePrikazy',0x1954,0x1cb8),
       ('Udalost',0x1dc7,0x2393),('DoplnPrikaz',0x2393,0x23fc),
       ('NactiPrikaz',0x25d5,0x2c72),('MalaPismena',0x2c72,0x2ced),
       ('ProvedPrikaz',0x3510,0x49ca),('Uvod',0x4b0b,0x4c08)]

UNIT=[('Cekej',0,0x37),('Klavesa',0x37,0x62),('BodVga',0x62,0x7f),
      ('BarvaBodu',0x7f,0xa4),('ZapisBarvu',0xa4,0xfc),
      ('NastavPaletu',0xfc,0x14c),('Rezim',0x14c,0x166),
      ('BodSachovnice',0x166,0x1a4),('StinovanyBod',0x1a4,0x1e8),
      ('CtyriBody',0x1e8,0x2ad),('Znamenko',0x2ad,0x35e),
      ('Logo',0x35e,0xdd1),('Zacni',0xdd1,0xdd6),('InicializaceEleps',0xdd6,0xe04)]

def mapfile(path):
    text=Path(path).read_text()
    rows=re.findall(r'^\s*([0-9A-F]{4}):([0-9A-F]{4})\s+(\S+)',text,re.M)
    return {name:(int(seg,16),int(off,16)) for seg,off,name in rows if name!='@'}

def candidates():
    m=MZ(ROOT/'oracle/ARABELA.EXE')
    result=[]
    known={start:name for name,start,end in EARLY}
    known[0x4d27]='HlavniProgram'
    unit_known={start:name for name,start,end in UNIT}
    # Prologues are candidates only; literal data can also contain this pattern.
    for segment,end,category in [(0,0x53c0,'game'),(0x53c,0x21a0,'custom_unit')]:
        image=m.image[segment*16:segment*16+end]
        for match in re.finditer(b'\x55\x89\xe5',image):
            result.append(dict(segment=segment,offset=match.start(),linear=segment*16+match.start(),
                               name=(known if segment==0 else unit_known).get(match.start()),
                               category=category,confidence='reconstructed_source_entry'))
    out=dict(segments=[dict(segment=0,start=0,end=0x53c0,kind='game_and_literals'),
                       dict(segment=0x53c,start=0x53c0,end=0x7560,kind='custom_unit_code_and_tables'),
                       dict(segment=0x756,start=0x7560,end=0x7640,kind='Borland_Dos'),
                       dict(segment=0x764,start=0x7640,end=0x7c60,kind='Borland_Crt'),
                       dict(segment=0x7c6,start=0x7c60,end=0x8c50,kind='Borland_System'),
                       dict(segment=0x8c5,start=0x8c50,end=0x9150,kind='initialized_data')],
             early_routines=[dict(name=n,start=s,end=e,size=e-s) for n,s,e in EARLY],candidates=result)
    out['unit_routines']=[dict(name=n,start=s,end=e,size=e-s) for n,s,e in UNIT]
    (ROOT/'oracle/map.json').write_text(json.dumps(out,indent=2)+'\n')
    print('Mapped game/unit entries:',len(result),'(includes main and unit initialization)')
    return out

def routines():
    a,b=MZ(ROOT/'oracle/ARABELA.EXE'),MZ(ROOT/'build/first/ARABELA.EXE')
    symbols=mapfile(ROOT/'build/first/ARABELA.MAP')
    lower=symbols['PROHLEDEJMISTNOST'][1]
    upper=symbols['ROZMISTENI'][1]
    nested=[m.start()+lower for m in re.finditer(b'\x55\x89\xe5',b.image[lower:upper])][1:]
    assert len(nested)==2, 'Nested procedure boundaries changed: inspect before comparing'
    symbols['ROZDEJ']=(0,nested[0]);symbols['VOLNEMISTO']=(0,nested[1])
    lower=symbols['UDALOST'][1]+0x2393-0x1dc7
    upper=symbols['NACTIPRIKAZ'][1]
    nested=[m.start()+lower for m in re.finditer(b'\x55\x89\xe5',b.image[lower:upper])]
    assert len(nested)==1, 'Input nested procedure boundary changed: inspect'
    symbols['DOPLNPRIKAZ']=(0,nested[0])
    results=[]
    for name,start,end in EARLY:
        seg,off=symbols[name.upper()]
        md=capstone.Cs(capstone.CS_ARCH_X86,capstone.CS_MODE_16)
        decoded=md.disasm(b.image[seg*16+off:seg*16+off+8192],off)
        terminal=next((ins for ins in decoded if ins.mnemonic=='ret'),None)
        assert terminal is not None, f'No Pascal return found for {name}'
        actual_size=terminal.address+terminal.size-off
        candidate=b.image[seg*16+off:seg*16+off+actual_size]
        reference=a.image[start:end]
        comparison=diff(reference,candidate)
        comparison.pop('differing_ranges')
        # Structural diagnostic only: operands of far calls depend on linked RTL.
        # No normalization is used in raw matching or in any generated executable.
        def call_mask(code):
            md=capstone.Cs(capstone.CS_ARCH_X86,capstone.CS_MODE_16)
            out=bytearray(code)
            for ins in md.disasm(code,0):
                if ins.mnemonic=='lcall' and ins.size==5 and ins.bytes[0]==0x9a:
                    out[ins.address+1:ins.address+5]=bytes(4)
            return bytes(out)
        structural=diff(call_mask(reference),call_mask(candidate))
        results.append(dict(name=name,reference_start=start,candidate_start=off,
                            far_call_operands_ignored=structural['exact'],**comparison))
    (ROOT/'build/routines.json').write_text(json.dumps(results,indent=2)+'\n')
    for r in results:
        print(f"{r['name']:18} {r['reference_start']:04X}/{r['candidate_start']:04X} "
              f"{r['equal_bytes']}/{r['reference_size']} raw identical; exact={r['exact']}")
    print('Raw exact routine bytes:',sum(r['reference_size'] for r in results if r['exact']))
    print('Reconstructed routine span:',sum(r['reference_size'] for r in results),
          '(excludes main, unit routines, and literals outside routines)')
    regions=[]
    for start,end,name in [(0,0x53c0,'game_and_literals'),
                           (0x53c0,0x7560,'Eleps_code_and_coordinate_data'),
                           (0x7560,0x7640,'Dos'),(0x7640,0x7c60,'Crt'),
                           (0x7c60,0x8c50,'System'),(0x8c50,0x9150,'initialized_data')]:
        regions.append(dict(name=name,start=start,end=end,**diff(a.image[start:end],b.image[start:end])))
    (ROOT/'build/regions.json').write_text(json.dumps(regions,indent=2)+'\n')
    print('Whole load image raw exact:',all(r['exact'] for r in regions),
          sum(r['reference_size'] for r in regions),'bytes')
    data=[]
    for name,start,size in [('JMENAPOSTAV',2,16*31),('JMENAPREDMETU',0x1f2,19*31),
                            ('MELODIE',0x440,120)]:
        seg,off=symbols[name]
        contents=diff(a.image[0x8c50+start:0x8c50+start+size],b.image[seg*16+off:seg*16+off+size])
        data.append(dict(name=name,reference_data_offset=start,candidate_data_offset=off,
                         location_exact=start==off,**contents))
    (ROOT/'build/constants.json').write_text(json.dumps(data,indent=2)+'\n')

if __name__=='__main__':
    candidates();routines()
