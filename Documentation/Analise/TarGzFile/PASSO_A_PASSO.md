---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Passo a Passo — Split TarGzFile em 5 ficheiros

## Passo 1 — Extrair bloco `type` para `TarGzFile.Types.pas`

1. Localizar em `TarGzFile.pas` todos os tipos nao-classe (enums, records proprios).
2. Criar `TarGzFile.Types.pas`; avaliar reusar tipos de `TarFile.Types.pas` via `uses` em vez de duplicar.
3. Compilar standalone.

## Passo 2 — Extrair `resourcestring` para `TarGzFile.Consts.pas`

1. Criar `TarGzFile.Consts.pas`.
2. Mover `resourcestring` de `TarGzFile.pas`.
3. Constante de nivel de compressao default (se hardcoded, mover para ca).

## Passo 3 — Extrair hierarquia `E<X>` para `TarGzFile.Exceptions.pas`

1. Criar `TarGzFile.Exceptions.pas`.
2. Mover `ETarGzFile` e subclasses; herdam de `EArchive`.
3. Verificar se existem excecoes inline no corpo de `TarGzFile.pas` (raises sem classe propria).

## Passo 4 — Criar `TarGzFile.Interfaces.pas`

1. Declarar `ITarGzFile` com os metodos publicos.
2. Declarar `ITarGzFileBuilder` se houver fluent.
3. Nenhuma dependencia de `TarFile.Interfaces.pas` (modulos independentes, exceto via `Commons`).

## Passo 5 — Integrar fluent inline (se `Tar.Fluent.pas` cobre TTarGzFile)

1. Verificar se `Tar.Fluent.pas` tem metodos para `TTarGzFile` ou somente para `TTarFile`.
2. Se cobre ambos, separar a porcao `TTarGzFile` e fundir em `TarGzFile.pas`.

## Passo 6 — Build gate completo

1. Build D24..D37 × W32+W64.
2. FPC smoke — 4 targets green.
3. Smoke `smoke_targz.dpr` — pass.
