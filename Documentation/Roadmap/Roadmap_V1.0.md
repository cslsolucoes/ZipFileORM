---
internal_file_version: 1.0.0
generated_by: documentation-agent-roadmap
date: 2026-05-28
---

# ZipFileORM — Roadmap de Evolucao v4.x / v5.0

## Resumo executivo

- Este roadmap cobre o horizonte v4.1 a v5.0 do ZipFileORM, partindo do estado estabelecido em v4.0.0 (refactor completo de naming + arquitetura sobre a v3.12.2).
- Cada fase e cada item do backlog sao rastreados a um gap concreto identificado na arvore `Documentation/` atual ou a um item pendente herdado da SPEC v3 (`Documentation/spec/zipfile-v3-multi-format-expansion.md §17`, itens P01..P98).
- As fases de documentacao e de codigo evoluem em paralelo; itens marcados como "documental" criam ou revisam artefactos em `Documentation/`; itens marcados como "codigo" entregam funcionalidade nova no `src/`.
- O hub `Documentation/README_V1.0.md` deve ser ressincronizado ao final de cada fase concluida.
- Escopo excluido: este roadmap nao executa migracoes, nao classifica documentos como superseded e nao cria RNs ou analises canonicas — essas operacoes pertencem aos agents especializados referenciados em cada item.

---

## 1. Estado atual — v4.0.0 (baseline deste roadmap)

### 1.1 Codigo

| Aspecto | Estado |
|---|---|
| `src/` | Flat, naming canonico `<Module>.<Feature>.pas` |
| Facade | `ZipfileORM.{pas,.Interfaces,.Compression,.Events}` — 4 units |
| Modulos format | 13 modulos: ZipFile, TarFile, TarGzFile, GzipFile, CabFile, SevenZFile, ArjFile, IsoFile, LhaFile, RarFile + Bzip2.Stream, UUE.Stream, ZCompress.LzwStream |
| Commons | 13 units cross-format: `Commons.Compression.{Base,None,ZLib,LZMA,Consts}`, `Commons.Encryption.AES`, `Commons.Progress`, `Commons.{Types,Consts,Exceptions}`, `Commons.{FPC,Compression.Defines}.inc` |
| Packages | 14 dpks (7 runtime + 7 design) → 23 BPLs D24..D37 Win32+Win64, todos verde |
| Testes | DUnitX compilando + 20 smokes compilando |

### 1.2 Documentacao (gaps identificados)

| Path | Status | Gap |
|---|---|---|
| `Documentation/README_V1.0.md` | Completo (hub) | Nenhum; ressincronizar apos cada fase |
| `Documentation/Arquitetura/Overview_V1.0.md` | Completo | Nenhum |
| `Documentation/Arquitetura/FLOWCHART_V1.0.md` | Completo | Nenhum |
| `Documentation/Arquitetura/Modulos_V1.0.md` | **Ausente** | Referenciado em Overview mas nao existe |
| `Documentation/Arquitetura/Commons_V1.0.md` | **Ausente** | Referenciado em Overview mas nao existe |
| `Documentation/Arquitetura/Camadas_V1.0.md` | **Ausente** | Referenciado em Overview mas nao existe |
| `Documentation/Regras de Negocio/` | **Vazia** (esqueleto) | 5 RNs planejadas nao criadas |
| `Documentation/API/` | **Vazia** (esqueleto) | 13 pastas modulo sem nenhum .md |
| `Documentation/Analise/` | **Vazia** (esqueleto) | 14 pastas sem arquivos .md |
| `Documentation/Roadmap/Migracao_v3_to_v4.md` | Completo | Nenhum |
| `Documentation/Roadmap/Roadmap_V1.0.md` | **Ausente** | Este arquivo — item de Onda 7.8 |
| `Documentation/Backup/` | Vazia (intencional) | Sem supersedidos ainda |
| `Documentation/spec/zipfile-v3-multi-format-expansion.md` | Completo (legacy) | SPEC v3 encerrada; preservada como referencia; nao editar |

### 1.3 Referencia SPEC v3 herdada

Todos os itens P01..P98 da SPEC v3 estao documentados em:
`Documentation/spec/zipfile-v3-multi-format-expansion.md` §17

Os itens pendentes consumidos por este roadmap sao:

| Item SPEC | Descricao resumida | Fase neste roadmap |
|---|---|---|
| P20-P29 | Property population — Object Inspector mais rico | v4.2 |
| P03+P04 | Event firing OnEntryFound + OnExtract nos formatos read-only | v4.3 |
| P40+P41 | 7z encryption write + 7z multi-volume write | v4.4 |
| P70+P73 | XML doc-comments publicos + examples por componente | v4.5 |
| P60 | UnRAR encoder (major undertaking) | v5.0 |

