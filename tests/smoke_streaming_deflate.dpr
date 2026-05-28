program smoke_streaming_deflate;
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  ZipFile in '..\src\ZipFile.pas',
  ZipFile.Streaming in '..\src\ZipFile.Streaming.pas';

const
  N = 256 * 1024;   // 256 KB payload

var
  Path: string;
  Zip: TZipFile;
  Big: TMemoryStream;
  Payload: TBytes;
  Stm: TStream;
  Buf: array[0..4095] of Byte;
  Read, TotalRead, I: Integer;
  ExpectedByte: Byte;
  Mismatch: Boolean;
begin
  Path := 'smoke_stream_deflate.zip';
  if FileExists(Path) then DeleteFile(Path);

  WriteLn('1. Building ZIP with DEFLATE entry (256 KB)...');
  SetLength(Payload, N);
  for I := 0 to N - 1 do Payload[I] := Byte(I);
  Big := TMemoryStream.Create;
  try
    Big.WriteBuffer(Payload[0], N);
    Big.Position := 0;
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Compression := cmMaximal;  // forca DEFLATE em vez de Store
      Zip.Active := True;
      Zip.AppendStream(Big, 'payload.bin', Now);
      WriteLn('   AppendStream OK (Compression=cmMaximal)');
    finally Zip.Free; end;
  finally Big.Free; end;

  WriteLn('2. Reading via streaming DEFLATE (chunked 4 KB)...');
  Zip := TZipFile.Create(nil);
  try
    Zip.FileName := Path;
    Zip.Active := True;
    Stm := Zip.GetEntryStream('payload.bin');
    try
      WriteLn('   stream class: ', Stm.ClassName);
      WriteLn('   stream size:  ', Stm.Size);
      if Stm.ClassName <> 'TZipEntryDeflateReadStream' then
      begin
        WriteLn('   FAIL: expected TZipEntryDeflateReadStream, got ', Stm.ClassName);
        Halt(1);
      end;
      TotalRead := 0;
      Mismatch := False;
      while True do
      begin
        Read := Stm.Read(Buf, SizeOf(Buf));
        if Read <= 0 then Break;
        for I := 0 to Read - 1 do
        begin
          ExpectedByte := Byte(TotalRead + I);
          if Buf[I] <> ExpectedByte then
          begin
            WriteLn('   MISMATCH byte ', TotalRead + I, ': got=', Buf[I], ' exp=', ExpectedByte);
            Mismatch := True;
            Break;
          end;
        end;
        if Mismatch then Break;
        Inc(TotalRead, Read);
      end;
      WriteLn('   total read:   ', TotalRead);
      if Mismatch or (TotalRead <> N) then
      begin
        WriteLn('   FAIL');
        Halt(1);
      end;
      WriteLn('   PASS — round-trip byte-identical sem allocar memoria do entry inteiro');
    finally Stm.Free; end;
  finally Zip.Free; end;
end.
