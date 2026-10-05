"""Convert PCjs sector JSON to a raw disk; extract root files through FAT12."""
import json
import struct
import sys
from pathlib import Path

def convert(source,destination):
    doc=json.loads(Path(source).read_text())
    tracks=doc.get('diskData',doc) if isinstance(doc,dict) else doc
    out=bytearray()
    for cylinder in tracks:
        for track in cylinder:
            for sector in sorted(track,key=lambda s:s.get('sector',s.get('s'))):
                n=sector.get('length',sector.get('l'))//4
                words=sector.get('data',sector.get('d',[]))
                words=words+[words[-1] if words else 0]*(n-len(words))
                out.extend(struct.pack('<'+'I'*n,*(w&0xffffffff for w in words)))
    Path(destination).write_bytes(out)
    return bytes(out)

def extract(data,folder):
    folder=Path(folder);folder.mkdir(parents=True,exist_ok=True)
    bps=struct.unpack_from('<H',data,11)[0];spc=data[13]
    reserved=struct.unpack_from('<H',data,14)[0];nf=data[16]
    entries=struct.unpack_from('<H',data,17)[0];spf=struct.unpack_from('<H',data,22)[0]
    fat=data[reserved*bps:(reserved+spf)*bps]
    root=(reserved+nf*spf)*bps
    base=root+((entries*32+bps-1)//bps)*bps
    for i in range(entries):
        e=data[root+i*32:root+(i+1)*32]
        if e[0]==0:break
        if e[0]==0xe5 or e[11]&0x18:continue
        name=e[:8].decode('ascii').rstrip();ext=e[8:11].decode('ascii').rstrip()
        if ext:name+='.'+ext
        cluster=struct.unpack_from('<H',e,26)[0];size=struct.unpack_from('<I',e,28)[0]
        content=bytearray();seen=set()
        while 2<=cluster<0xff8:
            if cluster in seen:raise ValueError('FAT cycle')
            seen.add(cluster)
            off=base+(cluster-2)*spc*bps
            content.extend(data[off:off+spc*bps])
            pos=cluster*3//2
            v=struct.unpack_from('<H',fat,pos)[0]
            cluster=(v>>4 if cluster&1 else v&0xfff)
        if len(content)<size:raise ValueError('Short FAT chain')
        (folder/name).write_bytes(content[:size])
        print(name,size)

if __name__=='__main__':
    data=convert(sys.argv[1],sys.argv[2])
    extract(data,sys.argv[3])