---

## 2. Fase Curta — v4.1: Splits profundos (Onda 2.x codigo)

**Horizonte:** 1-2 sprints (~25h de codigo + ~8h documental)
**Objetivo operacional:**
- Decompor cada modulo format monolitico em 5 ficheiros canonicos.
- Dissolver os `*.Fluent.pas` na classe principal (fluent inline) e em `*.Interfaces.pas` (builder interfaces).
- Gerar documentacao de arquitetura dos sub-modulos resultantes.

### 2.1 Escopo de codigo

Para cada um dos 13 modulos format (ZipFile, TarFile, TarGzFile, GzipFile, CabFile, SevenZFile, ArjFile, IsoFile, LhaFile, RarFile, Bzip2.Stream, UUE.Stream, ZCompress.LzwStream), entregar:

| Ficheiro | Conteudo |
|---|---|
| `<Module>.pas` | Classe principal `T<Format>File` com metodos fluent inline |
| `<Module>.Interfaces.pas` | `I<Format>*` interfaces + builder interfaces (absorve `*.Fluent.pas`) |
| `<Module>.Consts.pas` | Constantes do formato (magic bytes, limites, defaults) |
| `<Module>.Types.pas` | Enumeracoes e records proprios do formato |
| `<Module>.Exceptions.pas` | `E<Format>*` exceptions especificas |

Ordem priorizada: ZipFile → TarFile → resto (pelos modulos com mais consumidores na testsuite).

### 2.2 Escopo documental — v4.1

| Documento esperado | Acao | Entrada | Saida | Criterio de aceite | Responsavel |
|---|---|---|---|---|---|
| `Documentation/Arquitetura/Modulos_V1.0.md` | Criar | Overview_V1.0.md (referencia) + `src/` pos-split | Decomposicao detalhada dos 13 modulos com 5-file pattern | Arquivo criado; todos os 13 modulos descritos; referenciado no hub | Responsavel_Arquitetura |
| `Documentation/Arquitetura/Commons_V1.0.md` | Criar | Overview_V1.0.md (referencia) + `src/Commons.*` | Catalogo das 13 units Commons com responsabilidade e dependentes | Arquivo criado; lista completa de 13 units; sem omissoes | Responsavel_Arquitetura |
| `Documentation/Arquitetura/Camadas_V1.0.md` | Criar | Overview_V1.0.md + FLOWCHART_V1.0.md | Documento descritivo da separacao de responsabilidades por camada | Arquivo criado; quatro camadas (Facade, Modulos, Helpers, Commons) descritas com exemplos | Responsavel_Arquitetura |
| `Documentation/README_V1.0.md` | Revisar (ressincronizar) | Estado pos-entrega dos 3 arquivos acima | Hub com links para os 3 novos arquivos de Arquitetura | Links presentes; sem links orfaos; StatusCell atualizado | Responsavel_Arquitetura |

### 2.3 Dependencias

- Nenhum item documental desta fase bloqueia o trabalho de codigo.
- Os 3 arquivos de Arquitetura ausentes (Modulos, Commons, Camadas) sao pre-requisito para a fase v4.5 (XML docs + examples) que precisara referencias cruzadas.

### 2.4 Criterio de pronto — v4.1

- [ ] 13 modulos com 5-file split compilando sem erros em todos os 14 packages (23/23 BPLs verde).
- [ ] DUnitX + 20 smokes continuam passando sem regressao.
- [ ] `Documentation/Arquitetura/Modulos_V1.0.md` criado e referenciado no hub.
- [ ] `Documentation/Arquitetura/Commons_V1.0.md` criado e referenciado no hub.
- [ ] `Documentation/Arquitetura/Camadas_V1.0.md` criado e referenciado no hub.
- [ ] Hub `README_V1.0.md` ressincronizado; nenhum link para arquivo inexistente.

---

## 3. Fase Media — v4.2: Property population (~50h codigo)

**Horizonte:** 3-4 sprints
**Referencia SPEC:** itens P20-P29 em `Documentation/spec/zipfile-v3-multi-format-expansion.md §17`
**Objetivo operacional:**
- Preencher as properties read-only de cabecalho e flags de todos os formatos, tornando o Object Inspector mais rico e informativo sem breaking changes.
- Baixo risco (nenhuma quebra de ABI); alto valor visual (IDE usability).

