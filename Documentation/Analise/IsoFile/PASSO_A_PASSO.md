---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Passo a Passo — Split IsoFile em 5 ficheiros

## Passo 1 — Extrair bloco `type` para `IsoFile.Types.pas`

1. Localizar em `IsoFile.pas`: `TIsoVolumeDescriptorType` (enum: Primary=1, Supplementary=2, etc.), `TIsoPVD` (record de 2048 bytes do PVD — campos both-endian), `TIsoDirectoryRecord`, `TIsoPathTable`.
2. ATENCAO: records ISO 9660 usam campos both-endian (little + big endian no mesmo record). Preservar packing exato.
3. Criar `IsoFile.Types.pas`; usar `{$ALIGN 1}` ou `packed record` conforme necessario.
4. Compilar standalone.

## Passo 2 — Extrair `resourcestring` para `IsoFile.Consts.pas`

1. Criar `IsoFile.Consts.pas`.
2. Mover `resourcestring` de `IsoFile.pas`.
3. Adicionar: `cIsoPVDIdentifier = 'CD001'` (5 bytes no offset 1 do PVD).
4. Adicionar: `cIsoPVDSector = 16` (setor onde comeca o PVD), `cIsoSectorSize = 2048`.

## Passo 3 — Extrair hierarquia `E<X>` para `IsoFile.Exceptions.pas`

1. Criar `IsoFile.Exceptions.pas`.
2. Mover `EIsoFile`, `EIsoCorrupted`, `EIsoUnsupportedVolume`.
3. Herdar de `EArchive`.

## Passo 4 — Criar `IsoFile.Interfaces.pas`

1. Declarar `IIsoFile`: `Open`, `Close`, `GetEntryCount`, `FileExists`, `GetEntryStream`, `ReadAsBytes`, metodos de navegacao de diretorio.
2. Expor propriedades do Volume Descriptor via getter methods ou propriedades readonly na interface.

## Passo 5 — Integrar fluent inline (minimo)

1. Verificar se ha fluent em `IsoFile.pas` (provavelmente `WithFileName` apenas).
2. Garantir assinatura `WithFileName(const AFileName: string): IIsoFile`.

## Passo 6 — Build gate completo

1. Gerar fixture: `pwsh tools/Make-IsoFixture.ps1`.
2. Build D24..D37 × W32+W64.
3. FPC smoke — 4 targets green.
4. Smoke `smoke_iso.dpr` — pass.
