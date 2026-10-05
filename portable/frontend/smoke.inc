{ Integration test of the production SDL input/render loop. Test build only. }
procedure OverOkno;
var e : SDL_Event; adresar,s : UTF8String; plocha : PSDL_Surface;
    x,y,i,pocet : integer; log,pruchod : TStringList;

  procedure Over(ano : boolean; const co : string);
  begin
    if not ano then raise Exception.Create('SDL test: '+co);
    log.Add('PASS '+co)
  end;

  procedure Stisk(scancode : integer);
  begin
    FillChar(e,SizeOf(e),0); e.typ := SDL_EVENT_KEY_DOWN;
    e.key.scancode := scancode; e.key.down := true;
    Musi(SDL_PushEvent(e)); Udalosti
  end;

  procedure Napis(const text : UTF8String);
  begin
    s := text;
    FillChar(e,SizeOf(e),0); e.typ := SDL_EVENT_TEXT_INPUT;
    e.text.text := PAnsiChar(s);
    Musi(SDL_PushEvent(e)); Udalosti
  end;

  procedure Snimek(const jmeno : string);
  begin
    Nakresli;
    plocha := SDL_RenderReadPixels(kreslic,nil); Musi(plocha <> nil);
    Musi(SDL_SaveBMP(plocha,PAnsiChar(adresar+jmeno+'.bmp')));
    SDL_DestroySurface(plocha);
    SDL_RenderPresent(kreslic)
  end;

begin
  adresar := IncludeTrailingPathDelimiter(ExpandFileName(Volba('--smoke')));
  ForceDirectories(adresar); log := TStringList.Create;
  try
    Over(SizeOf(SDL_Event) = 128,'event ABI 128 bytes');
    Over(SizeOf(SDL_KeyboardEvent) = 40,'keyboard ABI 40 bytes');
    Over(SizeOf(SDL_TextInputEvent) = 32,'text ABI 32 bytes');
    Snimek('desktop');
    x := kdeJsem.x; y := kdeJsem.y;
    if y > 1 then begin Stisk(82); Over(kdeJsem.y = y-1,'arrow north') end
    else begin Stisk(81); Over(kdeJsem.y = y+1,'arrow south') end;
    Napis('neplatny prikaz'); Stisk(40);
    Over((vstup = '') and (Pos('Neznam prikaz',historie.Text) > 0),'typed command and Enter');
    Napis('?'); Over(vstup = '','help shortcut');
    Napis('Příliš žluťoučký'); Stisk(42);
    Over(vstup = 'Příliš žluťoučk','UTF-8 input and backspace');
    vstup := ''; Snimek('commands');
    Nakresli;
    if Length(tlacitka) > 0 then
    begin
      x := Round(tlacitka[0].oblast.x+5);
      y := Round(tlacitka[0].oblast.y+zacatekPrikazu+5);
      pocet := historie.Count;
      FillChar(e,SizeOf(e),0); e.typ := SDL_EVENT_MOUSE_BUTTON_DOWN;
      e.button.button := 1; e.button.x := x; e.button.y := y;
      Musi(SDL_PushEvent(e)); Udalosti;
      Over(historie.Count > pocet,'click command from MoznePrikazy')
    end;
    Stisk(41); Over(faze = Odchod,'nonblocking Escape');
    Napis('N'); Over(faze = Hra,'cancel exit');
    FillChar(e,SizeOf(e),0); e.typ := SDL_EVENT_MOUSE_WHEEL;
    e.wheel.y := 2; e.wheel.mouse_y := 100;
    Musi(SDL_PushEvent(e)); Udalosti;
    Over(posun > 0,'scroll history'); posun := 0;
    SDL_SetWindowSize(herniOkno,480,640); SDL_Delay(50); Udalosti;
    Snimek('narrow'); Over(sirka = 480,'resize reflow');
    VelikostPisma(24); Snimek('large-font');
    Over(body = 24,'scalable font');
    Pauza(true); x := HodinyHry; SDL_Delay(25);
    Over(HodinyHry = QWord(x),'pause freezes elapsed clock'); Pauza(false);
    pruchod := TStringList.Create;
    try
      pruchod.LoadFromFile(Volba('--walkthrough'));
      NovaHra(12345678); vstup := '';
      for i := 0 to pruchod.Count-1 do
      begin Napis(pruchod[i]); Stisk(40) end;
      Over(konec and (faze = Hotovo),'84-command walkthrough through SDL text/Enter events');
      Over(nejlepsi.pocet > 0,'SDL completion saved high score');
      SDL_SetWindowSize(herniOkno,1000,740); Udalosti;
      VelikostPisma(18); Snimek('victory')
    finally pruchod.Free end;
    historie.SaveToFile(adresar+'transcript.txt');
    log.SaveToFile(adresar+'results.txt')
  finally log.Free end
end;
