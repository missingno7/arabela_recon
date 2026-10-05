unit Arabela_Hra;
{$mode objfpc}{$H-}{$J+}{$packrecords 1}{$B-}{$R-}{$Q-}{$I-}
interface
uses Classes, SysUtils, Zaklad;
{ Mechanicky prenesena hra z uzavreneho TP6 oracle. Jmena zustavaji ceska. }
type
  zaznam = packed record
    cas : LongInt;
    jmeno : string[20];
    den, mesic, rok : word
  end;
  tabulka = packed record
    pocet : byte;
    hraci : array[1..11] of zaznam
  end;
  poloha = packed record
    x, y, z : word
  end;

  obsahMistnosti = packed record
    postava : shortint;
    pocetPredmetu : byte;
    seznam : array[1..19] of shortint;
    predmetJeTu : array[0..18] of boolean;
    zvlastnost : shortint;
  end;

const
  jmenaPostav : array[0..15] of string[30] = (
    'pan Majer', 'Honzik Majer', 'Marenka Hermanova',
    'Pekota', 'Mekota', 'Blekota', 'carodej Rumburak',
    'carodej Vigo', 'carodejnice', 'princezna Arabela',
    'princezna Xenie', 'slecna Mullerova', 'kral', 'kralovna',
    'ucitel Adam', 'vodnik');
  jmenaPredmetu : array[0..18] of string[30] = (
    'zvonecek', 'pohadkovou knihu',
    'letajici kufr', 'panenku', 'Pekotovu hlavu', 'boticky',
    'cepici', 'prsten', 'kouzelnou hulku', 'letajici koste',
    'klic', 'hreben', 'kabelku', 'zezlo', 'kvetinu', 'pravitko',
    'hrnecek', 'kouzelnou kouli', 'cestovni plast');

var
  postavy : array[0..15] of poloha;
  predmety : array[0..18] of poloha;
  kdeJsem : poloha;
  pocetRuk : byte;
  ruce : array[1..2] of shortint;
  zvlastni : array[0..3] of poloha;
  uvnitr : byte;
  dotazNaPredmet : boolean;
  cil : shortint;
  pocetUdalosti : word;
  chechota, chechotaZije : boolean;
  druhUdalosti : byte;
  zacatek, ted, dalsiOdstup, odstup, doba : LongInt;
  konec : boolean;
  zde : obsahMistnosti;
  nejlepsi : tabulka;
  priznak9, prvniPrikaz : boolean;


type fazeHry = (Hra, Jmeno, Odchod, Hotovo);
var
  faze : fazeHry;
  prikazy : TStringList;
  jmenoHrace : string[20];
  poradiSkore : word;

procedure NovaHra(semeno : LongInt);
procedure OdesliPrikaz(const prikaz : UTF8String);
procedure Tik;
function Zkratka(klavesa : word) : string;
procedure ObnovPrikazy;
procedure Rozmisteni;
procedure ProhledejMistnost(x,y,z : word);
procedure PopisMistnosti;
procedure MoznePrikazy;
function Udalost : boolean;
procedure ProvedPrikaz(prikaz : string);
function Cas : LongInt;
function MalaPismena(s : string) : string;
function JePrazdne(var predmet : shortint) : boolean;
procedure VymazPredmet(var predmet : shortint);
function StejnaPoloha(var prvni,druha : poloha) : boolean;
procedure NactiSkore;
procedure UlozSkore;
function ZapisSkore(doba : LongInt) : word;
{$IFDEF OVERENI_PORTU}
procedure OverPrikazy;
{$ENDIF}

implementation
procedure NactiSkore;
var i : integer; platne : boolean;
begin
  FillChar(nejlepsi,SizeOf(nejlepsi),0);
  if not CtiSkore(nejlepsi,SizeOf(nejlepsi)) then
    FillChar(nejlepsi,SizeOf(nejlepsi),0);
  platne := nejlepsi.pocet <= 11;
  if platne then
  begin
    for i := 1 to nejlepsi.pocet do
    begin
      platne := platne and (Length(nejlepsi.hraci[i].jmeno) <= 20) and
                           (nejlepsi.hraci[i].cas >= 0);
      if i > 1 then platne := platne and (nejlepsi.hraci[i-1].cas <= nejlepsi.hraci[i].cas)
    end;
    for i := nejlepsi.pocet+1 to 11 do FillChar(nejlepsi.hraci[i],SizeOf(zaznam),0)
  end;
  if not platne then FillChar(nejlepsi,SizeOf(nejlepsi),0)
end;

procedure UlozSkore;
begin
  if not PisSkore(nejlepsi,SizeOf(nejlepsi)) then
    WriteLn('Pozor: tabulku nejlepsich se nepodarilo ulozit.')
end;

function ZapisSkore(doba : LongInt) : word;
var
  denvtydnu, i : word;
begin
  i := nejlepsi.pocet + 1;
  while (i > 1) and (nejlepsi.hraci[i-1].cas > doba) do
  begin
    if i < 12 then nejlepsi.hraci[i] := nejlepsi.hraci[i-1];
    Dec(i)
  end;
  if i < 12 then
  with nejlepsi.hraci[i] do
  begin
    if nejlepsi.pocet < 11 then Inc(nejlepsi.pocet);
    WriteLn('Gratuluji, dostal jste se do seznamu nejlepsich - jste ',i,'.');
    jmeno := jmenoHrace;
    cas := doba;
    GetDate(rok,mesic,den,denvtydnu);
    UlozSkore
  end;
  ZapisSkore := i
end;

function Cas : LongInt;
begin Cas := CasSekundy end;

function JePrazdne(var predmet : shortint) : boolean;
begin
  JePrazdne := predmet = -1
end;

procedure VymazPredmet(var predmet : shortint);
begin
  predmet := -1
end;

function StejnaPoloha(var prvni, druha : poloha) : boolean;
begin
  StejnaPoloha := (prvni.x = druha.x) and (prvni.y = druha.y)
                 and (prvni.z = druha.z)
end;

procedure Vypis(s : string);
begin Write(s) end;

procedure ProhledejMistnost(x, y, z : word);
var
  i, j, k : shortint;
  misto : poloha;
