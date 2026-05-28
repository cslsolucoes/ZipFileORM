{ smoke_rar_fpc.pas — FPC-compatible RAR smoke }
program smoke_rar_fpc;
{$IFDEF FPC}{$mode delphi}{$H+}{$ENDIF}
uses SysUtils, Classes, RarFile;
var Rar: TRarFile; I: Integer; Got: string;
begin
  try
    if not FileExists('fixture.rar') then begin WriteLn('FAIL'); Halt(1); end;
    Rar := TRarFile.Create(nil);
    try
      Rar.FileName := 'fixture.rar';
      Rar.Active := True;
      WriteLn('IsRar5=', Rar.IsRar5, ' EntryCount=', Rar.EntryCount);
      for I := 0 to Rar.EntryCount - 1 do
        WriteLn('  [', I, '] ', Rar.GetEntryName(I), '  size=', Rar.GetFileSize(I));
      Got := Rar.ReadAsString('first.txt');
      if Got <> 'First RAR stored payload (m0 method)' then begin WriteLn('FAIL first'); Halt(1); end;
      Got := Rar.ReadAsString('second.txt');
      if Got <> 'Second RAR entry, lorem ipsum content' then begin WriteLn('FAIL second'); Halt(1); end;
      WriteLn('PASS');
    finally Rar.Free; end;
  except on E: Exception do begin WriteLn('EXC: ', E.ClassName, ' ', E.Message); Halt(2); end; end;
end.
