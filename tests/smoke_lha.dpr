program smoke_lha;
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  LhaFile in '..\src\LhaFile.pas';
var
  Lha: TLhaFile;
  I: Integer;
  Got: string;
begin
  try
    WriteLn('smoke_lha â€” TLhaFile READ ', {$IFDEF WIN64}'Win64'{$ELSE}'Win32'{$ENDIF});
    if not FileExists('fixture.lha') then
    begin WriteLn('FAIL: no fixture.lha'); Halt(1); end;

    Lha := TLhaFile.Create(nil);
    try
      Lha.FileName := 'fixture.lha';
      Lha.Active := True;
      WriteLn('EntryCount=', Lha.EntryCount);
      for I := 0 to Lha.EntryCount - 1 do
        WriteLn('  [', I, '] ', Lha.GetEntryName(I), '  size=', Lha.GetFileSize(I),
                '  method=', Lha.GetEntryMethod(I));

      Got := Lha.ReadAsString('first.txt');
      WriteLn('first.txt  -> "', Got, '"');
      if Got <> 'First LHA payload (Store -lh0- format)' then
      begin WriteLn('FAIL: first.txt mismatch'); Halt(1); end;

      Got := Lha.ReadAsString('second.txt');
      WriteLn('second.txt -> "', Got, '"');
      if Got <> 'Second file in LHA archive, deeper content' then
      begin WriteLn('FAIL: second.txt mismatch'); Halt(1); end;

      WriteLn('PASS â€” TLhaFile Store round-trip OK');
    finally Lha.Free; end;
  except
    on E: Exception do
    begin WriteLn('EXC: ', E.ClassName, ' / ', E.Message); Halt(2); end;
  end;
end.
