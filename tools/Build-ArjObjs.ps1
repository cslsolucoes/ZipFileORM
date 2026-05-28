# Build-ArjObjs.ps1
# Compila o decoder ARJ (decode.c + deps minimas) com SFX_LEVEL=1
# (ARJSFXJR — menor SFX, exclui CLI massive deps) em 4 toolchains.
# Decoder.c eh self-contained com setjmp/longjmp + tabelas Huffman.

$ErrorActionPreference = 'Continue'
$Root = Resolve-Path "$PSScriptRoot\.."
$Src = Join-Path $Root 'sdk\arj'
$MingwGcc = Join-Path $Root 'deps\gcc-mingw-w64\bin\gcc.exe'
$Bcc32 = "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\bcc32c.exe"
$Bcc64 = "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\bcc64.exe"
$LocalSdk  = Join-Path $Root 'deps\win64\include\sdk'
$LocalCrtl = Join-Path $Root 'deps\win64\include\crtl'

if (-not (Test-Path $Src)) { throw "ARJ SDK not at $Src" }
$Compat = Join-Path $Root 'sdk\arj\compat'

# Cores: decoder + CRC + minimal helpers.
$Cores = @('decode.c', 'crc32.c')

# SFX_LEVEL=1 (ARJSFXJR) corta a maioria das deps. TARGET=DOS (1) eh menor.
$CommonDefs = @(
  '-DSFX_LEVEL=1',
  '-DTARGET=1',           # DOS = simplest target
  '-DARJ_BIG_ENDIAN=0',
  '-DCOMPILER=99'         # generic compiler
)

function Try-Compile($Compiler, $ExtraArgs, $SrcFile, $OutDir, $OutExt) {
  $obj = (Split-Path -Leaf $SrcFile) -replace '\.c$', $OutExt
  $outPath = Join-Path $OutDir $obj
  $cmd = @($CommonDefs) + $ExtraArgs + @("-o$outPath", $SrcFile)
  Push-Location $Src
  try {
    $output = & $Compiler -c @cmd 2>&1
    $ec = $LASTEXITCODE
  } finally { Pop-Location }
  return [pscustomobject]@{
    File = (Split-Path -Leaf $SrcFile)
    ExitCode = $ec
    OK = ($ec -eq 0) -and (Test-Path $outPath)
    Output = $output
  }
}

$results = @()

if (Test-Path $Bcc32) {
  $Out32 = Join-Path $Root 'Library\delphi-win32'
  if (-not (Test-Path $Out32)) { New-Item -Path $Out32 -ItemType Directory | Out-Null }
  Write-Host "=== ARJ Win32 OMF ==="
  foreach ($f in $Cores) {
    $r = Try-Compile $Bcc32 @('-O2', "-I$Compat") $f $Out32 '.obj'
    if ($r.OK) { Write-Host "  OK   $($r.File)" -ForegroundColor Green }
    else {
      Write-Host "  FAIL $($r.File): exit $($r.ExitCode)" -ForegroundColor Red
      ($r.Output | Select-String -Pattern 'error:|fatal' | Select-Object -First 2) | ForEach-Object { Write-Host "       $_" }
    }
    $results += $r
  }
}

if ((Test-Path $Bcc64) -and (Test-Path $LocalSdk)) {
  $Out64 = Join-Path $Root 'Library\delphi-win64'
  if (-not (Test-Path $Out64)) { New-Item -Path $Out64 -ItemType Directory | Out-Null }
  Write-Host "=== ARJ Win64 ELF ==="
  $w64Args = @('-O2', '-fno-zero-initialized-in-bss', "-I$Compat", "-I$LocalSdk", "-I$LocalCrtl")
  foreach ($f in $Cores) {
    $r = Try-Compile $Bcc64 $w64Args $f $Out64 '.o'
    if ($r.OK) { Write-Host "  OK   $($r.File)" -ForegroundColor Green }
    else {
      Write-Host "  FAIL $($r.File): exit $($r.ExitCode)" -ForegroundColor Red
      ($r.Output | Select-String -Pattern 'error:|fatal' | Select-Object -First 2) | ForEach-Object { Write-Host "       $_" }
    }
    $results += $r
  }
}

if (Test-Path $MingwGcc) {
  $FpcOut32 = Join-Path $Root 'Library\fpc-win32'
  $FpcOut64 = Join-Path $Root 'Library\fpc-win64'
  if (-not (Test-Path $FpcOut32)) { New-Item -Path $FpcOut32 -ItemType Directory | Out-Null }
  if (-not (Test-Path $FpcOut64)) { New-Item -Path $FpcOut64 -ItemType Directory | Out-Null }
  $mingwArgs = @('-O2', '-std=gnu89', '-Wno-error',
                 '-Wno-old-style-definition', '-Wno-implicit-int',
                 '-Wno-implicit-function-declaration')
  Write-Host "=== ARJ FPC Win32 ==="
  foreach ($f in $Cores) {
    $r = Try-Compile $MingwGcc ($mingwArgs + @('-m32', "-I$Compat")) $f $FpcOut32 '.o'
    if ($r.OK) { Write-Host "  OK   $($r.File)" -ForegroundColor Green }
    else { Write-Host "  FAIL $($r.File): exit $($r.ExitCode)" -ForegroundColor Red }
    $results += $r
  }
  Write-Host "=== ARJ FPC Win64 ==="
  foreach ($f in $Cores) {
    $r = Try-Compile $MingwGcc ($mingwArgs + @('-m64', "-I$Compat")) $f $FpcOut64 '.o'
    if ($r.OK) { Write-Host "  OK   $($r.File)" -ForegroundColor Green }
    else { Write-Host "  FAIL $($r.File): exit $($r.ExitCode)" -ForegroundColor Red }
    $results += $r
  }
}

Write-Host ""
Write-Host "=== Summary ==="
$ok = ($results | Where-Object { $_.OK }).Count
$fail = ($results | Where-Object { -not $_.OK }).Count
Write-Host ("OK: {0}   FAIL: {1}   Total: {2}" -f $ok, $fail, $results.Count)
