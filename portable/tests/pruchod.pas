program Pruchod;
{$mode objfpc}{$H+}{$codepage utf8}
uses Classes, SysUtils, Zaklad, Arabela_Hra;
var
  prikazyHrace,log : TStringList;
  nyni : QWord;
  kroku : integer;
  hledam : set of byte;

{$I stav.inc}

function HodinyTestu : QWord;
begin Result := nyni end;

procedure VystupTestu(const s : UTF8String);
begin { Complete walkthrough transcript is captured by the command list. } end;

procedure Musi(ano : boolean; const co : string);
begin if not ano then raise Exception.Create(co) end;

procedure Prikaz(const s : string);
begin
  Inc(kroku); Musi(kroku < 1000,'Walkthrough exceeded 1000 commands');
  prikazyHrace.Add(s); OdesliPrikaz(s)
end;

function Mam(vec : byte) : boolean;
var i : integer;
begin
  Result := false;
  for i := 1 to pocetRuk do if ruce[i] = vec then Result := true
end;

procedure Ven;
begin
  if uvnitr <> 0 then Prikaz(Zkratka(Ord('-')))
end;

procedure JdiKam(const kam : poloha);
begin
  Ven;
  if kdeJsem.z <> kam.z then
  begin Musi(Mam(18),'Missing cloak'); Prikaz('pouzij cestovni plast') end;
  if kdeJsem.x <> kam.x then
  begin
    while kdeJsem.y < 3 do Prikaz('jdi na jih');
    while kdeJsem.y > 3 do Prikaz('jdi na sever');
    while kdeJsem.x < kam.x do Prikaz('jdi na vychod');
    while kdeJsem.x > kam.x do Prikaz('jdi na zapad')
  end;
  while kdeJsem.y < kam.y do Prikaz('jdi na jih');
  while kdeJsem.y > kam.y do Prikaz('jdi na sever');
  if zde.zvlastnost <> -1 then Prikaz(Zkratka(Ord('-')))
end;

procedure Ziskej(vec : byte);
var kam : poloha; strazce,potrebny : shortint;
begin
  if Mam(vec) then Exit;
  Musi(not (vec in hledam),'Dependency cycle at item '+IntToStr(vec));
  Include(hledam,vec);
  Musi(predmety[vec].x <> 0,'Missing item '+IntToStr(vec));
  kam := predmety[vec];
  ProhledejMistnost(kam.x,kam.y,kam.z); strazce := zde.postava;
  ProhledejMistnost(kdeJsem.x,kdeJsem.y,kdeJsem.z);
  if strazce >= 0 then
  begin
    potrebny := strazce+1;
    Musi((strazce <> 0) and (strazce <> 6) and (strazce <> 9),'Unexpected special exchange');
    Ziskej(potrebny);
    JdiKam(kam);
    Prikaz('odevzdej '+jmenaPredmetu[potrebny])
  end
  else
  begin
    JdiKam(kam); Prikaz('seber '+jmenaPredmetu[vec])
  end;
  Musi(Mam(vec),'Acquisition failed for '+IntToStr(vec));
  Exclude(hledam,vec)
end;

begin
  prikazyHrace := TStringList.Create; log := TStringList.Create;
  try
    Vystup := @VystupTestu; Hodiny := @HodinyTestu; PripojVystup;
    SouborSkore := ExpandFileName('walkthrough.SCO');
    DeleteFile(SouborSkore); nyni := 0; NovaHra(12345678);
    { No gameplay state edits: read positions, submit real commands, and
      navigate through the actual map to solve both dependency chains. }
    Ziskej(18);
    Ziskej(0); JdiKam(postavy[0]); Prikaz('odevzdej zvonecek');
    Ziskej(1); JdiKam(postavy[0]); Prikaz('odevzdej pohadkovou knihu');
    Musi(Mam(7),'Majer did not give ring');
    JdiKam(postavy[6]); Prikaz('promen Rumburaka v klic');
    Musi(Mam(10) and (postavy[6].x = 0),'Rumburak transformation');
    nyni := 123000;
    JdiKam(postavy[9]); Prikaz('vysvobod Arabelu');
    Musi(konec and (faze = Jmeno) and (doba = 123),'Win/name phase and elapsed time');
    ZapisStav;
    Prikaz('Příliš žluťoučký kůň');
    Musi(faze = Hotovo,'Game did not finish');
    NactiSkore;
    Musi((nejlepsi.pocet = 1) and (nejlepsi.hraci[1].cas = 123),'Persisted score');
    Musi(nejlepsi.hraci[1].jmeno = 'Příliš žluťouč','UTF-8 score name boundary');
    prikazyHrace.SaveToFile('walkthrough.txt');
    log.Add('PASS native start-to-finish walkthrough, '+IntToStr(kroku)+' real commands');
    log.Add('PASS win/name/completed phases, frozen monotonic score, UTF-8 name, score reload');
    log.SaveToFile('walkthrough-results.txt')
  finally
    Vystup := nil; Hodiny := nil; prikazyHrace.Free; log.Free
  end
end.
