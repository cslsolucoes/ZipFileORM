# Build-LzmaObjs.ps1
# Compila o subconjunto LZMA do SDK 24.07 (em ../sdk/lzma2601/C/) para .obj
# OMF Win32 via bcc32c.exe (Embarcadero C++ 10.2 Tokyo command-line freeware,
# em C:\Users\Public\Documents\Embarcadero\Studio\Outros\Gnostice\BCC102\).
#
# Saida: ../Lib/lzma_obj_win32/{LzmaDec,LzmaEnc,LzFind,Alloc,LzmaStubsST}.obj
# Esses .obj sao linkados estaticamente em src/ZipFileORM.Compression.LZMA.pas
# via {$L ..\Library\delphi-win32\X.obj}.
#
# Re-executar este script se atualizar o SDK ou patchear LzmaStubsST.c.

$ErrorActionPreference = 'Stop'

$Root = Resolve-Path "$PSScriptRoot\.."
$Src  = Join-Path $Root 'sdk\lzma2601\C'
$CabSrc = Join-Path $Root 'sdk\cabnet'
$MingwGcc = Join-Path $Root 'deps\gcc-mingw-w64\bin\gcc.exe'

# ---- Win32 OMF via bcc32c (vendored em ZipFileORM/BCC/, fallback BCC102) ----
$LocalBcc32 = Join-Path $Root 'BCC\bin\bcc32c.exe'
$ExtBcc32   = "C:\Users\Public\Documents\Embarcadero\Studio\Outros\Gnostice\BCC102\bin\bcc32c.exe"
if (Test-Path $LocalBcc32) {
    $Bcc32 = $LocalBcc32
    Write-Host "[Win32] Using vendored BCC\bin\bcc32c.exe"
} elseif (Test-Path $ExtBcc32) {
    $Bcc32 = $ExtBcc32
    Write-Host "[Win32] Using external BCC102 (vendored BCC/ not found)"
} else {
    $Bcc32 = $null
    Write-Warning "Neither vendored BCC/bin/bcc32c.exe nor BCC102 found."
}
$Out32 = Join-Path $Root 'Library\delphi-win32'

