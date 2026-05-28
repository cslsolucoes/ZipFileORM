{ 10_z_example.dpr
  Demonstra Z LZW (.Z compress legacy) — ZCompress.LzwStream + ZCompress.Fluent.
}
program _10_z_example;
{$APPTYPE CONSOLE}
{$IFDEF FPC}{$mode delphi}{$H+}{$ENDIF}
uses
  {$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ZCompress.LzwStream, ZCompress.Fluent;

procedure DemoBytes;
var Plain, Comp, Got: TBytes;
const TXT = 'Z LZW round-trip test. Lorem ipsum dolor sit amet consectetur.';
begin
  WriteLn('=== Demo 1: ZCompressBytes / ZDecompressBytes (legacy) ===');
  Plain := TEncoding.UTF8.GetBytes(TXT);
  Comp := ZCompressBytes(Plain, Z_BITS_MAX);
  WriteLn('  plain=', Length(Plain), '  comp=', Length(Comp));
  Got := ZDecompressBytes(Comp);
  if TEncoding.UTF8.GetString(Got) = TXT then
    WriteLn('  PASS - round-trip')
  else WriteLn('  FAIL');
  WriteLn;
end;

procedure DemoFluent;
var Comp, Plain: TBytes;
const TXT = 'ZCompress.Fluent chained API. AAAA BBBB CCCC DDDD EEEE.';
begin
  WriteLn('=== Demo 2: ZCompress.Fluent chained ===');
  Comp := Zlw.Compress(TEncoding.UTF8.GetBytes(TXT))
                   .WithMaxBits(Z_BITS_MAX)
                   .ToBytes;
  Plain := Zlw.Decompress(Comp).ToBytes;
  if TEncoding.UTF8.GetString(Plain) = TXT then
    WriteLn('  PASS - Fluent round-trip')
  else WriteLn('  FAIL');

  WriteLn('  Zlw.Compress(string).ToBytes size=',
          Length(Zlw.Compress(TXT).ToBytes));
  WriteLn;
end;

procedure DemoFile;
const
  TMP_TXT = 'example_10_input.txt';
  TMP_Z   = 'example_10.z';
  PAYLOAD = 'File-to-file Z LZW demo content';
var
  Fs: TFileStream; B: TBytes; Got: TBytes;
begin
  WriteLn('=== Demo 3: File-to-file ZCompress.Fluent ===');
  Fs := TFileStream.Create(TMP_TXT, fmCreate);
  try B := TEncoding.UTF8.GetBytes(PAYLOAD); if Length(B) > 0 then Fs.WriteBuffer(B[0], Length(B));
  finally Fs.Free; end;

  Zlw.CompressFile(TMP_TXT).ToFile(TMP_Z);
  Got := Zlw.DecompressFile(TMP_Z).ToBytes;
  if TEncoding.UTF8.GetString(Got) = PAYLOAD then
    WriteLn('  PASS - file round-trip')
  else WriteLn('  FAIL');

  if FileExists(TMP_TXT) then DeleteFile(TMP_TXT);
  if FileExists(TMP_Z) then DeleteFile(TMP_Z);
  WriteLn;
end;

begin
  try
    WriteLn('ZipFile example 10 -- Z LZW (.Z compress)');
    WriteLn('==========================================');
    WriteLn;
    DemoBytes;
    DemoFluent;
    DemoFile;
    WriteLn('OK -- todos demos PASS');
  except
    on E: Exception do begin WriteLn('FATAL: ', E.ClassName, ': ', E.Message); Halt(1); end;
  end;
end.
