# ARABELA: matching reconstruction

The target is ELEPS's Czech 1991 game, version 1.06. The recovered Turbo Pascal
6.0 source builds to a **byte-identical packed executable**: 20,837 bytes,
SHA-256 `f27d7e4f56fccb1258e51a45e16bffafb5b0f4f93029040a1b2e20ef770d2ec3`.
Pascal identifiers are provisional Czech ASCII names; they are not claimed to
be the lost originals.

The repository contains source, probes, scripts and documentation. Original
game assets, downloaded tools, Python dependencies and generated `build/` and
`oracle/` files are ignored. Supply the original files in `assets/` and install
the local toolchain before rebuilding; see [tool setup](tools/README.md).

The repository contains source, probes, scripts and documentation. Original
game assets, downloaded tools, Python dependencies and generated `build/` and
`oracle/` files are ignored. Supply the original files in `assets/` and install
the local toolchain before rebuilding; see [tool setup](tools/README.md).

Run from `D:\dos\arabela_recon`, in a terminal with a console:

```powershell
.\scripts\build.ps1 -Probes -Tests -RoundTrip -Verify
```

This checks pinned tools and untouched assets, regenerates the canonical
unpack, compiles the reconstruction and probes, runs behavioral checks under
DOSBox, proves the original LZEXE 0.90 packing round trip, and compares the
compiled and packed reconstruction. Exit 0 confirms verification; any packed
byte difference fails. The 37,200-byte compiler load image and all 580 ordered
relocation positions also match. The UNLZEXE reference's reconstructed MZ
header differs from TP6's actual header; that difference is reported explicitly.

`build/first/ARABELA.EXE` is the playable unpacked build;
`build/packed/ARABELA.EXE` matches the original packed game. Normal play writes
the adjacent `.SCO` file as the original does. Tests use isolated fixtures.
Every code instruction is compiled by TP6. NASM assembles only the recovered
logo coordinates from `src/LOGODATA.ASM` into an OMF data object; it emits no
instructions. The build does not read oracle bytes into its source or outputs,
and does not patch compiler output.

- `assets/`: immutable originals, checked by SHA-256 on each build.
- `oracle/`: reproducible references and evidence, never linked into the game.
- `src/`: ordinary procedural Turbo Pascal source.
- `probes/`: compiler experiments and test-only Pascal entry point.
- `scripts/`: unpacking, mapping, compiling, packing and comparison.
- `build/`: generated executables, maps, test results and raw differences.
- `tools/`: acquisition archives and host analysis dependencies. DOS tools
  are pinned under `C:\tools`.

See [status](docs/STATUS.md), [score ABI](docs/SCO.md), and
[packing experiment](docs/PACKING.md).
