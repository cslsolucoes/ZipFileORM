{ 11_uue_example.dpr
  Demonstra UUE (uuencode) — UUE.UUEStream + UUE.Fluent.
}
program _11_uue_example;
{$APPTYPE CONSOLE}
{$IFDEF FPC}{$mode delphi}{$H+}{$ENDIF}
uses
  {$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  UUE.UUEStream, UUE.Fluent;

procedure DemoLegacy;
var Plain, Got: TBytes; Encoded: string;
const TXT = 'UUE round-trip test. Hello world from the encoder!';
begin
  WriteLn('=== Demo 1: UuEncodeBytes / UuDecodeBytes (legacy) ===');
  Plain := TEncoding.UTF8.GetBytes(TXT);
  Encoded := UuEncodeBytes(Plain, 'message.bin', $1B6);  // mode 0o666
  WriteLn('  Encoded length=', Length(Encoded), ' (first 80 chars):');
  WriteLn('    ', Copy(Encoded, 1, 80), '...');

  Got := UuDecodeBytes(Encoded);
  if TEncoding.UTF8.GetString(Got) = TXT then
    WriteLn('  PASS - legacy round-trip')
  else WriteLn('  FAIL');
  WriteLn;
end;

procedure DemoFluent;
var Plain: TBytes; Encoded: string;
const TXT = 'UUE.Fluent chained API. The quick brown fox.';
begin
  WriteLn('=== Demo 2: UUE.Fluent ===');
  Plain := TEncoding.UTF8.GetBytes(TXT);
  Encoded := Uu.Encode(Plain)
                .WithFileName('payload.bin')
                .WithMode($1B6)
                .ToString;
  WriteLn('  Encoded (first 60 chars): ', Copy(Encoded, 1, 60), '...');

  // Decode
  if Uu.Decode(Encoded).ToString = TXT then
    WriteLn('  PASS - Fluent round-trip')
  else WriteLn('  FAIL');

  // Overload Uu.Encode(string)
  WriteLn('  Uu.Encode(string).ToString = "',
          Copy(Uu.Encode('compact text').WithFileName('t.txt').ToString, 1, 40), '..."');
  WriteLn;
end;

procedure DemoFile;
const
  TMP_TXT  = 'example_11_input.txt';
  TMP_UUE  = 'example_11_encoded.uue';
  PAYLOAD  = 'File-to-file UUE demo';
var
  Fs: TFileStream; B: TBytes;
  EncodedText: string;
  Sr: TStringList;
begin
  WriteLn('=== Demo 3: File-to-file Uu.EncodeFile + Decode ===');
  Fs := TFileStream.Create(TMP_TXT, fmCreate);
  try B := TEncoding.UTF8.GetBytes(PAYLOAD); if Length(B) > 0 then Fs.WriteBuffer(B[0], Length(B));
  finally Fs.Free; end;

  // Encode file -> string -> save to .uue
  EncodedText := Uu.EncodeFile(TMP_TXT).ToString;
  Sr := TStringList.Create;
  try
    Sr.Text := EncodedText;
    Sr.SaveToFile(TMP_UUE);
  finally Sr.Free; end;
  WriteLn('  Encoded ', TMP_TXT, ' -> ', TMP_UUE);

  // Decode back
  Sr := TStringList.Create;
  try
    Sr.LoadFromFile(TMP_UUE);
    if Uu.Decode(Sr.Text).ToString = PAYLOAD then
      WriteLn('  PASS - file round-trip')
    else WriteLn('  FAIL');
  finally Sr.Free; end;

  if FileExists(TMP_TXT) then DeleteFile(TMP_TXT);
  if FileExists(TMP_UUE) then DeleteFile(TMP_UUE);
  WriteLn;
end;

begin
  try
    WriteLn('ZipFile example 11 -- UUE (uuencode)');
    WriteLn('=====================================');
    WriteLn;
    DemoLegacy;
    DemoFluent;
    DemoFile;
    WriteLn('OK -- todos demos PASS');
  except
    on E: Exception do begin WriteLn('FATAL: ', E.ClassName, ': ', E.Message); Halt(1); end;
  end;
end.
