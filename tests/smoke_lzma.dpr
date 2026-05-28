program smoke_lzma;
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes, Commons.Compression.LZMA;
var
  Plain, Comp, Props, Got: TBytes;
  I: Integer;
begin
  try
    // Build a compressible payload (repeated pattern)
    SetLength(Plain, 4096);
    for I := 0 to High(Plain) do
      Plain[I] := Byte(I mod 23);
    WriteLn('plain size = ', Length(Plain));

    LzmaCompressBuffer(Plain, Length(Plain), Comp, Props, 5);
    WriteLn('comp size  = ', Length(Comp));
    WriteLn('props size = ', Length(Props));

    LzmaDecompressBuffer(Comp, Length(Comp), Props, Got, Length(Plain));
    WriteLn('got size   = ', Length(Got));

    for I := 0 to High(Plain) do
      if Got[I] <> Plain[I] then
      begin
        WriteLn('MISMATCH at byte ', I);
        Halt(1);
      end;
    WriteLn('OK round-trip LZMA');
  except
    on E: Exception do
    begin
      WriteLn('FATAL: ', E.ClassName, ' / ', E.Message);
      Halt(2);
    end;
  end;
end.
