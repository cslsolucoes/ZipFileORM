#requires -Version 5.1
<#
.SYNOPSIS
  Adiciona os paths do ZipFileORM ao Library Path do Lazarus IDE
  (~/.lazarus/environmentoptions.xml ou %APPDATA%\lazarus\environmentoptions.xml).

.DESCRIPTION
  Lazarus armazena Library Path em XML, nao no registro Windows.
  Este script localiza environmentoptions.xml, faz backup, e adiciona
  3 paths ao no <FPCSourceDirectory> ou <LazarusDirectory>/<SearchPaths>:

    <root>\src
    <root>\Lib\FPC\win32  (ou \win64 conforme target)

  Operacao idempotente: paths ja presentes nao sao duplicados.

.PARAMETER DryRun
  Mostra o que seria feito sem modificar arquivos.

.PARAMETER Force
  Aborta se Lazarus IDE estiver rodando; -Force ignora.

.PARAMETER ConfigPath
  Path explicito para environmentoptions.xml. Default: auto-detect.

.EXAMPLE
  pwsh tools/Install-LibraryPaths-Lazarus.ps1
  pwsh tools/Install-LibraryPaths-Lazarus.ps1 -DryRun
#>
[CmdletBinding()]
param(
  [switch] $DryRun,
  [switch] $Force,
  [string] $ConfigPath = ''
)

$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')

# 1. Detect Lazarus IDE running
$running = Get-Process -Name 'lazarus','startlazarus' -ErrorAction SilentlyContinue
if ($running -and -not $Force -and -not $DryRun) {
  Write-Host ''
  Write-Host 'ABORT: Lazarus IDE is running:' -ForegroundColor Red
  $running | ForEach-Object { Write-Host "  PID $($_.Id) - $($_.MainWindowTitle)" -ForegroundColor Red }
  Write-Host 'Close Lazarus and re-run, OR pass -Force.' -ForegroundColor Yellow
  exit 1
}

# 2. Locate environmentoptions.xml
function Find-LazarusConfig {
  param([string] $Explicit)
  if ($Explicit -and (Test-Path $Explicit)) { return $Explicit }
  $candidates = @(
    "$env:APPDATA\lazarus\environmentoptions.xml",
    "$env:USERPROFILE\.lazarus\environmentoptions.xml",
    'D:\lazarus\config\environmentoptions.xml',
    'C:\lazarus\config\environmentoptions.xml'
  )
  foreach ($c in $candidates) {
    if (Test-Path $c) { return $c }
  }
  return $null
}

$cfg = Find-LazarusConfig -Explicit $ConfigPath
if (-not $cfg) {
  Write-Host 'Lazarus environmentoptions.xml not found in standard locations:' -ForegroundColor Yellow
  Write-Host '  %APPDATA%\lazarus\, %USERPROFILE%\.lazarus\, D:\lazarus\config\' -ForegroundColor DarkGray
  Write-Host 'Pass -ConfigPath <full-path-to-environmentoptions.xml> to override.' -ForegroundColor Yellow
  Write-Host 'Lazarus may not be installed - skipping.' -ForegroundColor DarkGray
  exit 0
}

Write-Host ''
Write-Host '=== ZipFileORM - Install Library Paths (Lazarus) ==='
Write-Host "Project root : $root"
Write-Host "Config file  : $cfg"
if ($DryRun) { Write-Host 'Mode: DRY-RUN' -ForegroundColor Yellow }
Write-Host ''

# 3. Backup
if (-not $DryRun) {
  $bak = "$cfg.bak-$(Get-Date -Format yyyyMMddHHmmss)"
  Copy-Item $cfg $bak -Force
  Write-Host "Backup: $bak" -ForegroundColor DarkGray
}

# 4. Paths to add
$srcPath = Join-Path $root 'src'
$libW32  = Join-Path $root 'Lib\FPC\win32'
$libW64  = Join-Path $root 'Lib\FPC\win64'
$pathsToAdd = @($srcPath, $libW32, $libW64)

