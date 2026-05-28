# Make-IsoFixture.ps1
# Cria ZipFileORM/tests/fixture.iso via IMAPI2 (Windows ImageMastering API).
# Estrutura:
#   /FIRST.TXT
#   /SUBDIR/SECOND.TXT
# Modo: ISO 9660 sem Joliet (filenames upper-case 8.3).

$ErrorActionPreference = 'Stop'
$tests = Join-Path (Split-Path -Parent $PSScriptRoot) 'tests'
$src   = Join-Path $tests 'iso_src'
$iso   = Join-Path $tests 'fixture.iso'

if (Test-Path $src) { Remove-Item -Recurse -Force $src }
if (Test-Path $iso) { Remove-Item -Force $iso }
New-Item -ItemType Directory -Path $src | Out-Null
New-Item -ItemType Directory -Path (Join-Path $src 'SUBDIR') | Out-Null
[IO.File]::WriteAllText((Join-Path $src 'FIRST.TXT'), 'First file ISO payload from fixture builder')
[IO.File]::WriteAllText((Join-Path $src 'SUBDIR\SECOND.TXT'), 'Second file payload deeper in tree')

$image = New-Object -ComObject IMAPI2FS.MsftFileSystemImage
# IMAPI2 FileSystemsToCreate: 1=ISO9660, 2=Joliet, 4=UDF (combinaveis).
# 3 = ISO9660 + Joliet — cobre os 2 modos do TIsoFile.
$image.FileSystemsToCreate = 3
$image.VolumeName = 'TESTISO'
$image.Root.AddTree($src, $false)
$result = $image.CreateResultImage()
$stream = $result.ImageStream

# PowerShell nao consegue cast direto IStream — usar helper IMAPI2FS
# (CreateImageStream wrapper) com tipo C# inline compilado.
Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;
public static class IsoHelper {
  public static void SaveIStream(object stream, string path) {
    IStream s = (IStream)stream;
    using (var fs = new FileStream(path, FileMode.Create, FileAccess.Write)) {
      byte[] buf = new byte[8192];
      IntPtr read = Marshal.AllocCoTaskMem(4);
      try {
        while (true) {
          s.Read(buf, buf.Length, read);
          int n = Marshal.ReadInt32(read);
          if (n <= 0) break;
          fs.Write(buf, 0, n);
        }
      } finally { Marshal.FreeCoTaskMem(read); }
    }
  }
}
'@ -ReferencedAssemblies System.Runtime.InteropServices

[IsoHelper]::SaveIStream($stream, $iso)
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($stream) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($result) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($image)  | Out-Null

Get-Item $iso | Select-Object Name,Length
