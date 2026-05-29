---
internal_file_version: 1.0.0
generated_by: session-report
date: 2026-05-28
type: project-report
---

# Relatório de Sessão — Migração ZipFileORM v3.12.2 → v4.0.0

**Data:** 2026-05-28
**Projeto origem (preservado):** `c:\Users\Public\Documents\Embarcadero\Studio\Outros\zipfile`
**Projeto destino:** `C:\Users\Public\Documents\Embarcadero\Studio\Outros\Gnostice\zipfile\ZipFileORM`
**Versão alvo:** v4.0.0
**Total de commits gerados:** 11 (do `5f3d6117` inicial ao `09cac43c` final)
**Plano executado:** `D:\Users\claiton.linhares\.claude\plans\vectorized-churning-hartmanis.md`

---

## 1. Resumo Executivo

ZipFileORM v3.12.2 cresceu organicamente para 10 formatos com 35+ units em `src/` flat, naming inconsistente (`zipfile.pas` minúsculo, `tiCompress.pas` legacy MCL, etc.). Esta sessão refatorou o projeto inteiro para a v4.0.0 seguindo as policies de `.cursor/rules/backend-pascal-unit-naming_V1.6.0`, criou uma facade pública unificada (`ZipFileORM.*`), promoveu utilitários cross-format para `Commons.*`, validou builds em 7 versões Delphi × 2 plataformas, e implementou auto-registro de Library Paths no IDE via design-time BPL com discovery 100% runtime.

**Status final:**
- ✅ **23/23 packages OK** em D24..D37 W32+W64
- ✅ **21/21 testes** compilam em D29 W32 (DUnitX + 20 smokes)
- ✅ **22/22 smoke FPC OK** (Win32 + Win64 + Linux i386 + Linux x86_64)
- ✅ **90 ficheiros de Documentação** em 8 áreas estruturadas
- ✅ **Self-installing Library Paths** via design-time BPL initialization
- ✅ **Lazarus package (.lpk) + wrapper + tools FPC** completos
- ⏳ **Deferred:** split em 5 ficheiros por módulo (~25h) para v4.1

---

## 2. Contexto Inicial

### Pedido do usuário

> "@C:\Users\Public\Documents\Embarcadero\Studio\Outros\Gnostice\zipfile\ZipFileORM
> migração destes projeto para essa pasta fazendo a refatoração seguindo as Skills/rules/agents do .cursor e .workspace
> [...] proponha uma organização [...] faça um plano e já abra em mode plan para aprovação"

### Estado inicial detectado

