#requires -Version 5.1
<#
.SYNOPSIS
  Adiciona os paths do ZipFileORM ao Library Path de cada Delphi instalado
  (D24..D37) no registro do Windows.

.DESCRIPTION
  Para cada IDE Delphi suportado e instalado (D24/Berlin..D37/Florence),
  adiciona os seguintes paths ao 'Search Path' da chave Library do BDS:

    HKCU\Software\Embarcadero\BDS\<bds>\Library\Win32\Search Path
    HKCU\Software\Embarcadero\BDS\<bds>\Library\Win64\Search Path

  Paths adicionados:
    - <root>\src                  (fonte .pas)
    - <root>\Lib\RAD<xx>\Win32    (DCU/DCP runtime+designtime Win32)
    - <root>\Lib\RAD<xx>\Win64    (DCU/DCP runtime Win64)

  As mudancas tomam efeito quando o Delphi for re-aberto.

  Operacao idempotente: paths ja presentes nao sao duplicados.

.PARAMETER OnlyDelphi
  Filtra para uma ou mais versoes especificas (ex.: -OnlyDelphi 29,37).
  Default: todos D24..D37 detectados.

.PARAMETER DryRun
  Mostra o que seria feito sem alterar o registro.

.EXAMPLE
  pwsh tools/Install-LibraryPaths.ps1
  pwsh tools/Install-LibraryPaths.ps1 -OnlyDelphi 29
  pwsh tools/Install-LibraryPaths.ps1 -DryRun
#>
[CmdletBinding()]
param(
  [string[]] $OnlyDelphi = @(),
  [switch]   $DryRun
)

$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')

$delphis = @(
  @{ D = '24'; Bds = '18.0'; Rad = 'RAD10.1'; DelphiName = '10.1 Berlin'    }
  @{ D = '25'; Bds = '19.0'; Rad = 'RAD10.2'; DelphiName = '10.2 Tokyo'     }
  @{ D = '26'; Bds = '20.0'; Rad = 'RAD10.3'; DelphiName = '10.3 Rio'       }
  @{ D = '27'; Bds = '21.0'; Rad = 'RAD10.4'; DelphiName = '10.4 Sydney'    }
  @{ D = '28'; Bds = '22.0'; Rad = 'RAD11';   DelphiName = '11 Alexandria'  }
  @{ D = '29'; Bds = '23.0'; Rad = 'RAD12';   DelphiName = '12 Athens'      }
  @{ D = '37'; Bds = '37.0'; Rad = 'RAD13';   DelphiName = '13 Florence'    }
)

if ($OnlyDelphi.Count -gt 0) {
  $delphis = $delphis | Where-Object { $_.D -in $OnlyDelphi }
}

function Add-PathToRegistry {
  param(
    [string] $RegKey,
    [string[]] $PathsToAdd,
    [string] $Label,
    [bool] $IsDryRun
  )
  if (-not (Test-Path $RegKey)) {
    Write-Host "  SKIP $Label - registry key not present" -ForegroundColor DarkGray
    return
  }
  $current = (Get-ItemProperty -Path $RegKey -Name 'Search Path' -ErrorAction SilentlyContinue).'Search Path'
  if ($null -eq $current) { $current = '' }
  $newPath = $current
  $added = @()
  foreach ($p in $PathsToAdd) {
    $tokens = $newPath -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    $exists = $false
    foreach ($t in $tokens) {
      if ([string]::Equals($t, $p, [StringComparison]::OrdinalIgnoreCase)) { $exists = $true; break }
    }
    if ($exists) { continue }
    if ($newPath -and -not $newPath.EndsWith(';')) { $newPath = $newPath + ';' }
    $newPath = $newPath + $p
    $added += $p
  }
  if ($added.Count -eq 0) {
    Write-Host "  $Label - all paths already present" -ForegroundColor DarkGray
    return
  }
  if ($IsDryRun) {
    Write-Host "  DRYRUN $Label - would add:" -ForegroundColor Yellow
    $added | ForEach-Object { Write-Host "    + $_" -ForegroundColor Yellow }
    return
  }
  Set-ItemProperty -Path $RegKey -Name 'Search Path' -Value $newPath
  Write-Host "  OK $Label - added:" -ForegroundColor Green
  $added | ForEach-Object { Write-Host "    + $_" -ForegroundColor Green }
}

Write-Host ""
Write-Host "=== ZipFileORM - Install Library Paths ==="
Write-Host "Project root: $root"
if ($DryRun) { Write-Host "Mode: DRY-RUN (no registry changes)" -ForegroundColor Yellow }
Write-Host ""

$srcPath = Join-Path $root 'src'

foreach ($D in $delphis) {
  $libW32 = Join-Path $root "Lib\$($D.Rad)\Win32"
  $libW64 = Join-Path $root "Lib\$($D.Rad)\Win64"

  $bdsRoot = "HKCU:\Software\Embarcadero\BDS\$($D.Bds)\Library"

  if (-not (Test-Path "HKCU:\Software\Embarcadero\BDS\$($D.Bds)")) {
    Write-Host "D$($D.D) ($($D.DelphiName)) - not installed, skipped." -ForegroundColor DarkGray
    continue
  }

  Write-Host "D$($D.D) ($($D.DelphiName))" -ForegroundColor Cyan
  Add-PathToRegistry -RegKey "$bdsRoot\Win32" -PathsToAdd @($srcPath, $libW32) -Label 'Win32' -IsDryRun $DryRun.IsPresent
  Add-PathToRegistry -RegKey "$bdsRoot\Win64" -PathsToAdd @($srcPath, $libW64) -Label 'Win64' -IsDryRun $DryRun.IsPresent
}

Write-Host ""
Write-Host "Done. Restart any open Delphi IDE for changes to take effect." -ForegroundColor Cyan
