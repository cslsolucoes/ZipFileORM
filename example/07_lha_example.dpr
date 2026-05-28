{ 07_lha_example.dpr
  Demonstra TLhaFile (READ-only LHA/LZH).
  Requer fixture.lha pre-existente (gerar via tools/Make-LhaFixture.ps1).
  Suporta methods -lh0- (Store) e -lh4-/-lh5-/-lh6-/-lh7- (Pascal decoder port).
}
program _07_lha_example;
{$APPTYPE CONSOLE}
{$IFDEF FPC}{$mode delphi}{$H+}{$ENDIF}
uses
  {$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  Lha.LhaFile;

const
  LHA_PATH = '..\tests\fixture.lha';

procedure DemoRead;
var
  Lha: TLhaFile;
  I: Integer;
begin
  WriteLn('=== Demo 1: TLhaFile READ ===');
  if not FileExists(LHA_PATH) then
  begin
    WriteLn('  SKIP: ', LHA_PATH, ' nao encontrado.');
    WriteLn('  Gerar via: powershell ..\tools\Make-LhaFixture.ps1');
    Exit;
  end;

  Lha := TLhaFile.Create(nil);
  try
    Lha.FileName := LHA_PATH;
    Lha.Active := True;
    WriteLn('  EntryCount=', Lha.EntryCount);
    for I := 0 to Lha.EntryCount - 1 do
      WriteLn('    [', I, '] ', Lha.GetEntryName(I),
              '  size=', Lha.GetFileSize(I),
              '  method=', Lha.GetEntryMethod(I));

    if Lha.FileExists('first.txt') then
      WriteLn('  first.txt = "', Lha.ReadAsString('first.txt'), '"');
    if Lha.FileExists('second.txt') then
      WriteLn('  second.txt = "', Lha.ReadAsString('second.txt'), '"');

    // FindIndex by name
    WriteLn('  FindIndex("first.txt") = ', Lha.FindIndex('first.txt'));
  finally Lha.Free; end;
  WriteLn;
end;

procedure DemoFluent;
var Lha: TLhaFile; B: TBytes;
begin
  WriteLn('=== Demo 2: Inline fluent ===');
  if not FileExists(LHA_PATH) then begin WriteLn('  SKIP'); Exit; end;
  Lha := TLhaFile.Create(nil);
  try
    Lha.WithFileName(LHA_PATH).ThatOpens;
    if Lha.FileExists('first.txt') then
    begin
      B := Lha.ReadAsBytes('first.txt');
      WriteLn('  first.txt bytes count = ', Length(B));
    end;
  finally Lha.Free; end;
  WriteLn;
end;

begin
  try
    WriteLn('ZipFile example 07 -- LHA / LZH READ');
    WriteLn('=====================================');
    WriteLn;
    DemoRead;
    DemoFluent;
    WriteLn('OK -- demos completos');
  except
    on E: Exception do begin WriteLn('FATAL: ', E.ClassName, ': ', E.Message); Halt(1); end;
  end;
end.
