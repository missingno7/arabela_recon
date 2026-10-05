unit Okno;
{$mode objfpc}{$H+}{$codepage utf8}
interface
procedure Spust;
procedure Chyba(const s : string);
implementation
uses Classes, SysUtils, Math, SDL3, Zaklad, Arabela_Hra;
type
  radek = record
    textura : pointer;
    w,h : integer;
    oblast : SDL_FRect
  end;
var
  herniOkno, kreslic, pismo : pointer;
  historie : TStringList;
  radky, tlacitka : array of radek;
  vstup, skladany, cestaPisma : UTF8String;
  sirka,vyska,body : integer;
  meritkoX,meritkoY : Single;
  posun,posunPrikazu,vyskaTextu,zacatekPrikazu,konecTextu : integer;
  prekreslit : boolean = true;
  zavrit,pozastaveno : boolean;
  pocatekPauzy,celkemPauza : QWord;
  barvaTextu : SDL_Color = (r:224; g:226; b:214; a:255);
  barvaPrikazu : SDL_Color = (r:184; g:222; b:154; a:255);

procedure Chyba(const s : string);
var i : integer; log : TStringList;
begin
  for i := 1 to ParamCount-1 do
    if ParamStr(i) = '--smoke' then
    begin
      log := TStringList.Create;
      try
        log.Add(s); log.SaveToFile(IncludeTrailingPathDelimiter(ParamStr(i+1))+'error.txt')
      finally log.Free end;
      Exit
    end;
  SDL_ShowSimpleMessageBox($10,'ARABELA',PAnsiChar(s),nil)
end;

procedure Musi(ano : boolean);
begin if not ano then raise Exception.Create(string(SDL_GetError)) end;

function HodinyHry : QWord;
begin
  if pozastaveno then Result := pocatekPauzy-celkemPauza
  else Result := SDL_GetTicks-celkemPauza
end;

procedure Pauza(ano : boolean);
begin
  if ano = pozastaveno then Exit;
  if ano then pocatekPauzy := SDL_GetTicks
  else Inc(celkemPauza,SDL_GetTicks-pocatekPauzy);
  pozastaveno := ano
end;

procedure VypisText(const s : UTF8String);
var i : integer;
begin
  for i := 1 to Length(s) do
    if s[i] = #10 then historie.Add('')
    else if s[i] <> #13 then historie[historie.Count-1] := historie[historie.Count-1]+s[i];
  while historie.Count > 1000 do historie.Delete(0);
  posun := 0;
  prekreslit := true
end;

procedure Uvolni(var r : radek);
begin
  if r.textura <> nil then SDL_DestroyTexture(r.textura);
  FillChar(r,SizeOf(r),0)
end;

function Textura(const s : UTF8String; maxsir : integer; barva : SDL_Color) : radek;
var plocha : PSDL_Surface;
begin
  FillChar(Result,SizeOf(Result),0);
  Result.h := body+6;
  if s = '' then Exit;
  plocha := TTF_RenderText_Blended_Wrapped(pismo,PAnsiChar(s),Length(s),barva,Max(1,Round(maxsir*meritkoX)));
  if plocha = nil then Musi(false);
  Result.w := Ceil(plocha^.w/meritkoX);
  Result.h := Ceil(plocha^.h/meritkoY);
  Result.textura := SDL_CreateTextureFromSurface(kreslic,plocha);
  SDL_DestroySurface(plocha);
  Musi(Result.textura <> nil)
end;

procedure Obdelnik(x,y,w,h : Single; r,g,b : byte);
var oblast : SDL_FRect;
begin
  oblast.x := x; oblast.y := y; oblast.w := w; oblast.h := h;
  SDL_SetRenderDrawColor(kreslic,r,g,b,255);
  SDL_RenderFillRect(kreslic,@oblast)
end;

procedure Nakresli(var r : radek; x,y : Single);
var oblast : SDL_FRect;
begin
  if r.textura = nil then Exit;
  oblast.x := x; oblast.y := y; oblast.w := r.w; oblast.h := r.h;
  Musi(SDL_RenderTexture(kreslic,r.textura,nil,@oblast))