### 3.1 Escopo de codigo (P20-P29)

Cada formato recebe propriedades `published` read-only populadas durante `Open`:

| Modulo | Properties a popular |
|---|---|
| TZipFile | `ArchiveSize`, `IsZip64`, `IsEncrypted`, `CommentText`, `EntryCount` (ja existe) |
| TTarFile | `Format` (ustar/GNU/PAX detectado), `IsGnuLongNames`, `BlockSize` |
| TTarGzFile | `UncompressedSize`, `CompressionLevel` (do header gzip) |
| TGzipFile | `OriginalFileName`, `ModifiedTime`, `CompressionMethod` |
| TCabFile | `SetID`, `CabinetIndex`, `FolderCount`, `DataReserveSize` |
| TSevenZFile | `IsSolid`, `IsEncrypted`, `NumFolders`, `NumStreams` |
| TArjFile | `HostOS`, `ArjVersion`, `SecurityVersion` |
| TIsoFile | `VolumeID`, `SystemID`, `PublisherID`, `VolumeSetSize` |
| TLhaFile | `Method` (-lh0-...-lh7-), `OriginalSize`, `CompressedSize` |
| TRarFile | `IsRar5`, `IsMultiVolume`, `IsSolid`, `DictionarySize` |

### 3.2 Escopo documental — v4.2

| Documento esperado | Acao | Entrada | Saida | Criterio de aceite | Responsavel |
|---|---|---|---|---|---|
| `Documentation/Regras de Negocio/RN-Format-Detection.md` | Criar | SPEC v3 §3.2 (matriz formatos) + `src/Archive.Open.pas` | RN descrevendo logica de deteccao por magic bytes | Arquivo criado; cobre 10 formatos; criterios verificaveis por test case | Responsavel_RN |
| `Documentation/Regras de Negocio/RN-Compression-Methods.md` | Criar | SPEC v3 §3.x + `src/Commons.Compression.*` | RN descrevendo metodos por formato e defaults | Arquivo criado; tabela metodo x formato; referencias para P20-P29 | Responsavel_RN |
| `Documentation/Regras de Negocio/RN-Encryption-AES.md` | Criar | `src/Commons.Encryption.AES.pas` + SPEC v3 §13 (ZIP AES) | RN descrevendo politica de criptografia AES-256 | Arquivo criado; cobre ZIP (AES-256 WinZip-AE-2) e 7z; criterios de ativacao | Responsavel_RN |
| `Documentation/Regras de Negocio/RN-Streaming-Rules.md` | Criar | `src/ZipFile.Streaming.pas` + SPEC v3 §2 | RN descrevendo quando usar streaming vs. buffer | Arquivo criado; casos de uso com exemplos de codigo inline | Responsavel_RN |
| `Documentation/Regras de Negocio/RN-Naming-Conventions.md` | Criar | `.cursor/rules/backend-pascal-unit-naming_V1.6.0.mdc` | RN de naming canonica de units/classes/interfaces | Arquivo criado; cobrindo prefixos T/E/I/F, namespace, palette page | Responsavel_RN |
| `Documentation/README_V1.0.md` | Revisar | Estado pos-entrega dos 5 RNs | Hub com links para `Regras de Negocio/` populada | 5 links ativos; StatusCell `Regras de Negocio/` atualizado para `completo` | Responsavel_RN |

### 3.3 Dependencias

- v4.1 concluida (5-file split estavel) antes de popular properties nos novos ficheiros `<Module>.Types.pas`.
- RNs de v4.2 dependem de `Arquitetura/Modulos_V1.0.md` (criado em v4.1) para referencias cruzadas.

### 3.4 Criterio de pronto — v4.2

- [ ] P20-P29 todos entregues: cada formato com properties read-only populadas conforme tabela 3.1.
- [ ] DUnitX ampliado com ao menos 1 test por formato verificando property population pos-Open.
- [ ] 5 RNs criadas em `Documentation/Regras de Negocio/` com conteudo canonico.
- [ ] Hub ressincronizado; `Regras de Negocio/` com status `completo`.

---

## 4. Fase Media — v4.3: Event firing (~30h codigo)

**Horizonte:** 2-3 sprints
**Referencia SPEC:** itens P03+P04 em `Documentation/spec/zipfile-v3-multi-format-expansion.md §17`
**Objetivo operacional:**
- Implementar disparo efetivo de `OnEntryFound` e `OnExtract` nos 4 formatos read-only (TArjFile, TIsoFile, TLhaFile, TRarFile) que atualmente nao disparam esses eventos durante `Open`/`ReadAsBytes`.