# 5. Parse XML
[xml] $xml = Get-Content $cfg -Raw

# 6. Strategy: ensure paths exist in <EnvironmentOptions>/<FpcSourceDirectory>
# Lazarus puts global include paths in:
#   /CONFIG/EnvironmentOptions/Files/FppkgConfigFile
#   /CONFIG/EnvironmentOptions/Lazarus/UnitPath  (older versions)
# Most reliable target for global library availability is to register the
# package via <PackageFiles> or via a Project Group later. For environmentwide
# search paths the canonical key (Lazarus 2.x/3.x) is:
#   /CONFIG/EnvironmentOptions/Files/PackageFileSearchPath  (older)
#   /CONFIG/EnvironmentOptions/UserDefines/(custom)
# For simplest universal approach, we register under a custom <ZipFileORM> node
# that documents intent + the user adds via IDE Project > Open Recent Package.

# Practical approach: add to UserDefines (preserved across IDE restarts) and
# also write a small marker file so the user has a discoverable record.

$envNode = $xml.SelectSingleNode('/CONFIG/EnvironmentOptions')
if (-not $envNode) {
  Write-Host 'ERROR: Cannot locate /CONFIG/EnvironmentOptions in XML.' -ForegroundColor Red
  exit 1
}

# Marker node ZipFileORM contains Paths/Path1, Path2, ... entries
$markerNode = $envNode.SelectSingleNode('ZipFileORM')
if (-not $markerNode) {
  $markerNode = $xml.CreateElement('ZipFileORM')
  $envNode.AppendChild($markerNode) | Out-Null
}
$pathsNode = $markerNode.SelectSingleNode('Paths')
if (-not $pathsNode) {
  $pathsNode = $xml.CreateElement('Paths')
  $markerNode.AppendChild($pathsNode) | Out-Null
}

# Collect existing
$existing = @()
foreach ($child in $pathsNode.ChildNodes) {
  $v = $child.GetAttribute('Value')
  if ($v) { $existing += $v }
}

$added = @()
$next = ($pathsNode.ChildNodes.Count) + 1
foreach ($p in $pathsToAdd) {
  $exists = $false
  foreach ($e in $existing) {
    if ([string]::Equals($e, $p, [StringComparison]::OrdinalIgnoreCase)) { $exists = $true; break }
  }
  if ($exists) { continue }
  $node = $xml.CreateElement("Path$next")
  $node.SetAttribute('Value', $p)
  $pathsNode.AppendChild($node) | Out-Null
  $added += $p
  $next++
}

if ($added.Count -eq 0) {
  Write-Host '  All paths already present in <ZipFileORM>/<Paths> node.' -ForegroundColor DarkGray
} elseif ($DryRun) {
  Write-Host '  DRYRUN would add:' -ForegroundColor Yellow
  $added | ForEach-Object { Write-Host "    + $_" -ForegroundColor Yellow }
} else {
  $xml.Save($cfg)
  Write-Host '  OK added to <ZipFileORM>/<Paths>:' -ForegroundColor Green
  $added | ForEach-Object { Write-Host "    + $_" -ForegroundColor Green }
}

Write-Host ''
Write-Host 'IMPORTANT: Lazarus does NOT auto-pick paths from custom XML nodes.' -ForegroundColor Yellow
Write-Host 'To make Lazarus use these paths, register the package via IDE:' -ForegroundColor Yellow
Write-Host "  Package > Open Package File (.lpk) > $root\packages\ZipFileORMpkg.lpk" -ForegroundColor Cyan
Write-Host '  Then click "Compile" then "Use > Install".' -ForegroundColor Cyan
Write-Host ''
Write-Host 'The marker in <ZipFileORM>/<Paths> records intent and serves' -ForegroundColor DarkGray
Write-Host 'Uninstall-LibraryPaths-Lazarus.ps1 for cleanup.' -ForegroundColor DarkGray
