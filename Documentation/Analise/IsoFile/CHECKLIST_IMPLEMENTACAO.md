---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Checklist de Implementacao — IsoFile (split v4.1)

## Ficheiros alvo do split

- [ ] `IsoFile.pas` — `TIsoFile` classe + metodo fluente de abertura inline
- [ ] `IsoFile.Interfaces.pas` — `IIsoFile` (read-only: Open, Close, GetEntryCount, ReadAsBytes, FileExists, NavigateDirectory)
- [ ] `IsoFile.Consts.pas` — `resourcestring` rsIso* + identificador de sistema `CD001` + offsets PVD (setor 16, etc.)
- [ ] `IsoFile.Types.pas` — `TIsoVolumeDescriptorType` enum, `TIsoPVD` (Primary Volume Descriptor — 2048 bytes), `TIsoDirectoryRecord`, `TIsoPathTable`
- [ ] `IsoFile.Exceptions.pas` — `EIsoFile`, `EIsoCorrupted`, `EIsoUnsupportedVolume` (herdam de `EArchive`)

## Observacoes para formato read-only

- Sem builder elaborado — apenas `WithFileName` + `ThatOpens`
- Records ISO sao big-endian + little-endian (both-endian fields) — preservar packing correto ao mover para `.Types.pas`

## Build gate

- [ ] Compilar `IsoFile.Types.pas` standalone (com packing correto dos records ISO)
- [ ] Compilar `IsoFile.Consts.pas` standalone
- [ ] Compilar `IsoFile.Exceptions.pas`
- [ ] Compilar `IsoFile.Interfaces.pas`
- [ ] Compilar `IsoFile.pas` completo
- [ ] Build packages D24..D37 + FPC
- [ ] Smoke `smoke_iso.dpr` — pass (requer fixture `Make-IsoFixture.ps1`)
