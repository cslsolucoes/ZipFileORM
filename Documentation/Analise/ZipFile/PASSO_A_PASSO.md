---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Passo a Passo — Split ZipFile em 5 ficheiros

## Passo 1 — Extrair bloco `type` para `ZipFile.Types.pas`

1. Abrir `ZipFile.pas` e localizar todos os tipos nao-classe: enums (`TZipCompressionMethod`, `TZipCryptoMethod`), records (`TZipEntryRec`, `TZip64ExtraField`, `TZipLocalHeader`, `TZipCentralDir`).
2. Criar `ZipFile.Types.pas` com cabecalho padrao, secao `interface` com esses tipos.
3. Adicionar `ZipFile.Types` na clausula `uses` de `ZipFile.pas`.
4. Compilar `ZipFile.Types.pas` standalone (nao deve usar `Classes`, `TComponent`).
5. Verificar que todos os usos dos tipos em `ZipFile.pas` resolvem via nova unit.

## Passo 2 — Extrair `resourcestring` para `ZipFile.Consts.pas`

1. Criar `ZipFile.Consts.pas`.
2. Mover todos os blocos `resourcestring` de `ZipFile.pas` (e sub-modulos) para a nova unit.
3. Mover constantes magicas: assinatura `PK\x03\x04`, offsets de campos no header.
4. Adicionar `ZipFile.Consts` nos `uses` de `ZipFile.pas` e `ZipFile.Exceptions.pas`.
5. Compilar standalone.

## Passo 3 — Extrair hierarquia `E<X>` para `ZipFile.Exceptions.pas`

1. Criar `ZipFile.Exceptions.pas` com `uses SysUtils, Commons.Exceptions`.
2. Mover `EZipFile`, `EZipCorrupted`, `EZipPasswordRequired`, `EZipUnsupported` (e quaisquer outras).
3. Garantir que herdam de `EArchive` (de `Commons.Exceptions.pas`).
4. Atualizar `uses` em `ZipFile.pas`.
5. Compilar standalone.

## Passo 4 — Criar `ZipFile.Interfaces.pas` com contrato publico

1. Criar `ZipFile.Interfaces.pas`.
2. Declarar `IZipFile` com metodos publicos espelhados da interface publicada de `TZipFile`.
3. Declarar `IZipFileBuilder` (metodos fluentes: `WithFileName`, `WithPassword`, `ThatOpens`).
4. Declarar `IZipEntry` (campos de entrada: nome, tamanho, CRC, metodo).
5. Usar apenas `ZipFile.Types` e `ZipFile.Exceptions` nos `uses`.
6. Compilar standalone.

## Passo 5 — Dissolver `ZipFile.Fluent.pas` em `ZipFile.pas`

1. Abrir `ZipFile.Fluent.pas` e inventariar todos os metodos `With*`, `ThatOpens`, `ThatCreates`.
2. Mover as implementacoes para a secao `implementation` de `ZipFile.pas`, diretamente na classe `TZipFile`.
3. Adicionar as assinaturas na secao `public` de `TZipFile`.
4. Remover `ZipFile.Fluent.pas` dos packages (`.dpk` e `.lpk`).
5. Remover o ficheiro fisico apos confirmar que nenhum `uses` externo o referencia (Grep: `ZipFile.Fluent`).

## Passo 6 — Build gate completo

1. `dcc32 -Q -B ZipFileORMD29.dpk` — zero warnings/erros.
2. `dcc64 -Q -B ZipFileORMD29.dpk` — zero warnings/erros.
3. Repetir para D24..D28, D37.
4. `pwsh tools/Build-FPC-Smoke.ps1` — 4 targets green.
5. Rodar `ZipFileTestsD29.exe` — 21/21 pass.
6. Rodar smoke `smoke_zip.dpr` — pass.
