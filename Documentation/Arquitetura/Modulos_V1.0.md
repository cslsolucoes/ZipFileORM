---
internal_file_version: 1.0.0
generated_by: documentation-agent-architecture
date: 2026-05-28
---

# ZipFileORM v4.0.0 — Decomposicao de Modulos

> Descricao detalhada de cada um dos 13 modulos: 10 componentes format e 3 helper streams.
> Ver [Overview_V1.0.md](Overview_V1.0.md) para a visao de camadas e [FLOWCHART_V1.0.md](FLOWCHART_V1.0.md) para o diagrama de dependencias.

---

## Fronteiras deste documento

| O que entra | O que fica fora |
|---|---|
| Classes TComponent de cada formato | Implementacao interna de algoritmos (ZIP64, AES — ver Commons_V1.0.md) |
| Sub-modulos format-only | Facade ZipfileORM.* (ver Camadas_V1.0.md) |
| Helper streams (Bzip2, UUE, ZCompress) | Packages de instalacao (DPK/LPK — ver SPEC) |
| Metodos publicos expostos | Regras de negocio ou roadmap |

---

## 1. Modulo ZIP — TZipFile

### 1.1 Identificacao

| Campo | Valor |
|---|---|
| Ficheiro principal | `src/ZipFile.pas` |
| Classe publica | `TZipFile` |
| Unit Delphi | `ZipFile` |
| Palette page | `ZipCompress` |
| Capacidades | Read + Write |

### 1.2 Sub-modulos format-only

| Ficheiro | Conteudo | Quando ativo |
|---|---|---|
| `ZipFile.ZIP64.pas` | Suporte a arquivos >4 GB (Zip64 extensao PKWARE) | Sempre compilado; ativado em runtime quando entry >4 GB |
| `ZipFile.UTF8.pas` | Detecao e escrita do GP flag bit 11 (UTF-8 filenames) | Sempre compilado |
| `ZipFile.Streaming.pas` | Leitura/escrita sem seekable stream (streaming ZIP) | Sempre compilado |
| `ZipFile.Fluent.pas` | Builder fluent: `WithFileName`, `WithPassword`, `ThatOpens` | Sempre compilado |

### 1.3 Capacidades

| Capacidade | Suporte | Notas |
|---|---|---|
| Read (listar + extrair) | Sim | Qualquer metodo (Deflate, Store, LZMA, BZip2) |
| Write (criar + adicionar) | Sim | Deflate, Store, LZMA |
| AES-256 (WinZip AE-2) | Sim | Chave derivada PBKDF2-HMAC-SHA1 1000 iter |
| ZIP64 (>4 GB) | Sim | Ativado automaticamente quando necessario |
| UTF-8 filenames (bit 11) | Sim | Detectado na leitura; escrito na criacao |
| LZMA (method 14) | Sim (Win32/Win64) | Estaticamente linkado; FPC sem suporte |
| Streaming sem seek | Sim | ZipFile.Streaming.pas |
| Multi-volume | Nao | Deferido |

### 1.4 Metodos publicos principais

| Metodo | Retorno | Descricao |
|---|---|---|
| `Open` | — | Abre o arquivo ZIP para leitura (le central directory) |
| `Close` | — | Fecha o arquivo e libera recursos |
| `GetEntryCount` | `Integer` | Numero de entries no central directory |
| `FileExists(AName)` | `Boolean` | Verifica se entry existe (case-insensitive) |
| `GetEntryStream(AName)` | `TStream` | Stream inflado da entry (caller faz Free) |
| `ReadAsBytes(AName)` | `TBytes` | Conteudo descomprimido como array de bytes |
| `ReadAsString(AName)` | `string` | Conteudo descomprimido como string UTF-8 |
| `AppendStream(AName, AStream)` | — | Adiciona entry ao ZIP (comprime em Deflate) |
| `AppendFile(APath)` | — | Adiciona arquivo do disco ao ZIP |
| `CreateFromFiles(AFiles)` | — | Cria ZIP novo a partir de lista de arquivos |
| `UpdateFile(AName, AStream)` | — | Atualiza entry existente |
| `DeleteFile(AName)` | — | Remove entry do ZIP |
| `WithFileName(AName)` | `TZipFile` | Fluent: define FileName |
| `WithPassword(APwd)` | `TZipFile` | Fluent: define password AES |
| `ThatOpens` | `TZipFile` | Fluent: chama Open e retorna Self |

