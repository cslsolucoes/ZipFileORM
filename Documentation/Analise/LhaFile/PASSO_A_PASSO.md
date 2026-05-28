---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Passo a Passo — Split LhaFile em 5 ficheiros

## Passo 1 — Extrair bloco `type` para `LhaFile.Types.pas`

1. Localizar em `LhaFile.pas`: `TLhaMethod` (enum: lh0=Store, lh4..lh7), `TLhaHeaderLevel` (0, 1, 2), `TLhaLocalHeader` (record — tamanho variavel conforme nivel).
2. Atentar que Level-0 header e fixo, Level-1 tem extensoes, Level-2 usa CRC16 no header — modelar como variantes ou union se necessario.
3. Criar `LhaFile.Types.pas`; mover tipos.
4. Compilar standalone.

## Passo 2 — Extrair `resourcestring` para `LhaFile.Consts.pas`

1. Criar `LhaFile.Consts.pas`.
2. Mover `resourcestring` de `LhaFile.pas`.
3. Adicionar constantes de identificador de metodo: `-lh0-`, `-lh4-`, `-lh5-`, `-lh6-`, `-lh7-` (strings de 5 chars cada).
4. Adicionar offsets de campo do Level-0 header.

## Passo 3 — Extrair hierarquia `E<X>` para `LhaFile.Exceptions.pas`

1. Criar `LhaFile.Exceptions.pas`.
2. Mover `ELhaFile`, `ELhaUnsupportedMethod` (campo `Method: string` — o identificador de 5 chars), `ELhaCorrupted`.
3. Herdar de `EArchive`.

## Passo 4 — Criar `LhaFile.Interfaces.pas`

1. Declarar `ILhaFile`: `Open`, `Close`, `GetEntryCount`, `FileExists`, `GetEntryStream`, `ReadAsBytes`, `ReadAsString`.
2. Interface minima (formato read-only sem builder elaborado).

## Passo 5 — Avaliar isolamento do codec Huffman (opcional)

1. Se o codec Huffman adaptativo (-lh4..-lh7-) for maior que ~300 linhas, considerar `LhaFile.Codec.pas` interno (nao e um dos 5 ficheiros obrigatorios mas melhora legibilidade).
2. Esta decisao e opcional e nao bloqueia o split basico.

## Passo 6 — Build gate completo

1. Gerar fixture: `pwsh tools/Make-LhaFixture.ps1`.
2. Build D24..D37 × W32+W64.
3. FPC smoke — 4 targets green.
4. Smoke `smoke_lha.dpr` — pass.
