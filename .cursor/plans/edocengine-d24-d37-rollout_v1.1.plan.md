---
plan: edocengine-d24-d37-rollout
version: 1.1
component: eDocEngine
status: partial-complete
completedSets: [D27, D28, D29, D37]
pendingSets: [D24, D25, D26]
blocker: vendor-source-rtl-incompatibility
created: 2026-05-20
revised: 2026-05-20
executed: 2026-05-20
supersedes: edocengine-d24-d37-rollout_v1.0.plan.md
canonicalSourceSet: D29
canonicalMarketing: "12"
targetSets:
  - { suffix: D24, marketing: "10.1", bds: "18.0" }
  - { suffix: D25, marketing: "10.2", bds: "19.0" }
  - { suffix: D26, marketing: "10.3", bds: "20.0" }
  - { suffix: D27, marketing: "10.4", bds: "21.0" }
  - { suffix: D28, marketing: "11",   bds: "22.0" }
  - { suffix: D29, marketing: "12",   bds: "23.0" }
  - { suffix: D37, marketing: "13",   bds: "37.0" }
---

# Plano — eDocEngine: rollout multi-Delphi (D24..D37)

**Componente:** `eDocEngine/` (1º de 3 — DocumentStudio e PDFtoolkit VCL virão depois)
**Objetivo:** Materializar packages eDocEngine para Delphi 10.1 Berlin → 13 Florence, alinhados à *Unified packaging convention* documentada no CLAUDE.md.
**Fonte canônica (template):** set D29 atual em `eDocEngine/Source/` + `Shared3/Source/`.
**Restrição perene:** `Sample/` é read-only (enforced em [`.claude/settings.json`](../settings.json)). Todo trabalho ocorre em `eDocEngine/` + `Shared3/`.

---

## ⚠ Status de execução (2026-05-20) — PARTIAL COMPLETE

| Set | Delphi | Phase 1 (migração) | Phase 2 (geração) | Phase 3 (build Win32 / Win64) | Status |
| --- | --- | --- | --- | --- | --- |
| D24 | 10.1 Berlin | ✅ | ✅ (44 arquivos em `packages/`) | ❌ Win32 falha (13 erros) | **PENDENTE** |
| D25 | 10.2 Tokyo | ✅ | ✅ (44 arquivos) | ❌ Win32 falha (338 erros) | **PENDENTE** |
| D26 | 10.3 Rio | ✅ | ✅ (44 arquivos) | ❌ Win32 falha (350 erros) | **PENDENTE** |
| D27 | 10.4 Sydney | ✅ | ✅ | ✅ 7/7 Win32 / ⚠ 6/7 Win64 (designide Win32-only) | OK |
| D28 | 11 Alexandria | ✅ | ✅ | ✅ 7/7 Win32 / ⚠ 6/7 Win64 (designide Win32-only) | OK |
| D29 | 12 Athens (canonical) | ✅ | — (fonte) | ✅ 7/7 Win32 / ✅ 7/7 Win64 | OK |
| D37 | 13 Florence | ✅ | ✅ | ✅ 7/7 Win32 / ✅ 7/7 Win64 | OK |

**Resumo numérico**: 4 versões com build core completo (D27/D28/D29/D37) cobrindo Delphi 10.4 → 13. 3 versões pendentes (D24/D25/D26) para Delphi 10.1, 10.2, 10.3.

### Pendências de conclusão (D24/D25/D26)

**Bloqueio:** vendor source eDocEngine usa recursos RTL/type system **não disponíveis ou com assinaturas diferentes em Delphi 10.1/10.2/10.3**. Vendor Gnostice nunca testou nessas versões.

**Tipos de erro encontrados** (centenas por versão):

- `E2003: Undeclared identifier: 'Buf'/'BufLen'/'FormatSettings'/'SearchString'/'SelStart'/'Options'`
- `E2004: Identifier redeclared: 'Integer'`
- `E2008: Incompatible types`
- `E2010: Incompatible types: 'TFont' and 'TSize'`
- `E2015: Operator not applicable to this operand type`

**Para concluir D24/D25/D26 (escopo de trabalho estimado):**

