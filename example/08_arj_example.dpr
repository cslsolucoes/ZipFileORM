{ 08_arj_example.dpr
  Demonstra TArjFile (READ method 0 Store).
  Requer fixture.arj pre-existente (gerar via tools/Make-ArjFixture.ps1).
}
program _08_arj_example;
{$APPTYPE CONSOLE}
{$IFDEF FPC}{$mode delphi}{$H+}{$ENDIF}
uses
  {$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  Arj.ArjFile;

const
  ARJ_PATH = '..\tests\fixture.arj';

procedure DemoRead;
var
  Arj: TArjFile;
  I: Integer;
begin
  WriteLn('=== Demo 1: TArjFile READ ===');
  if not FileExists(ARJ_PATH) then
  begin
    WriteLn('  SKIP: ', ARJ_PATH, ' nao encontrado.');
    WriteLn('  Gerar via: powershell ..\tools\Make-ArjFixture.ps1');
    Exit;
  end;
  Arj := TArjFile.Create(nil);
  try
    Arj.FileName := ARJ_PATH;
    Arj.Active := True;
    WriteLn('  EntryCount=', Arj.EntryCount);
    for I := 0 to Arj.EntryCount - 1 do
      WriteLn('    [', I, '] ', Arj.GetEntryName(I),
              '  size=', Arj.GetFileSize(I),
              '  method=', Arj.GetEntryMethod(I));
    if Arj.FileExists('first.txt') then
      WriteLn('  first.txt = "', Arj.ReadAsString('first.txt'), '"');
  finally Arj.Free; end;
  WriteLn;
end;

procedure DemoFluent;
var Arj: TArjFile;
begin
  WriteLn('=== Demo 2: Inline fluent ===');
  if not FileExists(ARJ_PATH) then begin WriteLn('  SKIP'); Exit; end;
  Arj := TArjFile.Create(nil);
  try
    Arj.WithFileName(ARJ_PATH).ThatOpens;
    if Arj.FileExists('first.txt') then
      WriteLn('  fluent: first.txt = "', Arj.ReadAsString('first.txt'), '"');
  finally Arj.Free; end;
  WriteLn;
end;

begin
  try
    WriteLn('ZipFile example 08 -- ARJ READ (method 0 Store)');
    WriteLn('================================================');
    WriteLn;
    DemoRead;
    DemoFluent;
    WriteLn('OK -- demos completos');
  except
    on E: Exception do begin WriteLn('FATAL: ', E.ClassName, ': ', E.Message); Halt(1); end;
  end;
end.
