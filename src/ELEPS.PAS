unit Eleps;
{$A+}{$S-}{$R-}{$I-}{$B-}{$F-}{$X+}
interface
const
  melodie : array[1..60] of word = (
    622,2, 554,2, 523,4, 415,2, 349,4, 698,2,
    622,8, 622,2, 554,2, 523,4, 415,2, 349,4,
    523,2, 466,8, 523,2, 554,2, 622,4, 523,2,
    415,4, 932,2, 831,8, 784,2, 698,2, 622,2,
    523,2, 415,2, 554,2, 523,2, 466,2, 415,8);
procedure Zacni;
implementation
uses Crt;

{ Nazev jednotky a jmena jsou rekonstrukcni. Segment 053C obsahuje
  grafickou znacku ELEPS a prime ovladani VGA. ASM je dolozen porty
  a prerusenim BIOS; obrazove tabulky obsahuji pouze souradnice. }
type
  rgb = packed record r, g, b : byte end;
  radky = array[0..65520] of byte;
  bod = record x, y : byte end;
  body = array[0..250] of bod;
var
  vga : boolean;
  a, b, c, d, e : word; { Dosud neurcene nepouzite globalni hodnoty. }
  sloupec, radek, nejmensiY, nejvetsiY, dalsiY : word;
  f, g, h : word;
  napis, znacka : ^radky;
  j, k, l : word;
  paleta : array[0..255] of rgb;
  prvniBarva, posledniBarva : word;

{$L LOGODATA.OBJ}
{ Externi symboly jsou adresy obrazovych dat, nikdy se nevolaji. }
procedure BodyZnaku; external;
procedure BodyNapisu; external;
procedure Draha; external;

procedure Cekej(ms : word);
begin
  ms := ms div 15-1;
  asm
    mov ax,40h
    mov es,ax
    mov dx,3DAh
    mov cx,ms
  @zacatek:
    in al,dx
    and al,8
    jz @zacatek
  @konec:
    in al,dx
    and al,8
    jnz @konec
    mov ax,es:[1Ah]
    cmp ax,es:[1Ch]
    jne @hotovo
    loop @zacatek
  @hotovo:
  end
end;

function Klavesa : boolean;
var stisk : boolean;
begin
  stisk := true;
  asm
    mov ax,40h
    mov es,ax
    mov ax,es:[1Ah]
    cmp ax,es:[1Ch]
    jne @hotovo
    mov stisk,0
  @hotovo:
  end;
  Klavesa := stisk
end;

procedure BodVga(x,y : word; barva : byte);
begin Mem[$A000:320*y+x] := barva end;

function BarvaBodu(x,y : word) : byte;
begin BarvaBodu := Mem[$A000:320*y+x] end;

procedure ZapisBarvu(n : word; cervena,zelena,modra : byte);
begin
  if prvniBarva > n then prvniBarva := n;
  if posledniBarva < n then posledniBarva := n;
  with paleta[n] do begin r := cervena; g := zelena; b := modra end
end;

procedure NastavPaletu;
begin
  if prvniBarva <= posledniBarva then
  asm
    mov dx,3DAh
  @zacatek:
    in al,dx
    and al,8
    jz @zacatek
  @konec:
    in al,dx
    and al,8
    jnz @konec
    mov dx,3C8h
    mov ax,prvniBarva
    out dx,al
    inc dx
    lea si,paleta
    add si,prvniBarva
    add si,prvniBarva
    add si,prvniBarva
    mov cx,posledniBarva
    sub cx,prvniBarva
    inc cx
    cld
  @barva:
    lodsb
    out dx,al
    lodsb
    out dx,al
    lodsb
    out dx,al
    loop @barva
  end;
  prvniBarva := $FFFF;
  posledniBarva := 0
end;

function Rezim : byte;
var m : byte;
begin
  asm mov ah,0Fh; int 10h; mov m,al end;
  Rezim := m
end;

