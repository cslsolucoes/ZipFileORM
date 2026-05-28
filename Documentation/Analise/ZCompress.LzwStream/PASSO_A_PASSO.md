---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Passo a Passo — Split ZCompress.LzwStream em 5 ficheiros

## Passo 1 — Extrair bloco `type` para `ZCompress.Types.pas`

1. Localizar em `ZCompress.LzwStream.pas`: `TLzwMaxBits` (enum ou subrange 9..16), `TLzwFlag` (set de flags do byte de flags do header Unix compress: block mode, etc.).
2. Criar `ZCompress.Types.pas`; mover tipos.
3. Compilar standalone.

## Passo 2 — Extrair `resourcestring` para `ZCompress.Consts.pas`

1. Criar `ZCompress.Consts.pas`.
2. Mover `resourcestring` de `ZCompress.LzwStream.pas`.
3. Adicionar magic Unix compress: `cZCompressMagic: array[0..1] of Byte = ($1F, $9D)`.
4. Adicionar flag byte: `cLzwFlagBits = $1F` (bits max), `cLzwFlagBlock = $80` (block reset mode).
5. Adicionar tamanho padrao do dicionario: `cLzwDefaultBits = 16`.

## Passo 3 — Extrair hierarquia `E<X>` para `ZCompress.Exceptions.pas`

1. Criar `ZCompress.Exceptions.pas`.
2. Mover/criar `EZCompressStream`, `ELzwCorrupted`.
3. Herdar de `EArchive`.

## Passo 4 — Criar `ZCompress.Interfaces.pas`

1. Declarar `ILzwCompressStream`: metodos de escrita (compress) e leitura (decompress).
2. Declarar `IZCompressBuilder`: `WithMaxBits`, `WithBlockMode`, `CompressStream`, `DecompressStream`.

## Passo 5 — Dissolver `ZCompress.Fluent.pas` em `ZCompress.LzwStream.pas`

1. Inventariar metodos em `ZCompress.Fluent.pas` (142 L).
2. Mover implementacoes para `ZCompress.LzwStream.pas`.
3. Remover `ZCompress.Fluent.pas` dos packages (Grep: `ZCompress.Fluent`).

## Passo 6 — Build gate completo

1. Build D24..D37 × W32+W64.
2. FPC smoke — 4 targets green.
3. Smoke ZCompress — pass.
