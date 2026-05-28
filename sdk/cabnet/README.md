# sdk/cabnet — Microsoft Cabinet FCI/FDI portable source

## Origem

Vendored a partir de **Wine 9.x** (`zipfile/wine/dlls/cabinet/` no workspace).
Wine fornece uma reimplementação pura-C, LGPL-2.1, portável (compila em
Linux/macOS/Windows) da FCI (File Compression Interface) e FDI (File
Decompression Interface) APIs originalmente expostas por `cabinet.dll`.

**Por que não usar `cabinet.dll`:** a DLL é Windows-only. zipfile v3.x quer
suportar Linux x86_64 também (FPC cross-compile operacional desde v3.1).
Vendorando source Wine podemos buildar estaticamente em ambas plataformas.

## Build status — Windows OMF (Win32) ✅ FUNCIONANDO

**Toolchain:** Delphi D29 (BDS 23.0) `bcc32c.exe` + Embarcadero Win SDK
headers (D29 `include/windows/sdk/` + `include/windows/crtl/`).

**Por que D29 e não BCC102 vendored:** BCC102 freeware tem `winnt.h`
incompleto (faltam `CONST`/`PCWSTR`/`SLIST_HEADER`/etc.). D29 tem
versão completa (24547 linhas vs 20326 do BCC102).

**Headers Microsoft FCI/FDI:** copiados de `D29/include/windows/sdk/Fci.h`
e `Fdi.h` (originais Microsoft), substituem os Wine equivalentes que
tinham macros não-portáveis (`__WINE_ALLOC_SIZE`). Wine `fci.c`/`fdi.c`
são ABI-compatíveis com headers Microsoft (foi requisito de design).

**Build OK em 3 de 4 arquivos C:**

| Arquivo | Origem | OBJ size | Função |
|---|---|---|---|
| `fdi.c` | Wine 9.x | 36 587 B | File Decompression Interface (decoder) |
| `fci.c` | Wine 9.x | 19 577 B | File Compression Interface (encoder) |
| `cabinet_main.c` | Wine 9.x | 19 350 B | Win32 file IO helpers (CreateFileA/ReadFile/etc) |
| `compressapi.c` | Wine 9.x | — | DEFERIDO (LZMS API; precisa patch source para `#include <windows.h>`; não-essencial) |

Output em `zipfile/Lib/cabnet_obj_win32/{fdi,fci,cabinet_main}.obj`
(OMF Win32, linkável estaticamente via Delphi `{$L ..\Library\delphi-win32\X.obj}`).

## Build flags (Win32)

```powershell
$D29Bcc32 = "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\bcc32c.exe"
$D29Inc   = "C:\Program Files (x86)\Embarcadero\Studio\23.0\include\windows"
$CabSrc   = "<repo>\zipfile\sdk\cabnet"
$Compat   = "$CabSrc\compat"
$Zlib     = "<repo>\zipfile\wine\libs\zlib"

# fdi.c (decoder)
& $D29Bcc32 -c -O2 -D_X86_ "-I$D29Inc\sdk" "-I$D29Inc\crtl" "-I$Compat" "-I$CabSrc" -ofdi.obj fdi.c

# fci.c (encoder) — precisa zlib
& $D29Bcc32 -c -O2 -D_X86_ "-I$D29Inc\sdk" "-I$D29Inc\crtl" "-I$Compat" "-I$CabSrc" "-I$Zlib" -ofci.obj fci.c

# cabinet_main.c (Win32 helpers) — pre-includes windows.h + force _O_ACCMODE alias
& $D29Bcc32 -c -O2 -D_X86_ -D_O_ACCMODE=O_ACCMODE "-include$D29Inc\sdk\windows.h" `
    "-I$D29Inc\sdk" "-I$D29Inc\crtl" "-I$Compat" "-I$CabSrc" -ocabinet_main.obj cabinet_main.c
```

Script integrado em `zipfile/tools/Build-LzmaObjs.ps1` (block "v3.7: CAB Win32 OMF").

## Arquivos

| Arquivo | Origem | Função |
|---|---|---|
| `fci.c` | Wine 9.x `dlls/cabinet/fci.c` | FCI encoder, 1730 linhas |
| `fdi.c` | Wine 9.x `dlls/cabinet/fdi.c` | FDI decoder, 2864 linhas |
| `compressapi.c` | Wine 9.x | LZMS API (DEFERIDO) |
| `cabinet_main.c` | Wine 9.x | DllMain + Win32 file IO helpers |
| `cabinet.h` | Wine 9.x | Tipos internos Wine cabinet, 510 linhas |
| `fci.h` | Microsoft D29 SDK | API pública FCI (substitui Wine version) |
| `fdi.h` | Microsoft D29 SDK | API pública FDI (substitui Wine version) |
| `fci_wine.h.bak`, `fdi_wine.h.bak` | Wine 9.x | Versões originais Wine (backup) |
| `compressapi.h` | Wine 9.x | LZMS API header |
| `cabnet_shim.h` | Próprio | Wine debug macros + list.h equivalente |
| `compat/wine/debug.h`, `list.h` | Próprio | Stubs que re-rotateiam para shim |
| `LICENSE_LGPL.txt` | Wine `COPYING.LIB` | GNU LGPL 2.1 (uso interno) |

## Linux x86_64 (próximo)

Wine cabinet é portável; deve compilar em Linux via gcc com:

```bash
# zlib do sistema (apt install zlib1g-dev)
gcc -c -O2 -fPIC fdi.c -o fdi_linux.o
gcc -c -O2 -fPIC -lz fci.c -o fci_linux.o
# cabinet_main.c precisa porting CreateFileA/ReadFile -> open/read POSIX
# Recomenda-se pular cabinet_main.c em Linux e usar callbacks Pascal nativos.
```

Verificação pendente em sessão Linux (FPC cross-compile + gcc Linux x64).

## Pascal API planejada (próximo passo)

```pascal
unit Cab.CabFile;

type
  TCabFile = class(TComponent)
    procedure Open;
    procedure Close;
    function EntryCount: Integer;
    function GetEntryStream(const AName: string): TStream;
    procedure AppendStream(Src: TStream; const Name: string);
  end;

implementation
  {$L ..\Library\delphi-win32\fdi.obj}
  {$L ..\Library\delphi-win32\fci.obj}
  {$L ..\Library\delphi-win32\cabinet_main.obj}
  // externs FDICreate / FDICopy / FCICreate / FCIAddFile + 8 callbacks
```

Binding pendente — próximo commit. Por enquanto temos só a infraestrutura
C compilando.

## Não usado: `codeproject/CabCompressExtract/`

Avaliado mas REJEITADO — é wrapper C++ ao redor da `cabinet.dll` Microsoft
(headers FCI.H/FDI.H + classes auxiliares Compress.hpp/Extract.hpp).
Requer Windows + cabinet.dll runtime. Não serve para o objetivo Linux.
