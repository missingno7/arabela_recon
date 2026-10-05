param([switch]$Tests, [switch]$Run, [string]$Compiler)
$ErrorActionPreference = 'Stop'
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
}
if (Test-Path (Join-Path $PSScriptRoot 'arabela.lpr')) {
  & $Compiler @taskOptions ('-FU'+(Join-Path $taskOut 'units')) '-WG' (Join-Path $PSScriptRoot 'arabela.lpr')
  if ($LASTEXITCODE -ne 0) { throw 'Native SDL3 build failed' }
  Copy-Item (Join-Path $taskRoot 'tools\portable\sdl\SDL3.dll'),(Join-Path $taskRoot 'tools\portable\ttf\SDL3_ttf.dll') $taskOut -Force
  if ($Run) { Start-Process -FilePath (Join-Path $taskOut 'arabela.exe') -WorkingDirectory $taskOut }
}
