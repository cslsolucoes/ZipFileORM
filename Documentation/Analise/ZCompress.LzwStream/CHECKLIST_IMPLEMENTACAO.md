---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Checklist de Implementacao — ZCompress.LzwStream (split v4.1)

## Ficheiros alvo do split

- [ ] `ZCompress.LzwStream.pas` — `TLzwCompressStream` + metodos fluentes inline (dissolver `ZCompress.Fluent.pas`)
- [ ] `ZCompress.Interfaces.pas` — `ILzwCompressStream`, `IZCompressBuilder`
- [ ] `ZCompress.Consts.pas` — `resourcestring` rsZCompress* + magic Unix compress (`$1F $9D`) + flag byte (bits maximos, block mode)
- [ ] `ZCompress.Types.pas` — `TLzwMaxBits` (subrange 9..16), `TLzwFlag` (block mode, etc.)
- [ ] `ZCompress.Exceptions.pas` — `EZCompressStream`, `ELzwCorrupted` (herdam de `EArchive`)

## Sub-modulos a fundir

- [ ] `ZCompress.Fluent.pas` — dissolver: builder passa para `ZCompress.LzwStream.pas`

## Observacoes

- Sem dependencias de OBJs C — compilacao standalone simples
- Verificar se `TLzwCompressStream` implementa tambem descompressao ou apenas compressao

## Build gate

- [ ] Compilar `ZCompress.Types.pas` standalone
- [ ] Compilar `ZCompress.Consts.pas` standalone
- [ ] Compilar `ZCompress.Exceptions.pas`
- [ ] Compilar `ZCompress.Interfaces.pas`
- [ ] Compilar `ZCompress.LzwStream.pas` completo
- [ ] Build packages D24..D37 + FPC
- [ ] Smoke ZCompress — pass