### 1.5 Dependencias internas consumidas

| Unidade Commons | Motivo do consumo |
|---|---|
| `Commons.Compression.Base` | Factory de algoritmos de compressao |
| `Commons.Compression.None` | Metodo Store (method=0) |
| `Commons.Compression.ZLib` | Deflate (method=8) |
| `Commons.Compression.LZMA` | LZMA (method=14, Win32/Win64) |
| `Commons.Compression.Consts` | Constantes de registro no factory |
| `Commons.Encryption.AES` | WinZip AE-2 AES-256 |
| `Commons.Progress` | `TZipProgressEvent` (progresso overall) |
| `ZipfileORM.Events` | Todos os tipos de evento |

---

## 2. Modulo TAR — TTarFile

### 2.1 Identificacao

| Campo | Valor |
|---|---|
| Ficheiro principal | `src/TarFile.pas` |
| Classe publica | `TTarFile` |
| Unit Delphi | `TarFile` |
| Palette page | `ZipCompress` |
| Capacidades | Read + Write |

### 2.2 Sub-modulos format-only

| Ficheiro | Conteudo |
|---|---|
| `TarFile.GzipStream.pas` | `TGzipReadStream` / `TGzipWriteStream` — wraps ZLib com WindowBits=31 (gzip header) |
| `Tar.Fluent.pas` | Builder fluent: `WithFileName`, `WithFormat`, `ThatOpens` |

### 2.3 Capacidades

| Capacidade | Suporte | Notas |
|---|---|---|
| Read (POSIX ustar) | Sim | Header 512 bytes, tamanho ate 8 GB por entry |
| Read (GNU tar) | Sim | @LongLink para nomes >100 chars |
| Read (PAX) | Sim | POSIX.1-2001 extended headers UTF-8 |
| Write (POSIX ustar) | Sim | Default: tfUstar |
| Write (GNU/PAX) | Sim | Via TTarFormat enum |
| Criptografia | Nao | TAR nao tem spec nativa |
| Compressao | Nao direto | Use TTarGzFile para tar+gzip |

### 2.4 Enums de formato

```pascal
TTarFormat = (tfUstar, tfGnu, tfPax, tfV7);
TTarEntryType = (tetFile, tetDirectory, tetSymLink, tetHardLink, tetOther);
```

### 2.5 Metodos publicos principais

| Metodo | Retorno | Descricao |
|---|---|---|
| `Open` | — | Abre TAR para leitura, constroi indice de entries |
| `Close` | — | Fecha e libera recursos |
| `GetEntryCount` | `Integer` | Total de entries |
| `FileExists(AName)` | `Boolean` | Verifica entry por nome |
| `GetEntryStream(AName)` | `TStream` | Stream do payload (caller faz Free) |
| `ReadAsBytes(AName)` | `TBytes` | Payload completo em bytes |
| `ReadAsString(AName)` | `string` | Payload como string |
| `AppendStream(AName, AStream, AMode)` | — | Adiciona entry ao TAR |
| `AppendFile(APath)` | — | Adiciona arquivo do disco |
| `CreateFromFiles(AFiles)` | — | Cria TAR de lista de arquivos |

### 2.6 Dependencias internas consumidas

| Unidade | Motivo |
|---|---|
| `Commons.Progress` | TZipProgressEvent |
| `ZipfileORM.Events` | Tipos de evento |

---

## 3. Modulo TAR+GZ — TTarGzFile

