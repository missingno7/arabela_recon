program Arabela;
{$mode objfpc}{$H+}{$codepage utf8}
{$IFDEF UNIX}{$linklib pthread}{$ENDIF}
uses {$IFDEF UNIX}cthreads,{$ENDIF} SysUtils, Okno;
begin
  try
    Spust
  except
    on e : Exception do
    begin
      Chyba(e.Message);
      Halt(1)
    end
  end
end.
