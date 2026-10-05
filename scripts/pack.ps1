param(
  [string]$InputExe = 'build\ARABELA.EXE',
  [string]$OutputDirectory = 'build\packed'
)
$ErrorActionPreference='Stop'
$taskRoot=Split-Path -Parent $PSScriptRoot
$taskInput=[IO.Path]::GetFullPath((Join-Path $taskRoot $InputExe))
$taskOutput=[IO.Path]::GetFullPath((Join-Path $taskRoot $OutputDirectory))
if (-not $taskOutput.StartsWith($taskRoot + '\',[StringComparison]::OrdinalIgnoreCase) -or
    $taskOutput.Equals((Join-Path $taskRoot 'assets'),[StringComparison]::OrdinalIgnoreCase) -or
    $taskOutput.StartsWith((Join-Path $taskRoot 'assets') + '\',[StringComparison]::OrdinalIgnoreCase)) {
  throw 'Packing output must stay inside the workspace, outside assets'
}
New-Item -ItemType Directory -Force $taskOutput | Out-Null
if ($taskInput.Equals((Join-Path $taskOutput 'ARABELA.EXE'),[StringComparison]::OrdinalIgnoreCase)) {
  throw 'Packing input and output must be separate'
}
$taskInputHash=(Get-FileHash -LiteralPath $taskInput -Algorithm SHA256).Hash
$taskBackup=Join-Path $taskOutput 'ARABELA.OLD'
if (Test-Path -LiteralPath $taskBackup) { Remove-Item -LiteralPath $taskBackup }
Copy-Item -LiteralPath $taskInput -Destination (Join-Path $taskOutput 'ARABELA.EXE') -Force
Copy-Item -LiteralPath 'C:\tools\lzexe90\LZEXE.EXE' -Destination (Join-Path $taskOutput 'LZEXE.EXE') -Force
$taskArgs=@('-noconsole','-conf',('"' + (Join-Path $PSScriptRoot 'dosbox.conf') + '"'),
  '-c',('"mount c ' + $taskOutput + '"'),'-c','"c:"',
  '-c','"lzexe arabela.exe"','-c','"exit"')
$taskOldSDL=$env:SDL_VIDEODRIVER
$env:SDL_VIDEODRIVER='dummy'
try {
  $taskProcess=Start-Process -FilePath 'C:\tools\dosbox\DOSBox.exe' -ArgumentList $taskArgs -WindowStyle Hidden -WorkingDirectory $taskOutput -PassThru
  if (-not $taskProcess.WaitForExit(30000)) {
    Stop-Process -Id $taskProcess.Id
    throw 'LZEXE packing timed out'
  }
} finally { $env:SDL_VIDEODRIVER=$taskOldSDL }
if (-not (Test-Path -LiteralPath (Join-Path $taskOutput 'ARABELA.OLD'))) { throw 'Packer did not preserve its input' }
if ((Get-FileHash -LiteralPath $taskBackup -Algorithm SHA256).Hash -ne $taskInputHash) {
  throw 'Packer backup differs from its fresh input'
}
$taskPacked=Join-Path $taskOutput 'ARABELA.EXE'
$taskMagic=[IO.File]::ReadAllBytes($taskPacked)
if ([Text.Encoding]::ASCII.GetString($taskMagic,28,4) -ne 'LZ09') { throw 'Packer did not produce LZEXE 0.90 output' }
Write-Output $taskPacked
