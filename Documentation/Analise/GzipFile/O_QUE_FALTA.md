---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# O que Falta — GzipFile

## Gaps identificados (SPEC v3 §17)

| ID | Descricao | Prioridade | Esforco estimado |
| --- | --- | --- | --- |
| P20 | Populacao de propriedades read-only (OriginalSize, MTime, OSType, OriginalName) | Alta | ~3h |
| P03 | Disparo de evento `OnEntryFound` (unico entry) | Baixa | ~1h |
| P04 | Disparo de evento `OnExtract` com progresso | Media | ~2h |
| P70 | Documentacao XML inline | Baixa | ~2h |

## Gaps especificos do split v4.1

- Sem interface `IGzipFile` — consumidores dependem da classe concreta.
- Nenhum `GzipFile.Fluent.pas` identificado — verificar se fluent existe ou se e uma lacuna.
- `TGzipOsType` e `TGzipHeader` provavelmente sao tipos inline ou constantes anonimas.
- Magic bytes (`\x1f\x8b`) provavelmente hardcoded no corpo do metodo de deteccao.

## Pendencias de testes

- Nenhum teste de arquivo .gz corrompido (CRC invalido no trailer).
- Nenhum teste de decompressao com arquivo vazio (edge case: 0 bytes).
- Nenhum teste de nome original UTF-8 no header gzip (FNAME field com flag FHCRC).
