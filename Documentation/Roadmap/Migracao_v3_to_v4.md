---
internal_file_version: 1.0.0
generated_by: manual
date: 2026-05-28
---

# Migração ZipFileORM v3.x → v4.0.0 — Guia do Consumidor

## TL;DR

```pascal
// v3.x:
uses zipfile, ZipFile.Encryption.AES, ZipFile.Compression.LZMA;

// v4.0.0:
uses ZipFileORM;   // basta isso — facade re-exporta tudo
```

## Mudanças de naming (breaking)

| v3.x | v4.0.0 | Notas |
|---|---|---|
| `unit zipfile;` | `unit ZipFile;` | PascalCase consistente |
| `tiCompress`, `tiCompressNone`, `tiCompressZLib`, `tiConstants` | `Commons.Compression.{Base,None,ZLib,Consts}` | Refatoração legacy MCL |
| `dzlib` | `Commons.Compression.ZLib.Bridge` | FPC-only bridge |
| `ZipFile.Events` | `ZipFileORM.Events` | Promovido para facade |
| `ZipFile.Encryption.AES` | `Commons.Encryption.AES` | Promovido para Commons (cross-format) |
| `ZipFile.Compression.LZMA` | `Commons.Compression.LZMA` | Promovido para Commons (cross-format) |
| `ZipFile.Progress` | `Commons.Progress` | Promovido para Commons (cross-format) |
| `Tar.GzipStream` | `TarFile.GzipStream` | Naming consistente |
| `Bzip2.Bzip2Stream` | `Bzip2.Stream` | Remove redundância |
| `UUE.UUEStream` | `UUE.Stream` | Remove redundância |
| `Archive.Open` | `Archive.Open` (preservado) | Detection (mantido como auxiliar) |

## Novos namespaces

| Namespace | Conteúdo |
|---|---|
| `ZipFileORM.*` | Facade pública (4 units): `ZipFileORM`, `.Interfaces`, `.Compression`, `.Events` |
| `Commons.*` | 13 utilitários cross-format |
| `<Format>File` | 10 módulos format (TComponent classes) |
| `<Format>File.<SubConcept>` | Sub-módulos format-only (ZIP64, UTF8, Streaming, GzipStream) |
| `<Helper>.Stream` | Helper streams: Bzip2, UUE, ZCompress.Lzw |

## Refactor checklist (consumidor)

1. **Trocar uses:** `uses zipfile` → `uses ZipFileORM`
2. **Remover uses específicos:** `ZipFile.Events`, `ZipFile.Encryption.AES`, `ZipFile.Compression.LZMA`, `ZipFile.Progress` — todos agora vêm da facade ou de `Commons.*`.
3. **Atualizar paths em DPRs/DPKs:** se referenciava `..\src\tiCompress.pas` → `..\src\Commons.Compression.Base.pas`.
4. **Recompilar packages:** rodar `tools/Build-AllDelphis.ps1`.

## O que NÃO mudou

- ✅ Classes `T<Format>File` e suas propriedades published (Active, FileName, EntryCount, etc.)
- ✅ Métodos públicos: `Open`, `Close`, `ReadAsBytes`, `ReadAsString`, `GetEntryStream`
- ✅ Eventos: `OnBeforeOpen`, `OnAfterOpen`, `OnEntryFound`, etc.
- ✅ Fluent API: `WithFileName`, `ThatOpens`, etc.
- ✅ Palette page: `ZipFileORM` (10 componentes)
- ✅ Comportamento funcional dos formatos
- ✅ Compatibilidade fixtures binárias

## Diferenças funcionais (zero)

v4.0.0 é **refactor de naming + arquitetura, sem mudança comportamental**. Todos os testes DUnitX da v3.x continuam passando após atualização dos `uses`.

## Rollback

A origem `c:\Users\Public\Documents\Embarcadero\Studio\Outros\zipfile` (v3.12.2) está preservada intacta. Para reverter, basta usar a versão antiga — não há ações destrutivas em v4.0.0.
