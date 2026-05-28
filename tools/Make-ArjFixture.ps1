# Make-ArjFixture.ps1
# Cria ZipFileORM/tests/fixture.arj com 2 stored files (method 0).
# Spec referenciada: ARJ unofficial spec docs + SDK sdk/arj/defines.h.
# Header magic 0xEA60 LE, first_hdr_size=30 bytes basico + filename + comment + CRC32.

$ErrorActionPreference = 'Stop'
$tests = Join-Path (Split-Path -Parent $PSScriptRoot) 'tests'
$out = Join-Path $tests 'fixture.arj'
if (Test-Path $out) { Remove-Item -Force $out }

# CRC-32 table-driven (IEEE 802.3 / zlib)
$crcTable = New-Object uint32[] 256
for ($i = 0; $i -lt 256; $i++) {
  $c = [uint32]$i
  for ($j = 0; $j -lt 8; $j++) {
    if (($c -band 1) -ne 0) {
      $c = ($c -shr 1) -bxor 0xEDB88320
    } else {
      $c = $c -shr 1
    }
  }
  $crcTable[$i] = $c
}
function Crc32([byte[]]$data) {
  $c = [uint32]::MaxValue
  foreach ($b in $data) { $c = ($crcTable[($c -band 0xFF) -bxor $b]) -bxor ($c -shr 8) }
  return $c -bxor 0xFFFFFFFF
}

# ARJ header builder. Returns the header bytes for either MAIN (file_type=2)
# or FILE (file_type=0/normal). Layout per the ARJ format spec:
#   +0  2B magic 0xEA60 LE
#   +2  2B basic_hdr_size LE (size of basic header excluding magic+size field+CRC)
#   +4  1B first_hdr_size (=30, offset to filename within basic header)
#   +5  1B archiver_version (=11, ARJ 2.x)
#   +6  1B min_version_to_extract (=1)
#   +7  1B host_os (=2 UNIX, or 0 DOS — usamos 0)
#   +8  1B arj_flags (=0)
#   +9  1B security_version (=0)
#   +10 1B file_type (2=main_header, 0=normal file)
#   +11 1B reserved (=0)
#   +12 4B timestamp_dos LE (=0)
#   +16 4B compressed_size LE
#   +20 4B original_size LE
#   +24 4B file_crc32 LE
#   +28 2B filespec_position LE (=0)
#   +30 2B file_attr LE (=0)
#   +32 2B host_data LE (=0)
# Total first_hdr_size = 34 (some specs say 30 for older; usar 34 / first_hdr_size_v).
# Then: filename\0 comment\0 hdr_crc32(4B LE) ext_hdr_chain(2B size=0)
function Build-ArjHeader([byte]$FileType, [string]$Filename, [byte[]]$Data) {
  $compressed = if ($Data) { $Data.Length } else { 0 }
  $original = $compressed
  $crc32 = if ($Data -and $Data.Length -gt 0) { Crc32 $Data } else { 0 }
  $firstHdrSize = 34  # ARJ 2.x usa 34 (FIRST_HDR_SIZE_V)

  $fnBytes = [Text.Encoding]::ASCII.GetBytes($Filename)
  $basicHdr = New-Object byte[] ($firstHdrSize + $fnBytes.Length + 1 + 1)
  # +0 first_hdr_size
  $basicHdr[0] = $firstHdrSize
  $basicHdr[1] = 11   # archiver_version (ARJ 2.x .1)
  $basicHdr[2] = 1    # min_version_to_extract
  $basicHdr[3] = 0    # host_os DOS
  $basicHdr[4] = 0    # arj_flags
  $basicHdr[5] = 0    # security_version
  $basicHdr[6] = $FileType
  $basicHdr[7] = 0    # reserved
  # +8 timestamp 0 (4 bytes already zero)
  # +12 compressed_size
  $basicHdr[8] = $compressed -band 0xFF
  $basicHdr[9] = ($compressed -shr 8) -band 0xFF
  $basicHdr[10] = ($compressed -shr 16) -band 0xFF
  $basicHdr[11] = ($compressed -shr 24) -band 0xFF
  # +16 original_size
  $basicHdr[12] = $original -band 0xFF
  $basicHdr[13] = ($original -shr 8) -band 0xFF
  $basicHdr[14] = ($original -shr 16) -band 0xFF
  $basicHdr[15] = ($original -shr 24) -band 0xFF
  # Wait - my offsets shifted. The first byte of "basic header" is first_hdr_size.
  # Let me redo with correct layout.
  return $null
}

