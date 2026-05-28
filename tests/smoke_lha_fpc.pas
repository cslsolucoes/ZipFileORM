{ smoke_lha_fpc.pas — FPC-compatible LHA smoke }
program smoke_lha_fpc;
{$IFDEF FPC}{$mode delphi}{$H+}{$ENDIF}
uses
  SysUtils, Classes, LhaFile;
var
  Lha: TLhaFile;
  I: Integer;
  Got: string;
begin
  try
    if not FileExists('fixture.lha') then begin WriteLn('FAIL: no fixture.lha'); Halt(1); end;
    Lha := TLhaFile.Create(nil);
    try
      Lha.FileName := 'fixture.lha';
      Lha.Active := True;
      WriteLn('EntryCount=', Lha.EntryCount);
      for I := 0 to Lha.EntryCount - 1 do
        WriteLn('  [', I, '] ', Lha.GetEntryName(I), '  size=', Lha.GetFileSize(I),
                '  method=', Lha.GetEntryMethod(I));
      Got := Lha.ReadAsString('first.txt');
      WriteLn('first.txt -> "', Got, '"');
      if Got <> 'First LHA payload (Store -lh0- format)' then
      begin WriteLn('FAIL: first.txt'); Halt(1); end;
      Got := Lha.ReadAsString('second.txt');
      if Got <> 'Second file in LHA archive, deeper content' then
      begin WriteLn('FAIL: second.txt'); Halt(1); end;
      WriteLn('PASS — round-trip OK');
    finally Lha.Free; end;
  except
    on E: Exception do begin WriteLn('EXC: ', E.ClassName, ' ', E.Message); Halt(2); end;
  end;
end.
