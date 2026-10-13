# Package a portable Windows smoke-test application with its Arabic EXE name.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
  $output = 'build\windows\x64\runner\Release'
  if (!(Test-Path $output)) { throw "Build output not found: $output" }
  $sourceExe = Join-Path $output 'adwas_personnel.exe'
  if (!(Test-Path $sourceExe)) { throw "Built Windows executable missing: $sourceExe" }

  $stage = Join-Path $root 'artifacts\portable'
  $deliverable = 'التمام اليومي.exe'
  $archiveName = 'Altamam_AlYawmi_Part_VI_Windows_x64.zip'
  $artifacts = Join-Path $root 'artifacts'
  if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
  New-Item -ItemType Directory -Force -Path $stage | Out-Null
  Copy-Item -Path "$output\*" -Destination $stage -Recurse -Force
  $oldExe = Join-Path $stage 'adwas_personnel.exe'
  Rename-Item -LiteralPath $oldExe -NewName $deliverable
  if (!(Test-Path -LiteralPath (Join-Path $stage $deliverable))) {
    throw 'Arabic Windows executable was not packaged'
  }
  if (Test-Path (Join-Path $stage 'adwas_personnel.exe')) {
    throw 'Duplicate legacy executable name remained in portable package'
  }

  $archive = Join-Path $artifacts $archiveName
  Compress-Archive -Path "$stage\*" -DestinationPath $archive -Force
  if (!(Test-Path $archive)) { throw 'Portable archive missing' }
  $hash = (Get-FileHash -Algorithm SHA256 $archive).Hash
  "$hash  $archiveName" | Out-File (Join-Path $artifacts 'SHA256SUMS.txt') -Encoding utf8
  if ((Get-Item $archive).Length -lt 100000) { throw 'Suspiciously small build artifact' }
  Write-Host "Portable Windows build packaged: $archiveName"
} finally {
  Pop-Location
}
