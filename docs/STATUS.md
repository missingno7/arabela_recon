# Reconstruction status

**Packed source build matches the original byte for byte.**
TPC 6.0 compiles the recovered source; LZEXE 0.90 packs its unmodified output
to 20,837 bytes with SHA-256
`f27d7e4f56fccb1258e51a45e16bffafb5b0f4f93029040a1b2e20ef770d2ec3`.
Original assets remain untouched. `build/packed/comparison.json` records zero
differing bytes, zero differing ranges, and full packed-header equality.

## Compiler and unpacked layout

The compiler load image matches **all 37,200 bytes**, including game code and
literals (21,440), the custom unit and coordinate tables (8,608), Dos (224),
Crt (1,568), System (4,080), and initialized data (1,280). Region sizes include
linker alignment where applicable. All 580 relocation positions match in order.
Entry `0000:4D18` and stack `099F:4000` also match.

The compiled file is 39,552 bytes with a 2,352-byte MZ header. Its SHA-256 is
`ed94ebe954d0e46ddf3f4f8297953dfc94312c3b136e8bd8ae588ea3a95a4b12`.
The canonical UNLZEXE reference is 39,760 bytes with a 2,560-byte reconstructed header:
SHA-256 `2b7c22130ba85759821671833c78da985c6f46c5f36b928edcb33efb2ebd2372`.
DOS UNLZEXE 0.8 independently reproduces that reference. Its reconstructed
allocation fields and relocation segment/offset representations differ from
TP6's actual header. These differences are reported, not hidden or patched.
Raw packed identity closes the original-executable comparison. See PACKING.md.

## Source and toolchain

`src/ARABELA.PAS` contains the game; `src/ELEPS.PAS` contains the evidenced
custom VGA logo unit. The original unit name is unknown. Identifiers are
provisional Czech ASCII names. Source remains procedural Turbo Pascal with
globals, fixed arrays, records, short strings, case statements and nested
routines. No objects or modern architecture were introduced.

All 38 observed prologues are accounted for: 24 in the game, including its
main block, and 14 in the custom unit, including its initialization. All 23
game procedures/functions before the main block match raw bytes. The main,
unit, standard runtime, literals and initialized data match through complete
region comparison. `oracle/map.json`, `build/routines.json`,
`build/regions.json`, and `build/constants.json` retain the evidence.

Game directives are `$A-`, `$S-`, `$R-`, `$I-`, `$B-`, `$F-`, `$X+`.
The graphics unit uses `$A+` with a packed RGB record. Its melody constant
starts at DS:0440; placing it in that unit naturally reproduces the alignment
after the game's two name arrays. `$X+` permits the original discarded
ReadKey results. `$V-` is permissive and not independently recovered.
Unused local/global declarations remain provisional: their layout is recovered,
but the lost names and exact unused types cannot be inferred uniquely.

TPC 6.0 and its original TURBO.TPL are pinned from the PCjs installation disk.
Controlled probes reproduce GetDate, GetTime, Sound and NoSound byte for byte;
Delay differs only in the probe's linked data address. In the full build, the
entire Crt unit matches. MS-DOS Player runs TPC; DOSBox 0.74-3 runs LZEXE 0.90.
Tool versions, sources and hashes are in `oracle/toolchain.json`.

The logo tables are 5,013 bytes of **drawing coordinates**, not executable
fragments. Their y lists and 251 x/y pairs are retained as readable data
declarations in `src/LOGODATA.ASM`. NASM 2.16.03 assembles that data-only OMF
object; TP6 generates every instruction. The external Pascal symbols are used
only as addresses of these tables. `scripts/check_logo.py` rejects instructions
in that source and can render it with `--render`; `oracle/logo-data.png` shows
the decoded ELEPS artwork. Source builds never read oracle executable bytes.

## Behavior and preserved quirks

DOS tests use the actual recovered routines with test-only entry points.
Score fixtures check read/save of all 342 bytes, missing-file handling,
name/date insertion, full shifted records and preservation of the unused tail.
The command/event fixture has 63 passing assertions: all movement directions,
blocked paths, two hands, pickup/drop/exchange, Majer's exchange, Rumburak,
Arabela, four special locations, cloak travel, crystal-ball queries and seeded
random events. Keyboard fixtures feed the BIOS buffer from a test-only timer;
these do not modify production source or insert matching code into its build.
Backspace-to-empty plus arrow completion, period-as-enter, exit cancellation
with N, and actual Halt after A all pass.
Results are recorded in `build/tests/results.json` and per-case logs.
All seven DOS scenarios pass. The complete reproducible command
`scripts/build.ps1 -Probes -Tests -RoundTrip -Verify` finishes with exit 0.

Preserved quirks include 16-bit clock arithmetic before widening, clearing only
item x coordinates, the placement routine's `c := a+1`, repeated ball queries
retaining the previous target after an unknown name, and whole-table score
writes without initializing unused records or short-string tails. See SCO.md.
