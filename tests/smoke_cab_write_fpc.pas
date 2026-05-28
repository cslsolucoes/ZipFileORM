{ smoke_cab_write_fpc.pas — FPC-compatible CAB WRITE smoke }
program smoke_cab_write_fpc;
{$IFDEF FPC}{$mode delphi}{$H+}{$ENDIF}
uses
  SysUtils, Classes, CabFile;

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
    if FileExists(Src1) then DeleteFile(Src1);
    if FileExists(Src2) then DeleteFile(Src2);
    if FileExists(OutCab) then DeleteFile(OutCab);
    C := 'First file FPC v3.7.1 WRITE.';
    Stm := TFileStream.Create(Src1, fmCreate);
    try Stm.WriteBuffer(C[1], Length(C)); finally Stm.Free; end;
    C := 'Second file FPC Store mode.';
    Stm := TFileStream.Create(Src2, fmCreate);
    try Stm.WriteBuffer(C[1], Length(C)); finally Stm.Free; end;

    WriteLn('1. CreateFromFiles...');
    Cab := TCabFile.Create(nil);
    try
      Cab.FileName := OutCab;
      Cab.Compression := cctMSZIP;  // v3.7.2 — MSZIP funcional
      Cab.CreateFromFiles(['cab_write_src1.txt', 'first.txt',
                           'cab_write_src2.txt', 'second.txt']);
    finally Cab.Free; end;
    if not FileExists(OutCab) then begin WriteLn('   FAIL'); Halt(1); end;
    Stm := TFileStream.Create(OutCab, fmOpenRead);
    try WriteLn('   OK created (', Stm.Size, ' bytes)'); finally Stm.Free; end;

    WriteLn('2. Read back...');
    Cab := TCabFile.Create(nil);
    try
      Cab.FileName := OutCab;
      Cab.Active := True;
      WriteLn('   EntryCount=', Cab.EntryCount);
      if Cab.EntryCount <> 2 then begin WriteLn('   FAIL'); Halt(1); end;
      for I := 0 to Cab.EntryCount - 1 do
        WriteLn('   [', I, '] ', Cab.GetEntryName(I), '  size=', Cab.GetFileSize(I));
      ReadBack := Cab.ReadAsString('first.txt');
      WriteLn('   first.txt: "', ReadBack, '"');
      if ReadBack <> 'First file FPC v3.7.1 WRITE.' then begin WriteLn('   FAIL'); Halt(1); end;
      ReadBack := Cab.ReadAsString('second.txt');
      WriteLn('   second.txt: "', ReadBack, '"');
      if ReadBack <> 'Second file FPC Store mode.' then begin WriteLn('   FAIL'); Halt(1); end;
    finally Cab.Free; end;
    WriteLn('   PASS — full WRITE+READ round-trip OK');
  except
    on E: Exception do begin WriteLn('EXC: ', E.ClassName, ' ', E.Message); Halt(1); end;
  end;
end.
