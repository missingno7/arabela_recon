program CasOracle;
{$mode objfpc}{$H+}
uses Zaklad, Arabela_Hra;
var casZkousky : LongInt;
function HodinyTestu : QWord;
begin Result := casZkousky end;
procedure Pockej(ms : word);
begin Inc(casZkousky,ms) end;
procedure VystupTestu(const s : UTF8String);
begin end;
{$I cas_dos.inc}
begin
  Vystup := @VystupTestu; Hodiny := @HodinyTestu; Cekani := @Pockej; PripojVystup;
  OverCas;
  Vystup := nil; Hodiny := nil; Cekani := nil
end.
