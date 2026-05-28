program smoke_bzip2;
{$APPTYPE CONSOLE}
uses
  System.SysUtils,
  Bzip2.Stream in '..\src\Bzip2.Stream.pas';

const
  N = 64 * 1024;

var
  Src, Comp, Dec: TBytes;
  I: Integer;
begin
  WriteLn('BZIP2 round-trip ', N, ' bytes...');
  try
    SetLength(Src, N);
    for I := 0 to N - 1 do Src[I] := Byte(I mod 251);  // semi-pattern
    Comp := Bz2CompressBytes(Src, 9);
    WriteLn('  original: ', N, '  compressed: ', Length(Comp));
    Dec := Bz2DecompressBytes(Comp);
    WriteLn('  decompressed: ', Length(Dec));
    if Length(Dec) <> N then begin WriteLn('  FAIL size'); Halt(1); end;
    for I := 0 to N - 1 do
      if Dec[I] <> Src[I] then begin WriteLn('  FAIL byte ', I); Halt(1); end;
    WriteLn('  PASS');
  except
    on E: Exception do
    begin
      WriteLn('EXCEPTION: ', E.ClassName, ' ', E.Message);
      Halt(1);
    end;
  end;
end.
