program smoke_uue_lzw;
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  UUE.Stream in '..\src\UUE.Stream.pas',
  ZCompress.LzwStream in '..\src\ZCompress.LzwStream.pas';

procedure TestUUE;
var
  Src, Dec: TBytes;
  Enc: string;
  I, N: Integer;
begin
  WriteLn('--- UUE round-trip ---');
  N := 200;
  SetLength(Src, N);
  for I := 0 to N - 1 do Src[I] := Byte(I);
  Enc := UuEncodeBytes(Src, 'test.bin');
  WriteLn('  encoded length: ', Length(Enc));
  Dec := UuDecodeBytes(Enc);
  WriteLn('  decoded length: ', Length(Dec));
  if Length(Dec) <> N then begin WriteLn('  FAIL: size'); Halt(1); end;
  for I := 0 to N - 1 do
    if Dec[I] <> Src[I] then
    begin
      WriteLn('  FAIL byte ', I, ': src=', Src[I], ' dec=', Dec[I]);
      Halt(1);
    end;
  WriteLn('  PASS');
end;

procedure TestLZW;
var
  Src, Comp, Dec: TBytes;
  I, N: Integer;
  S: string;
begin
  WriteLn('--- Z LZW round-trip ---');
  S := 'TOBEORNOTTOBEORTOBEORNOT';
  for I := 0 to 4 do S := S + S;  // 768 bytes repetitivos
  N := Length(S);
  SetLength(Src, N);
  for I := 0 to N - 1 do Src[I] := Byte(S[I + 1]);
  Comp := ZCompressBytes(Src, 12);
  WriteLn('  original: ', N, '  compressed: ', Length(Comp));
  Dec := ZDecompressBytes(Comp);
  WriteLn('  decompressed: ', Length(Dec));
  if Length(Dec) <> N then
  begin
    WriteLn('  FAIL: size ', Length(Dec), ' != ', N);
    Halt(1);
  end;
  for I := 0 to N - 1 do
    if Dec[I] <> Src[I] then
    begin
      WriteLn('  FAIL byte ', I);
      Halt(1);
    end;
  WriteLn('  PASS');
end;

begin
  try
    TestUUE;
    TestLZW;
    WriteLn('All smoke tests PASS');
  except
    on E: Exception do
    begin
      WriteLn('EXCEPTION: ', E.ClassName, ' ', E.Message);
      Halt(1);
    end;
  end;
end.