begin
  misto.x := x;
  misto.y := y;
  misto.z := z;
  VymazPredmet(zde.postava);
  for i := 0 to 15 do
    if StejnaPoloha(postavy[i],misto) then zde.postava := i;
  for j := 0 to 18 do zde.predmetJeTu[j] := false;
  zde.pocetPredmetu := 0;
  for j := 0 to 18 do
    if StejnaPoloha(predmety[j],misto) then
    begin
      Inc(zde.pocetPredmetu);
      zde.seznam[zde.pocetPredmetu] := j;
      zde.predmetJeTu[j] := true
    end;
  VymazPredmet(zde.zvlastnost);
  for k := 0 to 3 do
    if StejnaPoloha(zvlastni[k],misto) then zde.zvlastnost := k
end;

procedure Rozmisteni;
var
  i, a, b, c : word;
  misto : poloha;
  volno : boolean;

  procedure Rozdej(pocet : word);
  var j : word;
  begin
    for j := 1 to pocet do
    begin
      a := Random(16);
      repeat
        a := (a + 1) mod 16;
        with postavy[shortint(a)] do ProhledejMistnost(x,y,z)
      until (a <> 9) and (zde.pocetPredmetu = 0);
      predmety[shortint(c)] := postavy[shortint(a)];
      { V EXE je a+1, nikoli c+1. }
      c := a + 1
    end
  end;

  procedure VolneMisto(predmet : shortint);
  var xx, yy, zz : word;
  begin
    with predmety[predmet] do
    begin
      repeat
        xx := Random(4) + 1;
        yy := Random(3) + 2;
        zz := Random(2) + 1;
        ProhledejMistnost(xx,yy,zz)
      until zde.pocetPredmetu = 0;
      x := xx;
      y := yy;
      z := zz
    end
  end;

begin
  for i := 0 to 15 do
  with postavy[shortint(i)] do
  begin
    x := ((i shr 1) and 3) + 1;
    y := (i shr 3) * 4 + 1;
    z := (i and 1) + 1
  end;
  Randomize;
  for i := 1 to 200 do
  begin
    a := Random(16);
    b := Random(16);
    misto := postavy[shortint(a)];
    postavy[shortint(a)] := postavy[shortint(b)];
    postavy[shortint(b)] := misto
  end;
  kdeJsem := postavy[9];
  pocetRuk := 0;
  uvnitr := 0;
  for i := 0 to 18 do predmety[shortint(i)].x := 0;
  predmety[10] := postavy[6];
  predmety[7] := postavy[0];
  predmety[17] := postavy[8];
  repeat VolneMisto(18) until predmety[18].z = postavy[9].z;
  c := 0;
  Rozdej(3);
  VolneMisto(c);
  c := 1;
  Rozdej(3);
  VolneMisto(c);
  c := 9;
  Rozdej(1);
  VolneMisto(c);
  for i := 1 to 2 do
  begin
    repeat
      a := Random(16);
      with postavy[shortint(a)] do ProhledejMistnost(x,y,z)
    until (a <> 9) and (zde.pocetPredmetu = 0);
    repeat b := Random(14) + 2
    until (b-1 <> a) and (predmety[shortint(b)].x = 0);
    predmety[shortint(b)] := postavy[shortint(a)]
  end;
  for a := 0 to 18 do
    if predmety[shortint(a)].x = 0 then VolneMisto(a);
  for a := 0 to 3 do
  with zvlastni[shortint(a)] do
  begin
    repeat
      repeat
        volno := true;
        x := Random(4) + 1;
        y := Random(5) + 1;
        z := Random(2) + 1;
        for b := 1 to a do
          volno := volno and not StejnaPoloha(zvlastni[shortint(b-1)],zvlastni[shortint(a)])
      until volno
    until not StejnaPoloha(zvlastni[shortint(a)],postavy[9])
  end;
  odstup := 300;
  pocetUdalosti := 0;
  dalsiOdstup := 120;
  chechota := boolean(Random(2));
  druhUdalosti := Random(3);
  jmenaPostav[11] := 'slecna Mullerova';
  chechotaZije := true
end;

procedure PopisMistnosti;
var
  i, j, k, l, m : word;
  { Jmena j..m jsou prozatimni: osm bajtu mistnich promennych
    je v ramci EXE vyhrazeno, ale tato procedura je nepouziva. }
