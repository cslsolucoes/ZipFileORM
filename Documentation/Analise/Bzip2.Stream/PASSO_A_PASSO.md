---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Passo a Passo — Split Bzip2.Stream em 5 ficheiros

## Passo 1 — Extrair bloco `type` para `Bzip2.Types.pas`

1. Localizar em `Bzip2.Stream.pas`: `TBzip2CompressionLevel` (enum ou subrange 1..9), record `bz_stream` (FFI C — struct da API bzip2).
2. Verificar packing do `bz_stream` (campos de ponteiro, inteiros — packing padrao C).
3. Criar `Bzip2.Types.pas`; mover tipos.
4. Compilar standalone.

## Passo 2 — Extrair `resourcestring` para `Bzip2.Consts.pas`

1. Criar `Bzip2.Consts.pas`.
2. Mover `resourcestring` de `Bzip2.Stream.pas`.
3. Adicionar magic bzip2: `cBzip2Magic: array[0..2] of Byte = (Ord('B'), Ord('Z'), Ord('h'))`.
4. Adicionar codigos de retorno SDK: `BZ_OK=0`, `BZ_RUN_OK=1`, `BZ_FINISH_OK=2`, `BZ_STREAM_END=4`, `BZ_DATA_ERROR=-4`, `BZ_MEM_ERROR=-3`.

## Passo 3 — Extrair hierarquia `E<X>` para `Bzip2.Exceptions.pas`

1. Criar `Bzip2.Exceptions.pas`.
2. Mover/criar `EBzip2Stream`, `EBzip2DataError` (campo `BZResult: Integer`), `EBzip2MemError`, `EBzip2ConfigError`.
3. Herdar de `EArchive`.

## Passo 4 — Criar `Bzip2.Interfaces.pas`

1. Declarar `IBzip2CompressStream`: `Write`, `Flush`, `Finish` (fluxo de escrita comprimida).
2. Declarar `IBzip2DecompressStream`: `Read` (fluxo de leitura descomprimida).
3. Declarar `IBzip2Builder`: `WithLevel`, `CompressStream`, `DecompressStream`.

## Passo 5 — Dissolver `Bzip2.Fluent.pas` em `Bzip2.Stream.pas`

1. Inventariar metodos em `Bzip2.Fluent.pas` (159 L).
2. Mover implementacoes para `Bzip2.Stream.pas`.
3. Remover `Bzip2.Fluent.pas` dos packages (Grep: `Bzip2.Fluent`).

## Passo 6 — Build gate completo

1. Recompilar OBJs se necessario: `pwsh tools/Build-Bzip2Objs.ps1`.
2. Build D24..D37 × W32+W64.
3. FPC smoke — 4 targets green.
4. Smoke bzip2 — pass.
