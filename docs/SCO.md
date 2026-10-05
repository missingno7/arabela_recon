# ARABELA.SCO

The supplied file is mutable score data, not a resource required to start the
game. The executable derives its filename from `FSplit(ParamStr(0),...)`, then
assigns the same directory and basename with `.SCO`.

The verified TP6 declaration is a typed file of one 342-byte record:

```pascal
type
  zaznam = record
    cas : LongInt;
    jmeno : string[20];
    den, mesic, rok : word
  end;
  tabulka = record
    pocet : byte;
    hraci : array[1..11] of zaznam
  end;
```

Each score is 31 bytes: time at 0, length-prefixed 21-byte short string at 4,
day at 25, month at 27, year at 29. The binary indexes records with stride 31
and calls `GetDate` on these three words. The initial suggestion `string[26]`
is disproven by those date writes.

The current count is 2. The active entries are MALENKO JAROMIR (5189 seconds,
14 June 1995) and BUFFY (5456 seconds, 18 November 1995).
The final 279 bytes equal packed EXE bytes starting at file offset `4BF2`.
This and whole-record typed `Read`/`Write` establish the unused-memory leak.
Do not synthesize that historical tail or clear it in production source.

`NactiSkore` sets `FileMode := 0`, calls `Reset`, and reads the complete typed
record. On error it assigns only `pocet := 0`. `UlozSkore` calls `Rewrite`,
writes the complete table and closes it. `ZapisSkore` shifts full records,
uses a strict greater-time comparison, reads a 20-character name, records the
date and saves. New entries can retain unrelated bytes after the string length.
`oracle/scores.json` gives raw offsets, parsed fields and loader occurrences.
