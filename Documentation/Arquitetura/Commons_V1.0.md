---
internal_file_version: 1.0.0
generated_by: documentation-agent-architecture
date: 2026-05-28
---

# ZipFileORM v4.0.0 — Commons: Utilitarios Cross-Format

> Descricao de todos os 13 ficheiros `Commons.*` e `Archive.Open` — os utilitarios reutilizaveis
> que dao suporte a dois ou mais modulos format.
> Ver [Overview_V1.0.md](Overview_V1.0.md) para o contexto de camadas e
> [Modulos_V1.0.md](Modulos_V1.0.md) para os consumidores de cada unidade.

---

## Fronteiras deste documento

| O que entra | O que fica fora |
|---|---|
| Todos os ficheiros `Commons.*` em `src/` | Classes TComponent dos modulos format |
| Ficheiro `Archive.Open.pas` (detector) | Sub-modulos format-only (ZipFile.ZIP64, etc.) |
| Ficheiros `.inc` de compilacao condicional | Facade ZipfileORM.* (ver Camadas_V1.0.md) |

---

## Diagrama de dependencias Commons

```
┌─────────────────────────────────────────────────────────────┐
│                  Modulos Format (L2)                        │
│  TZipFile  TCabFile  TTarFile  TGzipFile  TSevenZFile ...   │
└───┬────────────┬────────────┬────────────┬──────────────────┘
    │            │            │            │
    ▼            ▼            ▼            ▼
┌───────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐
│Commons.   │ │Commons.  │ │Commons.  │ │ZipfileORM.Events │
│Compression│ │Encryption│ │Progress  │ │(nao e Commons.*) │
│.{Base,    │ │.AES      │ │          │ │                  │
│None,ZLib, │ └──────────┘ └──────────┘ └──────────────────┘
│ZLib.Bridge│
│LZMA,Consts│
└─────┬─────┘
      │
      ▼
┌─────────────────────────────┐
│ Commons.{Types,Consts,      │
│         Exceptions}         │
│ Commons.Compression.Defines │
│ Commons.FPC.inc             │
└─────────────────────────────┘
```

---

## 1. Commons.Types

| Atributo | Valor |
|---|---|
| Ficheiro | `src/Commons.Types.pas` |
| Proposito | Tipos de dado compartilhados cross-format |
| Dependencias | `SysUtils`, `Classes` |

### Tipos exportados

| Tipo | Natureza | Descricao |
|---|---|---|
| `TArchiveCapability` | Enum | `(acRead, acWrite, acEncrypt, acSplitVolume, acSolidArchive)` |
| `TArchiveCapabilities` | Set | `set of TArchiveCapability` |
| `TArchiveSearchRec` | Record | Entry descriptor: `Name`, `DateTime`, `UncompressedSize`, `CompressedSize`, `IsDirectory`, `IsEncrypted`, `Comment` |
| `TArchiveProgressInfo` | Record | Progresso: `CurrentEntry`, `EntryIndex`, `TotalEntries`, `BytesProcessed`, `TotalBytes`, `PercentComplete` |

> Nota: `TArchiveFormat` (enum dos 10 formatos) vive em `Archive.Open.pas` — essa e a fonte canonica.

### Quem consome

| Modulo | Uso |
|---|---|
| `ZipfileORM.Interfaces` | `TCompressionMethod` via `ZipfileORM.Compression` (indireto) |
| Todos os modulos format | `TArchiveCapabilities` para inspecao de capacidades em runtime |

---

## 2. Commons.Consts

| Atributo | Valor |
|---|---|
| Ficheiro | `src/Commons.Consts.pas` |
| Proposito | Constantes globais da biblioteca (versao, etc.) |
| Dependencias | Nenhuma |

### Conteudo esperado

Constantes de versao (`ZipFileORM_VERSION = '4.0.0'`) e strings literais partilhadas que nao cabem nos consts especificos de formato. Complementa `Commons.Compression.Consts` (que foca no factory de compressao).

