program smoke_tar;
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes, TarFile;
const
  PAYLOAD: AnsiString = 'hello tar';
var
  Tar: TTarFile;
  Mem: TMemoryStream;
  Stm: TStream;
  Got: AnsiString;
begin
  if FileExists('tarsmoke.tar') then DeleteFile('tarsmoke.tar');
  try
    Tar := TTarFile.Create(nil);
    try
      Tar.FileName := 'tarsmoke.tar';
      Tar.Open;
      Mem := TMemoryStream.Create;
      try
        Mem.WriteBuffer(PAYLOAD[1], Length(PAYLOAD));
        Mem.Position := 0;
        Tar.AppendStream(Mem, 'a.txt', Now);
      finally Mem.Free; end;
      WriteLn('After append, EntryCount=', Tar.EntryCount);
    finally Tar.Free; end;
    WriteLn('--- Reopen ---');
    Tar := TTarFile.Create(nil);
    try
      Tar.FileName := 'tarsmoke.tar';
      Tar.Open;
      WriteLn('Reopen EntryCount=', Tar.EntryCount);
      Stm := Tar.GetEntryStream('a.txt');
      try
        WriteLn('Stm.Size=', Stm.Size);
        SetLength(Got, Stm.Size);
        if Stm.Size > 0 then Move(PByte(TMemoryStream(Stm).Memory)^, Got[1], Stm.Size);
        WriteLn('Got=[', Got, ']');
      finally Stm.Free; end;
    finally Tar.Free; end;
  except on E: Exception do begin WriteLn('FATAL ', E.ClassName, ' ', E.Message); Halt(1); end; end;
end.
