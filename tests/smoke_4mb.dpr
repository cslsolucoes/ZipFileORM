program smoke_4mb;
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes, ZipFile;
const
  N = 4 * 1024 * 1024;
var
  Path: string;
  Zip: TZipFile;
  Big: TMemoryStream;
  Payload, ReadBack: TBytes;
  Stm: TStream;
  I, R: Integer;
begin
  Path := 'smoke_4mb.zip';
  if FileExists(Path) then DeleteFile(Path);
  SetLength(Payload, N);
  for I := 0 to N - 1 do Payload[I] := Byte(I);
  WriteLn('1. Building 4MB ZIP...');
  try
    Big := TMemoryStream.Create;
    try
      Big.WriteBuffer(Payload[0], N);
      Big.Position := 0;
      Zip := TZipFile.Create(nil);
      try
        Zip.FileName := Path;
        Zip.Active := True;
        WriteLn('   Active OK');
        Zip.AppendStream(Big, 'big.bin', Now);
        WriteLn('   AppendStream OK');
      finally Zip.Free; end;
    finally Big.Free; end;
  except on E: Exception do begin WriteLn('FATAL WRITE: ', E.ClassName, ' ', E.Message); Halt(1); end; end;
  WriteLn('2. Reading via GetEntryStream...');
  try
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Active := True;
      Stm := Zip.GetEntryStream('big.bin');
      try
        WriteLn('   Stm.Size=', Stm.Size);
        SetLength(ReadBack, N);
        R := Stm.Read(ReadBack[0], N);
        WriteLn('   Read returned ', R, ' bytes');
        for I := 0 to N - 1 do
          if ReadBack[I] <> Payload[I] then
          begin
            WriteLn('FAIL byte ', I, ': expected ', Payload[I], ' got ', ReadBack[I]);
            Halt(2);
          end;
        WriteLn('OK round-trip 4MB');
      finally Stm.Free; end;
    finally Zip.Free; end;
  except on E: Exception do begin WriteLn('FATAL READ: ', E.ClassName, ' ', E.Message); Halt(3); end; end;
end.