### Quem consome

Facade `ZipfileORM.pas` e rotinas de splash/about em `packages/ZipCompress.SplashReg.pas`.

---

## 3. Commons.Exceptions

| Atributo | Valor |
|---|---|
| Ficheiro | `src/Commons.Exceptions.pas` |
| Proposito | Hierarquia base de exceptions cross-format |
| Dependencias | `SysUtils` |

### Hierarquia de classes

```
EArchive  (Exception base de toda a biblioteca)
  ├─ EArchiveNotFound
  ├─ EArchiveInvalidFormat
  ├─ EArchiveCorrupt
  ├─ EArchiveAlreadyOpen
  ├─ EArchiveNotOpen
  ├─ EArchiveEntryNotFound
  ├─ EArchiveWriteNotSupported
  ├─ EArchivePlatformNotSupported
  └─ EArchiveEncryption
       ├─ EArchivePasswordRequired
       └─ EArchivePasswordIncorrect
```

### Convencao de excecoes por modulo

Cada modulo format define suas proprias subclasses herdadas de `EArchive`:

| Modulo | Exception especifica | Herda de |
|---|---|---|
| TZipFile | `EZipFile` (em ZipFile.pas) | `EArchive` |
| TTarFile | `ETarError` | `Exception` (migracao pendente) |
| TCabFile | `ECabError`, `ECabNotSupportedOnPlatform` | `Exception` (migracao pendente) |
| TSevenZFile | `ESevenZError`, `ESevenZNotSupportedOnPlatform` | `Exception` (migracao pendente) |
| TArjFile | `EArjError` | `Exception` (migracao pendente) |
| Commons.Compression.LZMA | `EZipLZMAError`, `EZipLZMANotSupportedOnPlatform` | `Exception` |
| Commons.Encryption.AES | `EZipAESError` | `Exception` |

> Nota: modulos mais antigos ainda herdam de `Exception` diretamente. A migracao para `EArchive` esta prevista como parte da Onda 2 de refatoracao.

### Quem consome

`ZipfileORM.pas` re-exporta `EArchive` para que consumidores da facade possam capturar qualquer erro da biblioteca com um unico `except EArchive do`.

---

## 4. Commons.Progress

| Atributo | Valor |
|---|---|
| Ficheiro | `src/Commons.Progress.pas` |
| Proposito | Tipo de evento de progresso para operacoes longas |
| Dependencias | `SysUtils` |

### Tipo exportado

```pascal
TZipProgressEvent = procedure(
  Sender: TObject;
  BytesDone, BytesTotal: Int64;
  var Cancel: Boolean
) of object;
```

O parametro `Cancel := True` aborta a operacao em andamento. O chamador e responsavel pelo cleanup apos cancelamento.

### Quem consome

| Modulo | Propriedade de evento |
|---|---|
| TZipFile | `OnProgress` |
| TTarFile | `OnProgress` |
| TTarGzFile | `OnProgress` |
| TGzipFile | `OnProgress` |
| TCabFile | `OnProgress` |
| TSevenZFile | `OnProgress` |

---

## 5. Commons.Compression.Base

| Atributo | Valor |
|---|---|
| Ficheiro | `src/Commons.Compression.Base.pas` |
| Proposito | Classe abstrata + Factory pattern para compressao generica |
| Dependencias | `Classes`, `Contnrs`, `Commons.Compression.Consts` |

### Historico de nomenclatura

Era `tiCompress.pas` do MCL (MODELbuilder Component Library). Renomeado para namespace `Commons.*` na refatoracao v4.0.0.

### Classes exportadas

| Classe | Papel |
|---|---|
| `TtiCompressAbs` | Classe base abstrata — define contrato de 8 metodos (CompressStream, DecompressStream, CompressBuffer, DecompressBuffer, CompressString, DecompressString, CompressFile, DecompressFile) |
| `TtiCompressClass` | `class of TtiCompressAbs` — referencia de classe para o factory |
| `TtiCompressClassMapping` | Associa nome string a uma `TtiCompressClass` |
| `TtiCompressFactory` | Factory: registra classes, cria instancias por nome, lista tipos |

