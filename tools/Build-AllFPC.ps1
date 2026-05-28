#requires -Version 5.1
<#
.SYNOPSIS
  Orquestra build + install do ZipFileORM para FPC/Lazarus:
  1. Roda Build-FPC-Smoke.ps1 (22 targets) para validar compile
  2. Opcionalmente registra Library Paths no Lazarus environmentoptions.xml

.PARAMETER InstallLibPaths
  Apos build verde, dispara Install-LibraryPaths-Lazarus.ps1.

.PARAMETER Install
  Atalho para -InstallLibPaths (espelha Build-AllDelphis.ps1 -Install).

.EXAMPLE
  pwsh tools/Build-AllFPC.ps1
  pwsh tools/Build-AllFPC.ps1 -Install
#>
[CmdletBinding()]
param(
  [switch] $InstallLibPaths,
  [switch] $Install
)
if ($Install) { $InstallLibPaths = $true }

$ErrorActionPreference = 'Stop'

# 1. Run FPC smoke build
$smokeScript = Join-Path $PSScriptRoot 'Build-FPC-Smoke.ps1'
if (-not (Test-Path $smokeScript)) {
  Write-Host "ERROR: $smokeScript not found." -ForegroundColor Red
  exit 1
}

Write-Host ''
Write-Host '=== ZipFileORM FPC Build Orchestrator ===' -ForegroundColor Cyan
Write-Host ''

$smokeOutput = & $smokeScript 2>&1
$smokeOutput | Out-Host
$ok = ($smokeOutput | Select-String -Pattern 'BUILD OK').Count
$fail = ($smokeOutput | Select-String -Pattern 'BUILD FAIL').Count
$total = $ok + $fail

Write-Host ''
Write-Host "Build summary: $ok / $total OK" -ForegroundColor $(if ($fail -eq 0) { 'Green' } else { 'Red' })

# 2. Optional install of Library Paths
if ($InstallLibPaths) {
  if ($fail -eq 0) {
    $installScript = Join-Path $PSScriptRoot 'Install-LibraryPaths-Lazarus.ps1'
    if (Test-Path $installScript) {
      & $installScript
    } else {
      Write-Host "WARN: Install-LibraryPaths-Lazarus.ps1 not found." -ForegroundColor Yellow
    }
  } else {
    Write-Host 'SKIP Install-LibraryPaths-Lazarus.ps1 - build had failures.' -ForegroundColor Yellow
  }
}

exit $(if ($fail -eq 0) { 0 } else { 1 })
