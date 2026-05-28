---
internal_file_version: 1.0.0
generated_by: manual
date: 2026-05-28
---

# RN-Encryption-AES — AES-256 WinZip AE-2

## Contexto

ZIP supporta criptografia AES-256 conforme o padrão **WinZip AE-2**. ZipFileORM v4.0.0 implementa este padrão em `Commons.Encryption.AES.pas` (promovido de `ZipFile.Encryption.AES.pas` na refatoração para reuso cross-format — 7Z e RAR futuros poderão consumir).

## Regra

**Setup (write side):**
1. Consumidor define `TZipFile.UseAES := True` e `.Password := 'segredo'`
2. Componente gera 16 bytes random de **salt**
3. Deriva key + verification value via **PBKDF2-HMAC-SHA1** com 1000 iterações
4. Criptografa stream de dados via **AES-256 em modo CTR** (não CBC — WinZip especificação)
5. Anexa 10 bytes de **HMAC-SHA1 trailer** ao final do entry comprimido para integridade

**Verify (read side):**
1. Lê salt do entry header
2. Re-deriva key via PBKDF2 com mesma password
3. Verifica password incorrecta via PWD verification value (2 bytes) ANTES de tentar decrypt
4. Decrypt stream
5. Valida HMAC trailer ao final

## Implementação

Constantes (do código real):
- `AES256_KEY_SIZE = 32` (256 bits)
- `AES256_SALT_SIZE = 16` (128 bits salt)
- `WINZIP_AE_ITERATIONS = 1000` (PBKDF2)
- `WINZIP_AE_HMAC_TRAILER = 10` (bytes)

Path de otimização: **AES-NI hardware** detectado via CPUID → usa instruções `AESENC`/`AESDEC` nativas. Fallback software-only em CPUs antigas.

## Casos de borda

- **Password vazia + UseAES=True** → `EArchivePasswordRequired`
- **Salt curto** (corrupção) → `EArchiveCorrupt`
- **HMAC mismatch** → `EArchiveCorrupt` (NÃO `EArchivePasswordIncorrect` — pode ser corrupção de dados)
- **Cross-platform**: AES-NI funciona em Win32+Win64; FPC Linux usa software fallback

## Referências

- Código: `src/Commons.Encryption.AES.pas`
- Consumidor atual: `src/ZipFile.pas` (`TZipFile.UseAES`, `Password` properties)
- Spec: APPNOTE.TXT §7.4 (PKWARE) + WinZip AE-2 specification
