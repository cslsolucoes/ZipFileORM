---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Modulo TarGzFile

## O que faz

Implementa `TTarGzFile`, componente TComponent que le e escreve arquivos TAR.GZ (tarball comprimido com gzip). Combina o parser TAR de `TarFile.pas` com o stream gzip de `Tar.GzipStream.pas`, entregando uma API unificada para o formato mais comum de distribuicao de software Unix.

## Ficheiros em `src/`

| Ficheiro | Linhas | Papel |
| --- | --- | --- |
| `TarGzFile.pas` | 384 | Classe `TTarGzFile` — wrapper TAR + gzip |
| `Tar.GzipStream.pas` | — | `TGzipReadStream` / `TGzipWriteStream` (compartilhado com TarFile) |

## Capacidades

| Operacao | Suporte |
| --- | --- |
| Read (extracao) | Completo |
| Write (criacao) | Completo |
| Compressao gzip (RFC 1952) | Sim |
| Metadados Unix via TAR | Sim |
| Streaming progressivo | Parcial |

## Estado atual vs alvo v4.1

**Atual (v3/v4.0):** Classe compacta em `TarGzFile.pas` sem ficheiros auxiliares proprios. Delega ao `Tar.GzipStream.pas` compartilhado.

**Alvo (v4.1 — split 5 ficheiros):**

| Ficheiro alvo | Conteudo |
| --- | --- |
| `TarGzFile.pas` | `TTarGzFile` + metodos fluentes inline |
| `TarGzFile.Interfaces.pas` | `ITarGzFile`, `ITarGzFileBuilder` |
| `TarGzFile.Consts.pas` | Resourcestrings rsTarGz* |
| `TarGzFile.Types.pas` | `TTarGzCompressionLevel` enum + records especificos |
| `TarGzFile.Exceptions.pas` | `ETarGzFile` (herda de `EArchive`) |

---

*Referencia: SPEC v3 §7, §17 — P20*
