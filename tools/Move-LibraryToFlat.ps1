# Move-LibraryToFlat.ps1
# Consolida Library/<sdk>_obj_<plat>/ → Library/{delphi|fpc}-win{32|64}/ flat.
# Mapeamento:
#   <sdk>_obj_win32       -> delphi-win32 (bcc32c OMF)
#   <sdk>_obj_win64       -> delphi-win64 (bcc64 ELF)
#   <sdk>_obj_fpc_win32   -> fpc-win32 (mingw COFF -m32)
#   <sdk>_obj_fpc_win64   -> fpc-win64 (mingw COFF -m64)
#   cabnet_obj_linux_x64  -> linux-x64 (gcc-linux-musl)
#
# Verifica colisoes antes do move. Mantem old dirs vazios para Remove-Item.

$ErrorActionPreference = 'Stop'
$Root = Resolve-Path "$PSScriptRoot\..\Library"

$Map = @{
  'win32'      = 'delphi-win32'
  'win64'      = 'delphi-win64'
  'fpc_win32'  = 'fpc-win32'
  'fpc_win64'  = 'fpc-win64'
  'linux_x64'  = 'linux-x64'
}

$sdks = @('lzma','cabnet','bzip2','zlib','lha','arj')

# Cria destinos
foreach ($dest in $Map.Values) {
  $p = Join-Path $Root $dest
  if (-not (Test-Path $p)) { New-Item -Path $p -ItemType Directory | Out-Null }
}

$moved = 0
foreach ($sdk in $sdks) {
  foreach ($srcKey in $Map.Keys) {
    $srcDir = Join-Path $Root "${sdk}_obj_${srcKey}"
    $destDir = Join-Path $Root $Map[$srcKey]
    if (-not (Test-Path $srcDir)) { continue }
    $files = Get-ChildItem $srcDir -File -ErrorAction SilentlyContinue
    foreach ($f in $files) {
      $target = Join-Path $destDir $f.Name
      if (Test-Path $target) {
        Write-Warning "COLLISION: $($f.FullName) -> $target (skipping)"
        continue
      }
      Move-Item $f.FullName $target
      $moved++
    }
    # Remove empty source dir
    if ((Get-ChildItem $srcDir -Force -ErrorAction SilentlyContinue).Count -eq 0) {
      Remove-Item $srcDir -Force
    }
  }
}

Write-Host "Moved $moved files."
Write-Host ""
Write-Host "=== Final Library/ structure ==="
Get-ChildItem $Root -Directory | ForEach-Object {
  $count = (Get-ChildItem $_.FullName -File -ErrorAction SilentlyContinue).Count
  Write-Host ("  {0,-20} {1} files" -f $_.Name, $count)
}
