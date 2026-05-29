#requires -Version 5.1
<#
.SYNOPSIS
  Converte um PNG (qualquer tamanho/RGBA) em BMP v3 24x24 24-bit no formato
  esperado pela API IOTASplashScreenServices.AddPluginBitmap do RAD Studio.

.DESCRIPTION
  Pipeline:
    1. Carrega PNG via System.Drawing.Image.FromFile (alpha preservado).
    2. Cria canvas 24x24 com fundo do brand color (red BBGGRR $002030C8 default).
    3. Resize HighQualityBicubic com PixelOffsetMode=HighQuality (sharpen leve).
    4. Composita PNG sobre canvas (alpha-blend correto via DrawImage).
    5. Marca pixel (0, 23) com magenta $FF00FF (convenção splash transparency key).
    6. Escreve BMP v3 manualmente (BITMAPINFOHEADER 40 bytes — brcc32 rejeita
       BMP v4/v5 produzidos por System.Drawing.Bitmap.Save default; vide
       bug-zf-002 em .wolf/buglog.json).

  Pixel data: BGR bottom-up, padding 4-byte por linha.

.PARAMETER Source
  Caminho do PNG de entrada. Default: packages\ZipFileORM.png

.PARAMETER Destination
  Caminho do BMP de saida. Default: packages\ZipFileORM.bmp

.PARAMETER BackgroundColor
  Cor de fundo do canvas 24x24 (formato 0xRRGGBB). Default $C83020 (red brand).
  Use $00FFFFFF para branco, $00000000 para preto, etc.

.PARAMETER Size
  Tamanho do BMP de saida. Default 24 (convencao splash). Para about-box
  pode usar 48.

.PARAMETER NoTransparentCorner
  Se setado, NAO marca pixel (0, Size-1) como magenta. Util para about box
  que nao usa pixel-key transparency.

.EXAMPLE
  pwsh -File tools\Convert-PngToSplashBmp.ps1
  # Converte packages\ZipFileORM.png -> packages\ZipFileORM.bmp 24x24

.EXAMPLE
  pwsh -File tools\Convert-PngToSplashBmp.ps1 -Size 48 -NoTransparentCorner -Destination packages\ZipFileORM-about.bmp
  # 48x48 BMP para about box (sem pixel key)
#>
[CmdletBinding()]
param(
  [string] $Source = '',
  [string] $Destination = '',
  [int]    $BackgroundColor = 0xC83020,  # red brand (RGB)
  [int]    $Size = 24,
  [switch] $NoTransparentCorner
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrEmpty($Source))      { $Source      = Join-Path $root 'packages\ZipFileORM.png' }
if ([string]::IsNullOrEmpty($Destination)) { $Destination = Join-Path $root 'packages\ZipFileORM.bmp' }

if (-not (Test-Path -LiteralPath $Source)) {
  throw "Source PNG not found: $Source"
}

Add-Type -AssemblyName System.Drawing

Write-Host ("Source:      " + $Source) -ForegroundColor Cyan
Write-Host ("Destination: " + $Destination) -ForegroundColor Cyan
Write-Host ("Size:        ${Size}x${Size}") -ForegroundColor Cyan
Write-Host ("Background:  0x{0:X6}" -f $BackgroundColor) -ForegroundColor Cyan

# --- 1. Load PNG ---
$src = [System.Drawing.Image]::FromFile($Source)
Write-Host ("[1/6] Loaded PNG: {0}x{1} {2}" -f $src.Width, $src.Height, $src.PixelFormat)

