#requires -Version 5.1
<#
.SYNOPSIS
  Convert Lazarus XPM resource to Delphi .dcr (Delphi Component Resource).
  Parses XPM text, creates GDI+ Bitmap, saves BMP, wraps in .rc, compiles via brcc32.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)] [string] $XpmPath,
  [Parameter(Mandatory)] [string] $DcrPath,
  [string] $ResourceName = '',
  [string] $Brcc32Path = 'C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\brcc32.exe'
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

if (-not (Test-Path $XpmPath)) { throw "XPM not found: $XpmPath" }
if (-not $ResourceName) { $ResourceName = [IO.Path]::GetFileNameWithoutExtension($XpmPath).ToUpper() }

# Parse XPM
$lines = Get-Content $XpmPath | Where-Object { $_ -match '^"[^"]+"' } | ForEach-Object {
  if ($_ -match '^"([^"]*)"') { $Matches[1] }
}
# Header: "width height ncolors cpp"
$header = $lines[0] -split '\s+'
$width  = [int]$header[0]
$height = [int]$header[1]
$ncolors = [int]$header[2]
$cpp = [int]$header[3]

# Color table: ncolors lines
$colors = @{}
for ($i = 1; $i -le $ncolors; $i++) {
  $line = $lines[$i]
  $key = $line.Substring(0, $cpp)
  # Format: "<key>\tc <color>" -> color = #RRGGBB or "None"
  if ($line -match 'c\s+(\S+)') {
    $col = $Matches[1]
    if ($col -eq 'None') {
      $colors[$key] = [System.Drawing.Color]::Transparent
    } elseif ($col -match '^#([0-9A-Fa-f]{6})$') {
      $colors[$key] = [System.Drawing.Color]::FromArgb([Convert]::ToInt32($Matches[1], 16) -bor [int]0xFF000000)
    }
  }
}

# Create bitmap
$bmp = New-Object System.Drawing.Bitmap($width, $height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
for ($y = 0; $y -lt $height; $y++) {
  $pixelLine = $lines[$ncolors + 1 + $y]
  for ($x = 0; $x -lt $width; $x++) {
    $key = $pixelLine.Substring($x * $cpp, $cpp)
    if ($colors.ContainsKey($key)) {
      $bmp.SetPixel($x, $y, $colors[$key])
    }
  }
}

# Convert to 24bpp BGR (brcc32 requires classic DIB format, not 32bpp ARGB)
$bmp24 = New-Object System.Drawing.Bitmap($width, $height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g = [System.Drawing.Graphics]::FromImage($bmp24)
# Fill background with magenta (transparent color marker in Delphi component palette)
$g.Clear([System.Drawing.Color]::FromArgb(255, 255, 0, 255))
$g.DrawImage($bmp, 0, 0)
$g.Dispose()
# Save BMP next to DCR target
$bmpPath = [IO.Path]::ChangeExtension($DcrPath, '.bmp')
$bmp24.Save($bmpPath, [System.Drawing.Imaging.ImageFormat]::Bmp)
$bmp24.Dispose()
$bmp.Dispose()
Write-Host "BMP: $bmpPath ($width x $height, 24bpp, $ncolors src colors)"

# Build RC referencing BMP. Component icon: resource name must match component class name (TZipFileORM -> TZIPFILE).
$rcPath = [IO.Path]::ChangeExtension($DcrPath, '.rc')
$bmpName = [IO.Path]::GetFileName($bmpPath)
$rcText = "$ResourceName BITMAP `"$bmpName`"`r`n"
[System.IO.File]::WriteAllText($rcPath, $rcText, [System.Text.Encoding]::ASCII)
Write-Host "RC:  $rcPath  (resource: $ResourceName)"

# Compile via brcc32
$rcDir = Split-Path $rcPath -Parent
Push-Location $rcDir
try {
  & $Brcc32Path ([IO.Path]::GetFileName($rcPath)) "-fo$([IO.Path]::GetFileName($DcrPath))" 2>&1 | Select-Object -Last 5
} finally { Pop-Location }

if (Test-Path $DcrPath) {
  $sz = (Get-Item $DcrPath).Length
  Write-Host "DCR: $DcrPath ($sz bytes)" -ForegroundColor Green
} else {
  Write-Host "DCR generation FAILED" -ForegroundColor Red
}