end;

procedure Popisek(const s : UTF8String; x,y : integer; barva : SDL_Color);
var r : radek;
begin
  r := Textura(s,sirka-32,barva);
  Nakresli(r,x,y);
  Uvolni(r)
end;

procedure Prelom;
var i,x,y,h,nejvyssi,pw,ph : integer;
begin
  for i := 0 to High(radky) do Uvolni(radky[i]);
  SetLength(radky,historie.Count);
  vyskaTextu := 0;
  for i := 0 to historie.Count-1 do
  begin
    radky[i] := Textura(historie[i],sirka-36,barvaTextu);
    Inc(vyskaTextu,radky[i].h+3)
  end;
  for i := 0 to High(tlacitka) do Uvolni(tlacitka[i]);
  SetLength(tlacitka,prikazy.Count);
  x := 16; y := 0; nejvyssi := 0;
  for i := 0 to prikazy.Count-1 do
  begin
    tlacitka[i] := Textura(prikazy[i],sirka-64,barvaPrikazu);
    pw := Min(sirka-32,tlacitka[i].w+24);
    ph := tlacitka[i].h+14;
    if (x+pw > sirka-16) and (x > 16) then
    begin x := 16; Inc(y,nejvyssi+6); nejvyssi := 0 end;
    tlacitka[i].oblast.x := x;
    tlacitka[i].oblast.y := y;
    tlacitka[i].oblast.w := pw;
    tlacitka[i].oblast.h := ph;
    Inc(x,pw+8);
    nejvyssi := Max(nejvyssi,ph)
  end;
  h := Min(y+nejvyssi,Max(0,vyska div 3));
  zacatekPrikazu := vyska-(body+72)-h;
  konecTextu := zacatekPrikazu-12;
  posun := EnsureRange(posun,0,Max(0,vyskaTextu-(konecTextu-64)));
  posunPrikazu := EnsureRange(posunPrikazu,0,Max(0,y+nejvyssi-h));
  prekreslit := false
end;

procedure VelikostPisma(nova : integer); forward;

