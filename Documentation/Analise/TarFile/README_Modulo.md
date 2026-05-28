---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Modulo TarFile

## O que faz

Implementa `TTarFile`, componente TComponent que le e escreve arquivos TAR nos formatos POSIX ustar, GNU tar e PAX. Suporta metadados Unix (modo, owner, timestamps). Inclui `TTarFormat` enum para selecao de variante de formato.

## Ficheiros em `src/`

| Ficheiro | Linhas | Papel |
| --- | --- | --- |
| `TarFile.pas` | 738 | Classe `TTarFile` + enum `TTarFormat` + logica read/write |
| `Tar.GzipStream.pas` | — | `TGzipReadStream` / `TGzipWriteStream` (compartilhado com TarGzFile) |
| `Tar.Fluent.pas` | — | Builder fluente para `TTarFile` |

## Capacidades

| Operacao | Suporte |
| --- | --- |
| Read (extracao) | Completo |
| Write (criacao/append) | Completo |
| Formato ustar | Sim |
| Formato GNU tar | Sim |
| Formato PAX | Sim |
| Metadados Unix (mode/owner) | Sim |
| Compressao gzip integrada | Nao (usar TTarGzFile) |

## Estado atual vs alvo v4.1

**Atual (v3/v4.0):** `TTarFile` em ficheiro unico `TarFile.pas` com enum `TTarFormat` inline. Fluent em `Tar.Fluent.pas` separado. Stream helper em `Tar.GzipStream.pas`.

**Alvo (v4.1 — split 5 ficheiros):**

| Ficheiro alvo | Conteudo |
| --- | --- |
| `TarFile.pas` | `TTarFile` + metodos fluentes inline |
| `TarFile.Interfaces.pas` | `ITarFile`, `ITarFileBuilder` |
| `TarFile.Consts.pas` | Resourcestrings + magic (`ustar\0`, offsets de bloco 512 bytes) |
| `TarFile.Types.pas` | `TTarFormat`, `TTarEntryType`, `TTarHeader` record |
| `TarFile.Exceptions.pas` | `ETarFile`, `ETarCorrupted`, `ETarUnsupportedFormat` |

---

*Referencia: SPEC v3 §6, §17 — P20, P22*
