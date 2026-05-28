#requires -Version 5.1
<#
.SYNOPSIS
  Gera packages Delphi (runtime + design-time) + .dproj + .groupproj para os 7
  Delphi (D24..D37) seguindo padrao Gnostice. Source vendor intocado; arquivos
  novos vivem em ZipFileORM/packages/.
#>

$ErrorActionPreference = 'Stop'
$root    = Split-Path -Parent $PSScriptRoot
$pkgsDir = Join-Path $root 'packages'
New-Item -ItemType Directory -Path $pkgsDir -Force | Out-Null

$delphis = @(
  @{ D = '24'; Bds = '18.0'; Rad = 'RAD10.1'; Name = 'Delphi 10.1 Berlin' }
  @{ D = '25'; Bds = '19.0'; Rad = 'RAD10.2'; Name = 'Delphi 10.2 Tokyo' }
  @{ D = '26'; Bds = '20.0'; Rad = 'RAD10.3'; Name = 'Delphi 10.3 Rio' }
  @{ D = '27'; Bds = '21.0'; Rad = 'RAD10.4'; Name = 'Delphi 10.4 Sydney' }
  @{ D = '28'; Bds = '22.0'; Rad = 'RAD11';   Name = 'Delphi 11 Alexandria' }
  @{ D = '29'; Bds = '23.0'; Rad = 'RAD12';   Name = 'Delphi 12 Athens' }
  @{ D = '37'; Bds = '37.0'; Rad = 'RAD13';   Name = 'Delphi 13 Florence' }
)

# Setup output folders Lib/RAD<MM>/{Win32,Win64} (flat, no sub-dirs)
foreach ($d in $delphis) {
  foreach ($plat in 'Win32', 'Win64') {
    $libDir = Join-Path $root "Lib\$($d.Rad)\$plat"
    if (-not (Test-Path $libDir)) { New-Item -ItemType Directory -Path $libDir -Force | Out-Null }
  }
}

# Helper: write file without BOM (Delphi IDE rejects UTF-8 BOM in .dproj)
function Write-NoBom([string]$Path, [string]$Content) {
  [System.IO.File]::WriteAllText($Path, $Content, (New-Object System.Text.UTF8Encoding($false)))
}

function New-RuntimeDpk([hashtable]$D) {
  $name = "ZipFileORMD$($D.D)"
@"
package $name;

{`$R *.res}
{`$ALIGN 8}
{`$ASSERTIONS OFF}
{`$BOOLEVAL OFF}
{`$DEBUGINFO OFF}
{`$EXTENDEDSYNTAX ON}
{`$IMPORTEDDATA ON}
{`$IOCHECKS ON}
{`$LOCALSYMBOLS OFF}
{`$LONGSTRINGS ON}
{`$OPENSTRINGS ON}
{`$OPTIMIZATION ON}
{`$OVERFLOWCHECKS OFF}
{`$RANGECHECKS OFF}
{`$REFERENCEINFO OFF}
{`$SAFEDIVIDE OFF}
{`$STACKFRAMES OFF}
{`$TYPEDADDRESS OFF}
{`$VARSTRINGCHECKS ON}
{`$WRITEABLECONST ON}
{`$MINENUMSIZE 1}
{`$IMAGEBASE `$400000}
{`$IMPLICITBUILD OFF}
{`$DESCRIPTION 'ZipFileORM library (runtime) for $($D.Name)'}
{`$RUNONLY}

requires
  rtl,
  vcl;

contains
  // dzlib.pas is FPC-only (uses zbase) and is NOT included in Delphi builds.
  // tiCompressZLib.pas uses dzlib under {`$IFDEF FPC} and System.ZLib under {`$ELSE}.
  ZipFileORM.ZIP64 in '..\src\ZipFileORM.ZIP64.pas',
  ZipFileORM.UTF8 in '..\src\ZipFileORM.UTF8.pas',
  ZipFileORM.Progress in '..\src\ZipFileORM.Progress.pas',
  ZipFileORM.Encryption.AES in '..\src\ZipFileORM.Encryption.AES.pas',
  ZipFileORM.Streaming in '..\src\ZipFileORM.Streaming.pas',
  ZipFileORM.Fluent in '..\src\ZipFileORM.Fluent.pas',
  ZipFileORM.Compression.LZMA in '..\src\ZipFileORM.Compression.LZMA.pas',
  Tar.GzipStream in '..\src\Tar.GzipStream.pas',
  Tar.TarFile in '..\src\Tar.TarFile.pas',
  Tar.TarGzFile in '..\src\Tar.TarGzFile.pas',
  Archive.Open in '..\src\Archive.Open.pas',
  SevenZ.SevenZFile in '..\src\SevenZ.SevenZFile.pas',
  UUE.UUEStream in '..\src\UUE.UUEStream.pas',
  ZCompress.LzwStream in '..\src\ZCompress.LzwStream.pas',
  Cab.CabFile in '..\src\Cab.CabFile.pas',
  ZipFileORM in '..\src\ZipFileORM.pas',
  tiCompress in '..\src\tiCompress.pas',
  tiCompressNone in '..\src\tiCompressNone.pas',
  tiCompressZLib in '..\src\tiCompressZLib.pas',
  tiConstants in '..\src\tiConstants.pas';

end.
"@
}