### Singleton global

```pascal
function gCompressFactory: TtiCompressFactory;
```

O factory e um singleton lazy-initialized. Cada implementacao (ZLib, None) chama `gCompressFactory.RegisterClass(...)` em sua secao `initialization`.

### Funcoes de atalho

| Funcao | Descricao |
|---|---|
| `tiCompressString(AString, pCompress)` | Comprime string usando algoritmo nomeado |
| `tiDeCompressString(AString, pCompress)` | Descomprime string |
| `tiCompressStream(From, To, pCompress)` | Comprime stream |
| `tiDeCompressStream(From, To, pCompress)` | Descomprime stream |

### Quem consome

Primariamente `TZipFile.pas` — para deflate (ZLib) e store (None) de entries. Os outros modulos format nao consomem o factory diretamente (usam suas proprias libs C via OBJ link).

---

## 6. Commons.Compression.None

| Atributo | Valor |
|---|---|
| Ficheiro | `src/Commons.Compression.None.pas` |
| Proposito | Implementacao passthrough — Store sem compressao |
| Dependencias | `Commons.Compression.Base`, `Commons.Compression.Consts` |

### Classe exportada

`TtiCompressNone : TtiCompressAbs` — todas as operacoes copiam bytes sem transformacao.

Registra-se no factory com a chave `cgsCompressNone = 'No compression'`.

### Quem consome

`TZipFile` ao criar entries com method 0 (Store).

---

## 7. Commons.Compression.ZLib

| Atributo | Valor |
|---|---|
| Ficheiro | `src/Commons.Compression.ZLib.pas` |
| Proposito | Adaptador ZLib sobre TtiCompressAbs |
| Dependencias Delphi | `System.ZLib` |
| Dependencias FPC | `Commons.Compression.ZLib.Bridge` |

### Historico

Era `tiCompressZLib.pas` do MCL. Renomeado v4.0.0.

### Classe exportada

`TtiCompressZLib : TtiCompressAbs` — implementa todos os 8 metodos abstratos via ZLib.

Registra-se no factory com a chave `cgsCompressZLib = 'ZLib compression'`.

### Quem consome

`TZipFile` para entries com method 8 (Deflate). `TGzipFile` e `TTarGzFile` preferem usar `TarFile.GzipStream` diretamente.

---

## 8. Commons.Compression.ZLib.Bridge

| Atributo | Valor |
|---|---|
| Ficheiro | `src/Commons.Compression.ZLib.Bridge.pas` |
| Proposito | Bridge FPC-only entre TStream e zlib (`zbase` unit) |
| Compilado em | **Apenas FPC** (Delphi usa `System.ZLib` diretamente) |
| Dependencias | `zbase`, `SysUtils`, `Classes` |

### Historico

Era `dzlib.pas` do MCL — renomeado v4.0.0.

### Responsabilidade

Em FPC, a unit `zstream` nao oferece a mesma API que `System.ZLib` do Delphi. Este bridge expoe `CompressBuf` / `DecompressBuf` e as classes de stream necessarias para que `Commons.Compression.ZLib` seja compilavel em FPC sem codigo condicional no corpo.

### Quem consome

Apenas `Commons.Compression.ZLib` — relacao direta e unica.

---

## 9. Commons.Compression.Consts

| Atributo | Valor |
|---|---|
| Ficheiro | `src/Commons.Compression.Consts.pas` |
| Proposito | Constantes string para o factory de compressao |
| Dependencias | Nenhuma |

### Constantes exportadas

| Constante | Valor | Uso |
|---|---|---|
| `cgsCompressNone` | `'No compression'` | Chave de registro de TtiCompressNone |
| `cgsCompressZLib` | `'ZLib compression'` | Chave de registro de TtiCompressZLib; default nas funcoes de atalho |

