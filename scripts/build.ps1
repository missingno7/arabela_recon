param([switch]$Probes, [switch]$Verify, [switch]$Tests, [switch]$RoundTrip)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskPython = 'C:\Users\Jiri\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
$taskDos = 'C:\tools\nmlgcdos\msdos.exe'
$taskCompiler = 'C:\tools\tp6\TPC.EXE'
Push-Location $taskRoot
try {
  New-Item -ItemType Directory -Force build\first,build\probes | Out-Null
  & $taskPython scripts\check_tools.py
  if ($LASTEXITCODE -ne 0) { throw 'Pinned tool verification failed' }
  & $taskPython scripts\research.py oracle
  if ($LASTEXITCODE -ne 0) { throw 'Oracle verification failed' }
  & $taskPython scripts\check_logo.py
  if ($LASTEXITCODE -ne 0) { throw 'Graphics source validation failed' }
  & tools\nasm\nasm-2.16.03\nasm.exe -f obj src\LOGODATA.ASM -o build\first\LOGODATA.OBJ
  if ($LASTEXITCODE -ne 0) { throw 'Graphics coordinate data assembly failed' }
  & $taskDos -e $taskCompiler src\ELEPS.PAS /Obuild\first /Ebuild\first /GD
  if ($LASTEXITCODE -ne 0) { throw 'TP6 graphics unit compilation failed' }
  & $taskDos -e $taskCompiler src\ARABELA.PAS /Ubuild\first /Ebuild\first /GD
  if ($LASTEXITCODE -ne 0) { throw 'TP6 reconstruction compilation failed' }
  if ($Probes) {
    foreach ($taskSource in (Get-ChildItem probes\*.PAS).FullName) {
      & $taskDos -e $taskCompiler $taskSource /Ebuild\probes /GD
      if ($LASTEXITCODE -ne 0) { throw "TP6 probe failed: $taskSource" }
    }
    & $taskPython scripts\fingerprint.py
    if ($LASTEXITCODE -ne 0) { throw 'Standard-unit fingerprint changed' }
  }
  & $taskPython scripts\map_binary.py
  if ($LASTEXITCODE -ne 0) { throw 'Routine mapping failed' }
  if ($Tests) { & scripts\test.ps1 -Compile }
  if ($RoundTrip) {
    & $taskPython scripts\roundtrip.py
    if ($LASTEXITCODE -ne 0) { throw 'Allocation reference generation failed' }
    & scripts\pack.ps1 -InputExe oracle\TPALLOC.EXE -OutputDirectory build\roundtp
    & $taskPython scripts\research.py diff assets\ARABELA.EXE build\roundtp\ARABELA.EXE --out build\roundtp\comparison.json
    if ($LASTEXITCODE -ne 0) { throw 'Original LZEXE 0.90 round trip failed' }
  }
  if ($Verify) {
    & $taskPython scripts\research.py diff oracle\ARABELA.EXE build\first\ARABELA.EXE --out build\comparison.json
    $taskUnpackedResult=$LASTEXITCODE
    if ($taskUnpackedResult -gt 1) { throw 'Unpacked comparison failed' }
    $taskComparison=Get-Content build\comparison.json -Raw | ConvertFrom-Json
    if (-not $taskComparison.load_module.exact -or -not $taskComparison.relocation_linear_order_exact) {
      throw 'Compiler load image or relocation positions differ'
    }
    & scripts\pack.ps1 -InputExe build\first\ARABELA.EXE -OutputDirectory build\packed
    & $taskPython scripts\research.py diff assets\ARABELA.EXE build\packed\ARABELA.EXE --out build\packed\comparison.json
    $taskPackedResult=$LASTEXITCODE
    if ($taskPackedResult -gt 1) { throw 'Packed comparison failed' }
    if ($taskPackedResult -ne 0) {
      Write-Host 'Packed reconstruction differs; raw diffs saved. Verification returns 1.'
      exit 1
    }
    Write-Host 'PASS: compiler load image, relocation positions, and full packed executable match.'
  }
} finally { Pop-Location }
