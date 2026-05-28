---
internal_file_version: 1.0.0
generated_by: documentation-agent-class-writer
date: 2026-05-28
---

# Modulo RarFile

## O que faz

Implementa `TRarFile`, componente TComponent de leitura de arquivos RAR5 usando a DLL UnRAR vendorizada (`dll/`). Suporta metodo Store plenamente; metodos de compressao 1-5 sao deferred (requerem UnRAR API para descompressao real). Write nao e possivel pelo acordo de licenca da tecnologia RAR. E um dos quatro formatos read-only da biblioteca.

## Ficheiros em `src/`

| Ficheiro | Linhas | Papel |
| --- | --- | --- |
| `RarFile.pas` | 546 | Classe `TRarFile` — FFI para unrar.dll + parser RAR5 |

## Capacidades

| Operacao | Suporte |
| --- | --- |
| Read (extracao Store) | Completo |
| Read (descompressao via UnRAR DLL) | Deferred |
| RAR5 (formato moderno) | Sim |
| RAR4 (formato legado) | Nao confirmado |
| Write | Nao suportado (licenca) |

## Dependencias

- `dll/unrar.dll` (Win32) e `dll/unrar64.dll` (Win64) — vendorizados em `dll/`
- Requere DLL presente no mesmo diretorio do executavel ou no PATH

## Estado atual vs alvo v4.1

**Atual (v3/v4.0):** Classe em ficheiro unico `RarFile.pas` com FFI inline para unrar.dll.

**Alvo (v4.1 — split 5 ficheiros):**

| Ficheiro alvo | Conteudo |
| --- | --- |
| `RarFile.pas` | `TRarFile` + metodo fluente de abertura inline |
| `RarFile.Interfaces.pas` | `IRarFile` (read-only contract) |
| `RarFile.Consts.pas` | Resourcestrings rsRar* + magic RAR5 (`Rar!\x1A\x07\x01\x00`) + offsets |
| `RarFile.Types.pas` | `TRarCompressionMethod` enum, `TRarEntryRec`, records FFI unrar.dll |
| `RarFile.Exceptions.pas` | `ERarFile`, `ERarDllNotFound`, `ERarUnsupportedMethod` (herdam de `EArchive`) |

---

*Referencia: SPEC v3 §13, §17 — P20, P28, P60*
