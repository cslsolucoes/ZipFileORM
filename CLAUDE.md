# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> Project-specific guidance for Claude Code (and other AI assistants) working
> on the ZipFileORM v4.0.0 multi-format archive component library.

## OpenWolf

@.wolf/OPENWOLF.md

Este projeto usa OpenWolf para gerenciamento de contexto persistente.
Leia e siga `.wolf/OPENWOLF.md` toda sessão.

## Project overview

**ZipFileORM v4.0.0** é uma biblioteca Delphi/FPC de componentes para 10 formatos archive,
refatorada da v3.x para uma arquitetura canônica `src/` flat com namespaces
`Commons.*` (cross-format) + `ZipFileORM.*` (facade) + módulos format (`ZipFile`, `TarFile`, etc.).

**Legacy v3.x (read-only para diff):** `c:\Users\Public\Documents\Embarcadero\Studio\Outros\zipfile`
**Versão:** v4.0.0 (2026-05-28)
**Plataformas:** Delphi D24..D37 (10.1 Berlin a 13 Florence, Win32+Win64) + FPC/Lazarus.
**Licença:** LGPL-3.0

### Formatos suportados (10 componentes)

| Componente | Formato | Read | Write |
| --- | --- | --- | --- |
| `TZipFile`    | ZIP    | ✅ | ✅ |
| `TTarFile`    | TAR    | ✅ | ✅ |
| `TTarGzFile`  | TAR.GZ | ✅ | ✅ |
| `TGzipFile`   | GZ     | ✅ | ✅ |
| `TCabFile`    | CAB    | ✅ | ✅ |
| `TSevenZFile` | 7Z     | ✅ | ✅ |
| `TArjFile`    | ARJ    | ✅ | — |
| `TIsoFile`    | ISO    | ✅ | — |
| `TLhaFile`    | LHA    | ✅ | — |
| `TRarFile`    | RAR    | ✅ | — |

## Architecture — v4.0.0 canonical structure

### `src/` — flat single folder (sem subpastas)

Naming `<ModuleConcept>.<Feature>[.<SubFeature>].pas` atua como pasta virtual:

- **Facade pública** (`ZipFileORM.*`): `ZipFileORM.pas` (TArchive factory), `ZipFileORM.Interfaces.pas` (IArchive/IArchiveEntry), `ZipFileORM.Compression.pas` (TCompressionMethod enum), `ZipFileORM.Events.pas` (15 TArchive*Event types).
- **Commons** (`Commons.*` — cross-format): `Commons.Consts.pas`, `Commons.Types.pas`, `Commons.Exceptions.pas`, `Commons.Progress.pas`, `Commons.Compression.{Base,None,ZLib,LZMA,Consts}.pas`, `Commons.Encryption.AES.pas`, `Commons.FPC.inc`, `Commons.Compression.Defines.inc`.
- **Módulos format** (10): `ZipFile.pas`, `TarFile.pas`, `TarGzFile.pas`, `GzipFile.pas`, `CabFile.pas`, `SevenZFile.pas`, `ArjFile.pas`, `IsoFile.pas`, `LhaFile.pas`, `RarFile.pas`.
- **Sub-módulos format-only** (ZIP-specific): `ZipFile.ZIP64.pas`, `ZipFile.UTF8.pas`, `ZipFile.Streaming.pas`, `ZipFile.Fluent.pas`; TAR-specific: `TarFile.GzipStream.pas`.
- **Helper streams**: `Bzip2.Stream.pas`, `UUE.Stream.pas`, `ZCompress.LzwStream.pas` + Fluent variantes.
- **Auto-detect**: `Archive.Open.pas` (TArchiveFormat + DetectArchiveFormat).

**Resultado:** consumidor escreve `uses ZipFileORM;` e ganha acesso unificado.

### Política de classificação Sub-módulo vs Commons

| Categoria | Critério | Naming |
|---|---|---|
| **Sub-módulo do formato** | Feature exclusiva da spec do formato | `<Format>File.<SubConcept>.pas` |
| **Commons (promoted)** | Algoritmo reutilizável entre 2+ formatos | `Commons.<Concept>.pas` |

Exemplos: AES + LZMA + Progress estão em `Commons.*` (cross-format); ZIP64 + UTF8 + Streaming permanecem `ZipFile.*` (spec ZIP).

## Build system

