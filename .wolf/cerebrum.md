# Cerebrum — zipfile project

> Persistent learnings, conventions, and decisions for the zipfile project.
> Updated continuously by Claude/AI assistants between sessions.

## User Preferences

- **Build system:** sempre usar `dcc32.exe`/`dcc64.exe` direto do `$(BDS)\bin\`, NUNCA `msbuild` (vide CLAUDE.md). msbuild trunca paths longos em erros e ignora `<DCC_*Output>` quando `BDSCOMMONDIR` está no env.
- **Output paths:** Delphi DCU/DCP/BPL/BPI/HPP → `Lib/RAD<MM>/Win{32,64}/`. FPC PPU/.o → `Lib/FPC/Win{32,64}/`. Vide `.dproj` e `.lpk` para detalhes.
- **Palette:** componentes registrados na aba `ZipCompress` (não `Misc` ou `Gnostice ZipFile`).
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

## Do-Not-Repeat

| Date | Mistake | Fix |
| --- | --- | --- |
| 2026-05-27 | Tentei embedar WinRAR.exe icon via SHGetFileInfo achando que era "Windows native" | Verificar registry HKCR antes — se progid contém "WinRAR" é trademark, não Windows |
| 2026-05-27 | Tentei `msbuild` para `.dpk` | Use `dcc32`/`dcc64` direto com `-LE`/`-LN`/`-N`. msbuild trunca paths em erro |
| 2026-05-27 | `System.Drawing.Bitmap.Save(BMP)` para usar com brcc32 | Bitmap salvo é v4. Escrever BMP v3 manualmente |
| 2026-05-27 | Tentei `-foZipfile.dcr` com brcc32 em PowerShell pure | Sintaxe `-fo` em PS é problemática. Usar via Bash ou aspas: `& brcc -fo"Zipfile.dcr" zipfile.rc` |
| 2026-05-27 | Tentei rebuildar BPL com IDE aberto | RAD Studio locka BPL deployada. Fechar IDE antes de rebuild+redeploy |

## Decision Log

| Date | Decision | Rationale |
| --- | --- | --- |
| 2026-05-27 | Palette `ZipCompress` (não `Misc` original ou `Gnostice ZipFile`) | Branded mas neutral, fácil de buscar no Object Inspector |
| 2026-05-27 | Property surface explosion (22 → ~248) antes do behavior wiring | Estabiliza API; behavior incremental por release; consumidores não precisam esperar |
| 2026-05-27 | Uniform icon style (gradient+rounded+gloss+text) para todos os 10 | Coerência visual + zero IP risk |
| 2026-05-27 | TGzipFile como componente novo (single-file gzip) | Separar do TTarGzFile (tar+gz combo). Use cases diferentes |
| 2026-05-27 | Rename units sem namespace prefix (Tar.TarFile → TarFile etc.) | Alinhar com `ZipFile` histórico; coerência |
| 2026-05-27 | Multi-IDE D24..D37 rollout completo (49 BPLs) | Suporte amplo Delphi 10.1 Berlin → Delphi 13 Florence |
| 2026-05-27 | Eventos em `ZipFile.Events.pas` compartilhado | Evita duplicação de tipos em 10 components |
| 2026-05-27 | Cleanup Lib/ build artifacts | Build artifacts regeneráveis. Lib/ é cache local, não fonte. BPLs deployadas em BDSCOMMONDIR continuam intactas |
