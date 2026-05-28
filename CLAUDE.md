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
`Commons.*` (cross-format) + `ZipfileORM.*` (facade) + módulos format (`ZipFile`, `TarFile`, etc.).

**Origem (preservada):** `c:\Users\Public\Documents\Embarcadero\Studio\Outros\zipfile`
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

- **Facade pública** (`ZipfileORM.*`): `ZipfileORM.pas` (TArchive factory), `ZipfileORM.Interfaces.pas` (IArchive/IArchiveEntry), `ZipfileORM.Compression.pas` (TCompressionMethod enum), `ZipfileORM.Events.pas` (15 TArchive*Event types).
- **Commons** (`Commons.*` — cross-format): `Commons.Consts.pas`, `Commons.Types.pas`, `Commons.Exceptions.pas`, `Commons.Progress.pas`, `Commons.Compression.{Base,None,ZLib,LZMA,Consts}.pas`, `Commons.Encryption.AES.pas`, `Commons.FPC.inc`, `Commons.Compression.Defines.inc`.
- **Módulos format** (10): `ZipFile.pas`, `TarFile.pas`, `TarGzFile.pas`, `GzipFile.pas`, `CabFile.pas`, `SevenZFile.pas`, `ArjFile.pas`, `IsoFile.pas`, `LhaFile.pas`, `RarFile.pas`.
- **Sub-módulos format-only** (ZIP-specific): `ZipFile.ZIP64.pas`, `ZipFile.UTF8.pas`, `ZipFile.Streaming.pas`, `ZipFile.Fluent.pas`; TAR-specific: `TarFile.GzipStream.pas`.
- **Helper streams**: `Bzip2.Stream.pas`, `UUE.Stream.pas`, `ZCompress.LzwStream.pas` + Fluent variantes.
- **Auto-detect**: `Archive.Open.pas` (TArchiveFormat + DetectArchiveFormat).

**Resultado:** consumidor escreve `uses ZipfileORM;` e ganha acesso unificado.

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

# Build + adicionar Library Paths automaticamente em cada Delphi:
powershell -ExecutionPolicy Bypass -File tools/Build-AllDelphis.ps1 -InstallLibPaths

# Subset:
powershell -ExecutionPolicy Bypass -File tools/Build-AllDelphis.ps1 -OnlyDelphi 29,37

# Apenas instalar/atualizar Library Paths (sem rebuild):
powershell -ExecutionPolicy Bypass -File tools/Install-LibraryPaths.ps1

# Dry-run (mostra o que seria mudado sem alterar o registro):
powershell -ExecutionPolicy Bypass -File tools/Install-LibraryPaths.ps1 -DryRun

# Remover paths do registro (cleanup):
powershell -ExecutionPolicy Bypass -File tools/Uninstall-LibraryPaths.ps1

# Build dos OBJs C/C++ (só quando SDK muda):
powershell tools/Build-LzmaObjs.ps1
powershell tools/Build-Bzip2Objs.ps1
powershell tools/Build-LhaObjs.ps1
powershell tools/Build-ArjObjs.ps1

# Smoke tests FPC (4 targets):
powershell tools/Build-FPC-Smoke.ps1

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

### Status atual da migração v3 → v4

✅ **Ondas completas:**
1. Scaffold + Commons (refatoração legacy MCL para Commons.Compression.*)
2. Copy+uses-rewrite de 13 módulos + renomes
3. Facade ZipfileORM.* (Events/Interfaces/Compression/pas)
4. Packages: 14 dpk gerados + Build-AllDelphis.ps1 portado — **23/23 OK** (D24..D37 W32+W64)
5. Tests: DUnitX suite + 20 smokes compilam em D29 (21/21)
6. Tools/CLAUDE.md/context.json — atual

⏳ **Ondas pendentes:**
7. Documentation/ completa via agents documentation-*
8. Commits finais + tag v4.0.0
- **Deferred:** Split em 5 ficheiros por módulo (Types/Consts/Exceptions/Interfaces) — ~25h de trabalho profundo

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
  ZipfileORM;        // Facade única — re-exporta tudo

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

## Documentation

- `.cursor/` — rules pack 1.6.5 + skills (project-wide governance)
- `.workspace/context.json` — instância concreta (projectName, paths)
- `.wolf/cerebrum.md` — preferências do usuário + learnings
- `.wolf/anatomy.md` — inventário de ficheiros
- `Documentation/` — gerada via agents documentation-* (Onda 7 pendente)

## Plano de migração

Plano detalhado em `D:\Users\claiton.linhares\.claude\plans\vectorized-churning-hartmanis.md`.
