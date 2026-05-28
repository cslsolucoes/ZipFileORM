program smoke_iso;
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  IsoFile in '..\src\IsoFile.pas';

var
  Iso: TIsoFile;
  I: Integer;
  Got: string;
begin
  try
    WriteLn('smoke_iso â€” TIsoFile READ ', {$IFDEF WIN64}'Win64'{$ELSE}'Win32'{$ENDIF});
    if not FileExists('fixture.iso') then
    begin
      WriteLn('FAIL: fixture.iso not present');
      Halt(1);
    end;

    Iso := TIsoFile.Create(nil);
    try
      Iso.FileName := 'fixture.iso';
      Iso.Active := True;
      WriteLn('VolumeID="', Iso.VolumeID, '" Joliet=', Iso.JolietActive);
      WriteLn('EntryCount=', Iso.EntryCount);
      for I := 0 to Iso.EntryCount - 1 do
        WriteLn('  [', I, '] "', Iso.GetEntryName(I), '"  size=', Iso.GetFileSize(I),
                '  isdir=', Iso.IsDir(I));

      // ISO9660 puro (sem Joliet): nomes upper-case 8.3.
      Got := Iso.ReadAsString('FIRST.TXT');
      WriteLn('FIRST.TXT       -> "', Got, '"');
      if Got <> 'First file ISO payload from fixture builder' then
      begin WriteLn('FAIL: FIRST.TXT mismatch'); Halt(1); end;

      Got := Iso.ReadAsString('SUBDIR/SECOND.TXT');
      WriteLn('SUBDIR/SECOND.TXT -> "', Got, '"');
      if Got <> 'Second file payload deeper in tree' then
      begin WriteLn('FAIL: SECOND.TXT mismatch'); Halt(1); end;

      WriteLn('PASS â€” TIsoFile round-trip OK');
    finally
      Iso.Free;
    end;
  except
    on E: Exception do
    begin
      WriteLn('EXC: ', E.ClassName, ' / ', E.Message);
      Halt(2);
    end;
  end;
end.
