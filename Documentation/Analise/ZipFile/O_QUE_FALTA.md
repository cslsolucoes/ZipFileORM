---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# O que Falta — ZipFile

## Gaps identificados (SPEC v3 §17)

| ID | Descricao | Prioridade | Esforco estimado |
| --- | --- | --- | --- |
| P20 | Populacao de propriedades read-only do header (ArchiveSize, IsEncrypted, etc.) | Alta | ~8h |
| P21 | Populacao de propriedades de entrada (EntryCount real, nomes, tamanhos) | Alta | ~6h |
| P03 | Disparo de evento `OnEntryFound` durante Open | Media | ~4h |
| P04 | Disparo de evento `OnExtract` durante extracao | Media | ~4h |
| P41 | Escrita multivolume (split ZIP) | Baixa | ~20h |
| P70 | Documentacao XML inline nos metodos publicos | Media | ~8h |
| P73 | Exemplos compilaveis no README por componente | Media | ~4h |

## Gaps especificos do split v4.1

- `ZipFile.Fluent.pas` ainda existe como ficheiro separado — deve ser dissolvido.
- `ZipFile.Events.pas` e `ZipFile.Progress.pas` podem ter referencias cruzadas que nao foram limpas apos promocao para `Commons.*` e `ZipFileORM.Events.pas`.
- Nenhum `IZipFile` definido — consumidores dependem de `TZipFile` concreto (violacao do principio DI).
- Constantes magicas (numeros de versao, flags de feature) espalhadas no corpo de `ZipFile.pas` sem agrupamento em `ZipFile.Consts.pas`.
- Hierarquia de excecoes: `EZipFile` provavelmente herda de `Exception` diretamente, nao de `EArchive` — rompe polimorfismo de tratamento de erro cross-format.

## Pendencias de testes

- Nenhum teste cobre escrita ZIP com senha AES-256 + metodo LZMA simultaneamente.
- Nenhum teste de round-trip ZIP64 com arquivo >4 GB.
- Cobertura de eventos (P03/P04) zero — sem mock de callback.
