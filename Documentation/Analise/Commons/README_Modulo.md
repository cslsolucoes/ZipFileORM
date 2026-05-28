---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Modulo Commons

## O que faz

Agrupa todas as unidades cross-format compartilhadas por dois ou mais modulos da biblioteca. Inclui hierarquia de excecoes base, tipos de busca, constantes globais, codecs de compressao (ZLib, LZMA, None), criptografia AES e utilities de progresso. Nao contem componentes TComponent — e pura infraestrutura.

## Ficheiros em `src/`

| Ficheiro | Linhas | Papel |
| --- | --- | --- |
| `Commons.Consts.pas` | — | Resourcestrings globais (`rsArchive*`) |
| `Commons.Types.pas` | — | `TArchiveSearchRec`, `TArchiveProgressInfo`, `TArchiveCapability` |
| `Commons.Exceptions.pas` | — | `EArchive` + 8 subclasses (hierarquia base) |
| `Commons.Progress.pas` | — | `TZipProgressEvent` (promovido de `ZipFile.Progress.pas`) |
| `Commons.Compression.Consts.pas` | — | `cgsCompressNone`, `cgsCompressZLib` |
| `Commons.Compression.Base.pas` | — | `TtiCompressAbs` base + Factory pattern |
| `Commons.Compression.None.pas` | — | `TtiCompressNone` null object |
| `Commons.Compression.ZLib.pas` | — | `TtiCompressZLib` |
| `Commons.Compression.ZLib.Bridge.pas` | — | FPC-only bridge para zlib |
| `Commons.Compression.LZMA.pas` | — | `TLZMA` codec (promovido de `ZipFile.Compression.LZMA.pas`) |
| `Commons.Encryption.AES.pas` | — | `TAesContext` + WinZip-AE-2 (promovido de `ZipFile.Encryption.AES.pas`) |
| `Commons.FPC.inc` | — | `{$IFDEF FPC} {$mode delphi}{$H+}` block compartilhado |
| `Commons.Compression.Defines.inc` | — | Diretivas de versionamento Delphi/FPC |

## Capacidades

| Servico | Descricao |
| --- | --- |
| Hierarquia de excecoes | `EArchive` base + 8 subclasses polimorficas |
| Codec ZLib | Via `TtiCompressZLib` (abstrato + bridge FPC) |
| Codec LZMA | Via `TLZMA` (SDK vendorizado) |
| Codec None | Via `TtiCompressNone` (null object) |
| AES-256 | Via `TAesContext` (WinZip-AE-2) |
| Tipos compartilhados | `TArchiveSearchRec`, `TArchiveProgressInfo` |

## Estado atual vs alvo v4.1

**Atual (v4.0):** Commons ja foi split em v4.0 como resultado da promocao de unidades originalmente em `ZipFile.*`. Esta em bom estado. Sem Fluent separado.

**Alvo (v4.1):** Commons ja esta estruturado corretamente. As acoes remanescentes sao:

| Acao | Descricao |
| --- | --- |
| Verificar references cruzadas | Confirmar que nenhum modulo de formato importa outro modulo de formato via Commons |
| Adicionar `Commons.Interfaces.pas` | `ICompressor`, `IEncryptor` — abstrair para DI nos testes |
| Documentar hierarquia `EArchive` | Tabela de 8 subclasses com quando usar cada uma |

---

*Referencia: SPEC v3 §2, §17*