### Historico

Era `tiConstants.pas` do MCL — renomeado v4.0.0.

### Quem consome

`Commons.Compression.Base`, `Commons.Compression.None`, `Commons.Compression.ZLib` e `TZipFile`.

---

## 10. Commons.Compression.LZMA

| Atributo | Valor |
|---|---|
| Ficheiro | `src/Commons.Compression.LZMA.pas` |
| Proposito | LZMA (method 14 PKWARE) para entries ZIP — Win32+Win64 |
| Dependencias | `SysUtils` |
| Link estatico | `Lib/lzma_obj_win32/` (OMF) e `Lib/lzma_obj_win64/` (ELF) |

### OBJs linkados

| OBJ | Origem | Compilado com |
|---|---|---|
| `LzmaDec.obj` | LZMA SDK 24.07 | `bcc32c -c -O2 -D_7ZIP_ST` |
| `LzmaEnc.obj` | LZMA SDK 24.07 | idem |
| `LzFind.obj` | LZMA SDK 24.07 | idem |
| `Alloc.obj` | LZMA SDK 24.07 | idem |

### API publica

```pascal
procedure LzmaCompressBuffer(
  const Src: Pointer; SrcSize: SizeUInt;
  out   Dst: Pointer; out DstSize: SizeUInt;
  Level: Integer);

procedure LzmaDecompressBuffer(
  const Src: Pointer; SrcSize: SizeUInt;
  out   Dst: Pointer; out DstSize: SizeUInt);
```

### Restricoes de plataforma

| Plataforma | Suporte | Motivo |
|---|---|---|
| Delphi Win32 | Sim | OBJs OMF disponiveis |
| Delphi Win64 | Sim | OBJs ELF disponiveis |
| FPC | Nao | Raise `EZipLZMANotSupportedOnPlatform` |

### Excepcoes exportadas

| Classe | Situacao |
|---|---|
| `EZipLZMAError` | Erros gerais de LZMA |
| `EZipLZMANotSupportedOnPlatform` | FPC ou plataforma sem OBJs |

### Quem consome

Apenas `TZipFile` — para leitura e escrita de entries com method=14 (LZMA PKWARE).

---

## 11. Commons.Encryption.AES

| Atributo | Valor |
|---|---|
| Ficheiro | `src/Commons.Encryption.AES.pas` |
| Proposito | WinZip AE-2 AES-256 para entries ZIP |
| Dependencias | `SysUtils` |
| Implementacao | Pure Pascal — sem lookup tables (compacto e auditavel) |

### Primitivas implementadas

| Primitiva | Especificacao |
|---|---|
| SHA-1 | FIPS 180-4 |
| HMAC-SHA-1 | RFC 2104 |
| PBKDF2-HMAC-SHA-1 | RFC 8018 / PKCS#5 — 1000 iteracoes |
| AES-256 block cipher | FIPS 197 — pure pascal sem T-boxes |
| AES-256-CTR stream | Counter LE little-endian, iniciando em 1 |
| WinZip AE-2 framing | `salt(16) | pwd_verify(2) | ciphertext | hmac10(10)` |

### Constantes exportadas

| Constante | Valor | Descricao |
|---|---|---|
| `AES_BLOCK_SIZE` | 16 | Bytes por bloco AES |
| `AES256_KEY_BYTES` | 32 | Tamanho da chave em bytes |
| `AES256_SALT_SIZE` | 16 | Salt WinZip AE-2 |
| `WINZIP_AE_PWD_VERIFY_BYTES` | 2 | Password verification bytes |
| `WINZIP_AE_HMAC_TRAILER` | 10 | HMAC truncado (10 bytes SHA-1) |
| `WINZIP_AE_ITERATIONS` | 1000 | Iteracoes PBKDF2 |
| `WINZIP_AES_EXTRA_FIELD_ID` | `$9901` | ID do extra field no LFH/CDH |
| `WINZIP_AES_METHOD` | `99` | Placeholder de method quando criptografado |
| `GP_FLAG_ENCRYPTED` | `$0001` | Bit 0 do GP flag = entrada criptografada |

