---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# O que Falta — LhaFile

## Gaps identificados (SPEC v3 §17)

| ID | Descricao | Prioridade | Esforco estimado |
| --- | --- | --- | --- |
| P20 | Populacao de propriedades read-only (Level, HostOS, EntryCount) | Alta | ~3h |
| P27 | Populacao de metadados de entrada (metodo, tamanho original, CRC16, timestamp) | Alta | ~4h |
| P03 | Disparo de evento `OnEntryFound` | Media | ~2h |
| P04 | Disparo de evento `OnExtract` | Media | ~2h |
| — | Verificacao completa dos metodos -lh4..-lh7- (alem de compile-verified) | Baixa | ~10h |
| P70 | Documentacao XML inline | Baixa | ~3h |

## Gaps especificos do split v4.1

- Nenhuma interface `ILhaFile` publicada.
- O codec Huffman adaptativo (maior parte dos 1048 L) e monolitico — dificulta manutencao.
- `TLhaMethod` provavelmente e comparacao de string (5 chars) sem enum Pascal formal.
- Headers Level-0/1/2 provavelmente lidos com offsets manuais sem records tipados.
- CRC16 do header Level-2 e especifico do formato — verificar se validado ou ignorado.

## Pendencias de testes

- Smoke test requer fixture `Make-LhaFixture.ps1` — confirmar que o script gera LHA valido.
- Nenhum teste de descompressao -lh5- (mais comum no Windows).
- Nenhum teste de arquivo LHA com estrutura de subdiretorios.
- Sem teste de nomes de arquivo com caracteres Shift-JIS (codificacao original japonesa).
