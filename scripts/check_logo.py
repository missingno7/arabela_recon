"""Validate and optionally render the reconstructed data-only graphics source."""
import argparse
import json
import re
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]

def read_data():
    data={}
    current=None
    for line in (ROOT/'src/LOGODATA.ASM').read_text().splitlines():
        line=line.split(';',1)[0].strip()
        if not line: continue
        if line=='segment CODE private align=1 use16 class=CODE': continue
        if re.fullmatch(r'global (BODYZNAKU|BODYNAPISU|DRAHA)',line): continue
        if re.fullmatch(r'(BODYZNAKU|BODYNAPISU|DRAHA):',line):
            current=line[:-1]; assert current not in data
            data[current]=[]; continue
        assert current and re.fullmatch(r'db [0-9]+(?:, [0-9]+)*',line), \
            f'Only coordinate data declarations are allowed: {line}'
        values=list(map(int,line[3:].split(', ')))
        assert all(0<=v<=255 for v in values)
        data[current].extend(values)
    assert list(data)==['BODYZNAKU','BODYNAPISU','DRAHA']
    for name,size in [('BODYZNAKU',1719),('BODYNAPISU',2792)]:
        assert len(data[name])==size and data[name][-1]==0
        assert all(0<y<200 for y in data[name][:-1])
    assert len(data['DRAHA'])==251*2
    return data

def check(render=False):
    data=read_data()
    report=dict(source='src/LOGODATA.ASM',instructions=0,
                coordinate_bytes=sum(map(len,data.values())),
                tables={name:len(values) for name,values in data.items()})
    (ROOT/'build/logo-data.json').write_text(json.dumps(report,indent=2)+'\n')
    print('Logo source: 5,013 coordinate bytes, no instructions')
    if render:
        from PIL import Image,ImageDraw
        im=Image.new('RGB',(320,200),'black');draw=ImageDraw.Draw(im)
        for name,offset,color in [('BODYZNAKU',0,'cyan'),('BODYNAPISU',17,'white')]:
            x=previous=0
            for y in data[name][:-1]:
                if y<previous: x+=1
                previous=y
                draw.point((x+14,y+offset),fill=color)
        im.resize((960,600),Image.Resampling.NEAREST).save(ROOT/'oracle/logo-data.png')

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--render',action='store_true')
    check(parser.parse_args().render)