if (Test-Path $Bcc32) {
    if (-not (Test-Path $Out32)) {
        New-Item -Path $Out32 -ItemType Directory | Out-Null
    }
    Push-Location $Src
    try {
        # LZMA core (v2.1) + 7z container (v3.1) + dependencies
        # NB: 7zArcIn.c + 7zDec.c sao COMBINADOS em SevenZCombined.c (mutual
        # deps inviabilizam dois OBJs separados no linker Delphi single-pass).
        $Win32Sources = @(
            'LzmaDec.c', 'LzmaEnc.c', 'LzFind.c', 'Alloc.c', 'LzmaStubsST.c',
            # v3.1 7zip READ — container parser + decoders (combinados)
            '7zAlloc.c', 'SevenZCombined.c', '7zBuf.c', '7zBuf2.c', '7zCrc.c',
            '7zCrcOpt.c', '7zStream.c',
            # 7z compression filters (executables BCJ/BCJ2; data Delta; LZMA2)
            'Bra.c', 'Bra86.c', 'BraIA64.c', 'Bcj2.c', 'Delta.c', 'Lzma2Dec.c',
            # v3.1.3 LZMA2 ENCODER (para 7zip WRITE LZMA2 method 0x21)
            'Lzma2Enc.c',
            # 7z encryption (AES + SHA256 for AES key derivation)
            'Aes.c', 'AesOpt.c', 'Sha256.c', 'Sha256Opt.c',
            # CpuArch needed by AesOpt + CRC accel detection
            'CpuArch.c',
            # v3.1: SevenZWrapper.c — Pascal-facing API minimalista
            '7zFile.c', 'SevenZWrapper.c'
        )
        # v3.1.3: -DZ7_ST single-thread strip do MtCoder (Lzma2Enc.c usa
        # MtCoder mesmo em path memory-to-memory; sem Z7_ST, .o referencia
        # MtCoder_Code/Construct/Destruct que nao temos linkados).
        foreach ($SrcFile in $Win32Sources) {
            $ObjName = ($SrcFile -replace '\.c$', '.obj')
            $ObjPath = Join-Path $Out32 $ObjName
            Write-Host "[Win32] Compiling $SrcFile -> $ObjName"
            & $Bcc32 -c -O2 -D_7ZIP_ST -DZ7_ST -o"$ObjPath" $SrcFile
            if ($LASTEXITCODE -ne 0) {
                throw "bcc32c failed for $SrcFile (exit $LASTEXITCODE)"
            }
        }
    } finally {
        Pop-Location
    }
    Write-Host "Done Win32. Output in $Out32 :"
    Get-ChildItem $Out32 -Filter *.obj | Format-Table Name, Length

    # ---- v3.7: CAB Win32 OMF — usa D29 bcc32c + D29 Win SDK headers ----------
    # Embarcadero D29 (BDS 23.0) bcc32c.exe + headers tem winnt.h completo
    # (CONST/PCWSTR/etc) que o BCC102 freeware standalone nao tem. Necessario
    # para Wine cabinet fci.c/fdi.c que puxam <stdio.h> -> windows headers chain.
    $D29Bcc32 = "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\bcc32c.exe"
    $D29Inc   = "C:\Program Files (x86)\Embarcadero\Studio\23.0\include\windows"
    $CabOut32 = Join-Path $Root 'Library\delphi-win32'
    $CabCompat = Join-Path $CabSrc 'compat'
    $ZlibSrc  = Join-Path $Root 'sdk\zlib'
    if ((Test-Path $D29Bcc32) -and (Test-Path $D29Inc) -and (Test-Path $CabSrc)) {
        if (-not (Test-Path $CabOut32)) { New-Item -Path $CabOut32 -ItemType Directory | Out-Null }
        Push-Location $CabSrc
        try {
            $D29WinH = "$D29Inc\sdk\windows.h"
            # fdi.c (decoder) — nao precisa zlib (decompress eh manual)
            Write-Host "[CAB Win32] Compiling fdi.c (decoder)..."
            & $D29Bcc32 -c -O2 -D_X86_ "-I$D29Inc\sdk" "-I$D29Inc\crtl" "-I$CabCompat" "-I$CabSrc" "-o$CabOut32\fdi.obj" "fdi.c"
            if ($LASTEXITCODE -ne 0) { throw "fdi.c failed" }
            # fci.c (encoder) — precisa zlib.h (vendored em sdk/zlib/)
            Write-Host "[CAB Win32] Compiling fci.c (encoder)..."
            & $D29Bcc32 -c -O2 -D_X86_ "-I$D29Inc\sdk" "-I$D29Inc\crtl" "-I$CabCompat" "-I$CabSrc" "-I$ZlibSrc" "-o$CabOut32\fci.obj" "fci.c"
            if ($LASTEXITCODE -ne 0) { throw "fci.c failed" }
            # cabinet_main.c — Win32 file IO helpers (CreateFileA etc.)
            Write-Host "[CAB Win32] Compiling cabinet_main.c (Win32 helpers)..."
            & $D29Bcc32 -c -O2 -D_X86_ "-D_O_ACCMODE=O_ACCMODE" "-include$D29WinH" "-I$D29Inc\sdk" "-I$D29Inc\crtl" "-I$CabCompat" "-I$CabSrc" "-o$CabOut32\cabinet_main.obj" "cabinet_main.c"
            if ($LASTEXITCODE -ne 0) { throw "cabinet_main.c failed" }
            # compressapi.c (LZMS) — opcional, deferido (precisa #include <windows.h>
            # explicito no source vendored; nao quebra build CAB core)
        } finally { Pop-Location }
        Write-Host "Done CAB Win32."
    } else {
        Write-Warning "Skipped CAB Win32 (D29 bcc32c or sdk/cabnet not found)"
    }

    # ---- v3.7 FPC: CAB COFF Win32+Win64 via mingw-w64 gcc 16.1 vendored ----
    # FPC linker rejeita COMDAT pervasivo do MSVC cl.exe; mingw-w64 gcc gera
    # COFF "limpo" (sem .pdata/.xdata/.debug$F COMDAT) que FPC aceita direto.
    if ((Test-Path $MingwGcc) -and (Test-Path $CabSrc)) {
        $CabShim   = Join-Path $CabSrc 'cabnet_shim.h'
        $CabFpcW64 = Join-Path $Root 'Library\fpc-win64'
        $CabFpcW32 = Join-Path $Root 'Library\fpc-win32'
        if (-not (Test-Path $CabFpcW64)) { New-Item -Path $CabFpcW64 -ItemType Directory | Out-Null }
        if (-not (Test-Path $CabFpcW32)) { New-Item -Path $CabFpcW32 -ItemType Directory | Out-Null }
        Push-Location $CabSrc
        try {
            Write-Host "[CAB FPC Win64] Compiling fdi.c (mingw-w64 -m64)..."
            & $MingwGcc -c -O2 -m64 -include $CabShim "-I$CabCompat" "-I$CabSrc" "-o$CabFpcW64\fdi.o" "fdi.c"
            if ($LASTEXITCODE -ne 0) { throw "mingw fdi.c Win64 failed" }
            Write-Host "[CAB FPC Win64] Compiling fci.c..."
            & $MingwGcc -c -O2 -m64 -include $CabShim "-I$CabCompat" "-I$CabSrc" "-I$ZlibSrc" "-o$CabFpcW64\fci.o" "fci.c"
            if ($LASTEXITCODE -ne 0) { throw "mingw fci.c Win64 failed" }
            Write-Host "[CAB FPC Win32] Compiling fdi.c (mingw-w64 -m32)..."
            & $MingwGcc -c -O2 -m32 -include $CabShim "-I$CabCompat" "-I$CabSrc" "-o$CabFpcW32\fdi.o" "fdi.c"
            if ($LASTEXITCODE -ne 0) { throw "mingw fdi.c Win32 failed" }
            Write-Host "[CAB FPC Win32] Compiling fci.c..."
            & $MingwGcc -c -O2 -m32 -include $CabShim "-I$CabCompat" "-I$CabSrc" "-I$ZlibSrc" "-o$CabFpcW32\fci.o" "fci.c"
            if ($LASTEXITCODE -ne 0) { throw "mingw fci.c Win32 failed" }
        } finally { Pop-Location }
        Write-Host "Done CAB FPC (mingw-w64 COFF Win32+Win64)."
    } else {
        Write-Warning "Skipped CAB FPC (mingw-w64 gcc at ZipFileORM/deps/gcc-mingw-w64/ not found)"
    }
} else {
    Write-Warning "Skipped Win32 build (bcc32c not found at $Bcc32)"
}

