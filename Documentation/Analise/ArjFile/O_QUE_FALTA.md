---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# O que Falta — ArjFile

## Gaps identificados (SPEC v3 §17)

| ID | Descricao | Prioridade | Esforco estimado |
| --- | --- | --- | --- |
| P20 | Populacao de propriedades read-only (HostOS, ArjVersion, NumFiles) | Alta | ~3h |
| P25 | Populacao de metadados de entrada (metodo, original size, CRC) | Alta | ~3h |
| P03 | Disparo de evento `OnEntryFound` | Media | ~2h |
| P04 | Disparo de evento `OnExtract` | Media | ~2h |
| — | Descompressao metodos ARJ 1-9 (deferred) | Deferred | ~30h |
| P70 | Documentacao XML inline | Baixa | ~2h |

## Gaps especificos do split v4.1

- Nenhuma interface `IArjFile` publicada.
- `TArjCompressionMethod` provavelmente e integer ou enum sem tipo nomeado.
- Magic bytes (`$60 $EA`) provavelmente hardcoded sem constante nomeada.
- Verificar: o cabecalho ARJ tem CRC16 (nao CRC32) — confirmar se validado na leitura.

## Pendencias de testes

- Smoke test requer fixture gerada por `Make-ArjFixture.ps1` — confirmar que o script existe e gera arquivo valido.
- Nenhum teste de arquivo ARJ com metodo 1 (tentativa deve lancar `EArjUnsupportedMethod`).
- Nenhum teste de ARJ multi-volume.
- Sem teste de ARJ com senha (metodo de criptografia ARJ).
