# Make-RarFixture.ps1
# Cria ZipFileORM/tests/fixture.rar usando WinRAR CLI vendored em
# C:\Program Files\WinRAR\rar.exe. Modo: -m0 (store, no compression),
# -ma4 (RAR4 format — mais simples que RAR5 para reader pure-pascal).

$ErrorActionPreference = 'Stop'
$tests = Join-Path (Split-Path -Parent $PSScriptRoot) 'tests'
$src = Join-Path $tests 'rar_src'
$out = Join-Path $tests 'fixture.rar'

$rar = 'C:\Program Files\WinRAR\rar.exe'
if (-not (Test-Path $rar)) { throw "WinRAR rar.exe not found at $rar" }

if (Test-Path $src) { Remove-Item -Recurse -Force $src }
if (Test-Path $out) { Remove-Item -Force $out }
New-Item -ItemType Directory -Path $src | Out-Null
[IO.File]::WriteAllText((Join-Path $src 'first.txt'), 'First RAR stored payload (m0 method)')
[IO.File]::WriteAllText((Join-Path $src 'second.txt'), 'Second RAR entry, lorem ipsum content')

# rar a -m0 -ma4 fixture.rar rar_src\
# -m0 = store, -ma4 = RAR4 archive format (legacy, simpler)
Push-Location $tests
try {
  # -m0 = store; -ep1 = exclude base folder from path. Sem -ma (WinRAR
  # antigo cria RAR4 por default; mais novo aceita -ma4 mas algumas
  # versoes nao reconhecem o flag).
  & $rar a -m0 -ep1 fixture.rar 'rar_src\first.txt' 'rar_src\second.txt' | Out-Null
} finally { Pop-Location }

if (-not (Test-Path $out)) { throw "Failed to create $out" }
Get-Item $out | Select-Object Name,Length
