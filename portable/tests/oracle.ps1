# Builds a test-instrumented DOS oracle in ignored build output. Historical
# source and reconstruction artifacts are never changed by this script.
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$taskOut = Join-Path $taskRoot 'build\portable\dos-oracle'
New-Item -ItemType Directory -Force $taskOut | Out-Null
$taskSource = [IO.File]::ReadAllText((Join-Path $taskRoot 'src\ARABELA.PAS'))
$taskSource = $taskSource.Replace('  Randomize;','  { Test-only: seed supplied by the probe. }')
# Eliminate only presentation delays so a long command sequence runs quickly.
# No gameplay expression, branch or declaration is changed.
$taskSource = $taskSource.Replace('procedure Zahraj;',"procedure Delay(ms : word);`r`nbegin end;`r`n`r`nprocedure Zahraj;")
$taskSource = $taskSource.Replace('{$I CHOVANI.INC}','{$I ORACLE.INC}')
$taskSource = $taskSource.Replace('{$I PRIKAZY.INC}','').Replace('{$I KLAVESY.INC}','')
$taskSource = $taskSource.Replace("  if ParamStr(1) = 'actions' then OverPrikazy",'  Overeni; {')
$taskSource = $taskSource.Replace('  else Overeni;','  }')
[IO.File]::WriteAllText((Join-Path $taskOut 'ARABELA.PAS'),$taskSource,[Text.Encoding]::ASCII)
Copy-Item (Join-Path $PSScriptRoot 'oracle.inc') (Join-Path $taskOut 'ORACLE.INC') -Force
Copy-Item (Join-Path $PSScriptRoot 'stav.inc') (Join-Path $taskOut 'STAV.INC') -Force
Copy-Item (Join-Path $taskRoot 'build\portable\walkthrough.txt') (Join-Path $taskOut 'COMMANDS.TXT') -Force
Copy-Item (Join-Path $taskRoot 'build\first\ELEPS.TPU') $taskOut -Force
Push-Location $taskOut
try {
  & 'C:\tools\nmlgcdos\msdos.exe' -e 'C:\tools\tp6\TPC.EXE' ARABELA.PAS /DOVERENI
  if ($LASTEXITCODE -ne 0) { throw 'Seeded DOS oracle probe compilation failed' }
  $taskOldVideo = $env:SDL_VIDEODRIVER
  $env:SDL_VIDEODRIVER = 'dummy'
  try {
    $taskProcess = Start-Process -FilePath 'C:\tools\dosbox\DOSBox.exe' -ArgumentList @('-noconsole','-conf',('"'+(Join-Path $taskRoot 'scripts\dosbox.conf')+'"'),'-c',('"mount c '+$taskOut+'"'),'-c','"c:"','-c','"arabela"','-c','"exit"') -WindowStyle Hidden -PassThru
    if (-not $taskProcess.WaitForExit(30000)) { Stop-Process -Id $taskProcess.Id; throw 'Seeded DOS probe timeout' }
  } finally { $env:SDL_VIDEODRIVER = $taskOldVideo }
} finally { Pop-Location }
$taskDos = Get-FileHash -LiteralPath (Join-Path $taskOut 'SEED.BIN') -Algorithm SHA256
$taskNative = Get-FileHash -LiteralPath (Join-Path $taskRoot 'build\portable\SEED.BIN') -Algorithm SHA256
if ($taskDos.Hash -ne $taskNative.Hash) { throw 'Native RNG/placement differs from seeded TP6 oracle' }
Write-Host "PASS: raw seeded DOS/native RNG and 10 initial worlds: $($taskDos.Hash.ToLower())"
$taskDos = Get-FileHash -LiteralPath (Join-Path $taskOut 'FINISH.BIN') -Algorithm SHA256
$taskNative = Get-FileHash -LiteralPath (Join-Path $taskRoot 'build\portable\FINISH.BIN') -Algorithm SHA256
if ($taskDos.Hash -ne $taskNative.Hash) { throw 'Native final walkthrough state differs from TP6 oracle' }
Write-Host "PASS: same complete command sequence reaches identical DOS/native game state: $($taskDos.Hash.ToLower())"
