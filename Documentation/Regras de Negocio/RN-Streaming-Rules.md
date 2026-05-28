---
internal_file_version: 1.0.0
generated_by: manual
date: 2026-05-28
---

# RN-Streaming-Rules — Contratos de Stream Read-Only

## Contexto

Para arquivos ZIP grandes (>100 MB), leitura full-buffer estoura memória. ZipFileORM expõe `GetEntryStream` que devolve TStream que descomprime sob demanda, permitindo processamento streaming.

## Regra

`function TZipFile.GetEntryStream(const AName: string): TStream` devolve uma das 3 classes:

| Classe | Quando | Comportamento |
|---|---|---|
| `TZipEntryReadStream` | Method = Store (sem compressão) | Wrapper direto sobre file stream |
| `TZipEntryDeflateReadStream` | Method = Deflate | Inflate sob demanda via zlib, WindowBits=-15 (raw deflate) |
| `TZipEntryAESReadStream` | Method = Store/Deflate + AES | Decrypt CTR sob demanda + inflate (se applicable) |

**Semântica de Seek:**
- `TZipEntryReadStream`: Seek total (random access) — wrapper sobre TFileStream
- `TZipEntryDeflateReadStream`: Seek apenas forward (limitação inflate) — `soFromBeginning(0)` permitido (reset stream), `soFromCurrent(positive)` permitido (skip bytes lendo), outros raise `EArchiveStreamSeek`
- `TZipEntryAESReadStream`: Seek apenas forward + reset (idem)

**Position** sempre tracking bytes UNCOMPRESSED (não comprimidos).

## Implementação

- Código: `src/ZipFile.Streaming.pas` (3 classes citadas)
- Sub-módulo ZIP-only (não promovido a Commons pq layout ZIP-specific do local file header)
- `WindowBits=-15` para raw DEFLATE (sem header zlib, conforme APPNOTE.TXT)

## Casos de borda

- **Stream consumido até o fim** → leituras subsequentes retornam 0 (não erro)
- **Free durante leitura** → componente garante teardown limpo (CRC verification suppressed)
- **Concurrent reads do mesmo TZipFile** → NÃO suportado (cada open precisa um TZipFile próprio)
- **AES + Deflate combo** → 2 wrappers em chain (AES read → Inflate read)

## Referências

- Código: `src/ZipFile.Streaming.pas`
- Sub-módulo classification: format-only (ZIP spec specifics) — ver `Documentation/Arquitetura/Camadas_V1.0.md`
