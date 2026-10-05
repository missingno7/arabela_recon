param([switch]$Compile, [string[]]$Cases=@('read','missing','insert','actions','keys','escape','exit'))
$ErrorActionPreference='Stop'
$taskRoot=Split-Path -Parent $PSScriptRoot
$taskTestRoot=Join-Path $taskRoot 'build\tests'
New-Item -ItemType Directory -Force $taskTestRoot | Out-Null
if ($Compile) {
  Push-Location $taskRoot
  try {
    & 'C:\tools\nmlgcdos\msdos.exe' -e 'C:\tools\tp6\TPC.EXE' src\ARABELA.PAS /DOVERENI /Iprobes /Ubuild\first /Ebuild\tests /GD
    if ($LASTEXITCODE -ne 0) { throw 'Behavioral test compilation failed' }
  } finally { Pop-Location }
}
$taskOriginal=[IO.File]::ReadAllBytes((Join-Path $taskRoot 'assets\ARABELA.SCO'))
$taskResults=@()
foreach ($taskCase in $Cases) {
  $taskDir=Join-Path $taskTestRoot $taskCase
  New-Item -ItemType Directory -Force $taskDir | Out-Null
  Copy-Item -LiteralPath (Join-Path $taskTestRoot 'ARABELA.EXE') -Destination $taskDir -Force
  $taskScore=Join-Path $taskDir 'ARABELA.SCO'
  $taskResult=Join-Path $taskDir 'RESULT.TXT'
  if (Test-Path -LiteralPath $taskScore) { Remove-Item -LiteralPath $taskScore }
  if (Test-Path -LiteralPath $taskResult) { Remove-Item -LiteralPath $taskResult }
  if ($taskCase -in @('read','insert')) { [IO.File]::WriteAllBytes($taskScore,$taskOriginal) }
  [IO.File]::WriteAllText((Join-Path $taskDir 'INPUT.TXT'),"ZKOUSKA HRACE`r`n",[Text.Encoding]::ASCII)
  $taskArgs=@('-noconsole','-conf',('"'+(Join-Path $PSScriptRoot 'dosbox.conf')+'"'),
    '-c',('"mount c '+$taskDir+'"'),'-c','"c:"',
    '-c',('"arabela '+$taskCase+'"'),'-c','"exit"')
  $taskOldSDL=$env:SDL_VIDEODRIVER
  $env:SDL_VIDEODRIVER='dummy'
  try {
    $taskProcess=Start-Process -FilePath 'C:\tools\dosbox\DOSBox.exe' -ArgumentList $taskArgs -WindowStyle Hidden -WorkingDirectory $taskDir -PassThru
    $taskTimeout=60000
    if ($taskCase -eq 'actions') { $taskTimeout=1200000 }
    if (-not $taskProcess.WaitForExit($taskTimeout)) {
      Stop-Process -Id $taskProcess.Id
      throw "Behavioral test timed out: $taskCase"
    }
  } finally { $env:SDL_VIDEODRIVER=$taskOldSDL }
  $taskPassed=$false
  if (Test-Path -LiteralPath $taskResult) {
    $taskLog=Get-Content -LiteralPath $taskResult -Raw
    $taskPassed=$taskLog -match "PASS $taskCase"
    if ($taskCase -eq 'exit') {
      $taskPassed=($taskLog -match 'Program VYSVOBOD PRINCEZNU ARABELU se s Vami louci !') -and
                  ($taskLog -notmatch 'FAIL')
    }
  }
  if (-not $taskPassed) {
    throw "DOS behavioral test failed: $taskCase (see $taskResult)"
  }
  if ($taskCase -notin @('read','insert')) {
    if (Test-Path -LiteralPath $taskScore) { throw 'Reading missing scores unexpectedly created a file' }
  } else {
    $taskSaved=[IO.File]::ReadAllBytes($taskScore)
    if ($taskSaved.Length -ne 342) { throw 'Incorrect score file size' }
    $taskStart=0
    if ($taskCase -eq 'insert') { $taskStart=94 }
    for ($taskIndex=$taskStart; $taskIndex -lt 342; $taskIndex++) {
      if ($taskSaved[$taskIndex] -ne $taskOriginal[$taskIndex]) {
        throw "Score preservation differs at byte $taskIndex in $taskCase"
      }
    }
    if ($taskCase -eq 'insert') {
      for ($taskIndex=0; $taskIndex -lt 62; $taskIndex++) {
        if ($taskSaved[32+$taskIndex] -ne $taskOriginal[1+$taskIndex]) {
          throw 'Score insertion did not preserve complete shifted records'
        }
      }
    }
  }
  $taskResults += @{scenario=$taskCase;passed=$true;runner='DOSBox 0.74-3';source='ARABELA.PAS /DOVERENI'}
  Write-Host "PASS $taskCase"
}
$taskReport='results.json'
if ($Cases.Count -ne 7) { $taskReport='subset-results.json' }
$taskResults | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $taskTestRoot $taskReport) -Encoding utf8
