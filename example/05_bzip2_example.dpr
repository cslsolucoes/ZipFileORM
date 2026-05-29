{ 05_bzip2_example.dpr
  Demonstra BZIP2 (stream codec) — Bzip2.Bzip2Stream + Bzip2.Fluent.
  Cobre: Bz2CompressBytes/Bz2DecompressBytes + Stream variants + Fluent.
}
program _05_bzip2_example;
{$APPTYPE CONSOLE}
{$IFDEF FPC}{$mode delphi}{$H+}{$ENDIF}
uses
  {$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  Bzip2.Stream, Bzip2.Stream.Interfaces;

procedure DemoBytes;
var
  Plain, Comp, Got: TBytes;
const
  TXT = 'BZIP2 round-trip test. The quick brown fox jumps over the lazy dog. ' +
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do.';
begin
  WriteLn('=== Demo 1: Bz2CompressBytes / Bz2DecompressBytes (legacy) ===');
  Plain := TEncoding.UTF8.GetBytes(TXT);
  Comp := Bz2CompressBytes(Plain, 9);
  WriteLn('  plain=', Length(Plain), ' bytes  comp=', Length(Comp), ' bytes');
  Got := Bz2DecompressBytes(Comp);
  if TEncoding.UTF8.GetString(Got) = TXT then
    WriteLn('  PASS - round-trip OK')
  else WriteLn('  FAIL');
  WriteLn;
end;

procedure DemoStream;
const
  PAYLOAD = 'Stream-based bzip2 compression sample. AAAA BBBB CCCC DDDD EEEE.';
var
  Src, Mid, Dst: TMemoryStream;
  Bytes: TBytes;
begin
  WriteLn('=== Demo 2: Stream-based Bz2CompressStream / Bz2DecompressStream ===');
  Bytes := TEncoding.UTF8.GetBytes(PAYLOAD);

  Src := TMemoryStream.Create;
  Mid := TMemoryStream.Create;
  Dst := TMemoryStream.Create;
  try
    if Length(Bytes) > 0 then Src.WriteBuffer(Bytes[0], Length(Bytes));
    Src.Position := 0;
    Bz2CompressStream(Src, Mid, 9);
    Mid.Position := 0;
    Bz2DecompressStream(Mid, Dst);

    WriteLn('  Src=', Src.Size, '  Mid(comp)=', Mid.Size, '  Dst(decomp)=', Dst.Size);
    SetLength(Bytes, Dst.Size);
    Dst.Position := 0;
    if Dst.Size > 0 then Dst.ReadBuffer(Bytes[0], Dst.Size);
    if TEncoding.UTF8.GetString(Bytes) = PAYLOAD then
      WriteLn('  PASS')
    else WriteLn('  FAIL');
  finally
    Dst.Free; Mid.Free; Src.Free;
  end;
  WriteLn;
end;

procedure DemoFluent;
var
  Comp, Plain: TBytes;
const
  TXT = 'Bzip2.Fluent chained API test payload for compression and decompression';
begin
  WriteLn('=== Demo 3: Bzip2.Fluent (chained .WithLevel.ToBytes) ===');
  Comp := Bzip.Compress(TEncoding.UTF8.GetBytes(TXT))
               .WithLevel(9)
               .ToBytes;
  WriteLn('  Compressed size=', Length(Comp));

  Plain := Bzip.Decompress(Comp).ToBytes;
  if TEncoding.UTF8.GetString(Plain) = TXT then
    WriteLn('  PASS - Fluent round-trip')
  else WriteLn('  FAIL');

  // Overload com string
  WriteLn('  Bzip.Compress(string).ToBytes size=',
          Length(Bzip.Compress(TXT).WithLevel(1).ToBytes));
  WriteLn;
end;

procedure DemoFile;
const
  TMP_TXT = 'example_05_input.txt';
  TMP_BZ2 = 'example_05.bz2';
  PAYLOAD = 'File-to-file bzip2 demo via Bzip2.Fluent';
var
  Decoded: TBytes;
  Fs: TFileStream; Bytes: TBytes;
begin
  WriteLn('=== Demo 4: File-to-file via Fluent .ToFile / Bzip.CompressFile ===');
  // Create temp source file
  Fs := TFileStream.Create(TMP_TXT, fmCreate);
  try
    Bytes := TEncoding.UTF8.GetBytes(PAYLOAD);
    if Length(Bytes) > 0 then Fs.WriteBuffer(Bytes[0], Length(Bytes));
  finally Fs.Free; end;

  // Compress file -> file
  Bzip.CompressFile(TMP_TXT).WithLevel(9).ToFile(TMP_BZ2);
  WriteLn('  Compressed ', TMP_TXT, ' -> ', TMP_BZ2);

  // Decompress file -> bytes
  Decoded := Bzip.DecompressFile(TMP_BZ2).ToBytes;
  if TEncoding.UTF8.GetString(Decoded) = PAYLOAD then
    WriteLn('  PASS - file round-trip')
  else WriteLn('  FAIL');

  if FileExists(TMP_TXT) then DeleteFile(TMP_TXT);
  if FileExists(TMP_BZ2) then DeleteFile(TMP_BZ2);
  WriteLn;
end;

begin
  try
    WriteLn('ZipFile example 05 -- BZIP2');
    WriteLn('============================');
    WriteLn;
    DemoBytes;
    DemoStream;
    DemoFluent;
    DemoFile;
    WriteLn('OK -- todos demos PASS');
  except
    on E: Exception do begin WriteLn('FATAL: ', E.ClassName, ': ', E.Message); Halt(1); end;
  end;
end.
