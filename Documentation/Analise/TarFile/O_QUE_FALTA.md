---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# O que Falta — TarFile

## Gaps identificados (SPEC v3 §17)

| ID | Descricao | Prioridade | Esforco estimado |
| --- | --- | --- | --- |
| P20 | Populacao de propriedades read-only (ArchiveSize, Format detectado) | Alta | ~4h |
| P22 | Populacao de metadados de entrada (mode, uid, gid, mtime) | Alta | ~4h |
| P03 | Disparo de evento `OnEntryFound` | Media | ~3h |
| P04 | Disparo de evento `OnExtract` | Media | ~3h |
| P70 | Documentacao XML inline | Media | ~4h |

## Gaps especificos do split v4.1

- `Tar.Fluent.pas` ainda existe separado — nao dissolvido em `TarFile.pas`.
- `ITarFile` inexistente — nenhum contrato de interface publicado.
- `Tar.GzipStream.pas` e tecnicamente compartilhado com `TarGzFile` mas nao esta em `Commons.*` — decisao de localizacao pendente.
- `TTarFormat` e enum inline em `TarFile.pas` sem `TarFile.Types.pas` proprio.
- Hierarquia de excecoes: verificar se herda de `EArchive` ou de `Exception` diretamente.

## Pendencias de testes

- Nenhum teste de round-trip PAX (metadados extendidos).
- Nenhum teste de arquivos TAR >2 GB (limite inteiro 32-bit nos offsets GNU).
- Nenhum teste de nomes de arquivo com caracteres Unicode (PAX extended headers).
