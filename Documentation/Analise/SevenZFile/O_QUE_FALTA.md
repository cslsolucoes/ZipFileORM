---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# O que Falta — SevenZFile

## Gaps identificados (SPEC v3 §17)

| ID | Descricao | Prioridade | Esforco estimado |
| --- | --- | --- | --- |
| P20 | Populacao de propriedades read-only (Solid, NumBlocks, Method detectado, Version) | Alta | ~6h |
| P24 | Populacao de propriedades de entrada (CRC, tamanho comprimido, metodo por entrada) | Alta | ~5h |
| P40 | Criptografia AES-256 em escrita 7z | Comercial | ~15h |
| P41 | Multi-volume write 7z | Comercial | ~20h |
| P03 | Disparo de evento `OnEntryFound` | Media | ~3h |
| P04 | Disparo de evento `OnExtract` com progresso | Media | ~4h |
| P70 | Documentacao XML inline | Media | ~8h |

## Gaps especificos do split v4.1

- `SevenZ.Fluent.pas` ainda existe separado com tunagem LZMA (metodos mais complexos da biblioteca).
- Nenhuma interface `ISevenZFile` publicada.
- Codigos de retorno LZMA SDK (`SZ_ERROR_*`) sao inteiros sem enum Pascal.
- Records de cabecalho 7z provavelmente inline no corpo da classe sem record tipado separado.
- Interacao entre tunagem LZMA (FastBytes, MatchFinder, DictionarySize) e flags Solid/MultiThread nao documentada — risco de combinacao invalida.

## Pendencias de testes

- Nenhum teste de arquivo 7z solido com multiplos arquivos.
- Nenhum teste multi-thread (verificar thread-safety da integracao LZMA).
- Nenhum teste SFX (self-extracting).
- Sem cobertura de filtro Delta para arquivos binarios (exe, dll).
- Nenhum teste de round-trip LZMA2 com arquivo >1 GB.
