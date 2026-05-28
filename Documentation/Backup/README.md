---
internal_file_version: 1.0.0
generated_by: manual
date: 2026-05-28
---

# Backup — Documentos supersedidos

Pasta destino para documentos que forem **supersedidos** ao longo da evolução do projeto. Gerenciada por `documentation-agent-superseded-definition`.

## Estado atual

Vazia — nenhum documento foi supersedido ainda. v4.0.0 é refactor inaugural com nova arquitetura canônica.

## Regras

- Documentos supersedidos NÃO são apagados — são movidos para esta pasta com sufixo `_SUPERSEDED_YYYYMMDD`
- Cada documento supersedido carrega frontmatter `superseded_by: <novo_doc>` apontando para o substituto
- Critérios de "supersedido" estão definidos em `.cursor/rules/documentation-constitution-policies.mdc` (skill canônica `documentation-constitution-policies`)

## Histórico

Nenhum item ainda.
