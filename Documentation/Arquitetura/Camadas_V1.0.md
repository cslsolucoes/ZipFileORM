---
internal_file_version: 1.0.0
generated_by: documentation-agent-architecture
date: 2026-05-28
---

# ZipFileORM v4.0.0 — Modelo de Camadas

> Define as 4 camadas de responsabilidade, as regras de importacao e os contratos de fronteira.
> Ver [Overview_V1.0.md](Overview_V1.0.md) para o diagrama de camadas resumido e
> [FLOWCHART_V1.0.md](FLOWCHART_V1.0.md) para o grafico Mermaid completo de dependencias.

---

## Fronteiras deste documento

| O que entra | O que fica fora |
|---|---|
| Definicao das 4 camadas e seus membros | Implementacao interna de cada modulo |
| Regras de importacao (o que pode/nao pode importar) | Procedimento de build ou deploy |
| Contratos de fronteira (tipos partilhados entre camadas) | Roadmap ou decisoes de negocio |

---

## Visao geral do modelo de camadas

```
┌─────────────────────────────────────────────────────────────────────┐
│  L1 — FACADE PUBLICA                                                │
│  ZipFileORM.*                                                       │
│  ZipFileORM.pas · ZipFileORM.Interfaces · ZipFileORM.Compression   │
│  ZipFileORM.Events                                                  │
└─────────────────────────────┬───────────────────────────────────────┘
                              │  importa
┌─────────────────────────────▼───────────────────────────────────────┐
│  L2 — MODULOS FORMAT (10 TComponent)                                │
│  ZipFile · TarFile · TarGzFile · GzipFile · CabFile · SevenZFile   │
│  ArjFile · IsoFile · LhaFile · RarFile                              │
└────────────┬──────────────────────────────────┬─────────────────────┘
             │ importa                          │ importa
┌────────────▼──────────────┐     ┌─────────────▼──────────────────┐
│  L3 — SUB-MODULOS          │     │  L3 — HELPER STREAMS           │
│  FORMAT-ONLY               │     │  TarFile.GzipStream            │
│  ZipFile.ZIP64             │     │  Bzip2.Stream                  │
│  ZipFile.UTF8              │     │  UUE.Stream · UUE.Fluent       │
│  ZipFile.Streaming         │     │  ZCompress.LzwStream           │
│  ZipFile.Fluent            │     │  ZCompress.Fluent              │
│  Tar.Fluent                │     │                                │
│  Cab.Fluent                │     │                                │
│  SevenZ.Fluent             │     │                                │
│  Bzip2.Fluent              │     │                                │
│  Archive.Open              │     │                                │
└────────────┬──────────────┘     └─────────────┬──────────────────┘
             │ importa                          │ importa
┌────────────▼──────────────────────────────────▼──────────────────┐
│  L4 — COMMONS (utilitarios cross-format)                          │
│  Commons.Types · Commons.Consts · Commons.Exceptions              │
│  Commons.Progress                                                 │
│  Commons.Compression.{Base,None,ZLib,ZLib.Bridge,LZMA,Consts}    │
│  Commons.Encryption.AES                                           │
│  Commons.FPC.inc · Commons.Compression.Defines.inc               │
└───────────────────────────────────────────────────────────────────┘
```

---

## L1 — Facade Publica (`ZipFileORM.*`)

### Membros

| Ficheiro | Responsabilidade |
|---|---|
| `ZipFileORM.pas` | Re-exporta todos os 10 T<Format>File; define `TArchive` (class factory + DetectFormat); constante `ZipFileORM_VERSION` |
| `ZipFileORM.Interfaces` | `IArchive`, `IArchiveEntry`, `IArchiveBuilder` — contratos read-only uniformes |
| `ZipFileORM.Compression` | `TCompressionMethod` enum cross-format + helpers `CompressionMethodToString` |
| `ZipFileORM.Events` | 15+ tipos de evento (`TArchiveLifecycleEvent`, `TArchiveEntryFoundEvent`, etc.) compartilhados por todos os modulos |

### O que L1 pode importar

| Pode importar | Justificativa |
|---|---|
| L2 (todos os 10 modulos format) | Re-exporta os tipos para o consumidor |
| L3 `Archive.Open` | DetectFormat delega para `DetectArchiveFormat` |
| L4 `Commons.Exceptions` | Re-exporta `EArchive` para consumidores |
| L4 `Commons.Types` | Tipos partilhados nos contratos de interface |

### O que L1 nao pode importar

