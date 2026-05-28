---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Passo a Passo — Split CabFile em 5 ficheiros

## Passo 1 — Extrair bloco `type` para `CabFile.Types.pas`

1. Localizar em `CabFile.pas`: `TCabCompressionType`, `TCabEntryRec`, e todos os records FFI compatíveis com C (`CABINET`, `CFHEADER`, `CFFOLDER`, `CFFILE`, `ERF`, callbacks FDI/FCI).
2. Verificar diretivas de packing (`{$ALIGN 1}`, `packed record`) — copiar junto com os records.
3. Criar `CabFile.Types.pas` com os tipos.
4. Compilar standalone.

## Passo 2 — Extrair `resourcestring` para `CabFile.Consts.pas`

1. Criar `CabFile.Consts.pas`.
2. Mover `resourcestring` de `CabFile.pas`.
3. Adicionar constante `cCabMagic = 'MSCF'` (ou equivalente em bytes).
4. Adicionar offsets: cabinet header size (36 bytes), folder entry size, file entry size.

## Passo 3 — Extrair hierarquia `E<X>` para `CabFile.Exceptions.pas`

1. Criar `CabFile.Exceptions.pas`.
2. Mover `ECabFile`, `ECabFDIError` (com campo `FdiError: Integer`), `ECabFCIError`.
3. Herdar de `EArchive`.
4. Verificar se ha raises inline que usam codigo de erro FDI/FCI — capturar como campo da excecao.

## Passo 4 — Criar `CabFile.Interfaces.pas`

1. Declarar `ICabFile`: `Open`, `Close`, `GetEntryCount`, `ReadAsBytes`, `CreateFromFiles`, `AppendStream`.
2. Declarar `ICabFileBuilder`: `WithFileName`, `WithCompressionType`, `WithSetID`, `WithCabinetIndex`, `ThatOpens`.

## Passo 5 — Dissolver `Cab.Fluent.pas` em `CabFile.pas`

1. Inventariar metodos em `Cab.Fluent.pas`.
2. Mover implementacoes para `TCabFile` em `CabFile.pas`.
3. Remover `Cab.Fluent.pas` dos packages apos confirmar zero referencias (Grep: `Cab.Fluent`).

## Passo 6 — Build gate completo

1. Build D24..D37 × W32+W64.
2. FPC smoke — 4 targets green.
3. Smoke `smoke_cab.dpr` — pass.
4. DUnitX — 21/21 pass.