### 4.1 Escopo de codigo (P03+P04)

| Formato | Evento | Ponto de disparo |
|---|---|---|
| TArjFile | OnEntryFound | Loop de parsing de entradas em `Open` |
| TArjFile | OnExtract | Chamada de `ReadAsBytes` / `GetEntryStream` |
| TIsoFile | OnEntryFound | Traversal de directory records ISO 9660 + Joliet |
| TIsoFile | OnExtract | `ReadAsBytes` de sector chain |
| TLhaFile | OnEntryFound | Header scan level 0/1/2 |
| TLhaFile | OnExtract | `ReadAsBytes` com decoder -lh0- / -lh4..7- |
| TRarFile | OnEntryFound | Block header parsing RAR5 |
| TRarFile | OnExtract | `ReadAsBytes` Store method |

### 4.2 Escopo documental — v4.3

| Documento esperado | Acao | Entrada | Saida | Criterio de aceite | Responsavel |
|---|---|---|---|---|---|
| `Documentation/Analise/ArjFile/Events_V1.0.md` | Criar | `src/ArjFile.pas` pos-split + OnEntryFound/OnExtract spec | Analise PASSO_A_PASSO do disparo de eventos em TArjFile | Arquivo criado; fluxo de codigo documentado; criterio de teste descrito | Responsavel_Analise |
| `Documentation/Analise/IsoFile/Events_V1.0.md` | Criar | `src/IsoFile.pas` pos-split | Analise equivalente para TIsoFile | Idem | Responsavel_Analise |
| `Documentation/Analise/LhaFile/Events_V1.0.md` | Criar | `src/LhaFile.pas` pos-split | Analise equivalente para TLhaFile | Idem | Responsavel_Analise |
| `Documentation/Analise/RarFile/Events_V1.0.md` | Criar | `src/RarFile.pas` pos-split | Analise equivalente para TRarFile | Idem | Responsavel_Analise |

### 4.3 Dependencias

- v4.1 concluida (fontes split) — eventos ficam em `<Module>.pas` e interfaces em `<Module>.Interfaces.pas`.
- `ZipfileORM.Events.pas` (facade de eventos) deve estar estavel desde v4.0.0.

### 4.4 Criterio de pronto — v4.3

- [ ] P03+P04 entregues para os 4 formatos read-only.
- [ ] DUnitX com tests de evento: handler registrado deve ser chamado com `EntryName` correto durante Open e Extract.
- [ ] 4 arquivos de Analise de eventos criados.

---

## 5. Fase Media — v4.4: Features comerciais (~25h codigo)

**Horizonte:** 2-3 sprints
**Referencia SPEC:** itens P40+P41 em `Documentation/spec/zipfile-v3-multi-format-expansion.md §17`
**Objetivo operacional:**
- Entregar encryption write e multi-volume write para TSevenZFile — os dois features de maior valor comercial ainda ausentes no modulo 7z.

### 5.1 Escopo de codigo (P40+P41)

**P40 — 7z encryption write:**
- Encrypcao AES-256 no container 7z durante `AppendStream`/`CreateFromFiles`.
- Integrar `Commons.Encryption.AES` no encoder `SevenZFile.pas`.
- Propriedade `Password: string` publicada e `EncryptHeaders: Boolean`.

**P41 — 7z multi-volume write:**
- Suporte a `VolumeSize: Int64` em TSevenZFile.
- Gerador de volumes `.7z.001`, `.7z.002`, ... na sequencia de escrita.

### 5.2 Escopo documental — v4.4

| Documento esperado | Acao | Entrada | Saida | Criterio de aceite | Responsavel |
|---|---|---|---|---|---|
| `Documentation/Analise/SevenZFile/Encryption_V1.0.md` | Criar | `src/SevenZFile.pas` + `src/Commons.Encryption.AES.pas` | Analise CHECKLIST + PASSO_A_PASSO para P40 | Arquivo criado; fluxo AES-256 em write documentado; criterio interop com 7-Zip externo descrito | Responsavel_Analise |
| `Documentation/Analise/SevenZFile/MultiVolume_V1.0.md` | Criar | `src/SevenZFile.pas` pos-P41 | Analise PASSO_A_PASSO para P41 | Arquivo criado; logica de particionamento de stream descrita | Responsavel_Analise |

### 5.3 Dependencias

- v4.1 concluida.
- `Commons.Encryption.AES` estavel (disponivel desde v3.12/v4.0.0).
- Fixture externa: 7-Zip 26.01 para validar volumes gerados.

