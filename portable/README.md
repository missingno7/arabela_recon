# Native ARABELA source port

The historical reconstruction is closed at the annotated tag
`historical-exact-oracle-v1` (`08d933b`). On 2026-10-05 a fresh
`scripts/build.ps1 -Probes -Tests -RoundTrip -Verify` passed all seven DOS
scenarios, the 37,200-byte load image and 580 ordered linear relocations,
both packing checks, and the raw packed executable comparison.

All historical files remain unchanged. Development takes place on
`portable-sdl3`, inside this directory. The port is not a matching build.

## Build and play

Windows x64, from the repository root:

```powershell
.\portable\setup.ps1
.\portable\build.ps1 -Tests
.\portable\build.ps1 -Run
```

The first command downloads and checks pinned archives, then extracts them
locally. It does not install system-wide, change PATH or modify the registry.
The tested versions are Free Pascal 3.2.2, SDL 3.4.18 and SDL_ttf 3.2.2.
URLs, archive SHA-256 hashes and dependency licenses are in
[dependencies.json](dependencies.json). An existing Windows FPC installation
can be supplied with `build.ps1 -Compiler C:\path\fpc.exe`.

The native executable is `build/portable/arabela.exe`, with SDL3.dll and
SDL3_ttf.dll beside it. No original assets, DOS compiler, emulator, VGA data
or current working directory are needed to play. It starts directly with
the introduction and first room.

On Linux, install Free Pascal, SDL3 and SDL3_ttf development libraries and
a TrueType font, then use `make -C portable` or `make -C portable test`.
The Linux build recipe is provided; this milestone has been executed and
verified on Windows x64. Linux and Android runtime validation is still work
for those platforms.

The font lookup uses `--font /absolute/path/font.ttf`, `ARABELA_FONT`,
`font.ttf` beside the executable, Windows Consolas, then common Linux
DejaVu Sans Mono paths. There is no proprietary font copied into the repo.
Rendering uses [SDL_ttf's UTF-8 text renderer](https://wiki.libsdl.org/SDL3_ttf/TTF_RenderText_Blended_Wrapped).
Text rasterization follows pixel density while layout and input use window
coordinates. Moving to a display with a different pixel density reopens
the font at the corresponding size.

Type the original ASCII commands and press Enter (or `.`). `?` prints
help. Clickable commands come directly from `MoznePrikazy`; crystal-ball
query buttons fill in their prefix for you to complete. Arrow keys move,
Insert picks up, Delete gives/drops, `+` uses the cloak, `-` enters/leaves a
special location and `*` repeats the last ball query. Mouse wheel and
Page Up/Down scroll history; wheel over the action area scrolls actions.
Ctrl +/- changes font size. Escape asks A/N; F2 starts a new game.
Closing the window exits directly. There is no save-game feature yet.

Scores default to [SDL_GetPrefPath](https://wiki.libsdl.org/SDL3/SDL_GetPrefPath)
for `Arabela Recon/Arabela`, with filename `ARABELA.SCO`. `--scores` supplies
an explicit alternative path. An original 342-byte SCO can be read through
that path; subsequent wins update that file, so use a copy for preservation.
Original ASCII player names are compatible; automatic conversion of old
OEM Czech names is not implemented. `--seed 12345678` selects a reproducible
starting world. The game runs without any terminal.

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
clock, date access, score-file I/O and TP6-compatible seeded integer random numbers.
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
  remain the original ones. An injected clock supports deterministic tests.
  As in the DOS input loop, timed events are checked while the command line
  is empty. Losing focus/backgrounding pauses the elapsed clock, avoiding
  offscreen events and excluding time spent suspended from the score.
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
  Writes use a temporary sibling and replace the previous score file only
  after successful writing. Failures are visible in the game history.
  Invalid sizes, counts, name lengths and score ordering are rejected.

## Current validation

`portable/build.ps1 -Tests` builds and runs the existing
`probes/PRIKAZY.INC` against the native production game unit. The same 63
assertions pass against both runtimes; the historical probe is included
directly, not maintained as a competing portable fixture.

Additional tests cover score ordering and ties, the full 11-player table,
malformed/truncated files, write failures, Unicode paths and original SCO
reading without modifying it. A deterministic walkthrough rescues Arabela
and reloads its saved score using 84 real commands, without changing game
state behind the command processor.

The SDL integration build injects SDL events into the production input
loop, checks text/backspace, shortcuts, clicks, scrolling, resize, scaling,
pause and the complete walkthrough, and saves rendered screenshots in
`build/portable/smoke`. The production build excludes the smoke harness.
Tests pass with both the dummy/software backend and the native Windows
renderer (`build.ps1 -Tests -VideoDriver windows`).

`build.ps1 -Tests -Oracle` additionally builds a test-only TP6 probe in
ignored output and compares binary state vectors. It replaces random
seeding and presentation delays only in that generated test file; historical
sources remain unchanged. This option requires the already configured DOS
tools and `build/first/ELEPS.TPU`. Fresh checks confirm:

* 50 RNG values and resulting seeds, plus ten starting worlds: identical
  2,730-byte vector, SHA-256
  `5aa9232c0632a33eac8ac08aed3bf62c257a28a3f7a0baf02226494c690295fa`.
* The complete same command sequence rescues Arabela in the DOS and native
  runtimes and leaves identical character/object positions, player position,
  special locations, hands, query target and game flags. The 249-byte vector
  has SHA-256 `d88b5b60b00a2f49abcc6f21ba9b1baaf4d032b73018e9d2f0831958bb899f6fa`.

## Next platform work

The SDL frontend already uses text-input/IME events, an input-area hint,
mouse events compatible with SDL's touch-to-mouse delivery, clickable
actions, resize and foreground/background notifications. It has no
blocking input or writable-executable-directory assumption.

Android ARM64 will still need an SDLActivity/JNI entry point, cross-build
toolchain, bundled font loading and packaging. None is claimed working yet.
For autosave, serialize the core's positions, hands, special-location state,
query flags/target, event counters/intervals, Chechota flags, changed character
name, completion phase and RNG seed. Store relative elapsed times, and save
pending frontend text separately. Room caches and valid actions are derived
and should be rebuilt on restore. This design work does not add a second
state implementation to the playable milestone.

Downloaded compilers, SDL libraries and all generated artifacts stay in
ignored `tools/portable` and `build/portable` directories.
