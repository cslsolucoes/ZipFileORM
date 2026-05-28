---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Modulo GzipFile

## O que faz

Implementa `TGzipFile`, componente TComponent que le e escreve arquivos GZ de arquivo unico (RFC 1952). Diferente do `TTarGzFile`, opera diretamente sobre um unico stream comprimido sem estrutura de diretorio TAR. Util para compressao simples de logs, backups e transferencias de arquivo unico.

## Ficheiros em `src/`

| Ficheiro | Linhas | Papel |
| --- | --- | --- |
| `GzipFile.pas` | 386 | Classe `TGzipFile` — single-file gzip read/write |

## Capacidades

| Operacao | Suporte |
| --- | --- |
| Read (descompressao) | Completo |
| Write (compressao) | Completo |
| RFC 1952 (formato .gz) | Sim |
| Metadados gzip (OS, mtime, nome original) | Parcial |
| Arquivo unico (single-file) | Sim |
| Multi-arquivo (TAR) | Nao (usar TTarGzFile) |

## Estado atual vs alvo v4.1

**Atual (v3/v4.0):** Classe compacta em `GzipFile.pas` sem sub-modulos. Usa `Tar.GzipStream.pas` ou `System.ZLib`/`ZStream` diretamente.

**Alvo (v4.1 — split 5 ficheiros):**

| Ficheiro alvo | Conteudo |
| --- | --- |
| `GzipFile.pas` | `TGzipFile` + metodos fluentes inline |
| `GzipFile.Interfaces.pas` | `IGzipFile`, `IGzipFileBuilder` |
| `GzipFile.Consts.pas` | Resourcestrings rsGzip* + magic bytes (`\x1f\x8b`) |
| `GzipFile.Types.pas` | `TGzipOsType` enum + `TGzipHeader` record |
| `GzipFile.Exceptions.pas` | `EGzipFile`, `EGzipCorrupted` (herdam de `EArchive`) |

---

*Referencia: SPEC v3 §8, §17 — P20*