begin
  Write('<');
  for i := 1 to 77 do Write('=');
  WriteLn('>');
  if pocetRuk > 0 then
  begin
    Vypis('Neses s sebou v leve ruce ' + jmenaPredmetu[ruce[1]]);
    if pocetRuk > 1 then Vypis(' a v prave ' + jmenaPredmetu[ruce[2]]);
    WriteLn('.')
  end;
  with kdeJsem do ProhledejMistnost(x,y,z);
  if JePrazdne(zde.postava) or ((uvnitr = 0) and not JePrazdne(zde.zvlastnost)) then
  begin
    if uvnitr = 0 then
    begin
      Vypis('Jsi v chodbe.');
      WriteLn
    end
    else
    begin
      case zde.zvlastnost of
        0 : Vypis('Jsi na zebriku.');
        1 : Vypis('Jsi ve studni.');
        2 : Vypis('Jsi v peci.');
        3 : Vypis('Jsi na strese.')
      end;
      WriteLn
    end;
    if (uvnitr <> 0) or JePrazdne(zde.zvlastnost) then
    begin
      if zde.pocetPredmetu > 0 then Vypis('Vidis pred sebou ');
      if zde.pocetPredmetu > 2 then
        for i := 1 to zde.pocetPredmetu-2 do Vypis(jmenaPredmetu[zde.seznam[i]] + ', ');
      if zde.pocetPredmetu > 1 then Vypis(jmenaPredmetu[zde.seznam[zde.pocetPredmetu-1]] + ' a ');
      if zde.pocetPredmetu > 0 then
      begin
        Vypis(jmenaPredmetu[zde.seznam[zde.pocetPredmetu]] + '.');
        WriteLn
      end
    end
  end
  else
  begin
    Vypis('Jsi v mistnosti, kde je ' + jmenaPostav[zde.postava] + '.');
    WriteLn;
    if (zde.pocetPredmetu > 0) or (zde.postava = 9) then
    case zde.postava of
      0 : begin
        if not zde.predmetJeTu[7] or (zde.pocetPredmetu > 1) then
          Vypis(jmenaPostav[zde.postava] + ' drzi v leve ruce ' + jmenaPredmetu[zde.seznam[1]]);
        if not zde.predmetJeTu[7] and (zde.pocetPredmetu > 1) then
          Vypis(' a v prave ' + jmenaPredmetu[zde.seznam[2]]);
        if WhereX > 1 then WriteLn('.');
        if not zde.predmetJeTu[0] or not zde.predmetJeTu[1] then
        begin
          Vypis(jmenaPostav[zde.postava] + ' rika: Prines mi ');
          if not zde.predmetJeTu[0] then Vypis(jmenaPredmetu[0])
          else Vypis(jmenaPredmetu[1]);
          Vypis(', abych mohl pozadat o prsten.');
          WriteLn
        end
      end;
      6 : begin
        Vypis(jmenaPostav[zde.postava] + ' rika: ChaChaCha ! Princeznu Arabelu nikdy neziskas !');
        WriteLn;
        Vypis('Tu vysvobodis jen pomoci klice, ve ktery bys mne musel promenit pomoci prstenu.');
        WriteLn
      end;
      8 : begin
        Vypis(jmenaPostav[zde.postava] + ' drzi v leve ruce ' + jmenaPredmetu[zde.seznam[1]] + '.');
        WriteLn;
        if zde.seznam[1] = 17 then
        begin
          Vypis(jmenaPostav[zde.postava] + ' rika: S pomoci kouzelne koule ' + 'se kdykoli dozvis cestu');
          WriteLn;
          Vypis('k predmetum, na ktere se zeptas. Je velmi uzitecnym pomocnikem.');
          WriteLn;
          Vypis('Dam ti kouzelnou kouli, kdyz mi prineses ' + jmenaPredmetu[9] + '.');
          WriteLn
        end
      end;
      9 : begin
        Vypis(jmenaPostav[zde.postava] + ' vola: Vysvobod mne, Petre !');
        WriteLn;
        Vypis('Jsem zamcena ve vezeni, od nehoz ');
        if postavy[6].x = 0 then Vypis('mas klic !')
        else
        begin
          Vypis('neexistuje zadny klic !');
          WriteLn;
          Vypis('Zaklel mne sem Rumburak. Toho se ptej, jak mne muzes vysvobodit.');
          WriteLn;
          Vypis('Kdyz si nebudes vedet rady, stiskni klavesu "?".')
        end;
        WriteLn
      end
    else
      Vypis(jmenaPostav[zde.postava] + ' drzi v leve ruce ' + jmenaPredmetu[zde.seznam[1]] + '.');
      WriteLn;
      if zde.seznam[1] <> zde.postava+1 then
      begin
        Vypis(jmenaPostav[zde.postava] + ' rika: Dam ti ' + jmenaPredmetu[zde.seznam[1]] +
              ', kdyz mi prineses ' + jmenaPredmetu[shortint(zde.postava+1)] + '.');
        WriteLn
      end
    end
  end;
  if not JePrazdne(zde.zvlastnost) and ((uvnitr = 0) or (zde.zvlastnost = 0)) then
  begin
    Vypis('V mistnosti je ');
    case zde.zvlastnost of
      0 : Vypis('zebrik.');
      1 : Vypis('studna.');
      2 : Vypis('pec.');
      3 : Vypis('komin.')
    end;
    WriteLn
  end;
  Vypis('Muzes ');
  if uvnitr <> 0 then
  begin
    case zde.zvlastnost of
      0 : Vypis('slezt ze zebriku.');
      1 : Vypis('vylezt ze studny.');
      2 : Vypis('vylezt z pece.');
      3 : Vypis('slezt ze strechy.')
    end;
    WriteLn
  end
  else
  begin
    Vypis('jit ');
    case kdeJsem.y of
      1 : Vypis('na Jih');
      2,4 : Vypis('na Sever a na Jih');
      5 : Vypis('na Sever');
      3 : case kdeJsem.x of
        1 : Vypis('na Vychod, na Sever a na Jih');
        4 : Vypis('na Zapad, na Sever a na Jih');
        2,3 : Vypis('na Zapad, na Vychod, na Sever a na Jih')
      end
    end;
    if ((pocetRuk > 0) and (ruce[1] = 18)) or
       ((pocetRuk > 1) and (ruce[2] = 18)) then Vypis(' nebo pouzit cestovni plast');
    if not JePrazdne(zde.zvlastnost) then
      case zde.zvlastnost of
        0 : Vypis(' nebo vylezt na zebrik');
        1 : Vypis(' nebo vlezt do studny');
        2 : Vypis(' nebo vlezt do pece');
        3 : Vypis(' nebo vlezt do komina')
      end;
    WriteLn('.')
  end
end;

procedure VypisPrikaz(s : string);
begin
  if not prvniPrikaz then Vypis(' / ');
  prvniPrikaz := false;
  prikazy.Add(s);
  Vypis(s)
end;

procedure MoznePrikazy;
var i : word;
begin
  prikazy.Clear;
  prvniPrikaz := true;
  Vypis('Mozne prikazy: ');
  if uvnitr = 0 then
  begin
    if kdeJsem.y > 1 then VypisPrikaz('jdi na Sever');
    if kdeJsem.y < 5 then VypisPrikaz('jdi na Jih');
    if kdeJsem.y = 3 then
    begin
      if kdeJsem.x < 4 then VypisPrikaz('jdi na Vychod');
      if kdeJsem.x > 1 then VypisPrikaz('jdi na Zapad')
    end
  end;
  if JePrazdne(zde.postava) and ((uvnitr <> 0) or JePrazdne(zde.zvlastnost)) then
  begin
    if pocetRuk < 2 then
      for i := 1 to zde.pocetPredmetu do VypisPrikaz('seber ' + jmenaPredmetu[zde.seznam[i]]);
    for i := 1 to pocetRuk do VypisPrikaz('poloz ' + jmenaPredmetu[ruce[i]])
  end;
  if not JePrazdne(zde.postava) then
    case zde.postava of
      0 : begin
          for i := 1 to pocetRuk do
            if (ruce[i] = 0) or (ruce[i] = 1) then
              VypisPrikaz('odevzdej ' + jmenaPredmetu[ruce[i]])
          end;
      6 : begin
          for i := 1 to pocetRuk do
            if ruce[i] = 7 then VypisPrikaz('promen Rumburaka v klic')
          end;
      9 : begin
          for i := 1 to pocetRuk do
            if ruce[i] = 10 then VypisPrikaz('vysvobod Arabelu')
          end
    else
      for i := 1 to pocetRuk do
        if ruce[i] = zde.postava+1 then VypisPrikaz('odevzdej ' + jmenaPredmetu[ruce[i]])
    end;
  for i := 1 to pocetRuk do
    if (ruce[i] = 18) and (uvnitr = 0) then VypisPrikaz('pouzij cestovni plast')
    else if ruce[i] = 17 then
    begin
      VypisPrikaz('kde je (osoba)');
      VypisPrikaz('kde najdu (vec)')
    end;
  if not JePrazdne(zde.zvlastnost) then
    if uvnitr <> 0 then
      case zde.zvlastnost of
        0 : VypisPrikaz('slez ze zebriku');
        1 : VypisPrikaz('vylez ze studny');
        2 : VypisPrikaz('vylez z pece');
        3 : VypisPrikaz('slez ze strechy')
      end
    else
      case zde.zvlastnost of
        0 : VypisPrikaz('vylez na zebrik');
        1 : VypisPrikaz('vlez do studny');
        2 : VypisPrikaz('vlez do pece');
        3 : VypisPrikaz('vlez do komina')
      end;
  WriteLn('.')
