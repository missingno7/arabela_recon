program Skore;
{$mode objfpc}{$H+}{$codepage utf8}
uses Classes, SysUtils, Zaklad, Arabela_Hra;
var log : TStringList; i,j : integer; f : TFileStream; text : UTF8String;

procedure Over(ano : boolean; const co : string);
begin
  if not ano then raise Exception.Create(co);
  log.Add('PASS '+co)
end;

procedure VystupTestu(const s : UTF8String);
begin text := text+s end;

begin
  log := TStringList.Create;
  try
    Vystup := @VystupTestu; PripojVystup;
    Over((SizeOf(zaznam) = 31) and (SizeOf(tabulka) = 342) and
         (SizeOf(obsahMistnosti) = 41),'original packed score/room ABI');
    ForceDirectories('skóre'); SouborSkore := ExpandFileName('skóre/test.SCO');
    DeleteFile(SouborSkore); NactiSkore;
    Over((nejlepsi.pocet = 0) and not FileExists(SouborSkore),'missing file starts empty without writing');
    jmenoHrace := 'PRVNI'; Over(ZapisSkore(500) = 1,'first score');
    jmenoHrace := 'DRUHY'; Over(ZapisSkore(500) = 2,'equal times retain existing player order');
    jmenoHrace := 'LEPSI'; Over(ZapisSkore(100) = 1,'faster score inserted at head');
    NactiSkore;
    Over((nejlepsi.pocet = 3) and (nejlepsi.hraci[1].jmeno = 'LEPSI') and
         (nejlepsi.hraci[2].jmeno = 'PRVNI') and (nejlepsi.hraci[3].jmeno = 'DRUHY'),
         'atomic score replacement and UTF-8 filesystem path');
    for i := 1 to 11 do
    begin
      nejlepsi.hraci[i].cas := i*100;
      nejlepsi.hraci[i].jmeno := 'HRAC'
    end;
    nejlepsi.pocet := 11; UlozSkore;
    Over(ZapisSkore(1200) = 12,'full table rejects slower score');
    Over(ZapisSkore(1) = 1,'full table accepts faster score');
    Over((nejlepsi.pocet = 11) and (nejlepsi.hraci[11].cas = 1000),'full table drops only last player');
    f := TFileStream.Create(SouborSkore,fmOpenRead);
    try Over(f.Size = 342,'native score remains 342 bytes') finally f.Free end;
    for i := 1 to 4 do
    begin
      FillChar(nejlepsi,SizeOf(nejlepsi),0);
      case i of
        1 : nejlepsi.pocet := 255;
        2 : begin nejlepsi.pocet := 1; nejlepsi.hraci[1].cas := -1 end;
        3 : begin nejlepsi.pocet := 1; nejlepsi.hraci[1].jmeno[0] := #255 end;
        4 : begin nejlepsi.pocet := 2; nejlepsi.hraci[1].cas := 200; nejlepsi.hraci[2].cas := 100 end
      end;
      Over(PisSkore(nejlepsi,SizeOf(nejlepsi)),'write malformed fixture '+IntToStr(i));
      NactiSkore; Over(nejlepsi.pocet = 0,'reject malformed fixture '+IntToStr(i))
    end;
    f := TFileStream.Create(SouborSkore,fmCreate);
    try j := 1; f.WriteBuffer(j,1) finally f.Free end;
    NactiSkore; Over(nejlepsi.pocet = 0,'reject truncated file');
    SouborSkore := ExpandFileName('neexistuje/adresar/ARABELA.SCO');
    text := ''; UlozSkore;
    Over(Pos('nepodarilo ulozit',text) > 0,'write failure is visible');
    if ParamCount > 0 then
    begin
      SouborSkore := ExpandFileName(ParamStr(1)); NactiSkore;
      Over((nejlepsi.pocet = 2) and (nejlepsi.hraci[1].cas = 5189) and
           (nejlepsi.hraci[1].jmeno = 'MALENKO JAROMIR') and
           (nejlepsi.hraci[2].cas = 5456) and (nejlepsi.hraci[2].jmeno = 'BUFFY'),
           'read original ARABELA.SCO without modifying it');
      Over(nejlepsi.hraci[11].cas = 0,'unused DOS memory tail sanitized')
    end;
    log.SaveToFile('score-results.txt')
  finally Vystup := nil; log.Free end
end.
