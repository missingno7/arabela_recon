program Semena;
{$mode objfpc}{$H+}
uses Zaklad, Arabela_Hra;
const meze : array[0..9] of word = (0,1,2,3,4,5,16,19,32767,65535);
var f : file; i,j,n : word;
begin
  Assign(f,'SEED.BIN'); Rewrite(f,1);
  Zaklad.RandSeed := 12345678;
  for i := 0 to 49 do
  begin
    n := Zaklad.Random(meze[i mod 10]);
    BlockWrite(f,n,2); BlockWrite(f,Zaklad.RandSeed,4)
  end;
  for j := 1 to 10 do
  begin
    Zaklad.RandSeed := 12345678+j-1;
    Rozmisteni;
    BlockWrite(f,postavy,SizeOf(postavy));
    BlockWrite(f,predmety,SizeOf(predmety));
    BlockWrite(f,kdeJsem,SizeOf(kdeJsem));
    BlockWrite(f,zvlastni,SizeOf(zvlastni));
    BlockWrite(f,chechota,SizeOf(chechota));
    BlockWrite(f,chechotaZije,SizeOf(chechotaZije));
    BlockWrite(f,druhUdalosti,SizeOf(druhUdalosti))
  end;
  Close(f)
end.
