---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Passo a Passo — Split ArjFile em 5 ficheiros

## Passo 1 — Extrair bloco `type` para `ArjFile.Types.pas`

1. Localizar em `ArjFile.pas`: `TArjCompressionMethod` (enum com Store e metodos 1-9), `TArjFlag` (set de flags de arquivo), `TArjEntryRec`, `TArjLocalHeader` (record com campos do cabecalho ARJ: basic_header_size, version, minimum_version, host_os, etc.).
2. Criar `ArjFile.Types.pas`; mover tipos.
3. Compilar standalone.

## Passo 2 — Extrair `resourcestring` para `ArjFile.Consts.pas`

1. Criar `ArjFile.Consts.pas`.
2. Mover `resourcestring` de `ArjFile.pas`.
3. Adicionar: `cArjMagic: array[0..1] of Byte = ($60, $EA)`.
4. Adicionar offsets do cabecalho ARJ local: basic_header_size (0), version (2), minimum_version (3), host_os (4), etc.

## Passo 3 — Extrair hierarquia `E<X>` para `ArjFile.Exceptions.pas`

1. Criar `ArjFile.Exceptions.pas`.
2. Mover `EArjFile`, `EArjUnsupportedMethod` (com campo `Method: TArjCompressionMethod`), `EArjCorrupted`.
3. Herdar de `EArchive`.

## Passo 4 — Criar `ArjFile.Interfaces.pas`

1. Declarar `IArjFile` com metodos read-only: `Open`, `Close`, `GetEntryCount`, `FileExists`, `GetEntryStream`, `ReadAsBytes`, `ReadAsString`.
2. Nao ha builder elaborado para formato read-only — interface minima suficiente.

## Passo 5 — Integrar fluent inline (minimo)

1. `TArjFile` nao tem `Arj.Fluent.pas` — verificar se ha metodos fluentes inline em `ArjFile.pas`.
2. Se nao ha fluent, adicionar apenas `WithFileName`: `IArjFile`.

## Passo 6 — Build gate completo

1. Gerar fixture: `pwsh tools/Make-ArjFixture.ps1`.
2. Build D24..D37 × W32+W64.
3. FPC smoke — 4 targets green.
4. Smoke `smoke_arj.dpr` — pass.