# ---- Win64 ELF via bcc64 (D37 7.80) ----------------------------------------
# Headers ficam consolidados em deps/win64/include/ (vendored) — independente
# da estrutura Embarcadero. Se quiser usar os caminhos Embarcadero originais
# (D28 sdk + D37 crtl), defina USE_EMBARCADERO_PATHS=1 no environment.
$Bcc64    = "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\bcc64.exe"
$Out64    = Join-Path $Root 'Library\delphi-win64'

# Preferencia: deps/ locais (vendored); fallback automatic para Embarcadero.
$LocalSdk  = Join-Path $Root 'deps\win64\include\sdk'
$LocalCrtl = Join-Path $Root 'deps\win64\include\crtl'
$EmbSdk    = "C:\Program Files (x86)\Embarcadero\Studio\22.0\include\windows\sdk"
$EmbCrtl   = "C:\Program Files (x86)\Embarcadero\Studio\37.0\include\windows\crtl"

if ($env:USE_EMBARCADERO_PATHS -eq '1') {
    $Sdk  = $EmbSdk
    $Crtl = $EmbCrtl
    Write-Host "[Win64] Using Embarcadero header paths (USE_EMBARCADERO_PATHS=1)"
} elseif ((Test-Path $LocalSdk) -and (Test-Path $LocalCrtl)) {
    $Sdk  = $LocalSdk
    $Crtl = $LocalCrtl
    Write-Host "[Win64] Using vendored deps\win64\include\ (default)"
} else {
    $Sdk  = $EmbSdk
    $Crtl = $EmbCrtl
    Write-Host "[Win64] deps/ not found; falling back to Embarcadero paths"
}

