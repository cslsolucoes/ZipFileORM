program smoke_zip64w;
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes, ZipFile;
var
  Zip: TZipFile;
  Src, Got: TMemoryStream;
  Bl: Cardinal;
  Plain: AnsiString;
  Fs: TFileStream;
begin
  if FileExists('zw.zip') then DeleteFile('zw.zip');
  Plain := 'hello z64 write';
  try
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := 'zw.zip';
      Zip.ForceZip64 := True;
      WriteLn('A1 before Active=True');
      Zip.Active := True;
      WriteLn('A2 after Active');
      Src := TMemoryStream.Create;
      try
        Src.WriteBuffer(Plain[1], Length(Plain));
        Src.Position := 0;
        WriteLn('B1 before AppendStream');
        Zip.AppendStream(Src, 'h.txt', Now);
        WriteLn('B2 after AppendStream');
      finally Src.Free; end;
    finally Zip.Free; end;
    Fs := TFileStream.Create('zw.zip', fmOpenRead);
    try
      WriteLn(Format('FileSize=%d', [Fs.Size]));
    finally Fs.Free; end;
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := 'zw.zip';
      WriteLn('C1 reopen Active=True');
      Zip.Active := True;
      WriteLn('FileCount=', Zip.FileCount);
      Bl := 0;
      Got := Zip.GetFileStream('h.txt', Bl);
      try
        WriteLn('Got.Size=', Got.Size);
        SetLength(Plain, Got.Size);
        if Got.Size > 0 then Move(PByte(Got.Memory)^, Plain[1], Got.Size);
        WriteLn('Got=', Plain);
      finally Got.Free; end;
    finally Zip.Free; end;
    WriteLn('OK');
  except on E: Exception do begin WriteLn('FATAL ', E.ClassName, ' ', E.Message); Halt(1); end; end;
end.
