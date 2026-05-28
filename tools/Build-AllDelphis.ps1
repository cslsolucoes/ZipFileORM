#requires -Version 5.1
<#
.SYNOPSIS
  Compila ZipFileORMD<XX>.dpk (runtime Win32+Win64) e dclZipFileORMD<XX>.dpk
  (design-time Win32; Win64 onde BDS >= 23.0).

.PARAMETER OnlyDelphi
  Para validacao seletiva. Default: todos D24..D37.

.PARAMETER InstallLibPaths
  Apos o build, dispara tools/Install-LibraryPaths.ps1 para adicionar os
  paths de Library de cada Delphi (HKCU\...\BDS\<bds>\Library\<Plat>\Search Path).
  Idempotente — paths ja presentes nao sao duplicados.

.PARAMETER InstallBpls
  Apos o build, dispara tools/Install-Bpls.ps1 para copiar as BPLs runtime+
  design-time para %BDSCOMMONDIR%\Bpl\ de cada Delphi. Necessario para o IDE
  conseguir resolver dependencias ao instalar a dcl*.bpl.

.PARAMETER Install
  Atalho para -InstallLibPaths -InstallBpls (faz tudo apos build verde).
#>
[CmdletBinding()]
param(
  [string[]] $OnlyDelphi = @(),
  [switch]   $InstallLibPaths,
  [switch]   $InstallBpls,
  [switch]   $Install
)
if ($Install) { $InstallLibPaths = $true; $InstallBpls = $true }

$ErrorActionPreference = 'Stop'
$root    = Split-Path -Parent $PSScriptRoot
$pkgsDir = Join-Path $root 'packages'

# Note: ZipFileORM.LibraryPathReg.pas now discovers the project root at
# runtime via GetModuleFileName(HInstance). No build-time path injection
# needed. The BPL must be installed from its build output location
# <root>\Lib\RAD<xx>\Win<plat>\ so the BPL path encodes the root.

$delphis = @(
  @{ D = '24'; Bds = '18.0'; Rad = 'RAD10.1' }
  @{ D = '25'; Bds = '19.0'; Rad = 'RAD10.2' }
  @{ D = '26'; Bds = '20.0'; Rad = 'RAD10.3' }
  @{ D = '27'; Bds = '21.0'; Rad = 'RAD10.4' }
  @{ D = '28'; Bds = '22.0'; Rad = 'RAD11'   }
  @{ D = '29'; Bds = '23.0'; Rad = 'RAD12'   }
  @{ D = '37'; Bds = '37.0'; Rad = 'RAD13'   }
)
if ($OnlyDelphi.Count -gt 0) {
  $delphis = $delphis | Where-Object { $_.D -in $OnlyDelphi }
}

$ns = 'System;Winapi;Vcl;Data;Datasnap;Web;Soap;Xml;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell;Bde'

$results = New-Object System.Collections.Generic.List[object]
foreach ($D in $delphis) {
  $bdsDir = "C:\Program Files (x86)\Embarcadero\Studio\$($D.Bds)"
  $dcc32  = "$bdsDir\bin\dcc32.exe"
  $dcc64  = "$bdsDir\bin\dcc64.exe"
  if (-not (Test-Path $dcc32)) {
    Write-Host "SKIP D$($D.D) (BDS $($D.Bds)): dcc32 not found" -ForegroundColor Yellow
    continue
  }

  foreach ($info in @(
    @{ Dpk = "ZipFileORMD$($D.D)";    IsDt = $false; Plats = @('Win32','Win64') },
    @{ Dpk = "dclZipFileORMD$($D.D)"; IsDt = $true;  Plats = if ([double]$D.Bds -ge 23.0) { @('Win32','Win64') } else { @('Win32') } }
  )) {
    foreach ($plat in $info.Plats) {
      $compiler = if ($plat -eq 'Win32') { $dcc32 } else { $dcc64 }
      if (-not (Test-Path $compiler)) {
        Write-Host "SKIP $($info.Dpk) ${plat}: compiler not found" -ForegroundColor Yellow
        continue
      }
      $outDir = Join-Path $root "Lib\$($D.Rad)\$plat"
      if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
      Push-Location $pkgsDir
      try {
        $log = & $compiler -Q -B "$($info.Dpk).dpk" "-NS$ns" "-N$outDir" "-LE$outDir" "-LN$outDir" "-U..;$outDir" "-R.." 2>&1
        $ec = $LASTEXITCODE
        $bpl = Join-Path $outDir "$($info.Dpk).bpl"
        $ok = ($ec -eq 0) -and (Test-Path $bpl)
        $tag = if ($ok) { 'OK' } else { 'FAIL' }
        $color = if ($ok) { 'Green' } else { 'Red' }
        Write-Host ("{0,-30} D{1,-3} {2,-6} -> {3}" -f $info.Dpk, $D.D, $plat, $tag) -ForegroundColor $color
        if (-not $ok) {
          $log -split "`n" | Where-Object { $_ -match 'Error|Fatal' } | Select-Object -First 3 | ForEach-Object { Write-Host "   $_" -ForegroundColor Red }
        }
        $results.Add([pscustomobject]@{ Dpk=$info.Dpk; D=$D.D; Plat=$plat; OK=$ok })
      } finally { Pop-Location }
    }
  }
}

# Summary
Write-Host ""
Write-Host "=== Summary ==="
$total = $results.Count
$ok    = ($results | Where-Object OK).Count
"$ok / $total OK"

function Invoke-PostBuildScript {
  param([string] $ScriptName, [string[]] $OnlyDelphi)
  $sp = Join-Path $PSScriptRoot $ScriptName
  if (-not (Test-Path $sp)) {
    Write-Host "WARN: $ScriptName not found in $PSScriptRoot" -ForegroundColor Yellow
    return
  }
  if ($OnlyDelphi.Count -gt 0) {
    & $sp -OnlyDelphi $OnlyDelphi
  } else {
    & $sp
  }
}

# Optional post-build: install Library Paths in HKCU registry
if ($InstallLibPaths) {
  if ($ok -eq $total) {
    Invoke-PostBuildScript -ScriptName 'Install-LibraryPaths.ps1' -OnlyDelphi $OnlyDelphi
  } else {
    Write-Host "SKIP Install-LibraryPaths.ps1 - build had failures ($ok / $total)" -ForegroundColor Yellow
  }
}

# Optional post-build: copy BPLs to BDSCOMMONDIR\Bpl\
if ($InstallBpls) {
  if ($ok -eq $total) {
    Invoke-PostBuildScript -ScriptName 'Install-Bpls.ps1' -OnlyDelphi $OnlyDelphi
  } else {
    Write-Host "SKIP Install-Bpls.ps1 - build had failures ($ok / $total)" -ForegroundColor Yellow
  }
}
