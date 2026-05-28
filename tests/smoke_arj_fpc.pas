{ smoke_arj_fpc.pas — FPC-compatible ARJ smoke }
program smoke_arj_fpc;
{$IFDEF FPC}{$mode delphi}{$H+}{$ENDIF}
uses SysUtils, Classes, ArjFile;
var Arj: TArjFile; I: Integer; Got: string;
begin
  try
    if not FileExists('fixture.arj') then begin WriteLn('FAIL: no fixture.arj'); Halt(1); end;
    Arj := TArjFile.Create(nil);
    try
      Arj.FileName := 'fixture.arj';
      Arj.Active := True;
      WriteLn('ArchiveName="', Arj.ArchiveName, '" EntryCount=', Arj.EntryCount);
      for I := 0 to Arj.EntryCount - 1 do
        WriteLn('  [', I, '] ', Arj.GetEntryName(I), '  size=', Arj.GetFileSize(I));
      Got := Arj.ReadAsString('first.txt');
      if Got <> 'First ARJ stored payload (method 0)' then begin WriteLn('FAIL first'); Halt(1); end;
      Got := Arj.ReadAsString('second.txt');
      if Got <> 'Second ARJ entry, longer content here' then begin WriteLn('FAIL second'); Halt(1); end;
      WriteLn('PASS');
    finally Arj.Free; end;
  except on E: Exception do begin WriteLn('EXC: ', E.ClassName, ' ', E.Message); Halt(2); end; end;
end.
