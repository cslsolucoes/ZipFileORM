# Cerebrum — zipfile project

> Persistent learnings, conventions, and decisions for the zipfile project.
> Updated continuously by Claude/AI assistants between sessions.

## User Preferences

- **Build system:** sempre usar `dcc32.exe`/`dcc64.exe` direto do `$(BDS)\bin\`, NUNCA `msbuild` (vide CLAUDE.md). msbuild trunca paths longos em erros e ignora `<DCC_*Output>` quando `BDSCOMMONDIR` está no env.
- **Output paths:** Delphi DCU/DCP/BPL/BPI/HPP → `Lib/RAD<MM>/Win{32,64}/`. FPC PPU/.o → `Lib/FPC/Win{32,64}/`. Vide `.dproj` e `.lpk` para detalhes.
- **Palette:** componentes registrados na aba `ZipFileORM` (não `Misc` ou `Gnostice ZipFile`).
- **Unit naming:** units de componente sem prefixo namespace (`TarFile`, `CabFile`, `SevenZFile`, etc. — alinhado a `ZipFile` histórico). Units internos podem ter namespace (`ZipFile.Progress`, `Tar.GzipStream`, `Archive.Open`).
- **Property categories:** registrar via `RegisterPropertyInCategory` no `zipfileReg.pas` para Object Inspector "Arrange by Category".
- **Icons:** uniform style — gradient + rounded + gloss + sigla (vide §16.6 do SPEC). NÃO usar logos trademarked (WinRAR/WinZip/7-Zip official) — IP risk.
- **Property surface:** declarar PRIMEIRO (mesmo sem behavior wired), implementar depois — permite que consumidores subscrevam handlers/properties sem esperar release.

## Key Learnings

### Build system
- **brcc32 BMP rejection:** `System.Drawing.Bitmap.Save` produz BMP v4/v5 (BITMAPINFOHEADER 108 bytes). brcc32 só aceita BMP v3 puro (40 bytes). Workaround: helper `Save-Bmp24v3` em PowerShell escreve header manualmente. Vide `tools/Generate-Icons.ps1` (TODO criar).
- **PowerShell `$var:` parser:** `Write-Host "D$xx:" -NoNewline` falha — `:` interpretado como drive separator. Usar `("D{0}:" -f $xx)` format-string.
- **PowerShell `2>&1`:** com native exes (`dcc32`, `bcc32c`), PS 5.1 envolve cada linha stderr em ErrorRecord e seta `$?=$false` mesmo com exit code 0. Usar `$LASTEXITCODE` explicitamente.
- **Delphi 12+ design-time é 64-bit:** D29+ tem `bds.exe` e `bds64.exe`. Design BPLs Win64 são úteis e precisam ser deployadas em `BDSCOMMONDIR\Bpl\Win64\`. Pré-D29 (`designide` é Win32-only), só design Win32 funciona.
- **Deploy obrigatório para `BDSCOMMONDIR\Bpl[\Win64]\`** após build — sem isso, IDE não acha runtime BPL na hora de carregar design BPL. Erro típico: "Não foi possível encontrar o módulo especificado" em Install Packages.

### IOTA / IDE integration
- **`BorlandIDEServices` é nil durante init de design package:** doc IOTA explícita — `IOTASplashScreenServices` é o PRIMEIRO serviço disponível, antes de `BorlandIDEServices`. Use a global `SplashScreenServices` direto, NÃO `Supports(BorlandIDEServices, IOTASplashScreenServices, ...)`.
- **Splash bitmap convention:** 24x24 com pixel transparente no **lower-left** (`(0, Height-1)`), não upper-left.
- **About box:** registra DEPOIS — `BorlandIDEServices` já está pronto. Caminho usual `Supports(BorlandIDEServices, IOTAAboutBoxServices, ...)`.

### Wikimedia / external resources
- **Wikimedia thumbnails:** apenas tamanhos específicos funcionam (120, 250, 500). Outros (240, 480, 640) retornam HTTP 400. Sempre testar antes.
- **User-Agent obrigatório:** Wikimedia bloqueia requests sem UA. Use `"projeto-x/1.0 contact@email"` formato.
- **Trademark vs Copyright:** CC0/Public Domain logos (7-Zip, Gzip) são livres de copyright mas marcas continuam protegidas. NÃO embed sem considerar trademark risk.
- **SHGetFileInfo armadilha:** se o usuário tem WinRAR instalado, ele registra-se como handler de TODOS os formatos (.zip/.7z/.tar/.gz/.cab/.arj/.lha/.iso/.rar). Resultado: extrair file-association icons retorna sempre o mesmo ícone WinRAR — trademark infringement se embed.

### Components
- **`EntryCount: Integer`** declarado como `function` originalmente, depois renomeado para `GetEntryCount` (protected) + `property EntryCount: Integer read GetEntryCount;` (published). Delphi syntax `obj.EntryCount` funciona idêntico para função sem args E property → ZERO breakage em consumers (testes existentes em smoke_*.pas continuam OK).
- **Events declarados em unit comum `ZipFile.Events.pas`:** evita N redeclarações idênticas de `TArchiveLifecycleQueryEvent` etc. em 10 arquivos.

### Cross-platform
- **`{$IFDEF FPC} {$mode delphi}{$H+} {$ENDIF}` no topo:** padrão obrigatório para units que devem compilar Delphi+FPC.
- **`uses` clause:** `{$IFNDEF FPC}System.ZLib{$ELSE}ZStream{$ENDIF}` para zlib cross. Delphi usa `System.ZLib`, FPC usa `ZStream`.

### Text encoding & file headers
- **Mojibake detection signatures** (UTF-8 double-encoding): bytes `C3 83 C2 XX` (Latin-1 letters Ã§/Ã£/Ã¡/...), `C3 A2 E2 82 AC E2 80 9D` (em-dash —), `C3 A2 E2 80 A0 E2 80 99` (right arrow →). Scan files for these as canary; ASCII-only replaces preserve mojibake silently.
- **Mojibake fix strategy** (reverse round-trip): (1) read bytes, (2) strip leading BOM if present, (3) decode UTF-8 → .NET string, (4) re-encode as Windows-1252 with `EncoderExceptionFallback`, (5) validate result as strict UTF-8 (`DecoderExceptionFallback`), (6) write bytes. The validation step catches false positives where the file already has legitimate uppercase 'Ã' in Portuguese words like "NÃO" — those produce invalid UTF-8 when reverse-encoded and abort safely.
- **PowerShell `Get-ChildItem -LiteralPath -Include`:** `-Include` is IGNORED when `-LiteralPath` is used (only works with `-Path` + wildcard). Result: filter silently fails and recursion pulls in all files including binaries (DCU/EXE/PPU). Use `-Path` with wildcard OR explicit file extension filtering after `Get-ChildItem`.
- **BOM policy:** src/*.pas normalized to **no-BOM** (more diff-friendly, dcc32 and FPC accept both). Mixed BOM in same tree pollutes diffs. Decision applied in commit `4f36592a`.
- **Pascal source header rule scope:** `backend-pascal-source-header_V1.0.0` §11 — "para fontes existentes, aplicar apenas quando o arquivo for tocado na tarefa atual — NÃO fazer varredura retroativa". Header retrofits são incrementais, não bulk.

## Do-Not-Repeat

| Date | Mistake | Fix |
| --- | --- | --- |
| 2026-05-27 | Tentei embedar WinRAR.exe icon via SHGetFileInfo achando que era "Windows native" | Verificar registry HKCR antes — se progid contém "WinRAR" é trademark, não Windows |
| 2026-05-27 | Tentei `msbuild` para `.dpk` | Use `dcc32`/`dcc64` direto com `-LE`/`-LN`/`-N`. msbuild trunca paths em erro |
| 2026-05-27 | `System.Drawing.Bitmap.Save(BMP)` para usar com brcc32 | Bitmap salvo é v4. Escrever BMP v3 manualmente |
| 2026-05-27 | Tentei `-foZipFile.dcr` com brcc32 em PowerShell pure | Sintaxe `-fo` em PS é problemática. Usar via Bash ou aspas: `& brcc -fo"ZipFile.dcr" zipfile.rc` |
| 2026-05-27 | Tentei rebuildar BPL com IDE aberto | RAD Studio locka BPL deployada. Fechar IDE antes de rebuild+redeploy |
| 2026-05-28 | Bulk replace ASCII-only (`Zipfile` → `ZipFile`) em arquivos com mojibake pré-existente — não tocou os bytes corrompidos, propagou o estado quebrado para o commit | Antes de qualquer bulk-replace, scan o tree por mojibake signatures (`C3 83 C2`, `C3 A2 E2 82 AC`); corrija ANTES do replace funcional |
| 2026-05-28 | `Get-ChildItem -LiteralPath -Include '*.dpk'` recursou e pegou .dcu/.exe/.ppu também — `-Include` foi silenciosamente ignorado, bulk replace atingiu binários | Usar `-Path` + wildcard (`Path 'packages\*' -Include '*.dpk'`) OU filtrar via pipeline `Where-Object { $_.Extension -in '.pas','.dpk' }` |
| 2026-05-28 | Assumir BOM uniforme no tree (21/40 src tinham BOM, 19/40 não) — sem padrão | Política explícita: src/ é **no-BOM**. Scripts de geração devem usar `[System.Text.UTF8Encoding]::new($false)` |

## Decision Log

| Date | Decision | Rationale |
| --- | --- | --- |
| 2026-05-27 | Palette `ZipFileORM` (não `Misc` original ou `Gnostice ZipFile`) | Branded mas neutral, fácil de buscar no Object Inspector |
| 2026-05-27 | Property surface explosion (22 → ~248) antes do behavior wiring | Estabiliza API; behavior incremental por release; consumidores não precisam esperar |
| 2026-05-27 | Uniform icon style (gradient+rounded+gloss+text) para todos os 10 | Coerência visual + zero IP risk |
| 2026-05-27 | TGzipFile como componente novo (single-file gzip) | Separar do TTarGzFile (tar+gz combo). Use cases diferentes |
| 2026-05-27 | Rename units sem namespace prefix (Tar.TarFile → TarFile etc.) | Alinhar com `ZipFile` histórico; coerência |
| 2026-05-27 | Multi-IDE D24..D37 rollout completo (49 BPLs) | Suporte amplo Delphi 10.1 Berlin → Delphi 13 Florence |
| 2026-05-27 | Eventos em `ZipFile.Events.pas` compartilhado | Evita duplicação de tipos em 10 components |
| 2026-05-27 | Cleanup Lib/ build artifacts | Build artifacts regeneráveis. Lib/ é cache local, não fonte. BPLs deployadas em BDSCOMMONDIR continuam intactas |
| 2026-05-28 | Facade namespace normalizado para `ZipFileORM` (F maiúsculo) — alinha repo/packages/dproj/tag; 4 facade units renomeadas no src/ | Inconsistência detectada após a migração v3→v4; capital-F era o canônico no resto do projeto. Diff: 4 case-only renames (via two-step git mv no Windows) + 323 replaces em 67 arquivos. Commit `eafdae68` |
| 2026-05-28 | `.gitignore` ganhou exceção `!Library/**/*.o` + `!Library/**/*.a` | Regra `*.o` (FPC artifacts) estava ocultando 109 .obj/.o vendored em `Library/{delphi-win64,fpc-win32,fpc-win64}/`. Só `delphi-win32` passava porque usa `.obj`. Commit `62f9fa3f` |
| 2026-05-28 | src/*.pas normalizado para **no-BOM** + mojibake fix nos headers (17 src + 1 packages) + 6 stale names sincronizados | Higiene de tree pós-migração. Build verificado idêntico (437060 bytes code) — só comentários. Commit `4f36592a` |