### 3.1 Identificacao

| Campo | Valor |
|---|---|
| Ficheiro principal | `src/TarGzFile.pas` |
| Classe publica | `TTarGzFile` |
| Unit Delphi | `TarGzFile` |
| Palette page | `ZipCompress` |
| Capacidades | Read + Write |

### 3.2 Arquitetura interna

TTarGzFile e um wrapper: decompress gzip para `TMemoryStream` e delega ao `FInner: TTarFile` interno. Nao e um TComponent separado por si mesmo — reutiliza toda a logica de TTarFile.

```
TarGzFile.Open
  └─ Bz TGzipReadStream(FileStream)
       └─ Descomprime para FTempBuffer (TMemoryStream)
            └─ FInner.Open(FTempBuffer)   -- TTarFile lerá o buffer
```

### 3.3 Capacidades

| Capacidade | Suporte | Notas |
|---|---|---|
| Read (.tar.gz / .tgz) | Sim | Carrega tudo em RAM |
| Write (.tar.gz) | Sim | Escreve TAR em RAM, comprime ao fechar |
| Arquivos grandes (>100 MB) | Nao recomendado | Usar TTarFile + TGzipReadStream direto |

### 3.4 Dependencias internas consumidas

| Unidade | Motivo |
|---|---|
| `TarFile` | FInner: TTarFile |
| `TarFile.GzipStream` | TGzipReadStream / TGzipWriteStream |
| `Commons.Progress` | TZipProgressEvent |
| `ZipfileORM.Events` | Tipos de evento |

---

## 4. Modulo GZIP — TGzipFile

### 4.1 Identificacao

| Campo | Valor |
|---|---|
| Ficheiro principal | `src/GzipFile.pas` |
| Classe publica | `TGzipFile` |
| Unit Delphi | `GzipFile` |
| Palette page | `ZipCompress` |
| Capacidades | Read + Write |

### 4.2 Escopo

Single-file Gzip (RFC 1952): comprime ou descomprime UM unico arquivo. Nao e um archive multi-entrada — diferente de TTarGzFile.

### 4.3 Campos de metadata Gzip

| Campo Gzip | Propriedade Pascal | Descricao |
|---|---|---|
| FNAME | `OriginalName` | Nome original do arquivo dentro do .gz |
| COMMENT | `Comment` | Campo de comentario livre |
| MTIME | `OriginalTimestamp` | Timestamp de modificacao |
| OS | `OSCode` | 3=Unix, 0=FAT, 11=NTFS, 255=desconhecido |
| CRC32 | `CRC32` | Checksum ISIZE (read-only, apos Open) |
| ISIZE | `UncompressedSize` | Tamanho original (modulo 2^32) |

### 4.4 Metodos publicos principais

| Metodo | Retorno | Descricao |
|---|---|---|
| `Open` | — | Abre .gz e le header de metadata |
| `Close` | — | Fecha e libera |
| `CompressFromFile(ASrc)` | — | Comprime arquivo do disco para FileName |
| `CompressFromStream(ASrc)` | — | Comprime stream para FileName |
| `DecompressToFile(ADst)` | — | Descomprime FileName para arquivo |
| `DecompressToStream(ADst)` | — | Descomprime FileName para stream |
| `WithLevel(ALevel)` | `TGzipFile` | Fluent: nivel Deflate (1..9) |

### 4.5 Dependencias internas consumidas

| Unidade | Motivo |
|---|---|
| `TarFile.GzipStream` | TGzipReadStream / TGzipWriteStream |
| `Commons.Progress` | TZipProgressEvent |
| `ZipfileORM.Events` | Tipos de evento |

---

## 5. Modulo CAB — TCabFile

### 5.1 Identificacao

| Campo | Valor |
|---|---|
| Ficheiro principal | `src/CabFile.pas` |
| Classe publica | `TCabFile` |
| Unit Delphi | `CabFile` |
| Palette page | `ZipCompress` |
| Capacidades | Read + Write |

