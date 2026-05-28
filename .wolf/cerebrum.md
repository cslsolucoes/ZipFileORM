# Cerebrum â€” zipfile project

> Persistent learnings, conventions, and decisions for the zipfile project.
> Updated continuously by Claude/AI assistants between sessions.

## User Preferences

- **Build system:** sempre usar `dcc32.exe`/`dcc64.exe` direto do `$(BDS)\bin\`, NUNCA `msbuild` (vide CLAUDE.md). msbuild trunca paths longos em erros e ignora `<DCC_*Output>` quando `BDSCOMMONDIR` estÃ¡ no env.
- **Output paths:** Delphi DCU/DCP/BPL/BPI/HPP â†’ `Lib/RAD<MM>/Win{32,64}/`. FPC PPU/.o â†’ `Lib/FPC/Win{32,64}/`. Vide `.dproj` e `.lpk` para detalhes.
- **Palette:** componentes registrados na aba `ZipFileORM` (nÃ£o `Misc` ou `Gnostice ZipFile`).
- **Unit naming:** units de componente sem prefixo namespace (`TarFile`, `CabFile`, `SevenZFile`, etc. â€” alinhado a `ZipFile` histÃ³rico). Units internos podem ter namespace (`ZipFile.Progress`, `Tar.GzipStream`, `Archive.Open`).
- **Property categories:** registrar via `RegisterPropertyInCategory` no `zipfileReg.pas` para Object Inspector "Arrange by Category".
- **Icons:** uniform style â€” gradient + rounded + gloss + sigla (vide Â§16.6 do SPEC). NÃƒO usar logos trademarked (WinRAR/WinZip/7-Zip official) â€” IP risk.
- **Property surface:** declarar PRIMEIRO (mesmo sem behavior wired), implementar depois â€” permite que consumidores subscrevam handlers/properties sem esperar release.

## Key Learnings

### Build system
- **brcc32 BMP rejection:** `System.Drawing.Bitmap.Save` produz BMP v4/v5 (BITMAPINFOHEADER 108 bytes). brcc32 sÃ³ aceita BMP v3 puro (40 bytes). Workaround: helper `Save-Bmp24v3` em PowerShell escreve header manualmente. Vide `tools/Generate-Icons.ps1` (TODO criar).
- **PowerShell `$var:` parser:** `Write-Host "D$xx:" -NoNewline` falha â€” `:` interpretado como drive separator. Usar `("D{0}:" -f $xx)` format-string.
- **PowerShell `2>&1`:** com native exes (`dcc32`, `bcc32c`), PS 5.1 envolve cada linha stderr em ErrorRecord e seta `$?=$false` mesmo com exit code 0. Usar `$LASTEXITCODE` explicitamente.
- **Delphi 12+ design-time Ã© 64-bit:** D29+ tem `bds.exe` e `bds64.exe`. Design BPLs Win64 sÃ£o Ãºteis e precisam ser deployadas em `BDSCOMMONDIR\Bpl\Win64\`. PrÃ©-D29 (`designide` Ã© Win32-only), sÃ³ design Win32 funciona.
- **Deploy obrigatÃ³rio para `BDSCOMMONDIR\Bpl[\Win64]\`** apÃ³s build â€” sem isso, IDE nÃ£o acha runtime BPL na hora de carregar design BPL. Erro tÃ­pico: "NÃ£o foi possÃ­vel encontrar o mÃ³dulo especificado" em Install Packages.

### IOTA / IDE integration
- **`BorlandIDEServices` Ã© nil durante init de design package:** doc IOTA explÃ­cita â€” `IOTASplashScreenServices` Ã© o PRIMEIRO serviÃ§o disponÃ­vel, antes de `BorlandIDEServices`. Use a global `SplashScreenServices` direto, NÃƒO `Supports(BorlandIDEServices, IOTASplashScreenServices, ...)`.
- **Splash bitmap convention:** 24x24 com pixel transparente no **lower-left** (`(0, Height-1)`), nÃ£o upper-left.
- **About box:** registra DEPOIS â€” `BorlandIDEServices` jÃ¡ estÃ¡ pronto. Caminho usual `Supports(BorlandIDEServices, IOTAAboutBoxServices, ...)`.

### Wikimedia / external resources
- **Wikimedia thumbnails:** apenas tamanhos especÃ­ficos funcionam (120, 250, 500). Outros (240, 480, 640) retornam HTTP 400. Sempre testar antes.
- **User-Agent obrigatÃ³rio:** Wikimedia bloqueia requests sem UA. Use `"projeto-x/1.0 contact@email"` formato.
- **Trademark vs Copyright:** CC0/Public Domain logos (7-Zip, Gzip) sÃ£o livres de copyright mas marcas continuam protegidas. NÃƒO embed sem considerar trademark risk.
- **SHGetFileInfo armadilha:** se o usuÃ¡rio tem WinRAR instalado, ele registra-se como handler de TODOS os formatos (.zip/.7z/.tar/.gz/.cab/.arj/.lha/.iso/.rar). Resultado: extrair file-association icons retorna sempre o mesmo Ã­cone WinRAR â€” trademark infringement se embed.

### Components
- **`EntryCount: Integer`** declarado como `function` originalmente, depois renomeado para `GetEntryCount` (protected) + `property EntryCount: Integer read GetEntryCount;` (published). Delphi syntax `obj.EntryCount` funciona idÃªntico para funÃ§Ã£o sem args E property â†’ ZERO breakage em consumers (testes existentes em smoke_*.pas continuam OK).
- **Events declarados em unit comum `ZipFile.Events.pas`:** evita N redeclaraÃ§Ãµes idÃªnticas de `TArchiveLifecycleQueryEvent` etc. em 10 arquivos.

### Cross-platform
- **`{$IFDEF FPC} {$mode delphi}{$H+} {$ENDIF}` no topo:** padrÃ£o obrigatÃ³rio para units que devem compilar Delphi+FPC.
- **`uses` clause:** `{$IFNDEF FPC}System.ZLib{$ELSE}ZStream{$ENDIF}` para zlib cross. Delphi usa `System.ZLib`, FPC usa `ZStream`.

## Do-Not-Repeat

| Date | Mistake | Fix |
| --- | --- | --- |
| 2026-05-27 | Tentei embedar WinRAR.exe icon via SHGetFileInfo achando que era "Windows native" | Verificar registry HKCR antes â€” se progid contÃ©m "WinRAR" Ã© trademark, nÃ£o Windows |
| 2026-05-27 | Tentei `msbuild` para `.dpk` | Use `dcc32`/`dcc64` direto com `-LE`/`-LN`/`-N`. msbuild trunca paths em erro |
| 2026-05-27 | `System.Drawing.Bitmap.Save(BMP)` para usar com brcc32 | Bitmap salvo Ã© v4. Escrever BMP v3 manualmente |
| 2026-05-27 | Tentei `-foZipfile.dcr` com brcc32 em PowerShell pure | Sintaxe `-fo` em PS Ã© problemÃ¡tica. Usar via Bash ou aspas: `& brcc -fo"Zipfile.dcr" zipfile.rc` |
| 2026-05-27 | Tentei rebuildar BPL com IDE aberto | RAD Studio locka BPL deployada. Fechar IDE antes de rebuild+redeploy |

## Decision Log

| Date | Decision | Rationale |
| --- | --- | --- |
| 2026-05-27 | Palette `ZipFileORM` (nÃ£o `Misc` original ou `Gnostice ZipFile`) | Branded mas neutral, fÃ¡cil de buscar no Object Inspector |
| 2026-05-27 | Property surface explosion (22 â†’ ~248) antes do behavior wiring | Estabiliza API; behavior incremental por release; consumidores nÃ£o precisam esperar |
| 2026-05-27 | Uniform icon style (gradient+rounded+gloss+text) para todos os 10 | CoerÃªncia visual + zero IP risk |
| 2026-05-27 | TGzipFile como componente novo (single-file gzip) | Separar do TTarGzFile (tar+gz combo). Use cases diferentes |
| 2026-05-27 | Rename units sem namespace prefix (Tar.TarFile â†’ TarFile etc.) | Alinhar com `ZipFile` histÃ³rico; coerÃªncia |
| 2026-05-27 | Multi-IDE D24..D37 rollout completo (49 BPLs) | Suporte amplo Delphi 10.1 Berlin â†’ Delphi 13 Florence |
| 2026-05-27 | Eventos em `ZipFile.Events.pas` compartilhado | Evita duplicaÃ§Ã£o de tipos em 10 components |
| 2026-05-27 | Cleanup Lib/ build artifacts | Build artifacts regenerÃ¡veis. Lib/ Ã© cache local, nÃ£o fonte. BPLs deployadas em BDSCOMMONDIR continuam intactas |
