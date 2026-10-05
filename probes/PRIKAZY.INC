{ Deterministicke zkousky skutecnych procedur; pouze /DOVERENI. }
procedure OverPrikazy;
var
  i, a, b : word;
  p, q, r : poloha;
  semeno : LongInt;
  pocetZkousek : word;

  procedure Musi(ano : boolean; cislo : word);
  begin
    if not ano then begin WriteLn('FAIL actions ',cislo); Close(Output); Halt(1) end;
    Inc(pocetZkousek);
    WriteLn('OK ',cislo);
    Flush(Output)
  end;

  procedure Obnov;
  var i : word;
  begin
    for i := 0 to 15 do postavy[shortint(i)].x := 0;
    for i := 0 to 18 do predmety[shortint(i)].x := 0;
    for i := 0 to 3 do zvlastni[shortint(i)].x := 0;
    kdeJsem.x := 2; kdeJsem.y := 3; kdeJsem.z := 1;
    pocetRuk := 0; uvnitr := 0; konec := false;
    chechotaZije := true; cil := -1;
    ProhledejMistnost(kdeJsem.x,kdeJsem.y,kdeJsem.z)
  end;

  procedure Prohledej;
  begin ProhledejMistnost(kdeJsem.x,kdeJsem.y,kdeJsem.z) end;

  procedure NastavUdalost(druh : byte);
  begin
    ted := -86400; odstup := 0; dalsiOdstup := 120;
    pocetUdalosti := 2; druhUdalosti := druh; RandSeed := 12345678
  end;

