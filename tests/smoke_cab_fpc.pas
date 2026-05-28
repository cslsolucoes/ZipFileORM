{ smoke_cab_fpc.pas — FPC-compatible CAB smoke test }
program smoke_cab_fpc;
{$IFDEF FPC}{$mode delphi}{$H+}{$ENDIF}
uses
  SysUtils, Classes, CabFile;

var
  Cab: TCabFile;
  I: Integer;
  S: string;
begin
  try
    WriteLn('TCabFile FPC smoke — opening cab_fixture.cab');
    Cab := TCabFile.Create(nil);
    try
      Cab.FileName := 'cab_fixture.cab';
      Cab.Active := True;
      WriteLn('  EntryCount: ', Cab.EntryCount);
      for I := 0 to Cab.EntryCount - 1 do
        WriteLn('  [', I, '] ', Cab.GetEntryName(I), '  size=', Cab.GetFileSize(I));
      if Cab.EntryCount > 0 then
      begin
        S := Cab.ReadAsString(Cab.GetEntryName(0));
        WriteLn('  First entry contents: "', S, '"');
      end;
      WriteLn('  PASS');
    finally Cab.Free; end;
  except
    on E: Exception do
    begin
      WriteLn('EXCEPTION: ', E.ClassName, ' ', E.Message);
      Halt(1);
    end;
  end;
end.
