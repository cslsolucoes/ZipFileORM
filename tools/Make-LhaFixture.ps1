# Make-LhaFixture.ps1
# Cria ZipFileORM/tests/fixture.lha contendo 2 files (-lh0- Store, level 0 header).
# Sem dependencia em CLI LHa externo — bytes hand-crafted seguindo spec.

$ErrorActionPreference = 'Stop'
$tests = Join-Path (Split-Path -Parent $PSScriptRoot) 'tests'
$out = Join-Path $tests 'fixture.lha'
if (Test-Path $out) { Remove-Item -Force $out }

function Crc16Arc([byte[]]$bytes) {
  $crc = 0
  foreach ($b in $bytes) {
    $crc = $crc -bxor $b
    for ($i = 0; $i -lt 8; $i++) {
      if (($crc -band 1) -ne 0) {
        $crc = ($crc -shr 1) -bxor 0xA001
      } else {
        $crc = $crc -shr 1
      }
    }
  }
  return $crc -band 0xFFFF
}

function Make-Lh0Header([string]$Name, [byte[]]$Data) {
  $fname = [Text.Encoding]::ASCII.GetBytes($Name)
  $fnameLen = $fname.Length
  $crc = Crc16Arc $Data
  $sz = $Data.Length
  $h = New-Object byte[] (22 + $fnameLen + 2)
  # method @ 2..6
  $method = [Text.Encoding]::ASCII.GetBytes('-lh0-')
  [Array]::Copy($method, 0, $h, 2, 5)
  # packed_size @ 7..10
  $h[7] = $sz -band 0xFF; $h[8] = ($sz -shr 8) -band 0xFF
  $h[9] = ($sz -shr 16) -band 0xFF; $h[10] = ($sz -shr 24) -band 0xFF
  # orig_size @ 11..14 (same as packed for Store)
  $h[11] = $sz -band 0xFF; $h[12] = ($sz -shr 8) -band 0xFF
  $h[13] = ($sz -shr 16) -band 0xFF; $h[14] = ($sz -shr 24) -band 0xFF
  # timestamp 0 @ 15..18 (already zero)
  $h[19] = 0x20  # attr = normal file
  $h[20] = 0     # header level 0
  $h[21] = $fnameLen
  [Array]::Copy($fname, 0, $h, 22, $fnameLen)
  # CRC @ 22+fnameLen .. +1
  $h[22 + $fnameLen]     = $crc -band 0xFF
  $h[22 + $fnameLen + 1] = ($crc -shr 8) -band 0xFF
  # hdr_size (excluding sz byte itself + sm checksum byte)
  $h[0] = ($h.Length - 2) -band 0xFF
  # checksum: sum bytes 2..end mod 256
  $sum = 0
  for ($i = 2; $i -lt $h.Length; $i++) { $sum = ($sum + $h[$i]) -band 0xFF }
  $h[1] = $sum
  return $h
}

$file = New-Object System.Collections.Generic.List[byte]
$data1 = [Text.Encoding]::ASCII.GetBytes('First LHA payload (Store -lh0- format)')
$file.AddRange([byte[]](Make-Lh0Header 'first.txt' $data1))
$file.AddRange($data1)

$data2 = [Text.Encoding]::ASCII.GetBytes('Second file in LHA archive, deeper content')
$file.AddRange([byte[]](Make-Lh0Header 'second.txt' $data2))
$file.AddRange($data2)

# End-of-archive marker
$file.Add(0)

[IO.File]::WriteAllBytes($out, $file.ToArray())
Write-Host ("Created {0} ({1} bytes, 2 entries)" -f $out, $file.Count)
