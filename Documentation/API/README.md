---
internal_file_version: 1.0.0
generated_by: manual
date: 2026-05-28
---

# API Reference — ZipFileORM v4.0.0

Documentação per-classe/interface. Geração completa por classe via `documentation-agent-class-writer` em sessões futuras (15 dias úteis estimados, ~75 documentos finais com 7 seções cada).

## Estado atual

Esqueleto navegável por módulo. Cada subpasta tem README placeholder.

## Índice por módulo

### Facade pública (`ZipFileORM.*`)

| Módulo | Classes/Interfaces principais |
|---|---|
| [ZipFileORM/](ZipFileORM/) | `TArchive` (factory class), `TArchiveFormat` (re-export) |
| [ZipFileORM.Interfaces/](ZipFileORM.Interfaces/) | `IArchive`, `IArchiveEntry`, `IArchiveBuilder` |
| [ZipFileORM.Compression/](ZipFileORM.Compression/) | `TCompressionMethod`, helpers |
| [ZipFileORM.Events/](ZipFileORM.Events/) | 15 `TArchive*Event` types + `TArchiveReplaceAction` enum |

### Commons (cross-format)

| Módulo | Classes/Types |
|---|---|
| [Commons/](Commons/) | `EArchive` hierarchy, `TArchiveSearchRec`, `TArchiveProgressInfo`, `TArchiveCapability` |

### Módulos format (10)

| Módulo | Componente principal |
|---|---|
| [ZipFile/](ZipFile/) | `TZipFile` |
| [TarFile/](TarFile/) | `TTarFile`, `TTarFormat` |
| [TarGzFile/](TarGzFile/) | `TTarGzFile` |
| [GzipFile/](GzipFile/) | `TGzipFile` |
| [CabFile/](CabFile/) | `TCabFile`, `TCabCompressionType` |
| [SevenZFile/](SevenZFile/) | `TSevenZFile`, `TLzmaPreFilter`, `TMatchFinder` |
| [ArjFile/](ArjFile/) | `TArjFile` |
| [IsoFile/](IsoFile/) | `TIsoFile` |
| [LhaFile/](LhaFile/) | `TLhaFile` |
| [RarFile/](RarFile/) | `TRarFile` |

### Helper streams (3)

| Módulo | Classes |
|---|---|
| [Bzip2.Stream/](Bzip2.Stream/) | `TBzip2DecompressStream`, `TBzip2CompressStream` |
| [UUE.Stream/](UUE.Stream/) | `TUUEEncodeStream`, `TUUEDecodeStream` |
| [ZCompress.LzwStream/](ZCompress.LzwStream/) | `TLzwCompressStream` |

## Template (a ser usado em sessões futuras)

Cada classe receberá um `.md` com 7 seções:
1. **O que é** — definição e propósito
2. **Características** — propriedades-chave
3. **Engine** — algoritmo/SDK underlying
4. **Funcionalidades** — métodos principais
5. **Aplicabilidades** — casos de uso
6. **Exemplos de Uso** — code snippets
7. **Relacionamentos** — dependências

Trigger: rodar `documentation-agent-class-writer` apontando para `Documentation/API/inventory_V1.0.json` (a ser gerado).

## Ver também

- [Documentation/Analise/](../Analise/) — análise técnica unit/class/method
- [Documentation/Arquitetura/](../Arquitetura/) — visão arquitetural