- **Origem:** projeto v3.12.2 em `c:\...\Outros\zipfile\` com 39 ficheiros `.pas` em `src/` flat
- **Destino:** pasta `Gnostice\zipfile\ZipFileORM\` apenas com `.git/` e `LICENSE`
- **Convenções aplicáveis:** rules pack 1.6.5 (`.cursor/rules/`) + ProvidersORM como referência arquitetural (`E:\CSL\ProvidersORM\src\{Commons,Main,Modulos}\`)

### Decisões iniciais (4 questões respondidas pelo usuário)

| Pergunta | Resposta |
|---|---|
| Modo de migração | Refatorar para nova pasta, preservar origem intacta |
| Tratamento de legacy MCL (tiCompress*, dzlib) | Refatorar para namespace `Commons.Compression.*` |
| Papel do `ZipFileORM.pas` (facade) | Factory/registry central (`TArchive.OpenFile` → `IArchive`) |
| Layout de módulo | Inicialmente `src/Modulos/<Format>/` → revisado para **`src/` flat** |

### Refinamentos durante a planificação

Durante o desenho do plano, o usuário fez 3 correções importantes:

1. **"XXXXXXXX.Fluent.pas não será substituído pela XXXXXXXX.Interfaces.pas?"**
   → Fundidos: interfaces builder vão para `*.Interfaces.pas`, métodos fluent absorvidos na classe principal (conforme `backend-pascal-unit-naming_V1.6.0 §2`).

2. **"se são sub-modulos? ou commons?"**
   → Classificação explícita:
   - `Commons.*` = algoritmo reutilizável entre 2+ formatos (AES, LZMA, Progress)
   - `<Format>File.<SubConcept>.pas` = exclusivo da spec do formato (ZIP64, UTF8, Streaming, GzipStream)

3. **"colocar a criação da documentação completa na pasta documentation e o documentation/analise"**
   → Adicionada Onda 7 (geração via agents documentation-*).

---

## 3. Plano Aprovado — 8 Ondas

| Onda | Tarefa | Estimativa | Status |
|---|---|---|---|
| 1 | Scaffold + 13 ficheiros Commons (6 legacy MCL refatorados + 3 esqueletos + 4 inc/types) | ~2h | ✅ |
| 2 | Copy+uses-rewrite de 13 módulos + renomes + promoção AES/LZMA/Progress para Commons | ~25h | ✅ (parte mecânica) |
| 3 | Facade `ZipFileORM.{pas,Interfaces,Compression,Events}` | ~3h | ✅ |
| 4 | 14 packages D24..D37 W32+W64 | ~4h | ✅ |
| 5 | Tests portados (DUnitX + smokes) | ~3h | ✅ |
| 6 | tools/CLAUDE.md/context.json/.wolf/ | ~3h | ✅ |
| 7 | Documentation/ completa via agents documentation-* | ~8h | ✅ (base) |
| 8 | Commits finais + tag v4.0.0 | ~1h | ✅ |
| **2.x** | Split em 5 ficheiros por módulo (Types/Consts/Exceptions/Interfaces) | **~25h** | ⏳ deferred |

**Total estimado:** 49h. **Total executado em sessão:** ~12 commits.

---

## 4. Execução das Ondas

### Onda 1 — Scaffold + Commons

Criada estrutura base e refatoradas 6 units legacy MCL:

| Origem | Destino |
|---|---|
| `tiCompress.pas` | `Commons.Compression.Base.pas` |
| `tiCompressNone.pas` | `Commons.Compression.None.pas` |
| `tiCompressZLib.pas` | `Commons.Compression.ZLib.pas` |
| `dzlib.pas` | `Commons.Compression.ZLib.Bridge.pas` |
| `tiConstants.pas` | `Commons.Compression.Consts.pas` |
| `tiDefines.inc` | `Commons.Compression.Defines.inc` |

Criados 4 esqueletos novos: `Commons.{Consts,Types,Exceptions}.pas` + `Commons.FPC.inc` (substitui `{$IFDEF FPC}{$mode delphi}{$H+}` repetitivo).

**Build gate:** Commons compila standalone em D29 Win32 (839 linhas).

### Onda 2 — Copy + Uses-Rewrite + Promoções

Copiados 13 módulos format com renames:
- `Bzip2.Bzip2Stream.pas` → `Bzip2.Stream.pas`
- `UUE.UUEStream.pas` → `UUE.Stream.pas`
- `Tar.GzipStream.pas` → `TarFile.GzipStream.pas`

**Promoções cross-format → Commons:**
- `ZipFile.Encryption.AES.pas` → `Commons.Encryption.AES.pas`
- `ZipFile.Compression.LZMA.pas` → `Commons.Compression.LZMA.pas`
- `ZipFile.Progress.pas` → `Commons.Progress.pas`

Razão: AES e LZMA são algoritmos genéricos reutilizáveis (LZMA já consumido por ZIP e 7Z). Progress é evento cross-format.

**Build gate:** todos os 13 módulos format compilam em D29 W32.

### Onda 3 — Facade `ZipFileORM.*`

Criados 4 ficheiros de facade pública:

| Ficheiro | Conteúdo |
|---|---|
| `ZipFileORM.pas` | `TArchive` factory class + `uses` agregado de todos os 10 módulos |
| `ZipFileORM.Interfaces.pas` | `IArchive`, `IArchiveEntry`, `IArchiveBuilder` |
| `ZipFileORM.Compression.pas` | `TCompressionMethod` enum global + helpers string↔enum |
| `ZipFileORM.Events.pas` | 15 `TArchive*Event` types (era `ZipFile.Events.pas`) |

**Build gate:** `ZipFileORM.pas` compila em D29 W32 puxando todo o grafo (13.151 linhas).

### Onda 4 — Packages

Gerados 14 packages (7 runtime + 7 design-time) a partir de templates D29:

| Template | Variantes geradas |
|---|---|
| `ZipFileORMD29.dpk` (runtime) | D24, D25, D26, D27, D28, D29, D37 |
| `dclZipFileORMD29.dpk` (design-time) | D24, D25, D26, D27, D28, D29, D37 |

Portado `tools/Build-AllDelphis.ps1` da origem.

**Build gate:** `23/23 OK` (7 Delphis × Win32+Win64 = 14 BPLs runtime + 9 BPLs design-time = 23 BPL outputs).

Posteriormente foram adicionados os `.dproj` (metadata IDE) e `.groupproj` (Project Group) para abertura no IDE.

### Onda 5 — Tests

Portados:
- DUnitX consolidada (`tests/ZipFileTestsD29.dpr`)
- 12 `ZipFile.Tests.*.pas`
- 20 smoke DPRs
- 7 smoke FPC `.pas`

Uses ajustados em massa para os novos namespaces (`ZipFile.Events` → `ZipFileORM.Events`, etc.).

**Build gate:** `21/21 OK` em D29 W32.

### Onda 6 — Meta-arquivos

- `CLAUDE.md` adaptado para nova estrutura
- `.workspace/context.json` criado com metadata (projectName, paths, plataformas)
- `.wolf/anatomy.md` regenerado (inventário completo)
- `.wolf/memory.md` com checkpoint da sessão

### Onda 7 — Documentation/

**90 ficheiros gerados em 8 áreas:**

| Área | Ficheiros | Origem |
|---|---|---|
| `Arquitetura/` | 5 (Overview, Modulos, Commons, Camadas, FLOWCHART) | manual + `documentation-agent-architecture` |
| `Analise/` | 57 (14 módulos × 4 docs: README_Modulo, CHECKLIST, PASSO_A_PASSO, O_QUE_FALTA + 1 hub) | `documentation-agent-class-writer` |
| `API/` | 15 (master README + 14 módulo READMEs) | manual (após agent worktree-isolated falhar) |
| `Regras de Negocio/` | 6 (5 RNs + hub) | manual (após agent worktree-isolated falhar) |
| `Roadmap/` | 2 (Roadmap, Migracao_v3_to_v4) | manual + `documentation-agent-roadmap` |
| `Backup/` | 1 (README) | manual |
| `Esboco de Telas/` | 1 (README N/A — biblioteca sem UI) | manual |
| `spec/` | 1 (preservado v3 SPEC) | herdado |

### Onda 8 — Commits finais

Commit `5f3d6117` ZipFileORM v4.0.0 - Migration from v3.12.2 + canonical refactor + tag local `v4.0.0`.

---

## 5. Iterações Pós-Migração (10 commits adicionais)

Após o commit inicial v4.0.0, o usuário identificou várias issues operacionais que foram resolvidas iterativamente:

### 5.1 — Adicionar `.groupproj` (commit `00325697`)

**Pedido:** "faltou o .groupproj"

**Solução:** Copiados 7 `.groupproj` + 14 `.dproj` da origem. Permitem abertura no IDE como Project Group.

### 5.2 — Renomear palette ZipCompress → ZipFileORM (commit `a5b5efed`)

**Pedido:** "Trocar o Nome de ZipCompress para ZipFileORM"

**Mudanças:**

| Local | Mudança |
|---|---|
| `packages/zipfileReg.pas` | `cPalettePage = 'ZipFileORM'` |
| `src/ZipFile.pas:412` | `RegisterComponents('ZipFileORM', ...)` |
| `packages/ZipCompress.SplashReg.pas` | renomeado → `ZipFileORM.SplashReg.pas` |
| Splash IOTA | `cProductName = 'ZipFileORM 4.0.0'`, `cSKU = 'ZIPFILEORM-4.0.0'` |
| 7 `dcl*.dpk` | `contains` aponta para nome novo |
| `.wolf/`, `Documentation/Arquitetura/`, `Roadmap/` | textos alinhados |

### 5.3 — Auto-install Library Paths via PowerShell (commit `8b0aab7b`)

**Pedido:** "coloque qua quando o package for instalado ser adicionado os library path no delphi{24..37}"

**Solução inicial (depois evoluiu):**

- `tools/Install-LibraryPaths.ps1` — adiciona paths em `HKCU\Software\Embarcadero\BDS\<bds>\Library\<Plat>\Search Path`
- `tools/Uninstall-LibraryPaths.ps1` — reversão
- `Build-AllDelphis.ps1 -InstallLibPaths` — flag para disparar após build

### 5.4 — Erro "module not found" (commit `83c23667`)

**Pedido:** captura de tela de erro do IDE D37 não encontrando `dclZipFileORMD37.bpl`

**Diagnóstico:** runtime BPL não está no PATH do IDE. Windows não resolve dependência da BPL design-time.

**Solução:**
- `tools/Install-Bpls.ps1` — copia BPLs (rt + dt inicialmente) para `%BDSCOMMONDIR%\Bpl\` (location padrão do IDE)
- `tools/Uninstall-Bpls.ps1` — reversão
- `Build-AllDelphis.ps1 -InstallBpls / -Install` — flags integradas

### 5.5 — Library Path Win64 ausente no dialog (commit `747a8204`)

**Pedido:** "library path windows 64 não foi"

**Diagnóstico:** o Delphi expõe 5 chaves de path por plataforma; eu populei só `Search Path`. A chave `LibraryPath` (que aparece no Tools→Options) ficou intocada.

**Solução:** os scripts agora populam 3 chaves:

| Chave de registro | Função | Aparece em |
|---|---|---|
| `Search Path` | Compilador (dcc32/dcc64) | Library path do dialog |
| `LibraryPath` | (chave legacy/secundária) | Outras tools |
| `Browsing Path` | Navegação | Find Declaration, Code Insight |

### 5.6 — IDE sobrescreveu Library Path (commit `606f3b18`)

**Pedido:** screenshot mostrando "Library path" do D37 SEM ZipFileORM apesar do registro ter sido populado

**Diagnóstico:** IDE estava aberto antes do script rodar. IDE cacheava valor antigo em memória. Ao clicar Save no dialog Library, o IDE escreveu o cache antigo de volta no registro, sobrescrevendo as alterações.

**Solução:** scripts Install/Uninstall agora **abortam** se detectarem `bds.exe` rodando:

```
ABORT: One or more Delphi IDE processes (bds.exe) are running:
  PID 4512 - ZipFileORMD37 - RAD Studio 13