if (Test-Path $Bcc64) {
    if (-not (Test-Path $Sdk)) {
        Write-Warning "Win64 build needs SDK headers at $Sdk; skipping."
        return
    }
    if (-not (Test-Path $Out64)) {
        New-Item -Path $Out64 -ItemType Directory | Out-Null
    }
    Push-Location $Src
    try {
        # LZMA core (v2.2) + 7z container (v3.1) + dependencies + CpuArch
        # NB: 7zArcIn.c + 7zDec.c combinados em SevenZCombined.c (vide Win32).
        # v3.1.1 — substituido Aes.c + AesOpt.c por AesCombined.c (refs mutuas)
        # idem Sha256.c + Sha256Opt.c por Sha256Combined.c. Win64 ELF linker
        # bcc64/Delphi e single-pass; combinacao resolve refs internas.
        $Win64Sources = @(
            'LzmaDec.c', 'LzmaEnc.c', 'LzFind.c', 'Alloc.c', 'CpuArch.c', 'LzmaStubsST.c',
            # v3.1 7zip READ (combinados)
            '7zAlloc.c', 'SevenZCombined.c', '7zBuf.c', '7zBuf2.c', '7zCrc.c',
            '7zCrcOpt.c', '7zStream.c',
            'Bra.c', 'Bra86.c', 'BraIA64.c', 'Bcj2.c', 'Delta.c', 'Lzma2Dec.c',
            # v3.1.3 LZMA2 ENCODER
            'Lzma2Enc.c',
            # v3.1.1 — Aes/Sha256 combinados (mutual deps)
            'AesCombined.c', 'Sha256Combined.c',
            # v3.1: SevenZWrapper.c — Pascal-facing API
            '7zFile.c', 'SevenZWrapper.c'
        )
        # v3.1.1: -fno-zero-initialized-in-bss força globals zero-initialized
        # para .data em vez de .bss. Linker bcc64 ELF do Delphi rejeita seções
        # .bss (SHT_NOBITS) em OBJs que precisam ser linkados via {$L}. Sem
        # esse flag, 7zCrc.o (g_CrcTable + g_CrcUpdate) e qualquer outro com
        # globals não-inicializados emite "Bad object file format".
        #
        # v3.1.1: -DZ7_USE_AES_HW_STUB / -DZ7_USE_VAES_HW_STUB / -DZ7_USE_HW_SHA_STUB
        # geram wrappers `AesCbc_*_HW` / `Sha256_UpdateBlocks_HW` que delegam
        # para as variantes SW. Sem esses defines, bcc64 (clang predefine
        # `_MSC_VER` mas não dispara `Z7_LLVM_CLANG_VERSION` em todas as
        # gates de USE_INTEL_AES/USE_HW_SHA do SDK 24.07) deixa AesOpt.o e
        # Sha256Opt.o vazios — Aes.c/Sha256.c referenciam HW e quebram link.
        $W64Defines = @('-D_7ZIP_ST','-DZ7_ST','-DZ7_USE_AES_HW_STUB','-DZ7_USE_VAES_HW_STUB','-DZ7_USE_HW_SHA_STUB')
        foreach ($SrcFile in $Win64Sources) {
            $ObjName = ($SrcFile -replace '\.c$', '.o')
            $ObjPath = Join-Path $Out64 $ObjName
            Write-Host "[Win64] Compiling $SrcFile -> $ObjName"
            & $Bcc64 -c -O2 @W64Defines -fno-zero-initialized-in-bss -I"$Sdk" -I"$Crtl" -o"$ObjPath" $SrcFile
            if ($LASTEXITCODE -ne 0) {
                throw "bcc64 failed for $SrcFile (exit $LASTEXITCODE)"
            }
        }
    } finally {
        Pop-Location
    }
    Write-Host "Done Win64. Output in $Out64 :"
    Get-ChildItem $Out64 -Filter *.o | Format-Table Name, Length

    # ---- v3.7: CAB Win64 ELF (bcc64) -----------------------------------------
    $CabOut64 = Join-Path $Root 'Library\delphi-win64'
    $CabCompat = Join-Path $CabSrc 'compat'
    $ZlibSrc   = Join-Path $Root 'sdk\zlib'
    if ((Test-Path $Bcc64) -and (Test-Path $CabSrc) -and (Test-Path $Sdk)) {
        if (-not (Test-Path $CabOut64)) { New-Item -Path $CabOut64 -ItemType Directory | Out-Null }
        Push-Location $CabSrc
        try {
            Write-Host "[CAB Win64] Compiling fdi.c..."
            & $Bcc64 -c -O2 -D_AMD64_ "-I$Sdk" "-I$Crtl" "-I$CabCompat" "-I$CabSrc" "-o$CabOut64\fdi.o" "fdi.c"
            if ($LASTEXITCODE -ne 0) { throw "fdi.c Win64 failed" }
            Write-Host "[CAB Win64] Compiling fci.c..."
            & $Bcc64 -c -O2 -D_AMD64_ "-I$Sdk" "-I$Crtl" "-I$CabCompat" "-I$CabSrc" "-I$ZlibSrc" "-o$CabOut64\fci.o" "fci.c"
            if ($LASTEXITCODE -ne 0) { throw "fci.c Win64 failed" }
            Write-Host "[CAB Win64] Compiling cabinet_main.c..."
            & $Bcc64 -c -O2 -D_AMD64_ "-D_O_ACCMODE=O_ACCMODE" "-include$Sdk\windows.h" "-I$Sdk" "-I$Crtl" "-I$CabCompat" "-I$CabSrc" "-o$CabOut64\cabinet_main.o" "cabinet_main.c"
            if ($LASTEXITCODE -ne 0) { throw "cabinet_main.c Win64 failed" }
        } finally { Pop-Location }
        Write-Host "Done CAB Win64."
    } else {
        Write-Warning "Skipped CAB Win64 (bcc64 or sdk/cabnet not found)"
    }
} else {
    Write-Warning "Skipped Win64 build (bcc64 not found at $Bcc64). Install C++Builder Win64 in D37 (Tools → Manage Platforms → C++Builder → Windows 64-bit) to enable."
}

