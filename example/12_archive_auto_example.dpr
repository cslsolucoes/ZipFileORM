{ 12_archive_auto_example.dpr
  Demonstra Archive.Open.DetectArchiveFormat — auto-detect por magic bytes.
}
program _12_archive_auto_example;
{$APPTYPE CONSOLE}
{$IFDEF FPC}{$mode delphi}{$H+}{$ENDIF}
uses
  {$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  Archive.Open;

procedure DetectIfPresent(const APath: string);
var Fmt: TArchiveFormat;
begin
  if not FileExists(APath) then
  begin
    WriteLn('  ', APath, ' - nao encontrado');
    Exit;
  end;
  Fmt := DetectArchiveFormat(APath);
  Write('  ', APath, ' -> ');
  case Fmt of
    afZip:        WriteLn('ZIP');
    afGzip:       WriteLn('Gzip');
    afTar:        WriteLn('TAR (ustar)');
    afTarGz:      WriteLn('TAR + Gzip');
    afSevenZip:   WriteLn('7zip');
    afCab:        WriteLn('CAB');
    afBzip2:      WriteLn('BZIP2');
    afRar:        WriteLn('RAR');
    afZCompress:  WriteLn('Z (compress LZW)');
  else WriteLn('UNKNOWN (', Ord(Fmt), ')');
  end;
end;

begin
  try
    WriteLn('ZipFile example 12 -- Archive auto-detect by magic bytes');
    WriteLn('=========================================================');
    WriteLn;
    WriteLn('Procurando fixtures em ..\tests\:');
    DetectIfPresent('..\tests\fixture.7z');
    DetectIfPresent('..\tests\fixture.cab');
    DetectIfPresent('..\tests\fixture.iso');
    DetectIfPresent('..\tests\fixture.lha');
    DetectIfPresent('..\tests\fixture.arj');
    DetectIfPresent('..\tests\fixture.rar');
    DetectIfPresent('..\tests\fixture_store.7z');
    DetectIfPresent('..\tests\smoke_linux.zip');
    DetectIfPresent('..\tests\deflate_fixture.zip');
    WriteLn;
    WriteLn('Procurando outputs deste session em pasta atual:');
    DetectIfPresent('example_01_legacy.zip');
    DetectIfPresent('example_03_store.7z');
    DetectIfPresent('example_04_mszip.cab');
    WriteLn;
    WriteLn('OK -- detect demo completo');
  except
    on E: Exception do begin WriteLn('FATAL: ', E.ClassName, ': ', E.Message); Halt(1); end;
  end;
end.