end;

function Udalost : boolean;
var
  nyni : LongInt;
  x, y, z, i, a, b : word;
  prvniObsah, druhyObsah, puvodniObsah : obsahMistnosti;
  misto, prvniMisto, druheMisto : poloha;
begin
  nyni := Cas;
  Udalost := false;
  if ted + odstup < nyni then
  begin
    WriteLn;
    for x := 1 to 3 do
    begin
      Sound(440); Delay(30);
      Sound(660); Delay(30);
      Sound(880); Delay(30)
    end;
    NoSound;
    Vypis('Poznamka: ');
    if pocetUdalosti < 2 then
    begin
      if chechota then
      begin
        Vypis('Carodej Chechota se prave rozplynul v lesni vuni.');
        chechotaZije := false
      end
      else
      begin
        Vypis('Slecna Mullerova se prave vdala za Blekotu.');
        jmenaPostav[11] := 'pani Blekotova';
        if StejnaPoloha(postavy[11],kdeJsem) and
           (JePrazdne(zde.zvlastnost) or (uvnitr <> 0)) then PopisMistnosti
      end;
      chechota := not chechota
    end
    else
    begin
      if (druhUdalosti = 0) and ((pocetRuk = 0) or
         ((pocetRuk = 1) and (ruce[1] = 17))) then Inc(druhUdalosti);
      case druhUdalosti of
        0 : begin
          repeat a := Random(pocetRuk) + 1 until ruce[a] <> 17;
          puvodniObsah := zde;
          repeat
            x := Random(4) + 1;
            y := Random(5) + 1;
            z := kdeJsem.z;
            ProhledejMistnost(x,y,z);
            misto.x := x; misto.y := y; misto.z := z
          until JePrazdne(zde.postava) and (zde.pocetPredmetu = 0) and
                not StejnaPoloha(misto,kdeJsem);
          predmety[ruce[a]] := misto;
          Vypis('Prehnal se kolem mluvici vlk a odnesl ti ' + jmenaPredmetu[ruce[a]] + '.');
          WriteLn;
          Vypis('Uz nemas ' + jmenaPredmetu[ruce[a]] + '.');
          if a = 1 then ruce[1] := ruce[2];
          Dec(pocetRuk);
          zde := puvodniObsah
        end;
        1 : begin
          repeat
            x := Random(4) + 1;
            y := Random(5) + 1;
            z := kdeJsem.z;
            misto.x := x; misto.y := y; misto.z := z
          until not StejnaPoloha(kdeJsem,misto);
          Vypis('Chytil te do sparu bazilisek a odnesl te, sam ani nevi kam.');
          WriteLn;
          kdeJsem := misto;
          uvnitr := 0;
          PopisMistnosti
        end;
        2 : begin
          puvodniObsah := zde;
          a := Random(16);
          repeat b := Random(16) until b <> a;
          with postavy[shortint(a)] do ProhledejMistnost(x,y,z);
          prvniObsah := zde;
          with postavy[shortint(b)] do ProhledejMistnost(x,y,z);
          druhyObsah := zde;
          zde := puvodniObsah;
          prvniMisto := postavy[shortint(a)];
          druheMisto := postavy[shortint(b)];
          for x := 1 to prvniObsah.pocetPredmetu do
            predmety[prvniObsah.seznam[x]] := druheMisto;
          for x := 1 to druhyObsah.pocetPredmetu do
            predmety[druhyObsah.seznam[x]] := prvniMisto;
          postavy[shortint(a)] := druheMisto;
          postavy[shortint(b)] := prvniMisto;
          Vypis(jmenaPostav[shortint(a)] + ' a ' + jmenaPostav[shortint(b)] +
                ' si spolu prave prohazuji mista.');
          WriteLn;
          if (JePrazdne(zde.zvlastnost) or (uvnitr <> 0)) and
             (StejnaPoloha(kdeJsem,prvniMisto) or StejnaPoloha(kdeJsem,druheMisto)) then
            PopisMistnosti
        end
      end;
      druhUdalosti := (druhUdalosti + 1) mod 3
    end;
    odstup := dalsiOdstup;
    Inc(dalsiOdstup,60);
    Inc(pocetUdalosti);
    ted := nyni;
    Udalost := true
  end
end;

function Zkratka(klavesa : word) : string;
var prikaz : string; i : word;
  procedure DoplnPrikaz(s : string);
  begin
    if prikaz = '' then prikaz := s
  end;
