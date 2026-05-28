{ 06_iso_example.dpr
  Demonstra TIsoFile (READ-only ISO 9660 + Joliet).
  Requer fixture.iso pre-existente (gerar via tools/Make-IsoFixture.ps1).
}
program _06_iso_example;
{$APPTYPE CONSOLE}
{$IFDEF FPC}{$mode delphi}{$H+}{$ENDIF}
uses
  {$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  Iso.IsoFile;

const
  ISO_PATH = '..\tests\fixture.iso';

procedure DemoRead;
var
  Iso: TIsoFile;
  I: Integer;
begin
  WriteLn('=== Demo 1: TIsoFile READ (ISO 9660 + Joliet) ===');
  if not FileExists(ISO_PATH) then
  begin
    WriteLn('  SKIP: ', ISO_PATH, ' nao encontrado.');
    WriteLn('  Gerar via: powershell ..\tools\Make-IsoFixture.ps1');
    Exit;
  end;

  Iso := TIsoFile.Create(nil);
  try
    Iso.FileName := ISO_PATH;
    Iso.Active := True;
    WriteLn('  VolumeID = "', Iso.VolumeID, '"');
    WriteLn('  JolietActive = ', Iso.JolietActive);
    WriteLn('  EntryCount = ', Iso.EntryCount);
    for I := 0 to Iso.EntryCount - 1 do
      WriteLn('    [', I, '] ', Iso.GetEntryName(I),
              '  size=', Iso.GetFileSize(I),
              '  isdir=', Iso.IsDir(I));

    if Iso.FileExists('FIRST.TXT') then
      WriteLn('  FIRST.TXT = "', Iso.ReadAsString('FIRST.TXT'), '"');
    if Iso.FileExists('SUBDIR/SECOND.TXT') then
      WriteLn('  SUBDIR/SECOND.TXT = "', Iso.ReadAsString('SUBDIR/SECOND.TXT'), '"');
  finally Iso.Free; end;
  WriteLn;
end;

procedure DemoFluent;
var
  Iso: TIsoFile;
begin
  WriteLn('=== Demo 2: Inline fluent (WithFileName.ThatOpens) ===');
  if not FileExists(ISO_PATH) then begin WriteLn('  SKIP'); Exit; end;

  Iso := TIsoFile.Create(nil);
  try
    // Fluent chained: WithFileName, ThatOpens, then access
    Iso.WithFileName(ISO_PATH).ThatOpens;
    WriteLn('  Inline ThatOpens VolumeID=', Iso.VolumeID);
    if Iso.FileExists('FIRST.TXT') then
      WriteLn('  Content = "', Iso.ReadAsString('FIRST.TXT'), '"');
  finally Iso.Free; end;
  WriteLn;
end;

begin
  try
    WriteLn('ZipFile example 06 -- ISO 9660 + Joliet READ');
    WriteLn('=============================================');
    WriteLn;
    DemoRead;
    DemoFluent;
    WriteLn('OK -- demos completos');
  except
    on E: Exception do begin WriteLn('FATAL: ', E.ClassName, ': ', E.Message); Halt(1); end;
  end;
end.
