---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Modulo ZCompress.LzwStream

## O que faz

Fornece `TLzwCompressStream`, wrapper de TStream para compressao LZW — o algoritmo usado pelo formato Unix `.Z` (compress). Nao e um componente TComponent registrado na paleta. Inclui `ZCompress.Fluent.pas` com builder fluente. Util para interoperabilidade com arquivos `.Z` legados do Unix.

## Ficheiros em `src/`

| Ficheiro | Linhas | Papel |
| --- | --- | --- |
| `ZCompress.LzwStream.pas` | 352 | `TLzwCompressStream` — codec LZW 16-bit puro Pascal |
| `ZCompress.Fluent.pas` | 142 | Builder fluente para compressao/descompressao LZW |

## Capacidades

| Operacao | Suporte |
| --- | --- |
| Compressao LZW (stream) | Completo |
| Descompressao LZW (stream) | Verificar |
| Formato Unix `.Z` (magic + header) | Verificar |
| Bits: 9..16 | Verificar |

## Estado atual vs alvo v4.1

**Atual (v3/v4.0):** Dois ficheiros (`ZCompress.LzwStream.pas` + `ZCompress.Fluent.pas`). Implementacao pura Pascal.

**Alvo (v4.1 — split 5 ficheiros):**

| Ficheiro alvo | Conteudo |
| --- | --- |
| `ZCompress.LzwStream.pas` | `TLzwCompressStream` + metodos fluentes inline (dissolver `ZCompress.Fluent.pas`) |
| `ZCompress.Interfaces.pas` | `ILzwCompressStream`, `IZCompressBuilder` |
| `ZCompress.Consts.pas` | Resourcestrings rsZCompress* + magic Unix compress (`\x1F\x9D`) + parametros LZW |
| `ZCompress.Types.pas` | `TLzwBits` (enum 9..16), `TLzwFlag` enum |
| `ZCompress.Exceptions.pas` | `EZCompressStream`, `ELzwCorrupted` (herdam de `EArchive`) |

---

*Referencia: SPEC v3 §16, §17*
