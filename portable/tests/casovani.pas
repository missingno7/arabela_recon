program Casovani;
{$mode objfpc}{$H+}{$codepage utf8}
uses Classes, SysUtils, Zaklad, Arabela_Hra;
var
  nyni : QWord;
  text : UTF8String;
  cekalo : TStringList;
  log : TStringList;
  pocet : integer;
  predtim : QWord;
  misto : poloha;
  semeno : LongInt;

function HodinyTestu : QWord;
begin Result := nyni end;
procedure Pockej(ms : word);
begin
  cekalo.Add(IntToStr(ms));
  Inc(nyni,ms)
end;
procedure VystupTestu(const s : UTF8String);
begin text := text+s end;
procedure Over(ano : boolean; const co : string);
begin
  if not ano then raise Exception.Create(co);
  log.Add('PASS '+co)
end;

procedure PrazdnySvet;
var i : integer;
begin
  for i := 0 to 15 do postavy[i].x := 0;
  for i := 0 to 18 do predmety[i].x := 0;
  for i := 0 to 3 do zvlastni[i].x := 0;
  kdeJsem.x := 2; kdeJsem.y := 3; kdeJsem.z := 1;
  uvnitr := 0; pocetRuk := 0; konec := false;
  faze := Hra; cil := -1;
  ProhledejMistnost(2,3,1)
end;

procedure DalsiUdalost;
begin
  nyni := QWord(ted+odstup)*1000;
  pocet := pocetUdalosti;
  Over(not Udalost,'no event at exact deadline '+IntToStr(pocet));
  Inc(nyni,999);
  Over(not Udalost,'whole-second threshold '+IntToStr(pocet));
  Inc(nyni);
  Over(Udalost,'event after strict deadline '+IntToStr(pocet));
  Over(pocetUdalosti = pocet+1,'one event per check '+IntToStr(pocet));
  Over(QWord(ted)*1000 < nyni,'event timestamp sampled before alarm/text waits '+IntToStr(pocet))
end;

begin
  log := TStringList.Create; cekalo := TStringList.Create;
  try
    Vystup := @VystupTestu; Hodiny := @HodinyTestu; Cekani := @Pockej;
    PripojVystup;
    Vypis('A B!? ');
    Over((text = 'A B!? ') and (nyni = 240),'60 ms per non-space; spaces immediate');
    Over(cekalo.Count = 8,'10/50 ms pairs for four characters');
    for pocet := 0 to 7 do
      if Odd(pocet) then Over(cekalo[pocet] = '50','50 ms gap '+IntToStr(pocet))
      else Over(cekalo[pocet] = '10','10 ms tone duration '+IntToStr(pocet));
    predtim := nyni; WriteLn('TITLE 123');
    Over(nyni = predtim,'plain Write/WriteLn output stays instantaneous');
    Vypis('kůň'); Over(nyni = predtim+180,'UTF-8 glyphs do not split into delayed bytes');
    PrazdnySvet; predtim := nyni; ObnovPrikazy;
    Over(nyni = predtim,'silent valid-command refresh consumes no time');
    nyni := 0; ted := 0; odstup := 300; dalsiOdstup := 120;
    pocetUdalosti := 0; chechota := true; chechotaZije := true;
    druhUdalosti := 0;
    DalsiUdalost;
    Over(not chechotaZije and not chechota,'Chechota disappearance');
    Over((odstup = 120) and (dalsiOdstup = 180),'first interval 300 then 120 seconds');
    DalsiUdalost;
    Over((jmenaPostav[11] = 'pani Blekotova') and chechota,'Mullerova/Blekota marriage');
    Over((odstup = 180) and (dalsiOdstup = 240),'second follow-up interval 180 seconds');
    pocetRuk := 2; ruce[1] := 17; ruce[2] := 18; Zaklad.RandSeed := 12345678;
    DalsiUdalost;
    Over((pocetRuk = 1) and (ruce[1] = 17) and (predmety[18].x <> 0),
         'wolf steals eligible item and preserves crystal ball');
    Over((druhUdalosti = 1) and (odstup = 240),'wolf -> basilisk; next interval 240');
    misto := kdeJsem; uvnitr := 1;
    DalsiUdalost;
    Over(not StejnaPoloha(misto,kdeJsem) and (kdeJsem.z = misto.z) and (uvnitr = 0),
         'basilisk changes room in same realm and leaves special location');
    Over((druhUdalosti = 2) and (odstup = 300),'basilisk -> exchange; next interval 300');
    for pocet := 0 to 15 do
    begin
      postavy[pocet].x := ((pocet shr 1) and 3)+1;
      postavy[pocet].y := (pocet shr 3)*4+1;
      postavy[pocet].z := (pocet and 1)+1
    end;
    DalsiUdalost;
    Over((druhUdalosti = 0) and (odstup = 360),'exchange -> wolf; next interval 360');
    { Existing 63-assertion oracle fixture checks the exact swapped positions/items. }
    pocetRuk := 1; ruce[1] := 17;
    DalsiUdalost;
    Over(druhUdalosti = 2,'wolf skipped when inventory contains only crystal ball');
    PrazdnySvet; chechota := false; chechotaZije := true;
    pocetUdalosti := 0; ted := 0; odstup := 300; dalsiOdstup := 120;
    DalsiUdalost;
    Over(chechota and chechotaZije,'marriage may precede Chechota disappearance');
    DalsiUdalost;
    Over(not chechota and not chechotaZije,'both introductory events occur in reversed order');
    { Winning score must include typing the final response, not ask-name time. }
    PrazdnySvet; postavy[9] := kdeJsem; pocetRuk := 1; ruce[1] := 10;
    ProhledejMistnost(2,3,1); zacatek := 0; nyni := 123900;
    SouborSkore := ExpandFileName('timing-score.SCO'); DeleteFile(SouborSkore);
    text := '';
    OdesliPrikaz('vysvobod Arabelu');
    Over((faze = Jmeno) and (doba = nyni div 1000) and (doba > 123),
         'score includes the final character waits before completion');
    Over((Pos('Spotreboval jsi',text) > 0) and
         (Pos('Zadejte svoje jmeno',text) > Pos('Spotreboval jsi',text)),
         'elapsed result and ranking displayed before asking for score name');
    predtim := doba; Inc(nyni,60000); OdesliPrikaz('');
    Over((faze = Hotovo) and (nejlepsi.hraci[1].cas = predtim),
         'empty original-style score name accepted; time excludes name entry');
    semeno := SemenoCasu;
    Over(((LongWord(semeno) and $FF) <= 59) and
         (((LongWord(semeno) shr 8) and $FF) <= 23) and
         (((LongWord(semeno) shr 16) and $FF) <= 99) and
         (((LongWord(semeno) shr 24) and $FF) <= 59),'TP6 wall-clock seed byte layout');
    log.SaveToFile('timing-results.txt')
  finally Vystup := nil; Hodiny := nil; Cekani := nil; log.Free; cekalo.Free end
end.
