program smoke_arj;
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  ArjFile in '..\src\ArjFile.pas';
var
  Arj: TArjFile;
  I: Integer;
  Got: string;
begin
  try
    WriteLn('smoke_arj â€” TArjFile READ ', {$IFDEF WIN64}'Win64'{$ELSE}'Win32'{$ENDIF});
    if not FileExists('fixture.arj') then begin WriteLn('FAIL: no fixture.arj'); Halt(1); end;
    Arj := TArjFile.Create(nil);
    try
      Arj.FileName := 'fixture.arj';
      Arj.Active := True;
      WriteLn('ArchiveName="', Arj.ArchiveName, '"');
      WriteLn('EntryCount=', Arj.EntryCount);
      for I := 0 to Arj.EntryCount - 1 do
        WriteLn('  [', I, '] ', Arj.GetEntryName(I), '  size=', Arj.GetFileSize(I),
                '  method=', Arj.GetEntryMethod(I));
      Got := Arj.ReadAsString('first.txt');
      WriteLn('first.txt  -> "', Got, '"');
      if Got <> 'First ARJ stored payload (method 0)' then
      begin WriteLn('FAIL: first.txt mismatch'); Halt(1); end;
      Got := Arj.ReadAsString('second.txt');
      WriteLn('second.txt -> "', Got, '"');
      if Got <> 'Second ARJ entry, longer content here' then
      begin WriteLn('FAIL: second.txt mismatch'); Halt(1); end;
      WriteLn('PASS â€” TArjFile Store round-trip OK');
    finally Arj.Free; end;
  except
    on E: Exception do begin WriteLn('EXC: ', E.ClassName, ' / ', E.Message); Halt(2); end;
  end;
end.