### Tipos exportados

| Tipo | Descricao |
|---|---|
| `TAESKey256` | `array[0..31] of Byte` |
| `TAESBlock` | `array[0..15] of Byte` |
| `TSHA1Digest` | `array[0..19] of Byte` |
| `EZipAESError` | Exception base para erros AES |

### Funcoes publicas (selecao)

| Funcao | Descricao |
|---|---|
| `Sha1Bytes(Data, Len)` | Calcula SHA-1 de buffer |
| `HmacSha1(Key, KeyLen, Msg, MsgLen)` | HMAC-SHA-1 |
| `Pbkdf2HmacSha1(...)` | Derivacao de chave PBKDF2 |
| `AesExpandKey256(...)` | Expande chave AES-256 |
| `AesCtrEncrypt(...)` | Criptografia CTR in-place |

### Quem consome

Apenas `TZipFile` — para entries com `Method=WINZIP_AES_METHOD` (criptografia AES-256).

---

## 12. Commons.FPC.inc

| Atributo | Valor |
|---|---|
| Ficheiro | `src/Commons.FPC.inc` |
| Tipo | Include file de compilacao condicional |
| Proposito | Define `{$IFDEF FPC}` e modos de compilacao comuns a todos os modulos |

### Conteudo tipico

```pascal
{$IFDEF FPC}
  {$mode delphi}
  {$H+}
{$ENDIF}
```

Incluido via `{$I Commons.FPC.inc}` no topo de qualquer unit que precisa ser cross-compiler sem repetir os defines manualmente.

### Quem consome

`ZipfileORM.pas`, `ZipfileORM.Interfaces`, `ZipfileORM.Compression`, `Archive.Open`, e qualquer nova unit que siga o padrao v4.0.0. As units mais antigas (TarFile, CabFile, etc.) ainda usam o pragma inline `{$IFDEF FPC}{$mode delphi}{$H+}{$ENDIF}`.

---

## 13. Commons.Compression.Defines.inc

| Atributo | Valor |
|---|---|
| Ficheiro | `src/Commons.Compression.Defines.inc` |
| Tipo | Include file de compilacao condicional |
| Proposito | Defines especificos do subsistema de compressao |

### Relacao com Commons.FPC.inc

| Include | Escopo |
|---|---|
| `Commons.FPC.inc` | Global — qualquer unit do ZipFileORM |
| `Commons.Compression.Defines.inc` | Especifico — apenas units `Commons.Compression.*` |

### Quem consome

`Commons.Compression.Base`, `Commons.Compression.ZLib`, `Commons.Compression.None` e `Commons.Compression.Consts` (via `{$I Commons.Compression.Defines.inc}`).

---

## 14. Archive.Open (detector de formato)

| Atributo | Valor |
|---|---|
| Ficheiro | `src/Archive.Open.pas` |
| Proposito | Auto-deteccao de formato por magic bytes |
| Dependencias | `SysUtils`, `Classes` |

> Embora nao tenha o prefixo `Commons.`, este ficheiro e tratado como utilitario cross-format — e a unica fonte de verdade do enum `TArchiveFormat` e das funcoes de deteccao.

### TArchiveFormat (enum canônico)

| Valor | Descricao | Magic bytes |
|---|---|---|
| `afUnknown` | Formato nao reconhecido | — |
| `afZip` | ZIP | `PK\x03\x04`, `PK\x05\x06`, `PK\x07\x08` |
| `afGzip` | Gzip single-file | `\x1F\x8B` |
| `afTar` | TAR POSIX ustar | `ustar\x00` em offset 257 |
| `afTarGz` | TAR + Gzip | Gzip + conteudo TAR verificado |
| `afSevenZip` | 7-Zip | `7z\xBC\xAF\x27\x1C` |
| `afRar` | RAR | `Rar!\x1A\x07\x00` ou `\x01\x00` |
| `afCab` | Microsoft Cabinet | `PMOCC` (signature `MSCF`) |
| `afBzip2` | BZip2 | `BZh` |
| `afZCompress` | Unix compress .Z | `\x1F\x9D` |