procedure Nakresli;
var i,y,w,h,pw,ph : integer; clip,vstupOblast : SDL_Rect; oblast : SDL_FRect; prompt,edit : UTF8String;
begin
  Musi(SDL_GetWindowSize(herniOkno,w,h));
  if (w <> sirka) or (h <> vyska) then
  begin sirka := w; vyska := h; prekreslit := true end;
  Musi(SDL_GetRenderOutputSize(kreslic,pw,ph));
  if (Abs(meritkoX-pw/Max(1,w)) > 0.01) or (Abs(meritkoY-ph/Max(1,h)) > 0.01) then
  begin
    meritkoX := pw/Max(1,w); meritkoY := ph/Max(1,h);
    VelikostPisma(body)
  end;
  Musi(SDL_SetRenderScale(kreslic,meritkoX,meritkoY));
  if prekreslit then Prelom;
  SDL_SetRenderDrawColor(kreslic,18,23,20,255);
  SDL_RenderClear(kreslic);
  Obdelnik(0,0,sirka,50,31,43,31);
  if sirka >= 650 then Popisek('VYSVOBOD PRINCEZNU ARABELU · ELEPS 1991',16,12,barvaPrikazu)
  else Popisek('ARABELA · ELEPS 1991',16,12,barvaPrikazu);
  clip.x := 16; clip.y := 62; clip.w := sirka-32; clip.h := Max(0,konecTextu-62);
  SDL_SetRenderClipRect(kreslic,@clip);
  if vyskaTextu <= konecTextu-62 then y := 62+posun
  else y := konecTextu-vyskaTextu+posun;
  for i := 0 to High(radky) do
  begin
    if (y+radky[i].h >= 62) and (y < konecTextu) then Nakresli(radky[i],16,y);
    Inc(y,radky[i].h+3)
  end;
  SDL_SetRenderClipRect(kreslic,nil);
  Obdelnik(0,zacatekPrikazu-4,sirka,vyska-zacatekPrikazu,25,33,26);
  clip.y := zacatekPrikazu; clip.h := Max(0,vyska-(body+72)-zacatekPrikazu);
  SDL_SetRenderClipRect(kreslic,@clip);
  for i := 0 to High(tlacitka) do
  begin
    oblast := tlacitka[i].oblast;
    oblast.y := oblast.y+zacatekPrikazu-posunPrikazu;
    Obdelnik(oblast.x,oblast.y,oblast.w,oblast.h,41,58,40);
    Nakresli(tlacitka[i],oblast.x+12,oblast.y+7)
  end;
  SDL_SetRenderClipRect(kreslic,nil);
  case faze of
    Hra : prompt := 'Zadej prikaz: ';
    Jmeno : prompt := 'Tvoje jmeno: ';
    Odchod : prompt := 'Odejit? A / N: ';
    Hotovo : prompt := 'Konec hry. F2 = nova hra'
  end;
  if pozastaveno then prompt := 'Pozastaveno';
  Obdelnik(12,vyska-(body+66),sirka-24,body+38,40,48,38);
  edit := prompt+vstup+skladany+'_';
  while Length(edit) > 1 do
  begin
    TTF_GetStringSize(pismo,PAnsiChar(edit),Length(edit),pw,ph);
    if pw/meritkoX <= sirka-48 then Break;
    i := 2;
    while (i <= Length(edit)) and ((byte(edit[i]) and $C0) = $80) do Inc(i);
    Delete(edit,1,i-1)
  end;
  Popisek(edit,22,vyska-(body+56),barvaTextu);
  if sirka >= 850 then
    Popisek('? prikazy · sipky pohyb · Esc odchod · kolecko historie · Ctrl +/- pismo',16,vyska-24,barvaPrikazu)
  else Popisek('? pomoc · Esc odchod · F2 nova hra',16,vyska-24,barvaPrikazu);
  vstupOblast.x := 16;
  vstupOblast.y := vyska-(body+66);
  vstupOblast.w := sirka-32; vstupOblast.h := body+38;
  SDL_SetTextInputArea(herniOkno,@vstupOblast,0)
end;

procedure Odesli;
begin
  if vstup = '' then Exit;
  OdesliPrikaz(vstup);
  vstup := ''; skladany := '';
  posunPrikazu := 0; prekreslit := true
end;

procedure SmazZnak;
var i : integer;
begin
  i := Length(vstup);
  if i = 0 then Exit;
  while (i > 1) and ((byte(vstup[i]) and $C0) = $80) do Dec(i);
  Delete(vstup,i,Length(vstup)-i+1)
end;

procedure VelikostPisma(nova : integer);
var novePismo : pointer;
begin
  nova := EnsureRange(nova,12,40);
  novePismo := TTF_OpenFont(PAnsiChar(cestaPisma),nova*meritkoY);
  Musi(novePismo <> nil);
  if pismo <> nil then TTF_CloseFont(pismo);
  pismo := novePismo;
  body := nova;
  prekreslit := true
end;

