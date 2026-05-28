---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# O que Falta — ZCompress.LzwStream

## Gaps identificados (SPEC v3 §17)

| ID | Descricao | Prioridade | Esforco estimado |
| --- | --- | --- | --- |
| — | Sem `TZCompressFile` TComponent — apenas stream utilitario | Baixa | ~6h |
| — | Descompressao LZW (se nao implementada) — verificar `TLzwCompressStream` | Media | ~8h |
| — | Suporte completo ao formato Unix `.Z` (magic + header + decompress) | Media | ~6h |
| P70 | Documentacao XML inline | Baixa | ~1h |
| — | Cobertura de testes na suite DUnitX | Media | ~3h |

## Gaps especificos do split v4.1

- `ZCompress.Fluent.pas` ainda existe separado.
- Nenhuma interface `ILzwCompressStream` publicada.
- O nome `TLzwCompressStream` sugere apenas compressao — verificar se ha `TLzwDecompressStream` ou se a descompressao e feita pela mesma classe.
- Magic bytes Unix compress (`$1F $9D`) provavelmente nao validados na leitura.
- `TLzwMaxBits` provavelmente e apenas integer sem tipo alias.
- Block reset mode: verificar se implementado corretamente (afeta compatibilidade com Unix compress).

## Pendencias de testes

- Nenhum teste de round-trip com arquivo `.Z` gerado pelo Unix compress real.
- Nenhum teste de stream vazio.
- Nenhum teste com bits=9 (menor dicionario) vs bits=16 (maior).
- FPC: verificar comportamento do codec em arquiteturas little-endian vs big-endian.
