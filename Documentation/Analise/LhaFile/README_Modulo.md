---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Modulo LhaFile

## O que faz

Implementa `TLhaFile`, componente TComponent de leitura de arquivos LZH/LHA (formato popular no Japao nos anos 1990). Suporta metodo -lh0- (Store) plenamente e metodos -lh4- a -lh7- com compilacao verificada. E o maior dos quatro formatos read-only (1048 linhas) devido a complexidade do algoritmo de codificacao Huffman adaptativo.

## Ficheiros em `src/`

| Ficheiro | Linhas | Papel |
| --- | --- | --- |
| `LhaFile.pas` | 1048 | Classe `TLhaFile` — parser LHA + descompressao -lh0-, -lh4..7- |

## Capacidades

| Operacao | Suporte |
| --- | --- |
| Read (extracao -lh0- Store) | Completo |
| Read (descompressao -lh4..-lh7-) | Compile-verified |
| Write | Nao suportado |
| Formato LHA Level-0 header | Sim |
| Formato LHA Level-1 header | Sim |
| Formato LHA Level-2 header | Sim |

## Estado atual vs alvo v4.1

**Atual (v3/v4.0):** Classe em ficheiro unico `LhaFile.pas` com codec Huffman interno. Sem sub-modulos.

**Alvo (v4.1 — split 5 ficheiros):**

| Ficheiro alvo | Conteudo |
| --- | --- |
| `LhaFile.pas` | `TLhaFile` + metodo fluente de abertura inline |
| `LhaFile.Interfaces.pas` | `ILhaFile` (read-only contract) |
| `LhaFile.Consts.pas` | Resourcestrings rsLha* + identificadores de metodo (`-lh0-`, `-lh4-`, etc.) |
| `LhaFile.Types.pas` | `TLhaMethod` enum, `TLhaHeaderLevel` enum, `TLhaLocalHeader` record |
| `LhaFile.Exceptions.pas` | `ELhaFile`, `ELhaUnsupportedMethod`, `ELhaCorrupted` (herdam de `EArchive`) |

---

*Referencia: SPEC v3 §12, §17 — P20, P27*