begin
  prikaz := '';
        case klavesa of
          $4800 : if (kdeJsem.y > 1) and (JePrazdne(zde.zvlastnost) or (uvnitr = 0)) then
                    DoplnPrikaz('jdi na Sever');
          $4B00 : if (kdeJsem.y = 3) and (kdeJsem.x > 1) and
                     (JePrazdne(zde.zvlastnost) or (uvnitr = 0)) then DoplnPrikaz('jdi na Zapad');
          $4D00 : if (kdeJsem.y = 3) and (kdeJsem.x < 4) and
                     (JePrazdne(zde.zvlastnost) or (uvnitr = 0)) then DoplnPrikaz('jdi na Vychod');
          $5000 : if (kdeJsem.y < 5) and (JePrazdne(zde.zvlastnost) or (uvnitr = 0)) then
                    DoplnPrikaz('jdi na Jih');
          Ord('*') : if not JePrazdne(cil) and
                       (((pocetRuk > 0) and (ruce[1] = 17)) or
                        ((pocetRuk > 1) and (ruce[2] = 17))) then
                    begin
                      if dotazNaPredmet then DoplnPrikaz('kde najdu ' + jmenaPredmetu[cil])
                      else DoplnPrikaz('kde je ' + jmenaPostav[cil])
                    end;
          Ord('+') : for i := 1 to pocetRuk do
                      if (ruce[i] = 18) and (JePrazdne(zde.zvlastnost) or (uvnitr = 0)) then
                        DoplnPrikaz('pouzij cestovni plast');
          Ord('-') : if not JePrazdne(zde.zvlastnost) then
                    begin
                      if uvnitr <> 0 then
                        case zde.zvlastnost of
                          0 : DoplnPrikaz('slez ze zebriku');
                          1 : DoplnPrikaz('vylez ze studny');
                          2 : DoplnPrikaz('vylez z pece');
                          3 : DoplnPrikaz('slez ze strechy')
                        end
                      else
                        case zde.zvlastnost of
                          0 : DoplnPrikaz('vylez na zebrik');
                          1 : DoplnPrikaz('vlez do studny');
                          2 : DoplnPrikaz('vlez do pece');
                          3 : DoplnPrikaz('vlez do komina')
                        end
                    end;
          $5200 : if (JePrazdne(zde.zvlastnost) or (uvnitr <> 0)) and JePrazdne(zde.postava) and
                     (zde.pocetPredmetu > 0) and (pocetRuk < 2) then
                  begin
                    if zde.pocetPredmetu = 1 then DoplnPrikaz('seber ' + jmenaPredmetu[zde.seznam[1]])
                    else
                    begin
                      prikaz := 'seber ';
                      { predvyplneni vstupu }
                    end
                  end;
          $5300 : if JePrazdne(zde.zvlastnost) or (uvnitr <> 0) then
                  begin
                    if not JePrazdne(zde.postava) then
                    begin
                      for i := 1 to pocetRuk do
                        if ((zde.postava = 0) and (ruce[i] <= 1)) or (zde.postava = ruce[i]-1) then
                        case zde.postava of
                          6 : DoplnPrikaz('promen Rumburaka v klic');
                          9 : DoplnPrikaz('vysvobod Arabelu')
                        else
                          DoplnPrikaz('odevzdej ' + jmenaPredmetu[ruce[i]])
                        end
                    end
                    else
                      case pocetRuk of
                        0 : begin end;
                        1 : DoplnPrikaz('poloz ' + jmenaPredmetu[ruce[1]]);
                        2 : begin prikaz := 'poloz '; { predvyplneni vstupu } end
                      end
                  end
        end;
  Zkratka := prikaz
end;

function MalaPismena(s : string) : string;
var i : word;
begin
  for i := 1 to Length(s) do
    if (s[i] >= 'A') and (s[i] <= 'Z') then Inc(s[i],32);
  MalaPismena := s
end;

procedure ProvedPrikaz(prikaz : string);
var
  s, argument : string;
  prvni : char;
  rozpoznan : boolean;
  i, j, k, l, m : word; { Ctyri dalsi slova nejsou v tele pouzita. }
  kde : poloha;
