---
internal_file_version: 1.0.0
generated_by: manual
date: 2026-05-28
---

# RN-Naming-Conventions — Convenções de Naming Dentro de Archives

## Contexto

Diferentes formatos têm regras distintas para encoding de nomes de ficheiros e limites de tamanho. Este RN documenta como ZipFileORM lida com:
- ZIP UTF-8 (EFS bit 11)
- ZIP64 limits (>4 GiB ou >65535 entries)
- TAR format selection (POSIX ustar vs GNU vs PAX)

## Regra

### ZIP UTF-8 (`src/ZipFile.UTF8.pas`)

- Constante: `GP_FLAG_UTF8 = $0800` (bit 11 do General Purpose flag)
- **Read side:** se bit 11 set, decode nome como UTF-8; senão, usa Code Page corrente (legacy CP437/CP850)
- **Write side:** se nome contém chars não-ASCII OU `TZipFile.UseUtf8=True`, seta bit 11

### ZIP64 (`src/ZipFile.ZIP64.pas`)

Aciona quando QUALQUER:
- File size > 4 GiB (4_294_967_295 bytes)
- Compressed size > 4 GiB
- Local file header offset > 4 GiB (archive size > 4 GiB)
- Entry count > 65535

Sentinels:
- `$FFFFFFFF` para campos 32-bit "consultar ZIP64 extra field"
- `$FFFF` para entry count "consultar ZIP64 EOCD"

Force via `TZipFile.ForceZip64 := True` (mesmo para arquivos pequenos — útil para preparar archive antes de saber tamanho final).

### TAR formats (`src/TarFile.pas`)

Enum `TTarFormat`:
- `tfPOSIX_ustar` — padrão POSIX 1003.1-1988 (default)
- `tfGNU` — GNU extensions (long filenames via `././@LongLink`)
- `tfPAX` — POSIX 1003.1-2001 (extended headers)

Limites por campo (todos no header de 512 bytes):
- name: 100 bytes (ustar); 256 bytes (PAX); ilimitado (GNU LongLink)
- linkname: 100 bytes (ustar); idem PAX/GNU
- size: 11 octal digits (≤ 8 GiB em ustar); base-256 binary em PAX/GNU (até 95 bits)

## Implementação

Cada regra tem unit dedicada em `src/`:
- `ZipFile.UTF8.pas` — encoding handling
- `ZipFile.ZIP64.pas` — sentinels + extra field structures
- `TarFile.pas` — `TTarFormat` enum + write logic

## Casos de borda

- **ZIP filename UTF-8 sem bit 11** (alguns produtores antigos) → ZipFileORM detecta heurística (BOM detection)
- **ZIP64 com archive < 4 GiB mas count > 65535** → ainda gera ZIP64 EOCD
- **TAR ustar com filename = 100 chars exactos** → preenche todo o campo sem NUL terminator (válido)

## Referências

- `src/ZipFile.UTF8.pas`
- `src/ZipFile.ZIP64.pas`
- `src/TarFile.pas` (TTarFormat enum)
- APPNOTE.TXT §4.4.4 (general purpose bit flags)
- POSIX 1003.1-1988 (ustar)