### Funcoes publicas

| Funcao | Descricao |
|---|---|
| `DetectArchiveFormat(AStream)` | Le primeiros 512 bytes e retorna TArchiveFormat |
| `DetectArchiveFormat(APath)` | Abre arquivo, delega para versao stream |
| `ArchiveFormatToString(AFormat)` | Retorna string legivel (`'ZIP'`, `'Gzip'`, etc.) |
| `EArchiveDetectError` | Exception disparada quando deteccao falha |

### Quem consome

`ZipfileORM.pas` — re-exporta `TArchiveFormat` e `EArchiveDetectError` e delega `TArchive.DetectFormat(...)` para as funcoes deste modulo.

---

## Matriz de consumo (quem usa cada Commons)

| Commons / Ficheiro | TZipFile | TTarFile | TTarGzFile | TGzipFile | TCabFile | TSevenZFile | ZipfileORM |
|---|---|---|---|---|---|---|---|
| Commons.Types | Indireta | Nao | Nao | Nao | Nao | Nao | Sim |
| Commons.Consts | Nao | Nao | Nao | Nao | Nao | Nao | Sim |
| Commons.Exceptions | Indireta | Nao | Nao | Nao | Nao | Nao | Sim |
| Commons.Progress | Sim | Sim | Sim | Sim | Sim | Sim | Nao |
| Commons.Compression.Base | Sim | Nao | Nao | Nao | Nao | Nao | Nao |
| Commons.Compression.None | Sim | Nao | Nao | Nao | Nao | Nao | Nao |
| Commons.Compression.ZLib | Sim | Nao | Nao | Nao | Nao | Nao | Nao |
| Commons.Compression.ZLib.Bridge | FPC only via ZLib | Nao | Nao | Nao | Nao | Nao | Nao |
| Commons.Compression.LZMA | Sim | Nao | Nao | Nao | Nao | Nao | Nao |
| Commons.Compression.Consts | Sim | Nao | Nao | Nao | Nao | Nao | Nao |
| Commons.Encryption.AES | Sim | Nao | Nao | Nao | Nao | Nao | Nao |
| Commons.FPC.inc | Todos | Nao | Nao | Nao | Nao | Nao | Sim |
| Commons.Compression.Defines.inc | Via Base/ZLib/None | Nao | Nao | Nao | Nao | Nao | Nao |
| Archive.Open | Nao | Nao | Nao | Nao | Nao | Nao | Sim |

---

## Checklist de aceite

- [x] 13 ficheiros Commons.* documentados (incluindo 2 .inc e Archive.Open)
- [x] Para cada ficheiro: proposito, tipos/constantes exportados, quem consome
- [x] Hierarquia de exceptions documentada com arvore textual
- [x] Matriz de consumo cruzada (quem usa o que)
- [x] Historico de nomenclatura registrado (MCL -> Commons.*)
- [x] Nenhum placeholder ou stub no conteudo

---

## Ver tambem

- [Overview_V1.0.md](Overview_V1.0.md) — visao de camadas e principios arquiteturais
- [Modulos_V1.0.md](Modulos_V1.0.md) — os modulos format que consomem estes Commons
- [Camadas_V1.0.md](Camadas_V1.0.md) — regras de importacao entre camadas
- [FLOWCHART_V1.0.md](FLOWCHART_V1.0.md) — diagrama Mermaid de dependencias

---

## Changelog (este arquivo)

- 1.0.0 (2026-05-28): Criacao inicial — 13 ficheiros Commons.* + Archive.Open documentados a partir de inspecao real de `src/`.
