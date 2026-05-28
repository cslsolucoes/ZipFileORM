---
internal_file_version: 1.0.0
generated_by: manual
date: 2026-05-28
---

# ZipFileORM v4.0.0 — Overview de Arquitetura

## Propósito

ZipFileORM é uma biblioteca Delphi/FPC de componentes (`TComponent`) que encapsula 10 formatos de archive/compactação atrás de uma API uniforme, com cobertura completa read+write para 6 formatos principais e read-only para 4 formatos legacy.

## Diagrama de camadas

```text
┌───────────────────────────────────────────────────────────────────┐
│                    Consumer (uses ZipFileORM)                     │
└────────────────────────────────┬──────────────────────────────────┘
                                 │
┌────────────────────────────────▼──────────────────────────────────┐
│ FACADE — ZipFileORM.*                                             │
│   ZipFileORM.pas        ← TArchive factory + uses agregado        │
│   ZipFileORM.Interfaces ← IArchive, IArchiveEntry                 │
│   ZipFileORM.Compression← TCompressionMethod                      │
│   ZipFileORM.Events     ← 15 TArchive*Event types                 │
└────────────────────────────────┬──────────────────────────────────┘
                                 │
┌────────────────────────────────▼──────────────────────────────────┐
│ MÓDULOS FORMAT — 10 TComponent classes                            │
│ TZipFile, TTarFile, TTarGzFile, TGzipFile, TCabFile, TSevenZFile, │
│ TArjFile, TIsoFile, TLhaFile, TRarFile                            │
│ + sub-módulos format-only: ZipFile.{ZIP64,UTF8,Streaming,Fluent}, │
│                              TarFile.GzipStream                   │
└──────┬─────────────────────────────────────────────┬──────────────┘
       │                                             │
┌──────▼────────────┐                  ┌─────────────▼─────────────┐
│ HELPER STREAMS    │                  │ AUTO-DETECT               │
│ Bzip2.Stream      │                  │ Archive.Open.pas          │
│ UUE.Stream        │                  │   (magic byte detection)  │
│ ZCompress.Lzw…    │                  └───────────────────────────┘
└──────┬────────────┘
       │
┌──────▼─────────────────────────────────────────────────────────────┐
│ COMMONS — utilitários cross-format                                 │
│ Commons.Compression.{Base,None,ZLib,LZMA,Consts}                   │
│ Commons.Encryption.AES                                             │
│ Commons.Progress                                                   │
│ Commons.{Types,Consts,Exceptions}                                  │
│ Commons.{FPC,Compression.Defines}.inc                              │
└────────────────────────────────────────────────────────────────────┘
```

## Princípios arquiteturais

1. **`src/` flat** — sem subpastas; naming `<Module>.<Feature>.pas` atua como pasta virtual.
2. **Facade única** — consumidor escreve `uses ZipFileORM;` e ganha acesso a tudo.
3. **Commons.* = cross-format** — algoritmos reutilizáveis (AES, LZMA, ZLib) ficam aqui.
4. **`<Format>File.*` = format-only** — features exclusivas da spec do formato (ZIP64, UTF8 bit 11 GP flag, GzipStream inline em tar).
5. **TComponent na palette** — 10 componentes registráveis no Object Inspector com property categories.
6. **Cross-compiler** — Delphi D24..D37 (Win32+Win64) + FPC/Lazarus (Win32+Win64+Linux i386/x86_64).

## Build matrix

| Variante | dpk | BPL | Status build |
|---|---|---|---|
| Runtime Win32 | ZipFileORMD{24..29,37}.dpk | ZipFileORMDxx.bpl | ✅ 7/7 |
| Runtime Win64 | ZipFileORMD{24..29,37}.dpk | ZipFileORMDxx.bpl | ✅ 7/7 |
| Design Win32 | dclZipFileORMD{24..29,37}.dpk | dclZipFileORMDxx.bpl | ✅ 7/7 |
| Design Win64 | dclZipFileORMD29,D37.dpk | dclZipFileORMDxx.bpl | ✅ 2/2 (D29+D37) |
| **Total** | **14 dpks** | **23 BPLs** | **23/23 OK** |

## Diferenças v3.x → v4.0.0

| Aspecto | v3.x | v4.0.0 |
|---|---|---|
| Naming | `zipfile.pas` (minúsculo) | `ZipFile.pas` (PascalCase) |
| Commons | `tiCompress*`, `dzlib` (MCL legacy) | `Commons.Compression.*` |
| Facade pública | Nenhuma | `ZipFileORM.pas` (TArchive factory + uses agregado) |
| Events | `ZipFile.Events.pas` | `ZipFileORM.Events.pas` (promovido) |
| AES/LZMA/Progress | `ZipFile.{...}.pas` | `Commons.*` (promovido por cross-format reuse) |
| Naming policy | Ad-hoc | `.cursor/rules/backend-pascal-unit-naming_V1.6.0` |

Ver [Migracao_v3_to_v4.md](../Roadmap/Migracao_v3_to_v4.md) para guia de upgrade.

## Ver também

- [Modulos_V1.0.md](Modulos_V1.0.md) — decomposição detalhada por módulo
- [Commons_V1.0.md](Commons_V1.0.md) — utilitários cross-format
- [Camadas_V1.0.md](Camadas_V1.0.md) — separação de responsabilidades
- [FLOWCHART_V1.0.md](FLOWCHART_V1.0.md) — diagrama Mermaid de dependências
