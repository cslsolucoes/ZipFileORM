program smoke_sevenz_write_lzma2;
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  SevenZFile in '..\src\SevenZFile.pas';
var
  S: TSevenZFile;
  Names: array of string;
  Data: array of TBytes;
  Stm: TFileStream;
  I: Integer;
const
  TXT1 = 'First 7z LZMA2 compressed payload written by TSevenZFile. ' +
         'Repeated text repeated text repeated text repeated text repeated.';
  TXT2 = 'Second 7z entry, much longer for better compression ratio. ' +
         'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
begin
  try
    WriteLn('smoke_sevenz_write_lzma2 â€” TSevenZFile WRITE LZMA2 ',
      {$IFDEF WIN64}'Win64'{$ELSE}'Win32'{$ENDIF});

    if FileExists('write_lzma2_out.7z') then DeleteFile('write_lzma2_out.7z');

    SetLength(Names, 2);
    Names[0] := 'first.txt';
    Names[1] := 'second.txt';
    SetLength(Data, 2);
    Data[0] := TEncoding.UTF8.GetBytes(TXT1);
    Data[1] := TEncoding.UTF8.GetBytes(TXT2);
    WriteLn('Plain sizes: ', Length(Data[0]), ' + ', Length(Data[1]), ' = ',
      Length(Data[0]) + Length(Data[1]));

    S := TSevenZFile.Create(nil);
    try
      S.FileName := 'write_lzma2_out.7z';
      S.CreateFromBytesLzma2(Names, Data, 5);
    finally S.Free; end;

    Stm := TFileStream.Create('write_lzma2_out.7z', fmOpenRead);
    try
      WriteLn('Created archive: ', Stm.Size, ' bytes');
    finally Stm.Free; end;

    WriteLn('Round-trip via TSevenZFile READ...');
    S := TSevenZFile.Create(nil);
    try
      S.FileName := 'write_lzma2_out.7z';
      S.Active := True;
      WriteLn('  EntryCount=', S.EntryCount);
      for I := 0 to S.EntryCount - 1 do
        WriteLn('    [', I, '] ', S.GetEntryName(I), '  size=', S.GetFileSize(I));
      if S.ReadAsString('first.txt') <> TXT1 then
      begin WriteLn('FAIL first.txt'); Halt(1); end;
      if S.ReadAsString('second.txt') <> TXT2 then
      begin WriteLn('FAIL second.txt'); Halt(1); end;
      WriteLn('  first.txt OK (', Length(S.ReadAsString('first.txt')), ' chars)');
      WriteLn('  second.txt OK (', Length(S.ReadAsString('second.txt')), ' chars)');
    finally S.Free; end;
    WriteLn('PASS â€” LZMA2 WRITE + READ round-trip OK');
  except
    on E: Exception do
    begin
      WriteLn('EXC: ', E.ClassName, ' / ', E.Message);
      Halt(2);
    end;
  end;
end.
