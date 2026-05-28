#requires -Version 5.1
<#
.SYNOPSIS
  Remove as BPLs do ZipFileORM de %BDSCOMMONDIR%\Bpl\ em cada Delphi.

.DESCRIPTION
  Operacao reversa de Install-Bpls.ps1. Remove APENAS as 4 BPLs do
  ZipFileORM por Delphi (ZipFileORMD<XX>.bpl + dclZipFileORMD<XX>.bpl
  para Win32 e Win64).

.PARAMETER OnlyDelphi
  Filtra para uma ou mais versoes especificas.

.PARAMETER DryRun
  Mostra o que seria removido sem alterar arquivos.

.EXAMPLE
  pwsh tools/Uninstall-Bpls.ps1
  pwsh tools/Uninstall-Bpls.ps1 -DryRun
#>
[CmdletBinding()]
param(
  [string[]] $OnlyDelphi = @(),
  [switch]   $DryRun
)

$ErrorActionPreference = 'Stop'

$delphis = @(
  @{ D = '24'; Bds = '18.0' }
  @{ D = '25'; Bds = '19.0' }
  @{ D = '26'; Bds = '20.0' }
  @{ D = '27'; Bds = '21.0' }
  @{ D = '28'; Bds = '22.0' }
  @{ D = '29'; Bds = '23.0' }
  @{ D = '37'; Bds = '37.0' }
)
if ($OnlyDelphi.Count -gt 0) { $delphis = $delphis | Where-Object { $_.D -in $OnlyDelphi } }

function Get-BdsCommonDir {
  param([string] $Bds)
  $regKey = "HKCU:\Software\Embarcadero\BDS\$Bds\Globals"
  if (Test-Path $regKey) {
    $val = (Get-ItemProperty -Path $regKey -Name 'CommonDocumentsDir' -ErrorAction SilentlyContinue).'CommonDocumentsDir'
    if ($val) { return $val }
  }
  return "C:\Users\Public\Documents\Embarcadero\Studio\$Bds"
}

function Remove-Bpl {
  param([string] $File, [string] $Label, [bool] $IsDryRun)
  if (-not (Test-Path $File)) {
    Write-Host "    SKIP $Label : not present" -ForegroundColor DarkGray
    return
  }
  if ($IsDryRun) {
    Write-Host "    DRYRUN $Label : would remove $File" -ForegroundColor Yellow
    return
  }
  Remove-Item -Force $File
  Write-Host "    OK removed $Label" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== ZipFileORM - Uninstall BPLs from BDSCOMMONDIR ==="
if ($DryRun) { Write-Host "Mode: DRY-RUN (no file changes)" -ForegroundColor Yellow }
Write-Host ""

foreach ($D in $delphis) {
  $bdsCommon = Get-BdsCommonDir -Bds $D.Bds
  if (-not (Test-Path $bdsCommon)) {
    Write-Host "D$($D.D) - not installed, skipped." -ForegroundColor DarkGray
    continue
  }
  Write-Host "D$($D.D)" -ForegroundColor Cyan
  $bplW32 = Join-Path $bdsCommon 'Bpl'
  $bplW64 = Join-Path $bdsCommon 'Bpl\Win64'
  Remove-Bpl -File (Join-Path $bplW32 "ZipFileORMD$($D.D).bpl")     -Label "Win32 runtime"     -IsDryRun $DryRun.IsPresent
  Remove-Bpl -File (Join-Path $bplW32 "dclZipFileORMD$($D.D).bpl")  -Label "Win32 design-time" -IsDryRun $DryRun.IsPresent
  Remove-Bpl -File (Join-Path $bplW64 "ZipFileORMD$($D.D).bpl")     -Label "Win64 runtime"     -IsDryRun $DryRun.IsPresent
  Remove-Bpl -File (Join-Path $bplW64 "dclZipFileORMD$($D.D).bpl")  -Label "Win64 design-time" -IsDryRun $DryRun.IsPresent
}

Write-Host ""
Write-Host "Done." -ForegroundColor Cyan
