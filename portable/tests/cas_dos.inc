{ Same virtual-clock experiment in TP6 and native production game routines. }
procedure OverCas;
var f : file; i,j : word; staloSe : boolean;

  procedure Zaznam;
  begin
    BlockWrite(f,casZkousky,4); BlockWrite(f,staloSe,1);
    BlockWrite(f,ted,4); BlockWrite(f,odstup,4); BlockWrite(f,dalsiOdstup,4);
    BlockWrite(f,pocetUdalosti,2); BlockWrite(f,druhUdalosti,1);
    BlockWrite(f,chechota,1); BlockWrite(f,chechotaZije,1);
    BlockWrite(f,RandSeed,4);
    BlockWrite(f,postavy,SizeOf(postavy)); BlockWrite(f,predmety,SizeOf(predmety));
    BlockWrite(f,kdeJsem,SizeOf(kdeJsem)); BlockWrite(f,zvlastni,SizeOf(zvlastni));
    BlockWrite(f,ruce,SizeOf(ruce)); BlockWrite(f,pocetRuk,1); BlockWrite(f,uvnitr,1)
  end;

begin
  FillChar(postavy,SizeOf(postavy),0); FillChar(predmety,SizeOf(predmety),0);
  FillChar(zvlastni,SizeOf(zvlastni),0); FillChar(ruce,SizeOf(ruce),0);
  kdeJsem.x := 2; kdeJsem.y := 3; kdeJsem.z := 1;
  pocetRuk := 0; uvnitr := 0; RandSeed := 12345678;
  ProhledejMistnost(2,3,1);
  ted := 0; odstup := 300; dalsiOdstup := 120; pocetUdalosti := 0;
  chechota := true; chechotaZije := true; druhUdalosti := 0;
  staloSe := false; casZkousky := 0;
  Assign(f,'TIME.BIN'); Rewrite(f,1);
  Vypis('A B!? '); Zaznam;
  WriteLn('TITLE 123'); Zaznam;
  Vypis('Zadej prikaz: '); Zaznam;
  for j := 1 to 6 do
  begin
    if j = 3 then begin pocetRuk := 2; ruce[1] := 17; ruce[2] := 18 end;
    if j = 4 then uvnitr := 1;
    if j = 5 then
    begin
      for i := 0 to 15 do
      begin
        postavy[i].x := ((i shr 1) and 3)+1;
        postavy[i].y := (i shr 3)*4+1;
        postavy[i].z := (i and 1)+1
      end;
      ProhledejMistnost(kdeJsem.x,kdeJsem.y,kdeJsem.z)
    end;
    casZkousky := (ted+odstup)*1000;
    staloSe := Udalost; Zaznam;
    Inc(casZkousky,999); staloSe := Udalost; Zaznam;
    Inc(casZkousky); staloSe := Udalost; Zaznam;
    Vypis('Zadej prikaz: '); Zaznam
  end;
  Close(f)
end;
