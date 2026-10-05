{ Pouze zkusebni spousteci kod, neni soucasti obnovovane hry. }
procedure Overeni;
var
  predmet : shortint;
  p, q : poloha;
  puvodni : tabulka;
  i, poradi : word;
  f : file;

  procedure Musi(ano : boolean; chyba : word);
  begin
    if not ano then
    begin
      WriteLn('FAIL ',chyba);
      Close(Output);
      Halt(1)
    end
  end;

begin
  Assign(Output,'RESULT.TXT');
  Rewrite(Output);
  Musi(SizeOf(zaznam) = 31,1);
  Musi(SizeOf(tabulka) = 342,2);
  Musi(SizeOf(obsahMistnosti) = 41,26);
  Musi(MalaPismena('AbC XYz 123') = 'abc xyz 123',27);
  predmet := 5;
  Musi(not JePrazdne(predmet),3);
  VymazPredmet(predmet);
  Musi(JePrazdne(predmet) and (predmet = -1),4);
  p.x := 1; p.y := 3; p.z := 2;
  q := p;
  Musi(StejnaPoloha(p,q),5);
  Inc(q.z);
  Musi(not StejnaPoloha(p,q),6);
  { Zkouska posledni nalezene postavy a poradi predmetu. }
  for i := 0 to 15 do postavy[shortint(i)].x := 0;
  for i := 0 to 18 do predmety[shortint(i)].x := 0;
  for i := 0 to 3 do zvlastni[shortint(i)].x := 0;
  postavy[2] := p; postavy[4] := p;
  predmety[3] := p; predmety[17] := p;
  zvlastni[1] := p;
  ProhledejMistnost(1,3,2);
  Musi(zde.postava = 4,7);
  Musi((zde.pocetPredmetu = 2) and (zde.seznam[1] = 3) and (zde.seznam[2] = 17),8);
  Musi(zde.predmetJeTu[3] and zde.predmetJeTu[17] and not zde.predmetJeTu[0],9);
  Musi(zde.zvlastnost = 1,10);
  ProhledejMistnost(4,5,1);
  Musi(JePrazdne(zde.postava) and JePrazdne(zde.zvlastnost) and (zde.pocetPredmetu = 0),11);
  JmenoSouboru;
  if ParamStr(1) = 'missing' then
  begin
    FillChar(nejlepsi,SizeOf(nejlepsi),$A5);
    NactiSkore;
    Musi(nejlepsi.pocet = 0,12);
    Musi(nejlepsi.hraci[11].cas = -1515870811,13)
  end
  else
  begin
    NactiSkore;
    Musi(nejlepsi.pocet = 2,14);
    Musi((nejlepsi.hraci[1].cas = 5189) and
         (nejlepsi.hraci[1].jmeno = 'MALENKO JAROMIR'),15);
    Musi((nejlepsi.hraci[2].cas = 5456) and
         (nejlepsi.hraci[2].jmeno = 'BUFFY'),16);
    Musi((nejlepsi.hraci[1].den = 14) and
         (nejlepsi.hraci[1].mesic = 6) and (nejlepsi.hraci[1].rok = 1995),17);
    puvodni := nejlepsi;
    if ParamStr(1) = 'insert' then
    begin
      Assign(Input,'INPUT.TXT');
      Reset(Input);
      poradi := ZapisSkore(100);
      Close(Input);
      Musi((poradi = 1) and (nejlepsi.pocet = 3),18);
      Musi((nejlepsi.hraci[1].cas = 100) and
           (nejlepsi.hraci[1].jmeno = 'ZKOUSKA HRACE'),19);
      Musi(nejlepsi.hraci[2].jmeno = puvodni.hraci[1].jmeno,20);
      Musi(nejlepsi.hraci[3].jmeno = puvodni.hraci[2].jmeno,21);
      Musi(nejlepsi.hraci[1].rok >= 1980,22);
      puvodni := nejlepsi
    end;
    UlozSkore;
    FillChar(nejlepsi,SizeOf(nejlepsi),0);
    NactiSkore;
    Musi(nejlepsi.pocet = puvodni.pocet,23);
    Musi(nejlepsi.hraci[1].cas = puvodni.hraci[1].cas,24);
    Musi(nejlepsi.hraci[11].cas = puvodni.hraci[11].cas,25)
  end;
  WriteLn('PASS ',ParamStr(1));
  Close(Output)
end;
