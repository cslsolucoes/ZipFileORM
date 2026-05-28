---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Passo a Passo — Split GzipFile em 5 ficheiros

## Passo 1 — Extrair bloco `type` para `GzipFile.Types.pas`

1. Localizar em `GzipFile.pas`: `TGzipOsType` (enum OS identifier byte), `TGzipFlag` (set de flags do header), `TGzipHeader` (record dos 10 bytes iniciais do formato .gz).
2. Criar `GzipFile.Types.pas`; mover tipos.
3. Compilar standalone.

## Passo 2 — Extrair `resourcestring` para `GzipFile.Consts.pas`

1. Criar `GzipFile.Consts.pas`.
2. Mover `resourcestring` de `GzipFile.pas`.
3. Adicionar constante `cGzipMagic: array[0..1] of Byte = ($1F, $8B)`.
4. Adicionar offsets dos campos do header gzip (CM, FLG, MTIME, XFL, OS).

## Passo 3 — Extrair hierarquia `E<X>` para `GzipFile.Exceptions.pas`

1. Criar `GzipFile.Exceptions.pas`.
2. Mover `EGzipFile`, `EGzipCorrupted`.
3. Garantir heranca de `EArchive`.

## Passo 4 — Criar `GzipFile.Interfaces.pas`

1. Declarar `IGzipFile`: `Open`, `Close`, `Decompress`, `CompressFile`, `ReadAsBytes`, `ReadAsString`.
2. Declarar `IGzipFileBuilder`: `WithFileName`, `WithCompressionLevel`, `ThatOpens`.

## Passo 5 — Integrar fluent inline (se existir `Gzip.Fluent.pas`)

1. Verificar se ha ficheiro `Gzip.Fluent.pas` ou se o fluent ja e inline.
2. Se existir, dissolver em `GzipFile.pas`.

## Passo 6 — Build gate completo

1. Build D24..D37 × W32+W64.
2. FPC smoke — 4 targets green.
3. Smoke `smoke_gzip.dpr` — pass.
