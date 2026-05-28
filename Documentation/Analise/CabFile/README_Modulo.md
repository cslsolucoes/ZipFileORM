---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Modulo CabFile

## O que faz

Implementa `TCabFile`, componente TComponent que le e escreve arquivos Microsoft Cabinet (CAB) usando as APIs FDI (decompress) e FCI (compress) da biblioteca Wine/cabnet vendored. Suporta sets de cabinets multi-disco com `SetID` e `CabinetIndex`. E o unico formato proprietario Microsoft com suporte de escrita na biblioteca.

## Ficheiros em `src/`

| Ficheiro | Linhas | Papel |
| --- | --- | --- |
| `CabFile.pas` | 1267 | Classe `TCabFile` + `TCabCompressionType` + FFI para fdi.h/fci.h |
| `Cab.Fluent.pas` | — | Builder fluente para `TCabFile` |

## Capacidades

| Operacao | Suporte |
| --- | --- |
| Read (extracao) | Completo |
| Write (criacao) | Completo |
| Compressao MSZIP | Sim |
| Compressao LZX | Sim |
| Compressao Quantum | Parcial |
| Multi-cabinet set (SetID + CabinetIndex) | Sim |
| Cabinet continuacao (span) | Sim |

## Estado atual vs alvo v4.1

**Atual (v3/v4.0):** Classe maior (1267 L) em ficheiro unico com FFI inline e fluent separado em `Cab.Fluent.pas`.

**Alvo (v4.1 — split 5 ficheiros):**

| Ficheiro alvo | Conteudo |
| --- | --- |
| `CabFile.pas` | `TCabFile` + metodos fluentes inline |
| `CabFile.Interfaces.pas` | `ICabFile`, `ICabFileBuilder` |
| `CabFile.Consts.pas` | Resourcestrings rsCab* + magic `MSCF` + offsets |
| `CabFile.Types.pas` | `TCabCompressionType`, `TCabEntryRec`, records FCI/FDI |
| `CabFile.Exceptions.pas` | `ECabFile`, `ECabFDIError`, `ECabFCIError` (herdam de `EArchive`) |

---

*Referencia: SPEC v3 §5, §17 — P20, P23*
