---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Modulo Bzip2.Stream

## O que faz

Fornece `TBzip2DecompressStream` e `TBzip2CompressStream`, wrappers de TStream para compressao e descompressao bzip2. Nao e um componente TComponent registrado na paleta — e uma unidade de suporte usada diretamente via stream. Inclui `Bzip2.Fluent.pas` com builder fluente. Usa o SDK bzip2 vendorizado compilado para `Library/`.

## Ficheiros em `src/`

| Ficheiro | Linhas | Papel |
| --- | --- | --- |
| `Bzip2.Stream.pas` | 384 | `TBzip2DecompressStream`, `TBzip2CompressStream` — FFI bzip2 SDK |
| `Bzip2.Fluent.pas` | 159 | Builder fluente para compressao/descompressao bzip2 |

## Capacidades

| Operacao | Suporte |
| --- | --- |
| Compressao bzip2 (stream) | Completo |
| Descompressao bzip2 (stream) | Completo |
| Niveis de compressao 1-9 | Sim |
| Uso como TStream wrapper | Sim |

## Estado atual vs alvo v4.1

**Atual (v3/v4.0):** Dois ficheiros (`Bzip2.Stream.pas` + `Bzip2.Fluent.pas`). Nao ha `TBzip2File` componente — apenas streams utilitarios.

**Alvo (v4.1 — split 5 ficheiros):**

| Ficheiro alvo | Conteudo |
| --- | --- |
| `Bzip2.Stream.pas` | Classes stream + metodos fluentes inline (dissolver `Bzip2.Fluent.pas`) |
| `Bzip2.Interfaces.pas` | `IBzip2Stream`, `IBzip2Builder` |
| `Bzip2.Consts.pas` | Resourcestrings rsBzip2* + magic `BZh` + bloco magic `\x31\x41\x59\x26\x53\x59` |
| `Bzip2.Types.pas` | `TBzip2CompressionLevel` enum + records FFI bzip2 SDK |
| `Bzip2.Exceptions.pas` | `EBzip2Stream`, `EBzip2DataError`, `EBzip2MemError` (herdam de `EArchive`) |

---

*Referencia: SPEC v3 §14, §17 — P20*
