# Build-Bzip2Objs.ps1
# Compila o BZIP2 1.1.0-dev SDK (sdk/bzip2/) para 4 toolchains:
#   - Win32 OMF via bcc32c (BCC102 ou D29 freeware)
#   - Win64 ELF via bcc64 (D37)
#   - FPC Win32 COFF via mingw-w64 -m32
#   - FPC Win64 COFF via mingw-w64 -m64
#
# Output: Lib/bzip2_obj_{win32,win64,fpc_win32,fpc_win64}/BzipCombined.{obj,o}
# Linkados em src/Bzip2.Bzip2Stream.pas via {$L ..\Library\<toolchain>\BzipCombined.<ext>}
#
# Bzip2 BZ_API = WINAPI = __stdcall em Win32 (bzlib.h linha 88). bcc32c emite
# symbol sem prefixo `_` em modo stdcall. Pascal precisa declarar `stdcall`,
# NAO cdecl (vide v3.8 fix em Bzip2.Bzip2Stream.pas).

$ErrorActionPreference = 'Stop'

$Root = Resolve-Path "$PSScriptRoot\.."
$Src  = Join-Path $Root 'sdk\bzip2'
$MingwGcc = Join-Path $Root 'deps\gcc-mingw-w64\bin\gcc.exe'

if (-not (Test-Path $Src)) {
    throw "BZIP2 SDK not found at $Src"
}

# ---- Win32 OMF via bcc32c -------------------------------------------------
$LocalBcc32 = Join-Path $Root 'BCC\bin\bcc32c.exe'
$ExtBcc32   = "C:\Users\Public\Documents\Embarcadero\Studio\Outros\Gnostice\BCC102\bin\bcc32c.exe"
$D29Bcc32   = "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\bcc32c.exe"
if (Test-Path $LocalBcc32) { $Bcc32 = $LocalBcc32 }
elseif (Test-Path $ExtBcc32) { $Bcc32 = $ExtBcc32 }
elseif (Test-Path $D29Bcc32) { $Bcc32 = $D29Bcc32 }
else { $Bcc32 = $null }

$Out32 = Join-Path $Root 'Library\delphi-win32'
if (Test-Path $Bcc32) {
    if (-not (Test-Path $Out32)) { New-Item -Path $Out32 -ItemType Directory | Out-Null }
    Push-Location $Src
    try {
        Write-Host "[Win32] Compiling BzipCombined.c (bcc32c OMF)..."
        & $Bcc32 -c -O2 -DBZ_NO_STDIO -o"$Out32\BzipCombined.obj" "BzipCombined.c"
        if ($LASTEXITCODE -ne 0) { throw "bcc32c BzipCombined.c failed" }
    } finally { Pop-Location }
    Write-Host "Done Win32. $(Get-Item $Out32\BzipCombined.obj | Select-Object -ExpandProperty Length) bytes"
} else {
    Write-Warning "Skipped Win32 (bcc32c not found)"
}

# ---- Win64 ELF via bcc64 --------------------------------------------------
$Bcc64 = "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\bcc64.exe"
$LocalSdk  = Join-Path $Root 'deps\win64\include\sdk'
$LocalCrtl = Join-Path $Root 'deps\win64\include\crtl'
$Out64 = Join-Path $Root 'Library\delphi-win64'

if ((Test-Path $Bcc64) -and (Test-Path $LocalSdk)) {
    if (-not (Test-Path $Out64)) { New-Item -Path $Out64 -ItemType Directory | Out-Null }
    Push-Location $Src
    try {
        # -DBZ_NO_STDIO desabilita fopen/fprintf paths (so usamos BuffToBuff).
        # -fno-zero-initialized-in-bss para .bss → .data (limitacao bcc64 ELF).
        Write-Host "[Win64] Compiling BzipCombined.c (bcc64 ELF)..."
        & $Bcc64 -c -O2 -DBZ_NO_STDIO -fno-zero-initialized-in-bss -I"$LocalSdk" -I"$LocalCrtl" -o"$Out64\BzipCombined.o" "BzipCombined.c"
        if ($LASTEXITCODE -ne 0) { throw "bcc64 BzipCombined.c failed" }
    } finally { Pop-Location }
    Write-Host "Done Win64. $(Get-Item $Out64\BzipCombined.o | Select-Object -ExpandProperty Length) bytes"
} else {
    Write-Warning "Skipped Win64 (bcc64 ou SDK headers nao encontrados)"
}

# ---- FPC Win32+Win64 COFF via mingw-w64 -----------------------------------
if (Test-Path $MingwGcc) {
    $FpcOut32 = Join-Path $Root 'Library\fpc-win32'
    $FpcOut64 = Join-Path $Root 'Library\fpc-win64'
    if (-not (Test-Path $FpcOut32)) { New-Item -Path $FpcOut32 -ItemType Directory | Out-Null }
    if (-not (Test-Path $FpcOut64)) { New-Item -Path $FpcOut64 -ItemType Directory | Out-Null }
    Push-Location $Src
    try {
        Write-Host "[FPC Win32] Compiling BzipCombined.c (mingw -m32)..."
        & $MingwGcc -c -O2 -m32 -DBZ_NO_STDIO -o"$FpcOut32\BzipCombined.o" "BzipCombined.c"
        if ($LASTEXITCODE -ne 0) { throw "mingw -m32 failed" }
        Write-Host "[FPC Win64] Compiling BzipCombined.c (mingw -m64)..."
        & $MingwGcc -c -O2 -m64 -DBZ_NO_STDIO -o"$FpcOut64\BzipCombined.o" "BzipCombined.c"
        if ($LASTEXITCODE -ne 0) { throw "mingw -m64 failed" }
    } finally { Pop-Location }
    Write-Host "Done FPC COFF."
} else {
    Write-Warning "Skipped FPC (mingw-w64 gcc not found)"
}

Write-Host ""
Write-Host "=== bzip2 Build Summary ==="
@('bzip2_obj_win32','bzip2_obj_win64','bzip2_obj_fpc_win32','bzip2_obj_fpc_win64') | ForEach-Object {
    $d = Join-Path $Root "Lib\$_"
    if (Test-Path $d) {
        Get-ChildItem $d | Select-Object @{N='Dir';E={$_}}, Name, Length
    }
}
