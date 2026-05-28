---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Modulo UUE.Stream

## O que faz

Fornece `TUUEEncodeStream` e `TUUEDecodeStream`, wrappers de TStream para codificacao e decodificacao UUencoding (formato legado de codificacao binaria-para-texto usado em newsgroups Unix). Nao e um componente TComponent registrado na paleta. Inclui `UUE.Fluent.pas` com builder fluente.

## Ficheiros em `src/`

| Ficheiro | Linhas | Papel |
| --- | --- | --- |
| `UUE.Stream.pas` | 214 | `TUUEEncodeStream`, `TUUEDecodeStream` — codec UUencoding puro Pascal |
| `UUE.Fluent.pas` | 160 | Builder fluente para encode/decode UUE |

## Capacidades

| Operacao | Suporte |
| --- | --- |
| Codificacao UUencoding | Completo |
| Decodificacao UUencoding | Completo |
| Cabecalho `begin` / rodape `end` | Sim |
| Multiplas secoes (`begin ... end ... begin`) | Verificar |

## Estado atual vs alvo v4.1

**Atual (v3/v4.0):** Dois ficheiros (`UUE.Stream.pas` + `UUE.Fluent.pas`). Implementacao pura Pascal sem dependencias de SDK C.

**Alvo (v4.1 — split 5 ficheiros):**

| Ficheiro alvo | Conteudo |
| --- | --- |
| `UUE.Stream.pas` | Classes stream + metodos fluentes inline (dissolver `UUE.Fluent.pas`) |
| `UUE.Interfaces.pas` | `IUUEEncodeStream`, `IUUEDecodeStream`, `IUUEBuilder` |
| `UUE.Consts.pas` | Resourcestrings rsUUE* + constantes (`begin `, `end`, charset UUE) |
| `UUE.Types.pas` | `TUUEPermission` (tipo do campo mode do header `begin`) |
| `UUE.Exceptions.pas` | `EUUEStream`, `EUUEInvalidHeader`, `EUUECorrupted` (herdam de `EArchive`) |

---

*Referencia: SPEC v3 §15, §17*
