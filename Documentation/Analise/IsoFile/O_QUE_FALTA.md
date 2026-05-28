---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# O que Falta — IsoFile

## Gaps identificados (SPEC v3 §17)

| ID | Descricao | Prioridade | Esforco estimado |
| --- | --- | --- | --- |
| P20 | Populacao de propriedades read-only do PVD (VolumeID, PublisherID, VolumeSize, LogicalBlockSize) | Alta | ~4h |
| P26 | Populacao de metadados de entrada (data/hora ISO 9660, tamanho, localizacao no setor) | Alta | ~3h |
| P03 | Disparo de evento `OnEntryFound` (com nome e tamanho) | Media | ~2h |
| P04 | Disparo de evento `OnExtract` | Media | ~2h |
| — | Suporte a Rock Ridge (metadados Unix/symlinks) | Nao planejado | ~20h |
| P70 | Documentacao XML inline | Baixa | ~3h |

## Gaps especificos do split v4.1

- Nenhuma interface `IIsoFile` publicada.
- Records ISO provavelmente inline no corpo da classe sem tipo `TIsoPVD` nomeado separado.
- Both-endian fields do ISO 9660 podem nao estar modelados como records proprios — possivel uso de offsets manuais.
- `VolumeID`, `SystemID`, `PublisherID` provavelmente nao populados (P20).
- Joliet: nomes sao UCS-2 big-endian — verificar se ha conversao correta para `UnicodeString` Delphi/FPC.

## Pendencias de testes

- Smoke test requer fixture `Make-IsoFixture.ps1` — confirmar que o script gera ISO 9660 + Joliet valido.
- Nenhum teste de ISO com nomes de arquivo Unicode (Joliet).
- Nenhum teste de ISO com estrutura de subdiretorios profunda (>8 niveis — limite ISO 9660 base).
- Sem teste de arquivo ISO com arquivos de tamanho zero.
