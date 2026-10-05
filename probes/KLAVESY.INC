{ Pouze zkousky vstupu. Hodiny plni skutecny kruhovy buffer BIOS. }
var
  puvodniHodiny, puvodniKonec : pointer;
  klavesy : array[1..40] of word;
  cekani : array[1..40] of word;
  dalsiKlavesa, pocetKlaves, tiky : word;

procedure HodinyKlavesnice; interrupt;
var hlava, konec, dalsi : word;
begin
  asm pushf; call dword ptr puvodniHodiny end;
  if dalsiKlavesa <= pocetKlaves then
    if tiky > 0 then Dec(tiky)
    else
    begin
      hlava := MemW[$40:$1A]; konec := MemW[$40:$1C];
      dalsi := konec+2;
      if dalsi >= $3E then dalsi := $1E;
      if dalsi <> hlava then
      begin
        MemW[$40:konec] := klavesy[dalsiKlavesa];
        MemW[$40:$1C] := dalsi;
        Inc(dalsiKlavesa);
        if dalsiKlavesa <= pocetKlaves then tiky := cekani[dalsiKlavesa]
      end
    end
end;

procedure VratKlavesnici; far;
begin
  SetIntVec($1C,puvodniHodiny);
  ExitProc := puvodniKonec
end;

procedure OverKlavesnici;
var i : word; s : string;

  procedure Pridej(k,c : word);
  begin Inc(pocetKlaves); klavesy[pocetKlaves] := k; cekani[pocetKlaves] := c end;

  procedure Text(s : string);
  var i : word;
  begin for i := 1 to Length(s) do Pridej(Ord(s[i]),3) end;

begin
  Assign(Output,'RESULT.TXT'); Rewrite(Output);
  { Odlozeni prvniho stisku umozni puvodni vycisteni bufferu. }
  pocetKlaves := 0; dalsiKlavesa := 1; tiky := 18;
  ted := Cas; odstup := 86400;
  VymazPredmet(zde.zvlastnost); VymazPredmet(zde.postava);
  if ParamStr(1) = 'exit' then
  begin
    Pridej($011B,0); Pridej($1E41,100);
    WriteLn('EXIT scenario started')
  end
  else if ParamStr(1) = 'escape' then
  begin
    Pridej($011B,0); Pridej($314E,100);
    Text('jdi na jih.');
    cekani[3] := 36; { Novy prikaz az po potvrzeni Ne a vycisteni bufferu. }
    WriteLn('ESCAPE scenario started')
  end
  else
  begin
    Text('ab'); Pridej($0E08,3); Pridej($0E08,3); Pridej($4800,3);
    WriteLn('KEYS scenario started')
  end;
  GetIntVec($1C,puvodniHodiny);
  puvodniKonec := ExitProc; ExitProc := @VratKlavesnici;
  SetIntVec($1C,@HodinyKlavesnice);
  s := NactiPrikaz;
  VratKlavesnici;
  if ParamStr(1) = 'exit' then begin WriteLn('FAIL exit returned'); Close(Output); Halt(1) end;
  if ParamStr(1) = 'escape' then
  begin
    if s <> 'jdi na jih' then begin WriteLn('FAIL escape ',s); Close(Output); Halt(1) end
  end
  else if s <> 'jdi na Sever' then begin WriteLn('FAIL keys ',s); Close(Output); Halt(1) end;
  WriteLn('PASS ',ParamStr(1)); Close(Output)
end;
