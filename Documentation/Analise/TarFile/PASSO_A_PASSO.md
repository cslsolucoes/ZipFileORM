---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Passo a Passo — Split TarFile em 5 ficheiros

## Passo 1 — Extrair bloco `type` para `TarFile.Types.pas`

1. Localizar em `TarFile.pas`: `TTarFormat` (enum), `TTarEntryType`, `TTarHeader` (record 512 bytes), `TTarEntryRec`.
2. Criar `TarFile.Types.pas`; mover esses tipos para a secao `interface`.
3. Adicionar `TarFile.Types` nos `uses` de `TarFile.pas`.
4. Compilar standalone (sem `Classes`, `TComponent`).

## Passo 2 — Extrair `resourcestring` para `TarFile.Consts.pas`

1. Criar `TarFile.Consts.pas`.
2. Mover todos os `resourcestring` de `TarFile.pas`.
3. Mover constantes magicas: string `ustar`, tamanho de bloco (512), offsets dos campos de cabecalho.
4. Adicionar `TarFile.Consts` nos `uses` de `TarFile.pas`.

## Passo 3 — Extrair hierarquia `E<X>` para `TarFile.Exceptions.pas`

1. Criar `TarFile.Exceptions.pas` com `uses SysUtils, Commons.Exceptions`.
2. Mover `ETarFile`, `ETarCorrupted`, `ETarUnsupportedFormat`.
3. Garantir heranca de `EArchive`.
4. Atualizar `uses` em `TarFile.pas`.

## Passo 4 — Criar `TarFile.Interfaces.pas`

1. Declarar `ITarFile` com os metodos publicos de `TTarFile` (Open, Close, GetEntryCount, ReadAsBytes, AppendStream, etc.).
2. Declarar `ITarFileBuilder` (metodos `With*`, `ThatOpens`).
3. Usar apenas `TarFile.Types` e `TarFile.Exceptions`.

## Passo 5 — Dissolver `Tar.Fluent.pas` em `TarFile.pas`

1. Inventariar todos os metodos em `Tar.Fluent.pas`.
2. Mover implementacoes para `TarFile.pas` na classe `TTarFile`.
3. Remover `Tar.Fluent.pas` dos packages e do disco (apos Grep confirmar zero referencias externas).

## Passo 6 — Build gate completo

1. Build packages D24..D37 × W32+W64.
2. `pwsh tools/Build-FPC-Smoke.ps1` — 4 targets green.
3. Smoke `smoke_tar.dpr` — pass.
4. DUnitX suite — 21/21 pass.
