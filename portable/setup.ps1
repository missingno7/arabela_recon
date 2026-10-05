# Installs nothing system-wide. Everything is extracted into ignored tools.
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskTools = Join-Path $taskRoot 'tools\portable'
$taskDependencies = Get-Content (Join-Path $PSScriptRoot 'dependencies.json') -Raw | ConvertFrom-Json
New-Item -ItemType Directory -Force $taskTools | Out-Null
foreach ($taskEntry in $taskDependencies.PSObject.Properties) {
  $taskDependency = $taskEntry.Value
  $taskArchive = Join-Path $taskTools $taskDependency.file
  if (-not (Test-Path -LiteralPath $taskArchive)) {
    Invoke-WebRequest -Uri $taskDependency.url -OutFile $taskArchive
  }
  if ((Get-FileHash -LiteralPath $taskArchive -Algorithm SHA256).Hash.ToLower() -ne $taskDependency.sha256) {
    throw "Archive hash differs: $($taskDependency.file). Remove the incorrect local download and retry."
  }
}
foreach ($taskEntry in @('innoextract','sdl','ttf')) {
  Expand-Archive -LiteralPath (Join-Path $taskTools $taskDependencies.$taskEntry.file) -DestinationPath (Join-Path $taskTools $taskEntry) -Force
}
if (-not (Test-Path (Join-Path $taskTools 'fpc\app\bin\i386-win32\ppcrossx64.exe'))) {
  & (Join-Path $taskTools 'innoextract\innoextract.exe') -q -d (Join-Path $taskTools 'fpc') (Join-Path $taskTools 'fpc-3.2.2.exe') *> (Join-Path $taskTools 'extraction.log')
  if ($LASTEXITCODE -ne 0) { throw 'Local Free Pascal extraction failed' }
}
Write-Host 'Pinned Free Pascal + SDL3 + SDL_ttf ready in tools/portable. No PATH or registry changes.'
