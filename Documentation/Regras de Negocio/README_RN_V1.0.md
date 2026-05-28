---
internal_file_version: 1.0.0
generated_by: manual
date: 2026-05-28
---

# Regras de Negócio — ZipFileORM v4.0.0

Documentos de regras técnicas do projeto. Geração detalhada (formato padrão `documentation-business-rules_V3.1.0` com 12 seções) pendente para sessões futuras.

## Índice

| RN | Tópico | Fonte primária (src/) | Detalhamento |
|---|---|---|---|
| [RN-Format-Detection.md](RN-Format-Detection.md) | Auto-detect de formato por magic bytes | `Archive.Open.pas` | 🟡 base |
| [RN-Compression-Methods.md](RN-Compression-Methods.md) | Matriz métodos de compressão por formato | `ZipfileORM.Compression.pas` | 🟡 base |
| [RN-Encryption-AES.md](RN-Encryption-AES.md) | AES-256 WinZip AE-2 | `Commons.Encryption.AES.pas` | 🟡 base |
| [RN-Streaming-Rules.md](RN-Streaming-Rules.md) | Contratos de stream read-only | `ZipFile.Streaming.pas` | 🟡 base |
| [RN-Naming-Conventions.md](RN-Naming-Conventions.md) | UTF-8 bit 11, ZIP64 limits, TAR formats | `ZipFile.UTF8.pas`, `ZipFile.ZIP64.pas`, `TarFile.pas` | 🟡 base |

## Status

Versão **base** (slim) — cada RN tem 5 campos:
- **Contexto** — quando aplica
- **Regra** — declaração formal
- **Implementação** — referência ao código
- **Casos de borda** — exceções e limites
- **Referências** — fonte canônica em src/

A expansão para o formato completo (12 seções: Pre-condições, Fluxo principal, Fluxos de exceção, Validações, Tabelas BD, Impacto em outras RNs, LGPD, Esboço de implementação, Notas, Assinaturas) está prevista para v4.5 (Roadmap).
