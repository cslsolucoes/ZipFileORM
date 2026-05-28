---
internal_file_version: 1.0.0
generated_by: manual
date: 2026-05-28
---

# MigraÃ§Ã£o ZipFileORM v3.x â†’ v4.0.0 â€” Guia do Consumidor

## TL;DR

```pascal
// v3.x:
uses zipfile, ZipFile.Encryption.AES, ZipFile.Compression.LZMA;

// v4.0.0:
uses ZipFileORM;   // basta isso â€” facade re-exporta tudo
```

## MudanÃ§as de naming (breaking)

| v3.x | v4.0.0 | Notas |
|---|---|---|
| `unit zipfile;` | `unit ZipFile;` | PascalCase consistente |
| `tiCompress`, `tiCompressNone`, `tiCompressZLib`, `tiConstants` | `Commons.Compression.{Base,None,ZLib,Consts}` | RefatoraÃ§Ã£o legacy MCL |
| `dzlib` | `Commons.Compression.ZLib.Bridge` | FPC-only bridge |
| `ZipFile.Events` | `ZipFileORM.Events` | Promovido para facade |
| `ZipFile.Encryption.AES` | `Commons.Encryption.AES` | Promovido para Commons (cross-format) |
| `ZipFile.Compression.LZMA` | `Commons.Compression.LZMA` | Promovido para Commons (cross-format) |
| `ZipFile.Progress` | `Commons.Progress` | Promovido para Commons (cross-format) |
| `Tar.GzipStream` | `TarFile.GzipStream` | Naming consistente |
| `Bzip2.Bzip2Stream` | `Bzip2.Stream` | Remove redundÃ¢ncia |
| `UUE.UUEStream` | `UUE.Stream` | Remove redundÃ¢ncia |
| `Archive.Open` | `Archive.Open` (preservado) | Detection (mantido como auxiliar) |

## Novos namespaces

| Namespace | ConteÃºdo |
|---|---|
| `ZipFileORM.*` | Facade pÃºblica (4 units): `ZipFileORM`, `.Interfaces`, `.Compression`, `.Events` |
| `Commons.*` | 13 utilitÃ¡rios cross-format |
| `<Format>File` | 10 mÃ³dulos format (TComponent classes) |
| `<Format>File.<SubConcept>` | Sub-mÃ³dulos format-only (ZIP64, UTF8, Streaming, GzipStream) |
| `<Helper>.Stream` | Helper streams: Bzip2, UUE, ZCompress.Lzw |

## Refactor checklist (consumidor)

1. **Trocar uses:** `uses zipfile` â†’ `uses ZipFileORM`
2. **Remover uses especÃ­ficos:** `ZipFile.Events`, `ZipFile.Encryption.AES`, `ZipFile.Compression.LZMA`, `ZipFile.Progress` â€” todos agora vÃªm da facade ou de `Commons.*`.
3. **Atualizar paths em DPRs/DPKs:** se referenciava `..\src\tiCompress.pas` â†’ `..\src\Commons.Compression.Base.pas`.
4. **Recompilar packages:** rodar `tools/Build-AllDelphis.ps1`.

## O que NÃƒO mudou

- âœ… Classes `T<Format>File` e suas propriedades published (Active, FileName, EntryCount, etc.)
- âœ… MÃ©todos pÃºblicos: `Open`, `Close`, `ReadAsBytes`, `ReadAsString`, `GetEntryStream`
- âœ… Eventos: `OnBeforeOpen`, `OnAfterOpen`, `OnEntryFound`, etc.
- âœ… Fluent API: `WithFileName`, `ThatOpens`, etc.
- âœ… Palette page: `ZipFileORM` (10 componentes)
- âœ… Comportamento funcional dos formatos
- âœ… Compatibilidade fixtures binÃ¡rias

## DiferenÃ§as funcionais (zero)

v4.0.0 Ã© **refactor de naming + arquitetura, sem mudanÃ§a comportamental**. Todos os testes DUnitX da v3.x continuam passando apÃ³s atualizaÃ§Ã£o dos `uses`.

## Rollback

A origem `c:\Users\Public\Documents\Embarcadero\Studio\Outros\zipfile` (v3.12.2) estÃ¡ preservada intacta. Para reverter, basta usar a versÃ£o antiga â€” nÃ£o hÃ¡ aÃ§Ãµes destrutivas em v4.0.0.
