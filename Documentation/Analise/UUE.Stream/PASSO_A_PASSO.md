---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Passo a Passo — Split UUE.Stream em 5 ficheiros

## Passo 1 — Extrair bloco `type` para `UUE.Types.pas`

1. Localizar em `UUE.Stream.pas`: `TUUEPermission` (Word representando o modo octal Unix do cabecalho `begin`), `TUUELineRec` (se existir).
2. O tipo de permissao pode ser apenas um `Word` sem alias — criar alias `TUUEPermission = Word` explicitamente.
3. Criar `UUE.Types.pas`; mover tipos.
4. Compilar standalone.

## Passo 2 — Extrair `resourcestring` para `UUE.Consts.pas`

1. Criar `UUE.Consts.pas`.
2. Mover `resourcestring` de `UUE.Stream.pas`.
3. Adicionar: `cUUEBegin = 'begin '`, `cUUEEnd = 'end'`, `cUUECharset = ' !"#$%&''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_'` (chars 32..95).
4. Adicionar: `cUUEMaxLineBytes = 45` (bytes decodificados por linha), `cUUEMaxLineChars = 60` (chars codificados por linha).

## Passo 3 — Extrair hierarquia `E<X>` para `UUE.Exceptions.pas`

1. Criar `UUE.Exceptions.pas`.
2. Mover `EUUEStream`, `EUUEInvalidHeader` (campo: `InvalidLine: string`), `EUUECorrupted`.
3. Herdar de `EArchive`.

## Passo 4 — Criar `UUE.Interfaces.pas`

1. Declarar `IUUEEncodeStream`: metodos de escrita e finalizacao com cabecalho/rodape.
2. Declarar `IUUEDecodeStream`: metodos de leitura com verificacao de integridade.
3. Declarar `IUUEBuilder`: `Encode`, `Decode`, `WithPermission`, `WithFileName`.

## Passo 5 — Dissolver `UUE.Fluent.pas` em `UUE.Stream.pas`

1. Inventariar metodos em `UUE.Fluent.pas` (160 L).
2. Mover implementacoes para `UUE.Stream.pas`.
3. Remover `UUE.Fluent.pas` dos packages (Grep: `UUE.Fluent`).

## Passo 6 — Build gate completo

1. Build D24..D37 × W32+W64.
2. FPC smoke — 4 targets green.
3. Smoke UUE — pass.
