---
internal_file_version: 1.0.0
generated_by: manual
date: 2026-05-28
---

# RN-Compression-Methods — Matriz de Métodos por Formato

## Contexto

Cada formato suporta um subset distinto de métodos de compressão. O consumidor precisa saber quais são compatíveis ao escrever (write side) e quais são reconhecidos ao ler (read side).

## Regra

Enum global `TCompressionMethod` (em `ZipFileORM.Compression.pas`) cobre todos os métodos. A matriz read/write por formato:

| Formato | Read methods | Write methods |
|---|---|---|
| **ZIP**     | Store, Deflate, Deflate64, BZip2, LZMA | Store, Deflate, LZMA |
| **TAR**     | (uncompressed) | (uncompressed) |
| **TAR.GZ**  | Deflate (via gzip) | Deflate |
| **GZ**      | Deflate | Deflate |
| **CAB**     | MSZIP, Quantum, LZX | MSZIP |
| **7Z**      | LZMA2, Store | LZMA2, Store |
| **ARJ**     | Store (methods 1-9 deferred) | — (read-only) |
| **ISO**     | (uncompressed) | — (read-only) |
| **LHA**     | -lh0 Store; -lh4..7 compile-verified | — (read-only) |
| **RAR**     | RAR5 Store (methods 1-5 deferred) | — (read-only) |

## Implementação

- Enum: `src/ZipFileORM.Compression.pas` (`TCompressionMethod`)
- Helpers: `CompressionMethodToString`, `StringToCompressionMethod`
- Per-format: `T<Format>File.CompressionMethod` (property published em alguns componentes)

## Casos de borda

- **Store** = sem compressão (Method 0 em ZIP, Method 0 em 7Z)
- **Deflate raw** (WindowBits=-15) vs **Deflate com header zlib** — ZIP usa raw
- **LZMA em ZIP** (method 14): requer flag UseLZMA + decoder próprio (diferente do LZMA2 do 7Z)
- **Methods deferidos** (ARJ 1-9, RAR 1-5): retornam `cmUnknown` e `EArchiveCorrupt` na extração

## Referências

- `src/ZipFileORM.Compression.pas` — enum + helpers
- `src/ZipFile.pas` — TZipFile.Compression property
- `src/SevenZFile.pas` — TSevenZFile.CompressionMethod
- `src/CabFile.pas` — TCabFile.Compression (TCabCompressionType)
