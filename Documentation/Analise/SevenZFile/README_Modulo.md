---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Modulo SevenZFile

## O que faz

Implementa `TSevenZFile`, componente TComponent que le e escreve arquivos 7Z usando LZMA2 via `Lzma2Enc.c` vendorizado do SDK LZMA. Suporta Store e LZMA2, modo solido, multi-thread, SFX (self-extracting), filtros Delta e pre-filtros. E o componente com mais propriedades tunáveis de compressao da biblioteca.

## Ficheiros em `src/`

| Ficheiro | Linhas | Papel |
| --- | --- | --- |
| `SevenZFile.pas` | 1491 | Classe `TSevenZFile` + enums LZMA + FFI para 7z SDK |
| `SevenZ.Fluent.pas` | — | Builder fluente para `TSevenZFile` |

## Capacidades

| Operacao | Suporte |
| --- | --- |
| Read (extracao) | Completo |
| Write (criacao) | Completo |
| Metodo Store | Sim |
| Metodo LZMA2 | Sim |
| Modo solido | Sim |
| Multi-thread | Sim |
| SFX | Sim |
| Criptografia AES-256 | Pendente (P40) |
| Multi-volume write | Pendente (P41) |
| Filtro Delta | Sim |
| Tune LZMA (FastBytes, MatchFinder, DictSize) | Sim |

## Estado atual vs alvo v4.1

**Atual (v3/v4.0):** Classe maior (1491 L) com enums e FFI inline. Fluent separado em `SevenZ.Fluent.pas`.

**Alvo (v4.1 — split 5 ficheiros):**

| Ficheiro alvo | Conteudo |
| --- | --- |
| `SevenZFile.pas` | `TSevenZFile` + metodos fluentes inline |
| `SevenZFile.Interfaces.pas` | `ISevenZFile`, `ISevenZFileBuilder` |
| `SevenZFile.Consts.pas` | Resourcestrings rsSevenZ* + magic `7z\xBC\xAF\x27\x1C` + offsets |
| `SevenZFile.Types.pas` | `TSevenZMethod`, `TSevenZFilter`, `TSevenZMatchFinder`, records de header |
| `SevenZFile.Exceptions.pas` | `ESevenZFile`, `ESevenZLZMAError`, `ESevenZHeaderCorrupted` (herdam de `EArchive`) |

---

*Referencia: SPEC v3 §4, §17 — P20, P24, P40, P41*
