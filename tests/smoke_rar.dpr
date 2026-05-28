program smoke_rar;
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  RarFile in '..\src\RarFile.pas';
var
  Rar: TRarFile;
  I: Integer;
  Got: string;
begin
  try
    WriteLn('smoke_rar â€” TRarFile READ ', {$IFDEF WIN64}'Win64'{$ELSE}'Win32'{$ENDIF});
    if not FileExists('fixture.rar') then begin WriteLn('FAIL: no fixture.rar'); Halt(1); end;
    Rar := TRarFile.Create(nil);
    try
      Rar.FileName := 'fixture.rar';
      Rar.Active := True;
      WriteLn('IsRar5=', Rar.IsRar5, '  EntryCount=', Rar.EntryCount);
      for I := 0 to Rar.EntryCount - 1 do
        WriteLn('  [', I, '] ', Rar.GetEntryName(I), '  size=', Rar.GetFileSize(I),
                '  method=', Rar.GetEntryMethod(I));
      Got := Rar.ReadAsString('first.txt');
      WriteLn('first.txt  -> "', Got, '"');
      if Got <> 'First RAR stored payload (m0 method)' then
      begin WriteLn('FAIL: first.txt mismatch'); Halt(1); end;
      Got := Rar.ReadAsString('second.txt');
      WriteLn('second.txt -> "', Got, '"');
      if Got <> 'Second RAR entry, lorem ipsum content' then
      begin WriteLn('FAIL: second.txt mismatch'); Halt(1); end;
      WriteLn('PASS â€” TRarFile RAR5 Store round-trip OK');
    finally Rar.Free; end;
  except
    on E: Exception do begin WriteLn('EXC: ', E.ClassName, ' / ', E.Message); Halt(2); end;
  end;
end.
