{ 09_rar_example.dpr
  Demonstra TRarFile (READ RAR5 method 0 Store) — pure-pascal vint decoder.
  Requer fixture.rar (gerar via tools/Make-RarFixture.ps1 → usa WinRAR vendored).
}
program _09_rar_example;
{$APPTYPE CONSOLE}
{$IFDEF FPC}{$mode delphi}{$H+}{$ENDIF}
uses
  {$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  Rar.RarFile;

const
  RAR_PATH = '..\tests\fixture.rar';

procedure DemoRead;
var
  Rar: TRarFile;
  I: Integer;
begin
  WriteLn('=== Demo 1: TRarFile READ RAR5 ===');
  if not FileExists(RAR_PATH) then
  begin
    WriteLn('  SKIP: ', RAR_PATH, ' nao encontrado.');
    WriteLn('  Gerar via: powershell ..\tools\Make-RarFixture.ps1 (precisa WinRAR)');
    Exit;
  end;
  Rar := TRarFile.Create(nil);
  try
    Rar.FileName := RAR_PATH;
    Rar.Active := True;
    WriteLn('  IsRar5 = ', Rar.IsRar5);
    WriteLn('  EntryCount = ', Rar.EntryCount);
    for I := 0 to Rar.EntryCount - 1 do
      WriteLn('    [', I, '] ', Rar.GetEntryName(I),
              '  size=', Rar.GetFileSize(I),
              '  method=', Rar.GetEntryMethod(I));
    if Rar.FileExists('first.txt') then
      WriteLn('  first.txt = "', Rar.ReadAsString('first.txt'), '"');
    if Rar.FileExists('second.txt') then
      WriteLn('  second.txt = "', Rar.ReadAsString('second.txt'), '"');
  finally Rar.Free; end;
  WriteLn;
end;

procedure DemoFluent;
var Rar: TRarFile;
begin
  WriteLn('=== Demo 2: Inline fluent ===');
  if not FileExists(RAR_PATH) then begin WriteLn('  SKIP'); Exit; end;
  Rar := TRarFile.Create(nil);
  try
    Rar.WithFileName(RAR_PATH).ThatOpens;
    if Rar.FileExists('first.txt') then
      WriteLn('  fluent: first.txt = "', Rar.ReadAsString('first.txt'), '"');
  finally Rar.Free; end;
  WriteLn;
end;

begin
  try
    WriteLn('ZipFile example 09 -- RAR5 READ (method 0 Store)');
    WriteLn('=================================================');
    WriteLn;
    DemoRead;
    DemoFluent;
    WriteLn('OK -- demos completos');
  except
    on E: Exception do begin WriteLn('FATAL: ', E.ClassName, ': ', E.Message); Halt(1); end;
  end;
end.
