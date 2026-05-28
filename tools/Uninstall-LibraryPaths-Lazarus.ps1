#requires -Version 5.1
<#
.SYNOPSIS
  Remove o no <ZipFileORM>/<Paths> de environmentoptions.xml do Lazarus.

.DESCRIPTION
  Operacao reversa de Install-LibraryPaths-Lazarus.ps1. Remove a marca
  do ZipFileORM no XML preservando todo o resto.

.PARAMETER DryRun
  Mostra o que seria removido sem alterar arquivos.

.PARAMETER ConfigPath
  Path explicito; default auto-detect.

.EXAMPLE
  pwsh tools/Uninstall-LibraryPaths-Lazarus.ps1
  pwsh tools/Uninstall-LibraryPaths-Lazarus.ps1 -DryRun
#>
[CmdletBinding()]
param(
  [switch] $DryRun,
  [switch] $Force,
  [string] $ConfigPath = ''
)

$ErrorActionPreference = 'Stop'

# Detect Lazarus running
$running = Get-Process -Name 'lazarus','startlazarus' -ErrorAction SilentlyContinue
if ($running -and -not $Force -and -not $DryRun) {
  Write-Host 'ABORT: Lazarus IDE is running.' -ForegroundColor Red
  exit 1
}

function Find-LazarusConfig {
  param([string] $Explicit)
  if ($Explicit -and (Test-Path $Explicit)) { return $Explicit }
  foreach ($c in @(
    "$env:APPDATA\lazarus\environmentoptions.xml",
    "$env:USERPROFILE\.lazarus\environmentoptions.xml",
    'D:\lazarus\config\environmentoptions.xml',
    'C:\lazarus\config\environmentoptions.xml'
  )) {
    if (Test-Path $c) { return $c }
  }
  return $null
}

$cfg = Find-LazarusConfig -Explicit $ConfigPath
if (-not $cfg) {
  Write-Host 'Lazarus environmentoptions.xml not found - nothing to uninstall.' -ForegroundColor DarkGray
  exit 0
}

Write-Host ''
Write-Host '=== ZipFileORM - Uninstall Library Paths (Lazarus) ==='
Write-Host "Config file: $cfg"
if ($DryRun) { Write-Host 'Mode: DRY-RUN' -ForegroundColor Yellow }
Write-Host ''

[xml] $xml = Get-Content $cfg -Raw
$marker = $xml.SelectSingleNode('/CONFIG/EnvironmentOptions/ZipFileORM')
if (-not $marker) {
  Write-Host '  <ZipFileORM> node not present - nothing to remove.' -ForegroundColor DarkGray
  exit 0
}

$paths = @()
$pathsNode = $marker.SelectSingleNode('Paths')
if ($pathsNode) {
  foreach ($child in $pathsNode.ChildNodes) {
    $v = $child.GetAttribute('Value')
    if ($v) { $paths += $v }
  }
}

if ($DryRun) {
  Write-Host '  DRYRUN would remove <ZipFileORM> node containing:' -ForegroundColor Yellow
  $paths | ForEach-Object { Write-Host "    - $_" -ForegroundColor Yellow }
  exit 0
}

# Backup
$bak = "$cfg.bak-$(Get-Date -Format yyyyMMddHHmmss)"
Copy-Item $cfg $bak -Force
Write-Host "Backup: $bak" -ForegroundColor DarkGray

# Remove the marker node
$marker.ParentNode.RemoveChild($marker) | Out-Null
$xml.Save($cfg)
Write-Host '  OK removed <ZipFileORM> node containing:' -ForegroundColor Green
$paths | ForEach-Object { Write-Host "    - $_" -ForegroundColor Green }
Write-Host ''
Write-Host 'NOTE: Package itself remains installed in Lazarus.' -ForegroundColor Yellow
Write-Host 'To uninstall the package: open Lazarus > Package > Install/Uninstall Packages' -ForegroundColor Yellow
Write-Host '  > select ZipFileORMPkg in installed list > Uninstall selection.' -ForegroundColor Yellow