begin
  rozpoznan := false;
  s := MalaPismena(prikaz);
  prvni := s[1];
  if Copy(s,1,4) = 'jdi ' then
  begin
    argument := Copy(s,5,20);
    if argument = 'na sever' then
    begin
      if (kdeJsem.y > 1) and (JePrazdne(zde.zvlastnost) or (uvnitr = 0)) then
      begin Vypis('Jdu na Sever.'); WriteLn; Dec(kdeJsem.y); PopisMistnosti end
      else begin Vypis('na Sever nevedou dvere.'); WriteLn; MoznePrikazy end;
      Exit
    end;
    if argument = 'na jih' then
    begin
      if (kdeJsem.y < 5) and (JePrazdne(zde.zvlastnost) or (uvnitr = 0)) then
      begin Vypis('Jdu na Jih.'); WriteLn; Inc(kdeJsem.y); PopisMistnosti end
      else begin Vypis('na Jih nevedou dvere.'); WriteLn; MoznePrikazy end;
      Exit
    end;
    if argument = 'na vychod' then
    begin
      if (kdeJsem.y = 3) and (kdeJsem.x < 4) and
         (JePrazdne(zde.zvlastnost) or (uvnitr = 0)) then
      begin Vypis('Jdu na Vychod.'); WriteLn; Inc(kdeJsem.x); PopisMistnosti end
      else begin Vypis('na Vychod nevedou dvere.'); WriteLn; MoznePrikazy end;
      Exit
    end;
    if argument = 'na zapad' then
    begin
      if (kdeJsem.y = 3) and (kdeJsem.x > 1) and
         (JePrazdne(zde.zvlastnost) or (uvnitr = 0)) then
      begin Vypis('Jdu na Zapad.'); WriteLn; Dec(kdeJsem.x); PopisMistnosti end
      else begin Vypis('na Zapad nevedou dvere.'); WriteLn; MoznePrikazy end;
      Exit
    end;
    Vypis('Nejdu. Jak mam jit ' + argument + ' ?'); WriteLn; MoznePrikazy; Exit
  end;
  if Copy(s,1,6) = 'seber ' then
  begin
    argument := Copy(s,7,20);
    if not JePrazdne(zde.zvlastnost) and (uvnitr = 0) then
    begin Vypis('Mistnost je prazdna.'); WriteLn; MoznePrikazy; Exit end;
    if not JePrazdne(zde.postava) then
    begin
      Vypis('Nemohu sebrat, v mistnosti je ' + jmenaPostav[zde.postava] + '.');
      WriteLn; MoznePrikazy; Exit
    end;
    if pocetRuk > 1 then
    begin Vypis('Nemohu sebrat, mas plne obe ruce.'); WriteLn; MoznePrikazy; Exit end;
    for i := 1 to zde.pocetPredmetu do
      if argument = MalaPismena(jmenaPredmetu[zde.seznam[i]]) then
      begin
        Vypis('Beru ' + jmenaPredmetu[zde.seznam[i]] + '.'); WriteLn;
        Inc(pocetRuk); ruce[pocetRuk] := zde.seznam[i];
        predmety[zde.seznam[i]].x := 0;
        PopisMistnosti; Exit
      end;
    Vypis('Nelze brat ' + argument + ', neni zde.'); WriteLn; MoznePrikazy; Exit
  end;
  if Copy(s,1,6) = 'poloz ' then
  begin
    argument := Copy(s,7,20);
    if not JePrazdne(zde.zvlastnost) and (uvnitr = 0) then
    begin
      Vypis('Nelze nic pokladat, v mistnosti je ');
      case zde.zvlastnost of
        0 : Vypis('zebrik.'); 1 : Vypis('studna.');
        2 : Vypis('pec.'); 3 : Vypis('komin.')
      end;
      WriteLn; MoznePrikazy; Exit
    end;
    if not JePrazdne(zde.postava) then
    begin
      Vypis('Nemohu polozit, v mistnosti je ' + jmenaPostav[zde.postava]);
      WriteLn; MoznePrikazy; Exit
    end;
    for i := 1 to pocetRuk do
      if argument = MalaPismena(jmenaPredmetu[ruce[i]]) then
      begin
        Vypis('Pokladam ' + jmenaPredmetu[ruce[i]] + '.'); WriteLn;
        predmety[ruce[i]] := kdeJsem;
        if i = 1 then ruce[1] := ruce[2];
        Dec(pocetRuk); PopisMistnosti; Exit
      end;
    Vypis('Nemas u sebe ' + argument + ', nelze polozit.');
    WriteLn; MoznePrikazy; Exit
  end;
  if (Copy(s,1,9) = 'odevzdej ') or (s = 'promen rumburaka v klic') or
     (s = 'vysvobod arabelu') then
  begin
    if s[1] = 'p' then s := 'odevzdej prsten';
    if s[1] = 'v' then s := 'odevzdej klic';
    if (prvni = 'p') and ((zde.postava <> 6) or
       (not JePrazdne(zde.zvlastnost) and (uvnitr = 0))) then
    begin Vypis('Rumburak neni v teto mistnosti.'); WriteLn; MoznePrikazy; Exit end;
    if (prvni = 'v') and ((zde.postava <> 9) or
       (not JePrazdne(zde.zvlastnost) and (uvnitr = 0))) then
    begin Vypis('Arabela neni v teto mistnosti.'); WriteLn; MoznePrikazy; Exit end;
    argument := Copy(s,10,20);
    if (not JePrazdne(zde.zvlastnost) and (uvnitr = 0)) or JePrazdne(zde.postava) then
    begin Vypis('Neni komu odevzdat ' + argument + '.'); WriteLn; MoznePrikazy; Exit end;
    if not (((pocetRuk > 1) and (argument = MalaPismena(jmenaPredmetu[ruce[2]]))) or
            ((pocetRuk > 0) and (argument = MalaPismena(jmenaPredmetu[ruce[1]])))) then
    begin Vypis('Nemas u sebe ' + argument + ' !'); WriteLn; MoznePrikazy; Exit end;
    if argument = MalaPismena(jmenaPredmetu[ruce[1]]) then i := 1 else i := 2;
    if (zde.postava = 6) and (prvni = 'o') then
    begin Vypis('Rumburakovi nic neodevzdavej.'); WriteLn; MoznePrikazy; Exit end;
    if (zde.postava = 9) and (prvni = 'o') then
    begin Vypis('Arabele nic nemuzes odevzdat.'); WriteLn; MoznePrikazy; Exit end;
    if not (((zde.postava = 0) and (argument = MalaPismena(jmenaPredmetu[0]))) or
            (argument = MalaPismena(jmenaPredmetu[shortint(zde.postava+1)]))) then
    begin
      Vypis(jmenaPostav[zde.postava] + ' nechce prijmout ' + argument + '.');
      WriteLn; MoznePrikazy; Exit
    end;
    if zde.postava = 0 then
    begin
      if zde.pocetPredmetu = 2 then
      begin
        Vypis(jmenaPostav[zde.postava] + ' zvoni zvoneckem a ziskava kouzelny prsten.'); WriteLn;
        Vypis(jmenaPostav[zde.postava] + ' radi: Spechej s prstenem za Rumburakem !'); WriteLn;
        predmety[ruce[i]] := kdeJsem;
        predmety[7].x := 0; ruce[i] := 7;
        PopisMistnosti; Exit
      end;
        Vypis(jmenaPostav[zde.postava] + ' dekuje za ' + jmenaPredmetu[ruce[i]] +
              ' a prosi jeste o ' + jmenaPredmetu[shortint(1-ruce[i])] + '.'); WriteLn;
        predmety[ruce[i]] := kdeJsem;
        if i = 1 then ruce[1] := ruce[2];
        Dec(pocetRuk); PopisMistnosti; Exit
    end;
      predmety[ruce[i]] := kdeJsem;
      if prvni <> 'o' then
        case zde.postava of
          6 : begin
                Vypis('Promenil jsi Rumburaka v klic od Arabeliny cely.'); WriteLn;
                Vypis('Spechej s klicem za Arabelou !'); WriteLn
              end;
          9 : begin Vypis('Diky, Petre !'); WriteLn; konec := true end
        end
      else Vypis(jmenaPostav[zde.postava] + ' dekuje za ' + jmenaPredmetu[ruce[i]]);
      if i = 1 then ruce[1] := ruce[2];
      Dec(pocetRuk);
      if zde.pocetPredmetu > 0 then
      begin
        if prvni = 'o' then Vypis(' a dava ti vymenou ' + jmenaPredmetu[zde.seznam[1]]);
        Inc(pocetRuk); ruce[pocetRuk] := zde.seznam[1];
        predmety[zde.seznam[1]].x := 0
      end;
      if prvni = 'o' then WriteLn('.');
      if prvni = 'p' then postavy[6].x := 0;
      if prvni <> 'v' then PopisMistnosti;
      Exit
  end;
  if s = 'pouzij cestovni plast' then
  begin
    if uvnitr <> 0 then
    begin
      case zde.zvlastnost of
        0 : Vypis('Na zebriku'); 1 : Vypis('Ve studni');
        2 : Vypis('V peci'); 3 : Vypis('Na strese')
      end;
      Vypis(' nemuzes pouzivat cestovni plast.'); WriteLn; MoznePrikazy; Exit
    end;
    if not (((pocetRuk > 0) and (ruce[1] = 18)) or
            ((pocetRuk > 1) and (ruce[2] = 18))) then
    begin Vypis('Bez cestovniho plaste nelze cestovat.'); WriteLn; MoznePrikazy; Exit end;
    kdeJsem.z := 3-kdeJsem.z;
    Vypis('Cestujes pomoci cestovniho plaste ');
    if kdeJsem.z <> postavy[9].z then
    begin
      Vypis('do rise lidi.'); WriteLn;
      Vypis('Jsi v hotelu mesta, kde bydli Majerovi.')
    end
    else
    begin
      Vypis('do pohadkove rise.'); WriteLn;
      if chechotaZije then Vypis('Jsi v hrade carodeje Chechoty.')
      else Vypis('Jsi v carodejnem hrade (momentalne bez majitele).')
    end;
    WriteLn; PopisMistnosti; Exit
  end;
  if Copy(s,1,4) = 'kde ' then
  begin
    if not (((pocetRuk > 0) and (ruce[1] = 17)) or
            ((pocetRuk > 1) and (ruce[2] = 17))) then
    begin Vypis('Bez kouzelne koule se nemuzes na nic ptat.'); WriteLn; MoznePrikazy; Exit end;
    kde.x := 0;
    if Copy(s,5,3) = 'je ' then
    begin
      argument := Copy(s,8,20);
      for i := 0 to 15 do
        if argument = MalaPismena(jmenaPostav[shortint(i)]) then
        begin dotazNaPredmet := false; cil := i; kde := postavy[shortint(i)] end
    end;
    if Copy(s,5,6) = 'najdu ' then
    begin
      argument := Copy(s,11,20);
      for i := 0 to 18 do
        if argument = MalaPismena(jmenaPredmetu[shortint(i)]) then
        begin dotazNaPredmet := true; cil := i; kde := predmety[shortint(i)] end
    end;
    if kde.x = 0 then begin Vypis('Nevim, neznam.'); WriteLn; Exit end;
    if kde.z <> kdeJsem.z then begin Vypis('Musis pouzit cestovni plast.'); WriteLn; Exit end;
    if StejnaPoloha(kde,kdeJsem) then
    begin
      if JePrazdne(zde.zvlastnost) or (uvnitr <> 0) then
      begin Vypis('Tady.'); WriteLn; Exit end;
      case zde.zvlastnost of
        0 : Vypis('Vylez na zebrik.'); 1 : Vypis('Vlez do studny.');
        2 : Vypis('Vlez do pece.'); 3 : Vypis('Vlez do komina.')
      end;
      WriteLn; Exit
    end;
    if not JePrazdne(zde.zvlastnost) and (uvnitr <> 0) then
    begin
      case zde.zvlastnost of
        0 : Vypis('Slez ze zebriku.'); 1 : Vypis('Vylez ze studny.');
        2 : Vypis('Vylez z pece.'); 3 : Vypis('Slez ze strechy.')
      end;
      WriteLn; Exit
    end;
    if kdeJsem.y < 3 then
    begin
      if (kde.x <> kdeJsem.x) or (kde.y > kdeJsem.y) then Vypis('Jdi na Jih.')
      else Vypis('Jdi na Sever.');
      WriteLn; Exit
    end;
    if kdeJsem.y > 3 then
    begin
      if (kde.x <> kdeJsem.x) or (kde.y < kdeJsem.y) then Vypis('Jdi na Sever.')
      else Vypis('Jdi na Jih.');
      WriteLn; Exit
    end;
    if kde.x < kdeJsem.x then begin Vypis('Jdi na Zapad.'); WriteLn; Exit end;
    if kde.x > kdeJsem.x then begin Vypis('Jdi na Vychod.'); WriteLn; Exit end;
    if kde.y < kdeJsem.y then begin Vypis('Jdi na Sever.'); WriteLn; Exit end;
    Vypis('Jdi na Jih.'); WriteLn; Exit
  end;
  if s = 'slez ze zebriku' then
  begin
    if zde.zvlastnost <> 0 then begin Vypis('Z jakeho zebriku ?'); WriteLn; MoznePrikazy; Exit end;
    if uvnitr = 0 then begin Vypis('Vzdyt jsem dole !'); WriteLn; MoznePrikazy; Exit end;
    Vypis('Lezu dolu ze zebriku.'); WriteLn; uvnitr := 0; PopisMistnosti; Exit
  end;
  if s = 'vylez ze studny' then
  begin
    if zde.zvlastnost <> 1 then begin Vypis('Z jake studny ?'); WriteLn; MoznePrikazy; Exit end;
    if uvnitr = 0 then begin Vypis('Vzdyt jsem venku !'); WriteLn; MoznePrikazy; Exit end;
    Vypis('Lezu ven ze studny.'); WriteLn; uvnitr := 0; PopisMistnosti; Exit
  end;
  if s = 'vylez z pece' then
  begin
    if zde.zvlastnost <> 2 then begin Vypis('Z jake pece ?'); WriteLn; MoznePrikazy; Exit end;
    if uvnitr = 0 then begin Vypis('Vzdyt jsem venku !'); WriteLn; MoznePrikazy; Exit end;
    Vypis('Lezu ven z pece.'); WriteLn; uvnitr := 0; PopisMistnosti; Exit
  end;
  if s = 'slez ze strechy' then
  begin
    if zde.zvlastnost <> 3 then begin Vypis('Z jake strechy ?'); WriteLn; MoznePrikazy; Exit end;
    if uvnitr = 0 then begin Vypis('Vzdyt jsem dole !'); WriteLn; MoznePrikazy; Exit end;
    Vypis('Lezu dolu ze strechy.'); WriteLn; uvnitr := 0; PopisMistnosti; Exit
  end;
  if s = 'vylez na zebrik' then
  begin
    if zde.zvlastnost <> 0 then begin Vypis('Na jaky zebrik ?'); WriteLn; MoznePrikazy; Exit end;
    if uvnitr <> 0 then begin Vypis('Vzdyt jsem nahore !'); WriteLn; MoznePrikazy; Exit end;
    Vypis('Lezu na zebrik.'); WriteLn; uvnitr := 1; PopisMistnosti; Exit
  end;
  if s = 'vlez do studny' then
  begin
    if zde.zvlastnost <> 1 then begin Vypis('Do jake studny ?'); WriteLn; MoznePrikazy; Exit end;
    if uvnitr <> 0 then begin Vypis('Vzdyt jsem uvnitr !'); WriteLn; MoznePrikazy; Exit end;
    Vypis('Lezu do studny.'); WriteLn; uvnitr := 1; PopisMistnosti; Exit
  end;
  if s = 'vlez do pece' then
  begin
    if zde.zvlastnost <> 2 then begin Vypis('Do jake pece ?'); WriteLn; MoznePrikazy; Exit end;
    if uvnitr <> 0 then begin Vypis('Vzdyt jsem uvnitr !'); WriteLn; MoznePrikazy; Exit end;
    Vypis('Lezu do pece.'); WriteLn; uvnitr := 1; PopisMistnosti; Exit
  end;
  if s = 'vlez do komina' then
  begin
    if zde.zvlastnost <> 3 then begin Vypis('Do jakeho komina ?'); WriteLn; MoznePrikazy; Exit end;
    if uvnitr <> 0 then begin Vypis('Vzdyt jsem na strese !'); WriteLn; MoznePrikazy; Exit end;
    Vypis('Lezu do komina.'); WriteLn; uvnitr := 1; PopisMistnosti; Exit
  end;
  if not rozpoznan then begin Vypis('Neznam prikaz !'); WriteLn; MoznePrikazy end
