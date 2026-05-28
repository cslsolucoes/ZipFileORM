# Anatomy â€” ZipFileORM v4.0.0

**Refactored:** 2026-05-28
**Total ficheiros em `src/`:** 42 (39 .pas + 3 .inc)
**Total packages:** 14 dpk (7 runtime + 7 design-time) â€” D24..D37 Ã— W32+W64 = 23 BPL outputs
**Total tests:** 1 DUnitX suite + 12 ZipFile.Tests.*.pas + 25 smoke DPRs + 7 smoke FPC.

## Source inventory (`src/` flat)

### Facade pÃºblica (4 ficheiros) â€” `ZipFileORM.*`
| Ficheiro | DescriÃ§Ã£o |
| --- | --- |
| `ZipFileORM.pas` | TArchive factory + uses agregado de todos os mÃ³dulos. Re-exporta TArchiveFormat. |
| `ZipFileORM.Interfaces.pas` | IArchive, IArchiveEntry, IArchiveBuilder â€” contratos read-only cross-format. |
| `ZipFileORM.Compression.pas` | TCompressionMethod enum global + helpers stringâ†”enum. |
| `ZipFileORM.Events.pas` | 15 TArchive*Event types compartilhados. Era ZipFile.Events.pas. |

### Commons (13 ficheiros) â€” `Commons.*` (cross-format)
| Ficheiro | DescriÃ§Ã£o |
| --- | --- |
| `Commons.Consts.pas` | Resourcestrings globais (rsArchive*) |
| `Commons.Types.pas` | TArchiveSearchRec, TArchiveProgressInfo, TArchiveCapability |
| `Commons.Exceptions.pas` | EArchive hierarchy (8 sub-classes) |
| `Commons.Progress.pas` | TZipProgressEvent (promovido de ZipFile.Progress.pas) |
| `Commons.Compression.Consts.pas` | cgsCompressNone, cgsCompressZLib (era tiConstants.pas) |
| `Commons.Compression.Base.pas` | TtiCompressAbs base + Factory pattern (era tiCompress.pas) |
| `Commons.Compression.None.pas` | TtiCompressNone null object (era tiCompressNone.pas) |
| `Commons.Compression.ZLib.pas` | TtiCompressZLib (era tiCompressZLib.pas) |
| `Commons.Compression.ZLib.Bridge.pas` | FPC-only bridge para zlib (era dzlib.pas) |
| `Commons.Compression.LZMA.pas` | TLZMA codec (promovido de ZipFile.Compression.LZMA.pas) |
| `Commons.Encryption.AES.pas` | TAesContext + WinZip-AE-2 (promovido de ZipFile.Encryption.AES.pas) |
| `Commons.FPC.inc` | {$IFDEF FPC} {$mode delphi}{$H+} block compartilhado |
| `Commons.Compression.Defines.inc` | Diretivas de versionamento Delphi/FPC (era tiDefines.inc) |

### MÃ³dulos format (10) â€” TComponent classes registradas na palheta
| Componente | Ficheiro principal | Sub-mÃ³dulos |
| --- | --- | --- |
| TZipFile    | ZipFile.pas (2035 L) | ZIP64, UTF8, Streaming, Fluent |
| TTarFile    | TarFile.pas (738 L)  | GzipStream, Fluent (Tar.Fluent.pas) |
| TTarGzFile  | TarGzFile.pas (384 L) | â€” |
| TGzipFile   | GzipFile.pas (386 L)  | â€” |
| TCabFile    | CabFile.pas (1267 L)  | Fluent (Cab.Fluent.pas) |
| TSevenZFile | SevenZFile.pas (1491 L) | Fluent (SevenZ.Fluent.pas) |
| TArjFile    | ArjFile.pas (553 L) | â€” |
| TIsoFile    | IsoFile.pas (581 L) | â€” |
| TLhaFile    | LhaFile.pas (1048 L) | â€” |
| TRarFile    | RarFile.pas (546 L) | â€” |

### Helper streams (3 + Fluent variantes)
| Ficheiro | DescriÃ§Ã£o |
| --- | --- |
| `Bzip2.Stream.pas` (384 L) | TBzip2DecompressStream / TBzip2CompressStream (era Bzip2.Bzip2Stream.pas) |
| `Bzip2.Fluent.pas` (159 L) | Fluent builder Bzip2 |
| `UUE.Stream.pas` (214 L) | TUUEEncodeStream / TUUEDecodeStream (era UUE.UUEStream.pas) |
| `UUE.Fluent.pas` (160 L) | Fluent builder UUE |
| `ZCompress.LzwStream.pas` (352 L) | TLzwCompressStream (Unix compress .Z) |
| `ZCompress.Fluent.pas` (142 L) | Fluent builder ZCompress |

### Auto-detect
| Ficheiro | DescriÃ§Ã£o |
| --- | --- |
| `Archive.Open.pas` (141 L) | TArchiveFormat + DetectArchiveFormat (magic bytes) |

## Packages (`packages/`)

| dpk | Variante | Plataformas |
| --- | --- | --- |
| ZipFileORMD24..D29,D37 | runtime | Win32 + Win64 |
| dclZipFileORMD24..D29,D37 | design-time | Win32 (D29+: Win32+Win64) |

Total: 14 dpks, 23 BPL outputs.

Apoio: `zipfileReg.pas` (RegisterComponents + RegisterPropertyInCategory), `ZipFileORM.SplashReg.pas` (IOTA splash), `ZipFileORM.{rc,dcr,bmp}` (glyphs), `icons/`.

## Tests (`tests/`)

- `ZipFileTestsD29.dpr` â€” DUnitX suite consolidada
- 12 `ZipFile.Tests.*.pas` â€” Core/AES/LZMA/Tar/Streaming/UTF8/Zip64/Zip64Write/Fluent/FluentInline/Progress/Shared
- 25 smoke DPRs
- 7 smoke FPC (.pas)
- `fixtures/` â€” binary test fixtures

## Tools (`tools/`)

- `Build-AllDelphis.ps1` â€” build dos 14 dpk Ã— Delphis instalados
- `Build-FPC-Smoke.ps1` â€” 4 FPC targets
- `Build-{Lzma,Bzip2,Lha,Arj}Objs.ps1` â€” recompila OBJs C/C++
- `Make-{Arj,Iso,Lha,Rar}Fixture.ps1` â€” gera fixtures binÃ¡rias
- `Generate-DelphiPackages.ps1` â€” template generator

## Status build (D29 Win32 â€” sanity baseline)

- Commons standalone: âœ… (839 L)
- ZipFileORM facade: âœ… (13151 L compiladas)
- Packages D24..D29 + D37 W32+W64: âœ… (23/23)
- Tests Delphi: âœ… (21/21 DPRs)

## PrÃ³ximas pastas a inventariar

- `Documentation/` â€” Onda 7 pendente (geraÃ§Ã£o via documentation-agent-*)
- `Lib/` â€” outputs binÃ¡rios (gitignored)
- `sdk/`, `deps/`, `dll/` â€” vendored (copiados bit-a-bit)
