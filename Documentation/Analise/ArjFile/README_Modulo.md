---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Modulo ArjFile

## O que faz

Implementa `TArjFile`, componente TComponent de leitura de arquivos ARJ (formato de compressao legado dos anos 1990). Suporta metodo Store apenas (descompressao dos metodos 1-9 e deferred). E um dos quatro formatos read-only da biblioteca.

## Ficheiros em `src/`

| Ficheiro | Linhas | Papel |
| --- | --- | --- |
| `ArjFile.pas` | 553 | Classe `TArjFile` — parser de cabecalho ARJ + extracao Store |

## Capacidades

| Operacao | Suporte |
| --- | --- |
| Read (extracao Store) | Completo |
| Read (descompressao metodos 1-9) | Deferred |
| Write | Nao suportado |

## Estado atual vs alvo v4.1

**Atual (v3/v4.0):** Classe em ficheiro unico `ArjFile.pas`. Sem sub-modulos ou fluent (read-only nao requer builder elaborado).

**Alvo (v4.1 — split 5 ficheiros):**

| Ficheiro alvo | Conteudo |
| --- | --- |
| `ArjFile.pas` | `TArjFile` + metodo fluente de abertura inline |
| `ArjFile.Interfaces.pas` | `IArjFile` (read-only contract) |
| `ArjFile.Consts.pas` | Resourcestrings rsArj* + magic ARJ (`\x60\xEA`) + offsets de cabecalho |
| `ArjFile.Types.pas` | `TArjCompressionMethod`, `TArjEntryRec`, `TArjLocalHeader` record |
| `ArjFile.Exceptions.pas` | `EArjFile`, `EArjUnsupportedMethod`, `EArjCorrupted` (herdam de `EArchive`) |

---

*Referencia: SPEC v3 §10, §17 — P20, P25*