end;

procedure Uvod;
var i : word;
begin
  Write('<');
  for i := 1 to 77 do Write('=');
  WriteLn('>');
  WriteLn('< * VYSVOBOD PRINCEZNU ARABELU *                    (C) ELEPS, 1991  ver.1.06 >');
  Write('<');
  for i := 1 to 77 do Write('=');
  WriteLn('>');
  Vypis('Jsi Petr a dostal jsi se do hradu carodeje Chechoty v pohadkove risi. Tvym ukolem je vysvobodit');
  Vypis(' princeznu Arabelu z vezeni, kam ji zavrel zly carodej Rumburak.'); WriteLn;
  Vypis('Pis z klavesnice sve pokyny, ja je budu za Tebe provadet.'); WriteLn;
  Vypis('Preji prijemnou hru !'); WriteLn
end;

procedure DokonciHru;
var i : word; n : LongInt;
begin
  Write('<');
  for i := 1 to 77 do Write('=');
  WriteLn('>');
  WriteLn('Arabela je vysvobozena. Gratulujeme, Petre !');
  Write('Spotreboval jsi ');
  n := doba div 3600;
  if n > 0 then
  begin
    Write(n,' hodin');
    if n = 1 then Write('u') else if n < 5 then Write('y');
    Write(' a ')
  end;
  n := doba mod 3600 div 60;
  Write(n,' minut');
  if n = 1 then Write('u') else if (n < 5) and (n > 1) then Write('y');
  WriteLn('.');
  NactiSkore;
  i := poradiSkore;
  if i < 12 then
  begin
    WriteLn;
    Vypis('Nova tabulka nejlepsich vysledku:'); WriteLn;
    Vypis('================================='); WriteLn;
    for i := 1 to nejlepsi.pocet do
      with nejlepsi.hraci[i] do
      begin
        Write(i:2,'. ');
        Vypis(Copy(jmeno+'                    ',1,20));
        Write(cas div 3600:8,':');
        if cas mod 3600 div 60 < 10 then Write('0');
        Write(cas mod 3600 div 60);
        Write(':');
        if cas mod 60 < 10 then Write('0');
        Write(cas mod 60);
        Write(den:8,'.');
        case mesic of
           1 : Write('ledna');     2 : Write('unora');
           3 : Write('brezna');    4 : Write('dubna');
           5 : Write('kvetna');    6 : Write('cervna');
           7 : Write('cervence');  8 : Write('srpna');
           9 : Write('zari');     10 : Write('rijna');
          11 : Write('listopadu');12 : Write('prosince')
        end;
        WriteLn(' ',rok)
      end
  end;
  WriteLn('Konec programu.');
  faze := Hotovo