Close all Delphi IDEs and re-run, OR pass -Force to bypass.
```

Bonus descoberto: mapeamento dialog ↔ registry:
- Dialog "Library path" → registry `Search Path`
- Dialog "Browsing path" → registry `Browsing Path`
- Chave `LibraryPath` → legacy, não usada pelo dialog

### 5.7 — Uninstall não limpou (commit `033b8eaf`)

**Pedido:** "quando foi feito o uninstall não limpou o library path"

**Diagnóstico:** Uninstall original usava match **exato** pelo path atual (`$PSScriptRoot/..`). Se o projeto foi instalado de outro local antes, esses paths viram órfãos no registro.

**Solução:** Match **flexível por default** via regex `(?i)[\\/]ZipFileORM[\\/]`:

- ✅ Pega clones em qualquer local
- ✅ Case-insensitive
- ✅ Aceita `\` ou `/` como separador
- ✅ Não pega falsos positivos (`ZipFileORMv5`, `MyZipFileORM`)
- Flag `-StrictPath` reverte ao comportamento exato

### 5.8 — Self-install no momento da instalação (commit `8b1d4af5`)

**Pedido:** "é para fazer na instalação" — não via script externo, mas **quando o package é instalado via IDE**

**Solução:** Nova unit `packages/ZipFileORM.LibraryPathReg.pas` embutida na DPL design-time. Seu `initialization` block roda automaticamente quando o IDE carrega a package (Component → Install Packages OU startup).

Fluxo:
```
1. IDE carrega dclZipFileORMD<xx>.bpl
2. Windows resolve dep -> ZipFileORMD<xx>.bpl
3. BPL design-time inicializa:
   a. ZipFileORM.SplashReg
   b. zipfileReg (palette registration)
   c. ZipFileORM.LibraryPathReg <- NOVO
      - Le IOTAServices.GetBaseRegistryKey
      - Mapeia VER<XXX> compile-time -> RAD<xx>
      - Adiciona paths em 3 keys × 2 plats
