program smoke_cab_write;
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  CabFile in '..\src\CabFile.pas';

var
  Cab: TCabFile;
  TmpDir: string;
  Src1, Src2, OutCab: string;
  C: AnsiString;
  Stm: TFileStream;
  ReadBack: string;
  I: Integer;
begin
  try
    TmpDir := IncludeTrailingPathDelimiter(GetCurrentDir);
    Src1 := TmpDir + 'cab_write_src1.txt';
    Src2 := TmpDir + 'cab_write_src2.txt';
    OutCab := TmpDir + 'cab_write_out.cab';

    // Cleanup
    if FileExists(Src1) then DeleteFile(Src1);
    if FileExists(Src2) then DeleteFile(Src2);
    if FileExists(OutCab) then DeleteFile(OutCab);

    // Create source files
    C := 'First file contents created by v3.7.1 WRITE.';
    Stm := TFileStream.Create(Src1, fmCreate);
    try Stm.WriteBuffer(C[1], Length(C)); finally Stm.Free; end;
    C := 'Second file payload from FCI Store mode.';
    Stm := TFileStream.Create(Src2, fmCreate);
    try Stm.WriteBuffer(C[1], Length(C)); finally Stm.Free; end;

    WriteLn('1. CreateFromFiles -> ', OutCab);
    Cab := TCabFile.Create(nil);
    try
      Cab.FileName := OutCab;
      Cab.Compression := cctMSZIP;  // v3.7.2 â€” MSZIP funcional via zlib real
      Cab.CreateFromFiles(['cab_write_src1.txt', 'first.txt',
                           'cab_write_src2.txt', 'second.txt']);
    finally Cab.Free; end;
    if not FileExists(OutCab) then begin WriteLn('   FAIL: cab not created'); Halt(1); end;
    Stm := TFileStream.Create(OutCab, fmOpenRead);
    try WriteLn('   OK created (', Stm.Size, ' bytes)'); finally Stm.Free; end;

    WriteLn('2. Read back...');
    Cab := TCabFile.Create(nil);
    try
      Cab.FileName := OutCab;
      Cab.Active := True;
      WriteLn('   EntryCount=', Cab.EntryCount);
      if Cab.EntryCount <> 2 then begin WriteLn('   FAIL: expected 2'); Halt(1); end;
      for I := 0 to Cab.EntryCount - 1 do
        WriteLn('   [', I, '] ', Cab.GetEntryName(I), '  size=', Cab.GetFileSize(I));
      ReadBack := Cab.ReadAsString('first.txt');
      WriteLn('   first.txt: "', ReadBack, '"');
      if ReadBack <> 'First file contents created by v3.7.1 WRITE.' then
      begin WriteLn('   FAIL: first.txt mismatch'); Halt(1); end;
      ReadBack := Cab.ReadAsString('second.txt');
      WriteLn('   second.txt: "', ReadBack, '"');
      if ReadBack <> 'Second file payload from FCI Store mode.' then
      begin WriteLn('   FAIL: second.txt mismatch'); Halt(1); end;
    finally Cab.Free; end;
    WriteLn('   PASS â€” full WRITE+READ round-trip OK');
  except
    on E: Exception do
    begin
      WriteLn('EXCEPTION: ', E.ClassName, ' ', E.Message);
      Halt(1);
    end;
  end;
end.