# ---- v3.6: LZMA FPC Win32+Win64 COFF via mingw-w64 gcc 16.1 vendored ----
# Mesma estrategia do BzipCombined.c em v3.8 e do cabnet_obj_fpc_* em v3.7.
# FPC linker aceita COFF "limpo" do mingw (sem COMDAT/section flags exoticos).
if ((Test-Path $MingwGcc) -and (Test-Path $Src)) {
    $FpcOut32 = Join-Path $Root 'Library\fpc-win32'
    $FpcOut64 = Join-Path $Root 'Library\fpc-win64'
    if (-not (Test-Path $FpcOut32)) { New-Item -Path $FpcOut32 -ItemType Directory | Out-Null }
    if (-not (Test-Path $FpcOut64)) { New-Item -Path $FpcOut64 -ItemType Directory | Out-Null }
    # Apenas LZMA core (sem 7z full chain) — TSevenZFile e Win32+Win64 Delphi-only.
    # LzmaStubsST.c desabilitado em modo single-thread (define _7ZIP_ST).
    $FpcLzmaSources = @(
        'LzmaDec.c', 'LzmaEnc.c', 'LzFind.c', 'Alloc.c', 'CpuArch.c', 'LzmaStubsST.c',
        # v3.1.3: Lzma2Enc.c para FPC tambem (consistencia 4 toolchains)
        'Lzma2Enc.c'
    )
    Push-Location $Src
    try {
        foreach ($SrcFile in $FpcLzmaSources) {
            $ObjName = ($SrcFile -replace '\.c$', '.o')
            Write-Host "[LZMA FPC Win32] Compiling $SrcFile -> $ObjName (mingw -m32)..."
            & $MingwGcc -c -O2 -m32 -D_7ZIP_ST -DZ7_ST "-o$FpcOut32\$ObjName" $SrcFile
            if ($LASTEXITCODE -ne 0) { throw "mingw -m32 $SrcFile failed" }
        }
        foreach ($SrcFile in $FpcLzmaSources) {
            $ObjName = ($SrcFile -replace '\.c$', '.o')
            Write-Host "[LZMA FPC Win64] Compiling $SrcFile -> $ObjName (mingw -m64)..."
            & $MingwGcc -c -O2 -m64 -D_7ZIP_ST -DZ7_ST "-o$FpcOut64\$ObjName" $SrcFile
            if ($LASTEXITCODE -ne 0) { throw "mingw -m64 $SrcFile failed" }
        }
    } finally { Pop-Location }
    Write-Host "Done LZMA FPC (mingw-w64 COFF Win32+Win64)."
} else {
    Write-Warning "Skipped LZMA FPC (mingw-w64 gcc at ZipFileORM/deps/gcc-mingw-w64/ not found)"
}