### 5.2 Sub-modulos format-only

| Ficheiro | Conteudo |
|---|---|
| `Cab.Fluent.pas` | Builder fluent: `WithFileName`, `ThatOpens` |

### 5.3 Dependencias nativas

TCabFile linka estaticamente `fdi.obj` do sdk/cabnet/ (Wine cabinet source compilado via bcc32c). Sem dependencia em `cabinet.dll`. Win32-only nesta versao.

### 5.4 Capacidades e restricoes

| Capacidade | Suporte | Notas |
|---|---|---|
| Read (Store / MSZIP) | Sim (Win32) | Via FDI linkado estaticamente |
| Write (FCI) | Sim | Implementado em v3.7+ |
| Win64 | Deferido | Problemas bcc64 ELF (ver SPEC §15) |
| FPC/Linux | Deferido | Requer cross-compile do fdi.obj |
| Sets multi-cabinet | Parcial | SetID + CabinetIndex suportados |

### 5.5 Campos de configuracao de escrita

| Propriedade | Tipo | Descricao |
|---|---|---|
| `Compression` | `TCabCompressionType` | cctNone ou cctMSZIP |
| `CompressionLevel` | `Integer` | 1..9 (reservado v3.8) |
| `SetID` | `Word` | Cabinet set ID (multi-cabinet) |
| `CabinetIndex` | `Word` | Indice dentro do set |
| `VolumeSize` | `Int64` | 0=single .cab; >0=split |

### 5.6 Dependencias internas consumidas

| Unidade | Motivo |
|---|---|
| `Commons.Progress` | TZipProgressEvent |
| `ZipfileORM.Events` | Tipos de evento |

---

## 6. Modulo 7-Zip — TSevenZFile

### 6.1 Identificacao

| Campo | Valor |
|---|---|
| Ficheiro principal | `src/SevenZFile.pas` |
| Classe publica | `TSevenZFile` |
| Unit Delphi | `SevenZFile` |
| Palette page | `ZipCompress` |
| Capacidades | Read + Write |

### 6.2 Sub-modulos format-only

| Ficheiro | Conteudo |
|---|---|
| `SevenZ.Fluent.pas` | Builder fluent |

### 6.3 Dependencias nativas

TSevenZFile linka estaticamente os .obj do LZMA SDK 24.07 (em `Lib/lzma_obj_win32` e `Lib/lzma_obj_win64`) + wrapper minimalista C `sdk/lzma2601/C/SevenZWrapper.c`.

| Platform | OBJ format | Compilador |
|---|---|---|
| Delphi Win32 | OMF | bcc32c (BCC102/D29) |
| Delphi Win64 | ELF | bcc64 (D37) |
| FPC | — | Nao suportado (raise ESevenZNotSupportedOnPlatform) |

### 6.4 Metodos de compressao suportados (leitura)

| Enum `TSevenZMethod` | Codec ID | Descricao |
|---|---|---|
| `szmCopy` | `$00` | Store (sem compressao) |
| `szmLzma2` | `$21` | LZMA2 (default moderno) |
| `szmLzma` | `$03 $01 $01` | LZMA classico |
| `szmPpmd` | `$03 $04 $01` | PPMd (texto) |
| `szmDeflate` | `$04 $01 $08` | Deflate (compatibilidade ZIP) |
| `szmDeflate64` | `$04 $01 $09` | Deflate64 |
| `szmBzip2` | `$04 $02 $02` | BZip2 |
| `szmZstd` | `$04 $F7 $11 $01` | Zstandard (7-zip 22+) |
| `szmBrotli` | `$04 $F7 $11 $02` | Brotli (7-zip 22+) |
| `szmLz4` | `$04 $F7 $11 $04` | LZ4 |

### 6.5 Dependencias internas consumidas

| Unidade | Motivo |
|---|---|
| `Commons.Progress` | TZipProgressEvent |
| `ZipfileORM.Events` | Tipos de evento |

