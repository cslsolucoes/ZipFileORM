# Build-LhaObjs.ps1
# Tenta compilar arquivos do SDK LHa (sdk/lha/src/) para .obj/.o em 4
# toolchains. Foco em decoder algorithm files (slide, huf, dhuf, shuf,
# larc, maketbl, maketree, bitio, crcio) que devem ser mais portaveis
# que CLI front-ends (lharc, lhadd, lhext, lhlist).
#
# Estrategia: tentar cada .c com -DHAVE_CONFIG_H=0 + flags minimos.
# Documenta o que builda vs o que falha (deps Unix-only).
#
# Decoder cores sao consumidos por wrapper Pascal/C futuro que substitua
# os FILE* I/O por buffer in-memory.

$ErrorActionPreference = 'Continue'
$Root = Resolve-Path "$PSScriptRoot\.."
$Src = Join-Path $Root 'sdk\lha\src'
$MingwGcc = Join-Path $Root 'deps\gcc-mingw-w64\bin\gcc.exe'
$Bcc32 = "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\bcc32c.exe"
$Bcc64 = "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\bcc64.exe"
$LocalSdk  = Join-Path $Root 'deps\win64\include\sdk'
$LocalCrtl = Join-Path $Root 'deps\win64\include\crtl'

if (-not (Test-Path $Src)) { throw "LHA SDK not at $Src" }
$Compat = Join-Path $Root 'sdk\lha\compat'

# Decoder algorithm files (no CLI deps) — primeira tentativa
$DecoderCores = @(
  'bitio.c', 'crcio.c', 'maketbl.c', 'maketree.c',
  'slide.c', 'huf.c', 'dhuf.c', 'shuf.c', 'larc.c'
)

# Defines comuns: stub HAVE_* config flags p/ evitar autoconf checks
$CommonDefs = @(
  '-DSUPPORT_LH7',
  '-DSTDC_HEADERS=1',
  '-DHAVE_LIMITS_H=1',
  '-DHAVE_STDLIB_H=1',
  '-DHAVE_STRING_H=1',
  '-DHAVE_MEMORY_H=1',
  '-DHAVE_MEMSET=1',
  '-DHAVE_MEMCMP=1',
  '-DHAVE_MEMCPY=1',
  '-DHAVE_STRCHR=1',
  '-DHAVE_STRRCHR=1',
  '-DHAVE_SSIZE_T=1',         # ssize_t ja em sys/types via Win headers
  '-DHAVE_SYS_PARAM_H=0',
  '-DHAVE_DIRENT_H=0',
  '-DHAVE_UTIME_H=0',
  '-DHAVE_LSTAT=0',
  '-DHAVE_SYMLINK=0',
  '-DRETSIGTYPE=void',        # signal handler return type (autoconf default)
  '-DHAVE_VSNPRINTF=1',       # use system snprintf (avoid SDK redef conflict)
  '-DHAVE_SNPRINTF=1',
  '-DHAVE_MEMMOVE=1',
  '-DHAVE_STRDUP=1',
  '-DHAVE_STRCASECMP=1',
  '-DHAVE_STRNCASECMP=1'
)

function Try-Compile($Compiler, $ExtraArgs, $SrcFile, $OutDir, $OutExt, $Includes) {
  $obj = (Split-Path -Leaf $SrcFile) -replace '\.c$', $OutExt
  $outPath = Join-Path $OutDir $obj
  $cmd = @($CommonDefs) + $ExtraArgs + @($Includes) + @("-o$outPath", $SrcFile)
  Push-Location $Src
  try {
    $output = & $Compiler -c @cmd 2>&1
    $ec = $LASTEXITCODE
  } finally { Pop-Location }
  return [pscustomobject]@{
    File = (Split-Path -Leaf $SrcFile)
    OutExt = $OutExt
    ExitCode = $ec
    OK = ($ec -eq 0) -and (Test-Path $outPath)
    Output = $output
  }
}

$results = @()

