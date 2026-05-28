# Dump-7zStore.ps1
# Cria fixture_store.7z (Store -mx0) e analisa o header structure
# para reverse-engineering do container 7z.

$ErrorActionPreference = 'Stop'
$tests = Join-Path (Split-Path -Parent $PSScriptRoot) 'tests'
$src = Join-Path $tests 'sevenz_src'

if (Test-Path $src) { Remove-Item -Recurse -Force $src }
New-Item -ItemType Directory -Path $src | Out-Null
[IO.File]::WriteAllText((Join-Path $src 'first.txt'), 'First 7z stored payload (method Copy)')
[IO.File]::WriteAllText((Join-Path $src 'second.txt'), 'Second 7z entry, lorem ipsum content')

$out = Join-Path $tests 'fixture_store.7z'
if (Test-Path $out) { Remove-Item -Force $out }
Push-Location $src
& 'C:\Program Files\7-Zip\7z.exe' a -t7z -mx0 $out 'first.txt' 'second.txt' | Out-Null
Pop-Location

$b = [IO.File]::ReadAllBytes($out)
Write-Host ("Size: {0} bytes" -f $b.Length)
Write-Host ("Signature[0..5]: {0:X2} {1:X2} {2:X2} {3:X2} {4:X2} {5:X2}" -f $b[0],$b[1],$b[2],$b[3],$b[4],$b[5])
Write-Host ("Version[6..7]: {0:X2} {1:X2}" -f $b[6],$b[7])
Write-Host ("StartHdrCRC[8..11]: {0:X2} {1:X2} {2:X2} {3:X2}" -f $b[8],$b[9],$b[10],$b[11])
Write-Host ("NextHeaderOffset[12..19]: $(($b[12..19] | ForEach-Object { '{0:X2}' -f $_ }) -join ' ')")
Write-Host ("NextHeaderSize[20..27]:   $(($b[20..27] | ForEach-Object { '{0:X2}' -f $_ }) -join ' ')")
Write-Host ("NextHeaderCRC[28..31]:    {0:X2} {1:X2} {2:X2} {3:X2}" -f $b[28],$b[29],$b[30],$b[31])
$hdrOffset = [BitConverter]::ToInt64($b, 12)
$hdrSize = [BitConverter]::ToInt64($b, 20)
Write-Host ("NextHeaderOffset = $hdrOffset; NextHeaderSize = $hdrSize")
$hdrStart = $hdrOffset + 32
Write-Host ("Header starts at file offset $hdrStart")
Write-Host ""
Write-Host "Payload (offset 32..$($hdrStart - 1)):"
for ($i = 32; $i -lt $hdrStart; $i++) {
  Write-Host -NoNewline ("{0:X2} " -f $b[$i])
  if ((($i - 32 + 1) % 16) -eq 0) { Write-Host "" }
}
Write-Host ""
Write-Host ""
Write-Host "Header bytes ($hdrSize bytes):"
for ($i = 0; $i -lt $hdrSize; $i++) {
  Write-Host -NoNewline ("{0:X2} " -f $b[$hdrStart + $i])
  if ((($i + 1) % 16) -eq 0) { Write-Host "" }
}
Write-Host ""
