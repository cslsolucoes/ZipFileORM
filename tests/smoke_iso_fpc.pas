{ smoke_iso_fpc.pas — FPC-compatible ISO 9660 smoke }
program smoke_iso_fpc;
{$IFDEF FPC}{$mode delphi}{$H+}{$ENDIF}
uses
  SysUtils, Classes, IsoFile;
var
  Iso: TIsoFile;
  I: Integer;
  Got: string;
begin
  try
    if not FileExists('fixture.iso') then begin WriteLn('FAIL: no fixture.iso'); Halt(1); end;
    Iso := TIsoFile.Create(nil);
    try
      Iso.FileName := 'fixture.iso';
      Iso.Active := True;
      WriteLn('VolumeID="', Iso.VolumeID, '" Joliet=', Iso.JolietActive);
      WriteLn('EntryCount=', Iso.EntryCount);
      for I := 0 to Iso.EntryCount - 1 do
        WriteLn('  [', I, '] ', Iso.GetEntryName(I), '  size=', Iso.GetFileSize(I));
      Got := Iso.ReadAsString('FIRST.TXT');
      WriteLn('FIRST.TXT -> "', Got, '"');
      if Got <> 'First file ISO payload from fixture builder' then
      begin WriteLn('FAIL: FIRST.TXT'); Halt(1); end;
      Got := Iso.ReadAsString('SUBDIR/SECOND.TXT');
      WriteLn('SECOND.TXT -> "', Got, '"');
      if Got <> 'Second file payload deeper in tree' then
      begin WriteLn('FAIL: SECOND.TXT'); Halt(1); end;
      WriteLn('PASS — round-trip OK');
    finally Iso.Free; end;
  except
    on E: Exception do begin WriteLn('EXC: ', E.ClassName, ' ', E.Message); Halt(2); end;
  end;
end.