---

## 7. Modulo ARJ — TArjFile

### 7.1 Identificacao

| Campo | Valor |
|---|---|
| Ficheiro principal | `src/ArjFile.pas` |
| Classe publica | `TArjFile` |
| Unit Delphi | `ArjFile` |
| Palette page | `ZipCompress` |
| Capacidades | Read-only |

### 7.2 Capacidades e restricoes

| Capacidade | Suporte | Notas |
|---|---|---|
| Leitura (Method 0 — Store) | Sim | Pure-pascal, sem lib C |
| Leitura de metadata (qualquer method) | Sim | Lista entries sem extrair |
| Extracao (Methods 1-9) | Nao | Deferido v3.4.1 — raise EArjError |
| Criptografia | Nao | file_type=1 nao implementado |
| Multi-volume | Nao | Deferido |
| Cross-platform | Sim | Delphi + FPC + Linux |

### 7.3 Formato ARJ (resumo estrutural)

```
+0  2B  magic 0xEA60
+2  2B  basic_hdr_size
+4  NB  basic header (34 bytes ARJ 2.x: versao, flags, timestamps, CRC, nome)
+4+N  4B  header_crc32
+8+N  cadeia de extended headers (cada um terminado por size=0)
     payload comprimido (se entry de arquivo)
```

### 7.4 Dependencias internas consumidas

Nenhuma dependencia em Commons.* — implementacao pure-pascal autonoma usando apenas `SysUtils` e `Classes`.

---

## 8. Modulo ISO — TIsoFile

### 8.1 Identificacao

| Campo | Valor |
|---|---|
| Ficheiro principal | `src/IsoFile.pas` |
| Classe publica | `TIsoFile` |
| Unit Delphi | `IsoFile` |
| Palette page | `ZipCompress` |
| Capacidades | Read-only |

### 8.2 Capacidades

| Capacidade | Suporte | Notas |
|---|---|---|
| ISO 9660 (nivel 1, 2, 3) | Sim | Leitura de entries + extracao |
| Joliet extensions | Sim | Unicode filenames (UCS-2) |
| Rock Ridge | Nao | Deferido |
| Write (.iso) | Nao | Deferido |

### 8.3 Propriedades de Volume Descriptor

| Propriedade | Descricao |
|---|---|
| `VolumeID` | Label do volume (32 chars ISO) |
| `SystemID` | System identifier |
| `PublisherID` | Publisher identifier |
| `ApplicationID` | Application identifier |
| `CreationDate` | Data de criacao do volume |
| `ModificationDate` | Data de modificacao |

### 8.4 Dependencias internas consumidas

Nenhuma dependencia em Commons.* — pure-pascal, apenas `SysUtils` + `Classes`.

---

## 9. Modulo LHA — TLhaFile

### 9.1 Identificacao

| Campo | Valor |
|---|---|
| Ficheiro principal | `src/LhaFile.pas` |
| Classe publica | `TLhaFile` |
| Unit Delphi | `LhaFile` |
| Palette page | `ZipCompress` |
| Capacidades | Read-only |

### 9.2 Metodos suportados

| Metodo LHA | Suporte | Notas |
|---|---|---|
| `-lh0-` (Store) | Sim | Extracao completa |
| `-lh4-` a `-lh7-` | Verificado por compilacao | Decompressor compilado; testes pendentes |
| `-lzs-`, `-lz5-` | Nao | Deferido |

### 9.3 Dependencias internas consumidas

Nenhuma dependencia em Commons.* — pure-pascal autonomo.

---

## 10. Modulo RAR — TRarFile

### 10.1 Identificacao

| Campo | Valor |
|---|---|
| Ficheiro principal | `src/RarFile.pas` |
| Classe publica | `TRarFile` |
| Unit Delphi | `RarFile` |
| Palette page | `ZipCompress` |
| Capacidades | Read-only |

### 10.2 Capacidades

