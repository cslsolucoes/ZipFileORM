#requires -Version 5.1
<#
.SYNOPSIS
  Reverts source file renames and content changes made by Rename-ZipFileToORM.ps1.
  Keeps package infrastructure names (ZipFileORMD*.dpk etc.) but restores
  source unit names, class names, and filenames to original ZipFile/zipfile state.

  Scope:
  - Phase 1: Revert content in source .pas files (src/, tests/, testcase/, example/, reg files)
  - Phase 2: Rename source files back to original names
  - Phase 3: Fix .dpk/.lpk unit references to point to original source names
  - Phase 4: Fix CLAUDE.md / README.md class name references (TZipFileORM -> TZipFile)
#>

[CmdletBinding(SupportsShouldProcess)]
param([switch]$DryRun)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot   # zipfile/ root

# ---------------------------------------------------------------------------
# Helper: write file UTF-8 no BOM
# ---------------------------------------------------------------------------
function Save-File([string]$path, [string]$text) {
    $enc = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($path, $text, $enc)
}

# ---------------------------------------------------------------------------
# Phase 1: Reverse content substitutions in SOURCE .pas files
# These are in src/, tests/, testcase/, example/, and the two reg/pkg files.
# Substitutions applied in reverse order of the original forward passes.
# ---------------------------------------------------------------------------
Write-Host "=== Phase 1: Revert content in source files ===" -ForegroundColor Cyan

function Revert-SourceContent([string]$text) {
    # Compound names first (prevent partial double-match)
    $text = $text -creplace 'ZipFileORMReg',  'zipfileReg'
    $text = $text -creplace 'ZipFileORMpkg',  'zipfilepkg'
    $text = $text -creplace 'ZipFileORMPkg',  'ZipFilePkg'    # Lazarus wrapper unit
    $text = $text -creplace 'ZipFileORMTests','ZipFileTests'
    $text = $text -creplace 'ZipFileORM_',    'zipfile_'
    $text = $text -creplace 'ZipFileORM-',    'zipfile-'

    # Class / exception names
    $text = $text -creplace 'TZipFileORM', 'TZipFile'
    $text = $text -creplace 'EZipFileORM', 'EZipFile'

    # Unit declarations
    $text = $text -creplace 'unit ZipFileORM;', 'unit ZipFile;'

    # Namespace prefix ZipFileORM. -> ZipFile. (covers uses clauses, type refs, file paths in comments)
    $text = $text -creplace 'ZipFileORM\.', 'ZipFile.'

    # Standalone ZipFileORM (not preceded or followed by word chars or dot)
    $text = $text -creplace '(?<![.\w])ZipFileORM(?![.\w])', 'ZipFile'

    return $text
}

# Source dirs to process
$sourceDirs = @(
    (Join-Path $root 'src'),
    (Join-Path $root 'tests'),
    (Join-Path $root 'testcase'),
    (Join-Path $root 'example')
)
$srcRegFiles = @(
    (Join-Path $root 'packages\ZipFileORMReg.pas'),
    (Join-Path $root 'packages\ZipFileORMpkg.pas')
)
$srcExts = @('*.pas','*.dpr','*.lpr','*.lpi')

$changed = 0
foreach ($dir in $sourceDirs) {
    if (-not (Test-Path $dir)) { continue }
    foreach ($ext in $srcExts) {
        Get-ChildItem $dir -Filter $ext -File | ForEach-Object {
            $raw = [System.IO.File]::ReadAllText($_.FullName)
            $updated = Revert-SourceContent $raw
            if ($updated -ne $raw) {
                $rel = $_.FullName.Replace($root, '.')
                if ($DryRun) { Write-Host "  [DRY] $rel" }
                else { Save-File $_.FullName $updated; Write-Host "  UPDATED: $rel" -ForegroundColor Green }
                $changed++
            }
        }
    }
}
foreach ($f in $srcRegFiles) {
    if (-not (Test-Path $f)) { continue }
    $raw = [System.IO.File]::ReadAllText($f)
    $updated = Revert-SourceContent $raw
    if ($updated -ne $raw) {
        $rel = $f.Replace($root, '.')
        if ($DryRun) { Write-Host "  [DRY] $rel" }
        else { Save-File $f $updated; Write-Host "  UPDATED: $rel" -ForegroundColor Green }
        $changed++
    }
}
Write-Host "Phase 1 done: $changed files updated.`n" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Phase 2: Rename source files back to original names
# ---------------------------------------------------------------------------
Write-Host "=== Phase 2: Rename source files ===" -ForegroundColor Cyan

