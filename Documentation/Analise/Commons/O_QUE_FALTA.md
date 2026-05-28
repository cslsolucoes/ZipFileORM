---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# O que Falta — Commons

## Gaps identificados (SPEC v3 §17)

| ID | Descricao | Prioridade | Esforco estimado |
| --- | --- | --- | --- |
| — | `Commons.Interfaces.pas` com `ICompressor` e `IEncryptor` inexistente | Alta | ~4h |
| — | Verificacao de ausencia de dependencias circulares (Commons → Formato) | Alta | ~2h |
| — | Documentacao das 8 subclasses de `EArchive` — quando usar cada uma | Alta | ~2h |
| P70 | Documentacao XML inline em todos os 13 ficheiros | Media | ~8h |
| — | Testes unitarios para `Commons.Compression.*` (ZLib, LZMA, None) | Media | ~6h |

## Gaps especificos do split v4.1

- `TtiCompressAbs` nao implementa `ICompressor` — impossibilita DI em testes (mock de codec).
- `TAesContext` nao implementa `IEncryptor` — impossibilita mock de criptografia em testes.
- `Commons.Compression.ZLib.Bridge.pas` (FPC-only) pode nao ter sido testado em Linux x86_64 (apenas Win32/Win64 verificados).
- `Commons.Compression.LZMA.pas` e `Commons.Encryption.AES.pas`: verificar que as referencias de `uses` em `ZipFile.pas` foram atualizadas de `ZipFile.Compression.LZMA` e `ZipFile.Encryption.AES` para os novos nomes em Commons (promocao v4.0).
- Sem `TArchiveCapability` check API — modulos poderiam expor capacidades (Read/Write/Encrypt/etc.) de forma uniforme.

## Pendencias de testes

- Nenhum teste unitario para `EArchive` hierarquia (heranca, mensagens).
- Nenhum teste para `TtiCompressZLib` standalone (sem `TZipFile`).
- Nenhum teste para `TtiCompressNone` (null object — deve fazer passthrough).
- Sem teste de `Commons.Compression.ZLib.Bridge.pas` no FPC Linux.
