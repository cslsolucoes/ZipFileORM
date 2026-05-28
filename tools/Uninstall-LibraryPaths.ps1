#requires -Version 5.1
<#
.SYNOPSIS
  Remove os paths do ZipFileORM do Library Path de cada Delphi instalado
  (D24..D37) no registro do Windows.

.DESCRIPTION
  Operacao reversa de Install-LibraryPaths.ps1. Remove apenas as entradas
  exatas que apontam para este projeto - preserva quaisquer outros paths
  ja presentes na chave 'Search Path'.

.PARAMETER OnlyDelphi
  Filtra para uma ou mais versoes especificas. Default: todos D24..D37.

.PARAMETER DryRun
  Mostra o que seria removido sem alterar o registro.

.EXAMPLE
  pwsh tools/Uninstall-LibraryPaths.ps1
  pwsh tools/Uninstall-LibraryPaths.ps1 -DryRun
#>
[CmdletBinding()]
param(
  [string[]] $OnlyDelphi = @(),
  [switch]   $DryRun
)

$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')

$delphis = @(
  @{ D = '24'; Bds = '18.0'; Rad = 'RAD10.1' }
  @{ D = '25'; Bds = '19.0'; Rad = 'RAD10.2' }
  @{ D = '26'; Bds = '20.0'; Rad = 'RAD10.3' }
  @{ D = '27'; Bds = '21.0'; Rad = 'RAD10.4' }
  @{ D = '28'; Bds = '22.0'; Rad = 'RAD11'   }
  @{ D = '29'; Bds = '23.0'; Rad = 'RAD12'   }
  @{ D = '37'; Bds = '37.0'; Rad = 'RAD13'   }
)
if ($OnlyDelphi.Count -gt 0) { $delphis = $delphis | Where-Object { $_.D -in $OnlyDelphi } }

function Remove-PathFromRegistryValue {
  param(
    [string]   $RegKey,
    [string]   $ValueName,
    [string[]] $PathsToRemove,
    [bool]     $IsDryRun
  )
  $current = (Get-ItemProperty -Path $RegKey -Name $ValueName -ErrorAction SilentlyContinue).$ValueName
  if ($null -eq $current -or $current -eq '') { return }
  $tokens = $current -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
  $kept = @()
  $removed = @()
  foreach ($t in $tokens) {
    $shouldRemove = $false
    foreach ($p in $PathsToRemove) {
      if ([string]::Equals($t, $p, [StringComparison]::OrdinalIgnoreCase)) { $shouldRemove = $true; break }
    }
    if ($shouldRemove) { $removed += $t } else { $kept += $t }
  }
  if ($removed.Count -eq 0) {
    Write-Host "    [$ValueName] none present" -ForegroundColor DarkGray
    return
  }
  if ($IsDryRun) {
    Write-Host "    DRYRUN [$ValueName] would remove $($removed.Count):" -ForegroundColor Yellow
    $removed | ForEach-Object { Write-Host "      - $_" -ForegroundColor Yellow }
    return
  }
  $newPath = ($kept -join ';')
  Set-ItemProperty -Path $RegKey -Name $ValueName -Value $newPath
  Write-Host "    OK [$ValueName] removed $($removed.Count):" -ForegroundColor Green
  $removed | ForEach-Object { Write-Host "      - $_" -ForegroundColor Green }
}

function Remove-PathFromRegistry {
  param(
    [string]   $RegKey,
    [string[]] $PathsToRemove,
    [string]   $Label,
    [bool]     $IsDryRun
  )
  if (-not (Test-Path $RegKey)) {
    Write-Host "  SKIP $Label - registry key not present" -ForegroundColor DarkGray
    return
  }
  Write-Host "  $Label" -ForegroundColor Cyan
  foreach ($vn in @('Search Path', 'LibraryPath', 'Browsing Path')) {
    Remove-PathFromRegistryValue -RegKey $RegKey -ValueName $vn -PathsToRemove $PathsToRemove -IsDryRun $IsDryRun
  }
}

Write-Host ""
Write-Host "=== ZipFileORM - Uninstall Library Paths ==="
Write-Host "Project root: $root"
if ($DryRun) { Write-Host "Mode: DRY-RUN (no registry changes)" -ForegroundColor Yellow }
Write-Host ""

$srcPath = Join-Path $root 'src'

foreach ($D in $delphis) {
  $libW32 = Join-Path $root "Lib\$($D.Rad)\Win32"
  $libW64 = Join-Path $root "Lib\$($D.Rad)\Win64"
  $bdsRoot = "HKCU:\Software\Embarcadero\BDS\$($D.Bds)\Library"
  if (-not (Test-Path "HKCU:\Software\Embarcadero\BDS\$($D.Bds)")) {
    Write-Host "D$($D.D) - not installed, skipped." -ForegroundColor DarkGray
    continue
  }
  Write-Host "D$($D.D)" -ForegroundColor Cyan
  Remove-PathFromRegistry -RegKey "$bdsRoot\Win32" -PathsToRemove @($srcPath, $libW32) -Label 'Win32' -IsDryRun $DryRun.IsPresent
  Remove-PathFromRegistry -RegKey "$bdsRoot\Win64" -PathsToRemove @($srcPath, $libW64) -Label 'Win64' -IsDryRun $DryRun.IsPresent
}

Write-Host ""
Write-Host "Done. Restart any open Delphi IDE for changes to take effect." -ForegroundColor Cyan