$renames = @(
    # src/ ZipFile.* sub-units
    @{ From = 'src\ZipFileORM.Events.pas';          To = 'src\ZipFile.Events.pas' }
    @{ From = 'src\ZipFileORM.UTF8.pas';             To = 'src\ZipFile.UTF8.pas' }
    @{ From = 'src\ZipFileORM.ZIP64.pas';            To = 'src\ZipFile.ZIP64.pas' }
    @{ From = 'src\ZipFileORM.Encryption.AES.pas';   To = 'src\ZipFile.Encryption.AES.pas' }
    @{ From = 'src\ZipFileORM.Compression.LZMA.pas'; To = 'src\ZipFile.Compression.LZMA.pas' }
    @{ From = 'src\ZipFileORM.Streaming.pas';        To = 'src\ZipFile.Streaming.pas' }
    @{ From = 'src\ZipFileORM.Fluent.pas';           To = 'src\ZipFile.Fluent.pas' }
    @{ From = 'src\ZipFileORM.Progress.pas';         To = 'src\ZipFile.Progress.pas' }
    # src/ main unit (zipfile, lowercase)
    @{ From = 'src\ZipFileORM.pas';                  To = 'src\zipfile.pas' }

    # tests/ DUnitX units
    @{ From = 'tests\ZipFileORM.Tests.AES.pas';      To = 'tests\ZipFile.Tests.AES.pas' }
    @{ From = 'tests\ZipFileORM.Tests.Core.pas';     To = 'tests\ZipFile.Tests.Core.pas' }
    @{ From = 'tests\ZipFileORM.Tests.Fluent.pas';   To = 'tests\ZipFile.Tests.Fluent.pas' }
    @{ From = 'tests\ZipFileORM.Tests.FluentInline.pas'; To = 'tests\ZipFile.Tests.FluentInline.pas' }
    @{ From = 'tests\ZipFileORM.Tests.LZMA.pas';     To = 'tests\ZipFile.Tests.LZMA.pas' }
    @{ From = 'tests\ZipFileORM.Tests.Progress.pas'; To = 'tests\ZipFile.Tests.Progress.pas' }
    @{ From = 'tests\ZipFileORM.Tests.Shared.pas';   To = 'tests\ZipFile.Tests.Shared.pas' }
    @{ From = 'tests\ZipFileORM.Tests.Streaming.pas';To = 'tests\ZipFile.Tests.Streaming.pas' }
    @{ From = 'tests\ZipFileORM.Tests.Tar.pas';      To = 'tests\ZipFile.Tests.Tar.pas' }
    @{ From = 'tests\ZipFileORM.Tests.UTF8.pas';     To = 'tests\ZipFile.Tests.UTF8.pas' }
    @{ From = 'tests\ZipFileORM.Tests.Zip64.pas';    To = 'tests\ZipFile.Tests.Zip64.pas' }
    @{ From = 'tests\ZipFileORM.Tests.Zip64Write.pas';To = 'tests\ZipFile.Tests.Zip64Write.pas' }
    @{ From = 'tests\ZipFileORMTestsD29.dpr';        To = 'tests\ZipFileTestsD29.dpr' }

    # testcase/ FPCUnit
    @{ From = 'testcase\ZipFileORM_tc.pas';              To = 'testcase\zipfile_tc.pas' }
    @{ From = 'testcase\ZipFileORM_testsuitegui.lpi';    To = 'testcase\zipfile_testsuitegui.lpi' }
    @{ From = 'testcase\ZipFileORM_testsuitegui.lpr';    To = 'testcase\zipfile_testsuitegui.lpr' }

    # packages/ registration + Lazarus wrapper
    @{ From = 'packages\ZipFileORMReg.pas';          To = 'packages\zipfileReg.pas' }
    @{ From = 'packages\ZipFileORMpkg.pas';          To = 'packages\zipfilepkg.pas' }
)

