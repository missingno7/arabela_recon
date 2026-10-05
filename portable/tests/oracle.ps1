# Builds a test-instrumented DOS oracle in ignored build output. Historical
# source and reconstruction artifacts are never changed by this script.
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$taskOut = Join-Path $taskRoot 'build\portable\dos-oracle'
New-Item -ItemType Directory -Force $taskOut | Out-Null
$taskSource = [IO.File]::ReadAllText((Join-Path $taskRoot 'src\ARABELA.PAS'))
$taskSource = $taskSource.Replace('  Randomize;','  { Test-only: seed supplied by the probe. }')
# Accelerate the route, then instrument waits/clock for the shared timing
# experiment. Event/placement/command bodies remain the recovered ones.
$taskSource = $taskSource.Replace('procedure Zahraj;',"var casZkousky : LongInt; meriSeCas : boolean;`r`nprocedure Delay(ms : word);`r`nbegin if meriSeCas then Inc(casZkousky,ms) end;`r`n`r`nprocedure Zahraj;")
$taskCasStart = $taskSource.IndexOf('function Cas : LongInt;')
$taskCasEnd = $taskSource.IndexOf('function JePrazdne',$taskCasStart)
$taskSource = $taskSource.Substring(0,$taskCasStart)+"function Cas : LongInt;`r`nbegin Cas := casZkousky div 1000 end;`r`n`r`n"+$taskSource.Substring($taskCasEnd)
$taskSource = $taskSource.Replace('{$I CHOVANI.INC}','{$I ORACLE.INC}')
$taskSource = $taskSource.Replace('{$I PRIKAZY.INC}','').Replace('{$I KLAVESY.INC}','')
$taskSource = $taskSource.Replace("  if ParamStr(1) = 'actions' then OverPrikazy",'  Overeni; {')
$taskSource = $taskSource.Replace('  else Overeni;','  }')
[IO.File]::WriteAllText((Join-Path $taskOut 'ARABELA.PAS'),$taskSource,[Text.Encoding]::ASCII)
Copy-Item (Join-Path $PSScriptRoot 'oracle.inc') (Join-Path $taskOut 'ORACLE.INC') -Force
Copy-Item (Join-Path $PSScriptRoot 'stav.inc') (Join-Path $taskOut 'STAV.INC') -Force
Copy-Item (Join-Path $PSScriptRoot 'cas_dos.inc') (Join-Path $taskOut 'CAS_DOS.INC') -Force
# Keep the existing route experiment accelerated; only OverCas advances time.
$taskProbe = [IO.File]::ReadAllText((Join-Path $taskOut 'ORACLE.INC')).Replace('  OverCas','  meriSeCas := true; OverCas')
[IO.File]::WriteAllText((Join-Path $taskOut 'ORACLE.INC'),$taskProbe,[Text.Encoding]::ASCII)
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
$taskDos = Get-FileHash -LiteralPath (Join-Path $taskOut 'TIME.BIN') -Algorithm SHA256
$taskNative = Get-FileHash -LiteralPath (Join-Path $taskRoot 'build\portable\TIME.BIN') -Algorithm SHA256
if ($taskDos.Hash -ne $taskNative.Hash) { throw 'Native delay/event sequence differs from TP6 virtual-clock experiment' }
Write-Host "PASS: original/native text delays, event thresholds, six transitions and time/state vectors: $($taskDos.Hash.ToLower())"