| Proibido | Motivo |
|---|---|
| Sub-modulos format-only (ZipFile.ZIP64, etc.) | Detalhes internos — nao devem vazar na facade publica |
| Commons.Compression.* | Detalhes de algoritmo — nao sao contratos publicos |
| Commons.Encryption.AES | Idem — detalhes internos de ZIP |

### Contrato de fronteira (uso pelo consumidor)

```pascal
uses ZipFileORM;  // unica clausula necessaria

// Deteccao automatica + criacao:
var Fmt: TArchiveFormat;
Fmt := TArchive.DetectFormat('arquivo.7z');
// Fmt = afSevenZip

// Criacao direta:
var Zip: TZipFile;
Zip := TArchive.CreateZip(Self, 'app.zip');
Zip.Open;
var Data: TBytes := Zip.ReadAsBytes('config.json');
Zip.Close;

// Via interface uniforme:
var Arc: IArchive;
// (adapter por implementar na Onda 3)
```

---

## L2 — Modulos Format (10 TComponent)

### Membros

| Classe | Ficheiro | Palette |
|---|---|---|
| `TZipFile` | `ZipFile.pas` | ZipFileORM |
| `TTarFile` | `TarFile.pas` | ZipFileORM |
| `TTarGzFile` | `TarGzFile.pas` | ZipFileORM |
| `TGzipFile` | `GzipFile.pas` | ZipFileORM |
| `TCabFile` | `CabFile.pas` | ZipFileORM |
| `TSevenZFile` | `SevenZFile.pas` | ZipFileORM |
| `TArjFile` | `ArjFile.pas` | ZipFileORM |
| `TIsoFile` | `IsoFile.pas` | ZipFileORM |
| `TLhaFile` | `LhaFile.pas` | ZipFileORM |
| `TRarFile` | `RarFile.pas` | ZipFileORM |

### O que L2 pode importar

| Pode importar | Justificativa |
|---|---|
| L3 sub-modulos format-only do mesmo formato | ZipFile importa ZipFile.ZIP64, ZipFile.UTF8, etc. |
| L3 helper streams transversais | TarGzFile importa TarFile.GzipStream; GzipFile idem |
| L4 Commons.* | Reutilizacao de algoritmos cross-format |
| L1 ZipFileORM.Events | Tipos de evento compartilhados |
| L1 ZipFileORM.Compression | TCompressionMethod (enum cross-format) |

### O que L2 nao pode importar

| Proibido | Motivo |
|---|---|
| Outro modulo format L2 | Excecao: TTarGzFile importa TTarFile (wrapper legítimo) — todos os outros pares sao proibidos |
| ZipFileORM.pas (facade) | Dependencia circular — L1 importa L2, nao o contrario |
| ZipFileORM.Interfaces | Excecao: pode importar para implementar `IArchive` se necessario |

> Excecao documentada: `TTarGzFile` importa `TTarFile` (camada L2 → L2) porque e um wrapper deliberado que delega toda a logica TAR ao `FInner: TTarFile`. Esta relacao e unica e permitida.

### Contrato de fronteira (API publica padrao)

Todos os modulos format devem expor ao menos:

| Metodo / Propriedade | Tipo | Descricao |
|---|---|---|
| `Active` | `Boolean` | True quando o arquivo esta aberto |
| `FileName` | `string` | Caminho do arquivo em disco |
| `Open` | proc | Abre o arquivo |
| `Close` | proc | Fecha o arquivo |
| `GetEntryCount` | `Integer` | Numero de entries |
| `FileExists(AName)` | `Boolean` | Verifica existencia de entry |
| `GetEntryStream(AName)` | `TStream` | Stream do conteudo (caller faz Free) |
| `ReadAsBytes(AName)` | `TBytes` | Conteudo como bytes |
| `ReadAsString(AName)` | `string` | Conteudo como string |
| `OnProgress` | `TZipProgressEvent` | Progresso de operacoes longas |

---

## L3 — Sub-modulos Format-Only + Helper Streams

L3 e dividido em dois grupos com naturezas distintas.

### L3A — Sub-modulos Format-Only

Ficam no mesmo namespace do formato pai e implementam features exclusivas da spec daquele formato.

