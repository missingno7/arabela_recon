program Zkouska;
uses Dos, Crt;
type
  zaznam = record
    cas: LongInt;
    jmeno: string[20];
    den,mesic,rok: word
  end;
  tabulka = record pocet: byte; hraci: array[1..11] of zaznam end;
var
  s,t: string;
  i: integer;
  h,m,v,setina: word;
  f: file of tabulka;
  nejlepsi: tabulka;
  mnozina: set of byte;
begin
  s := 'ahoj'; t := s + ' svete';
  if s = t then WriteLn(t);
  for i := 1 to 3 do WriteLn(i);
  case i of 1: s := 'jedna'; 2: s := 'dve' end;
  mnozina := [1,3,5];
  if i in mnozina then Inc(i);
  Randomize; i := Random(7);
  GetTime(h,m,v,setina);
  Assign(f,'TEST.SCO');
  {$I-} Reset(f); {$I+}
  if IOResult = 0 then begin Read(f,nejlepsi); Close(f) end;
  TextMode(3); ClrScr; Sound(440); Delay(1); NoSound;
  WriteLn(SizeOf(zaznam),' ',SizeOf(tabulka));
end.