```

Versão inicial usava `ZipFileORM.ProjectRoot.inc` com constante hardcoded gerada pelo build script.

### 5.9 — Não pode ser hardcoded (commit `09cac43c`)

**Pedido:** "não pode ser hardcore, tem que ser em relação"

**Solução:** Discovery 100% runtime via `GetModuleFileName(HInstance)`:

```pascal
function DiscoverProjectRoot: string;
var P: string;
begin
  Result := '';
  P := GetThisBplPath;                   // GetModuleFileName(HInstance)
  if P = '' then Exit;
  P := TPath.GetDirectoryName(P);        // <root>\Lib\RAD<xx>\Win<plat>
  P := TPath.GetDirectoryName(P);        // <root>\Lib\RAD<xx>
  P := TPath.GetDirectoryName(P);        // <root>\Lib
  P := TPath.GetDirectoryName(P);        // <root>
  if DirectoryExists(P + '\src') then
    Result := P;                         // sentinel valida que e ZipFileORM
end;
```

**Removidos:**
- `packages/ZipFileORM.ProjectRoot.inc` (deletado)
- Geração no `Build-AllDelphis.ps1` (removida)

**Implicações:**
- BPL na nova localização (após `mv` do projeto) descobre o novo root sozinho — basta rebuild
- Design-time BPL **deve** ser instalado de `<root>\Lib\RAD<xx>\Win<plat>\` para o discovery funcionar
- `Install-Bpls.ps1` ajustado para copiar **apenas runtime BPL** para `%BDSCOMMONDIR%\Bpl\` (dt fica em `<root>\Lib\` para preservar discovery)

---

## 5.10 — FPC/Lazarus completo (Ondas 9-11)

Após o gap reportado pelo usuário ("faltou o FPC"), foi executado um pacote final cobrindo Lazarus/FPC:

### Onda 9 — Validação build FPC

| Item | Mudança |
|---|---|
| `packages/zipfilepkg.pas` | `uses` reescrito v3 → v4 (35 items: Commons.*, ZipFileORM.*, sub-módulos, helper streams) |
| `packages/ZipFileORMpkg.lpk` | **Criado** com 35 items + RequiredPkgs (LCL, FCL) + UnitOutputDirectory `..\Lib\FPC\$(TargetOS)` |
| `packages/ZipFileORM.LibraryPathReg.pas` | Envelopado em `{$IFNDEF FPC}` (usa ToolsAPI/Win.Registry — Delphi-only) |
| `src/Commons.Compression.ZLib.Bridge.pas:154,198` | `Integer(Pointer)` → `PtrUInt(Pointer)` (FPC64 pointer size mismatch + warning) |
| `src/SevenZFile.pas:1321,1428` | `CreateFromBytesLzma2` + `CreateFromFilesLzma2` envelopados em `{$IFDEF SEVENZ_AVAILABLE}` com fallback `raise` no FPC |
| `tools/Build-FPC-Smoke.ps1` | Ajustado: targets `smoke_linux.pas` Win32/Win64 agora recebem `-Fl<GccLibDir>` (igual aos CAB targets) |

**Build gate FPC:** `22/22 OK` (Win32, Win64, Linux x86_64, Linux i386, CAB, LZMA, ISO, LHA, ARJ, RAR).

### Onda 10 — Lazarus IDE integration

| Script | Função |
|---|---|
| `tools/Install-LibraryPaths-Lazarus.ps1` | Localiza `%APPDATA%\lazarus\environmentoptions.xml` (ou `~/.lazarus/`), faz backup, adiciona `<ZipFileORM>/<Paths>` com `<root>\src`, `<root>\Lib\FPC\win{32,64}`. Idempotente. Aborta se Lazarus IDE rodando. Instrui usuário a finalizar via `Package → Open Package File → ZipFileORMpkg.lpk`. |
| `tools/Uninstall-LibraryPaths-Lazarus.ps1` | Remove o node `<ZipFileORM>` preservando todo o resto. Backup automático. |
| `tools/Build-AllFPC.ps1` | Wrapper: roda `Build-FPC-Smoke.ps1` + opcional `-Install` que dispara `Install-LibraryPaths-Lazarus.ps1` após build verde. |

### Onda 11 — Documentação e meta-arquivos

- `CLAUDE.md` ganhou comandos FPC (`Build-AllFPC.ps1 -Install`, `Install-LibraryPaths-Lazarus.ps1`, etc.)
- `.wolf/memory.md` com checkpoint da sessão FPC
- Esta seção do REPORT consolida o trabalho

---

## 6. Decisões Arquiteturais Chave

### 6.1 `src/` flat (sem subpastas)

**Motivo:** simplicidade de search paths. Naming `<Module>.<Feature>[.<SubFeature>].pas` atua como pasta virtual. `.dpk` precisa apenas de `-U..\src` (1 path), zero ordering dependencies.

### 6.2 Facade pública `ZipFileORM.*`

Consumidor escreve `uses ZipFileORM;` e ganha acesso a tudo (10 módulos format + factory + contratos + eventos). Padrão Vcl.pas/FMX.pas.

### 6.3 Classificação Sub-módulo vs Commons

| Categoria | Critério | Exemplos |
|---|---|---|
| **Sub-módulo do formato** | Exclusivo da spec do formato | `ZipFile.ZIP64`, `ZipFile.UTF8`, `ZipFile.Streaming`, `TarFile.GzipStream` |
| **Commons (cross-format)** | Algoritmo reutilizável entre 2+ formatos | `Commons.Encryption.AES`, `Commons.Compression.LZMA`, `Commons.Progress` |

### 6.4 Fluent dissolvido em Interfaces

Conforme `backend-pascal-unit-naming_V1.6.0 §2`: `*.Interfaces.pas` contém interface principal + **builder interfaces** fluent. Os antigos `*.Fluent.pas` deixam de existir como units separadas. Métodos fluent inline ficam na classe principal retornando `Self` (encadeamento).

### 6.5 Library Path discovery 100% runtime

Sem `.inc` hardcoded, sem build-time path injection. O BPL design-time, ao ser carregado pelo IDE, descobre o root via `GetModuleFileName(HInstance)` + walk-up de 4 níveis + validação por sentinel (`<root>\src` deve existir).

**Benefícios:**
- Mover o projeto: rebuild + reinstalar → funciona sem editar nada
- Múltiplos clones simultâneos: cada um registra seu próprio path
- Zero dependência de arquivos de marker ou registry pre-set

---

## 7. Resultado Final

### 7.1 Inventário

```text
ZipFileORM/
├── .git/
├── .cursor/                    (1.6.5 rules pack — copiado da origem)
├── .wolf/                      (OpenWolf — anatomy/cerebrum/memory/buglog)
├── .workspace/                 (context.json + rules/)
├── CLAUDE.md
├── Documentation/              (90 ficheiros em 8 áreas)
│   ├── Arquitetura/             (5: Overview, Modulos, Commons, Camadas, FLOWCHART)
│   ├── Analise/                 (57: 14 módulos × 4 docs + hub)
│   ├── API/                     (15: master + 14 módulos)
│   ├── Regras de Negocio/       (6: 5 RNs + hub)
│   ├── Roadmap/                 (2: Roadmap, Migracao_v3_to_v4)
│   ├── Backup/                  (1: README)
│   ├── Esboco de Telas/         (1: README N/A)
│   └── spec/                    (1: v3 SPEC preservado)
├── src/                        (42 ficheiros: 39 .pas + 3 .inc)
│   ├── ZipFileORM.{pas,Interfaces,Compression,Events}.pas       (4)
│   ├── Commons.{Consts,Types,Exceptions,Progress}.pas           (4)
│   ├── Commons.Compression.{Base,None,ZLib,ZLib.Bridge,Consts,LZMA}.pas  (6)
│   ├── Commons.Encryption.AES.pas                               (1)
│   ├── Commons.{FPC,Compression.Defines}.inc                    (2)
│   ├── <10 módulos format + 4 sub-módulos format-only>          (14)
│   ├── <3 helper streams + 3 Fluent>                            (6)
│   └── Archive.Open.pas                                         (1)
├── packages/                   (44 ficheiros)
│   ├── 7 ZipFileORMD<xx>.{dpk,dproj} + Grp.groupproj
│   ├── 7 dclZipFileORMD<xx>.{dpk,dproj}
│   ├── ZipFileORMpkg.lpk (Lazarus)
│   ├── zipfileReg.pas + ZipFileORM.SplashReg.pas
│   ├── ZipFileORM.LibraryPathReg.pas                            (NOVO)
│   ├── ZipFileORM.{rc,dcr,bmp} + icons/
│   └── 14 .res files
├── tests/                      (~135 ficheiros — DUnitX + smokes)
├── tools/                      (18 PowerShell scripts)
│   ├── Build-AllDelphis.ps1 (com flags -InstallBpls, -InstallLibPaths, -Install)
│   ├── Install-LibraryPaths.ps1 + Uninstall-LibraryPaths.ps1
│   ├── Install-Bpls.ps1 + Uninstall-Bpls.ps1                    (NOVO)
│   └── ... (Build-*Objs, Make-*Fixture, etc.)
├── sdk/ + deps/ + dll/ + Library/   (vendored — copiados bit-a-bit)
├── example/ + Lib/             (Lib gitignored)
└── LICENSE
```

### 7.2 Métricas de qualidade

| Métrica | Valor |
|---|---|
| Ficheiros `.pas` em `src/` | 39 |
| Total linhas em facade `ZipFileORM.pas` compilada | 13.151 |
| Packages compilando (D24..D37 × W32+W64) | **23/23 OK** |
| Tests Delphi compilando (D29 W32) | **21/21 OK** |
| Documentos em Documentation/ | 90 |
| Path keys populados por Delphi (Win32 + Win64) | 3 × 2 = 6 |
| Total alvos registro | 7 Delphis × 6 keys = 42 |
| Commits da migração | 11 |

---

## 8. Histórico de Commits

```text
09cac43c LibraryPathReg: 100% runtime discovery, no hardcoded path
8b1d4af5 Self-installing Library Paths via design-time BPL initialization
033b8eaf Uninstall-LibraryPaths: flexible match captures moved/stale ZipFileORM paths
6ec95888 Uninstall-LibraryPaths: add IDE-running protection (symmetry with Install)
606f3b18 Install scripts: abort if IDE is running (avoid stale-cache overwrite)
747a8204 Install/Uninstall LibraryPaths: populate 3 path keys not just Search Path
83c23667 Auto-install BPLs to BDSCOMMONDIR to fix "module not found" error
8b0aab7b Auto-install Library Paths in Delphi IDE (D24..D37) on package build
00325697 Add .groupproj + .dproj files for IDE Project Group support
a5b5efed Rename palette page ZipCompress -> ZipFileORM
5f3d6117 ZipFileORM v4.0.0 - Migration from v3.12.2 + canonical refactor
131d1e64 Initial commit (já existia no destino)
```

**Tag:** `v4.0.0` (local, não pushed)

---

## 9. Fluxo Operacional Final

### 9.1 Build + Install completo

```powershell
cd C:\Users\Public\Documents\Embarcadero\Studio\Outros\Gnostice\zipfile\ZipFileORM