end;

procedure ObnovPrikazy;
var ticho : boolean;
begin
  ticho := Potichu;
  Potichu := true;
  if faze = Hra then MoznePrikazy else prikazy.Clear;
  Potichu := ticho
end;

procedure NovaHra(semeno : LongInt);
begin
  Zaklad.RandSeed := semeno;
  zacatek := Cas;
  ted := zacatek;
  jmenaPostav[11] := 'slecna Mullerova';
  Rozmisteni;
  konec := false;
  VymazPredmet(cil);
  faze := Hra;
  Uvod;
  PopisMistnosti;
  ObnovPrikazy
end;

procedure OdesliPrikaz(const prikaz : UTF8String);
var s : string; i : word;
begin
  if faze = Hotovo then Exit;
  if prikaz = #27 then s := #27 else s := Trim(prikaz);
  if s = '' then Exit;
  if s = #27 then WriteLn('> odejdi') else WriteLn('> ',s);
  if faze = Odchod then
  begin
    if UpCase(s[1]) = 'A' then
    begin
      WriteLn('Program VYSVOBOD PRINCEZNU ARABELU se s Vami louci !');
      faze := Hotovo
    end
    else if UpCase(s[1]) = 'N' then faze := Hra;
    ObnovPrikazy;
    Exit
  end;
  if faze = Jmeno then
  begin
    i := 21;
    if Length(s) > 20 then
      while (i > 1) and ((byte(s[i]) and $C0) = $80) do Dec(i);
    jmenoHrace := Copy(s,1,i-1);
    poradiSkore := ZapisSkore(doba);
    DokonciHru;
    Exit
  end;
  if s = '?' then MoznePrikazy
  else if s = #27 then
  begin
    faze := Odchod;
    WriteLn('Prejes si odejit ?  (Stiskni A=Ano nebo N=Ne): ')
  end
  else ProvedPrikaz(Copy(s,1,60));
  if konec then
  begin
    doba := Cas-zacatek;
    if doba < 0 then doba := 0;
    NactiSkore;
    i := nejlepsi.pocet+1;
    while (i > 1) and (nejlepsi.hraci[i-1].cas > doba) do Dec(i);
    poradiSkore := i;
    if i < 12 then
    begin
      WriteLn('Arabela je vysvobozena. Zadejte svoje jmeno pro tabulku nejlepsich:');
      faze := Jmeno
    end
    else DokonciHru
  end;
  ObnovPrikazy
end;

procedure Tik;
begin
  if (faze = Hra) and Udalost then ObnovPrikazy
end;

{$IFDEF OVERENI_PORTU}
{$I ../../probes/PRIKAZY.INC}
{$ENDIF}

initialization
  prikazy := TStringList.Create;
finalization
  prikazy.Free;
end.