try {
  # --- 2. Create 24bpp canvas at target size with brand background ---
  $bmp = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
  $gfx = [System.Drawing.Graphics]::FromImage($bmp)
  try {
    $gfx.CompositingQuality     = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $gfx.InterpolationMode      = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $gfx.SmoothingMode          = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $gfx.PixelOffsetMode        = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $gfx.CompositingMode        = [System.Drawing.Drawing2D.CompositingMode]::SourceOver

    # Background
    $bg = [System.Drawing.Color]::FromArgb(
      ($BackgroundColor -shr 16) -band 0xFF,
      ($BackgroundColor -shr  8) -band 0xFF,
       $BackgroundColor          -band 0xFF
    )
    $brush = New-Object System.Drawing.SolidBrush($bg)
    $gfx.FillRectangle($brush, 0, 0, $Size, $Size)
    $brush.Dispose()
    Write-Host "[2/6] Canvas filled with brand background"

    # --- 3+4. Resize + composite (alpha-blend over background) ---
    $dstRect = New-Object System.Drawing.Rectangle(0, 0, $Size, $Size)
    $gfx.DrawImage($src, $dstRect, 0, 0, $src.Width, $src.Height, [System.Drawing.GraphicsUnit]::Pixel)
    Write-Host "[3-4/6] Resized + composited with HighQualityBicubic"

    $gfx.Flush()
  } finally {
    $gfx.Dispose()
  }

  # --- 5. Mark transparent corner ---
  if (-not $NoTransparentCorner) {
    $magenta = [System.Drawing.Color]::FromArgb(255, 0, 255)
    $bmp.SetPixel(0, $Size - 1, $magenta)
    Write-Host "[5/6] Transparent corner marker set at (0, $($Size - 1)) = magenta"
  } else {
    Write-Host "[5/6] Transparent corner skipped (-NoTransparentCorner)"
  }

  # --- 6. Manual BMP v3 write (40-byte BITMAPINFOHEADER) ---
  # Pixel data: BGR bottom-up, row-aligned to 4 bytes.
  $rowBytesUnpadded = $Size * 3
  $rowPad = (4 - ($rowBytesUnpadded % 4)) % 4
  $rowBytesPadded = $rowBytesUnpadded + $rowPad
  $pixelBytes = $rowBytesPadded * $Size
  $fileSize = 14 + 40 + $pixelBytes  # FH(14) + IH(40) + pixels

  # Extract pixel data from $bmp (top-down ARGB) and convert to bottom-up BGR
  $pixels = New-Object byte[] $pixelBytes
  for ($y = 0; $y -lt $Size; $y++) {
    $srcRow = $y
    $dstRow = $Size - 1 - $y  # bottom-up
    $rowOffset = $dstRow * $rowBytesPadded
    for ($x = 0; $x -lt $Size; $x++) {
      $c = $bmp.GetPixel($x, $srcRow)
      $byteIdx = $rowOffset + $x * 3
      $pixels[$byteIdx]     = $c.B
      $pixels[$byteIdx + 1] = $c.G
      $pixels[$byteIdx + 2] = $c.R
    }
    # padding bytes are already zero from New-Object
  }

  $fs = [System.IO.File]::Open($Destination, [System.IO.FileMode]::Create)
  $bw = New-Object System.IO.BinaryWriter($fs)
  try {
    # BITMAPFILEHEADER (14 bytes)
    $bw.Write([byte]0x42); $bw.Write([byte]0x4D)         # 'BM'
    $bw.Write([uint32]$fileSize)                          # bfSize
    $bw.Write([uint16]0); $bw.Write([uint16]0)            # bfReserved1+2
    $bw.Write([uint32](14 + 40))                          # bfOffBits = 54

    # BITMAPINFOHEADER (40 bytes — v3 ONLY; brcc32 requires this size)
    $bw.Write([uint32]40)                                 # biSize
    $bw.Write([int32]$Size)                               # biWidth
    $bw.Write([int32]$Size)                               # biHeight (positive = bottom-up)
    $bw.Write([uint16]1)                                  # biPlanes
    $bw.Write([uint16]24)                                 # biBitCount
    $bw.Write([uint32]0)                                  # biCompression = BI_RGB
    $bw.Write([uint32]$pixelBytes)                        # biSizeImage
    $bw.Write([int32]2835)                                # biXPelsPerMeter (~72 DPI)
    $bw.Write([int32]2835)                                # biYPelsPerMeter
    $bw.Write([uint32]0)                                  # biClrUsed
    $bw.Write([uint32]0)                                  # biClrImportant

    # Pixel data
    $bw.Write($pixels)
  } finally {
    $bw.Dispose()
    $fs.Dispose()
  }
  Write-Host "[6/6] BMP v3 written (40-byte BITMAPINFOHEADER, BGR bottom-up)"

  $finalSize = (Get-Item -LiteralPath $Destination).Length
  Write-Host ""
  Write-Host ("OK. {0} ({1} bytes)" -f $Destination, $finalSize) -ForegroundColor Green
} finally {
  $bmp.Dispose()
  $src.Dispose()
}
