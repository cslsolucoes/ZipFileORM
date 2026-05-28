---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# O que Falta — UUE.Stream

## Gaps identificados (SPEC v3 §17)

| ID | Descricao | Prioridade | Esforco estimado |
| --- | --- | --- | --- |
| — | Sem `TUUEFile` TComponent — apenas stream utilitario | Baixa | ~6h |
| — | Suporte a multiplas secoes (`begin...end...begin...end`) | Baixa | ~4h |
| P70 | Documentacao XML inline | Baixa | ~1h |
| — | Cobertura de testes na suite DUnitX | Media | ~3h |

## Gaps especificos do split v4.1

- `UUE.Fluent.pas` ainda existe separado.
- Nenhuma interface `IUUEEncodeStream` publicada.
- Charset UUE provavelmente hardcoded como string literal sem constante nomeada.
- `TUUEPermission` provavelmente nao existe como tipo — campo octal lido como inteiro anonimo.
- Nao ha verificacao de checksum de linha UUE (o formato tem um character de checksum implicito).

## Pendencias de testes

- Nenhum teste de round-trip encode+decode com dados binarios aleatorios.
- Nenhum teste de arquivo UUE com nome de arquivo contendo espacos.
- Nenhum teste de dados UUE malformados (linha muito longa, charset invalido).
- FPC: verificar comportamento do codec com diferentes codepages de sistema.
