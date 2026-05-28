# Component Icon Sources — Credits

Os ícones em `packages/icons/` são uma mistura de:

## Imagens de domínio público / CC0 (sem restrição)

Origem: Wikimedia Commons. Embora CC0/PD dispensem atribuição legal, registramos
as fontes por boa-fé.

| Ícone componente | Fonte | Licença | URL |
|---|---|---|---|
| `TSEVENZFILE.bmp` | `7-Zip_Icon.svg` | CC0 1.0 Universal | <https://commons.wikimedia.org/wiki/File:7-Zip_Icon.svg> |
| `TGZIPFILE.bmp` | `Gzip-Logo.svg` | Public Domain (below threshold of originality) | <https://commons.wikimedia.org/wiki/File:Gzip-Logo.svg> |

Arquivos SVG originais preservados em `source/` (não compilados nas BPLs).
Wikimedia thumbnails 120px baixados (`*_120.png`) e reduzidos para 24×24 BMP via
PowerShell + System.Drawing.

**Trademark notice:** "7-Zip" é trademark de Igor Pavlov; "gzip" é projeto do
GNU Project. Os logos visuais são de domínio público em copyright (geometric
shapes / text below threshold of originality), mas os nomes/marcas continuam
protegidos. Este uso é puramente identificador (etiqueta visual do componente
correspondente ao formato de arquivo) — não implica afiliação, endosso ou
parceria com Igor Pavlov ou GNU Project.

## Ícones gerados originalmente para este projeto

Os 8 ícones restantes (`TZIPFILE`, `TTARFILE`, `TTARGZFILE`, `TCABFILE`,
`TARJFILE`, `TISOFILE`, `TLHAFILE`, `TRARFILE`) foram **gerados programaticamente**
via PowerShell + System.Drawing.Drawing2D (gradiente vertical + cantos
arredondados + sigla branca Segoe UI Bold). Sem reprodução de marcas de
terceiros — design original do projeto Gnostice/ZipFileORM.

Decisão de não usar logos oficiais para esses formatos:

- **RAR**: trademark RARLAB — uso poderia sugerir afiliação não-existente
- **TAR/Tar.gz**: único SVG disponível em Wikimedia (`Tar_gz_archive_icon.svg`)
  é licenciado GPL v2 — embedding contaminaria o pacote inteiro com licença viral
- **CAB/ARJ/LHA/ISO**: sem logo oficial distintivo; ícone genérico estilizado eh
  mais informativo
- **ZIP**: sem logo oficial; "ZIP" é genérico formato

## Pipeline de regeneração

```powershell
# (1) Baixar PD source SVGs
Invoke-WebRequest -Uri 'https://upload.wikimedia.org/wikipedia/commons/...' \
  -UserAgent 'ZipFileORM-icon-fetch contact@cslsoftwares.com.br'

# (2) Resize PNG 120px → 24×24 BMP v3
.\tools\Generate-IconBmps.ps1  # System.Drawing.Bitmap + HighQualityBicubic

# (3) Compile DCR
brcc32 -foZipfile.dcr ZipFileORM.rc

# (4) Rebuild dcl BPL
dcc32 -Q -B dclZipFileORMD<XX>.dpk
```

## Compatibility / Display

- BMP format: 24bpp, BMP v3 (BITMAPINFOHEADER 40 bytes — brcc32-compatible)
- Magenta pixel `$00FF00FF` no canto inferior-esquerdo (`(0, 23)`) é a convenção
  de Delphi component bitmap transparency.
- Render no Tool Palette / Object Inspector / Form Designer.