function New-DesignDpk([hashtable]$D) {
  $name = "dclZipFileORMD$($D.D)"
  $rt   = "ZipFileORMD$($D.D)"
@"
package $name;

{`$R *.res}
{`$R ZipFileORM.dcr}
{`$ALIGN 8}
{`$ASSERTIONS OFF}
{`$BOOLEVAL OFF}
{`$DEBUGINFO OFF}
{`$EXTENDEDSYNTAX ON}
{`$IMPORTEDDATA ON}
{`$IOCHECKS ON}
{`$LOCALSYMBOLS OFF}
{`$LONGSTRINGS ON}
{`$OPENSTRINGS ON}
{`$OPTIMIZATION ON}
{`$OVERFLOWCHECKS OFF}
{`$RANGECHECKS OFF}
{`$REFERENCEINFO OFF}
{`$SAFEDIVIDE OFF}
{`$STACKFRAMES OFF}
{`$TYPEDADDRESS OFF}
{`$VARSTRINGCHECKS ON}
{`$WRITEABLECONST ON}
{`$MINENUMSIZE 1}
{`$IMAGEBASE `$400000}
{`$IMPLICITBUILD OFF}
{`$DESCRIPTION 'ZipFileORM library (design-time) for $($D.Name)'}
{`$DESIGNONLY}

requires
  designide,
  rtl,
  vcl,
  $rt;

contains
  ZipFileORMReg in 'ZipFileORMReg.pas';

end.
"@
}

function New-Dproj([hashtable]$D, [string]$DpkName, [bool]$IsDesigntime) {
  $guid = '{' + [Guid]::NewGuid().ToString().ToUpper() + '}'
  $rt = if ($IsDesigntime) { 'false' } else { 'true' }
  $dt = if ($IsDesigntime) { 'true'  } else { 'false' }
  # cxBDEAdapters lesson: design-time Win64 only works in Delphi 12+ (BDS 23.0+).
  # For runtime: always Win32+Win64. For design-time: D24..D28 = Win32 only (1), D29/D37 = both (3).
  $targeted = if ($IsDesigntime -and [double]$D.Bds -lt 23.0) { '1' } else { '3' }
@"
<?xml version="1.0" encoding="utf-8"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
    <PropertyGroup>
        <ProjectGuid>$guid</ProjectGuid>
        <ProjectVersion>$($D.Bds)</ProjectVersion>
        <FrameworkType>VCL</FrameworkType>
        <MainSource>$DpkName.dpk</MainSource>
        <Base>True</Base>
        <Config Condition="'`$(Config)'==''">Release</Config>
        <Platform Condition="'`$(Platform)'==''">Win32</Platform>
        <TargetedPlatforms>$targeted</TargetedPlatforms>
        <AppType>Package</AppType>
    </PropertyGroup>
    <PropertyGroup Condition="'`$(Config)'=='Base' or '`$(Base)'!=''">
        <Base>true</Base>
    </PropertyGroup>
    <PropertyGroup Condition="('`$(Platform)'=='Win32' and '`$(Base)'=='true') or '`$(Base_Win32)'!=''">
        <Base_Win32>true</Base_Win32>
        <CfgParent>Base</CfgParent>
        <Base>true</Base>
    </PropertyGroup>
    <PropertyGroup Condition="('`$(Platform)'=='Win64' and '`$(Base)'=='true') or '`$(Base_Win64)'!=''">
        <Base_Win64>true</Base_Win64>
        <CfgParent>Base</CfgParent>
        <Base>true</Base>
    </PropertyGroup>
    <PropertyGroup Condition="('`$(Config)'=='Release' and '`$(Base)'!='') or '`$(Cfg_2)'!=''">
        <Cfg_2>true</Cfg_2>
        <CfgParent>Base</CfgParent>
        <Base>true</Base>
    </PropertyGroup>
    <PropertyGroup Condition="'`$(Base)'!=''">
        <DCC_Description>ZipFileORM $($D.Name) ($(if ($IsDesigntime) {'design'} else {'runtime'}))</DCC_Description>
        <DCC_DependencyCheckOutputName>$DpkName.bpl</DCC_DependencyCheckOutputName>
        <DCC_E>false</DCC_E>
        <DCC_F>false</DCC_F>
        <DCC_ImageBase>00400000</DCC_ImageBase>
        <DCC_K>false</DCC_K>
        <DCC_N>false</DCC_N>
        <DCC_S>false</DCC_S>
        <DCC_Namespace>Winapi;System.Win;Data.Win;Datasnap.Win;Web.Win;Soap.Win;Xml.Win;Bde;System;Xml;Data;Datasnap;Web;Soap;Vcl;Vcl.Imaging;Vcl.Touch;Vcl.Samples;Vcl.Shell;`$(DCC_Namespace)</DCC_Namespace>
        <GenDll>true</GenDll>
        <GenPackage>true</GenPackage>
        <RuntimeOnlyPackage>$rt</RuntimeOnlyPackage>
        <DesignOnlyPackage>$dt</DesignOnlyPackage>
        <DCC_UnitSearchPath>..\src;`$(DCC_UnitSearchPath)</DCC_UnitSearchPath>
        <DCC_ResourcePath>..\src;`$(DCC_ResourcePath)</DCC_ResourcePath>
        <DCC_OutputNeverBuildDcps>true</DCC_OutputNeverBuildDcps>
    </PropertyGroup>
    <PropertyGroup Condition="'`$(Base_Win32)'!=''">
        <DCC_DcpOutput>..\Lib\$($D.Rad)\Win32</DCC_DcpOutput>
        <DCC_BplOutput>..\Lib\$($D.Rad)\Win32</DCC_BplOutput>
        <DCC_DcuOutput>..\Lib\$($D.Rad)\Win32</DCC_DcuOutput>
        <DCC_HppOutput>..\Lib\$($D.Rad)\Win32</DCC_HppOutput>
        <DCC_ObjOutput>..\Lib\$($D.Rad)\Win32</DCC_ObjOutput>
        <DCC_UnitSearchPath>..\Lib\$($D.Rad)\Win32;`$(DCC_UnitSearchPath)</DCC_UnitSearchPath>
    </PropertyGroup>
    <PropertyGroup Condition="'`$(Base_Win64)'!=''">
        <DCC_DcpOutput>..\Lib\$($D.Rad)\Win64</DCC_DcpOutput>
        <DCC_BplOutput>..\Lib\$($D.Rad)\Win64</DCC_BplOutput>
        <DCC_DcuOutput>..\Lib\$($D.Rad)\Win64</DCC_DcuOutput>
        <DCC_HppOutput>..\Lib\$($D.Rad)\Win64</DCC_HppOutput>
        <DCC_ObjOutput>..\Lib\$($D.Rad)\Win64</DCC_ObjOutput>
        <DCC_UnitSearchPath>..\Lib\$($D.Rad)\Win64;`$(DCC_UnitSearchPath)</DCC_UnitSearchPath>
    </PropertyGroup>
    <PropertyGroup Condition="'`$(Cfg_2)'!=''">
        <DCC_DebugInformation>0</DCC_DebugInformation>
        <DCC_Define>RELEASE;`$(DCC_Define)</DCC_Define>
        <DCC_LocalDebugSymbols>false</DCC_LocalDebugSymbols>
        <DCC_SymbolReferenceInfo>0</DCC_SymbolReferenceInfo>
    </PropertyGroup>
    <ItemGroup>
        <DelphiCompile Include="`$(MainSource)">
            <MainSource>MainSource</MainSource>
        </DelphiCompile>
        <BuildConfiguration Include="Base">
            <Key>Base</Key>
        </BuildConfiguration>
        <BuildConfiguration Include="Release">
            <Key>Cfg_2</Key>
            <CfgParent>Base</CfgParent>
        </BuildConfiguration>
    </ItemGroup>
    <ProjectExtensions>
        <Borland.Personality>Delphi.Personality.12</Borland.Personality>
        <Borland.ProjectType>Package</Borland.ProjectType>
        <BorlandProject>
            <Delphi.Personality>
                <Source>
                    <Source Name="MainSource">$DpkName.dpk</Source>
                </Source>
            </Delphi.Personality>
        </BorlandProject>
    </ProjectExtensions>
    <Import Project="`$(BDS)\Bin\CodeGear.Delphi.Targets" Condition="Exists('`$(BDS)\Bin\CodeGear.Delphi.Targets')"/>
    <Import Project="`$(APPDATA)\Embarcadero\`$(BDSAPPDATABASEDIR)\`$(PRODUCTVERSION)\UserTools.proj" Condition="Exists('`$(APPDATA)\Embarcadero\`$(BDSAPPDATABASEDIR)\`$(PRODUCTVERSION)\UserTools.proj')"/>
</Project>
"@
}

function New-Groupproj([hashtable]$D) {
  $guid = '{' + [Guid]::NewGuid().ToString().ToUpper() + '}'
  $rt   = "ZipFileORMD$($D.D)"
  $dt   = "dclZipFileORMD$($D.D)"
@"
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup>
    <ProjectGuid>$guid</ProjectGuid>
  </PropertyGroup>
  <ProjectExtensions>
    <Borland.Personality>Default.Personality.12</Borland.Personality>
    <Borland.ProjectType />
    <BorlandProject>
  <BorlandProject xmlns=""> <Default.Personality> </Default.Personality> </BorlandProject></BorlandProject>
  </ProjectExtensions>
  <Target Name="$rt">
    <MSBuild Projects="$rt.dproj" Targets="" />
  </Target>
  <Target Name="$dt">
    <MSBuild Projects="$dt.dproj" Targets="" />
  </Target>
  <Target Name="${rt}:Clean">
    <MSBuild Projects="$rt.dproj" Targets="Clean" />
  </Target>
  <Target Name="${dt}:Clean">
    <MSBuild Projects="$dt.dproj" Targets="Clean" />
  </Target>
  <Target Name="${rt}:Make">
    <MSBuild Projects="$rt.dproj" Targets="Make" />
  </Target>
  <Target Name="${dt}:Make">
    <MSBuild Projects="$dt.dproj" Targets="Make" />
  </Target>
  <Target Name="Build">
    <CallTarget Targets="$rt;$dt" />
  </Target>
  <Target Name="Clean">
    <CallTarget Targets="${rt}:Clean;${dt}:Clean" />
  </Target>
  <Target Name="Make">
    <CallTarget Targets="${rt}:Make;${dt}:Make" />
  </Target>
</Project>
"@
}

# Generate per Delphi version
$count = 0
foreach ($D in $delphis) {
  $rtDpk = "ZipFileORMD$($D.D)"
  $dtDpk = "dclZipFileORMD$($D.D)"

  Write-NoBom (Join-Path $pkgsDir "$rtDpk.dpk")   (New-RuntimeDpk $D)
  Write-NoBom (Join-Path $pkgsDir "$rtDpk.dproj") (New-Dproj $D $rtDpk $false)

  Write-NoBom (Join-Path $pkgsDir "$dtDpk.dpk")   (New-DesignDpk $D)
  Write-NoBom (Join-Path $pkgsDir "$dtDpk.dproj") (New-Dproj $D $dtDpk $true)

  Write-NoBom (Join-Path $pkgsDir "ZipFileORMD$($D.D)Grp.groupproj") (New-Groupproj $D)

  $count++
  Write-Host "Generated: $rtDpk + $dtDpk + groupproj  ($($D.Name))"
}

Write-Host ""
Write-Host "=== Done ==="
Write-Host "Total: $count Delphi versions = $($count * 2) .dpk + $($count * 2) .dproj + $count .groupproj"
Write-Host "Files in packages/: $((Get-ChildItem $pkgsDir -File).Count)"