# Build + copia runtime BPLs + popula Library Paths via script (backup)
powershell -ExecutionPolicy Bypass -File tools/Build-AllDelphis.ps1 -Install
```

### 9.2 Install via IDE (self-registering)

1. **Feche TODOS os IDEs Delphi** (a unit LibraryPathReg precisa escrever sem o IDE sobrescrever)
2. Abra o Delphi alvo (D37, D29, etc.)
3. `Component → Install Packages → Add`
4. Selecione **da pasta do projeto** (não de BDSCOMMONDIR):
   ```
   <root>\Lib\RAD<xx>\Win32\dclZipFileORMD<xx>.bpl
   ```
5. Click OK
6. **Neste momento** a unit `ZipFileORM.LibraryPathReg`:
   - GetModuleFileName retorna `<root>\Lib\RAD<xx>\Win32\dcl...bpl`
   - Walk up 4 níveis descobre `<root>`
   - Valida `<root>\src` existe
   - Registra paths em 3 keys × Win32+Win64
7. Reabra o IDE para o dialog refletir as mudanças

### 9.3 Library Paths registrados

Por cada Delphi e plataforma:

```
HKCU\Software\Embarcadero\BDS\<bds>\Library\Win<32|64>\
  Search Path     +=  <root>\src ; <root>\Lib\RAD<xx>\Win<32|64>
  LibraryPath     +=  (idem)
  Browsing Path   +=  (idem)
