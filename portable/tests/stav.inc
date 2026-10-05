{ Semantic state vector shared by native and DOS walkthrough probes.
  Derived room caches, inactive entries and runtime clock storage omitted. }
procedure ZapisStav;
var f : file;
begin
  Assign(f,'FINISH.BIN'); Rewrite(f,1);
  BlockWrite(f,postavy,SizeOf(postavy));
  BlockWrite(f,predmety,SizeOf(predmety));
  BlockWrite(f,kdeJsem,SizeOf(kdeJsem));
  BlockWrite(f,zvlastni,SizeOf(zvlastni));
  BlockWrite(f,ruce,SizeOf(ruce));
  BlockWrite(f,pocetRuk,1); BlockWrite(f,uvnitr,1);
  BlockWrite(f,cil,1); BlockWrite(f,dotazNaPredmet,1);
  BlockWrite(f,konec,1); BlockWrite(f,chechota,1); BlockWrite(f,chechotaZije,1);
  Close(f)
end;
