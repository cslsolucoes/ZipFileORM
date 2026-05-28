#requires -Version 5.1
<#
.SYNOPSIS
  Compila tests/smoke_linux.pas para todos targets FPC suportados (Windows
  i386/x86_64, Linux i386/x86_64). Reporta resultado de cada um.

.NOTES
  Requer FPC instalado em D:\fpc\fpc\bin\ (4 targets pre-built nos units/).
  Cada target precisa de -Fu para rtl-objpas (StrUtils) — fpc.cfg `*` glob
  nao pega esse subfolder automaticamente.
#>

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$tests = Join-Path $root 'tests'
$src = Join-Path $root 'src'

$fpcRoot = 'D:\fpc\fpc'
$bin = "$fpcRoot\bin"
$unitsRoot = "$fpcRoot\units"
$mingwW64Lib = Join-Path $root 'deps\gcc-mingw-w64\x86_64-w64-mingw32\lib'
$mingwW32Lib = Join-Path $root 'deps\gcc-mingw-w64\i686-w64-mingw32\lib'
# libgcc.a (gcc internals 64-bit math helpers __moddi3/__udivdi3) — paths multilib
$mingwGccW32 = Join-Path $root 'deps\gcc-mingw-w64\x86_64-w64-mingw32\lib\gcc\x86_64-w64-mingw32\16.1.0\32'
$mingwGccW64 = Join-Path $root 'deps\gcc-mingw-w64\x86_64-w64-mingw32\lib\gcc\x86_64-w64-mingw32\16.1.0'

# Targets para smoke_linux.pas (ZIP core) + smoke_cab_fpc.pas (CAB FPC Windows)
$targets = @(
  @{ Name='Win32 i386';     Compiler="$bin\i386-win32\ppc386.exe"; Args=@('-TWin32');                Subdir='i386-win32';    Pas='smoke_linux.pas';     OutExe='smoke_linux.exe';     LibDir=$mingwW32Lib }
  @{ Name='Win64 x86_64';   Compiler="$bin\x86_64-win64\ppcx64.exe"; Args=@('-TWin64','-Px86_64');  Subdir='x86_64-win64';  Pas='smoke_linux.pas';     OutExe='smoke_linux.exe';     LibDir=$mingwW64Lib }
  @{ Name='Linux x86_64';   Compiler="$bin\x86_64-win64\ppcx64.exe"; Args=@('-Tlinux','-Px86_64'); Subdir='x86_64-linux';  Pas='smoke_linux.pas';     OutExe='smoke_linux';         LibDir=$null }
  @{ Name='Linux i386';     Compiler="$bin\x86_64-win64\ppcross386.exe"; Args=@('-Tlinux','-Pi386'); Subdir='i386-linux';  Pas='smoke_linux.pas';     OutExe='smoke_linux';         LibDir=$null }
  @{ Name='CAB Win32 i386'; Compiler="$bin\i386-win32\ppc386.exe"; Args=@('-TWin32');                Subdir='i386-win32';    Pas='smoke_cab_fpc.pas';     OutExe='smoke_cab_fpc.exe';     LibDir=$mingwW32Lib; GccLibDir=$mingwGccW32 }
  @{ Name='CAB Win64 x86_64'; Compiler="$bin\x86_64-win64\ppcx64.exe"; Args=@('-TWin64','-Px86_64'); Subdir='x86_64-win64';  Pas='smoke_cab_fpc.pas';     OutExe='smoke_cab_fpc.exe';     LibDir=$mingwW64Lib; GccLibDir=$mingwGccW64 }
  @{ Name='CAB WRITE Win32'; Compiler="$bin\i386-win32\ppc386.exe"; Args=@('-TWin32');                Subdir='i386-win32';    Pas='smoke_cab_write_fpc.pas'; OutExe='smoke_cab_write_fpc.exe'; LibDir=$mingwW32Lib; GccLibDir=$mingwGccW32 }
  @{ Name='CAB WRITE Win64'; Compiler="$bin\x86_64-win64\ppcx64.exe"; Args=@('-TWin64','-Px86_64'); Subdir='x86_64-win64';  Pas='smoke_cab_write_fpc.pas'; OutExe='smoke_cab_write_fpc.exe'; LibDir=$mingwW64Lib; GccLibDir=$mingwGccW64 }
  # v3.6: LZMA FPC mingw COFF
  @{ Name='LZMA FPC Win32'; Compiler="$bin\i386-win32\ppc386.exe"; Args=@('-TWin32');                Subdir='i386-win32';    Pas='smoke_lzma_fpc.pas';      OutExe='smoke_lzma_fpc.exe';      LibDir=$mingwW32Lib }
  @{ Name='LZMA FPC Win64'; Compiler="$bin\x86_64-win64\ppcx64.exe"; Args=@('-TWin64','-Px86_64'); Subdir='x86_64-win64';  Pas='smoke_lzma_fpc.pas';      OutExe='smoke_lzma_fpc.exe';      LibDir=$mingwW64Lib }
  # v3.11: ISO 9660 pure-pascal (sem C dep)
  @{ Name='ISO FPC Win32';  Compiler="$bin\i386-win32\ppc386.exe"; Args=@('-TWin32');                Subdir='i386-win32';    Pas='smoke_iso_fpc.pas';       OutExe='smoke_iso_fpc.exe';       LibDir=$null }
  @{ Name='ISO FPC Win64';  Compiler="$bin\x86_64-win64\ppcx64.exe"; Args=@('-TWin64','-Px86_64'); Subdir='x86_64-win64';  Pas='smoke_iso_fpc.pas';       OutExe='smoke_iso_fpc.exe';       LibDir=$null }
  @{ Name='ISO FPC Linux64'; Compiler="$bin\x86_64-win64\ppcx64.exe"; Args=@('-Tlinux','-Px86_64'); Subdir='x86_64-linux';  Pas='smoke_iso_fpc.pas';       OutExe='smoke_iso_fpc';           LibDir=$null }
  # v3.3: LHA pure-pascal (Store -lh0- only)
  @{ Name='LHA FPC Win32';  Compiler="$bin\i386-win32\ppc386.exe"; Args=@('-TWin32');                Subdir='i386-win32';    Pas='smoke_lha_fpc.pas';       OutExe='smoke_lha_fpc.exe';       LibDir=$null }
  @{ Name='LHA FPC Win64';  Compiler="$bin\x86_64-win64\ppcx64.exe"; Args=@('-TWin64','-Px86_64'); Subdir='x86_64-win64';  Pas='smoke_lha_fpc.pas';       OutExe='smoke_lha_fpc.exe';       LibDir=$null }
  @{ Name='LHA FPC Linux64'; Compiler="$bin\x86_64-win64\ppcx64.exe"; Args=@('-Tlinux','-Px86_64'); Subdir='x86_64-linux';  Pas='smoke_lha_fpc.pas';       OutExe='smoke_lha_fpc';           LibDir=$null }
  # v3.4: ARJ pure-pascal (method 0 only)
  @{ Name='ARJ FPC Win32';  Compiler="$bin\i386-win32\ppc386.exe"; Args=@('-TWin32');                Subdir='i386-win32';    Pas='smoke_arj_fpc.pas';       OutExe='smoke_arj_fpc.exe';       LibDir=$null }
  @{ Name='ARJ FPC Win64';  Compiler="$bin\x86_64-win64\ppcx64.exe"; Args=@('-TWin64','-Px86_64'); Subdir='x86_64-win64';  Pas='smoke_arj_fpc.pas';       OutExe='smoke_arj_fpc.exe';       LibDir=$null }
  @{ Name='ARJ FPC Linux64'; Compiler="$bin\x86_64-win64\ppcx64.exe"; Args=@('-Tlinux','-Px86_64'); Subdir='x86_64-linux';  Pas='smoke_arj_fpc.pas';       OutExe='smoke_arj_fpc';           LibDir=$null }
  # v3.5: RAR5 pure-pascal (method 0 only)
  @{ Name='RAR FPC Win32';  Compiler="$bin\i386-win32\ppc386.exe"; Args=@('-TWin32');                Subdir='i386-win32';    Pas='smoke_rar_fpc.pas';       OutExe='smoke_rar_fpc.exe';       LibDir=$null }
  @{ Name='RAR FPC Win64';  Compiler="$bin\x86_64-win64\ppcx64.exe"; Args=@('-TWin64','-Px86_64'); Subdir='x86_64-win64';  Pas='smoke_rar_fpc.pas';       OutExe='smoke_rar_fpc.exe';       LibDir=$null }
  @{ Name='RAR FPC Linux64'; Compiler="$bin\x86_64-win64\ppcx64.exe"; Args=@('-Tlinux','-Px86_64'); Subdir='x86_64-linux';  Pas='smoke_rar_fpc.pas';       OutExe='smoke_rar_fpc';           LibDir=$null }
)

