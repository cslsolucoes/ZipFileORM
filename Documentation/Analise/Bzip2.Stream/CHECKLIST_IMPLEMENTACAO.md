---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Checklist de Implementacao — Bzip2.Stream (split v4.1)

## Ficheiros alvo do split

- [ ] `Bzip2.Stream.pas` — `TBzip2DecompressStream`, `TBzip2CompressStream` + metodos fluentes inline (dissolver `Bzip2.Fluent.pas`)
- [ ] `Bzip2.Interfaces.pas` — `IBzip2CompressStream`, `IBzip2DecompressStream`, `IBzip2Builder`
- [ ] `Bzip2.Consts.pas` — `resourcestring` rsBzip2* + magic bytes bzip2 (`BZh`) + block magic + codigos de erro BZ_*
- [ ] `Bzip2.Types.pas` — `TBzip2CompressionLevel` enum (1..9), records FFI bzip2 SDK (`bz_stream`)
- [ ] `Bzip2.Exceptions.pas` — `EBzip2Stream`, `EBzip2DataError`, `EBzip2MemError`, `EBzip2ConfigError` (herdam de `EArchive`)

## Sub-modulos a fundir

- [ ] `Bzip2.Fluent.pas` — dissolver: builder passa para `Bzip2.Stream.pas`

## Atencao especial — OBJs C

- [ ] Confirmar que OBJs bzip2 de `Library/` sao linkados corretamente em `Bzip2.Stream.pas`
- [ ] Verificar diretiva `{$L}` ou `{$LINK}` nos ficheiros apos move

## Build gate

- [ ] Compilar `Bzip2.Types.pas` standalone
- [ ] Compilar `Bzip2.Consts.pas` standalone
- [ ] Compilar `Bzip2.Exceptions.pas`
- [ ] Compilar `Bzip2.Interfaces.pas`
- [ ] Compilar `Bzip2.Stream.pas` completo (requer OBJs de `Library/Bzip2/`)
- [ ] Build packages D24..D37 + FPC
- [ ] Smoke bzip2 — pass