### Regra crítica — sempre `dcc32`/`dcc64` direto, NUNCA `msbuild`

```bash
# CORRETO:
"$BDS/bin/dcc32.exe" -Q -B "ZipFileORMD37.dpk" "-N$out" "-LN$out" "-LE$out" "-U..\src;$out" "-NS$ns"

# ERRADO — não usar:
msbuild ZipFileORMD37.dproj /t:Build /p:Config=Release /p:Platform=Win32
```

### Output paths

| Compiler | Output dir |
| --- | --- |
| Delphi D24..D37 | `Lib/RAD<MM>/Win{32,64}/` |
| FPC (Lazarus) | `Lib/FPC/$(TargetOS)/` |

### Common commands (PowerShell, executar da raiz do projeto)

```powershell
# Build packages para todos os Delphis (D24..D37 W32+W64):
powershell -ExecutionPolicy Bypass -File tools/Build-AllDelphis.ps1

# Build + COMPLETO (LibraryPaths + Bpls em BDSCOMMONDIR):
powershell -ExecutionPolicy Bypass -File tools/Build-AllDelphis.ps1 -Install

# Apenas Library Paths (registry):
powershell -ExecutionPolicy Bypass -File tools/Build-AllDelphis.ps1 -InstallLibPaths

# Apenas BPLs (copy para BDSCOMMONDIR\Bpl\):
powershell -ExecutionPolicy Bypass -File tools/Build-AllDelphis.ps1 -InstallBpls

# Subset:
powershell -ExecutionPolicy Bypass -File tools/Build-AllDelphis.ps1 -OnlyDelphi 29,37 -Install

# Apenas instalar/atualizar (sem rebuild):
powershell -ExecutionPolicy Bypass -File tools/Install-LibraryPaths.ps1
powershell -ExecutionPolicy Bypass -File tools/Install-Bpls.ps1

# Dry-run:
powershell -ExecutionPolicy Bypass -File tools/Install-LibraryPaths.ps1 -DryRun
powershell -ExecutionPolicy Bypass -File tools/Install-Bpls.ps1 -DryRun

# Cleanup completo:
powershell -ExecutionPolicy Bypass -File tools/Uninstall-LibraryPaths.ps1
powershell -ExecutionPolicy Bypass -File tools/Uninstall-Bpls.ps1

# Build dos OBJs C/C++ (só quando SDK muda):
powershell tools/Build-LzmaObjs.ps1
powershell tools/Build-Bzip2Objs.ps1
powershell tools/Build-LhaObjs.ps1
powershell tools/Build-ArjObjs.ps1

# Smoke tests FPC (22 targets: Win32+Win64+Linux x 6 formatos):
powershell tools/Build-FPC-Smoke.ps1

# Build FPC completo + Library Paths Lazarus (idempotente):
powershell tools/Build-AllFPC.ps1 -Install

# Install/Uninstall Library Paths Lazarus standalone:
powershell tools/Install-LibraryPaths-Lazarus.ps1
powershell tools/Uninstall-LibraryPaths-Lazarus.ps1

# DUnitX Delphi suite:
& "$bds/bin/dcc32.exe" -Q -B tests/ZipFileTestsD29.dpr "-U..\src"
```

### Library Paths automáticos

O script [tools/Install-LibraryPaths.ps1](tools/Install-LibraryPaths.ps1) adiciona em cada Delphi instalado (D24..D37):

- `<root>\src` — fonte `.pas`
- `<root>\Lib\RAD<xx>\Win32` — DCU/DCP runtime+designtime Win32
- `<root>\Lib\RAD<xx>\Win64` — DCU/DCP runtime Win64

Chave do registro: `HKCU\Software\Embarcadero\BDS\<bds>\Library\Win{32,64}\Search Path`.

Idempotente — paths já presentes não são duplicados. Reversível via `Uninstall-LibraryPaths.ps1`. Pode ser disparado automaticamente após build com `Build-AllDelphis.ps1 -InstallLibPaths`.

### Status v4.0.0

- Build matrix: **23/23 OK** (D24..D37 Win32+Win64) + FPC smokes (4 targets)
- Tests: DUnitX suite (D29) + 20 smokes (Delphi + FPC nativo)
- **Self-install:** design-time BPL `dclZipFileORMDxx` carrega `ZipFileORM.LibraryPathReg` que descobre paths em runtime e registra Library Paths automaticamente ao abrir o IDE — sem hardcoded paths.
- Pendente: `Documentation/` completa via agents `documentation-*`; tag `v4.0.0`.
- **Deferred:** split em 5 ficheiros por módulo (Types/Consts/Exceptions/Interfaces) — ~25h.

