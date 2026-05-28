---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Checklist de Implementacao — SevenZFile (split v4.1)

## Ficheiros alvo do split

- [ ] `SevenZFile.pas` — `TSevenZFile` classe + metodos fluentes inline (dissolver `SevenZ.Fluent.pas`)
- [ ] `SevenZFile.Interfaces.pas` — `ISevenZFile`, `ISevenZFileBuilder`
- [ ] `SevenZFile.Consts.pas` — `resourcestring` rsSevenZ* + magic bytes 7z header (`$37 $7A $BC $AF $27 $1C`) + versao de header
- [ ] `SevenZFile.Types.pas` — `TSevenZMethod` (Store/LZMA2), `TSevenZFilter` (Delta/BCJ), `TSevenZMatchFinder` (HC4/BT4), records de cabecalho 7z
- [ ] `SevenZFile.Exceptions.pas` — `ESevenZFile`, `ESevenZLZMAError` (com campo `LZMAResult: Integer`), `ESevenZHeaderCorrupted`

## Sub-modulos a fundir

- [ ] `SevenZ.Fluent.pas` — dissolver: metodos `With*` passam para `TSevenZFile`

## Atencao especial — FFI LZMA SDK

- [ ] Declaracoes de FFI do Lzma2Enc/Lzma2Dec devem permanecer visíveis em `SevenZFile.pas` ou ser isoladas em `SevenZFile.Types.pas`
- [ ] Verificar packing dos records C-compat antes de mover

## Build gate

- [ ] Compilar `SevenZFile.Types.pas` standalone
- [ ] Compilar `SevenZFile.Consts.pas` standalone
- [ ] Compilar `SevenZFile.Exceptions.pas`
- [ ] Compilar `SevenZFile.Interfaces.pas`
- [ ] Compilar `SevenZFile.pas` completo (linka OBJs de `Library/`)
- [ ] Build packages D24..D37 + FPC
- [ ] Smoke `smoke_sevenz.dpr` — pass
