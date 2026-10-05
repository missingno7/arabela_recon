# Native ARABELA source port

The historical reconstruction is closed at the annotated tag
`historical-exact-oracle-v1` (`08d933b`). On 2026-10-05 a fresh
`scripts/build.ps1 -Probes -Tests -RoundTrip -Verify` passed all seven DOS
scenarios, the 37,200-byte load image and 580 ordered linear relocations,
both packing checks, and the raw packed executable comparison.

All historical files remain unchanged. Development takes place on
`portable-sdl3`, inside this directory. The port is not a matching build.

## Actual platform dependencies

The game uses Crt for input, output geometry, delays and PC-speaker tones;
Dos for date/time and executable-relative score paths; and Eleps for the
VGA intro and ending melody. There are no gameplay BIOS interrupts, ports,
VGA accesses, custom object systems or custom assembly to migrate.

`game/arabela_hra.pas` carries the recovered globals, arrays, short strings,
records and procedural game routines forward. `Rozmisteni`,
`ProhledejMistnost`, `PopisMistnosti`, `MoznePrikazy`, `Udalost` and
`ProvedPrikaz` retain their recovered structure. The production port has
one implementation of the game rules.

The DOS key-editing loop becomes `OdesliPrikaz` and `Tik`. `Zkratka` keeps
the shortcut conditions in the game unit. `MoznePrikazy` supplies the
action list through the same `VypisPrikaz` calls that print command help.
The frontend does not decide which game actions are legal.

`platform/zaklad.pas` provides text output callbacks, an injectable elapsed
clock, date access and TP6-compatible seeded integer random numbers.
The runtime is single-threaded and never waits for terminal input.
`NovaHra`, command submission, ticking and the explicit game phase also
leave a small boundary for later suspend/resume and save-state work.
The globals are still the complete recoverable game state; save games
and Android packaging are later work.

## Intentional differences

* No VGA intro, typewriter delays or PC-speaker sound in this milestone.
* Text wrapping belongs to the frontend; there is no fixed 80x25 screen.
* Elapsed monotonic seconds replace TP6's overflowing 16-bit wall-clock
  expression and midnight adjustment. The event condition and intervals
  remain the original ones. A injected clock supports deterministic tests.
* Random placement and events use the original TP6 LCG and high-word
  modulo range reduction, rather than Free Pascal's different RNG.
* Name entry and exit confirmation are nonblocking game phases. Completing
  a game freezes its elapsed score before asking for a name.
* Scores retain the packed 342-byte layout and ordering. The storage path
  is supplied by the platform, rather than inferred from the executable.
  The native runtime starts unused storage at zero; preserving leaked DOS
  memory in unused records is not a port requirement. Names are UTF-8,
  limited to the original 20-byte field without splitting a character.
  Original game messages and commands are ASCII, as in the recovered game.

## Current validation

`portable/build.ps1 -Tests` builds and runs the existing
`probes/PRIKAZY.INC` against the native production game unit. The same 63
assertions pass against both runtimes; the historical probe is included
directly, not maintained as a competing portable fixture.

Downloaded compilers, SDL libraries and all generated artifacts stay in
ignored `tools/portable` and `build/portable` directories.
