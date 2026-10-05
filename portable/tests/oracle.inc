{ Test-only TP6 instrumentation. Does not change any historical source file. }
{$I STAV.INC}
{$I CAS_DOS.INC}

procedure Overeni;
const meze : array[0..9] of word = (0,1,2,3,4,5,16,19,32767,65535);
var f : file; i,j,n : word; prikazy : text; prikaz : string;
begin
  Assign(f,'SEED.BIN'); Rewrite(f,1);
  RandSeed := 12345678;
  for i := 0 to 49 do
  begin
    n := Random(meze[i mod 10]);
    BlockWrite(f,n,2); BlockWrite(f,RandSeed,4)
  end;
  for j := 1 to 10 do
  begin
    RandSeed := 12345678+j-1;
    Rozmisteni;
    BlockWrite(f,postavy,SizeOf(postavy));
    BlockWrite(f,predmety,SizeOf(predmety));
    BlockWrite(f,kdeJsem,SizeOf(kdeJsem));
    BlockWrite(f,zvlastni,SizeOf(zvlastni));
    BlockWrite(f,chechota,SizeOf(chechota));
    BlockWrite(f,chechotaZije,SizeOf(chechotaZije));
    BlockWrite(f,druhUdalosti,SizeOf(druhUdalosti))
  end;
  Close(f);
  RandSeed := 12345678; Rozmisteni;
  { Unused while cil=-1; DOS uninitialized storage depends on probe layout. }
  dotazNaPredmet := false;
  konec := false; VymazPredmet(cil); PopisMistnosti;
  Assign(prikazy,'COMMANDS.TXT'); Reset(prikazy);
  while not EOF(prikazy) and not konec do
  begin ReadLn(prikazy,prikaz); ProvedPrikaz(prikaz) end;
  Close(prikazy);
  if not konec then Halt(1);
  ZapisStav;
  OverCas
end;
