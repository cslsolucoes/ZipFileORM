---
internal_file_version: 1.0.0
generated_by: manual
date: 2026-05-28
---

# Documentation Hub — ZipFileORM v4.0.0

Hub central da documentação do projeto. Use como índice para navegar.

## Estrutura

| Pasta | Conteúdo | Status |
|---|---|---|
| [Arquitetura/](Arquitetura/) | Overview do projeto, decomposição de módulos, diagrama de camadas, FLOWCHART Mermaid | ✅ base |
| [Analise/](Analise/) | Análise técnica unit/class/method por módulo (CHECKLIST, PASSO_A_PASSO, O_QUE_FALTA) | 🟡 esqueleto |
| [API/](API/) | Documentação per-classe/interface seguindo template padrão (7 seções) | 🟡 esqueleto |
| [Regras de Negocio/](Regras%20de%20Negocio/) | RN-Format-Detection, RN-Compression-Methods, RN-Encryption-AES, RN-Streaming-Rules, RN-Naming-Conventions | ✅ base |
| [Roadmap/](Roadmap/) | Roadmap v4.x + Migração v3→v4 | ✅ base |
| [Esboco de Telas/](Esboco%20de%20Telas/) | N/A (library sem UI) | ❌ N/A |
| [Backup/](Backup/) | Documentos supersedidos | (vazio) |
| [spec/](spec/) | SPEC histórico v3.x (preservado como referência) | 📦 legacy |

## Geração planejada (Onda 7)

Esta documentação será expandida em fases via sub-agents:

| Passo | Agent/Skill | Saída |
|---|---|---|
| 7.1 | documentation-agent-orchestrator | Bootstrap inicial (concluído — esta estrutura) |
| 7.2 | documentation-agent-class-scanner | Inventário JSON de classes/interfaces em src/ |
| 7.3 | documentation-agent-class-writer | API/<Module>/<Type>.md (7 seções) |
| 7.4 | documentation-agent-class-indexer | API/README.md + API/FLOWCHART.md |
| 7.5 | documentation-agent-architecture | Arquitetura/{Overview,Modulos,Commons,Camadas,FLOWCHART}_V1.0.md |
| 7.6 | documentation-paste_analysis_unit_class_method | Analise/<Module>/* (por classe) |
| 7.7 | documentation-agent-rules | Regras de Negocio/RN-*.md |
| 7.8 | documentation-agent-roadmap | Roadmap/{Roadmap,Migracao_v3_to_v4}.md |
| 7.9 | documentation-agent-review | Compliance review |
| 7.10 | documentation-file-versioning | Frontmatter `internal_file_version: 1.0.0` em todos |

## Convenções

- Todos os ficheiros `.md` carregam frontmatter YAML mínimo (`internal_file_version`, `generated_by`, `date`).
- Naming: `<Nome>_V<X.Y.Z>.md` para documentos versionados; `README.md` para índices de pasta.
- Encoding: UTF-8 (sem BOM).
- Sem escapes `#NNN` (conforme `.cursor/rules/pascal-encoding-no-escapes_V1.0.0.mdc`).

## Versionamento

| Versão | Data | Mudanças |
|---|---|---|
| V1.0.0 | 2026-05-28 | Bootstrap inicial da estrutura |
