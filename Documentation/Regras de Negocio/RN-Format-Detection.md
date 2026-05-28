---
internal_file_version: 1.0.0
generated_by: manual
date: 2026-05-28
---

# RN-Format-Detection — Auto-detect de Formato por Magic Bytes

## Contexto

Consumidor passa um caminho para `TArchive.OpenFile()` ou `TArchive.DetectFormat()` sem saber a priori se é ZIP/TAR/Gzip/CAB/7Z/RAR/ARJ/ISO/LHA/BZIP2/Z. O sistema deve identificar o formato lendo os primeiros bytes do arquivo.

## Regra

A detecção é feita por **magic bytes** lidos dos primeiros 512 bytes do stream/arquivo. A ordem de verificação importa (formatos com magic mais específicos primeiro):

| Formato | Magic | Offset |
|---|---|---|
| ZIP | `PK\x03\x04` ou `PK\x05\x06` ou `PK\x07\x08` | 0 |
| 7Z | `7z\xBC\xAF\x27\x1C` | 0 |
| RAR | `Rar!\x1A\x07\x00` (RAR4) ou `Rar!\x1A\x07\x01\x00` (RAR5) | 0 |
| CAB | `MSCF` | 0 |
| BZIP2 | `BZh` | 0 |
| Z compress | `\x1F\x9D` | 0 |
| Gzip | `\x1F\x8B` | 0 |
| TAR | `ustar` | 257 |

## Implementação

Arquivo canônico: `src/Archive.Open.pas`
Função: `function DetectArchiveFormat(AStream: TStream): TArchiveFormat` e overload por path.
Re-exportada via `ZipfileORM.pas`: `TArchive.DetectFormat()`.

## Casos de borda

- **Buffer < 4 bytes** → retorna `afUnknown`
- **TAR offset 257** → exige `N >= 264` (header completo)
- **.tar.gz** → detectado como `afGzip` primeiro (precisa descomprimir para confirmar tar interno)
- **Stream.Position** preservado: salvo antes da leitura, restaurado no `finally`
- **Arquivo inexistente** (overload por path) → retorna `afUnknown`

## Referências

- Código: `src/Archive.Open.pas:73-125`
- Re-export: `src/ZipfileORM.pas` (TArchive class methods)
- SPEC histórico: `Documentation/spec/zipfile-v3-multi-format-expansion.md` §ADR-002
