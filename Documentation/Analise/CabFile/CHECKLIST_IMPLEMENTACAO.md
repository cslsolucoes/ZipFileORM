---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Checklist de Implementacao — CabFile (split v4.1)

## Ficheiros alvo do split

- [ ] `CabFile.pas` — `TCabFile` classe + metodos fluentes inline (dissolver `Cab.Fluent.pas`)
- [ ] `CabFile.Interfaces.pas` — `ICabFile`, `ICabFileBuilder`
- [ ] `CabFile.Consts.pas` — `resourcestring` rsCab* + magic `MSCF` (4 bytes) + offsets de header Cabinet
- [ ] `CabFile.Types.pas` — `TCabCompressionType`, `TCabEntryRec`, records `CABINET` / `CFHEADER` / `CFFOLDER` / `CFFILE`
- [ ] `CabFile.Exceptions.pas` — `ECabFile`, `ECabFDIError`, `ECabFCIError` (herdam de `EArchive`)

## Sub-modulos a fundir

- [ ] `Cab.Fluent.pas` — dissolver: metodos `With*` passam para `TCabFile`

## Atencao especial — FFI

- [ ] As declaracoes FFI (imports de fdi.h/fci.h) devem permanecer em `CabFile.pas` ou ser isoladas em `CabFile.Types.pas` (records C-compat)
- [ ] Verificar alinhamento de packing (`{$ALIGN 1}` / `packed record`) nos records FFI antes de mover

## Build gate

- [ ] Compilar `CabFile.Types.pas` standalone (com `{$ALIGN 1}` se necessario)
- [ ] Compilar `CabFile.Consts.pas` standalone
- [ ] Compilar `CabFile.Exceptions.pas`
- [ ] Compilar `CabFile.Interfaces.pas`
- [ ] Compilar `CabFile.pas` completo
- [ ] Build packages D24..D37 + FPC
- [ ] Smoke `smoke_cab.dpr` — pass
