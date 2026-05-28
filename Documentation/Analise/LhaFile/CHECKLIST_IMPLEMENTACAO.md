---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Checklist de Implementacao — LhaFile (split v4.1)

## Ficheiros alvo do split

- [ ] `LhaFile.pas` — `TLhaFile` classe + metodo fluente de abertura inline
- [ ] `LhaFile.Interfaces.pas` — `ILhaFile` (read-only: Open, Close, GetEntryCount, ReadAsBytes, FileExists)
- [ ] `LhaFile.Consts.pas` — `resourcestring` rsLha* + constantes de identificador de metodo (`-lh0-`=Store, `-lh4-`..,`-lh7-`), nivel de header
- [ ] `LhaFile.Types.pas` — `TLhaMethod` enum, `TLhaHeaderLevel` (0/1/2), `TLhaLocalHeader` record (com campos variavies por nivel)
- [ ] `LhaFile.Exceptions.pas` — `ELhaFile`, `ELhaUnsupportedMethod`, `ELhaCorrupted` (herdam de `EArchive`)

## Observacoes para formato read-only e algoritmo interno

- O codec Huffman adaptativo (-lh4..-lh7-) vive em `LhaFile.pas` — avaliar se isolar em `LhaFile.Codec.pas` interno (fora do split obrigatorio de 5, mas util para legibilidade)
- Records de header LHA Level-0/1/2 tem estrutura variavel — modelar com cuidado

## Build gate

- [ ] Compilar `LhaFile.Types.pas` standalone
- [ ] Compilar `LhaFile.Consts.pas` standalone
- [ ] Compilar `LhaFile.Exceptions.pas`
- [ ] Compilar `LhaFile.Interfaces.pas`
- [ ] Compilar `LhaFile.pas` completo
- [ ] Build packages D24..D37 + FPC
- [ ] Smoke `smoke_lha.dpr` — pass (requer fixture `Make-LhaFixture.ps1`)