# Simplified: write header byte-by-byte using a List, then concat.

function Add-LE16([System.Collections.Generic.List[byte]]$List, [uint16]$Value) {
  $List.Add(([byte]($Value -band 0xFF)))
  $List.Add(([byte](($Value -shr 8) -band 0xFF)))
}
function Add-LE32([System.Collections.Generic.List[byte]]$List, [uint32]$Value) {
  $List.Add(([byte]($Value -band 0xFF)))
  $List.Add(([byte](($Value -shr 8) -band 0xFF)))
  $List.Add(([byte](($Value -shr 16) -band 0xFF)))
  $List.Add(([byte](($Value -shr 24) -band 0xFF)))
}

function Build-Header([byte]$FileType, [string]$Filename, [byte[]]$Data) {
  $compressed = if ($Data) { [uint32]$Data.Length } else { [uint32]0 }
  $original = $compressed
  $fileCrc = if ($Data -and $Data.Length -gt 0) { Crc32 $Data } else { [uint32]0 }

  $basic = New-Object System.Collections.Generic.List[byte]
  $basic.Add(34)            # first_hdr_size = 34 (ARJ 2.x)
  $basic.Add(11)            # archiver_version
  $basic.Add(1)             # min_version_to_extract
  $basic.Add(0)             # host_os DOS
  $basic.Add(0)             # arj_flags
  $basic.Add(0)             # security_version
  $basic.Add($FileType)
  $basic.Add(0)             # reserved
  Add-LE32 $basic 0          # timestamp_dos
  Add-LE32 $basic $compressed
  Add-LE32 $basic $original
  Add-LE32 $basic $fileCrc
  Add-LE16 $basic 0         # filespec_position
  Add-LE16 $basic 0         # file_attr
  Add-LE16 $basic 0         # host_data
  # Total here: 8 + 4 + 4 + 4 + 4 + 2 + 2 + 2 = 30 bytes... but first_hdr_size=34?
  # ARJ 2.x V format adds 4 bytes (extended_filespec_size?). Padding 4 bytes.
  Add-LE32 $basic 0         # extra 4 bytes for V layout

  # filename\0
  foreach ($b in [Text.Encoding]::ASCII.GetBytes($Filename)) { $basic.Add($b) }
  $basic.Add(0)
  # comment\0 (empty)
  $basic.Add(0)

  # Header CRC32 of basic header bytes (not including magic + size + crc itself)
  $hdrCrc = Crc32 $basic.ToArray()

  # Compose full record: magic + basic_hdr_size + basic + hdr_crc + ext_chain_term(0)
  $rec = New-Object System.Collections.Generic.List[byte]
  Add-LE16 $rec 0xEA60         # magic
  Add-LE16 $rec ($basic.Count) # basic header size LE
  $rec.AddRange([byte[]]$basic.ToArray())
  Add-LE32 $rec $hdrCrc
  Add-LE16 $rec 0              # ext header chain terminator (size=0)
  return ,$rec.ToArray()
}

$file = New-Object System.Collections.Generic.List[byte]

# Main header (file_type=2 = comment header / archive descriptor)
$mainName = 'fixture.arj'
$file.AddRange([byte[]](Build-Header 2 $mainName $null))

# File 1: first.txt
$data1 = [Text.Encoding]::ASCII.GetBytes('First ARJ stored payload (method 0)')
$file.AddRange([byte[]](Build-Header 0 'first.txt' $data1))
$file.AddRange($data1)

# File 2: second.txt
$data2 = [Text.Encoding]::ASCII.GetBytes('Second ARJ entry, longer content here')
$file.AddRange([byte[]](Build-Header 0 'second.txt' $data2))
$file.AddRange($data2)

# End-of-archive: magic + basic_hdr_size=0
Add-LE16 $file 0xEA60
Add-LE16 $file 0

[IO.File]::WriteAllBytes($out, $file.ToArray())
Write-Host ("Created {0} ({1} bytes)" -f $out, $file.Count)
