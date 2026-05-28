---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Passo a Passo — Split RarFile em 5 ficheiros

## Passo 1 — Extrair bloco `type` para `RarFile.Types.pas`

1. Localizar em `RarFile.pas`: `TRarCompressionMethod` (enum), `TRarEntryRec`, e todos os records FFI: `RAROpenArchiveDataEx`, `RARHeaderDataEx`, `UNRARCALLBACK`.
2. Verificar packing: os records FFI devem ter `{$ALIGN 4}` ou `packed record` para correspondencia C.
3. Criar `RarFile.Types.pas`; mover tipos.
4. Compilar standalone.

## Passo 2 — Extrair `resourcestring` para `RarFile.Consts.pas`

1. Criar `RarFile.Consts.pas`.
2. Mover `resourcestring` de `RarFile.pas`.
3. Adicionar magic RAR5: `cRar5Magic: array[0..7] of Byte = ($52, $61, $72, $21, $1A, $07, $01, $00)`.
4. Adicionar codigos de erro UnRAR: `ERAR_SUCCESS`, `ERAR_END_ARCHIVE`, `ERAR_NO_MEMORY`, etc.

## Passo 3 — Extrair hierarquia `E<X>` para `RarFile.Exceptions.pas`

1. Criar `RarFile.Exceptions.pas`.
2. Mover `ERarFile`, `ERarDllNotFound`, `ERarUnsupportedMethod`, `ERarPasswordRequired`.
3. Herdar de `EArchive`.
4. `ERarDllNotFound` deve ter campo com o nome da DLL nao encontrada.

## Passo 4 — Criar `RarFile.Interfaces.pas`

1. Declarar `IRarFile`: `Open`, `Close`, `GetEntryCount`, `FileExists`, `GetEntryStream`, `ReadAsBytes`, `ReadAsString`.
2. Interface minima (formato read-only sem builder elaborado).

## Passo 5 — Verificar e unificar declaracao FFI da DLL

1. Confirmar se `unrar.dll` e carregada via `LoadLibrary` (dinamico) ou `external` (estatico).
2. Se estatico: encapsular em bloco `{$IFDEF WIN64} external 'unrar64.dll' {$ELSE} external 'unrar.dll' {$ENDIF}`.
3. Documentar prerequisito: DLL deve estar no PATH ou no diretorio do EXE.

## Passo 6 — Build gate completo

1. Gerar fixture: `pwsh tools/Make-RarFixture.ps1` (requer WinRAR instalado).
2. Copiar `dll/unrar.dll` e `dll/unrar64.dll` para diretorio de saida do smoke test.
3. Build D24..D37 × W32+W64.
4. FPC smoke — 4 targets green.
5. Smoke `smoke_rar.dpr` — pass.