procedure BodSachovnice(x,y : word; barva : byte);
begin
  if Odd((x div 4)+(y div 4)) then BodVga(x,y,barva+9)
  else BodVga(x,y,barva)
end;

procedure StinovanyBod(x,y : word; barva,rozdil : byte);
begin
  if Odd((x div 4)+(y div 4)) then BodVga(x,y,barva+rozdil)
  else BodVga(x,y,barva)
end;

procedure Znamenko;
var i,j : word; p : ^body;

  procedure CtyriBody(x,y : word; posun : integer; barva : byte);
  begin
    BodSachovnice(x+159+posun,y+posun,barva);
    BodSachovnice(159-x+posun,y+posun,barva);
    BodSachovnice(x+159+posun,198-y+posun,barva);
    BodSachovnice(159-x+posun,198-y+posun,barva)
  end;

begin
    p := @Draha;
    for i := 0 to 250 do
      with p^[i] do
      begin CtyriBody(x,y,1,8); CtyriBody(x,y,0,8) end;
    for i := 0 to 250 do
      with p^[i] do CtyriBody(x,y,-1,7)
end;

procedure Logo;
var x,y,i,j,k,l,barva : word;

begin
  prvniBarva := $FFFF; posledniBarva := 0;
  FillChar(paleta,768,0);
  znacka := @BodyZnaku;
  if Rezim <> $13 then asm mov ax,13h; int 10h end;
  if Rezim <> $13 then Exit;
  i := 0; sloupec := 0; radek := 0; nejvetsiY := 0; nejmensiY := 199;
  for j := 0 to 40 do ZapisBarvu(j,0,0,0);
  NastavPaletu;
  for i := 0 to 319 do
    for j := 0 to 199 do
      if Odd((i div 4)+(j div 4)) then BodVga(i,j,9);
  for i := 1 to 319 do begin BodVga(i,1,19); BodVga(i,199,19) end;
  for j := 1 to 199 do begin BodVga(1,j,19); BodVga(319,j,19) end;
  for i := 0 to 318 do begin BodVga(i,0,18); BodVga(i,198,18) end;
  for j := 0 to 198 do begin BodVga(0,j,18); BodVga(318,j,18) end;
  if (BarvaBodu(0,0) <> 18) or Klavesa then Exit;
  napis := @BodyNapisu;
  i := 0; sloupec := 0; radek := 0; nejvetsiY := 0; nejmensiY := 199;
  while napis^[i] > 0 do
  begin
    if napis^[i] < radek then Inc(sloupec);
    radek := napis^[i];
    if radek < nejmensiY then nejmensiY := radek;
    if radek > nejvetsiY then nejvetsiY := radek;
    StinovanyBod(sloupec+14,radek+17,((radek+sloupec) and 3)+30,4);
    Inc(i)
  end;
  for j := 0 to 63 do
  begin
    for i := 0 to 8 do ZapisBarvu(i,0,25*j div 63,25*j div 63);
    for i := 0 to 8 do ZapisBarvu(i+9,0,20*j div 63,20*j div 63);
    ZapisBarvu(18,0,j,j);
    ZapisBarvu(19,0,28*j div 63,28*j div 63);
    for i := 0 to 3 do
    begin
      ZapisBarvu(i+30,0,(30+((j div 3+i) and 3)*11)*j div 63,
                      (30+((j div 3+i) and 3)*11)*j div 63);
      ZapisBarvu(i+34,0,(30+((j div 3+i) and 3)*11)*j div 63,
                      (30+((j div 3+i) and 3)*11)*j div 63)
    end;
    NastavPaletu;
    if Klavesa then Exit
  end;
  for j := 0 to 160 do
  begin
    for i := 0 to 3 do
    begin
      ZapisBarvu(i+30,0,30+(((j+64) div 3+i) and 3)*11,30+(((j+64) div 3+i) and 3)*11);
      ZapisBarvu(i+34,0,30+(((j+64) div 3+i) and 3)*11,30+(((j+64) div 3+i) and 3)*11)
    end;
    NastavPaletu;
    if Klavesa then Exit
  end;
  for j := 0 to 63 do
  begin
    for i := 0 to 3 do
    begin
      k := 30+(((j+64+161) div 3+i) and 3)*11;
      barva := (63-j)*k div 63+25*j div 63;
      ZapisBarvu(i+30,0,barva,barva);
      barva := (63-j)*k div 63+20*j div 63;
      ZapisBarvu(i+34,0,barva,barva)
    end;
    NastavPaletu;
    if Klavesa then Exit
  end;
  Cekej(430);
  for i := 0 to 20 do
  begin
    for j := 0 to 8 do
    begin ZapisBarvu(j,0,i+25,i+25); ZapisBarvu(j+9,0,i+20,i+20) end;
    for j := 0 to 3 do
    begin ZapisBarvu(j+30,0,i+25,i+25); ZapisBarvu(j+34,0,i+20,i+20) end;
    NastavPaletu
  end;
  Cekej(620);
  for i := 14 to sloupec+14 do
    for j := nejmensiY+17 to nejvetsiY+17 do
      if Odd((i div 4)+(j div 4)) then BodVga(i,j,9) else BodVga(i,j,0);
  Znamenko;
  i := 0; sloupec := 0;
  while znacka^[i] > 0 do
  begin
    if Klavesa then Exit;
    if znacka^[i] < radek then Inc(sloupec);
    radek := znacka^[i];
    if radek < nejmensiY then nejmensiY := radek;
    if radek > nejvetsiY then nejvetsiY := radek;
    x := sloupec;
    case sloupec+42 of
        0..130 : begin barva := 1; Inc(x,27); y := radek end;
      131..200 : begin barva := 3; Inc(x,17); y := radek end;
      201..250 : begin barva := 5; Inc(x,27); y := radek end
    else begin barva := 7; Dec(x,104); y := radek+62 end
    end;
    if (i = 0) or (znacka^[i-1] > znacka^[i]) or
       (znacka^[i] > znacka^[i+1]) or (sloupec < 20) or (sloupec > 280) then
    begin barva := 13; x := sloupec end
    else
    begin
      BodSachovnice(x+14,y,barva);
      BodSachovnice(x+15,y+1,barva+1);
      BodSachovnice(x+16,y+2,barva+1)
    end;
    Inc(i)
  end;
  dalsiY := nejmensiY+20;
  for i := 0 to 3 do
  begin
    Cekej(160);
    if Klavesa then Exit;
    for j := 0 to 23 do
    begin
      ZapisBarvu(2*i+1,0,18*j div 23+45,18*j div 23+45);
      ZapisBarvu(2*i+10,0,j+40,j+40);
      ZapisBarvu(2*i+2,0,45-17*j div 23,45-17*j div 23);
      ZapisBarvu(2*i+11,0,40-12*j div 23,40-12*j div 23);
      NastavPaletu;
      Cekej(30);
      if Klavesa then Exit
    end
  end;
  Cekej(820);
  if Klavesa then Exit;
  for j := 0 to 63 do
  begin
    for i := 0 to 3 do
    begin
      ZapisBarvu(2*i+1,j,63,63-j);
      ZapisBarvu(2*i+10,j,63,63-j);
      ZapisBarvu(2*i+2,33*j div 63,33,28-28*j div 63);
      ZapisBarvu(2*i+11,33*j div 63,33,28-28*j div 63)
    end;
    ZapisBarvu(18,j,63,63-j);
    ZapisBarvu(19,33*j div 63,33,28-28*j div 63);
    ZapisBarvu(0,18*j div 63,45-45*j div 63,45-45*j div 63);
    ZapisBarvu(9,18*j div 63,40-40*j div 63,40-40*j div 63);
    NastavPaletu
  end;
  Cekej(2800)
end;

procedure Zacni;
begin end;

begin
  vga := true;
  Logo;
  if Rezim = $13 then asm mov ax,3; int 10h end
  else vga := false;
  while Klavesa do ReadKey
end.