| Capacidade | Suporte | Notas |
|---|---|---|
| RAR5 Store (method 0) | Sim | Via UnRAR DLL em `dll/` |
| RAR5 methods 1-5 | Deferido | Aguarda decisao de viabilidade (SPEC §17, P60) |
| RAR4 | Nao | Fora de escopo v4.x |
| Write (.rar) | Nao | RAR e formato proprietario; encoder nao disponivel |

### 10.3 Dependencias externas

TRarFile depende de `unrar.dll` (Win32/Win64) da pasta `dll/`. A DLL e binario proprietario da RarLabs — nao compilada a partir do codigo-fonte.

### 10.4 Dependencias internas consumidas

Minima — apenas `SysUtils` + `Classes` + `ZipfileORM.Events` para eventos de erro.

---

## 11. Helper Stream — TGzipReadStream / TGzipWriteStream

### 11.1 Identificacao

| Campo | Valor |
|---|---|
| Ficheiro | `src/TarFile.GzipStream.pas` |
| Unit Delphi | `TarFile.GzipStream` |
| Tipo | Helper stream — nao e TComponent |
| Capacidades | Read + Write (streaming) |

### 11.2 Finalidade

Wraps ZLib com `WindowBits = 31` para ativar o header Gzip (RFC 1952) em vez do header zlib raw. Usado internamente por `TTarGzFile` e `TGzipFile`.

| Classe | Modo | Uso |
|---|---|---|
| `TGzipReadStream` | Leitura | Cliente le bytes inflated; stream interno e gzipped |
| `TGzipWriteStream` | Escrita | Cliente escreve bytes plaintext; saida e gzipped |

### 11.3 Limitacoes

- `Seek` backwards nao suportado (inflate e stateful).
- Para acesso aleatorio em .gz: carregar em `TMemoryStream` intermediario.

### 11.4 Compatibilidade de compilador

| Compiler | Implementacao |
|---|---|
| Delphi (D24..D37) | `System.ZLib` — `TZDecompressionStream` / `TZCompressionStream` |
| FPC / Lazarus | `zstream` unit — `TDecompressionStream` / `TCompressionStream` |

### 11.5 Dependencias internas consumidas

Nenhuma dependencia em Commons.* — usa apenas a RTL ZLib de cada compilador.

---

## 12. Helper Stream — Bzip2.Stream

### 12.1 Identificacao

| Campo | Valor |
|---|---|
| Ficheiro | `src/Bzip2.Stream.pas` |
| Unit Delphi | `Bzip2.Stream` |
| Tipo | Helper stream — nao e TComponent |
| Capacidades | Compress + Decompress (buffer e stream one-shot) |

### 12.2 API publica

| Funcao | Descricao |
|---|---|
| `Bz2CompressBytes(Src, BlockSize100k)` | Comprime `TBytes` em BZip2; retorna `TBytes` |
| `Bz2DecompressBytes(Src)` | Descomprime `TBytes` BZip2 |
| `Bz2CompressStream(Src, Dst, BlockSize100k)` | Comprime stream one-shot |
| `Bz2DecompressStream(Src, Dst)` | Descomprime stream one-shot |

### 12.3 Toolchains / plataformas

| Plataforma | Toolchain dos OBJs | Status |
|---|---|---|
| Delphi Win32 | bcc32c (OMF) | Disponivel v3.8 |
| Delphi Win64 | bcc64 (ELF) | Disponivel v3.8 |
| FPC Win32+Win64 | mingw-w64 (COFF) | Disponivel v3.8 |

### 12.4 Excepcoes

| Classe | Situacao |
|---|---|
| `EBzip2Error` | Erros gerais de BZip2 |
| `EBzip2NotSupportedOnPlatform` | Plataforma sem OBJs compilados |

---

## 13. Helper Stream — ZCompress.LzwStream

### 13.1 Identificacao

