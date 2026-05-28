---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Passo a Passo — Split SevenZFile em 5 ficheiros

## Passo 1 — Extrair bloco `type` para `SevenZFile.Types.pas`

1. Localizar em `SevenZFile.pas`: `TSevenZMethod`, `TSevenZFilter`, `TSevenZMatchFinder`, `TSevenZPreFilter`, records de header 7z (SignatureHeader, PackInfo, CodersInfo, etc.).
2. Atentar para records FFI — verificar `{$ALIGN}` e packed antes de mover.
3. Criar `SevenZFile.Types.pas`; mover todos os tipos.
4. Compilar standalone.

## Passo 2 — Extrair `resourcestring` para `SevenZFile.Consts.pas`

1. Criar `SevenZFile.Consts.pas`.
2. Mover `resourcestring` de `SevenZFile.pas`.
3. Adicionar: `cSevenZMagic: array[0..5] of Byte = ($37, $7A, $BC, $AF, $27, $1C)`.
4. Adicionar versao de header 7z: `cSevenZMajorVersion = 0; cSevenZMinorVersion = 4`.

## Passo 3 — Extrair hierarquia `E<X>` para `SevenZFile.Exceptions.pas`

1. Criar `SevenZFile.Exceptions.pas`.
2. Mover `ESevenZFile`, `ESevenZLZMAError` (com `LZMAResult: Integer`), `ESevenZHeaderCorrupted`.
3. Herdar de `EArchive`.
4. Verificar codigos de retorno do LZMA SDK (SZ_OK=0, SZ_ERROR_*) — documentar na excecao.

## Passo 4 — Criar `SevenZFile.Interfaces.pas`

1. Declarar `ISevenZFile`: `Open`, `Close`, `GetEntryCount`, `ReadAsBytes`, `CreateFromFiles`, `AppendStream`.
2. Declarar `ISevenZFileBuilder`: `WithFileName`, `WithMethod`, `WithSolid`, `WithMultiThreaded`, `WithFastBytes`, `WithMatchFinder`, `WithDictionarySize`, `ThatOpens`.

## Passo 5 — Dissolver `SevenZ.Fluent.pas` em `SevenZFile.pas`

1. Inventariar metodos em `SevenZ.Fluent.pas` (especialmente tunagem LZMA: `WithFastBytes`, `WithDeltaDistance`, `WithPreFilter`).
2. Mover implementacoes para `TSevenZFile` em `SevenZFile.pas`.
3. Remover `SevenZ.Fluent.pas` dos packages (Grep: `SevenZ.Fluent`).

## Passo 6 — Build gate completo

1. Build D24..D37 × W32+W64 (requer OBJs de `Library/LZMA/`).
2. FPC smoke — 4 targets green.
3. Smoke `smoke_sevenz.dpr` — pass.
4. DUnitX — 21/21 pass.