```

### 9.4 Quick start consumidor

```pascal
uses
  ZipFileORM;        // Facade — re-exporta tudo

var
  Zip: TZipFile;
  Fmt: TArchiveFormat;
begin
  // Auto-detect
  Fmt := TArchive.DetectFormat('arquivo.bin');

  // Factory por formato
  Zip := TArchive.CreateZip(nil, 'archive.zip');
  try
    Zip.Open;
    WriteLn(Zip.ReadAsString('readme.txt'));
  finally
    Zip.Free;
  end;
end;
```

---

## 10. Lições Aprendidas

### 10.1 Sobre Delphi IDE / registry

- **`Search Path` vs `LibraryPath`** são chaves de registro diferentes. Dialog "Library path" lê/escreve em `Search Path`. `LibraryPath` é legacy/secundária.
- **IDE em memória cacheia** o valor. Modificar o registro com IDE aberto + user clicar Save = registro sobrescrito.
- **BDSCOMMONDIR\Bpl\** está no PATH do IDE. BPLs nele resolvem automaticamente.
- **GetModuleFileName(HInstance)** dentro de uma BPL retorna o caminho dessa BPL — base para discovery runtime.

### 10.2 Sobre rules de naming

- A policy `backend-pascal-unit-naming_V1.6.0 §2` é explícita: `.Interfaces.pas` contém interface + builder fluent. Faz sentido aplicar e dissolver os `*.Fluent.pas`.
- Promoção a `Commons.*` deve ter critério claro: **reuso real ou potencial entre 2+ formatos**. Não é "código bonito" — é arquitetura.

### 10.3 Sobre PowerShell + Pascal

- Em PowerShell 5.1 sem BOM, em-dashes (`—`) em string literals quebram o parser. Usar ASCII puro (`-`) ou salvar com BOM.
- `@($a + 'x', $b + 'y')` é parseado como 1 elemento (operator precedence). Usar `@(($a + 'x'), ($b + 'y'))`.

### 10.4 Sobre operações reversíveis

- Todo script que modifica registro/filesystem deve ter contraparte de uninstall.
- Match flexível (regex pattern) > match exato. Match exato falha para clones órfãos.
- Proteção pre-flight (detectar IDE rodando) economiza retrabalho.

---

## 11. Próximos Passos Recomendados

### 11.1 v4.1 — Splits profundos (deferred, ~25h)

Para cada um dos 13 módulos, criar split em 5 ficheiros:
- `<Module>.pas` (classe + fluent inline)
- `<Module>.Interfaces.pas` (interface + builder)
- `<Module>.Consts.pas`
- `<Module>.Types.pas`
- `<Module>.Exceptions.pas`

Guia disponível em `Documentation/Analise/<Module>/PASSO_A_PASSO.md`.

### 11.2 v4.2 — Property population (P20-P29 da v3 SPEC §17)

50h estimadas, baixo risco, alto valor visual (Object Inspector mais rico).

### 11.3 v4.3 — Event firing (P03+P04)

30h estimadas. `OnEntryFound` e `OnExtract` events ativos nos formatos read-only.

### 11.4 v4.5 — Documentation excellence

- Gerar 75 docs detalhados por classe via `documentation-agent-class-writer` (cada um com 7 seções)
- XML doc-comments em todos públicos
- Examples por componente

### 11.5 v5.0 — UnRAR encoder (major)

Tradução do unrar C++ source. Decisão de viabilidade pendente.

---

## 12. Pendências Conhecidas

1. ~~**FPC build não validado**~~ → **resolvido na Onda 9** (22/22 OK).
2. **DUnitX run não executado** — testes compilam (`21/21 OK`) mas não foi rodado o EXE para validar funcionalidade end-to-end.
3. **Push remoto não feito** — commits são apenas locais. `git push origin master --tags` pendente quando estiver confortável.
4. **`example/` não atualizado** — código de exemplo foi copiado da origem mas ainda usa `uses zipfile` (v3 naming). Update pendente.
5. **Lazarus `.lpk` não regenerado** — copiado da origem, pode precisar de paths refeitos.

---

## 13. Referências

- **Plano completo:** `D:\Users\claiton.linhares\.claude\plans\vectorized-churning-hartmanis.md`
- **Rules aplicáveis:** `.cursor/rules/backend-pascal-unit-naming_V1.6.0.mdc`, `.cursor/rules/artifact-placement-policy_V1.2.0.mdc`, `.cursor/rules/pascal-encoding-no-escapes_V1.0.0.mdc`
- **Skills usadas:** `documentation-agent-architecture`, `documentation-agent-rules`, `documentation-agent-roadmap`, `documentation-agent-class-scanner`, `documentation-agent-class-writer`
- **SPEC v3 (histórico):** `Documentation/spec/zipfile-v3-multi-format-expansion.md`
- **OpenWolf:** `.wolf/OPENWOLF.md`

---

## 14. Assinaturas

- **Modelo:** Claude Opus 4.7 (1M context)
- **Projeto:** ZipFileORM v4.0.0
- **Sessão:** 2026-05-28
- **Plano aprovado pelo:** usuário em mode plan
- **Hash final:** `09cac43c`

---

## 15. Sessão 2026-05-28/29 — Plano `structured-orbiting-fox`

> Continuação posterior à v4.0.0 inicial. Executou Waves 1+2+3a+3b + Wave 4 inicial
> do plano `D:\Users\claiton.linhares\.claude\plans\structured-orbiting-fox.md`.

### 15.1 Sumário de commits da sessão (15 commits)

```text
8895d013  feat(properties): wire P28 TarFile geometry + P54 Zip ArchiveComment  ← Wave 4 inicial
a02a4beb  fix: TZipFile.AppendStream now actually honors Compression := cmMaximal ← bug histórico
10f7be31  docs(headers): apply canonical 7-field template to 11 new split units
8e391092  refactor: split Arj/Iso/Lha/Rar Exceptions (Wave 3b uniformity)
d34234d1  refactor: split CabFile/SevenZFile/ZipFile into Types/Exceptions/Consts (Wave 3a)
c7cfdfea  wolf+tests: capture sdk/bzip2 limbo + fix Tests.Fluent uses clause
6f8d9929  refactor: dissolve *.Fluent.pas into <X>.Interfaces.pas + base unit (rule §2)
dd3a3300  docs: add project README and PKWARE APPNOTE reference
4d58853d  wolf: capture session learnings (encoding, gitignore, case-rename, IDE guard)
dacc2722  Fix double-encoded UTF-8 mojibake in 9 docs (Portuguese accents)
62f9fa3f  gitignore: allow vendored Library/**/*.o (Delphi Win64 + FPC link inputs)
5bea30b8  Add ignore files for Claude Code, Continue.dev and Cursor
eafdae68  Normalize facade namespace: ZipfileORM -> ZipFileORM
56c3366c  FPC/Lazarus support complete (Ondas 9-11)
4f36592a  chore(headers): fix mojibake, strip BOM, sync stale names in src/ + packages/
```

### 15.2 Architectural changes (per rule `backend-pascal-unit-naming_V1.6.0 §2`)

| Item | Antes | Depois |
|---|---|---|
| Builder pattern | 7 `<X>.Fluent.pas` standalone units | 7 builders movidos para `<X>[File].pas` + interfaces em `<X>[File].Interfaces.pas` companion |
| Exceptions | inline em cada `<X>.pas` | 7 companion `<X>File.Exceptions.pas` (Cab/SevenZ/Zip + Arj/Iso/Lha/Rar) |
| Types públicos | inline | 3 companion `<X>File.Types.pas` (Cab/SevenZ/Zip — 6 enums 7z + records) |
| Consts | inline | 1 companion `ZipFile.Consts.pas` (resourcestrings) |
| Headers | 35 estilo A minimal (preservados) | 18 novos arquivos com canonical 7-field template (`backend-pascal-source-header_V1.0.0`) |

### 15.3 Bug fixes da sessão

| ID | Local | Impacto |
|---|---|---|
| streaming-deflate | `TZipFile.AppendStream` | `Compression := cmMaximal` era ignorado (case statement comentada). Fix: factory dispatch + raw deflate helpers (Delphi `ZLib.TZCompressionStream` WindowBits=-15; FPC `zstream.TCompressionStream` ASkipHeader=True) + EOCDR cdoffset delta |
| mojibake | 9 docs | Round-trip reverse-encoding (UTF-8 → 1252 → bytes, safety check via UTF-8 strict decoder) |
| Library/**/*.o | `.gitignore` | 109 arquivos vendored faltavam; negação explícita `!Library/**/*.o` |
| facade naming | 4 src/ + 67 refs | `ZipfileORM` (lowercase f) → `ZipFileORM` (canonical) |

### 15.4 Wave 4 inicial (Property population)

Status de cada propriedade tratada nesta sessão:

| ID | Componente | Properties wired | Status |
|---|---|---|---|
| **P28** | TTarFile | FBlockSize=512, FBlockingFactor=20, FRecordSize=10240 (computed), FArchiveSize (Open/Close) | ✅ |
| **P20** parcial | TZipFile | FArchiveSize, FArchiveComment (read from EOCDR) | ✅ |
| **P54** | TZipFile | ArchiveComment write para EOCDR `ZIPfilecomment` field | ✅ |

Restam P21-P27, P29 (~45h), P40-P58 (~120h), Waves 5-7.

### 15.5 Métricas finais

| Métrica | v4.0.0 inicial | v4.1.0-WIP atual |
|---|---|---|
| `src/*.pas` arquivos | 40 | 58 (40 base + 18 companions) |
| Build matrix Delphi | 23/23 OK | 23/23 OK |
| FPC matrix | 4 smokes | **22/22 OK** |
| DUnitX tests | 21 (compile only) | **43/43 passed (functional)** |
| Companion files com canonical header | 0 | 18 (100%) |
| Audit P4 progress (base files retrofit) | 35 pending | 35 pending (per rule §11 incremental) |

### 15.6 Pendências restantes formais

| Wave | Item | Esforço estimado | Bloqueador |
|---|---|---|---|
| 4 | P21-P27/P29 property population | ~40h | scope de release |
| 4 | P40-P58 format-specific write features | ~120h | scope de release |
| 5 | P01-P12 event firing wiring | ~150h | scope de release |
| 6 | v4.5 Documentation excellence | ~20-40h | scope de release |
| 7 | v5.0 UnRAR encoder | meses | decisão community |
| Audit P4 | 35 base files header retrofit | incremental | per rule §11 (no-retroactive-sweep) |

---

## 16. Assinatura sessão 2

- **Modelo:** Claude Opus 4.7 (1M context)
- **Projeto:** ZipFileORM v4.1.0-WIP
- **Sessão:** 2026-05-28 → 2026-05-29
- **Plano aprovado:** `structured-orbiting-fox` em mode plan
- **Hash inicial:** `09cac43c` · **Hash final:** `8895d013` (ou subsequente desta consolidação)
