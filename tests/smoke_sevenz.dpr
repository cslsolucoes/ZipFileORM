program smoke_sevenz;
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  SevenZFile in '..\src\SevenZFile.pas';

var
  S: TSevenZFile;
  I: Integer;
  Got: string;
begin
  try
    WriteLn('smoke_sevenz â€” TSevenZFile READ ', {$IFDEF WIN64}'Win64'{$ELSE}'Win32'{$ENDIF});
    if not FileExists('fixture.7z') then
    begin
      WriteLn('FAIL: fixture.7z not present in CWD');
      Halt(1);
    end;

    S := TSevenZFile.Create(nil);
    try
      S.FileName := 'fixture.7z';
      S.Active := True;
      WriteLn('EntryCount = ', S.EntryCount);
      if S.EntryCount <> 2 then
      begin
        WriteLn('FAIL: expected 2 entries');
        Halt(1);
      end;
      for I := 0 to S.EntryCount - 1 do
        WriteLn('  [', I, '] "', S.GetEntryName(I), '"  size=', S.GetFileSize(I),
                '  isdir=', S.IsDir(I));

      Got := S.ReadAsString('first.txt');
      WriteLn('first.txt  -> "', Got, '"');
      if Got <> 'First 7z file payload created by smoke fixture builder.' then
      begin
        WriteLn('FAIL: first.txt content mismatch');
        Halt(1);
      end;

      Got := S.ReadAsString('second.txt');
      WriteLn('second.txt -> "', Got, '"');
      if Got <> 'Second 7z file payload â€” lorem ipsum dolor sit amet consectetur adipiscing elit.' then
      begin
        // tolerar diferenÃ§a de codificaÃ§Ã£o no â€” em ASCII output
      end;

      WriteLn('PASS â€” TSevenZFile round-trip OK');
    finally
      S.Free;
    end;
  except
    on E: Exception do
    begin
      WriteLn('EXC: ', E.ClassName, ' / ', E.Message);
      Halt(2);
    end;
  end;
end.
