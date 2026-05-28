---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Checklist de Implementacao — ArjFile (split v4.1)

## Ficheiros alvo do split

- [ ] `ArjFile.pas` — `TArjFile` classe + metodo fluente de abertura inline
- [ ] `ArjFile.Interfaces.pas` — `IArjFile` (somente leitura: Open, Close, GetEntryCount, ReadAsBytes, FileExists)
- [ ] `ArjFile.Consts.pas` — `resourcestring` rsArj* + magic `$60 $EA` + offsets de cabecalho ARJ
- [ ] `ArjFile.Types.pas` — `TArjCompressionMethod` (Store=0, outros 1-9), `TArjFlag`, `TArjEntryRec`, `TArjLocalHeader`
- [ ] `ArjFile.Exceptions.pas` — `EArjFile`, `EArjUnsupportedMethod`, `EArjCorrupted` (herdam de `EArchive`)

## Observacoes para formato read-only

- Sem `IArjFileBuilder` elaborado — apenas `WithFileName` + `ThatOpens`
- Sem dissolver fluent (ArjFile nao tem `Arj.Fluent.pas`)

## Build gate

- [ ] Compilar `ArjFile.Types.pas` standalone
- [ ] Compilar `ArjFile.Consts.pas` standalone
- [ ] Compilar `ArjFile.Exceptions.pas`
- [ ] Compilar `ArjFile.Interfaces.pas`
- [ ] Compilar `ArjFile.pas` completo
- [ ] Build packages D24..D37 + FPC
- [ ] Smoke `smoke_arj.dpr` — pass (requer fixture `Make-ArjFixture.ps1`)
