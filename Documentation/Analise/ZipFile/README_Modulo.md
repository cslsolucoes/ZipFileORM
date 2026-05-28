---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Modulo ZipFile

## O que faz

Implementa `TZipFile`, componente TComponent que le e escreve arquivos ZIP (PKWARE AppNote) com suporte a AES-256, LZMA, ZIP64 e UTF-8. E o componente de producao mais completo da biblioteca, cobrindo casos de uso industriais como arquivos multivolume, headers criptografados e streaming progressivo.

## Ficheiros em `src/`

| Ficheiro | Linhas | Papel |
| --- | --- | --- |
| `ZipFile.pas` | 2035 | Classe principal `TZipFile` + logica read/write |
| `ZipFile.ZIP64.pas` | — | Extensoes ZIP64 (offsets e tamanhos >4 GB) |
| `ZipFile.UTF8.pas` | — | Tratamento de nomes de entrada UTF-8 |
| `ZipFile.Encryption.AES.pas` | — | WinZip-AE-2 AES-256 (promovido em v4 para `Commons.Encryption.AES.pas`) |
| `ZipFile.Compression.LZMA.pas` | — | Codec LZMA (promovido em v4 para `Commons.Compression.LZMA.pas`) |
| `ZipFile.Streaming.pas` | — | API de streaming progressivo (OnEntryFound/OnExtract) |
| `ZipFile.Fluent.pas` | — | Builder fluente `TZipFile.Create.WithFileName(...).ThatOpens` |
| `ZipFile.Events.pas` | — | 15 tipos de evento compartilhados (promovido em v4 para `ZipFileORM.Events.pas`) |
| `ZipFile.Progress.pas` | — | `TZipProgressEvent` (promovido em v4 para `Commons.Progress.pas`) |

## Capacidades

| Operacao | Suporte |
| --- | --- |
| Read (extracao) | Completo |
| Write (criacao/append) | Completo |
| Streaming progressivo | Sim |
| AES-256 | Sim |
| LZMA | Sim |
| ZIP64 (>4 GB) | Sim |
| UTF-8 filenames | Sim |
| Multivolume | Leitura (escrita pendente P41) |

## Estado atual vs alvo v4.1

**Atual (v3/v4.0):** Classe monolitica em `ZipFile.pas` com extensoes em ficheiros `ZipFile.*.pas` separados. Fluent em `ZipFile.Fluent.pas` independente.

**Alvo (v4.1 — split 5 ficheiros):**

| Ficheiro alvo | Conteudo |
| --- | --- |
| `ZipFile.pas` | `TZipFile` + metodos fluentes inline |
| `ZipFile.Interfaces.pas` | `IZipFile`, `IZipFileBuilder` |
| `ZipFile.Consts.pas` | Resourcestrings + magic numbers ZIP |
| `ZipFile.Types.pas` | Enums (`TZipCompressionMethod`, etc.) + records |
| `ZipFile.Exceptions.pas` | `EZipFile`, `EZipCorrupted`, `EZipPasswordRequired` |

---

*Referencia: SPEC v3 §3, §17 — P20, P21, P41*
