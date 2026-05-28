---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Checklist de Implementacao — ZipFile (split v4.1)

## Ficheiros alvo do split

- [ ] `ZipFile.pas` — `TZipFile` classe + metodos fluentes inline (dissolver `ZipFile.Fluent.pas`)
- [ ] `ZipFile.Interfaces.pas` — `IZipFile`, `IZipFileBuilder`, `IZipEntry` (contrato publico)
- [ ] `ZipFile.Consts.pas` — `resourcestring` rsZip* + constantes magicas (`PK\x03\x04`, offsets de header)
- [ ] `ZipFile.Types.pas` — `TZipCompressionMethod`, `TZipCryptoMethod`, `TZipEntryRec`, `TZip64ExtraField`
- [ ] `ZipFile.Exceptions.pas` — `EZipFile`, `EZipCorrupted`, `EZipPasswordRequired`, `EZipUnsupported`

## Sub-modulos a fundir ou promover

- [ ] `ZipFile.ZIP64.pas` — fundir em `ZipFile.pas` (logica de leitura/escrita de offsets 64-bit)
- [ ] `ZipFile.UTF8.pas` — fundir em `ZipFile.pas` (helper string encoding ja e pequeno)
- [ ] `ZipFile.Streaming.pas` — manter separado ou fundir (decidir em v4.1)
- [ ] `ZipFile.Fluent.pas` — dissolver: metodos `With*` e `ThatOpens` passam para `TZipFile` diretamente
- [ ] `ZipFile.Events.pas` — ja promovido para `ZipFileORM.Events.pas` em v4.0 (verificar uses)
- [ ] `ZipFile.Progress.pas` — ja promovido para `Commons.Progress.pas` em v4.0 (verificar uses)
- [ ] `ZipFile.Encryption.AES.pas` — ja promovido para `Commons.Encryption.AES.pas` em v4.0
- [ ] `ZipFile.Compression.LZMA.pas` — ja promovido para `Commons.Compression.LZMA.pas` em v4.0

## Build gate

- [ ] Compilar `ZipFile.Types.pas` standalone (sem dependencias de TComponent)
- [ ] Compilar `ZipFile.Consts.pas` standalone
- [ ] Compilar `ZipFile.Exceptions.pas` com uses minimo (`SysUtils`, `Commons.Exceptions.pas`)
- [ ] Compilar `ZipFile.Interfaces.pas` com uses `ZipFile.Types.pas`
- [ ] Compilar `ZipFile.pas` completo (runtime package D24..D37 + FPC)
- [ ] Rodar suite DUnitX: 21/21 pass
- [ ] Rodar smoke tests ZipFile: pass
