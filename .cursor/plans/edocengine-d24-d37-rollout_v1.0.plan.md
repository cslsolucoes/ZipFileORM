---
plan: edocengine-d24-d37-rollout
version: 1.0
component: eDocEngine
status: DEPRECATED
deprecatedOn: 2026-05-20
supersededBy: edocengine-d24-d37-rollout_v1.1.plan.md
---

# ⚠ DEPRECATED — usar v1.1

Este arquivo foi substituído por **[edocengine-d24-d37-rollout_v1.1.plan.md](edocengine-d24-d37-rollout_v1.1.plan.md)**.

## Motivos da substituição

- Contagem de pacotes errada (`20` em vez de `21` — faltava contar runtime ou design-time)
- Coluna **BDS major** com valor `24.0` para Delphi 13 Florence — correto é `37.0` (Embarcadero unificou pasta de instalação com `CompilerVersion` a partir do Delphi 13)
- Coluna **`ProjectVersion`** com valores históricos confusos — alinhada a `BDS major` em v1.1
- Substituição "D29 → D<XX>" cega (sem regex contextual) — quebraria literais Pascal e XML
- `{$LIBSUFFIX}` / `<DllSuffix>` / `<TargetName>` esquecidos
- Encoding UTF-8 BOM dos `.dproj` não tratado — PowerShell pode corromper na escrita
- Idempotência declarada na Fase 4 conflitava com "falha se existir" na Fase 2.1
- Ativação do `rsvars.bat` por Delphi não documentada — `msbuild` sem isso não acha o IDE
- Sem procedimento de rollback explícito (git init / restore via snapshot)
- Sem **Definition of Done** formal
- Sem cronograma estimado

**Não edite este arquivo.** Apague-o quando conveniente (o `.claude/settings.json` bloqueia `del/rm` por default — fazer manualmente).