begin
  Assign(Output,'RESULT.TXT'); Rewrite(Output); pocetZkousek := 0;
  Obnov;
  ProvedPrikaz('JDI NA SEVER'); Musi(kdeJsem.y = 2,1);
  ProvedPrikaz('jdi na jih'); Musi(kdeJsem.y = 3,2);
  ProvedPrikaz('jdi na vychod'); Musi(kdeJsem.x = 3,3);
  ProvedPrikaz('jdi na zapad'); Musi(kdeJsem.x = 2,4);
  kdeJsem.y := 1; Prohledej;
  ProvedPrikaz('jdi na sever'); Musi(kdeJsem.y = 1,5);
  ProvedPrikaz('jdi na vychod'); Musi(kdeJsem.x = 2,6);
  kdeJsem.y := 5; Prohledej;
  ProvedPrikaz('jdi na jih'); Musi(kdeJsem.y = 5,7);
  kdeJsem.x := 1; kdeJsem.y := 3; Prohledej;
  ProvedPrikaz('jdi na zapad'); Musi(kdeJsem.x = 1,8);
  kdeJsem.x := 4; Prohledej;
  ProvedPrikaz('jdi na vychod'); Musi(kdeJsem.x = 4,9);
  p := kdeJsem; ProvedPrikaz('nesmysl'); Musi(StejnaPoloha(p,kdeJsem),10);
  ProvedPrikaz('jdi nikam'); Musi(StejnaPoloha(p,kdeJsem),11);

  Obnov; predmety[3] := kdeJsem; predmety[4] := kdeJsem;
  predmety[5] := kdeJsem; Prohledej;
  ProvedPrikaz('seber panenku');
  Musi((pocetRuk = 1) and (ruce[1] = 3) and (predmety[3].x = 0),12);
  ProvedPrikaz('seber Pekotovu hlavu');
  Musi((pocetRuk = 2) and (ruce[2] = 4),13);
  ProvedPrikaz('seber boticky'); Musi((pocetRuk = 2) and (predmety[5].x <> 0),14);
  ProvedPrikaz('poloz panenku');
  Musi((pocetRuk = 1) and (ruce[1] = 4) and StejnaPoloha(predmety[3],kdeJsem),15);
  ProvedPrikaz('poloz Pekotovu hlavu'); Musi(pocetRuk = 0,16);
  ProvedPrikaz('poloz boticky'); Musi(pocetRuk = 0,17);
  postavy[2] := kdeJsem; Prohledej;
  ProvedPrikaz('seber panenku'); Musi(pocetRuk = 0,18);

  Obnov; postavy[2] := kdeJsem; predmety[4] := kdeJsem;
  pocetRuk := 2; ruce[1] := 3; ruce[2] := 18; Prohledej;
  ProvedPrikaz('odevzdej cestovni plast'); Musi(pocetRuk = 2,19);
  ProvedPrikaz('odevzdej panenku');
  Musi((pocetRuk = 2) and (ruce[1] = 18) and (ruce[2] = 4) and
       (predmety[4].x = 0) and StejnaPoloha(predmety[3],kdeJsem),20);
  Obnov; postavy[0] := kdeJsem; predmety[7] := kdeJsem;
  pocetRuk := 2; ruce[1] := 0; ruce[2] := 1; Prohledej;
  ProvedPrikaz('odevzdej zvonecek');
  Musi((pocetRuk = 1) and (ruce[1] = 1) and (zde.pocetPredmetu = 2),21);
  ProvedPrikaz('odevzdej pohadkovou knihu');
  Musi((pocetRuk = 1) and (ruce[1] = 7) and (predmety[7].x = 0),22);

  Obnov; postavy[6] := kdeJsem; predmety[10] := kdeJsem;
  pocetRuk := 1; ruce[1] := 7; Prohledej;
  ProvedPrikaz('odevzdej prsten'); Musi((postavy[6].x <> 0) and (ruce[1] = 7),23);
  ProvedPrikaz('promen Rumburaka v klic');
  Musi((postavy[6].x = 0) and (pocetRuk = 1) and (ruce[1] = 10),24);
  Obnov; postavy[9] := kdeJsem; pocetRuk := 1; ruce[1] := 10; Prohledej;
  ProvedPrikaz('odevzdej klic'); Musi(not konec,25);
  ProvedPrikaz('vysvobod Arabelu'); Musi(konec and (pocetRuk = 0),26);

  for a := 0 to 3 do
  begin
    Obnov; zvlastni[shortint(a)] := kdeJsem; predmety[3] := kdeJsem; Prohledej;
    ProvedPrikaz('seber panenku'); Musi(pocetRuk = 0,30+10*a);
    case a of
      0 : ProvedPrikaz('vylez na zebrik'); 1 : ProvedPrikaz('vlez do studny');
      2 : ProvedPrikaz('vlez do pece'); 3 : ProvedPrikaz('vlez do komina')
    end;
    Musi(uvnitr = 1,31+10*a);
    p := kdeJsem; ProvedPrikaz('jdi na jih'); Musi(StejnaPoloha(p,kdeJsem),32+10*a);
    ProvedPrikaz('seber panenku'); Musi((pocetRuk = 1) and (ruce[1] = 3),33+10*a);
    case a of
      0 : ProvedPrikaz('slez ze zebriku'); 1 : ProvedPrikaz('vylez ze studny');
      2 : ProvedPrikaz('vylez z pece'); 3 : ProvedPrikaz('slez ze strechy')
    end;
    Musi(uvnitr = 0,34+10*a)
  end;

  Obnov; ProvedPrikaz('pouzij cestovni plast'); Musi(kdeJsem.z = 1,70);
  pocetRuk := 1; ruce[1] := 18;
  postavy[9].x := 4; postavy[9].y := 5; postavy[9].z := 2;
  ProvedPrikaz('pouzij cestovni plast'); Musi(kdeJsem.z = 2,71);
  ProvedPrikaz('pouzij cestovni plast'); Musi(kdeJsem.z = 1,72);
  zvlastni[0] := kdeJsem; uvnitr := 1; Prohledej;
  ProvedPrikaz('pouzij cestovni plast'); Musi(kdeJsem.z = 1,73);

  Obnov; ProvedPrikaz('kde je carodej Rumburak'); Musi(cil = -1,74);
  pocetRuk := 1; ruce[1] := 17;
  postavy[6].x := 4; postavy[6].y := 5; postavy[6].z := 1;
  p := kdeJsem; ProvedPrikaz('kde je carodej Rumburak');
  Musi((cil = 6) and not dotazNaPredmet and StejnaPoloha(p,kdeJsem),75);
  predmety[7].x := 1; predmety[7].y := 1; predmety[7].z := 1;
  ProvedPrikaz('kde najdu prsten'); Musi((cil = 7) and dotazNaPredmet,76);
  ProvedPrikaz('kde najdu nic'); Musi((cil = 7) and dotazNaPredmet,77);
  predmety[7] := kdeJsem; Prohledej;
  ProvedPrikaz('kde najdu prsten'); Musi(StejnaPoloha(p,kdeJsem),78);
  predmety[7].z := 2;
  ProvedPrikaz('kde najdu prsten'); Musi(kdeJsem.z = 1,79);

  Obnov; NastavUdalost(0); pocetUdalosti := 0; chechota := true;
  Musi(Udalost and not chechotaZije and not chechota,80);
  ted := -86400;
  Musi(Udalost and (jmenaPostav[11] = 'pani Blekotova') and chechota,81);
  Obnov; NastavUdalost(0); pocetRuk := 2; ruce[1] := 17; ruce[2] := 18;
  Musi(Udalost and (pocetRuk = 1) and (ruce[1] = 17) and
       (predmety[18].x <> 0) and (druhUdalosti = 1),82);
  Obnov; NastavUdalost(1); p := kdeJsem; uvnitr := 1;
  Musi(Udalost and not StejnaPoloha(p,kdeJsem) and (kdeJsem.z = p.z) and
       (uvnitr = 0) and (druhUdalosti = 2),83);
  Obnov;
  for i := 0 to 15 do
  begin
    postavy[shortint(i)].x := ((i shr 1) and 3)+1;
    postavy[shortint(i)].y := (i shr 3)*4+1;
    postavy[shortint(i)].z := (i and 1)+1
  end;
  NastavUdalost(2); semeno := RandSeed;
  a := Random(16); repeat b := Random(16) until a <> b;
  p := postavy[shortint(a)]; q := postavy[shortint(b)];
  predmety[3] := p; predmety[4] := q; Prohledej; r := kdeJsem;
  RandSeed := semeno;
  Musi(Udalost and StejnaPoloha(postavy[shortint(a)],q) and
       StejnaPoloha(postavy[shortint(b)],p) and StejnaPoloha(predmety[3],q) and
       StejnaPoloha(predmety[4],p) and StejnaPoloha(kdeJsem,r) and (druhUdalosti = 0),84);
  Musi((pocetUdalosti = 3) and (odstup = 120) and (dalsiOdstup = 180),85);
  ted := Cas; odstup := 300; Musi(not Udalost,86);
  WriteLn('PASS actions ',pocetZkousek); Close(Output)
end;
