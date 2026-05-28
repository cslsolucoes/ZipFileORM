#requires -Version 5.1
<#
.SYNOPSIS
  Copia as BPLs runtime + design-time para %BDSCOMMONDIR%\Bpl\ em cada
  Delphi instalado (D24..D37) — local padrao que o IDE sempre encontra.

.DESCRIPTION
  Quando voce clica "Install Package" no IDE apontando para uma dcl*.bpl,
  o Windows precisa resolver as dependencias dessa BPL (a runtime BPL).
  Se a runtime nao estiver no PATH do IDE (ou no mesmo diretorio), o IDE
  retorna o erro "Nao foi possivel encontrar o modulo especificado".

  Este script resolve isto copiando ambas as BPLs (runtime + design-time)
  para %BDSCOMMONDIR%\Bpl\<plataforma>\ que ja esta no PATH do IDE.

  Localizacoes copiadas:
    Win32: %BDSCOMMONDIR%\Bpl\
    Win64: %BDSCOMMONDIR%\Bpl\Win64\

  BDSCOMMONDIR por versao (default):
    D24..D29: C:\Users\Public\Documents\Embarcadero\Studio\<bds>
    D37:      C:\Users\Public\Documents\Embarcadero\Studio\37.0

.PARAMETER OnlyDelphi
  Filtra para uma ou mais versoes especificas (ex.: -OnlyDelphi 29,37).

.PARAMETER DryRun
  Mostra o que seria copiado sem alterar arquivos.

.EXAMPLE
  pwsh tools/Install-Bpls.ps1
  pwsh tools/Install-Bpls.ps1 -OnlyDelphi 37
  pwsh tools/Install-Bpls.ps1 -DryRun
#>
[CmdletBinding()]
param(
  [string[]] $OnlyDelphi = @(),
  [switch]   $DryRun
)

$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')

$delphis = @(
  @{ D = '24'; Bds = '18.0'; Rad = 'RAD10.1'; DelphiName = '10.1 Berlin'   }
  @{ D = '25'; Bds = '19.0'; Rad = 'RAD10.2'; DelphiName = '10.2 Tokyo'    }
  @{ D = '26'; Bds = '20.0'; Rad = 'RAD10.3'; DelphiName = '10.3 Rio'      }
  @{ D = '27'; Bds = '21.0'; Rad = 'RAD10.4'; DelphiName = '10.4 Sydney'   }
  @{ D = '28'; Bds = '22.0'; Rad = 'RAD11';   DelphiName = '11 Alexandria' }
  @{ D = '29'; Bds = '23.0'; Rad = 'RAD12';   DelphiName = '12 Athens'     }
  @{ D = '37'; Bds = '37.0'; Rad = 'RAD13';   DelphiName = '13 Florence'   }
)
if ($OnlyDelphi.Count -gt 0) { $delphis = $delphis | Where-Object { $_.D -in $OnlyDelphi } }

function Get-BdsCommonDir {
  param([string] $Bds)
  # Try registry first
  $regKey = "HKCU:\Software\Embarcadero\BDS\$Bds\Globals"
  if (Test-Path $regKey) {
    $val = (Get-ItemProperty -Path $regKey -Name 'CommonDocumentsDir' -ErrorAction SilentlyContinue).'CommonDocumentsDir'
    if ($val) { return $val }
  }
  # Fallback to standard path
  return "C:\Users\Public\Documents\Embarcadero\Studio\$Bds"
}

function Copy-Bpl {
  param(
    [string] $SrcFile,
    [string] $DstDir,
    [string] $Label,
    [bool]   $IsDryRun
  )
  if (-not (Test-Path $SrcFile)) {
    Write-Host "    SKIP $Label : source not found ($SrcFile)" -ForegroundColor DarkGray
    return
  }
  if (-not (Test-Path $DstDir)) {
    if ($IsDryRun) {
      Write-Host "    DRYRUN $Label : would create $DstDir" -ForegroundColor Yellow
    } else {
      New-Item -ItemType Directory -Force -Path $DstDir | Out-Null
    }
  }
  $dst = Join-Path $DstDir (Split-Path $SrcFile -Leaf)
  if ($IsDryRun) {
    Write-Host "    DRYRUN $Label : would copy" -ForegroundColor Yellow
    Write-Host "        from: $SrcFile" -ForegroundColor Yellow
    Write-Host "        to  : $dst" -ForegroundColor Yellow
    return
  }
  Copy-Item $SrcFile $dst -Force
  Write-Host "    OK $Label -> $dst" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== ZipFileORM - Install BPLs to BDSCOMMONDIR ==="
Write-Host "Project root: $root"
if ($DryRun) { Write-Host "Mode: DRY-RUN (no file changes)" -ForegroundColor Yellow }
Write-Host ""

foreach ($D in $delphis) {
  $bdsCommon = Get-BdsCommonDir -Bds $D.Bds
  if (-not (Test-Path $bdsCommon)) {
    Write-Host "D$($D.D) ($($D.DelphiName)) - BDSCOMMONDIR not found: $bdsCommon, skipped." -ForegroundColor DarkGray
    continue
  }
  Write-Host "D$($D.D) ($($D.DelphiName)) - BDSCOMMONDIR: $bdsCommon" -ForegroundColor Cyan

  $libW32 = Join-Path $root "Lib\$($D.Rad)\Win32"
  $libW64 = Join-Path $root "Lib\$($D.Rad)\Win64"
  $bplW32 = Join-Path $bdsCommon 'Bpl'
  $bplW64 = Join-Path $bdsCommon 'Bpl\Win64'

  # Win32: runtime + design-time
  $rtSrc  = Join-Path $libW32 "ZipFileORMD$($D.D).bpl"
  $dtSrc  = Join-Path $libW32 "dclZipFileORMD$($D.D).bpl"
  Copy-Bpl -SrcFile $rtSrc -DstDir $bplW32 -Label "Win32 runtime"     -IsDryRun $DryRun.IsPresent
  Copy-Bpl -SrcFile $dtSrc -DstDir $bplW32 -Label "Win32 design-time" -IsDryRun $DryRun.IsPresent

  # Win64: runtime (sempre) + design-time (apenas D29+ tem dcl Win64)
  $rtSrc64 = Join-Path $libW64 "ZipFileORMD$($D.D).bpl"
  $dtSrc64 = Join-Path $libW64 "dclZipFileORMD$($D.D).bpl"
  Copy-Bpl -SrcFile $rtSrc64 -DstDir $bplW64 -Label "Win64 runtime" -IsDryRun $DryRun.IsPresent
  if ([double]$D.Bds -ge 23.0) {
    Copy-Bpl -SrcFile $dtSrc64 -DstDir $bplW64 -Label "Win64 design-time" -IsDryRun $DryRun.IsPresent
  }
}

Write-Host ""
Write-Host "Done. The IDE can now find ZipFileORM BPLs without specifying PATH." -ForegroundColor Cyan
Write-Host "Run Component > Install Packages and add dclZipFileORMD<XX>.bpl from %BDSCOMMONDIR%\Bpl\." -ForegroundColor Cyan