# === Win32 OMF via bcc32c ===
if (Test-Path $Bcc32) {
  $Out32 = Join-Path $Root 'Library\delphi-win32'
  if (-not (Test-Path $Out32)) { New-Item -Path $Out32 -ItemType Directory | Out-Null }
  Write-Host "=== LHA Win32 OMF (bcc32c) ==="
  foreach ($f in $DecoderCores) {
    $r = Try-Compile $Bcc32 @('-O2', "-I$Compat") $f $Out32 '.obj' @()
    if ($r.OK) {
      Write-Host ("  OK   {0}" -f $r.File) -ForegroundColor Green
    } else {
      Write-Host ("  FAIL {0}: exit {1}" -f $r.File, $r.ExitCode) -ForegroundColor Red
      ($r.Output | Select-String -Pattern 'error:' | Select-Object -First 2) | ForEach-Object { Write-Host "       $_" }
    }
    $results += $r
  }
}

# === Win64 ELF via bcc64 ===
if ((Test-Path $Bcc64) -and (Test-Path $LocalSdk)) {
  $Out64 = Join-Path $Root 'Library\delphi-win64'
  if (-not (Test-Path $Out64)) { New-Item -Path $Out64 -ItemType Directory | Out-Null }
  Write-Host "=== LHA Win64 ELF (bcc64) ==="
  $w64Args = @('-O2', '-fno-zero-initialized-in-bss', "-I$Compat", "-I$LocalSdk", "-I$LocalCrtl")
  foreach ($f in $DecoderCores) {
    $r = Try-Compile $Bcc64 $w64Args $f $Out64 '.o' @()
    if ($r.OK) {
      Write-Host ("  OK   {0}" -f $r.File) -ForegroundColor Green
    } else {
      Write-Host ("  FAIL {0}: exit {1}" -f $r.File, $r.ExitCode) -ForegroundColor Red
      ($r.Output | Select-String -Pattern 'error:' | Select-Object -First 2) | ForEach-Object { Write-Host "       $_" }
    }
    $results += $r
  }
}

# === FPC Win32+Win64 COFF via mingw ===
if (Test-Path $MingwGcc) {
  $FpcOut32 = Join-Path $Root 'Library\fpc-win32'
  $FpcOut64 = Join-Path $Root 'Library\fpc-win64'
  if (-not (Test-Path $FpcOut32)) { New-Item -Path $FpcOut32 -ItemType Directory | Out-Null }
  if (-not (Test-Path $FpcOut64)) { New-Item -Path $FpcOut64 -ItemType Directory | Out-Null }
  # mingw 16.1 rejeita K&R old-style function definitions. SDK LHa de 1995
  # usa estilo K&R em muitos files; -std=gnu89 + warnings desabilitados.
  $mingwArgs = @('-O2', '-std=gnu89', '-Wno-error', '-Wno-old-style-definition',
                 '-Wno-implicit-int', '-Wno-implicit-function-declaration')
  Write-Host "=== LHA FPC Win32 COFF (mingw -m32) ==="
  foreach ($f in $DecoderCores) {
    $r = Try-Compile $MingwGcc ($mingwArgs + @('-m32', "-I$Compat")) $f $FpcOut32 '.o' @()
    if ($r.OK) {
      Write-Host ("  OK   {0}" -f $r.File) -ForegroundColor Green
    } else {
      Write-Host ("  FAIL {0}: exit {1}" -f $r.File, $r.ExitCode) -ForegroundColor Red
    }
    $results += $r
  }
  Write-Host "=== LHA FPC Win64 COFF (mingw -m64) ==="
  foreach ($f in $DecoderCores) {
    $r = Try-Compile $MingwGcc ($mingwArgs + @('-m64', "-I$Compat")) $f $FpcOut64 '.o' @()
    if ($r.OK) {
      Write-Host ("  OK   {0}" -f $r.File) -ForegroundColor Green
    } else {
      Write-Host ("  FAIL {0}: exit {1}" -f $r.File, $r.ExitCode) -ForegroundColor Red
    }
    $results += $r
  }
}

Write-Host ""
Write-Host "=== Summary ==="
$ok = ($results | Where-Object { $_.OK }).Count
$fail = ($results | Where-Object { -not $_.OK }).Count
Write-Host ("OK: {0}   FAIL: {1}   Total: {2}" -f $ok, $fail, $results.Count)
