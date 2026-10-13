# Bootstrap the official Flutter Windows runner and apply Arabic branding.
# It does not overwrite Dart sources or manually maintained Windows files.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
  if (Test-Path 'windows\CMakeLists.txt') {
    Write-Host 'Windows runner already present; retaining existing source.'
  } else {
    $temporaryBase = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { [System.IO.Path]::GetTempPath() }
    $temporary = Join-Path $temporaryBase ('adwas_personnel_' + [Guid]::NewGuid().ToString('N'))
    try {
      flutter create --platforms=windows --project-name adwas_personnel --org com.adwas $temporary
      if ($LASTEXITCODE -ne 0) { throw 'flutter create failed' }
      if (!(Test-Path (Join-Path $temporary 'windows\CMakeLists.txt'))) {
        throw 'Windows runner template missing'
      }
      Copy-Item (Join-Path $temporary 'windows') (Join-Path $root 'windows') -Recurse
      if (!(Test-Path 'windows\CMakeLists.txt')) { throw 'Windows runner copy failed' }
      Write-Host 'Windows runner generated from the current Flutter SDK.'
    } finally {
      if (Test-Path $temporary) { Remove-Item $temporary -Recurse -Force }
    }
  }

  python scripts/patch_windows_metadata.py
  if ($LASTEXITCODE -ne 0) { throw 'Failed to apply Arabic Windows metadata' }
} finally {
  Pop-Location
}
