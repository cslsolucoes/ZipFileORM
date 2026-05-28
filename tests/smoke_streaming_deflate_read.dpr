program smoke_streaming_deflate_read;
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  ZipFile in '..\src\ZipFile.pas',
  ZipFile.Streaming in '..\src\ZipFile.Streaming.pas';

var
  Zip: TZipFile;
  Stm: TStream;
  Buf: array[0..4095] of Byte;
  ReadCount, TotalRead: Integer;
begin
  WriteLn('Reading DEFLATE entry via streaming (chunked 4 KB)...');
  Zip := TZipFile.Create(nil);
  try
    Zip.FileName := 'deflate_fixture.zip';
    Zip.Active := True;
    WriteLn('  FileCount=', Zip.FileCount);
    Stm := Zip.GetEntryStream('payload.txt');
    try
      WriteLn('  stream class: ', Stm.ClassName);
      WriteLn('  stream size:  ', Stm.Size);
      if Stm.ClassName <> 'TZipEntryDeflateReadStream' then
      begin
        WriteLn('  FAIL: expected TZipEntryDeflateReadStream, got ', Stm.ClassName);
        Halt(1);
      end;
      TotalRead := 0;
      while True do
      begin
        ReadCount := Stm.Read(Buf, SizeOf(Buf));
        if ReadCount <= 0 then Break;
        Inc(TotalRead, ReadCount);
      end;
      WriteLn('  total read:   ', TotalRead);
      if TotalRead <> Stm.Size then
      begin
        WriteLn('  FAIL: TotalRead=', TotalRead, ' Size=', Stm.Size);
        Halt(1);
      end;
      WriteLn('  PASS - streaming DEFLATE read OK');
    finally Stm.Free; end;
  finally Zip.Free; end;
end.
