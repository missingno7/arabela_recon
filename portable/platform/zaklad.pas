unit Zaklad;
{$mode objfpc}{$H+}
interface
uses SysUtils;
type
  zapisTextu = procedure(const s : UTF8String);
  zdrojCasu = function : QWord;
var
  Vystup : zapisTextu;
  Hodiny : zdrojCasu;
  Potichu : boolean;
  RandSeed : LongInt;
  SouborSkore : UTF8String;
procedure PripojVystup;
function WhereX : integer;
function WhereY : integer;
function CasSekundy : LongInt;
function Random(mez : word) : word;
procedure Randomize;
procedure Sound(hz : word);
procedure NoSound;
procedure Delay(ms : word);
procedure GetDate(var rok, mesic, den, denvtydnu : word);
implementation
var sloupec : integer = 1;

function Zapis(var f : TextRec) : integer;
var i : integer; s : UTF8String;
begin
  SetLength(s,f.BufPos);
  if f.BufPos > 0 then Move(f.BufPtr^,s[1],f.BufPos);
  for i := 1 to Length(s) do
    if s[i] = #10 then sloupec := 1
    else if s[i] <> #13 then Inc(sloupec);
  if Assigned(Vystup) and not Potichu then Vystup(s);
  f.BufPos := 0;
  Result := 0
end;

function Zavri(var f : TextRec) : integer;
begin Result := Zapis(f) end;

procedure PripojVystup;
begin
  FillChar(Output,SizeOf(Output),0);
  with TextRec(Output) do
  begin
    Mode := fmOutput;
    BufSize := 1; { Okamzity vystup, vcetne nedokonceneho radku. }
    BufPtr := @Buffer;
    InOutFunc := @Zapis;
    FlushFunc := @Zapis;
    CloseFunc := @Zavri
  end;
  sloupec := 1
end;

function WhereX : integer;
begin Result := sloupec end;
function WhereY : integer;
begin Result := 1 end;

function CasSekundy : LongInt;
begin
  if Assigned(Hodiny) then Result := Hodiny() div 1000
  else Result := GetTickCount64 div 1000
end;

function Random(mez : word) : word;
var semeno : LongWord;
begin
  { TP6 SYSTEM: 32bitove preteceni a horni slovo modulo mez.
    Oracle file 9220..9233, 926F..92A4 (header 2560 bytes). }
  semeno := LongWord((QWord(LongWord(RandSeed)) * $08088405 + 1) and $FFFFFFFF);
  RandSeed := LongInt(semeno);
  if mez = 0 then Result := 0 else Result := (semeno shr 16) mod mez
end;
procedure Randomize;
begin { Semeno urcuje volajici NovaHra, take v testech. } end;
procedure Sound(hz : word);
begin end;
procedure NoSound;
begin end;
procedure Delay(ms : word);
begin { Prvni port nema zvuk ani blokujici animaci psani. } end;
procedure GetDate(var rok, mesic, den, denvtydnu : word);
begin
  DecodeDate(Date,rok,mesic,den);
  denvtydnu := DayOfWeek(Date)-1
end;
end.