| Ficheiro | Formato pai | Feature implementada |
|---|---|---|
| `ZipFile.ZIP64.pas` | ZIP | Suporte a entries >4 GB (extensao ZIP64) |
| `ZipFile.UTF8.pas` | ZIP | GP flag bit 11 — filenames UTF-8 per APPNOTE |
| `ZipFile.Streaming.pas` | ZIP | Modo streaming (sem seekable stream) |
| `ZipFile.Fluent.pas` | ZIP | Builder fluent |
| `Tar.Fluent.pas` | TAR | Builder fluent |
| `Cab.Fluent.pas` | CAB | Builder fluent |
| `SevenZ.Fluent.pas` | 7Z | Builder fluent |
| `Bzip2.Fluent.pas` | BZIP2 | Builder fluent |
| `UUE.Fluent.pas` | UUE | Builder fluent |
| `ZCompress.Fluent.pas` | .Z | Builder fluent |
| `Archive.Open.pas` | Cross-format | Deteccao por magic bytes; define `TArchiveFormat` |

### O que L3A pode importar

| Pode importar | Justificativa |
|---|---|
| L4 Commons.* | Raro — apenas se a feature precisar de algoritmo cross-format |
| RTL (`SysUtils`, `Classes`, `ZLib`) | Sempre permitido |

### O que L3A nao pode importar

| Proibido | Motivo |
|---|---|
| L2 (outro modulo format) | Sub-modulo nao deve criar dependencias cruzadas entre formatos |
| L1 (facade) | Dependencia circular |

### L3B — Helper Streams

Streams reutilizaveis que nao sao TComponent e podem ser consumidos por mais de um modulo.

| Ficheiro | Classe(s) exportada(s) | Consumidor principal |
|---|---|---|
| `TarFile.GzipStream.pas` | `TGzipReadStream`, `TGzipWriteStream` | TTarGzFile, TGzipFile |
| `Bzip2.Stream.pas` | Funcoes `Bz2Compress*`, `Bz2Decompress*` | TZipFile (BZip2 entries), standalone |
| `UUE.Stream.pas` | Funcoes `UuEncode*`, `UuDecode*` | Standalone / utilities |
| `ZCompress.LzwStream.pas` | Funcoes `ZCompress*`, `ZDecompress*` | Standalone / utilities |

### O que L3B pode importar

| Pode importar | Justificativa |
|---|---|
| RTL (`SysUtils`, `Classes`, `System.ZLib` / `zstream`) | Sempre permitido |
| L4 Commons.* | Se algoritmo for partilhado (ex.: `Commons.Progress` para eventos de progresso) |

### O que L3B nao pode importar

| Proibido | Motivo |
|---|---|
| L2 (qualquer TComponent format) | Stream nao pode depender de componente — viola separacao |
| L1 (facade) | Dependencia circular |
| Sub-modulos L3A de outros formatos | Mantém isolamento |

---

## L4 — Commons (Cross-Format)

### Membros

| Ficheiro | Categoria |
|---|---|
| `Commons.Types.pas` | Tipos de dado |
| `Commons.Consts.pas` | Constantes globais |
| `Commons.Exceptions.pas` | Hierarquia de exceptions |
| `Commons.Progress.pas` | Tipo de evento de progresso |
| `Commons.Compression.Base.pas` | Infraestrutura de compressao (factory pattern) |
| `Commons.Compression.None.pas` | Implementacao Store |
| `Commons.Compression.ZLib.pas` | Implementacao ZLib / Deflate |
| `Commons.Compression.ZLib.Bridge.pas` | Bridge FPC-only para zlib |
| `Commons.Compression.LZMA.pas` | Implementacao LZMA (via OBJs estaticos) |
| `Commons.Compression.Consts.pas` | Constantes do factory de compressao |
| `Commons.Encryption.AES.pas` | AES-256 WinZip AE-2 |
| `Commons.FPC.inc` | Include de compilacao condicional global |
| `Commons.Compression.Defines.inc` | Include especifico do subsistema de compressao |

### O que L4 pode importar

| Pode importar | Justificativa |
|---|---|
| RTL (`SysUtils`, `Classes`, `ZLib`, `zbase`) | Sempre permitido |
| Outros ficheiros L4 | Commons.Compression.ZLib importa Commons.Compression.Base + Consts |
| OBJs estaticos externos (LZMA SDK, bzip2) | Dependencias C compiladas — nao sao Pascal units |

### O que L4 nao pode importar

| Proibido | Motivo |
|---|---|
| L1 (facade) | Dependencia circular |
| L2 (modulos format) | Commons nao pode depender de um formato especifico |
| L3 (sub-modulos ou helper streams) | Commons sao base; sub-modulos sao folhas |

