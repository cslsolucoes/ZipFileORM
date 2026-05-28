---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# O que Falta — RarFile

## Gaps identificados (SPEC v3 §17)

| ID | Descricao | Prioridade | Esforco estimado |
| --- | --- | --- | --- |
| P20 | Populacao de propriedades read-only (IsEncrypted, IsSolid, ArchiveVersion, NumFiles) | Alta | ~3h |
| P28 | Populacao de metadados de entrada (metodo, tamanho original, CRC32, timestamp) | Alta | ~3h |
| P03 | Disparo de evento `OnEntryFound` | Media | ~2h |
| P04 | Disparo de evento `OnExtract` | Media | ~2h |
| P60 | UnRAR encoder (escrita RAR) — major undertaking, viabilidade a decidir | Deferred | ~100h+ |
| P70 | Documentacao XML inline | Baixa | ~2h |

## Gaps especificos do split v4.1

- Nenhuma interface `IRarFile` publicada.
- Records FFI (`RAROpenArchiveDataEx`, `RARHeaderDataEx`) provavelmente inline no corpo sem tipo nomeado separado.
- Codigos de erro UnRAR (`ERAR_*`) provavelmente como constantes inteiras sem enum.
- Carregamento da DLL: verificar se usa `LoadLibrary` (permite fallback gracioso se DLL ausente) ou `external` (crash na inicializacao se DLL nao encontrada).
- RAR4 vs RAR5: confirmar qual formato e suportado; magic bytes diferentes ($52$61$72$21$1A$07 para RAR4, $01$00 extra para RAR5).

## Pendencias de testes

- Smoke test requer DLL presente + fixture `Make-RarFixture.ps1` (requer WinRAR instalado).
- Nenhum teste de ausencia de DLL — deve lancar `ERarDllNotFound` graciosamente.
- Nenhum teste de arquivo RAR com senha.
- Sem teste de arquivo RAR multi-volume.
- Nenhum teste de RAR4 (formato legado).