| Campo | Valor |
|---|---|
| Ficheiro | `src/ZCompress.LzwStream.pas` |
| Unit Delphi | `ZCompress.LzwStream` |
| Tipo | Helper stream — nao e TComponent |
| Capacidades | Compress + Decompress formato .Z (Unix compress) |

### 13.2 Formato suportado

O formato `.Z` usa LZW (Lempel-Ziv-Welch) com header de 3 bytes (`$1F`, `$9D`, flags). A patente Sperry/Unisys LZW US4558302 expirou em jun/2003 — formato livre.

| Campo | Valor |
|---|---|
| Magic | `0x1F 0x9D` |
| Bit mode max (default) | 16 bits |
| Block mode code | `256` (clear table) |
| First custom code | `257` |

### 13.3 API publica

| Funcao | Descricao |
|---|---|
| `ZCompressBytes(Src, MaxBits)` | Comprime `TBytes` para formato .Z |
| `ZDecompressBytes(Src)` | Descomprime `TBytes` .Z |
| `ZCompressStream(Src, Dst, MaxBits)` | Comprime stream |
| `ZDecompressStream(Src, Dst)` | Descomprime stream |

### 13.4 Dependencias internas consumidas

Nenhuma — implementacao pure-pascal autonoma, apenas `SysUtils` + `Classes`.

---

## Matriz resumo de dependencias por modulo

| Modulo | Commons.Compression.* | Commons.Encryption.AES | Commons.Progress | ZipfileORM.Events | Lib C (OBJ) |
|---|---|---|---|---|---|
| TZipFile | Base, None, ZLib, LZMA, Consts | Sim (AES-256) | Sim | Sim | Sim (LZMA Win32+Win64) |
| TTarFile | Nenhuma | Nao | Sim | Sim | Nao |
| TTarGzFile | Nenhuma (usa TarFile.GzipStream) | Nao | Sim | Sim | Nao |
| TGzipFile | Nenhuma (usa TarFile.GzipStream) | Nao | Sim | Sim | Nao |
| TCabFile | Nenhuma | Nao | Sim | Sim | Sim (FDI Win32) |
| TSevenZFile | Nenhuma | Nao | Sim | Sim | Sim (LZMA SDK Win32+Win64) |
| TArjFile | Nenhuma | Nao | Nao | Nao | Nao |
| TIsoFile | Nenhuma | Nao | Nao | Nao | Nao |
| TLhaFile | Nenhuma | Nao | Nao | Nao | Nao |
| TRarFile | Nenhuma | Nao | Nao | Sim | Sim (unrar.dll) |
| TGzipReadStream | Nenhuma | Nao | Nao | Nao | Nao |
| Bzip2.Stream | Nenhuma | Nao | Nao | Nao | Sim (bzip2 Win32+Win64) |
| ZCompress.LzwStream | Nenhuma | Nao | Nao | Nao | Nao |

---

## Checklist de aceite

- [x] 13 modulos cobertos (10 format + 3 helper streams)
- [x] Cada modulo tem ficheiro principal, classe, capacidades e metodos
- [x] Sub-modulos format-only identificados para ZIP, TAR, GZip, CAB, 7Z
- [x] Matriz de dependencias Commons.* por modulo
- [x] Restricoes de plataforma documentadas (Win32/Win64/FPC)
- [x] Nenhum placeholder ou stub no conteudo

---

## Ver tambem

- [Overview_V1.0.md](Overview_V1.0.md) — visao de camadas e principios arquiteturais
- [Commons_V1.0.md](Commons_V1.0.md) — detalhe dos 13 ficheiros Commons.*
- [Camadas_V1.0.md](Camadas_V1.0.md) — regras de importacao entre camadas
- [FLOWCHART_V1.0.md](FLOWCHART_V1.0.md) — diagrama Mermaid de dependencias

---

## Changelog (este arquivo)

- 1.0.0 (2026-05-28): Criacao inicial — 13 modulos documentados (10 format + 3 helper streams) a partir de inspecao real de `src/`.
