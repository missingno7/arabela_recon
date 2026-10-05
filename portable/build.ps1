param([switch]$Tests, [switch]$Oracle, [switch]$Run, [string]$Compiler, [string]$VideoDriver = 'dummy')
$ErrorActionPreference = 'Stop'
if ($Oracle) { $Tests = $true }
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskOut = Join-Path $taskRoot 'build\portable'
$taskFpc = Join-Path $taskRoot 'tools\portable\fpc\app'
if (-not $Compiler) { $Compiler = Join-Path $taskFpc 'bin\i386-win32\ppcrossx64.exe' }
New-Item -ItemType Directory -Force $taskOut,(Join-Path $taskOut 'units'),(Join-Path $taskOut 'testunits') | Out-Null
$taskOptions = @('-B','-Mobjfpc','-Sh','-O2','-gl',('-Fu'+(Join-Path $PSScriptRoot 'game')),('-Fu'+(Join-Path $PSScriptRoot 'platform')),('-Fu'+(Join-Path $PSScriptRoot 'frontend')),('-FE'+$taskOut))
if ($Compiler -eq (Join-Path $taskFpc 'bin\i386-win32\ppcrossx64.exe')) {
  $taskOptions += @('-n',('-Fu'+(Join-Path $taskFpc 'units\x86_64-win64\rtl')),('-Fu'+(Join-Path $taskFpc 'units\x86_64-win64\rtl-objpas')),('-Fu'+(Join-Path $taskFpc 'units\x86_64-win64\fcl-base')))
}
if ($Tests) {
  & $Compiler @taskOptions ('-FU'+(Join-Path $taskOut 'testunits')) '-dOVERENI_PORTU' (Join-Path $PSScriptRoot 'tests\chovani.pas')
  if ($LASTEXITCODE -ne 0) { throw 'Portable behavioral test compilation failed' }
  Push-Location $taskOut
  try {
    & .\chovani.exe
    if ($LASTEXITCODE -ne 0 -or (Get-Content RESULT.TXT -Raw) -notmatch 'PASS actions 63') { throw 'Portable oracle comparison failed' }
    Write-Host 'PASS: same 63 command/event assertions as the historical DOS oracle.'
  } finally { Pop-Location }
  foreach ($taskTest in @('semena','pruchod','skore','casovani','cas_oracle')) {
    & $Compiler @taskOptions ('-FU'+(Join-Path $taskOut 'testunits')) (Join-Path $PSScriptRoot ('tests\'+$taskTest+'.pas'))
    if ($LASTEXITCODE -ne 0) { throw "Portable $taskTest compilation failed" }
    Push-Location $taskOut
    try {
      if ($taskTest -eq 'skore' -and (Test-Path (Join-Path $taskRoot 'assets\ARABELA.SCO'))) {
        & (Join-Path $taskOut ($taskTest+'.exe')) (Join-Path $taskRoot 'assets\ARABELA.SCO')
      } else { & (Join-Path $taskOut ($taskTest+'.exe')) }
      if ($LASTEXITCODE -ne 0) { throw "Portable $taskTest failed" }
    } finally { Pop-Location }
  }
  Get-Content (Join-Path $taskOut 'walkthrough-results.txt')
  Get-Content (Join-Path $taskOut 'score-results.txt')
  Get-Content (Join-Path $taskOut 'timing-results.txt')
  if ((Get-FileHash (Join-Path $taskOut 'SEED.BIN') -Algorithm SHA256).Hash.ToLower() -ne '5aa9232c0632a33eac8ac08aed3bf62c257a28a3f7a0baf02226494c690295fa') {
    throw 'Seeded RNG/world regression: differs from independently captured TP6 oracle'
  }
  Write-Host 'PASS: 50 RNG outputs/seeds and 10 initial worlds match the TP6 golden hash.'
  if ((Get-FileHash (Join-Path $taskOut 'TIME.BIN') -Algorithm SHA256).Hash.ToLower() -ne 'bdf1d1f8826ac2bf340a75cce4ba52d3d5ff717b3e538f1668cd9d984a3e881a') {
    throw 'Delay/event time-state vector differs from independently captured TP6 oracle'
  }
  Write-Host 'PASS: character/alarm delays and six event transitions match the TP6 virtual-clock trace.'
  if ($Oracle) { & (Join-Path $PSScriptRoot 'tests\oracle.ps1') }
}
if (Test-Path (Join-Path $PSScriptRoot 'arabela.lpr')) {
  Copy-Item (Join-Path $taskRoot 'tools\portable\sdl\SDL3.dll'),(Join-Path $taskRoot 'tools\portable\ttf\SDL3_ttf.dll') $taskOut -Force
  if ($Tests) {
    & $Compiler @taskOptions ('-FU'+(Join-Path $taskOut 'testunits')) '-dOVERENI_OKNA' '-WG' (Join-Path $PSScriptRoot 'arabela.lpr')
    if ($LASTEXITCODE -ne 0) { throw 'SDL integration test compilation failed' }
    $taskSmoke = Join-Path $taskOut 'smoke'
    New-Item -ItemType Directory -Force $taskSmoke | Out-Null
    foreach ($taskOldReport in @('error.txt','results.txt')) {
      $taskReportPath = Join-Path $taskSmoke $taskOldReport
      if (Test-Path -LiteralPath $taskReportPath) { Remove-Item -LiteralPath $taskReportPath }
    }
    $taskOldVideo = $env:SDL_VIDEODRIVER
    $taskOldRender = $env:SDL_RENDER_DRIVER
    $env:SDL_VIDEODRIVER = $VideoDriver
    if ($VideoDriver -eq 'dummy') { $env:SDL_RENDER_DRIVER = 'software' } else { $env:SDL_RENDER_DRIVER = $null }
    try {
      $taskSmokeScore = Join-Path $taskSmoke 'ARABELA.SCO'
      if (Test-Path $taskSmokeScore) { Remove-Item -LiteralPath $taskSmokeScore }
      $taskProcess = Start-Process -FilePath (Join-Path $taskOut 'arabela.exe') -ArgumentList @('--smoke',('"'+$taskSmoke+'"'),'--scores',('"'+$taskSmokeScore+'"'),'--seed','12345678','--walkthrough',('"'+(Join-Path $taskOut 'walkthrough.txt')+'"')) -WindowStyle Hidden -PassThru
      if (-not $taskProcess.WaitForExit(30000)) { Stop-Process -Id $taskProcess.Id; throw 'SDL test timeout' }
      if ($taskProcess.ExitCode -ne 0) {
        $taskErrorPath = Join-Path $taskSmoke 'error.txt'
        if (Test-Path -LiteralPath $taskErrorPath) { throw ('SDL integration test failed: '+(Get-Content $taskErrorPath -Raw)) }
        throw 'SDL integration test failed'
      }
      Get-Content (Join-Path $taskSmoke 'results.txt')
    } finally { $env:SDL_VIDEODRIVER = $taskOldVideo; $env:SDL_RENDER_DRIVER = $taskOldRender }
  }
  & $Compiler @taskOptions ('-FU'+(Join-Path $taskOut 'units')) '-WG' (Join-Path $PSScriptRoot 'arabela.lpr')
  if ($LASTEXITCODE -ne 0) { throw 'Native SDL3 build failed' }
  if ($Run) { Start-Process -FilePath (Join-Path $taskOut 'arabela.exe') -WorkingDirectory $taskOut }
}