### 5.4 Criterio de pronto — v4.4

- [ ] P40: `TSevenZFile` com `Password` + `EncryptHeaders` populados; arquivo gerado abre no 7-Zip externo com senha correta.
- [ ] P41: `VolumeSize` funcional; conjunto de volumes gerado e re-abrivel pelo proprio TSevenZFile.
- [ ] DUnitX com smoke de encryption e de multi-volume (roundtrip write→read).
- [ ] 2 arquivos de Analise criados para SevenZFile.

---

## 6. Fase Longa — v4.5: Documentation excellence (~25h documental)

**Horizonte:** 3-4 sprints (pode sobrepor v4.4)
**Referencia SPEC:** itens P70+P73 em `Documentation/spec/zipfile-v3-multi-format-expansion.md §17`
**Objetivo operacional:**
- Cobrir todos os publicos da API com XML doc-comments em Pascal (`///`).
- Gerar exemplos funcionais por componente em `example/`.

### 6.1 Escopo documental (P70+P73)

**P70 — XML doc-comments:**

Para cada unit publica (4 facade + 13 modulos format + 13 Commons = 30 units), adicionar bloco `///` em:
- Cada `type T*` e `I*`
- Cada metodo/propriedade `published` ou `public`
- Cada constante exportada

| Documento esperado | Acao | Entrada | Saida | Criterio de aceite | Responsavel |
|---|---|---|---|---|---|
| `Documentation/API/<Module>/README.md` (13 modulos) | Criar | `src/<Module>.pas` + `src/<Module>.Interfaces.pas` pos-split | README por modulo com visao geral, properties, metodos, eventos | 13 READMEs criados; cada um com secoes: Overview, Properties, Methods, Events, Examples | Responsavel_API |
| `Documentation/API/Commons/README.md` | Criar | `src/Commons.*` | README das 13 units Commons agrupadas | Arquivo criado; 13 units descritas com responsabilidade | Responsavel_API |
| `Documentation/API/ZipfileORM/README.md` | Criar | `src/ZipfileORM.*` (4 units facade) | README da facade publica | Arquivo criado; quick-start snippet incluido | Responsavel_API |

**P73 — Examples por componente:**

| Documento esperado | Acao | Entrada | Saida | Criterio de aceite | Responsavel |
|---|---|---|---|---|---|
| `Documentation/Analise/ZipFile/Examples_V1.0.md` | Criar | `example/` + `src/ZipFile.pas` | Exemplos comentados de read, write, fluent, AES, ZIP64 | Arquivo criado; minimo 5 exemplos com codigo comentado | Responsavel_Analise |
| `Documentation/Analise/<Module>/Examples_V1.0.md` (12 restantes) | Criar | `example/` + src pos-split | Exemplos por componente | Idem — minimo 3 exemplos por componente | Responsavel_Analise |

### 6.2 Dependencias

- v4.1 concluida (src split) — doc-comments vao nos ficheiros split definitivos.
- v4.2 concluida (property population) — doc-comments das properties read-only so fazem sentido depois de populadas.

### 6.3 Criterio de pronto — v4.5

- [ ] 100% dos publicos (type, method, property, const) nas 30 units com bloco `///` preenchido.
- [ ] 15 READMEs de API criados (13 modulos + Commons + ZipfileORM).
- [ ] 13 arquivos `Examples_V1.0.md` criados (1 por modulo format).
- [ ] Hub ressincronizado; `API/` e `Analise/` com status `completo`.

---

## 7. Fase Longa — v5.0: UnRAR encoder (major undertaking)

**Horizonte:** indefinido — sujeito a decisao de viabilidade
**Referencia SPEC:** item P60 em `Documentation/spec/zipfile-v3-multi-format-expansion.md §17`
**Objetivo operacional:**
- Avaliar viabilidade tecnica do encoder RAR e, se aprovada, entregar `TRarFile` com capacidade de escrita.

### 7.1 Estado atual do gap

| Aspecto | Estado |
|---|---|
| RAR READ (Store) | Entregue em v3.5 — `src/RarFile.pas` |
| UnRAR source SDK | `sdk/unrar/` (150 .cpp/.hpp) disponivel |
| UnRAR.dll | `dll/unrar_x86{,-64}/unrar.dll` disponivel como fallback |
| Encoder RAR | Sem spec publica do encoder; RARLAB nao publica algoritmo de escrita |
| Decisao de viabilidade | **PENDENTE** — stakeholder deve deliberar |

