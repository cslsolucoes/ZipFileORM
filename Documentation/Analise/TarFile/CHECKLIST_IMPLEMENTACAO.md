---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Checklist de Implementacao — TarFile (split v4.1)

## Ficheiros alvo do split

- [ ] `TarFile.pas` — `TTarFile` classe + metodos fluentes inline (dissolver `Tar.Fluent.pas`)
- [ ] `TarFile.Interfaces.pas` — `ITarFile`, `ITarFileBuilder` (contrato publico)
- [ ] `TarFile.Consts.pas` — `resourcestring` rsTar* + constantes magicas (magic `ustar\0`, bloco 512 bytes, offsets de campo)
- [ ] `TarFile.Types.pas` — `TTarFormat`, `TTarEntryType`, `TTarHeader` (record 512 bytes), `TTarEntryRec`
- [ ] `TarFile.Exceptions.pas` — `ETarFile`, `ETarCorrupted`, `ETarUnsupportedFormat` (herdam de `EArchive`)

## Sub-modulos a fundir ou manter

- [ ] `Tar.GzipStream.pas` — manter separado (compartilhado com `TarGzFile`); avaliar mover para `Commons.`
- [ ] `Tar.Fluent.pas` — dissolver: metodos `With*` passam para `TTarFile` diretamente

## Build gate

- [ ] Compilar `TarFile.Types.pas` standalone
- [ ] Compilar `TarFile.Consts.pas` standalone
- [ ] Compilar `TarFile.Exceptions.pas` com uses `Commons.Exceptions`
- [ ] Compilar `TarFile.Interfaces.pas` com uses `TarFile.Types`
- [ ] Compilar `TarFile.pas` completo
- [ ] Compilar package D24..D37 + FPC
- [ ] Rodar smoke `smoke_tar.dpr` — pass