1. **Analisar e patchar cada erro com diretiva `{$IF CompilerVersion}`** ou `{$IFDEF VERxxx}` — cada arquivo `.pas` afetado vai precisar de patches similares ao que foi feito em `gtCstSpdEng.pas` (issue #10/#11 do relatório).
2. **Lista de arquivos provavelmente afetados** (a confirmar):
   - `Shared3/Source/Rtl/gtUtils3.pas` (já mostrou warnings de WideChar em D29; provavelmente mais grave em D26-)
   - `eDocEngine/Source/gtCstSpdEng.pas` (já patchado para D27/D28 — pode precisar de mais)
   - `eDocEngine/Source/gtCstDocEng.pas`, `gtCstPDFEng.pas`, `gtCstSpdEng.pas` (core engines)
   - Outros conforme erros forem aparecendo
3. **Esforço estimado**: 4–8 horas por Delphi (D24 mais antigo provavelmente o mais difícil; D26 o mais próximo do D27 que já funciona).
4. **Decisão de produto**: Vale o effort? Delphi 10.1 (2016), 10.2 (2017), 10.3 (2018) estão fora do suporte oficial Embarcadero. Se nenhum cliente atual usa essas versões, **considerar descontinuar suporte** e remover esses sets do escopo.

**Como retomar:**

1. Reabrir este plano e relatório de issues [`.workspace/edocengine-multi-delphi-issues-report.md`](../../.workspace/edocengine-multi-delphi-issues-report.md)
2. Re-buildar D26 (mais próximo): `tools\Build-RADSet.ps1 -Suffix D26 -Marketing 10.3 -BdsFolder 20.0 -OnlyCore`
3. Para cada erro, aplicar patch no `.pas` correspondente com diretiva `{$IF CompilerVersion}` (preferência durável registrada na memory)
4. Repetir para D25 e D24
5. Documentar TODOS os patches em `Backup/eDocEngine-vendor-patches/` para auditoria

### Problemas encontrados durante a execução

14 problemas catalogados durante a execução, agrupados por fase. Cada item: sintoma + causa raiz + mitigação + lição.

---

#### Phase 0 — Pré-voo

##### #1 Plano assumiu `git init` automático; usuário rejeitou

**Sintoma:** A primeira tarefa da Fase 0.1 era `git init` para habilitar rollback granular. O usuário rejeitou: "não quero git, pule".

**Impacto:** `.git/` ficou criado (inerte) no workspace. Rollback granular indisponível — só temos snapshot zip (Fase 0.4) e backup file-level em `Backup/eDocEngine-D29-original/` (Fase 0.5).

**Mitigação:** Pulei tudo relacionado a git. Os 2 níveis de rollback (zip + file-level) cobrem cenários comuns.

**Lição para os próximos componentes:** **Não assumir** que o usuário quer git. A decisão deve ser **opt-in explícita** no Phase 0, não default.

---

##### #2 Defines `gtDefines.Inc`/`gtSharedDefines.inc` adicionados (VER340..VER380) quebraram compilação

**Sintoma:** Após adicionar blocos `{$IFDEF VER340}` … `{$IFDEF VER370}` (com `gtCF`, `gtBDS2006`, `gtDelphi2009Up`, etc.), o build do D29 começou a falhar em `gtUtils3.pas` com erros do tipo:

- `E2250: There is no overloaded version of 'CharInSet' that can be called with these arguments`
- `W1058: Implicit string cast with potential data loss from 'string' to 'ShortString'`
- `E2008: Incompatible types`

**Causa raiz:** O catch-all `{$IFNDEF gtCF}` do vendor define **apenas** `gtDelphi3Up..gtDelphi2010Up`. Quando eu setei `gtCF` para VER340+, o catch-all foi **desativado** e o code path muda. Especificamente, ativei `gtDelphiXEUp..gtDelphiXE8Up` que **não estavam** no catch-all — esses defines fazem o vendor source escolher caminhos que usam `SysUtils.CharInSet` que falha para `WideChar` em Delphi 12.

**Mitigação:** Removi os blocos VER340..VER380 e **mantive o catch-all original do vendor**. Delphi 10.4+ caem no `{$IFNDEF gtCF}` que define apenas o baseline.

**Lição:** **Nunca presuma** que adicionar defines novos é seguro. O vendor source pode ter assumido a ausência deles. **Validar com build antes de prosseguir.** Para versões ainda não suportadas explicitamente, deixar o catch-all rodar (não tente "preencher a lacuna" sem ver o efeito).

---

#### Phase 1 — Migração para `packages/`

##### #3 IDE do usuário tem 249 library paths → `error MSB6003 / "filename too long"`

**Sintoma:** Após criar `eDocEngine/packages/` e mover os 21 `.dproj` D29, o primeiro build falhou com:

```text
warning MSB6002: The command-line for the "DCC" task is too long. Command-lines longer than 32000 characters are likely to fail.
error MSB6003: The specified task executable "dcc" could not be run. O nome do arquivo ou a extensão é muito grande
```

**Causa raiz:** O IDE Delphi 12 do usuário tem instalado **249 library paths globais** em `EnvOptions.proj` (Skia4Delphi, KonopkaControls, jcl, Abbrevia, ICS, TeeBI, Python4Delphi, AsyncPro, BluetoothFramework, DOSCommand, IconFontsImageList, LockBox, VirtualTreeView, Delphi4PythonExporter, etc.). O `CodeGear.Delphi.Targets` injeta esses paths em `$(DelphiLibraryPath)` que vai parar no `-U`, `-I`, `-R` do `dcc32`. Resultado: command-line passa de 32K → CreateProcess Windows API rejeita.

**Mitigação:** Adicionei `/p:DelphiLibraryPath="<bds>\lib\<plat>\release"` em TODA invocação `msbuild` (limitando a paths do BDS core). O script `Build-RADSet.ps1` faz isso automaticamente.

**Lição:** Em ambientes de desenvolvedor real, **sempre** assumir que o IDE tem libraries demais. O workaround `/p:DelphiLibraryPath=` é obrigatório, não opcional. Plano v1.1 marcava como R8 com mitigação errada (`LongPathsEnabled`); a real mitigação é truncar DelphiLibraryPath.

---

##### #4 `<PropertyGroup>` inserido depois do `<Import CodeGear.Delphi.Targets>` é ignorado

**Sintoma:** Meu `Migrate-D29ToPackages.ps1` inseriu o bloco de outputs (`<DCC_DcpOutput>`, `<DCC_UnitSearchPath>`) **antes** de `</Project>`. Build resultou em `error F1026: File not found: 'gtUtils3.pas'` — o `<DCC_UnitSearchPath>` aparentemente foi ignorado.

**Causa raiz:** `CodeGear.Delphi.Targets` (linhas 128-129 do arquivo) define `<UnitSearchPath>` em tempo de **import**:

```xml
<UnitSearchPath Condition="'$(DCC_UnitSearchPath)' != ''">$(DCC_UnitSearchPath);$(DelphiLibraryPath)</UnitSearchPath>
<UnitSearchPath Condition="'$(DCC_UnitSearchPath)' == ''">$(DelphiLibraryPath)</UnitSearchPath>
```

Esses PropertyGroups são avaliados **quando o Import é processado** — naquele momento, `$(DCC_UnitSearchPath)` ainda é vazio (porque meu Base_Win32-conditional PG vinha depois). Resultado: `<UnitSearchPath>` = `$(DelphiLibraryPath)` literal (sem meus paths customizados).

**Mitigação:** Patch para **mover o bloco PropertyGroup para antes do `<Import>`**. Implementado em script PowerShell separado pós-migração.

**Lição:** **Ordem importa** no MSBuild com Imports. Sempre inserir overrides ANTES do `<Import>` do Targets file, não depois. **Atualizar `Migrate-D29ToPackages.ps1`** para colocar o bloco na posição correta na primeira passada (atualmente ainda tem o bug original).

---

##### #5 `$(DCC_UnitSearchPath)` recursivo amplifica command-line para >32K

**Sintoma:** Mesmo após o fix #4, builds ainda davam "command-line too long" (variação).

**Causa raiz:** Meu PropertyGroup tinha `<DCC_UnitSearchPath>...meus paths...;$(DCC_UnitSearchPath)</DCC_UnitSearchPath>`. O `$(DCC_UnitSearchPath)` recursivo se expandia para o conteúdo herdado (massivo de EnvOptions.proj), inflando o command-line.

**Mitigação:** Removi a recursão `;$(DCC_UnitSearchPath)` — meu valor passa a SUBSTITUIR (não adicionar) ao herdado.

**Lição:** Em MSBuild, `;$(X)` no final de um valor que é o **próprio `X`** causa expansão que pode duplicar conteúdo herdado de cadeias `<Import>`. Sempre validar quanto isso vai expandir antes de aceitar.

---

##### #6 Build de packages dependentes recompila source dos `requires` (em vez de usar `.dcp`)

**Sintoma:** Build do groupproj falhava em `gtFiltersD29` com `error F1026: File not found: 'gtDZLIB3.pas'`. O `gtDZLIB3.pas` está em `Shared3/Source/Compression/`, **não** em `Shared3/Source/Filters/`.

**Causa raiz:** `dcc32 -B` (Build All) recompila TODOS os requires, não apenas link com .dcp. Mesmo que `gtCompressionD29.dcp` exista em `Lib/RAD12/win32/dcp/`, o `-B` força reler a fonte. Meu `<DCC_UnitSearchPath>` do gtFiltersD29 só tinha `..\..\Shared3\Source\Filters` — não conseguia achar `gtDZLIB3.pas` em `Compression/`.

**Mitigação:** Mudei o script para fazer `<DCC_UnitSearchPath>` **comprehensive**: TODOS os 5 Shared3 paths + TODOS os 14 adapter paths + `Lib/RAD<MM>/win{32,64}/dcp`. Cada .dproj agora tem o mesmo UnitSearchPath gigante (~600 chars).

**Lição:** **`-B` em groupproj é o default da Delphi**. Não dá pra confiar em `.dcp` cache. Cada .dproj precisa ver TODAS as fontes que pode precisar via `<DCC_UnitSearchPath>`. Estratégia "include-all" é robusta mesmo que verbose.

---

##### #7 Closure de scriptblock PowerShell não capturou variável corretamente

**Sintoma:** Meu primeiro patch dos `<DCC_UnitSearchPath>` em 21 `.dproj` escreveu o mesmo valor (`win64\dcp`) em ambos Win32 e Win64 PropertyGroups — quando deveria ser `win32\dcp` no Win32 PG e `win64\dcp` no Win64 PG.

**Causa raiz:** PowerShell `[regex]::Replace($c, $pattern, { param($m) "...$unitPathWin32..." })` — a scriptblock NÃO capturou `$unitPathWin32` da scope pai. Sem closure adequado, a variável dentro do scriptblock referenciou algo errado (ambos viraram `$unitPathWin64`).

**Mitigação:** Reescrevi usando template string substitutiva sem scriptblocks.

**Lição:** PowerShell 5.1 + `[regex]::Replace($c, $pattern, $scriptblock)` é **uma armadilha** de closures. Não usar scriptblock com variável externa — sempre passar via string substitution ou pre-compute.

---

##### #8 Bug no `Migrate-D29ToPackages.ps1`: `<Projects Include>` no groupproj duplicou `gtDocEngD29` e omitiu `DCLgtDocEngD29`

**Sintoma:** Build via core groupproj só compilou 6/7 BPLs — faltou `DCLgtDocEngD29.bpl`. Investigando o .groupproj, o `<ItemGroup>` tinha `<Projects Include=".\gtDocEngD29.dproj">` repetido 2x e nenhuma menção a `DCLgtDocEngD29.dproj`.

**Causa raiz:** Meu Patch-Groupproj fazia replace em `<Projects Include="..\..\Shared3\Source\...">` mas não tratava o caso de paths como `..\Source\<file>.dproj`. O `DCLgtDocEngD29.dproj` originalmente estava listado como `..\Source\DCLgtDocEngD29.dproj` e meu regex falhou em distinguir.

**Mitigação:** Patch manual do .groupproj posterior. **O bug original ainda está no script** `Migrate-D29ToPackages.ps1` — re-executar quebraria de novo.

**Lição:** **Patch generators que processam paths relativos** precisam considerar TODAS as profundidades de path possíveis no source. Testar com .groupproj completo, não amostras.

---

#### Phase 2 — Geração D24..D28+D37

##### #9 `ProjectVersion` na tabela do plano não corresponde à realidade

**Sintoma:** O plano dizia "ProjectVersion = BDS folder major" — `D29 → 23.0`. Mas o vendor D29 original tinha `<ProjectVersion>20.3</ProjectVersion>`.

**Causa raiz:** A regra "ProjectVersion = BDS major" foi uma suposição não validada empiricamente. O Embarcadero usa um valor interno do formato `.dproj` (ex: 20.3 para Delphi 12) que evolui com cada update do IDE, **não** alinhado com a pasta BDS.

**Mitigação:** Generate-DXXSet.ps1 ainda usa BDS major como ProjectVersion (`18.0` para D24, `22.0` para D28, etc.). Empiricamente funcionou para D37 (Delphi 13 → PV=37.0) — mas é incerto se Delphi 10.1 aceitaria PV=18.0 sem migrar. **D29 ficou com PV=20.3 original** (mais conservador).

**Lição:** **Sempre validar ProjectVersion empiricamente** abrindo um projeto vazio no IDE alvo. Plano v1.1 mencionava isso como passo opcional — deveria ser obrigatório antes da geração.

---

#### Phase 3 — Build por Delphi

##### #10 Vendor source NÃO é portável de Delphi 12 para Delphi 10.4/11 sem patches

**Sintoma:** Build D27 (Delphi 10.4 Sydney) e D28 (Delphi 11 Alexandria) falham com erros idênticos em `gtCstSpdEng.pas` linhas 1897, 2189, 2191, 2192, 2194, 2199, 2206, 2209:

```text
error E2018: Record, object or class type required
error E2003: Undeclared identifier: 'Index'
error E2070: Unknown directive: 'TgtColumnInfoList'
```

**Causa raiz:** **Embarcadero mudou `TList.Items` de `Integer` para `NativeInt` no Delphi 12 (BDS 23.0)**:

| BDS | Delphi | `TList.Items[Index: ...]` |
| --- | --- | --- |
| 21.0 | 10.4 Sydney | `Integer` |
| 22.0 | 11 Alexandria | `Integer` |
| **23.0** | **12 Athens** | **`NativeInt`** ⟵ MUDOU |
| 37.0 | 13 Florence | `NativeInt` |

O vendor declara `TgtColumnInfoList.Items[Index: NativeInt]` (em `gtCstSpdEng.pas` linha 154). Em **Delphi 12+**: assinatura idêntica ao parent → override correto → `FPrevColumnsInfo.Items[i]` resolve para `TgtColumnInfo`. Em **Delphi 10.4/11**: parent é `Integer`, descendant é `NativeInt` → assinaturas diferentes, override NÃO acontece → `FPrevColumnsInfo.Items[i]` resolve para `TList.Items` (Pointer) → `.ColumnNum` falha com E2018.

**Mitigação:** Patch no vendor source `gtCstSpdEng.pas`:

```pascal
function GetItem(Index: {$IF CompilerVersion >= 36.0}NativeInt{$ELSE}Integer{$IFEND}): TgtColumnInfo;
property Items[Index: {$IF CompilerVersion >= 36.0}NativeInt{$ELSE}Integer{$IFEND}]: TgtColumnInfo read GetItem; default;
```

Em ambas declarações + implementação, escolher tipo correto por `CompilerVersion`.

**Lição:** **O vendor não testou seu source em Delphi <12**. Provavelmente Gnostice deixou de suportar Delphi pre-12 antes de Embarcadero ter feito essa mudança em `TList`. Para rollout multi-Delphi, **patches no vendor source são inevitáveis**. Documentar TODOS os patches aplicados.

---

##### #11 Há mais bugs Delphi-<12 escondidos no vendor source

**Sintoma:** Após patch #10, D27/D28 funcionaram. Mas D24/D25/D26 continuam falhando com erros DIFERENTES (não mais E2018 no gtCstSpdEng.pas — outros tipos de erro em outros arquivos).

**Causa raiz confirmada:** Vendor source provavelmente tem outras incompatibilidades similares em outros arquivos — qualquer lugar que use:

- Métodos virtuais cuja assinatura mudou entre Delphi 11 e 12 (como TList.Items #10)
- Records com helpers
- Generics avançados
- `inline var` (recurso novo Delphi 12)
- Pattern matching (recurso novo Delphi 12)
- Atributos `[unsafe]`, `[weak]` etc.
- RTL API que mudou (CharInSet, FormatSettings, TFont/TSize etc.)

**Mitigação:** Aceitar iteratividade — cada erro precisa patch individual com `{$IF CompilerVersion}`. Para D24/D25/D26 isso significa CENTENAS de patches (ver #14).

**Lição:** **Não confiar que UM patch resolve TODA a incompatibilidade.** Plano deveria ter uma fase "patch vendor source" iterativa: build → identificar erro → patch → build novamente, até passar.

---

##### #12 `Win64x` (Delphi 12+) vs `Win64` (Delphi <=11) — platform name change

**Sintoma:** Build D28 (Delphi 11) Win64x falhou com:

```text
error : Invalid PLATFORM variable "Win64x". PLATFORM must be one of the following:
"Win32", "Win64", "AndroidArm32", "AndroidArm64", ...
```

**Causa raiz:** Embarcadero introduziu o platform `Win64x` (MS toolchain x64) **em Delphi 12** (BDS 23.0). Delphi 10.x e 11 só conhecem `Win64`. O .dproj gerado a partir do template D29 (Delphi 12) tem todas as conditions baseadas em `Win64x`, quebrando em Delphis anteriores.

**Mitigação:** Após `Generate-DXXSet.ps1`, aplicar substituição **string-level** `Win64x` → `Win64` em todos `.dproj` dos sets D24-D28. Em `Build-RADSet.ps1`, passar `/p:Platform=Win64` (não `Win64x`) para esses Delphis.

**Lição:** **Phase 2 (Generate) não pode fazer apenas substituição RAD/Suffix/PV** — também precisa lidar com **platform identifier changes** entre Delphi versions. Adicionar isso ao Generate-DXXSet.ps1 quando re-gerar D24-D28: condicionalmente substituir Win64x→Win64 para targets BDS<23.

---

##### #13 `designide` package só existe Win32 em Delphi <=11

**Sintoma:** Build D28 Win64 falhou em DCLgtDocEngD28 (design-time) com:

```text
DCLgtDocEngD28.dpk(34): error E2202: Required package 'designide' not found
```

**Causa raiz:** Em Delphi 11 e anteriores, o pacote `designide` (do próprio IDE Delphi) **só existe em Win32** — porque o IDE Delphi nessa época era 32-bit only. Em Delphi 12+, Embarcadero passou a fornecer `designide` também para Win64x.

Como `DCLgtDocEng<XX>.dpk` `requires designide`, ele **não pode** ser compilado para Win64 em Delphi <=11.

**Mitigação:** Aceitar como limitação. Para D27/D28: Win32 7/7, Win64 6/7 (design-time é Win32-only). Documentar essa expectativa no critério de saída.

**Lição:** O critério "7/7 BPLs em ambas plataformas" do plano v1.1 era irrealista para Delphi <=11. Para essas versões, o critério correto é "6 runtime BPLs em Win64 + 7 BPLs em Win32 (incluindo design-time)".

---

##### #14 D24/D25/D26 (Delphi 10.1, 10.2, 10.3) têm múltiplas incompatibilidades RTL

**Sintoma:** Build D26 Win32: 350 erros. D25: 338 erros. D24: 13 erros (parou de compilar mais cedo).

Erros incluem:

- `E2003: Undeclared identifier: 'Buf'/'BufLen'/'FormatSettings'/'SearchString'/'SelStart'/'Options'`
- `E2004: Identifier redeclared: 'Integer'`
- `E2008: Incompatible types`
- `E2010: Incompatible types: 'TFont' and 'TSize'`
- `E2015: Operator not applicable to this operand type`

**Causa raiz:** Vendor source usa recursos RTL/type system que **não estavam disponíveis** ou tinham assinaturas diferentes em Delphi 10.1/10.2/10.3. Cada 10.x tem seu próprio conjunto de breaking changes ao longo do tempo. O vendor Gnostice provavelmente nunca testou em Delphi <10.4.

**Mitigação:** **Fora de escopo desta sessão.** Cada erro precisa de patch individual com `{$IF CompilerVersion}` — potencialmente dezenas de patches por Delphi. **Status: D24/D25/D26 documentados como PENDENTES** no início deste plano.

**Lição:** **Plano v1.1 superestimava o escopo** ao incluir D24-D26. Versões anteriores a Delphi 10.4 Sydney têm RTL muito diferente e exigem effort substancial (não apenas mecânica de packages). Para o próximo componente (DocumentStudio/PDFtoolkit), avaliar empiricamente o escopo antes de prometer "suporte total".

### Patches já aplicados ao vendor source (D27/D28 compat)

| Arquivo | Patch | Issue |
| --- | --- | --- |
| `eDocEngine/Source/gtCstSpdEng.pas` (3 locais) | `NativeInt` → `{$IF CompilerVersion >= 36.0}NativeInt{$ELSE}Integer{$IFEND}` | #10 — TList.Items mudou de Integer→NativeInt em Delphi 12 |
| `.dproj` Win64x → Win64 para D24-D28 | string-level substitution | #12 — Win64x é Delphi 12+ only |

### Suposições do plano que se revelaram falsas (8 itens)

| # | Suposição original | Realidade descoberta |
| --- | --- | --- |
| S1 | `ProjectVersion` = BDS major | Vendor usa `20.3` para D29 (não `23.0`) — valor interno do .dproj format |
| S2 | Migração `packages/` é puramente mecânica | Múltiplos bugs de regex, encoding, ordem MSBuild (issues #4–#7) |
| S3 | Adicionar `VER340..VER370` em `gtDefines.Inc` é seguro | Quebra build D29 (issue #2) |
| S4 | Vendor source compila em qualquer Delphi 10.1+ | Vendor só testou Delphi 12; quebra em 10.4/11 e mais ainda em 10.1-10.3 |
| S5 | `-B` (Build) só precisa de `.dcp` para deps | `-B` recompila source das deps; UnitSearchPath precisa de TUDO (issue #6) |
| S6 | IDE Delphi tem library path razoável | IDE real: 249 entries → 32K overflow (issue #3) |
| S7 | Closures PowerShell capturam variáveis externas | Em `[regex]::Replace` com scriptblock, NÃO captura (issue #7) |
| S8 | Win32+Win64 deve dar 7/7 BPLs em qualquer Delphi | Em Delphi <=11, design-time Win64 impossível (issue #13) |

### Convenção `packages/` finalizada (Opção 3 — só Delphi outputs)

Outputs em `eDocEngine/Lib/RAD<MM>/win{32,64}/`:

- ✅ `bpl/` (Delphi runtime BPL)
- ✅ `dcp/` (Delphi compiled package)
- ✅ `dcu/` (Delphi compiled units)
- ✅ `exe/` (executable, raro em packages)
- ❌ `bpi/`, `hpp/`, `obj/`, `lib/` — **removidos da convenção**. Vendor não usa C++Builder personality. Se precisar futuramente, habilitar via `<DCC_GenerateHppFiles>true</DCC_GenerateHppFiles>` + adicionar `<DCC_BpiOutput>` etc. de volta ao Migrate-D29ToPackages.ps1.

Detalhes completos em [`.workspace/edocengine-multi-delphi-issues-report.md`](../../.workspace/edocengine-multi-delphi-issues-report.md) (14 issues catalogados).

## Definition of Done global

Considerado concluído quando **todos** os itens abaixo estiverem satisfeitos:

1. **Consolidação `packages/`**: pasta `eDocEngine/packages/` existe e contém todos os `.dpk`/`.dproj`/`.groupproj` (flat, sem subpastas). `eDocEngine/Source/`, `eDocEngine/Source/<Adapter>/` e `Shared3/Source/<sub>/` contêm apenas código-fonte (`.pas`/`.res`/`.inc`/`.dfm`).
2. **7 sets `D<XX>`** (D24, D25, D26, D27, D28, D29, D37) materializados em `eDocEngine/packages/`, cada um com 21 pares `.dpk`/`.dproj` + 2 `.groupproj` = **147 `.dpk` + 147 `.dproj` + 14 `.groupproj` na pasta**.
3. **7 árvores `eDocEngine/Lib/RAD<MM>/win{32,64}/{dcp,dcu,bpl,exe}/`** populadas (build pode ser parcial — adapters cujo host não está instalado ficam ausentes, registrados nos build-reports).
4. **`tools/`** contém os 3 scripts versionados (`Migrate-D29ToPackages.ps1`, `Generate-DXXSet.ps1`, `Build-RADSet.ps1`) + `README.md` explicando uso e idempotência.
5. **Build do D29** atual no Delphi 12 funcional com novo layout `packages/` + `Lib/RAD12/` (Fase 1).
6. **Build de cada `D<XX>`** cujo IDE está instalado registrado em `.workspace/build-reports/eDocEngine-RAD<MM>.txt`.
7. **CLAUDE.md** tabela "Current state vs. target" atualizada: linha eDocEngine ✅ com lista de versões verificadas.
8. **Snapshot Fase 0.4** preservado em `.workspace/snapshots/` por no mínimo 30 dias após go-live.

## Inventário do set D29 (template)

**21 pacotes** por versão Delphi (5 Shared3 + 1 runtime eDocEngine + 1 design-time eDocEngine + 14 adapters) + **2 groupproj**.

⚠ **Estado atual:** os `.dpk`/`.dproj` do D29 estão espalhados por `eDocEngine/Source/`, `eDocEngine/Source/<Adapter>/` e `Shared3/Source/<sub>/`. **Estado-alvo após Fase 1**: todos consolidados em `eDocEngine/packages/` (flat, sem subpastas). A tabela abaixo lista o estado-atual (origem) — destino é sempre `eDocEngine/packages/<basename>.{dpk,dproj}`.

### Camada 1 — Shared3 (5 pacotes — origem em Shared3, destino em eDocEngine/packages/)

| Pacote | Origem atual | Source code (.pas) — permanece |
| --- | --- | --- |
| `gtRtlD29` | `Shared3/Source/Rtl/gtRtlD29.{dpk,dproj}` | `Shared3/Source/Rtl/` |
| `gtCompressionD29` | `Shared3/Source/Compression/gtCompressionD29.{dpk,dproj}` | `Shared3/Source/Compression/` |
| `gtFiltersD29` | `Shared3/Source/Filters/gtFiltersD29.{dpk,dproj}` | `Shared3/Source/Filters/` |
| `gtCryptD29` | `Shared3/Source/PDFCrypt/gtCryptD29.{dpk,dproj}` | `Shared3/Source/PDFCrypt/` |
| `gtFontD29` | `Shared3/Source/PDFFontProcessor/gtFontD29.{dpk,dproj}` | `Shared3/Source/PDFFontProcessor/` |

### Camada 2 — eDocEngine runtime + design-time (2 pacotes)

| Pacote | Origem atual | Source code — permanece |
| --- | --- | --- |
| `gtDocEngD29` (runtime) | `eDocEngine/Source/gtDocEngD29.{dpk,dproj}` | `eDocEngine/Source/` |
| `DCLgtDocEngD29` (design-time) | `eDocEngine/Source/DCLgtDocEngD29.{dpk,dproj}` | `eDocEngine/Source/` |

### Camada 3 — Adapters (14 pacotes)

| Host | Pacote | Origem atual | Source code — permanece |
| --- | --- | --- | --- |
| ReportBuilder | `DCLgtRBExpD29` | `eDocEngine/Source/RB/` | `eDocEngine/Source/RB/` |
| FastReport | `DCLgtFRExpD29` | `eDocEngine/Source/FR/` | `eDocEngine/Source/FR/` |
| QuickReport | `DCLgtQRExpD29` | `eDocEngine/Source/QR/` | `eDocEngine/Source/QR/` |
| RAVE Reports | `DCLgtRaveExpD29` | `eDocEngine/Source/Rave/` | `eDocEngine/Source/Rave/` |
| ACE Reporter | `DCLgtAceExpD29` | `eDocEngine/Source/Ace/` | `eDocEngine/Source/Ace/` |
| TRichView | `DCLgtRichVwExpD29` | `eDocEngine/Source/RichVw/` | `eDocEngine/Source/RichVw/` |
| TScaleRichView | `DCLgtScaleRichVwExpD29` | `eDocEngine/Source/ScaleRichVw/` | `eDocEngine/Source/ScaleRichVw/` |
| ThtmlViewer | `DCLgtHtmVwExpD29` | `eDocEngine/Source/HtmlView/` | `eDocEngine/Source/HtmlView/` |
| DevExpress XPress | `DCLgtXPressExpD29` | `eDocEngine/Source/DevExpress/` | `eDocEngine/Source/DevExpress/` |
| TMS AdvGrid | `DCLgtAdvGridExpD29` | `eDocEngine/Source/TMS/` | `eDocEngine/Source/TMS/` |
| opEDocExcel | `DCLopEDocExcelEngD29` | `eDocEngine/Source/opEDocExcelEng/` | `eDocEngine/Source/opEDocExcelEng/` |
| GMail Suite | `DCLgtGmSuiteExpD29` | `eDocEngine/Source/GmSuite/` | `eDocEngine/Source/GmSuite/` |
| Indy E-Mail | `DCLgtIndyAdapterD29` | `eDocEngine/Source/EmailAdapters/Indy/` | `eDocEngine/Source/EmailAdapters/Indy/` |
| Document Producer | `DCLgtDocProdD29` | `eDocEngine/Source/Producer/` | `eDocEngine/Source/Producer/` |

### Groupproj (2)

| Groupproj | Origem atual | Destino |
| --- | --- | --- |
| Core (5 Shared3 + 2 eDocEngine) | `eDocEngine/Source/DCLgtDocEngD29Grp.groupproj` | `eDocEngine/packages/DCLgtDocEngD29Grp.groupproj` |
| Adapters (14) | `eDocEngine/Source/DCLgtDocEngExportIntfD29Grp.groupproj` | `eDocEngine/packages/DCLgtDocEngExportIntfD29Grp.groupproj` |

### Layout-alvo após Fase 1

```text
eDocEngine/
├── Source/                                    # .pas/.res/.inc inalterados
│   ├── (gtCstDocEng.pas, gtPDFEng.pas, …)
│   ├── RB/   FR/   QR/   Rave/   Ace/         # adapters source
│   ├── RichVw/   ScaleRichVw/   HtmlView/
│   ├── DevExpress/   TMS/   opEDocExcelEng/
│   ├── GmSuite/   Producer/
│   └── EmailAdapters/Indy/
├── packages/                                  # NOVO — 21 .dpk + 21 .dproj + 2 .groupproj (flat)
│   ├── gtRtlD29.{dpk,dproj}
│   ├── gtCompressionD29.{dpk,dproj}
│   ├── gtFiltersD29.{dpk,dproj}
│   ├── gtCryptD29.{dpk,dproj}
│   ├── gtFontD29.{dpk,dproj}
│   ├── gtDocEngD29.{dpk,dproj}
│   ├── DCLgtDocEngD29.{dpk,dproj}
│   ├── DCLgtRBExpD29.{dpk,dproj}
│   ├── DCLgtFRExpD29.{dpk,dproj}
│   ├── DCLgtQRExpD29.{dpk,dproj}
│   ├── DCLgtRaveExpD29.{dpk,dproj}
│   ├── DCLgtAceExpD29.{dpk,dproj}
│   ├── DCLgtRichVwExpD29.{dpk,dproj}
│   ├── DCLgtScaleRichVwExpD29.{dpk,dproj}
│   ├── DCLgtHtmVwExpD29.{dpk,dproj}
│   ├── DCLgtXPressExpD29.{dpk,dproj}
│   ├── DCLgtAdvGridExpD29.{dpk,dproj}
│   ├── DCLopEDocExcelEngD29.{dpk,dproj}
│   ├── DCLgtGmSuiteExpD29.{dpk,dproj}
│   ├── DCLgtIndyAdapterD29.{dpk,dproj}
│   ├── DCLgtDocProdD29.{dpk,dproj}
│   ├── DCLgtDocEngD29Grp.groupproj
│   └── DCLgtDocEngExportIntfD29Grp.groupproj
└── Lib/                                       # build outputs (Fases 1.3+ e 3)
    └── RAD12/win{32,64}/{dcp,dcu,bpl,exe,hpp,obj,lib}/
```

Após Fase 2, mais 6 sets D24..D28+D37 são adicionados em `eDocEngine/packages/`, totalizando **147 `.dpk` + 147 `.dproj` + 14 `.groupproj`** todos na mesma pasta.

---

## Os 2 tokens (alinhar com CLAUDE.md)

| Token | Aparece em | Valores |
| --- | --- | --- |
| **`D<XX>`** (sufixo de pacote) | Filename de `.dpk`/`.dproj`/`.groupproj`; tag `requires`/`contains` no `.dpk`; `<MainSource>`/`<Source Name>`/`<Project Name>` no `.dproj`; `{$DESCRIPTION '... <XX>0'}` no `.dpk` | D24, D25, D26, D27, D28, D29, D37 |
| **`RAD<MM>`** (tag de output) | Apenas `<DCC_*Output>`/`<LIB_Output>` no `.dproj` e nome do build-report | RAD10.1, RAD10.2, RAD10.3, RAD10.4, RAD11, RAD12, RAD13 |

**Mapa fixo (sem aritmética uniforme):** D24↔RAD10.1 · D25↔RAD10.2 · D26↔RAD10.3 · D27↔RAD10.4 · D28↔RAD11 · D29↔RAD12 · D37↔RAD13.

---

## Fase 0 — Pré-voo

### 0.1 Inicializar repositório git (se ainda não inicializado)

`CLAUDE.md` registra `Is a git repository: false`. Sem versionamento, não há rollback granular. Inicializar antes de qualquer escrita:

```powershell
cd 'c:\Users\Public\Documents\Embarcadero\Studio\Outros\Gnostice'
git init
git add .gitignore .claudeignore .continueignore .cursorignore CLAUDE.md .claude\settings.json
git commit -m "chore: workspace baseline antes do rollout multi-Delphi eDocEngine"
git add -A
git commit -m "snapshot: estado D29 baseline (eDocEngine/Source + Shared3/Source)"
```

⚠ Se o usuário NÃO quiser git, sinalizar e seguir só com snapshot zip (0.2). Mas registrar que rollback granular fica indisponível.

### 0.2 Validar pré-requisitos do ambiente

```powershell
# PowerShell 5.1+ (Windows nativo) ou PowerShell 7+
$PSVersionTable.PSVersion

# Git
git --version

# msbuild — só verifica se há AO MENOS UMA instalação RAD Studio
Get-ChildItem 'C:\Program Files (x86)\Embarcadero\Studio' -Directory -ErrorAction SilentlyContinue

# Permissão de escrita no workspace
[System.IO.File]::WriteAllText('eDocEngine\.write-test.tmp', 'ok')
Remove-Item 'eDocEngine\.write-test.tmp'
```

**Critério de saída 0.2:** PowerShell ≥ 5.1, git presente, ao menos um BDS instalado, escrita ok.

### 0.3 Confirmar IDEs Embarcadero instalados

```powershell
Get-ChildItem 'C:\Program Files (x86)\Embarcadero\Studio' -Directory |
  Where-Object { Test-Path (Join-Path $_.FullName 'bin\rsvars.bat') } |
  Sort-Object Name |
  Select-Object Name, FullName
```

Mapear cada `BDS major` ao sufixo:

| BDS folder | Delphi | Sufixo | rsvars.bat | Status |
| --- | --- | --- | --- | --- |
| 18.0 | 10.1 Berlin | D24 | `C:\Program Files (x86)\Embarcadero\Studio\18.0\bin\rsvars.bat` | [ ] instalado / [ ] pular |
| 19.0 | 10.2 Tokyo | D25 | `…\19.0\bin\rsvars.bat` | [ ] instalado / [ ] pular |
| 20.0 | 10.3 Rio | D26 | `…\20.0\bin\rsvars.bat` | [ ] instalado / [ ] pular |
| 21.0 | 10.4 Sydney | D27 | `…\21.0\bin\rsvars.bat` | [ ] instalado / [ ] pular |
| 22.0 | 11 Alexandria | D28 | `…\22.0\bin\rsvars.bat` | [ ] instalado / [ ] pular |
| 23.0 | 12 Athens | D29 | `…\23.0\bin\rsvars.bat` | **[x] fonte canônica** |
| 37.0 | 13 Florence | D37 | `…\37.0\bin\rsvars.bat` | [ ] instalado / [ ] pular |

⚠ **Quebra de sequência BDS:** Embarcadero passou de `23.0` (Delphi 12) direto para `37.0` (Delphi 13), alinhando a pasta de instalação com `CompilerVersion`. Não esperar `24.0` no resultado do `Get-ChildItem`.

**Decisão necessária:** preencher a coluna *Status* antes da Fase 3. Versões "pular" geram arquivos (Fase 2) mas não passam por build (Fase 3 condicional).

### 0.4 Backup obrigatório do estado D29

```powershell
$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
$snapDir = '.workspace\snapshots'
New-Item -ItemType Directory -Force -Path $snapDir | Out-Null
Compress-Archive `
  -Path 'eDocEngine\Source','Shared3\Source' `
  -DestinationPath "$snapDir\eDocEngine-D29-baseline-$ts.zip" `
  -CompressionLevel Optimal
Write-Host "Snapshot criado: $snapDir\eDocEngine-D29-baseline-$ts.zip"
```

**Critério de saída 0.4:** arquivo zip ≥ 1 MB existe em `.workspace/snapshots/`.

### 0.5 Limpar artefatos de desenvolvimento

Antes de qualquer geração, remover state do IDE que polui diff:

```powershell
Get-ChildItem 'eDocEngine\Source','Shared3\Source' -Recurse -Force -Include `
  '__history','__recovery','*.dproj.local','*.identcache','*.dsk','*.tvsconfig','*.delphilsp.json','*.stat' |
  Remove-Item -Recurse -Force
```

Se `git` inicializado, fazer commit "chore: limpeza de IDE state" antes de prosseguir.

### 0.6 Validar matrizes de defines

Confirmar que `eDocEngine/Source/gtDefines.Inc` e `Shared3/Source/gtSharedDefines.inc` mapeiam `VER310..VER370`. Comando:

```powershell
Select-String -Path 'eDocEngine\Source\gtDefines.Inc','Shared3\Source\gtSharedDefines.inc' `
  -Pattern 'VER(31|32|33|34|35|36|37|38)0\b'
```

Esperado: ≥ 7 matches (VER310..VER370). Se faltar `VER370` ou `VER380`, adicionar bloco `{$IFDEF VERxxx} {$DEFINE gtDelphiNUp} {$ENDIF}` correspondente, antes da Fase 2.

### 0.7 Criar pasta `eDocEngine/packages/`

```powershell
$pkgDir = 'eDocEngine\packages'
if (-not (Test-Path $pkgDir)) {
  New-Item -ItemType Directory -Path $pkgDir | Out-Null
  Write-Host "Criada pasta $pkgDir"
} else {
  Write-Host "$pkgDir já existe"
  # Verificar se está vazia — se não, abortar e perguntar ao usuário
  $existing = Get-ChildItem $pkgDir -Force
  if ($existing.Count -gt 0) {
    Write-Warning "Pasta $pkgDir não está vazia ($($existing.Count) itens). Verificar antes de prosseguir."
  }
}
```

**Critério de saída 0.7:** `eDocEngine/packages/` existe e está vazia (ou seu conteúdo prévio foi confirmado/auditado).

**Critério de saída Fase 0:** todos os passos 0.1–0.7 executados com sucesso, snapshot criado, IDEs mapeados, `packages/` pronta para receber arquivos na Fase 1.

---

## Fase 1 — Convergência do D29 à *Unified packaging convention*

O set D29 atual está espalhado por `Source/` e subpastas, e escreve outputs no diretório global do IDE. Esta fase faz **duas mudanças**:

1. **Mover** os 21 `.dpk`/`.dproj` + 2 `.groupproj` para `eDocEngine/packages/` (flat).
2. **Reescrever** os `.dproj` para:
   - Outputs em `..\Lib\RAD12\win{32,64}\...` (uniforme, sem cálculo per-subfolder porque agora todo mundo está em `packages/`)
   - `<DCC_UnitSearchPath>` apontando de volta para `..\Source\<sub>` e `..\..\Shared3\Source\<sub>` (porque os .pas continuam onde estão)
3. **Reescrever** os 2 `.groupproj` para usar `<Projects Include=".\<file>.dproj">` (mesma pasta).

### 1.1 Script `tools/Migrate-D29ToPackages.ps1` (substitui o antigo Patch-D29Outputs.ps1)

**Não fazer à mão** — 21 arquivos × várias configs + recálculo de paths = ~100 edições.

Parâmetros:

```text
-DryRun                              (lista mudanças sem escrever/mover)
-LogFile <path>                      (default: .workspace/build-reports/migrate-D29-<ts>.log)
-KeepOrigin                          (mantém .dpk/.dproj originais — útil só pra debug; default: mover de verdade)
```

Comportamento obrigatório:

1. **Inventário inicial**: localizar os 21 `.dpk` D29 atuais — origem registrada conforme tabela do Inventário.
2. **Para cada `.dproj`**:
   - Detectar encoding (esperado UTF-8 BOM) e preservar
   - Calcular `OldDir` (origem) e novos `<DCC_UnitSearchPath>` que apontam de volta para `OldDir` relativo a `eDocEngine/packages/`
   - Reescrever blocos `<PropertyGroup>` para Base, Cfg_1_Win32, Cfg_2_Win32, Cfg_1_Win64, Cfg_2_Win64 com os novos paths (Lib uniforme, UnitSearchPath calculado)
   - Preservar todos os outros elements (`<DCC_Define>`, `<VerInfo_Keys>`, `<DllSuffix>`, defines de host como `${FastReport_DCU_DIR}`, etc.)
   - Escrever o `.dproj` corrigido em `eDocEngine/packages/<basename>.dproj`
   - Apagar o `.dproj` original (se não `-KeepOrigin`)
3. **Para cada `.dpk`**: mover sem modificação (o conteúdo Pascal não referencia paths).
4. **Para os 2 `.groupproj`**: reescrever `<Projects Include="…">` para `.\<filename>.dproj` e mover.
5. **Log**: cada move, cada substituição em arquivo, em `.workspace/build-reports/migrate-D29-<ts>.log`.

### 1.2 Blocos XML de output (uniformes para todos os 21 .dproj)

Após mover para `eDocEngine/packages/`, `<LibRelative>` é **sempre** `..\Lib`. O bloco a inserir é o mesmo para todos:

```xml
<PropertyGroup Condition="'$(Base)'!=''">
  <DCC_Description>Gnostice eDocEngine 290</DCC_Description>
  <ProjectVersion>23.0</ProjectVersion>
  <TargetedPlatforms>3</TargetedPlatforms>
</PropertyGroup>

<PropertyGroup Condition="'$(Base_Win32)'!=''">
  <DCC_DcpOutput>..\Lib\RAD12\win32\dcp</DCC_DcpOutput>
  <DCC_DcuOutput>..\Lib\RAD12\win32\dcu</DCC_DcuOutput>
  <DCC_BplOutput>..\Lib\RAD12\win32\bpl</DCC_BplOutput>
  <DCC_ExeOutput>..\Lib\RAD12\win32\exe</DCC_ExeOutput>
  <DCC_HppOutput>..\Lib\RAD12\win32\hpp</DCC_HppOutput>
  <DCC_ObjOutput>..\Lib\RAD12\win32\obj</DCC_ObjOutput>
  <LIB_Output>..\Lib\RAD12\win32\lib</LIB_Output>
</PropertyGroup>

<PropertyGroup Condition="'$(Base_Win64)'!=''">
  <DCC_DcpOutput>..\Lib\RAD12\win64\dcp</DCC_DcpOutput>
  <DCC_DcuOutput>..\Lib\RAD12\win64\dcu</DCC_DcuOutput>
  <DCC_BplOutput>..\Lib\RAD12\win64\bpl</DCC_BplOutput>
  <DCC_ExeOutput>..\Lib\RAD12\win64\exe</DCC_ExeOutput>
  <DCC_HppOutput>..\Lib\RAD12\win64\hpp</DCC_HppOutput>
  <DCC_ObjOutput>..\Lib\RAD12\win64\obj</DCC_ObjOutput>
  <LIB_Output>..\Lib\RAD12\win64\lib</LIB_Output>
</PropertyGroup>
```

### 1.3 `<DCC_UnitSearchPath>` por pacote (calculado pelo script)

Como o `.dproj` mudou de pasta mas o `.pas` ficou onde estava, **adicionar** ao `<DCC_UnitSearchPath>` os paths abaixo (preservando entradas pré-existentes como DCU de hosts):

| Pacote | Adicionar ao `<DCC_UnitSearchPath>` (a partir de `eDocEngine/packages/`) |
| --- | --- |
| `gtRtlD29`, `gtCompressionD29`, `gtFiltersD29`, `gtCryptD29`, `gtFontD29` | `..\..\Shared3\Source\<sub>` (sub = Rtl/Compression/Filters/PDFCrypt/PDFFontProcessor) |
| `gtDocEngD29`, `DCLgtDocEngD29` | `..\Source` |
| `DCLgtRBExpD29` | `..\Source\RB;..\Source` |
| `DCLgtFRExpD29` | `..\Source\FR;..\Source` |
| `DCLgtQRExpD29` | `..\Source\QR;..\Source` |
| `DCLgtRaveExpD29` | `..\Source\Rave;..\Source` |
| `DCLgtAceExpD29` | `..\Source\Ace;..\Source` |
| `DCLgtRichVwExpD29` | `..\Source\RichVw;..\Source` |
| `DCLgtScaleRichVwExpD29` | `..\Source\ScaleRichVw;..\Source` |
| `DCLgtHtmVwExpD29` | `..\Source\HtmlView;..\Source` |
| `DCLgtXPressExpD29` | `..\Source\DevExpress;..\Source` |
| `DCLgtAdvGridExpD29` | `..\Source\TMS;..\Source` |
| `DCLopEDocExcelEngD29` | `..\Source\opEDocExcelEng;..\Source` |
| `DCLgtGmSuiteExpD29` | `..\Source\GmSuite;..\Source` |
| `DCLgtIndyAdapterD29` | `..\Source\EmailAdapters\Indy;..\Source` |
| `DCLgtDocProdD29` | `..\Source\Producer;..\Source` |

**Manter intactos** entries pré-existentes do tipo `$(BDS)\source\...`, `${FastReport_DCU_DIR}`, paths absolutos de host etc. — só **prepend** os novos paths relativos.

### 1.4 Reescrever os 2 `.groupproj`

`eDocEngine/packages/DCLgtDocEngD29Grp.groupproj`:

```xml
<Projects Include=".\gtRtlD29.dproj" />
<Projects Include=".\gtCompressionD29.dproj" />
<Projects Include=".\gtFiltersD29.dproj" />
<Projects Include=".\gtCryptD29.dproj" />
<Projects Include=".\gtFontD29.dproj" />
<Projects Include=".\gtDocEngD29.dproj" />
<Projects Include=".\DCLgtDocEngD29.dproj" />
```

`eDocEngine/packages/DCLgtDocEngExportIntfD29Grp.groupproj`:

```xml
<Projects Include=".\DCLgtRBExpD29.dproj" />
<Projects Include=".\DCLgtFRExpD29.dproj" />
<Projects Include=".\DCLgtQRExpD29.dproj" />
<Projects Include=".\DCLgtRaveExpD29.dproj" />
<Projects Include=".\DCLgtAceExpD29.dproj" />
<Projects Include=".\DCLgtRichVwExpD29.dproj" />
<Projects Include=".\DCLgtScaleRichVwExpD29.dproj" />
<Projects Include=".\DCLgtHtmVwExpD29.dproj" />
<Projects Include=".\DCLgtXPressExpD29.dproj" />
<Projects Include=".\DCLgtAdvGridExpD29.dproj" />
<Projects Include=".\DCLopEDocExcelEngD29.dproj" />
<Projects Include=".\DCLgtGmSuiteExpD29.dproj" />
<Projects Include=".\DCLgtIndyAdapterD29.dproj" />
<Projects Include=".\DCLgtDocProdD29.dproj" />
```

### 1.5 Executar migração

```powershell
.\tools\Migrate-D29ToPackages.ps1 -DryRun     # 1ª execução: só lista
.\tools\Migrate-D29ToPackages.ps1             # 2ª execução: aplica
```

Se `git` inicializado:

```powershell
git status
git add -A
git commit -m "fase1: migrar 21 .dpk/.dproj + 2 .groupproj D29 para eDocEngine/packages/"
```

### 1.6 Build de validação no Delphi 12

Abrir "RAD Studio 12 Command Prompt" (ou ativar manualmente). **Os groupprojs agora vivem em `eDocEngine/packages/`, não mais em `eDocEngine/Source/`**:

```cmd
call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"
msbuild eDocEngine\packages\DCLgtDocEngD29Grp.groupproj /t:Build /p:Config=Release /p:Platform=Win32 /v:minimal  || exit /b 1
msbuild eDocEngine\packages\DCLgtDocEngD29Grp.groupproj /t:Build /p:Config=Release /p:Platform=Win64 /v:minimal  || exit /b 1
msbuild eDocEngine\packages\DCLgtDocEngExportIntfD29Grp.groupproj /t:Build /p:Config=Release /p:Platform=Win32 /v:minimal
msbuild eDocEngine\packages\DCLgtDocEngExportIntfD29Grp.groupproj /t:Build /p:Config=Release /p:Platform=Win64 /v:minimal
```

⚠ Adapters podem falhar (host não instalado) — não usar `|| exit /b 1` no segundo `.groupproj`. Capturar exit code separadamente.

### 1.7 Verificar Tool Palette (manual)

1. Abrir Delphi 12 IDE
2. **Component → Install Packages**
3. Localizar `DCLgtDocEngD29` na lista; remover entrada antiga (se apontava para `…\23.0\Bpl\`)
4. **Add…** → escolher `eDocEngine\Lib\RAD12\win32\bpl\DCLgtDocEngD29.bpl`
5. Confirmar que `TgtPDFEngine`, `TgtHTMLEngine`, etc. aparecem na Tool Palette categoria "Gnostice eDocEngine 290"

**Critério de saída Fase 1:**

- [ ] `eDocEngine/packages/` contém 21 `.dpk` + 21 `.dproj` + 2 `.groupproj` D29 (flat)
- [ ] `eDocEngine/Source/`, `eDocEngine/Source/<Adapter>/`, `Shared3/Source/<sub>/` **não** contêm mais arquivos `.dpk`/`.dproj`/`.groupproj` (só `.pas`/`.res`/`.inc`/`.dfm`)
- [ ] `eDocEngine/Lib/RAD12/win32/bpl/` contém ao menos os 7 core BPLs (gtRtl, gtCompression, gtFilters, gtCrypt, gtFont, gtDocEng, DCLgtDocEng) — 14 adapters condicionais
- [ ] `eDocEngine/Lib/RAD12/win64/bpl/` idem
- [ ] Nenhum BPL escreveu em `C:\Users\Public\Documents\Embarcadero\Studio\23.0\Bpl\` (verificar com `Get-ChildItem` antes/depois)
- [ ] Tool Palette do Delphi 12 mostra componentes do D29 com fonte = novo BPL path
- [ ] Commit git "fase1: …" registrado

---

## Fase 2 — Geração dos sets D24..D28 e D37

### 2.1 Script `tools/Generate-DXXSet.ps1`

**Pré-requisito:** Fase 1 concluída — todos os arquivos D29 estão em `eDocEngine/packages/`. Este script trabalha **exclusivamente** dentro de `eDocEngine/packages/` (não toca `Source/` nem `Shared3/Source/`).

#### Parâmetros

```text
-PackagesDir 'eDocEngine\packages'    (default; pasta canônica de todos .dpk/.dproj/.groupproj)
-SourceSuffix D29                     (default; sempre o template)
-TargetSuffix D24|D25|D26|D27|D28|D37
-TargetMarketing 10.1|10.2|10.3|10.4|11|13   (só esses 6, D29→12 já existe)
-TargetProjectVersion <string>        (ex: '18.0', '23.0', '37.0' — da tabela 2.2; sempre == BDS folder major)
-Mode SkipExisting|Overwrite|Fail     (default: SkipExisting — garante idempotência)
-DryRun                               (lista mudanças sem escrever)
-LogFile <path>                       (default: .workspace/build-reports/generate-<TargetSuffix>-<ts>.log)
```

#### Comportamento

1. **Encoding**: ler `.dproj`/`.dpk` detectando BOM; preservar exatamente na escrita.
2. **Para cada arquivo** `<PackagesDir>/*D29*.{dpk,dproj,groupproj}`:
   - Path destino: mesmo dir, nome com `D29 → D<XX>` (ex.: `eDocEngine/packages/DCLgtRBExpD29.dproj` → `eDocEngine/packages/DCLgtRBExpD<XX>.dproj`).
   - Se destino existe e `-Mode SkipExisting`: log "skip" e continuar.
   - Se destino existe e `-Mode Overwrite`: log "overwrite" e prosseguir.
   - Se destino existe e `-Mode Fail`: abort.
3. **Substituições contextuais** (NÃO regex cego — ver lista abaixo).
4. **`<DCC_UnitSearchPath>`**: copiar da `.dproj` D29 sem alteração — paths (`..\Source\<sub>`, `..\..\Shared3\Source\<sub>`) já estão corretos porque destino fica na **mesma pasta** que o D29 (`eDocEngine/packages/`).
5. **`<DllSuffix>`**, `<TargetName>` (se presentes): aplicar substituição como na lista contextual.
6. **Excluir do clone**: nada extra (`packages/` já está limpa de IDE state após a Fase 0.5).

#### Lista de substituições contextuais

**Em `.dpk` (texto Pascal):**

| Padrão (regex Pascal) | Substituir por | Notas |
| --- | --- | --- |
| `package\s+(\w+)D29\b` | `package $1D<XX>` | Linha `package <Name>D29;` no topo |
| `{\$DESCRIPTION\s+'Gnostice\s+(.+?)\s+290'}` | `{$DESCRIPTION 'Gnostice $1 <XX>0'}` | Tag de descrição |
| `{\$LIBSUFFIX\s+'290'}` | `{$LIBSUFFIX '<XX>0'}` | Sufixo de biblioteca (se presente) |
| `{\$IMPLICITBUILD\s+(ON\|OFF)}` | inalterado | Não mexer |
| `\b(\w+)D29\b` em linhas `requires` ou `contains` | `$1D<XX>` | SÓ dentro dos blocos `requires`/`contains` |

**Em `.dproj` (XML):**

| XML element | Substituição |
| --- | --- |
| `<MainSource>(.+?)D29\.dpk</MainSource>` | `<MainSource>$1D<XX>.dpk</MainSource>` |
| `<Source Name="MainSource">(.+?)D29\.dpk</Source>` | `<Source Name="MainSource">$1D<XX>.dpk</Source>` |
| `<ProjectVersion>.+?</ProjectVersion>` | `<ProjectVersion><TargetProjectVersion></ProjectVersion>` |
| `<DCC_Description>Gnostice (.+?) 290</DCC_Description>` | `<DCC_Description>Gnostice $1 <XX>0</DCC_Description>` |
| `<DllSuffix>290</DllSuffix>` (se presente) | `<DllSuffix><XX>0</DllSuffix>` |
| `<TargetName>(.+?)D29</TargetName>` (se presente) | `<TargetName>$1D<XX></TargetName>` |
| Paths em `<DCC_*Output>`/`<LIB_Output>`: `\\RAD12\\` | `\\RAD<MM>\\` |
| `<VerInfo_Keys>...FileVersion=...</VerInfo_Keys>` | inalterado (versão do produto, não do Delphi) |

**Em `.groupproj` (XML):**

| XML element | Substituição |
| --- | --- |
| `<Projects Include="(.+?)D29\.dproj">` | `<Projects Include="$1D<XX>.dproj">` |
| `<Target Name="(.+?)D29:Build">` | `<Target Name="$1D<XX>:Build">` (e Clean/Make) |
| Filename do groupproj | `DCLgtDocEngD29Grp.groupproj` → `DCLgtDocEngD<XX>Grp.groupproj` |

⚠ **Nunca** fazer `(Get-Content $f).Replace('D29', 'D<XX>')` global — quebraria strings literais como `'D29 release notes'` em `<VerInfo_Keys>` ou comentários `// D29 fix`.

### 2.2 Tabela de `ProjectVersion` por alvo

**Regra de alinhamento:** `ProjectVersion` = **BDS major** da Fase 0.3. Embarcadero usa o mesmo número para a pasta de instalação e para o `<ProjectVersion>` do `.dproj`.

| Sufixo | Delphi | BDS major | `ProjectVersion` |
| --- | --- | --- | --- |
| D24 | 10.1 Berlin | 18.0 | `18.0` |
| D25 | 10.2 Tokyo | 19.0 | `19.0` |
| D26 | 10.3 Rio | 20.0 | `20.0` |
| D27 | 10.4 Sydney | 21.0 | `21.0` |
| D28 | 11 Alexandria | 22.0 | `22.0` |
| D29 | 12 Athens | 23.0 | `23.0` |
| D37 | 13 Florence | 37.0 | `37.0` |

**Validação opcional por IDE** (recomendada se houver suspeita de divergência por causa de update específico — R1):

1. Abrir o RAD Studio alvo
2. File → New → Package — Delphi
3. Salvar como `test-version.dproj` em pasta temporária
4. Fechar IDE
5. Abrir `test-version.dproj` em editor: confirmar que `<ProjectVersion>X.Y</ProjectVersion>` bate com o valor da tabela
6. Se divergente: ajustar a tabela e o `$map` da seção 2.4
7. Apagar pasta temporária

### 2.3 Conteúdo dos `.groupproj` gerados

#### `DCLgtDocEngD<XX>Grp.groupproj` (core — 7 packages, ordem obrigatória)

```xml
<Projects Include=".\gtRtlD<XX>.dproj" />
<Projects Include=".\gtCompressionD<XX>.dproj" />
<Projects Include=".\gtFiltersD<XX>.dproj" />
<Projects Include=".\gtCryptD<XX>.dproj" />
<Projects Include=".\gtFontD<XX>.dproj" />
<Projects Include=".\gtDocEngD<XX>.dproj" />
<Projects Include=".\DCLgtDocEngD<XX>.dproj" />
```

Todos os 7 `<Projects Include>` usam `.\<file>.dproj` porque vivem na mesma pasta (`eDocEngine/packages/`). Ordem reflete dependências `requires` — não inverter.

#### `DCLgtDocEngExportIntfD<XX>Grp.groupproj` (14 adapters — ordem livre)

```xml
<Projects Include=".\DCLgtRBExpD<XX>.dproj" />
<Projects Include=".\DCLgtFRExpD<XX>.dproj" />
<Projects Include=".\DCLgtQRExpD<XX>.dproj" />
<Projects Include=".\DCLgtRaveExpD<XX>.dproj" />
<Projects Include=".\DCLgtAceExpD<XX>.dproj" />
<Projects Include=".\DCLgtRichVwExpD<XX>.dproj" />
<Projects Include=".\DCLgtScaleRichVwExpD<XX>.dproj" />
<Projects Include=".\DCLgtHtmVwExpD<XX>.dproj" />
<Projects Include=".\DCLgtXPressExpD<XX>.dproj" />
<Projects Include=".\DCLgtAdvGridExpD<XX>.dproj" />
<Projects Include=".\DCLopEDocExcelEngD<XX>.dproj" />
<Projects Include=".\DCLgtGmSuiteExpD<XX>.dproj" />
<Projects Include=".\DCLgtIndyAdapterD<XX>.dproj" />
<Projects Include=".\DCLgtDocProdD<XX>.dproj" />
```

Adapters não dependem entre si; ordem livre. Se um adapter falhar (host não instalado), msbuild prossegue para o próximo.

### 2.4 Execução em batch

```powershell
$map = @(
  @{ Suffix='D24'; Marketing='10.1'; ProjectVersion='18.0' },
  @{ Suffix='D25'; Marketing='10.2'; ProjectVersion='19.0' },
  @{ Suffix='D26'; Marketing='10.3'; ProjectVersion='20.0' },
  @{ Suffix='D27'; Marketing='10.4'; ProjectVersion='21.0' },
  @{ Suffix='D28'; Marketing='11';   ProjectVersion='22.0' },
  @{ Suffix='D37'; Marketing='13';   ProjectVersion='37.0' }
)
foreach ($e in $map) {
  Write-Host "=== Gerando $($e.Suffix) ($($e.Marketing)) ==="
  .\tools\Generate-DXXSet.ps1 `
    -SourceSuffix D29 `
    -TargetSuffix $e.Suffix `
    -TargetMarketing $e.Marketing `
    -TargetProjectVersion $e.ProjectVersion `
    -Mode SkipExisting
  if ($LASTEXITCODE -ne 0) { throw "Geração de $($e.Suffix) falhou (exit=$LASTEXITCODE)" }
}
```

### 2.5 Validação pós-geração

```powershell
$pkg = 'eDocEngine\packages'

# 1. Contagem por sufixo: cada D<XX> deve ter 21 .dpk + 21 .dproj + 2 .groupproj
foreach ($suffix in 'D24','D25','D26','D27','D28','D37') {
  $dpk = (Get-ChildItem $pkg -Filter "*$suffix.dpk").Count
  $dproj = (Get-ChildItem $pkg -Filter "*$suffix.dproj").Count
  $grp = (Get-ChildItem $pkg -Filter "*$suffix*Grp.groupproj").Count
  Write-Host "$suffix : $dpk .dpk, $dproj .dproj, $grp .groupproj (esperado: 21/21/2)"
  if ($dpk -ne 21 -or $dproj -ne 21 -or $grp -ne 2) { Write-Warning "Contagem fora do esperado para $suffix" }
}

# 2. Nenhum .dpk órfão (sem .dproj parceiro)
Get-ChildItem $pkg -Filter '*.dpk' |
  Where-Object { -not (Test-Path ($_.FullName -replace '\.dpk$', '.dproj')) } |
  ForEach-Object { Write-Warning "Órfão (sem .dproj): $($_.FullName)" }

# 3. Nenhum arquivo D29 modificado por engano
git diff --stat -- "$pkg\*D29*"
# Esperado: vazio (Fase 1 commitou as mudanças do D29; Fase 2 só adiciona)

# 4. Source/ e Shared3/Source/ não devem conter .dpk/.dproj/.groupproj
$strays = Get-ChildItem 'eDocEngine\Source','Shared3\Source' -Recurse -Include *.dpk,*.dproj,*.groupproj
if ($strays) { $strays | ForEach-Object { Write-Warning "Stray (deveria estar em packages/): $($_.FullName)" } }

# 5. Outputs RAD<MM> corretos por sufixo
$expectedRAD = @{ D24='RAD10.1'; D25='RAD10.2'; D26='RAD10.3'; D27='RAD10.4'; D28='RAD11'; D29='RAD12'; D37='RAD13' }
foreach ($entry in $expectedRAD.GetEnumerator()) {
  $sample = Get-ChildItem $pkg -Filter "*$($entry.Key).dproj" | Select-Object -First 1
  if ($sample) {
    $hit = Select-String -Path $sample.FullName -Pattern "\\$($entry.Value)\\" -Quiet
    if (-not $hit) { Write-Warning "$($entry.Key): output $($entry.Value) não encontrado em $($sample.Name)" }
  }
}
```

Se git inicializado:

```powershell
git add -A
git commit -m "fase2: gerar sets D24/D25/D26/D27/D28/D37 a partir do template D29"
```

**Critério de saída Fase 2:**

- [ ] 6 novos sets presentes (D24, D25, D26, D27, D28, D37) — total 7 contando D29
- [ ] Contagem 21/21/2 confirmada para cada novo sufixo
- [ ] Zero `.dpk` órfão
- [ ] D29 não modificado (diff vazio na seção `*D29*`)
- [ ] Outputs em cada `.dproj` apontam para o `RAD<MM>` correto (sanity: grep `RAD10.1` em `*D24.dproj` deve retornar matches)
- [ ] Commit git "fase2: …" registrado

### 2.6 Rollback se Fase 2 falhar meio caminho

```powershell
# Opção 1: git (preferida)
git reset --hard HEAD     # volta ao commit "fase1: ..."

# Opção 2: restaurar do snapshot Fase 0.4 (se git não usado)
$latest = Get-ChildItem '.workspace\snapshots\eDocEngine-D29-baseline-*.zip' |
  Sort-Object LastWriteTime -Descending | Select-Object -First 1
Expand-Archive -Path $latest.FullName -DestinationPath '.' -Force
```

---

## Fase 3 — Build & sanity check por Delphi instalado

### 3.1 Script `tools/Build-RADSet.ps1`

Wrapper que ativa `rsvars.bat` correto, roda msbuild, captura exit code e tee output para report:

```text
Parâmetros:
  -Suffix D24|D25|...|D37
  -Marketing 10.1|...|13
  -BdsFolder 18.0|...|37.0
  -Platforms Win32,Win64           (default ambos)
  -SkipAdaptersOnFail              (default $true — adapters sem host não abortam)
  -ReportDir '.workspace\build-reports'

Comportamento:
  1. Verifica existência de C:\Program Files (x86)\Embarcadero\Studio\$BdsFolder\bin\rsvars.bat
  2. Spawna cmd.exe com rsvars + msbuild dentro, captura stdout/stderr
  3. Localiza groupprojs em eDocEngine\packages\:
     - Core: DCLgtDocEng<Suffix>Grp.groupproj
     - Adapters: DCLgtDocEngExportIntf<Suffix>Grp.groupproj
  4. Para cada combinação Platform x Groupproj:
     - Core groupproj: falha aborta
     - Adapters groupproj: falha é warning, continua
  5. Gera report eDocEngine-RAD<Marketing>.txt com:
     - Tempo total
     - BPLs gerados (ls eDocEngine\Lib\RAD<MM>\win32\bpl\)
     - Adapters skipped (host não encontrado)
     - Erros/warnings críticos
```

### 3.2 Execução em batch para todos os Delphis instalados

```powershell
$map = @(
  @{ Suffix='D24'; Marketing='10.1'; BdsFolder='18.0' },
  @{ Suffix='D25'; Marketing='10.2'; BdsFolder='19.0' },
  @{ Suffix='D26'; Marketing='10.3'; BdsFolder='20.0' },
  @{ Suffix='D27'; Marketing='10.4'; BdsFolder='21.0' },
  @{ Suffix='D28'; Marketing='11';   BdsFolder='22.0' },
  @{ Suffix='D29'; Marketing='12';   BdsFolder='23.0' },
  @{ Suffix='D37'; Marketing='13';   BdsFolder='37.0' }
)
foreach ($e in $map) {
  $rsvars = "C:\Program Files (x86)\Embarcadero\Studio\$($e.BdsFolder)\bin\rsvars.bat"
  if (-not (Test-Path $rsvars)) {
    Write-Host "SKIP $($e.Suffix): Delphi $($e.Marketing) não instalado (sem $rsvars)"
    continue
  }
  .\tools\Build-RADSet.ps1 -Suffix $e.Suffix -Marketing $e.Marketing -BdsFolder $e.BdsFolder
}
```

### 3.3 Verificação Tool Palette para cada Delphi (manual, opcional)

Para cada Delphi com build OK na 3.2:

1. Abrir IDE
2. Component → Install Packages → Add `eDocEngine\Lib\RAD<MM>\win32\bpl\DCLgtDocEngD<XX>.bpl`
3. Confirmar 5+ componentes (TgtPDFEngine, TgtHTMLEngine, TgtRTFEngine, TgtXLSEngine, …) na Tool Palette
4. Para cada adapter buildado: instalar `DCL<Adapter>D<XX>.bpl` e validar registro

**Critério de saída Fase 3:**

- [ ] `eDocEngine/Lib/RAD<MM>/win32/bpl/` contém ≥ 7 BPLs (5 Shared3 + runtime + design-time) para cada Delphi instalado
- [ ] `eDocEngine/Lib/RAD<MM>/win64/bpl/` idem
- [ ] `.workspace/build-reports/eDocEngine-RAD<MM>.txt` arquivado para cada Delphi com build executado
- [ ] Adapters faltando (host não instalado) listados explicitamente no report
- [ ] (Opcional 3.3) Tool Palette verificado em ao menos Delphi 12 (atual) e mais 1

---

## Fase 4 — Aceitação global

- [ ] **Layout consolidado**: `eDocEngine/packages/` contém todos os `.dpk`/`.dproj`/`.groupproj` (flat)
- [ ] **`eDocEngine/Source/`, `eDocEngine/Source/<Adapter>/`, `Shared3/Source/<sub>/`** contêm apenas `.pas`/`.res`/`.inc`/`.dfm` (zero `.dpk`/`.dproj`/`.groupproj`)
- [ ] **7 sets `D<XX>`** em `eDocEngine/packages/` (D24..D29, D37): 147 `.dpk` + 147 `.dproj` + 14 `.groupproj`
- [ ] **Lib trees** `eDocEngine/Lib/RAD10.1..RAD13/win{32,64}/...` populadas para Delphis instalados
- [ ] **3 scripts** em `tools/` versionados: `Migrate-D29ToPackages.ps1`, `Generate-DXXSet.ps1`, `Build-RADSet.ps1`
- [ ] **`tools/README.md`** documentando os 3 scripts (parâmetros, exemplos, idempotência)
- [ ] **CLAUDE.md** "Current state vs. target": linha eDocEngine → "✅ D24..D37 materializados em `packages/`; builds verificados: {lista Delphi}"
- [ ] **Build-reports** em `.workspace/build-reports/` para cada Delphi com build executado
- [ ] **Snapshot Fase 0.4** preservado em `.workspace/snapshots/` (mínimo 30 dias)
- [ ] **Commits git** "fase1: …", "fase2: …", "fase3: …" presentes
- [ ] (Opcional) Tag git `edocengine-multi-delphi-v1.0` no commit final

---

## Procedimento de rollback global

Se em qualquer fase precisar reverter ao estado D29 original:

### Com git (preferido)

```powershell
git log --oneline                                 # localizar commit "snapshot: estado D29 baseline"
git reset --hard <hash-do-baseline>
git clean -fd 'eDocEngine\Source' 'Shared3\Source' 'eDocEngine\Lib'
```

### Sem git (fallback via snapshot)

```powershell
# 1. Apagar tudo que foi gerado pela migração + Fase 2
Remove-Item 'eDocEngine\Lib' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item 'eDocEngine\packages' -Recurse -Force -ErrorAction SilentlyContinue

# 2. Restaurar D29 original (arquivos voltam para Source/<sub> e Shared3/Source/<sub>) do snapshot
$latest = Get-ChildItem '.workspace\snapshots\eDocEngine-D29-baseline-*.zip' |
  Sort-Object LastWriteTime -Descending | Select-Object -First 1
Expand-Archive -Path $latest.FullName -DestinationPath '.' -Force
```

---

## Riscos & decisões pendentes

| # | Risco / decisão | Severidade | Quando resolver |
| --- | --- | --- | --- |
| R1 | `ProjectVersion` errado faz IDE migrar projeto na 1ª abertura (modifica disco). | Alta | Antes da Fase 2.4 — validar via 2.2 procedimento. |
| R2 | Adapters dependem de hosts externos (FastReport, QR, etc.) instalados *na versão alvo*. Falta de host = adapter sem build. | Média | Fase 3.1 — `-SkipAdaptersOnFail $true` por default; listar pulados no report. |
| R3 | `.res` em adapters (`ScaleRichVw`, `RichVw`) pode ter sido gerado em Delphi diferente (D26 legado). Resources não-portáveis entre versões. | Média | Fase 2 — regenerar `.res` via msbuild, não copiar do D29. Validar com `Get-FileHash` antes/depois. |
| R4 | Shared3 será reutilizado pelos outros 2 produtos no futuro? Afeta onde `Lib/RAD<MM>/` dos Shared3 packages cai. **Default proposto:** `eDocEngine/Lib/RAD<MM>/` enquanto eDocEngine for único consumidor. | Alta (arquitetural) | Antes da Fase 1.1 — confirmar com usuário. Se usuário disser "Shared3/Lib", mudar `<LibRelative>` nos Shared3 .dproj para `..\..\Lib` (no próprio Shared3). |
| R5 | C++Builder personality: gerar `.bpi`/`.lib`/`.hpp` exige license/install do C++Builder em cada Delphi. Sem ele, `<LIB_Output>` fica configurado mas pasta `lib/` vazia (não dá erro). | Baixa | Fase 3 — registrar no report quais Delphis têm C++Builder. |
| R6 | Encoding `.dproj`: vendor usa UTF-8 BOM. PowerShell `Set-Content -Encoding UTF8` SEM BOM por default em PS5/7. Script deve usar `[System.IO.File]::WriteAllText($path, $content, $utf8WithBom)`. | Alta | Fase 2.1 — testar primeiro com `-DryRun` + diff binário do output. |
| R7 | `Sample/eDocEngine_VCL/` permanece read-only (enforced em `.claude/settings.json`). Não usar como destino. | Resolvido | Já enforced. |
| R8 | Paths longos no Windows: agora simplificados pela consolidação em `packages/` — `eDocEngine\packages\DCLgtIndyAdapterD24.dproj` = ~57 chars (era 73 antes). Risco residual baixo, mas habilitar `LongPathsEnabled` ainda é boa prática. | Baixa | Fase 1.6 — testar build; se falhar com "path too long", habilitar via `New-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem -Name LongPathsEnabled -Value 1 -Type DWord`. |
| R13 | **Mover .dpk/.dproj para `packages/` quebra Sample/eDocEngine_VCL como referência** se este referenciasse paths absolutos. O Sample é read-only (R7) e mantém o layout antigo — não usar diff direto entre Sample e workspace após Fase 1. | Baixa | Documentar — Sample é referência *do estado original*, não do alvo. |
| R9 | Sem git inicializado, Fase 2.6 rollback depende só do snapshot zip — granularidade pior. | Média | Fase 0.1 — decidir com usuário. |
| R10 | Code signing dos BPLs: vendor original não assina; nosso build também não vai assinar. Se cliente do eDocEngine exigir BPL assinado, precisa de step adicional pós-build (não escopo deste plano). | Baixa | Fora de escopo — registrar como decisão futura. |
| R11 | Substituição cega `D29 → D<XX>` quebraria literais Pascal (`'D29 release notes'` em VerInfo ou comentários `// D29 fix #123`). Script DEVE usar regex contextuais (Fase 2.1 lista). | Alta | Fase 2.1 implementação. |
| R12 | Comportamento default em falha de adapter Fase 3: continuar (warning) vs abortar. **Default proposto:** `-SkipAdaptersOnFail $true` — continuar com warning. Core groupproj falha = abort. | Média | Resolvido no script Build-RADSet.ps1. |

---

## Decisões a confirmar com usuário ANTES de Fase 1

1. **Git**: inicializar repositório git no workspace? (R9) — *recomendado: sim*
2. **Shared3/Lib**: onde caem os BPLs de `gtRtlD<XX>`, `gtCompressionD<XX>`, etc.? (R4) — *default proposto: `eDocEngine/Lib/RAD<MM>/`*
3. **Long paths Windows**: habilitar `LongPathsEnabled` agora ou só se Fase 1.3 falhar? (R8) — *default proposto: habilitar agora*
4. **Versões a gerar**: alguma das versões D24..D28 / D37 deve ser pulada por decisão de produto (não só "IDE não instalado")? — *default: gerar todas mesmo sem IDE; build é condicional*
5. **`-Mode` default no Generate-DXXSet.ps1**: `SkipExisting` (idempotente) ou `Fail` (estrito)? — *default proposto: `SkipExisting`*

---

## Cronograma estimado

| Fase | Esforço | Pode rodar em paralelo? |
| --- | --- | --- |
| Fase 0 | 30–60 min (mais validar `ProjectVersion` por IDE) | Não |
| Fase 1 (script + patch + build D29) | 2–4 h | Não |
| Fase 2 (3 scripts + geração) | 3–6 h (maior parte: escrever Generate-DXXSet.ps1) | Não |
| Fase 3 (build por Delphi) | 30 min/Delphi × 6 = 3 h | Sim (1 cmd prompt por Delphi) |
| Fase 4 (DoD + docs) | 1–2 h | Não |
| **Total** | **10–16 h de trabalho efetivo** | — |

---

## Pós-rollout — preparação para os próximos 2 componentes

Depois do eDocEngine concluído:

1. **DocumentStudio** — packages atualmente *sem* sufixo `D<XX>` (`gtxDocumentStudioCore.dpk` etc.). Plano separado vai exigir renomear filenames além de duplicar. Esquema FMX+VCL multiplica contagem.
2. **PDFtoolkit VCL** — múltiplos `.dpk` por Delphi com **esquema legado** (`D10`/`D101`/`D11`/`D12`/`D13` + `BDS2006`/`D2005`/`D2007`/`D2009`/`DXE..DXE5`). Plano vai exigir remapear esquema legado para `D24..D37` e decidir se mantém alias ou apaga o antigo. Tem que cuidar do `Shared/PdfProcessor/` separado do `Shared3/`.

Cada um terá seu próprio `<slug>_v1.0.plan.md` em `.claude/plans/`. Reaproveitar `Generate-DXXSet.ps1` parametrizando o template path.

---

## Changelog do plano

- **v1.1 (2026-05-20, rev. 3)** — *Status final da execução*: marcado como `partial-complete`. Adicionada seção "Status de execução" com tabela por sufixo. Adicionada lista completa dos **14 problemas encontrados** durante execução (link para issues report). Adicionadas **8 suposições do plano que se revelaram falsas**. Documentadas as **3 pendências (D24/D25/D26)** com bloqueio claro, esforço estimado, e procedimento de retomada. Convenção `bpi/hpp/obj/lib` removida (Opção 3 — só Delphi outputs). Patches vendor aplicados documentados (gtCstSpdEng.pas + Win64x→Win64).
- **v1.1 (2026-05-20, rev. 2)**: consolidação `eDocEngine/packages/` adicionada — todos `.dpk`/`.dproj`/`.groupproj` se movem para uma pasta flat na raiz do componente. `<LibRelative>` agora uniforme (`..\Lib`). `<DCC_UnitSearchPath>` recalculado per-pacote para apontar de volta a `..\Source\<sub>` e `..\..\Shared3\Source\<sub>`. Groupprojs usam `<Projects Include=".\<file>.dproj">`. Script renomeado `Patch-D29Outputs.ps1` → `Migrate-D29ToPackages.ps1` (agora move + reescreve). Fase 0.7 nova: criar pasta. Fase 1 reestruturada em 7 subfases (1.1..1.7). DoD ampliado para 8 itens. R13 novo. Build commands apontam para `eDocEngine\packages\*.groupproj` em vez de `eDocEngine\Source\*.groupproj`.
- **v1.1 (2026-05-20)**: revisão completa fechando lacunas — git init obrigatório, scripts especificados por completo (3 PS1), encoding UTF-8 BOM tratado, substituições contextuais detalhadas, rollback explícito com/sem git, contagem corrigida (21 não 20), tabela de tokens centralizada, DoD formal, riscos R6..R12 adicionados, cronograma, decisões pré-Fase-1. ProjectVersion alinhada a BDS major.
- **v1.0 (2026-05-20)**: versão inicial — estrutura 4 fases + inventário + riscos R1..R6.