### 7.2 Pre-condicoes para iniciar v5.0

1. Decisao explicita do stakeholder sobre abordagem: (a) traduzir C++ UnRAR source para Pascal, (b) chamar UnRAR.dll via dynamic load, ou (c) gerar apenas RAR4 via algoritmo documentado reverse-engineered.
2. Estimativa de esforco validada: ~40-80h dependendo da abordagem escolhida (150 .cpp com C++ ABI stubs vs. DLL load vs. RAR4 subconjunto).
3. Fixture de validacao: ferramenta externa WinRAR/RAR para verificar archives gerados.

### 7.3 Escopo documental — v5.0

| Documento esperado | Acao | Entrada | Saida | Criterio de aceite | Responsavel |
|---|---|---|---|---|---|
| `Documentation/Analise/RarFile/EncoderFeasibility_V1.0.md` | Criar (ANTES de codificar) | `sdk/unrar/` + SPEC §14.3 + abordagens A/B/C | Analise de viabilidade com comparativo de abordagens | Arquivo criado; 3 abordagens avaliadas; recomendacao com esforco estimado; aguarda decisao humana | Responsavel_Analise |
| `Documentation/Analise/RarFile/Encoder_V1.0.md` | Criar (DEPOIS da decisao) | Abordagem escolhida + `src/RarFile.Encoder.pas` | Analise PASSO_A_PASSO do encoder implementado | Arquivo criado; fluxo de escrita documentado; criterio de interop com WinRAR descrito | Responsavel_Analise |

### 7.4 Criterio de pronto — v5.0

- [ ] `EncoderFeasibility_V1.0.md` entregue e aprovado pelo stakeholder antes de qualquer codificacao.
- [ ] Abordagem escolhida pelo stakeholder documentada em `Documentation/Analise/RarFile/EncoderFeasibility_V1.0.md`.
- [ ] `TRarFile` com metodo `CreateFromFiles` funcional (abordagem aprovada).
- [ ] Roundtrip write→read verificado contra WinRAR externo.
- [ ] `Encoder_V1.0.md` criado.

---

## 8. Backlog de documentacao — visao consolidada

| # | Documento esperado | Status atual | Acao | Fase | Responsavel | Criterio de aceite |
|---|---|---|---|---|---|---|
| 1 | `Documentation/Arquitetura/Modulos_V1.0.md` | Ausente (referenciado no Overview) | Criar | v4.1 | Responsavel_Arquitetura | Arquivo criado; 13 modulos descritos; hub atualizado |
| 2 | `Documentation/Arquitetura/Commons_V1.0.md` | Ausente (referenciado no Overview) | Criar | v4.1 | Responsavel_Arquitetura | Arquivo criado; 13 units Commons descritas; hub atualizado |
| 3 | `Documentation/Arquitetura/Camadas_V1.0.md` | Ausente (referenciado no Overview) | Criar | v4.1 | Responsavel_Arquitetura | Arquivo criado; 4 camadas descritas; hub atualizado |
| 4 | `Documentation/Regras de Negocio/RN-Format-Detection.md` | Ausente (esqueleto vazio) | Criar | v4.2 | Responsavel_RN | RN com logica de deteccao por magic; 10 formatos cobertos |
| 5 | `Documentation/Regras de Negocio/RN-Compression-Methods.md` | Ausente (esqueleto vazio) | Criar | v4.2 | Responsavel_RN | RN com tabela metodo x formato; referencias P20-P29 |
| 6 | `Documentation/Regras de Negocio/RN-Encryption-AES.md` | Ausente (esqueleto vazio) | Criar | v4.2 | Responsavel_RN | RN cobrindo ZIP AES-256 + 7z; criterios de ativacao |
| 7 | `Documentation/Regras de Negocio/RN-Streaming-Rules.md` | Ausente (esqueleto vazio) | Criar | v4.2 | Responsavel_RN | RN com casos de uso streaming vs. buffer |
| 8 | `Documentation/Regras de Negocio/RN-Naming-Conventions.md` | Ausente (esqueleto vazio) | Criar | v4.2 | Responsavel_RN | RN de naming canonico de units/classes |
| 9 | `Documentation/Analise/ArjFile/Events_V1.0.md` | Ausente | Criar | v4.3 | Responsavel_Analise | Analise de disparo de eventos em TArjFile |
| 10 | `Documentation/Analise/IsoFile/Events_V1.0.md` | Ausente | Criar | v4.3 | Responsavel_Analise | Idem TIsoFile |
| 11 | `Documentation/Analise/LhaFile/Events_V1.0.md` | Ausente | Criar | v4.3 | Responsavel_Analise | Idem TLhaFile |
| 12 | `Documentation/Analise/RarFile/Events_V1.0.md` | Ausente | Criar | v4.3 | Responsavel_Analise | Idem TRarFile |
| 13 | `Documentation/Analise/SevenZFile/Encryption_V1.0.md` | Ausente | Criar | v4.4 | Responsavel_Analise | Analise P40 — AES-256 write em 7z |
| 14 | `Documentation/Analise/SevenZFile/MultiVolume_V1.0.md` | Ausente | Criar | v4.4 | Responsavel_Analise | Analise P41 — multi-volume write em 7z |
| 15 | `Documentation/API/<Module>/README.md` (13 modulos) | Ausente (13 pastas vazias) | Criar | v4.5 | Responsavel_API | 13 READMEs com Overview/Properties/Methods/Events/Examples |
| 16 | `Documentation/API/Commons/README.md` | Ausente | Criar | v4.5 | Responsavel_API | 13 units Commons descritas |
| 17 | `Documentation/API/ZipfileORM/README.md` | Ausente | Criar | v4.5 | Responsavel_API | Facade descrita com quick-start snippet |
| 18 | `Documentation/Analise/<Module>/Examples_V1.0.md` (13 modulos) | Ausente | Criar | v4.5 | Responsavel_Analise | Minimo 3 exemplos por modulo; 5 para ZipFile |
| 19 | `Documentation/Analise/RarFile/EncoderFeasibility_V1.0.md` | Ausente | Criar | v5.0 | Responsavel_Analise | 3 abordagens avaliadas; aprovado por stakeholder |
| 20 | `Documentation/Analise/RarFile/Encoder_V1.0.md` | Ausente | Criar (pos-decisao) | v5.0 | Responsavel_Analise | Encoder implementado documentado |
| 21 | `Documentation/README_V1.0.md` | Completo | Revisar (ressincronizar) | Ao final de cada fase | Responsavel_Review | Sem links orfaos; StatusCell atualizado; nenhuma entrada duplicada |

