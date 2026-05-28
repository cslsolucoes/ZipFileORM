---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Checklist de Implementacao — Commons (consolidacao v4.1)

## Status atual

Commons ja esta split em multiplos ficheiros desde v4.0. O trabalho de v4.1 e de consolidacao e adicao de contratos de interface, nao split.

## Acoes v4.1

### Verificacao de integridade

- [ ] Confirmar que nenhum ficheiro `Commons.*` importa unidades de formato (`ZipFile`, `TarFile`, etc.) nos `uses`
- [ ] Confirmar que nenhum ficheiro de formato importa outro formato via Commons (dependencia circular)
- [ ] Rodar Grep: `uses.*ZipFile` em todos os `Commons.*.pas` — deve retornar zero resultados
- [ ] Verificar `Commons.Compression.ZLib.Bridge.pas` tem `{$IFDEF FPC}` correto e nao compila em Delphi

### Adicionar `Commons.Interfaces.pas` (novo ficheiro)

- [ ] Declarar `ICompressor` — `Compress(AInput, AOutput: TStream): Integer`; `Decompress(AInput, AOutput: TStream): Integer`; `GetMethodName: string`
- [ ] Declarar `IEncryptor` — `Encrypt(AKey: TBytes; AInput, AOutput: TStream)`, `Decrypt(AKey: TBytes; AInput, AOutput: TStream)`
- [ ] Fazer `TtiCompressAbs` implementar `ICompressor`
- [ ] Fazer `TAesContext` implementar `IEncryptor`

### Documentar hierarquia EArchive

- [ ] Listar as 8 subclasses de `EArchive` em `Commons.Exceptions.pas` com descricao de quando usar cada uma
- [ ] Verificar que todas as excecoes dos modulos de formato herdam de uma das 8 subclasses (nao de `Exception` diretamente)

## Build gate

- [ ] Compilar `Commons.Types.pas` standalone
- [ ] Compilar `Commons.Consts.pas` standalone
- [ ] Compilar `Commons.Exceptions.pas` com uses `SysUtils` apenas
- [ ] Compilar `Commons.Interfaces.pas` standalone
- [ ] Compilar `Commons.Compression.Base.pas`
- [ ] Compilar toda a cadeia Commons em ordem topologica
- [ ] Build packages D24..D37 + FPC — zero erros
