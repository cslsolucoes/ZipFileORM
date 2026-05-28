---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# O que Falta — CabFile

## Gaps identificados (SPEC v3 §17)

| ID | Descricao | Prioridade | Esforco estimado |
| --- | --- | --- | --- |
| P20 | Populacao de propriedades read-only (SetID, CabinetIndex, NumFolders, NumFiles) | Alta | ~5h |
| P23 | Populacao de propriedades de entrada (data/hora, atributos Win32) | Alta | ~4h |
| P03 | Disparo de evento `OnEntryFound` | Media | ~3h |
| P04 | Disparo de evento `OnExtract` com progresso | Media | ~3h |
| P70 | Documentacao XML inline | Media | ~6h |

## Gaps especificos do split v4.1

- `Cab.Fluent.pas` ainda existe separado.
- Nenhuma interface `ICabFile` publicada.
- Records FFI (C-compat) misturados com logica de negocio em `CabFile.pas` sem separacao clara.
- Codigos de erro FDI/FCI (`FDIERROR_*`, `FCIERR_*`) sao inteiros magicos sem tipo enum Pascal.
- Hierarquia de excecoes: verificar se `ECabFile` herda de `EArchive` ou `Exception`.

## Pendencias de testes

- Nenhum teste de cabinet multi-volume (span entre dois .cab).
- Nenhum teste de compressao LZX (apenas MSZIP coberto).
- Nenhum teste com `SetID` e `CabinetIndex` diferentes do default (0/0).
- Sem teste de cabinet com mais de 65535 arquivos (limite CFFILE count).