---

## 9. Matriz prioridade x impacto x dependencia

| Item (backlog #) | Documento | Prioridade | Impacto | Dependencia |
|---|---|---|---|---|
| 1 | Arquitetura/Modulos | Alta | Alto | Baixa |
| 2 | Arquitetura/Commons | Alta | Alto | Baixa |
| 3 | Arquitetura/Camadas | Alta | Medio | Baixa |
| 4-8 | Regras de Negocio (5 RNs) | Alta | Alto | Media (v4.1 estavel) |
| 9-12 | Analise Events (4 formatos) | Media | Medio | Alta (v4.1 + codigo P03/P04) |
| 13-14 | Analise 7z Encryption + MultiVol | Media | Alto | Alta (v4.1 + codigo P40/P41) |
| 15-17 | API READMEs (15 arquivos) | Media | Alto | Alta (v4.1 + v4.2) |
| 18 | Examples por modulo (13) | Baixa | Alto | Alta (v4.1 + v4.2 + examples/ estavel) |
| 19 | RarFile EncoderFeasibility | Baixa | Alto | Baixa (analise pre-codigo) |
| 20 | RarFile Encoder doc | Baixa | Alto | Alta (v5.0 codigo concluido) |
| 21 | Hub ressincronizacao | Alta | Alto | Baixa (gatilho: conclusao de cada fase) |

**Regras de derivacao de prioridade:**

- Alta: desbloqueia leitura/navegabilidade do hub ou garante rastreabilidade de gaps imediatos.
- Media: expande cobertura por modulo mas nao bloqueia onboarding basico.
- Baixa: aprofundamentos, exemplos e decisoes sujeitas a aprovacao humana.

---

## 10. Rastreabilidade — Documento existente x Acao no roadmap

| Documento existente | Referenciado em | Acao que influencia ou lacuna que resolve |
|---|---|---|
| `Documentation/README_V1.0.md` | Hub central | Gatilho de ressincronizacao ao final de cada fase; links #1, #2, #3 criados em v4.1; links #4-8 em v4.2; links #15-18 em v4.5 |
| `Documentation/Arquitetura/Overview_V1.0.md` | v4.1 §2.2 | Referencia de entrada para criar Modulos_V1.0.md, Commons_V1.0.md, Camadas_V1.0.md — os 3 links orfaos do Overview viram itens #1, #2, #3 do backlog |
| `Documentation/Arquitetura/FLOWCHART_V1.0.md` | v4.1 §2.2 | Entrada para Camadas_V1.0.md (item #3) — diagrama de dependencias ja disponivel |
| `Documentation/Roadmap/Migracao_v3_to_v4.md` | Hub + este roadmap §1.1 | Guia de upgrade ja completo; nao requer acao; referenciado como contexto em v4.1 |
| `Documentation/spec/zipfile-v3-multi-format-expansion.md` | Todas as fases | Fonte primaria dos itens P03, P04, P20-P29, P40, P41, P60, P70, P73; preservada como legacy; nao editar |
| `Documentation/Analise/` (14 pastas vazias) | v4.3, v4.4, v4.5 | Lacuna identificada: 14 modulos sem nenhum .md — itens #9-14 + #18 do backlog preenchem progressivamente |
| `Documentation/API/` (13 pastas vazias + Commons) | v4.5 | Lacuna identificada: API completamente vazia — itens #15, #16, #17 do backlog |
| `Documentation/Regras de Negocio/` (vazia) | v4.2 | Lacuna identificada: 5 RNs planejadas no hub mas nao criadas — itens #4-8 do backlog |

---

## 11. Plano de revisao continua e atualizacao

### 11.1 Cadencia

| Gatilho | Acao | Responsavel |
|---|---|---|
| Conclusao de fase (v4.1/v4.2/etc.) | Ressincronizar hub `README_V1.0.md`; verificar links orfaos | Responsavel_Review |
| Novo arquivo .md criado em `Documentation/` | Adicionar entrada na tabela de Estrutura do hub | Responsavel_Review |
| Novo `src/*.pas` criado apos v4.1 | Verificar se modulo tem entrada em `API/<Module>/README.md`; se nao, adicionar ao backlog | Responsavel_Arquitetura |
| Bump de versao do produto (v4.x → v4.(x+1)) | Atualizar campo `date` e `internal_file_version` deste roadmap; registrar no hub | Responsavel_Review |
| Decisao de stakeholder sobre v5.0 UnRAR encoder | Atualizar item #19 de `Ausente` para `Em progresso`; criar item #20 | Responsavel_Analise |

### 11.2 Ciclo de feedback e edicao

1. Rascunho de documento novo — gerado por agent especializado.
2. Review estrutural — Responsavel_Review verifica secoes obrigatorias (frontmatter, criterio de aceite, rastreabilidade).
3. Review gramatical e idioma — Responsavel_Review.
4. Edicao final — ajustes menores.
5. Merge e ressincronizacao do hub.

### 11.3 Checklist pos-merge (por documento novo)

- [ ] Frontmatter YAML presente com `internal_file_version`, `generated_by`, `date`.
- [ ] Naming segue convencao `<Nome>_V<X.Y.Z>.md` (documentos versionados) ou `README.md` (indices).
- [ ] Link adicionado no hub `Documentation/README_V1.0.md`.
- [ ] Sem conteudo duplicado de arquivo ja existente e canonico.
- [ ] Encoding UTF-8 sem BOM; sem escapes `#NNN` em codigos de exemplo Pascal.
- [ ] Links internos ao documento validados (sem referencias a paths inexistentes).

---

## 12. Criterios de pronto consolidados por fase

| Fase | Criterio de pronto resumido |
|---|---|
| v4.1 | 5-file split para 13 modulos compilando (23/23 BPLs verde) + DUnitX PASS + 3 docs Arquitetura criados + hub ressincronizado |
| v4.2 | P20-P29 entregues + DUnitX com property tests + 5 RNs criadas + hub com Regras de Negocio completo |
| v4.3 | P03+P04 para 4 formatos read-only + DUnitX com event tests + 4 docs Analise/Events criados |
| v4.4 | P40+P41 para TSevenZFile + DUnitX com smoke roundtrip + 2 docs Analise/SevenZFile criados |
| v4.5 | 100% publicos com XML doc-comments + 15 API READMEs + 13 Examples .md + hub completo |
| v5.0 | EncoderFeasibility aprovado + encoder implementado + roundtrip verificado + 2 docs Analise/RarFile criados |

**Definicao transversal de "Pronto para fase":** todas as acoes do backlog daquela fase com status `Concluido` + hub ressincronizado sem links orfaos + ausencia de duplicacao residual (nenhum item "criar" aponta para path ja canonico existente no hub).

---

## Versionamento

| Versao | Data | Mudancas |
|---|---|---|
| V1.0.0 | 2026-05-28 | Versao inicial — gerada por documentation-agent-roadmap para v4.0.0 baseline |