$renamed = 0
foreach ($pair in $renames) {
    $from = Join-Path $root $pair.From
    $to   = Join-Path $root $pair.To
    if (Test-Path $from) {
        if ($DryRun) {
            Write-Host "  [DRY] $($pair.From) -> $($pair.To)"
        } else {
            Rename-Item -Path $from -NewName (Split-Path $to -Leaf) -Force
            Write-Host "  RENAMED: $($pair.From) -> $($pair.To)" -ForegroundColor Yellow
        }
        $renamed++
    } else {
        Write-Host "  SKIP (not found): $($pair.From)" -ForegroundColor DarkGray
    }
}
Write-Host "Phase 2 done: $renamed files renamed.`n" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Phase 3: Fix .dpk and .lpk unit references
# Keep package names/descriptions (ZipFileORMD*, ZipFileORMPkg) but
# fix contains/unit references to point to the original source names.
# ---------------------------------------------------------------------------
Write-Host "=== Phase 3: Fix package file unit references ===" -ForegroundColor Cyan

function Fix-PackageContent([string]$text) {
    # 1. Registration file reference in dclZipFileORM*.dpk
    $text = $text -creplace "ZipFileORMReg in 'ZipFileORMReg\.pas'", "zipfileReg in 'zipfileReg.pas'"

    # 2. Main unit reference: ZipFileORM in '..\src\ZipFileORM.pas'
    #    (must run before the generic ZipFileORM. rule so ZipFileORM.pas -> zipfile.pas not ZipFile.pas)
    $text = $text -creplace "ZipFileORM in '\.\.\\src\\ZipFileORM\.pas'", "zipfile in '..\src\zipfile.pas'"

    # 3. Sub-unit namespace prefix: ZipFileORM. -> ZipFile. (unit names and file paths like ZipFileORM.UTF8.pas)
    $text = $text -creplace 'ZipFileORM\.', 'ZipFile.'

    # 4. .lpk XML: main unit filename attribute
    $text = $text -creplace '<Filename Value="\.\.\\src\\ZipFileORM\.pas"/>', '<Filename Value="..\src\zipfile.pas"/>'

    # 5. .lpk XML: main unit name attribute
    $text = $text -creplace '<UnitName Value="ZipFileORM"/>', '<UnitName Value="ZipFile"/>'

    return $text
}

$pkgExts = @('*.dpk','*.lpk')
$pkgDir  = Join-Path $root 'packages'
$pkgChanged = 0
foreach ($ext in $pkgExts) {
    Get-ChildItem $pkgDir -Filter $ext -File | ForEach-Object {
        $raw = [System.IO.File]::ReadAllText($_.FullName)
        $updated = Fix-PackageContent $raw
        if ($updated -ne $raw) {
            $rel = $_.FullName.Replace($root, '.')
            if ($DryRun) { Write-Host "  [DRY] $rel" }
            else { Save-File $_.FullName $updated; Write-Host "  UPDATED: $rel" -ForegroundColor Green }
            $pkgChanged++
        }
    }
}
Write-Host "Phase 3 done: $pkgChanged package files updated.`n" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Phase 4: Fix documentation files (CLAUDE.md, README.md)
# TZipFileORM -> TZipFile (class name - not a project name reference)
# ---------------------------------------------------------------------------
Write-Host "=== Phase 4: Fix documentation class name references ===" -ForegroundColor Cyan

$docFiles = @(
    (Join-Path $root 'CLAUDE.md'),
    (Join-Path $root 'README.md')
)
$docChanged = 0
foreach ($f in $docFiles) {
    if (-not (Test-Path $f)) { continue }
    $raw = [System.IO.File]::ReadAllText($f)
    $updated = $raw -creplace 'TZipFileORM', 'TZipFile'
    if ($updated -ne $raw) {
        $rel = $f.Replace($root, '.')
        if ($DryRun) { Write-Host "  [DRY] $rel" }
        else { Save-File $f $updated; Write-Host "  UPDATED: $rel" -ForegroundColor Green }
        $docChanged++
    }
}
Write-Host "Phase 4 done: $docChanged doc files updated.`n" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host "=== Done ===" -ForegroundColor Green
Write-Host "Source content reverts: $changed  |  File renames: $renamed  |  Package fixes: $pkgChanged  |  Doc fixes: $docChanged"
if ($DryRun) { Write-Host "(DRY RUN - no files modified)" -ForegroundColor Yellow }