### Packages — runtime vs design-time

`packages/` contém DOIS conjuntos de BPLs por versão Delphi (D24..D37):

- `ZipFileORMDxx.dpk` — **runtime BPL** (componentes para apps consumidores)
- `dclZipFileORMDxx.dpk` — **design-time BPL** (instalado no IDE; registra componentes na palette + auto-LibraryPaths)
- Units de registro design-time:
  - `zipfileReg.pas` — registro de componentes na palette
  - `ZipFileORM.SplashReg.pas` — splash screen no IDE
  - `ZipFileORM.LibraryPathReg.pas` — auto-discovery e registro de Library Paths em runtime

### Running single tests

```powershell
# DUnitX — filtrar por fixture name (recompila + executa):
& "$bds\bin\dcc32.exe" -Q -B tests\ZipFileTestsD29.dpr "-U..\src"
tests\ZipFileTestsD29.exe --include "TZipFileAESTests"

# FPC smoke individual:
fpc -Mdelphi -Fu..\src tests\smoke_lzma_fpc.pas
.\tests\smoke_lzma_fpc.exe

# Delphi smoke individual (qualquer smoke_*.dpr em tests/):
& "$bds\bin\dcc32.exe" -Q tests\smoke_sevenz.dpr "-U..\src"
.\tests\smoke_sevenz.exe
```

## Conventions

- Header padrão Pascal no topo de cada .pas
- `{$I Commons.FPC.inc}` no topo (substitui `{$IFDEF FPC} {$mode delphi}{$H+} {$ENDIF}` repetitivo)
- `uses System.ZLib` em Delphi; `Commons.Compression.ZLib.Bridge` em FPC
- Prefixos: `T<ClassName>`, `E<Exception>`, `I<Interface>`, `F<Field>`

### Unit naming policy

Conforme `.cursor/rules/backend-pascal-unit-naming_V1.6.0.mdc`:

- `<ModuleConcept>.<Feature>[.<SubFeature>].pas` em inglês
- `Commons.` prefix para utilitários cross-format
- `<Format>File.Interfaces.pas` contém **interface principal + builders fluent** (sem .Fluent.pas separado)

## Quick start (consumer)

```pascal
uses
  ZipFileORM;        // Facade única — re-exporta tudo

var
  Fmt: TArchiveFormat;
  Zip: TZipFile;
begin
  // Detect format
  Fmt := TArchive.DetectFormat('arquivo.bin');
  WriteLn('Formato: ', TArchive.FormatToString(Fmt));

  // Use a specific component
  Zip := TArchive.CreateZip(nil, 'archive.zip');
  try
    Zip.Open;
    // ...
  finally
    Zip.Free;
  end;
end;
```

## Vendored C/C++ sources e binários nativos

- `sdk/` — source vendored read-only (arj, bzip2, cabnet, lha, lzma2601, unrar, zlib). Recompilar com `tools/Build-*Objs.ps1` apenas quando o SDK mudar.
- `deps/` — `.obj` pré-compilados linkados em build-time pelos módulos format. Subpastas: `win32/`, `win64/`, `gcc-mingw-w64/`, `gcc-linux-musl/` (cross-compile).
- `dll/` — DLLs runtime opcionais (`unrar_x86/`, `unrar_x86-64/` para `TRarFile`).

## Documentation

- `.cursor/` — rules pack 1.6.5 + skills (project-wide governance)
- `.workspace/context.json` — instância concreta (projectName, paths)
- `.wolf/cerebrum.md` — preferências do usuário + learnings
- `.wolf/anatomy.md` — inventário de ficheiros (consultar ANTES de ler qualquer .pas)
- `.claudeignore` — exclui `Lib/`, `*.dcu`, `*.bpl`, `*.o`, `*.ppu`, fixtures de teste e `Documentation/` do contexto IA (consulta sob demanda)
- `Documentation/` — gerada via agents documentation-* (Onda 7 pendente)

## Plano de migração

Plano detalhado em `D:\Users\claiton.linhares\.claude\plans\vectorized-churning-hartmanis.md`.
