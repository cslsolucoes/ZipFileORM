# Build-All-Examples.ps1
# Compila e (opcionalmente) roda todos os exemplos de ZipFileORM/example/.
# Use -Run para tambem executar cada .exe.

param(
  [switch]$Run,
  [switch]$Win64
)

$ErrorActionPreference = 'Continue'
$bds = "C:\Program Files (x86)\Embarcadero\Studio\23.0"
$ex = $PSScriptRoot
$src = Join-Path (Split-Path -Parent $ex) 'src'
$dcc = if ($Win64) { "$bds\bin\dcc64.exe" } else { "$bds\bin\dcc32.exe" }
$ns = "System;Winapi;Xml;Data;Datasnap;Web;Soap;Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell"

$examples = @(
  '01_zip_example',
  '02_tar_example',
  '03_sevenz_example',
  '04_cab_example',
  '05_bzip2_example',
  '06_iso_example',
  '07_lha_example',
  '08_arj_example',
  '09_rar_example',
  '10_z_example',
  '11_uue_example',
  '12_archive_auto_example'
)

$plat = if ($Win64) { 'Win64' } else { 'Win32' }
Write-Host "Compiling examples ($plat)..."
$results = @()

Push-Location $ex
foreach ($name in $examples) {
  $dpr = "$name.dpr"
  $exe = "$name.exe"
  if (-not (Test-Path $dpr)) {
    Write-Host "  SKIP $name (no .dpr)" -ForegroundColor Yellow
    continue
  }
  Remove-Item $exe -ErrorAction SilentlyContinue
  $log = & $dcc -Q -B "-NS$ns" "-U$src" $dpr 2>&1
  $ec = $LASTEXITCODE
  $ok = ($ec -eq 0) -and (Test-Path $exe)
  if ($ok) {
    Write-Host "  OK   $name" -ForegroundColor Green
    $results += [pscustomobject]@{ Name = $name; Status = 'BUILD OK' }
    if ($Run) {
      Write-Host "  --- running $name ---"
      & ".\$exe" | Out-String | Write-Host
    }
  } else {
    Write-Host "  FAIL $name (exit $ec)" -ForegroundColor Red
    ($log | Select-String -Pattern 'Error|Fatal' | Select-Object -First 3) |
      ForEach-Object { Write-Host "       $_" }
    $results += [pscustomobject]@{ Name = $name; Status = "BUILD FAIL exit $ec" }
  }
}
Pop-Location

Write-Host ""
Write-Host "=== Summary ($plat) ==="
$results | Format-Table -AutoSize
$ok = ($results | Where-Object Status -eq 'BUILD OK').Count
Write-Host ("OK: {0} / {1}" -f $ok, $results.Count)