> Esta e a regra mais critica: qualquer unit `Commons.*` que importar um modulo format (L2) ou sub-modulo (L3) viola a direcionalidade do grafo e cria dependencia circular.

---

## Regras de importacao — tabela consolidada

| Camada | Pode importar | Nao pode importar |
|---|---|---|
| **L1 Facade** | L2 format, L3 Archive.Open, L4 Commons.Exceptions + Commons.Types | L3 sub-modulos format-only, Commons.Compression.*, Commons.Encryption |
| **L2 Format** | L3 proprios sub-modulos + helper streams, L4 Commons.*, L1 Events + Compression | L1 ZipFileORM.pas, outros L2 (exceto TTarGzFile→TTarFile) |
| **L3A Sub-modulo format-only** | L4 Commons.* (raro), RTL | L2 outros formatos, L1, outro L3A |
| **L3B Helper stream** | L4 Commons.* (se necessario), RTL | L2 qualquer TComponent, L1, outro L3A |
| **L4 Commons** | Outros L4, RTL, OBJs externos | L1, L2, L3 |

---

## Fluxo de chamada — caso de uso: leitura de entry ZIP com AES

```
Consumer
  └─ uses ZipFileORM                           [L1: facade]
       └─ TArchive.CreateZip(...)              [L1: factory]
            └─ TZipFile.Create + .Open         [L2: ZipFile]
                 ├─ ZipFile.UTF8 (detect bit11)[L3A: sub-modulo]
                 ├─ ZipFile.ZIP64 (large file) [L3A: sub-modulo]
                 └─ TZipFile.ReadAsBytes(...)
                      ├─ Commons.Compression.ZLib.DecompressBuffer [L4]
                      └─ Commons.Encryption.AES.AesCtrEncrypt      [L4]
```

---

## Fluxo de chamada — caso de uso: leitura de .tar.gz

```
Consumer
  └─ uses ZipFileORM                            [L1: facade]
       └─ TArchive.CreateTarGz(...)             [L1: factory]
            └─ TTarGzFile.Open                  [L2: TarGzFile]
                 ├─ TGzipReadStream (decompress)[L3B: helper stream]
                 │    └─ System.ZLib / zstream  [RTL]
                 └─ TTarFile.Open(FTempBuffer)  [L2: TarFile — excecao permitida]
                      └─ TTarFile.ReadAsBytes   [L2]
```

---

## Dependencias externas (fora do modelo de 4 camadas)

| Dependencia | Tipo | Camada consumidora | Notas |
|---|---|---|---|
| LZMA SDK 24.07 OBJs | OBJ estatico C | L4 Commons.Compression.LZMA | `Lib/lzma_obj_win{32,64}/` |
| bzip2 1.1.0-dev OBJs | OBJ estatico C | L3B Bzip2.Stream | `Library/bzip2/` |
| FDI (Wine Cabinet) OBJ | OBJ estatico C | L2 CabFile | `sdk/cabnet/` |
| LZMA SDK (SevenZWrapper) OBJ | OBJ estatico C | L2 SevenZFile | `Lib/lzma_obj_win{32,64}/` |
| UnRAR DLL | DLL proprietaria | L2 RarFile | `dll/unrar.dll` — binario RarLabs |
| System.ZLib (Delphi RTL) | RTL unit | L3B TarFile.GzipStream, L4 Commons.Compression.ZLib | Nao e uma dep externa — esta na RTL |

---

## Checklist de aceite

- [x] 4 camadas definidas com membros explicitos
- [x] Regras de importacao (pode/nao pode) por camada em tabela
- [x] Diagrama ASCII de camadas com setas direcionais
- [x] Fluxos de chamada concretos para 2 casos de uso
- [x] Excecao TTarGzFile->TTarFile documentada e justificada
- [x] Dependencias externas (OBJs C, DLLs) mapeadas
- [x] Nenhum placeholder ou stub no conteudo

---

## Ver tambem

- [Overview_V1.0.md](Overview_V1.0.md) — diagrama resumido de camadas e principios
- [Modulos_V1.0.md](Modulos_V1.0.md) — decomposicao detalhada dos 13 modulos
- [Commons_V1.0.md](Commons_V1.0.md) — utilitarios cross-format (L4)
- [FLOWCHART_V1.0.md](FLOWCHART_V1.0.md) — grafico Mermaid de todas as dependencias

---

## Changelog (este arquivo)

- 1.0.0 (2026-05-28): Criacao inicial — 4 camadas L1..L4 definidas com regras de importacao, diagramas ASCII, fluxos de chamada e matriz consolidada.
