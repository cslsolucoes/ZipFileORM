program smoke_sevenz_write;
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  SevenZFile in '..\src\SevenZFile.pas';

var
  S: TSevenZFile;
  Names: array of string;
  Data: array of TBytes;
  D1, D2: TBytes;
  Stm: TFileStream;
const
  TXT1 = 'First 7z stored payload written by TSevenZFile';
  TXT2 = 'Second 7z entry, longer content for round-trip test';
begin
  try
    WriteLn('smoke_sevenz_write â€” TSevenZFile WRITE ',
      {$IFDEF WIN64}'Win64'{$ELSE}'Win32'{$ENDIF});

    if FileExists('write_out.7z') then DeleteFile('write_out.7z');

    D1 := TEncoding.UTF8.GetBytes(TXT1);
    D2 := TEncoding.UTF8.GetBytes(TXT2);

    SetLength(Names, 2);
    Names[0] := 'first.txt';
    Names[1] := 'second.txt';
    SetLength(Data, 2);
    Data[0] := D1;
    Data[1] := D2;

    S := TSevenZFile.Create(nil);
    try
      S.FileName := 'write_out.7z';
      S.CreateFromBytes(Names, Data);
    finally S.Free; end;

    if not FileExists('write_out.7z') then
    begin
      WriteLn('FAIL: write_out.7z not created');
      Halt(1);
    end;
    Stm := TFileStream.Create('write_out.7z', fmOpenRead);
    try
      WriteLn('Created write_out.7z (', Stm.Size, ' bytes)');
    finally Stm.Free; end;
    WriteLn('WRITE OK. Validating via TSevenZFile READ...');

    // Self-round-trip: re-abre o arquivo escrito e le content back
    S := TSevenZFile.Create(nil);
    try
      S.FileName := 'write_out.7z';
      S.Active := True;
      WriteLn('  EntryCount=', S.EntryCount);
      if S.EntryCount <> 2 then begin WriteLn('FAIL: expected 2'); Halt(1); end;
      if S.ReadAsString('first.txt') <> TXT1 then
      begin WriteLn('FAIL: first.txt round-trip'); Halt(1); end;
      if S.ReadAsString('second.txt') <> TXT2 then
      begin WriteLn('FAIL: second.txt round-trip'); Halt(1); end;
      WriteLn('  first.txt  -> "', S.ReadAsString('first.txt'), '"');
      WriteLn('  second.txt -> "', S.ReadAsString('second.txt'), '"');
    finally S.Free; end;
    WriteLn('PASS â€” TSevenZFile WRITE+READ round-trip OK');
  except
    on E: Exception do
    begin
      WriteLn('EXC: ', E.ClassName, ' / ', E.Message);
      Halt(2);
    end;
  end;
end.