Push-Location $tests
$results = @()
foreach ($t in $targets) {
  Write-Host ("=== FPC {0} ===" -f $t.Name)
  if (-not (Test-Path $t.Compiler)) {
    Write-Host "  SKIP (compiler not found: $($t.Compiler))" -ForegroundColor Yellow
    $results += [pscustomobject]@{ Target=$t.Name; Status='SKIP'; Note='no compiler' }
    continue
  }
  Remove-Item $t.OutExe -ErrorAction SilentlyContinue
  $rtlObjpas = Join-Path $unitsRoot "$($t.Subdir)\rtl-objpas"
  $extraArgs = @()
  if (Test-Path $rtlObjpas) { $extraArgs += "-Fu$rtlObjpas" }
  if ($t.LibDir -and (Test-Path $t.LibDir)) { $extraArgs += "-Fl$($t.LibDir)" }
  if ($t.GccLibDir -and (Test-Path $t.GccLibDir)) { $extraArgs += "-Fl$($t.GccLibDir)" }
  $argList = $t.Args + @("-Fu$src") + $extraArgs + @($t.Pas)
  $log = & $t.Compiler @argList 2>&1
  $ec = $LASTEXITCODE
  $okBuild = ($ec -eq 0) -and (Test-Path $t.OutExe)
  if (-not $okBuild) {
    Write-Host "  BUILD FAIL (exit $ec)" -ForegroundColor Red
    $log | Select-String -Pattern 'Error|Fatal' | Select-Object -First 3 | ForEach-Object { Write-Host "    $_" }
    $results += [pscustomobject]@{ Target=$t.Name; Status='BUILD FAIL'; Note="exit $ec" }
    continue
  }
  $size = (Get-Item $t.OutExe).Length
  Write-Host ("  BUILD OK ({0} B)" -f $size) -ForegroundColor Green
  $results += [pscustomobject]@{ Target=$t.Name; Status='BUILD OK'; Note="$size B" }
}
Pop-Location

Write-Host ""
Write-Host "=== Summary ==="
$results | Format-Table -AutoSize
