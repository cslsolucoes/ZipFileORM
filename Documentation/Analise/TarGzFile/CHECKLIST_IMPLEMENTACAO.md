---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Checklist de Implementacao — TarGzFile (split v4.1)

## Ficheiros alvo do split

- [ ] `TarGzFile.pas` — `TTarGzFile` classe + metodos fluentes inline
- [ ] `TarGzFile.Interfaces.pas` — `ITarGzFile`, `ITarGzFileBuilder`
- [ ] `TarGzFile.Consts.pas` — `resourcestring` rsTarGz* + constantes (nivel de compressao default)
- [ ] `TarGzFile.Types.pas` — `TTarGzCompressionLevel` enum + tipos especificos
- [ ] `TarGzFile.Exceptions.pas` — `ETarGzFile` (herda de `EArchive`)

## Dependencias externas a verificar

- [ ] `Tar.GzipStream.pas` — confirmar que a dependencia e via `uses` e nao por copia de codigo
- [ ] `TarFile.Types.pas` — `TTarGzFile` pode reusar `TTarFormat` e `TTarHeader`; avaliar uses cruzado

## Build gate

- [ ] Compilar `TarGzFile.Types.pas` standalone
- [ ] Compilar `TarGzFile.Consts.pas` standalone
- [ ] Compilar `TarGzFile.Exceptions.pas`
- [ ] Compilar `TarGzFile.Interfaces.pas`
- [ ] Compilar `TarGzFile.pas` completo
- [ ] Build packages D24..D37 + FPC
- [ ] Smoke `smoke_targz.dpr` — pass
