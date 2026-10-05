"""Small reproducible research commands; all generated files stay outside assets."""
import argparse
import json
import re
import struct
import sys
from pathlib import Path
from mz import MZ, sha, compare
from unpack import unpack

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools/pylib'))

def save(path, value):
    Path(path).write_text(json.dumps(value,indent=2)+'\n',encoding='utf-8')

def oracle():
    expected = {'ARABELA.EXE':'f27d7e4f56fccb1258e51a45e16bffafb5b0f4f93029040a1b2e20ef770d2ec3',
                'ARABELA.SCO':'b3497d6b006e9d2b8cb407eb5d63ce513a90c80a86606b9f972cb480f9856e8a',
                'arabela.7z':'655e5898d97b953af9a78856c0f942f844bdaabc76bada32cb69562311e97075'}
    assets = []
    for name,digest in expected.items():
        data=(ROOT/'assets'/name).read_bytes()
        assert sha(data) == digest, f'Original changed: {name}'
        assets.append(dict(name=name,size=len(data),sha256=digest))
    save(ROOT/'oracle/assets.json',assets)
    info=unpack(ROOT/'assets/ARABELA.EXE',ROOT/'oracle/ARABELA.EXE')
    assert info['sha256'] == '2b7c22130ba85759821671833c78da985c6f46c5f36b928edcb33efb2ebd2372'
    save(ROOT/'oracle/unpack.json',info)
    for folder in ('assets','oracle'):
        save(ROOT/f'oracle/{folder}-mz.json',MZ(ROOT/f'{folder}/ARABELA.EXE').report())
    print(json.dumps(info,indent=2))

def scores():
    data=(ROOT/'assets/ARABELA.SCO').read_bytes()
    exe=(ROOT/'assets/ARABELA.EXE').read_bytes()
    records=[]
    for i in range(11):
        record=data[1+i*31:1+(i+1)*31]
        n=record[4]
        records.append(dict(index=i+1,offset=1+i*31,value=struct.unpack_from('<i',record)[0],
                            length=n,name=record[5:5+n].decode('cp852',errors='replace') if n<=20 else None,
                            day=struct.unpack_from('<H',record,25)[0],month=struct.unpack_from('<H',record,27)[0],
                            year=struct.unpack_from('<H',record,29)[0],
                            raw=record.hex(),packed_exe_occurrence=exe.find(record)))
    report=dict(count=data[0],records=records,tail_offset=63,tail_size=len(data[63:]),
                tail_in_packed_exe=exe.find(data[63:]))
    save(ROOT/'oracle/scores.json',report)
    print(json.dumps(report,indent=2,ensure_ascii=True))

def disasm(path,start,end,segment=0):
    import capstone
    mz=MZ(path)
    md=capstone.Cs(capstone.CS_ARCH_X86,capstone.CS_MODE_16)
    for ins in md.disasm(mz.image[segment*16+start:segment*16+end],start):
        print(f'{segment:04X}:{ins.address:04X}  {ins.bytes.hex():<20} {ins.mnemonic:<8} {ins.op_str}')

def strings(path):
    mz=MZ(path)
    # Literal candidates: printable ASCII only. Preserve raw CP852 bytes separately.
    result=[]
    for m in re.finditer(rb'[\x20-\x7e]{4,}',mz.image):
        pos=m.start(); n=mz.image[pos-1] if pos else 0
        result.append(dict(linear=pos,file_offset=pos+mz.header_size,
                           preceding_byte=n,text=m.group().decode('ascii')))
    save(ROOT/'oracle/strings.json',result)
    for row in result:
        print(f"{row['linear']:05X} ({row['preceding_byte']:3}) {row['text']}")

if __name__ == '__main__':
    p=argparse.ArgumentParser()
    sub=p.add_subparsers(dest='cmd',required=True)
    sub.add_parser('oracle'); sub.add_parser('scores')
    q=sub.add_parser('mz'); q.add_argument('path')
    q=sub.add_parser('strings'); q.add_argument('path')
    q=sub.add_parser('diff'); q.add_argument('reference');q.add_argument('candidate');q.add_argument('--out')
    q=sub.add_parser('disasm');q.add_argument('path');q.add_argument('start',type=lambda x:int(x,16));q.add_argument('end',type=lambda x:int(x,16));q.add_argument('--segment',type=lambda x:int(x,16),default=0)
    args=p.parse_args()
    if args.cmd == 'oracle': oracle()
    elif args.cmd == 'scores': scores()
    elif args.cmd == 'mz': print(json.dumps(MZ(args.path).report(),indent=2))
    elif args.cmd == 'strings': strings(args.path)
    elif args.cmd == 'disasm': disasm(args.path,args.start,args.end,args.segment)
    elif args.cmd == 'diff':
        result=compare(args.reference,args.candidate)
        if args.out: save(args.out,result)
        brief={k:v for k,v in result.items() if k not in ('reference','candidate')}
        for k in ('file','header','load_module'): brief[k]={a:b for a,b in brief[k].items() if a!='differing_ranges'}
        print(json.dumps(brief,indent=2))
        sys.exit(0 if result['file']['exact'] else 1)
