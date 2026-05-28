---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Passo a Passo — Consolidacao Commons v4.1

Commons nao precisa de split (ja foi feito em v4.0). O trabalho de v4.1 e verificacao, adicao de interfaces e documentacao.

## Passo 1 — Auditoria de dependencias

1. Rodar Grep por `uses` em todos os `Commons.*.pas`:
   - Padroes proibidos: `ZipFile`, `TarFile`, `CabFile`, `SevenZFile`, `ArjFile`, `IsoFile`, `LhaFile`, `RarFile`, `Bzip2.Stream`, `UUE.Stream`, `ZCompress.LzwStream`.
2. Qualquer resultado e uma dependencia circular — extrair para uma unidade neutra ou inverter a dependencia.
3. Documentar resultado na tabela de dependencias do `README_Modulo.md`.

## Passo 2 — Verificar hierarquia EArchive

1. Abrir `Commons.Exceptions.pas`.
2. Listar todas as classes declaradas: deve haver `EArchive` + pelo menos 8 subclasses.
3. Para cada modulo de formato, verificar que suas excecoes herdam de uma das subclasses de `EArchive`.
4. Se alguma herda de `Exception` diretamente: corrigir heranca.

## Passo 3 — Criar `Commons.Interfaces.pas`

1. Criar `Commons.Interfaces.pas` com uses `Classes` apenas (para `TStream`).
2. Declarar `ICompressor` (contrato de codec de compressao).
3. Declarar `IEncryptor` (contrato de codec de criptografia).
4. Adicionar `Commons.Interfaces` nos `uses` de `Commons.Compression.Base.pas`.
5. Fazer `TtiCompressAbs` declarar implementacao de `ICompressor` (sem quebrar compatibilidade — adicionar `class(TInterfacedObject, ICompressor)` ou equivalente).

## Passo 4 — Verificar `Commons.FPC.inc` e `Commons.Compression.Defines.inc`

1. Confirmar que todos os `Commons.*.pas` incluem `Commons.FPC.inc` corretamente.
2. Confirmar que `Commons.Compression.ZLib.Bridge.pas` usa `{$IFDEF FPC}` e nao compila em Delphi.
3. Confirmar que nao ha codigo duplicado entre `Commons.Compression.Defines.inc` e `Commons.FPC.inc`.

## Passo 5 — Atualizar documentacao inline

1. Adicionar comentarios `{ }` em cada ficheiro `Commons.*.pas` com descricao de proposito.
2. Documentar cada subclasse de `EArchive` com quando usa-la.

## Passo 6 — Build gate completo

1. Compilar cada `Commons.*.pas` em ordem topologica (Consts → Types → Exceptions → Interfaces → Compression.* → Encryption.*).
2. Build packages D24..D37 × W32+W64 — zero erros.
3. FPC smoke — 4 targets green.
4. DUnitX — 21/21 pass.