procedure Klavesa(const e : SDL_KeyboardEvent);
var kod : word; s : string;
begin
  if e.repeated then Exit;
  if (e.modifiers and $C0) <> 0 then
  begin
    case e.key of
      Ord('+'),Ord('=') : VelikostPisma(body+2);
      Ord('-') : VelikostPisma(body-2)
    end;
    Exit
  end;
  case e.scancode of
    40,88 : Odesli; { Enter / numericky Enter }
    42 : SmazZnak;
    41 : begin OdesliPrikaz(#27); vstup := ''; prekreslit := true end;
    59 : begin NovaHra(LongInt(SDL_GetTicks)); vstup := ''; prekreslit := true end; { F2 }
    75 : Inc(posun,Max(20,konecTextu-80));
    78 : posun := Max(0,posun-Max(20,konecTextu-80));
    77 : posun := 0;
    79..82,73,76 : if vstup = '' then
      begin
        case e.scancode of
          79 : kod := $4D00; 80 : kod := $4B00;
          81 : kod := $5000; 82 : kod := $4800;
          73 : kod := $5200; 76 : kod := $5300
        end;
        if faze = Hra then
        begin
          s := Zkratka(kod);
          vstup := s;
          if (s <> '') and (s[Length(s)] <> ' ') then Odesli
        end
      end
  end;
  posun := EnsureRange(posun,0,Max(0,vyskaTextu-(konecTextu-64)))
end;

procedure TextVstupu(const s : UTF8String);
var dopln : string;
begin
  if (s = '?') and (vstup = '') and (faze = Hra) then
  begin OdesliPrikaz('?'); prekreslit := true; Exit end;
  if (s = '.') and (faze = Hra) then begin Odesli; Exit end;
  if (vstup = '') and (faze = Hra) and ((s = '*') or (s = '+') or (s = '-')) then
  begin
    dopln := Zkratka(Ord(s[1]));
    vstup := dopln; Odesli; Exit
  end;
  if faze <> Hotovo then
    if Length(vstup+s) <= 120 then vstup := vstup+s;
  if (faze = Odchod) and ((UpperCase(vstup) = 'A') or (UpperCase(vstup) = 'N')) then Odesli
end;

procedure Udalosti;
var e : SDL_Event; i,x,y : integer; oblast : SDL_FRect;
begin
  while SDL_PollEvent(e) do
    case e.typ of
      SDL_EVENT_QUIT,SDL_EVENT_WINDOW_CLOSE_REQUESTED : zavrit := true;
      SDL_EVENT_WINDOW_RESIZED,SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED : prekreslit := true;
      SDL_EVENT_WINDOW_FOCUS_LOST,SDL_EVENT_WILL_ENTER_BACKGROUND : Pauza(true);
      SDL_EVENT_WINDOW_FOCUS_GAINED,SDL_EVENT_DID_ENTER_FOREGROUND : Pauza(false);
      SDL_EVENT_KEY_DOWN : if not pozastaveno then Klavesa(e.key);
      SDL_EVENT_TEXT_INPUT : if not pozastaveno then TextVstupu(UTF8String(e.text.text));
      SDL_EVENT_TEXT_EDITING : if not pozastaveno then skladany := UTF8String(e.edit.text);
      SDL_EVENT_MOUSE_WHEEL :
      begin
        if e.wheel.direction = 1 then e.wheel.y := -e.wheel.y;
        if e.wheel.mouse_y >= zacatekPrikazu then
        begin posunPrikazu := Max(0,posunPrikazu-Round(e.wheel.y)*40); prekreslit := true end
        else posun := EnsureRange(posun+Round(e.wheel.y)*60,0,Max(0,vyskaTextu-(konecTextu-64)))
      end;
      SDL_EVENT_MOUSE_BUTTON_DOWN : if not pozastaveno and (faze = Hra) and (e.button.button = 1) then
      begin
        x := Round(e.button.x); y := Round(e.button.y);
        if (y < zacatekPrikazu) or (y >= vyska-(body+72)) then Continue;
        for i := 0 to High(tlacitka) do
        begin
          oblast := tlacitka[i].oblast;
          oblast.y := oblast.y+zacatekPrikazu-posunPrikazu;
          if (x >= oblast.x) and (x < oblast.x+oblast.w) and
             (y >= oblast.y) and (y < oblast.y+oblast.h) then
          begin
            vstup := prikazy[i];
            if Pos('(osoba)',vstup) > 0 then vstup := 'kde je '
            else if Pos('(vec)',vstup) > 0 then vstup := 'kde najdu '
            else Odesli;
            Break
          end
        end
      end
    end
end;

function Volba(const jmeno : string) : string;
var i : integer;
begin
  Result := '';
  for i := 1 to ParamCount-1 do
    if ParamStr(i) = jmeno then Exit(ParamStr(i+1))
end;

function NajdiPismo : UTF8String;
const cesty : array[0..2] of string = (
  '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf',
  '/usr/share/fonts/dejavu-sans-mono-fonts/DejaVuSansMono.ttf',
  '/usr/share/fonts/TTF/DejaVuSansMono.ttf');
var i : integer;
begin
  Result := Volba('--font');
  if Result = '' then Result := GetEnvironmentVariable('ARABELA_FONT');
  if Result <> '' then Exit;
  Result := string(SDL_GetBasePath)+'font.ttf';
  if FileExists(Result) then Exit;
  {$IFDEF WINDOWS}
  Result := GetEnvironmentVariable('WINDIR')+'\Fonts\consola.ttf';
  if FileExists(Result) then Exit;
  {$ENDIF}
  for i := 0 to High(cesty) do if FileExists(cesty[i]) then Exit(cesty[i]);
  raise Exception.Create('Nenalezeno pismo. Zadej --font /cesta/pismo.ttf nebo ARABELA_FONT.')
end;

{$IFDEF OVERENI_OKNA}
{$I smoke.inc}
{$ENDIF}

procedure Spust;
var cesta : PAnsiChar; i : integer; flags : QWord;
begin
  { SDL/graphics drivers expect the C floating-point environment. }
  SetExceptionMask([exInvalidOp,exDenormalized,exZeroDivide,exOverflow,exUnderflow,exPrecision]);
  Musi(SizeOf(SDL_Event) = 128);
  Musi(SDL_Init(SDL_INIT_VIDEO));
  try
    Musi(TTF_Init);
    try
      flags := SDL_WINDOW_RESIZABLE or SDL_WINDOW_HIGH_PIXEL_DENSITY;
      {$IFDEF OVERENI_OKNA}
      if Volba('--smoke') <> '' then flags := flags or $8; { SDL_WINDOW_HIDDEN }
      {$ENDIF}
      herniOkno := SDL_CreateWindow('ARABELA · ELEPS 1991',1000,740,flags);
      Musi(herniOkno <> nil);
      SDL_SetWindowMinimumSize(herniOkno,360,320);
      kreslic := SDL_CreateRenderer(herniOkno,nil); Musi(kreslic <> nil);
      historie := TStringList.Create; historie.Add('');
      Vystup := @VypisText; Hodiny := @HodinyHry; PripojVystup;
      cestaPisma := NajdiPismo;
      Musi(SDL_GetWindowSize(herniOkno,sirka,vyska));
      meritkoY := 1; meritkoX := 1;
      VelikostPisma(18);
      SouborSkore := Volba('--scores');
      if SouborSkore = '' then
      begin
        cesta := SDL_GetPrefPath('Arabela Recon','Arabela'); Musi(cesta <> nil);
        SouborSkore := UTF8String(cesta)+'ARABELA.SCO'; SDL_free(cesta)
      end;
      SDL_StartTextInput(herniOkno);
      NovaHra(StrToIntDef(Volba('--seed'),LongInt(SDL_GetTicks)));
      {$IFDEF OVERENI_OKNA}
      if Volba('--smoke') <> '' then
      begin OverOkno; Exit end;
      {$ENDIF}
      repeat
        Udalosti;
        if not pozastaveno and (vstup = '') and (skladany = '') then Tik;
        Nakresli;
        SDL_RenderPresent(kreslic);
        SDL_Delay(16)
      until zavrit;
    finally
      Vystup := nil; Hodiny := nil;
      for i := 0 to High(radky) do Uvolni(radky[i]);
      for i := 0 to High(tlacitka) do Uvolni(tlacitka[i]);
      historie.Free;
      if pismo <> nil then TTF_CloseFont(pismo);
      if kreslic <> nil then SDL_DestroyRenderer(kreslic);
      if herniOkno <> nil then SDL_DestroyWindow(herniOkno);
      TTF_Quit
    end
  finally SDL_Quit end
end;
end.
