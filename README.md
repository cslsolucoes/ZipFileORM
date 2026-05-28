# ZipFileORM v4.0.0 — Multi-format Archive Component Library

> **Object Pascal component pack** para 10 formatos de arquivos archive/compactação
> com suporte cross-platform **Delphi (D24..D37) + FPC/Lazarus** simultaneamente.

[![Version](https://img.shields.io/badge/version-4.0.0-blue.svg)](Documentation/REPORT_Migration_v4.md)
[![Delphi](https://img.shields.io/badge/Delphi-10.1%20Berlin%E2%80%93%2013%20Florence-orange.svg)](#supported-platforms)
[![FPC](https://img.shields.io/badge/FPC-3.2.2%2B-green.svg)](#supported-platforms)
[![Build](https://img.shields.io/badge/build-23%2F23%20Delphi%20%2B%2022%2F22%20FPC-success.svg)](#build-status)
[![License](https://img.shields.io/badge/license-LGPL--3.0-lightgrey.svg)](LICENSE)

---

## Table of Contents

1. [What's new in v4.0.0](#whats-new-in-v400)
2. [Features](#features)
3. [Supported Platforms](#supported-platforms)
4. [Installation](#installation)
5. [Quick Start](#quick-start)
6. [Component Reference](#component-reference)
7. [Examples](#examples)
8. [Architecture](#architecture)
9. [Build From Source](#build-from-source)
10. [Documentation](#documentation)
11. [Migration v3 → v4](#migration-v3--v4)
12. [Roadmap](#roadmap)
13. [License](#license)

---

## What's new in v4.0.0

v4.0.0 é uma **major refactor** focada em arquitetura e DX, **sem mudanças comportamentais**:

- **`src/` flat** — todos os 39 ficheiros `.pas` num único diretório, naming canônico `<Module>.<Feature>[.<SubFeature>].pas`
- **Facade pública única** — escreva `uses ZipfileORM;` e tenha acesso a todos os 10 formatos + factory + auto-detect
- **Commons.* cross-format** — utilitários compartilhados (AES, LZMA, Progress) promovidos para namespace dedicado
- **Naming consistente** — `unit ZipFile` (PascalCase) substituindo `unit zipfile` (lowercase v3)
- **Self-installing Library Paths** — design-time BPL registra paths no IDE via runtime discovery (Delphi)
- **Lazarus IDE integration** — script PowerShell registra paths em `environmentoptions.xml`
- **Palette renomeada** — `ZipFileORM` (era `ZipCompress` em v3.x)

Ver [Documentation/Roadmap/Migracao_v3_to_v4.md](Documentation/Roadmap/Migracao_v3_to_v4.md) para guia de upgrade.

---

## Features

### 10 Componentes para 10 formatos

| Componente | Formato | Read | Write | Encryption | Multi-volume |
| --- | --- | :---: | :---: | :---: | :---: |
| **`TZipFile`** | ZIP | ✅ | ✅ | AES-256 WinZip-AE-2 | ZIP64 |
| **`TTarFile`** | TAR (ustar/GNU/PAX) | ✅ | ✅ | — | — |
| **`TTarGzFile`** | TAR + Gzip (.tar.gz/.tgz) | ✅ | ✅ | — | — |
| **`TGzipFile`** | Single-file Gzip (.gz) | ✅ | ✅ | — | — |
| **`TCabFile`** | Microsoft Cabinet | ✅ | ✅ | — | Cabinet sets |
| **`TSevenZFile`** | 7-Zip | ✅ | LZMA2 | AES-256 (planned) | Split (planned) |
| **`TArjFile`** | ARJ | ✅ Store | — | — | Multi-vol detect |
| **`TIsoFile`** | ISO 9660 + Joliet | ✅ | — | — | — |
| **`TLhaFile`** | LHA/LZH | ✅ Store | — | — | — |
| **`TRarFile`** | RAR (RAR4+RAR5) | ✅ Store | — | — | Multi-vol detect |

### Facade unificada (v4.0.0)

```pascal
uses ZipfileORM;   // dá acesso a TUDO:
//  - 10 classes T<Format>File
//  - TArchive factory (DetectFormat, CreateZip, CreateTar, ...)
//  - IArchive, IArchiveEntry interfaces (read-only cross-format)
//  - TArchiveFormat enum (afZip, afTar, afCab, af7Z, ...)
//  - TCompressionMethod enum (cmStore, cmDeflate, cmLzma2, ...)
//  - 15 TArchive*Event types (lifecycle, entry, password, verify)
```

### Compression methods

- **ZIP**: Store, Deflate, **LZMA**, **AES-256** (WinZip-AE-2), ZIP64, UTF-8 (bit 11 GP flag)
- **7z**: Copy, **LZMA2** (SDK 26.01), LZMA, PPMd, Deflate, BZip2
- **CAB**: Store (cctNone), **MSZIP** (zlib-based)
- **TAR.GZ**: Gzip levels 1..9
- **Gzip**: Deflate levels 1..9, RFC 1952 metadata
- **BZIP2**: helper stream classes

### Design-time integration

- **Tool Palette page `ZipFileORM`** com 10 componentes (renomeada de `ZipCompress` na v4)
- **Property categories** — Object Inspector "Arrange by Category" (File, Compression, Encryption, ZIP64, Encoding, etc.)
- **Eventos publicados** — lifecycle, extract, add, password, multi-volume, verify, error/log
- **IDE Splash + About box** registration via IOTA APIs
- **Self-install Library Paths** — design-time BPL adiciona paths ao Tools→Options no momento da instalação
- **10 ícones customizados** 24×24 estilo uniforme

### Build status

| Target | Status |
|---|---|
| Delphi D24..D37 Win32 (runtime + design-time) | ✅ **14/14** |
| Delphi D24..D37 Win64 (runtime; design-time D29+D37) | ✅ **9/9** |
| FPC Windows i386/x86_64 (smoke_linux ZIP core) | ✅ **2/2** |
| FPC Linux i386/x86_64 | ✅ **2/2** |
| FPC CAB/LZMA/ISO/LHA/ARJ/RAR variants | ✅ **18/18** |
| DUnitX Delphi D29 W32 (suite + 20 smoke DPRs) | ✅ **21/21** |
| **TOTAL** | **✅ 66/66** |

---

## Supported Platforms

| IDE | Version | Pkg suffix | Status |
| --- | --- | --- | :---: |
| Embarcadero Delphi | 10.1 Berlin | D24 | ✅ |
| Embarcadero Delphi | 10.2 Tokyo | D25 | ✅ |
| Embarcadero Delphi | 10.3 Rio | D26 | ✅ |
| Embarcadero Delphi | 10.4 Sydney | D27 | ✅ |
| Embarcadero Delphi | 11 Alexandria | D28 | ✅ |
| Embarcadero Delphi | 12 Athens | D29 | ✅ |
| Embarcadero Delphi | 13 Florence | D37 | ✅ |
| Free Pascal | 3.2.2+ | — | ✅ Win32/Win64/Linux i386/x86_64 |
| Lazarus | 3.0+ | — | ✅ |

---

## Installation

### Quick install (Delphi, recomendado)

```powershell
cd C:\path\to\ZipFileORM

# Build all installed Delphis + copia runtime BPLs para BDSCOMMONDIR + registra paths
powershell -ExecutionPolicy Bypass -File tools/Build-AllDelphis.ps1 -Install
```

Depois no IDE:
1. `Component → Install Packages → Add`
2. Selecionar `<root>\Lib\RAD<xx>\Win32\dclZipFileORMD<xx>.bpl` (da pasta do projeto, **não** de `%BDSCOMMONDIR%\Bpl\`)
3. Click OK. A unit `ZipFileORM.LibraryPathReg` no BPL grava paths no registro automaticamente.
4. Reabra o IDE para `Tools → Options → Library` refletir as mudanças
5. Os 10 componentes aparecem na aba **`ZipFileORM`** da Tool Palette

### Quick install (Lazarus/FPC)

```powershell
cd C:\path\to\ZipFileORM

# Build smoke FPC (22 targets) + registra Library Paths no Lazarus
powershell -ExecutionPolicy Bypass -File tools/Build-AllFPC.ps1 -Install
```

Depois no IDE:
1. `Package → Open Package File (.lpk)` → `packages/ZipFileORMpkg.lpk`
2. `Compile` → `Use → Install` (rebuilda Lazarus)
3. Os 10 componentes aparecem na aba **`ZipFileORM`** da paleta

### Manual install (sem script)

Veja [CLAUDE.md](CLAUDE.md) seção "Common commands" para comandos `dcc32`/`dcc64` direto.

---

## Quick Start

```pascal
uses
  ZipfileORM;     // Facade única — re-exporta tudo

var
  Zip: TZipFile;
  Fmt: TArchiveFormat;
begin
  // 1. Auto-detect formato
  Fmt := TArchive.DetectFormat('arquivo.bin');
  WriteLn('Formato: ', TArchive.FormatToString(Fmt));

  // 2. Factory por formato (configura FileName)
  Zip := TArchive.CreateZip(nil, 'archive.zip');
  try
    Zip.Open;
    WriteLn(Zip.ReadAsString('readme.txt'));
  finally
    Zip.Free;
  end;
end;
```

### Fluent API (one-liner)

```pascal
uses ZipfileORM;

var Content: string;
begin
  Content := TZipFile.Create(nil)
              .WithFileName('archive.zip')
              .ThatOpens
              .ReadAsString('readme.txt');
end;
```

---

## Component Reference

### Common API (todos componentes)

```pascal
type
  T<Format>File = class(TComponent)
  public
    constructor Create(AOwner: TComponent); override;
    procedure Open;
    procedure Close;
    function GetEntryCount: Integer;
    function FileExists(const AName: string): Boolean;
    function GetEntryStream(const AName: string): TStream;
    function ReadAsBytes(const AName: string): TBytes;
    function ReadAsString(const AName: string): string;
    // Fluent
    function WithFileName(const APath: string): T<Format>File;
    function ThatOpens: T<Format>File;
  published
    property Active: Boolean;
    property FileName: string;
    property EntryCount: Integer;          // read-only
    // ... format-specific properties
    // ... ~15-24 events (OnBeforeOpen, OnExtractProgress, OnAskPassword, etc.)
  end;
```

### Write API (TZipFile, TSevenZFile, TTarFile, TTarGzFile, TGzipFile, TCabFile)

```pascal
// Zip
procedure AppendStream(Stream: TStream; ZIPFileName: string; FileDateTime: TDateTime);
procedure AppendFileFromDisk(AFileName, ZIPFileName: string);
procedure DeleteFile(AFileName: string);

// Tar / TarGz
procedure AppendStream(AStream: TStream; const AName: string; AModTime: TDateTime);
procedure AppendBytes(const ABytes: TBytes; const AName: string);

// 7z
procedure CreateFromFiles(const AFileList: array of string);
procedure CreateFromFilesLzma2(const AFileList: array of string; ALevel: Integer = 5);

// Gzip
procedure CompressFromFile(const ASourcePath: string);
procedure DecompressToFile(const ATargetPath: string);

// Cab
procedure CreateFromFiles(const ASourcesAndNames: array of string);
```

---

## Examples

### TZipFile — criar ZIP com AES-256

```pascal
uses ZipfileORM;

var
  Zip: TZipFile;
  FS: TFileStream;
begin
  Zip := TZipFile.Create(nil);
  try
    Zip.FileName := 'secret.zip';
    Zip.UseUtf8 := True;       // filename encoding UTF-8 (bit 11 GP flag)
    Zip.UseAES := True;        // AES-256 WinZip-AE-2
    Zip.Password := 'minha-senha-forte';
    Zip.Active := True;

    FS := TFileStream.Create('documento.pdf', fmOpenRead);
    try
      Zip.AppendStream(FS, 'documento.pdf', Now);
    finally
      FS.Free;
    end;
  finally
    Zip.Free;
  end;
end;
```

### TSevenZFile — criar 7z com LZMA2

```pascal
uses ZipfileORM;   // facade

var SevenZ: TSevenZFile;
begin
  SevenZ := TSevenZFile.Create(nil);
  try
    SevenZ.FileName := 'archive.7z';
    SevenZ.CompressionMethod := szmLzma2;
    SevenZ.CompressionLevel := 7;
    SevenZ.MultiThreaded := True;
    SevenZ.DictionarySize := 67108864;     // 64 MB
    SevenZ.SolidArchive := True;

    SevenZ.CreateFromFilesLzma2(
      ['c:\data\report.pdf',  'report.pdf',
       'c:\data\photo.jpg',   'photo.jpg'],
      7);
  finally
    SevenZ.Free;
  end;
end;
```

### TTarGzFile — criar TAR.GZ

```pascal
uses ZipfileORM;

var TarGz: TTarGzFile;
begin
  TarGz := TTarGzFile.Create(nil);
  try
    TarGz.FileName := 'backup.tar.gz';
    TarGz.GzipLevel := 9;
    TarGz.Format := tfUstar;
    TarGz.OwnerName := 'claiton';
    TarGz.GroupName := 'staff';
    TarGz.Open;
    TarGz.AppendFileFromDisk('c:\data\app.log', 'app.log');
    TarGz.AppendString('Hello World', 'hello.txt');
    TarGz.Save;
  finally
    TarGz.Free;
  end;
end;
```

### Auto-detect formato

```pascal
uses ZipfileORM;

var Fmt: TArchiveFormat;
begin
  Fmt := TArchive.DetectFormat('unknown.bin');
  case Fmt of
    afZip:      WriteLn('ZIP archive');
    afTar:      WriteLn('TAR archive');
    afGzip:     WriteLn('Gzip file');
    afSevenZip: WriteLn('7-Zip archive');
    afCab:      WriteLn('Microsoft Cabinet');
    afRar:      WriteLn('RAR archive');
    // ...
  end;
end;
```

### Event handlers

```pascal
// Progress + cancel
Zip.OnProgress := procedure(Sender: TObject; BytesDone, BytesTotal: Int64;
                            var Cancel: Boolean)
begin
  ProgressBar1.Position := Round(BytesDone / BytesTotal * 100);
  Application.ProcessMessages;
  Cancel := UserPressedCancel;
end;

// Password retry
Zip.OnAskPassword := procedure(Sender: TObject; const EntryName: string;
                               Attempt: Integer;
                               var Password: string; var Cancel: Boolean)
begin
  if not InputQuery('Password', 'Senha para ' + EntryName, Password) then
    Cancel := True;
end;
```

---

## Architecture

### Layered design v4.0.0

```text
┌─────────────────────────────────────────────────────────────┐
│  Tool Palette "ZipFileORM" (Object Inspector + IDE)         │
│  10 components × ~248 properties × ~145 events              │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│  FACADE — ZipfileORM.*                                      │
│  ZipfileORM.pas      ← TArchive factory + uses agregado     │
│  ZipfileORM.Interfaces ← IArchive, IArchiveEntry            │
│  ZipfileORM.Compression← TCompressionMethod                 │
│  ZipfileORM.Events   ← 15 TArchive*Event types              │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│  MÓDULOS FORMAT — 10 TComponent classes                     │
│  TZipFile, TTarFile, TTarGzFile, TGzipFile, TCabFile,       │
│  TSevenZFile, TArjFile, TIsoFile, TLhaFile, TRarFile        │
│  + sub-módulos: ZipFile.{ZIP64,UTF8,Streaming,Fluent}       │
│  + helper streams: Bzip2.Stream, UUE.Stream, ZCompress.Lzw  │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│  COMMONS.* — utilitários cross-format                       │
│  Commons.Compression.{Base,None,ZLib,LZMA,Bridge,Consts}    │
│  Commons.Encryption.AES                                     │
│  Commons.Progress, Commons.{Types,Consts,Exceptions}        │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│  Vendored SDKs (sdk/)                                       │
│  LZMA SDK 26.01, bzip2 1.1.0-dev, Wine cabinet,             │
│  LHA decoder, ARJ source, zlib 1.3.2.1, UnRAR SDK 7.21      │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│  Cross-compilers (deps/)                                    │
│  mingw-w64 gcc 16.1.0 (Windows COFF for FPC)                │
│  gcc-linux-musl 15.2.0 (ELF Linux cross)                    │
└─────────────────────────────────────────────────────────────┘
```

### Sub-módulo vs Commons — classificação

| Categoria | Critério | Exemplos |
|---|---|---|
| **Sub-módulo do formato** | Feature exclusiva da spec do formato | `ZipFile.ZIP64`, `ZipFile.UTF8`, `ZipFile.Streaming`, `TarFile.GzipStream` |
| **Commons.* (cross-format)** | Algoritmo reutilizável entre 2+ formatos | `Commons.Encryption.AES`, `Commons.Compression.LZMA`, `Commons.Progress` |

---

## Build From Source

### Pré-requisitos

- **Delphi** D24..D37 (ou subset) instalado em `C:\Program Files (x86)\Embarcadero\Studio\<BDS>\`
- **OR FPC/Lazarus** 3.2.2+ em `D:\fpc\fpc\bin\` (ou ajuste em `tools/Build-FPC-Smoke.ps1`)
- **PowerShell** 5.1+ (built-in Windows)

### Build commands

```powershell
cd C:\path\to\ZipFileORM

# Build all installed Delphis (D24..D37 × Win32+Win64 = 23 BPLs)
powershell -ExecutionPolicy Bypass -File tools/Build-AllDelphis.ps1

# Build + install completo (BPLs em BDSCOMMONDIR + Library Paths)
powershell -ExecutionPolicy Bypass -File tools/Build-AllDelphis.ps1 -Install

# Subset (1 ou mais Delphis)
powershell -ExecutionPolicy Bypass -File tools/Build-AllDelphis.ps1 -OnlyDelphi 29,37

# Smoke FPC (22 targets: Win32/Win64/Linux × 6 formatos)
powershell -ExecutionPolicy Bypass -File tools/Build-FPC-Smoke.ps1

# Build FPC + register Library Paths Lazarus
powershell -ExecutionPolicy Bypass -File tools/Build-AllFPC.ps1 -Install

# Install/Uninstall Library Paths standalone
powershell -ExecutionPolicy Bypass -File tools/Install-LibraryPaths.ps1
powershell -ExecutionPolicy Bypass -File tools/Install-LibraryPaths-Lazarus.ps1
powershell -ExecutionPolicy Bypass -File tools/Uninstall-LibraryPaths.ps1
powershell -ExecutionPolicy Bypass -File tools/Uninstall-LibraryPaths-Lazarus.ps1
```

### Build de OBJs vendored (só quando SDK muda)

```powershell
powershell tools/Build-LzmaObjs.ps1   # LZMA SDK
powershell tools/Build-Bzip2Objs.ps1  # bzip2
powershell tools/Build-LhaObjs.ps1    # LHA
powershell tools/Build-ArjObjs.ps1    # ARJ
```

---

## Documentation

| Documento | Conteúdo |
|---|---|
| [CLAUDE.md](CLAUDE.md) | AI assistant guidance + project conventions |
| [Documentation/REPORT_Migration_v4.md](Documentation/REPORT_Migration_v4.md) | Relatório completo da migração v3.12.2 → v4.0.0 (14 seções) |
| [Documentation/Arquitetura/](Documentation/Arquitetura/) | Overview, Modulos, Commons, Camadas, FLOWCHART (Mermaid) |
| [Documentation/Roadmap/Migracao_v3_to_v4.md](Documentation/Roadmap/Migracao_v3_to_v4.md) | Guia de upgrade para consumidores v3 → v4 |
| [Documentation/Regras de Negocio/](Documentation/Regras%20de%20Negocio/) | 5 RNs: Format-Detection, Compression-Methods, Encryption-AES, Streaming-Rules, Naming-Conventions |
| [Documentation/Analise/](Documentation/Analise/) | Análise por módulo: README_Modulo + CHECKLIST + PASSO_A_PASSO + O_QUE_FALTA |
| [Documentation/API/](Documentation/API/) | Esqueleto navegável por módulo (geração detalhada pendente v4.5) |
| [Documentation/spec/zipfile-v3-multi-format-expansion.md](Documentation/spec/zipfile-v3-multi-format-expansion.md) | SPEC v3 histórico (preservado para referência) |
| [appnote.md](appnote.md) | PKWARE ZIP appnote (reference oficial) |
| [.wolf/cerebrum.md](.wolf/cerebrum.md) | Persistent learnings + do-not-repeat |

---

## Migration v3 → v4

Resumo das mudanças breaking (ver [Migracao_v3_to_v4.md](Documentation/Roadmap/Migracao_v3_to_v4.md) completo):

```pascal
// v3.x:
uses zipfile, ZipFile.Encryption.AES, ZipFile.Compression.LZMA;

// v4.0.0:
uses ZipfileORM;   // facade re-exporta tudo
```

| v3.x | v4.0.0 |
|---|---|
| `unit zipfile` (lowercase) | `unit ZipFile` (PascalCase) |
| `tiCompress*`, `dzlib` (MCL legacy) | `Commons.Compression.*` |
| `ZipFile.Events` | `ZipfileORM.Events` |
| `ZipFile.Encryption.AES` | `Commons.Encryption.AES` (promovido) |
| `ZipFile.Compression.LZMA` | `Commons.Compression.LZMA` (promovido) |
| `ZipFile.Progress` | `Commons.Progress` (promovido) |
| `Tar.GzipStream` | `TarFile.GzipStream` |
| `Bzip2.Bzip2Stream` | `Bzip2.Stream` |
| `UUE.UUEStream` | `UUE.Stream` |
| Palette page `ZipCompress` | Palette page `ZipFileORM` |

**Comportamento funcional:** ZERO mudanças. Testes DUnitX continuam passando após atualizar `uses`.

---

## Roadmap

Resumo das próximas waves (vide [Documentation/Roadmap/Roadmap_V1.0.md](Documentation/Roadmap/Roadmap_V1.0.md) completo):

- **v4.1** — Splits profundos por módulo (5 ficheiros: `.pas`, `.Interfaces`, `.Consts`, `.Types`, `.Exceptions`). ~25h.
- **v4.2** — Property population (P20-P29 da v3 SPEC). ~50h.
- **v4.3** — Event firing wiring (P03+P04). ~30h.
- **v4.4** — 7z encryption + multi-volume write (P40+P41). ~25h.
- **v4.5** — Documentation excellence — XML docs + 75 docs/classe via `documentation-agent-class-writer`. ~25h.
- **v5.0** — UnRAR encoder (major undertaking). Decisão de viabilidade pendente.

---

## License

LGPL-3.0 — vide [LICENSE](LICENSE) para texto completo.

Vendor SDKs em `sdk/` mantêm suas próprias licenças (LZMA SDK = public domain;
bzip2 = BSD-like; cabnet/Wine = LGPL; UnRAR = restricted; etc.).

---

## Contributing

PRs welcome. Convenções:

1. Cada PR refere-se a um item `P##` do SPEC §17 ou `C##` do Roadmap_V1.0.md
2. Commit message: `[P##] Description` ou `[Wave N] Description`
3. Build gate obrigatório: `Build-AllDelphis.ps1 -OnlyDelphi 29,37` + `Build-FPC-Smoke.ps1` antes do merge
4. Naming policy: `.cursor/rules/backend-pascal-unit-naming_V1.6.0.mdc`

---

## Acknowledgments

- **LZMA SDK 26.01** — Igor Pavlov (public domain)
- **bzip2** — Julian Seward (BSD-like)
- **zlib 1.3.2.1** — Jean-loup Gailly + Mark Adler (BSD-like)
- **Wine cabinet (FCI/FDI)** — Wine Project (LGPL)
- **LHA for UNIX 1.14i** — Haruyasu Yoshizaki, Tsugio Okamoto (public domain)
- **ARJ 3.10** — Robert K. Jung (GPL-2 source, decoder only)
- **UnRAR SDK 7.21** — RARLAB (restricted, decoder only)
- **MCL legacy** — MODELbuilder Component Library team (LGPL-2.1+) — base `zipfile.pas` original (Darius Blaszijk, 2006-2007)

Trademarks pertencem aos respectivos donos (7-Zip™ Igor Pavlov, WinRAR™ RARLAB,
WinZip™ Corel). Este projeto não é afiliado nem endossado por eles.
