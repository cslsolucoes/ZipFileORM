---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Checklist de Implementacao — UUE.Stream (split v4.1)

## Ficheiros alvo do split

- [ ] `UUE.Stream.pas` — `TUUEEncodeStream`, `TUUEDecodeStream` + metodos fluentes inline (dissolver `UUE.Fluent.pas`)
- [ ] `UUE.Interfaces.pas` — `IUUEEncodeStream`, `IUUEDecodeStream`, `IUUEBuilder`
- [ ] `UUE.Consts.pas` — `resourcestring` rsUUE* + constantes: prefixo `begin `, sufixo `end`, charset UUE (32..95), tamanho de linha (60 chars = 45 bytes decodificados)
- [ ] `UUE.Types.pas` — `TUUEPermission` (Word — modo octal Unix do header begin), `TUUELineRec`
- [ ] `UUE.Exceptions.pas` — `EUUEStream`, `EUUEInvalidHeader` (campo: line encontrada), `EUUECorrupted` (herdam de `EArchive`)

## Sub-modulos a fundir

- [ ] `UUE.Fluent.pas` — dissolver: builder passa para `UUE.Stream.pas`

## Observacoes para implementacao pura Pascal

- Sem dependencias de OBJs C — `UUE.Types.pas` e `UUE.Consts.pas` compilam trivialmente standalone
- Sem necessidade de diretivas `{$L}` / `{$LINK}`

## Build gate

- [ ] Compilar `UUE.Types.pas` standalone
- [ ] Compilar `UUE.Consts.pas` standalone
- [ ] Compilar `UUE.Exceptions.pas`
- [ ] Compilar `UUE.Interfaces.pas`
- [ ] Compilar `UUE.Stream.pas` completo
- [ ] Build packages D24..D37 + FPC
- [ ] Smoke UUE — pass
