---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Checklist de Implementacao — GzipFile (split v4.1)

## Ficheiros alvo do split

- [ ] `GzipFile.pas` — `TGzipFile` classe + metodos fluentes inline
- [ ] `GzipFile.Interfaces.pas` — `IGzipFile`, `IGzipFileBuilder`
- [ ] `GzipFile.Consts.pas` — `resourcestring` rsGzip* + magic bytes `\x1f\x8b` + offsets de header
- [ ] `GzipFile.Types.pas` — `TGzipOsType`, `TGzipFlag` (set), `TGzipHeader` record (10 bytes)
- [ ] `GzipFile.Exceptions.pas` — `EGzipFile`, `EGzipCorrupted` (herdam de `EArchive`)

## Dependencias externas a verificar

- [ ] Verificar se usa `Tar.GzipStream.pas` ou implementacao propria — se propria, consolidar
- [ ] Verificar uses: `System.ZLib` (Delphi) vs `ZStream` (FPC) — encapsular em bloco `{$IFDEF FPC}`

## Build gate

- [ ] Compilar `GzipFile.Types.pas` standalone
- [ ] Compilar `GzipFile.Consts.pas` standalone
- [ ] Compilar `GzipFile.Exceptions.pas`
- [ ] Compilar `GzipFile.Interfaces.pas`
- [ ] Compilar `GzipFile.pas` completo
- [ ] Build packages D24..D37 + FPC
- [ ] Smoke `smoke_gzip.dpr` — pass
