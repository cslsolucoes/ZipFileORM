program baseline_smoke;
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes, ZipFile;
const
  Z = 'baseline_test.zip';
var
  Zip: TZipFile;
  Src: TMemoryStream;
  PLAIN: AnsiString;
  Got: AnsiString;
  BL: Cardinal;
  S: TMemoryStream;
begin
  if FileExists(Z) then DeleteFile(Z);
  PLAIN := 'hello world baseline';
  try
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Z;
      WriteLn('A1 before Active');
      Zip.Active := True;
      WriteLn('A2 after Active');
      Src := TMemoryStream.Create;
      try
        Src.WriteBuffer(PLAIN[1], Length(PLAIN));
        Src.Position := 0;
        WriteLn('B1 before AppendStream');
        Zip.AppendStream(Src, 'h.txt', Now);
        WriteLn('B2 after AppendStream');
      finally Src.Free; end;
    finally Zip.Free; end;
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Z;
      WriteLn('C1 reopen');
      Zip.Active := True;
      BL := 0;
      S := Zip.GetFileStream('h.txt', BL);
      SetLength(Got, S.Size);
      if S.Size > 0 then Move(PByte(S.Memory)^, Got[1], S.Size);
      WriteLn('GOT=', Got);
      S.Free;
    finally Zip.Free; end;
  except on E: Exception do begin WriteLn('FATAL ', E.ClassName, ' ', E.Message); Halt(1); end; end;
end.
