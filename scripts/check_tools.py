"""Pin the compiler, standard units, packer, and execution environment."""
import json
from pathlib import Path
from mz import sha

ROOT=Path(__file__).resolve().parents[1]
TOOLS=[
 ('NASM 2.16.03 (coordinate data only)','tools/nasm/nasm-2.16.03/nasm.exe',
  'a93276636266516421cc9b422f47476c21f7a2949f1ae251556b2f1d33a3be04',
  'https://www.nasm.us/pub/nasm/releasebuilds/2.16.03/win64/nasm-2.16.03-win64.zip'),
 ('Turbo Pascal 6.0','C:/tools/tp6/TPC.EXE',
  '2feaeb1bb125eccc44470755440098500fae8239fc74291da71b233f9445473d',
  'https://raw.githubusercontent.com/jeffpar/pcjs-miscdisks/master/pcx86/lang/borland/pascal/6.00/TURBO-PASCAL-600-DISK1.json'),
 ('Turbo Pascal 6.0 standard units','C:/tools/tp6/TURBO.TPL',
  '65079b04179d219cc7ef02ba6c4c344f43c8ab3e741b61eb1e992f4dc3156b33',
  'same PCjs installation disk'),
 ('LZEXE 0.90','C:/tools/lzexe90/LZEXE.EXE',
  'd9cfc09396ca7a192649a9e0bae8d811bef8b877fac3f77e19c4bd23f695bb53',
  'https://discmaster.textfiles.com/file/16184/MAX_PROGRAMMERS.iso/PROGRAMS/UTILS/COMPRESS/LZEXE.ZIP'),
 ('DOSBox 0.74-3','C:/tools/dosbox/DOSBox.exe',
  'dcfd46fa521f5ce89dce3bf026056f3a1d15533f80321ee887403e30d7949f5e',
  'https://downloads.sourceforge.net/project/dosbox/dosbox/0.74-3/DOSBox0.74-3-win32-installer.exe'),
 ('MS-DOS Player (existing ReC98 build)','C:/tools/nmlgcdos/msdos.exe',
  'f7f6cb0a3e816c5edb13112d327c1bddbf7463fe7bf9a005ca1eb5317751bd02',
  'pre-existing local installation')]

def check():
    result=[]
    for name,path,digest,url in TOOLS:
        resolved=Path(path)
        if not resolved.is_absolute(): resolved=ROOT/resolved
        data=resolved.read_bytes()
        assert sha(data)==digest, f'Tool changed: {path}'
        result.append(dict(name=name,path=path,size=len(data),sha256=digest,source=url))
    (ROOT/'oracle/toolchain.json').write_text(json.dumps(result,indent=2)+'\n')
    print('Pinned tool hashes verified:',len(result))

if __name__=='__main__':check()
