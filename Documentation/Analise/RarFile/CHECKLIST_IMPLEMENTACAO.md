---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Checklist de Implementacao — RarFile (split v4.1)

## Ficheiros alvo do split

- [ ] `RarFile.pas` — `TRarFile` classe + metodo fluente de abertura inline
- [ ] `RarFile.Interfaces.pas` — `IRarFile` (read-only: Open, Close, GetEntryCount, ReadAsBytes, FileExists)
- [ ] `RarFile.Consts.pas` — `resourcestring` rsRar* + magic RAR5 (`$52 $61 $72 $21 $1A $07 $01 $00`) + codigos de erro UnRAR
- [ ] `RarFile.Types.pas` — `TRarCompressionMethod` enum, `TRarEntryRec`, records FFI (RAROpenArchiveDataEx, RARHeaderDataEx, etc.)
- [ ] `RarFile.Exceptions.pas` — `ERarFile`, `ERarDllNotFound`, `ERarUnsupportedMethod`, `ERarPasswordRequired` (herdam de `EArchive`)

## Atencao especial — DLL e FFI

- [ ] Verificar se FFI usa `loadlibrary`/`GetProcAddress` dinamico ou declaracoes `external 'unrar.dll'`
- [ ] Se `external` estatico: adicionar condicional `{$IFDEF WIN64} 'unrar64.dll' {$ELSE} 'unrar.dll' {$ENDIF}`
- [ ] Records FFI (RAROpenArchiveDataEx, RARHeaderDataEx) devem manter packing C-compat ao mover para `.Types.pas`

## Build gate

- [ ] Compilar `RarFile.Types.pas` standalone (com packing correto)
- [ ] Compilar `RarFile.Consts.pas` standalone
- [ ] Compilar `RarFile.Exceptions.pas`
- [ ] Compilar `RarFile.Interfaces.pas`
- [ ] Compilar `RarFile.pas` completo
- [ ] Build packages D24..D37 + FPC
- [ ] Smoke `smoke_rar.dpr` — pass (requer fixture `Make-RarFixture.ps1` + DLL presente)
