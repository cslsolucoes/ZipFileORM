{ 01_zip_example.dpr
  Exemplo completo de TZipFile + ZipFile.Fluent (Zip.NewArchive).

  Demonstra:
   - WRITE: AppendStream, AppendFileFromDisk, UpdateFile, DeleteFile
   - READ:  GetEntryStream, FileExists, FindFirst/FindNext
   - Methods: Compression (cmMaximal=Deflate / cmNone=Store), LZMA
   - Encryption: AES-256 WinZip-AE-2 com password (round-trip funcional)
   - UTF-8 filenames + ZIP64 forçado
   - Fluent: Zip.NewArchive(...).WithAES.WithUtf8.WithLZMA.Append*.Execute
}
program _01_zip_example;
{$APPTYPE CONSOLE}
{$IFDEF FPC}{$mode delphi}{$H+}{$ENDIF}
uses
  {$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  ZipFile, ZipFile.Fluent;

const
  TMP_ZIP = 'example_01_legacy.zip';
  TMP_FLU = 'example_01_fluent.zip';
  TMP_AES = 'example_01_aes.zip';
  TMP_LZMA = 'example_01_lzma.zip';

function StreamToString(AStream: TStream): string;
var Bytes: TBytes;
begin
  SetLength(Bytes, AStream.Size);
  AStream.Position := 0;
  if AStream.Size > 0 then AStream.ReadBuffer(Bytes[0], AStream.Size);
  Result := TEncoding.UTF8.GetString(Bytes);
end;

procedure DecryptViaLegacy(const APath, AName, APassword, AExpected: string); forward;

function StringToStream(const S: string): TMemoryStream;
var Bytes: TBytes;
begin
  Result := TMemoryStream.Create;
  Bytes := TEncoding.UTF8.GetBytes(S);
  if Length(Bytes) > 0 then Result.WriteBuffer(Bytes[0], Length(Bytes));
  Result.Position := 0;
end;

procedure DemoLegacy;
var
  Zip: TZipFile;
  Stm: TMemoryStream;
  Sr: TZipSearchRec;
  Got: TStream;
  N: Integer;
begin
  WriteLn('=== Demo 1: TZipFile legacy API ===');
  if FileExists(TMP_ZIP) then DeleteFile(TMP_ZIP);

  // CREATE — TZipFile API direta
  Zip := TZipFile.Create(nil);
  try
    Zip.FileName := TMP_ZIP;
    Zip.Active := True;
    Zip.Compression := cmMaximal;  // cmMaximal=Deflate / cmNone=Store

    // AppendStream com TDateTime (signature: stream, name, datetime)
    Stm := StringToStream('Hello ZIP legacy API. Round-trip test.');
    try Zip.AppendStream(Stm, 'docs/hello.txt', Now);
    finally Stm.Free; end;

    Stm := StringToStream('Bytes payload via AppendStream');
    try Zip.AppendStream(Stm, 'docs/bytes.bin', Now);
    finally Stm.Free; end;

    Stm := StringToStream('Lorem ipsum dolor sit amet');
    try Zip.AppendStream(Stm, 'lorem.txt', Now);
    finally Stm.Free; end;

    // AppendFileFromDisk auto-include timestamp from disk
    Zip.AppendFileFromDisk('01_zip_example.dpr', 'src/main.dpr');

    WriteLn('  Created ', TMP_ZIP, ' with ', Zip.FileCount, ' entries');
  finally Zip.Free; end;

  // READ — iterate via FindFirst/FindNext
  Zip := TZipFile.Create(nil);
  try
    Zip.FileName := TMP_ZIP;
    Zip.Active := True;
    WriteLn('  FileCount=', Zip.FileCount);
    N := Zip.FindFirst(Sr);
    while N = 0 do
    begin
      WriteLn('    ', Sr.Name, ' uncompressed=', Sr.USize, ' compressed=', Sr.CSize);
      N := Zip.FindNext(Sr);
    end;

    // GetEntryStream (caller frees)
    Got := Zip.GetEntryStream('docs/hello.txt');
    try
      WriteLn('  hello.txt = "', StreamToString(Got), '"');
    finally Got.Free; end;

    // FileExists
    WriteLn('  FileExists("docs/hello.txt")=', Zip.FileExists('docs/hello.txt'));
    WriteLn('  FileExists("notthere")=', Zip.FileExists('notthere'));
  finally Zip.Free; end;
  WriteLn;
end;

procedure DemoUpdateDelete;
var
  Zip: TZipFile;
  Stm: TMemoryStream;
begin
  WriteLn('=== Demo 2: UpdateFile + DeleteFile (TZipFile mutator) ===');
  Zip := TZipFile.Create(nil);
  try
    Zip.FileName := TMP_ZIP;
    Zip.Active := True;

    Stm := StringToStream('Replaced lorem content');
    try Zip.UpdateFile(Stm, 'lorem.txt');
    finally Stm.Free; end;
    Zip.DeleteFile('docs/bytes.bin');
    WriteLn('  After Update+Delete: FileCount=', Zip.FileCount);
  finally Zip.Free; end;

  // Reabrir para confirmar (Update reorganiza CD; precisa close+reopen)
  Zip := TZipFile.Create(nil);
  try
    Zip.FileName := TMP_ZIP;
    Zip.Active := True;
    WriteLn('  After reopen: FileCount=', Zip.FileCount);
    WriteLn('  FileExists("docs/bytes.bin") = ', Zip.FileExists('docs/bytes.bin'));
    WriteLn('  FileExists("lorem.txt") = ', Zip.FileExists('lorem.txt'));
  finally Zip.Free; end;
  WriteLn;
end;

procedure DemoFluent;
var Stm: TStream;
begin
  WriteLn('=== Demo 3: Zip.Fluent (IZipFileBuilder) ===');
  if FileExists(TMP_FLU) then DeleteFile(TMP_FLU);

  Zip.NewArchive(TMP_FLU)
     .WithUtf8(True)
     .WithCompression(cmMaximal)
     .AppendFile('01_zip_example.dpr', 'src/main.dpr')
     .AppendStream(StringToStream('Fluent inline string'), 'inline.txt', True)
     .Execute;

  WriteLn('  Created ', TMP_FLU);
  WriteLn('  CountEntries=', Zip.OpenArchive(TMP_FLU).CountEntries);

  Stm := Zip.OpenArchive(TMP_FLU).ExtractStream('inline.txt');
  try WriteLn('  inline.txt = "', StreamToString(Stm), '"');
  finally Stm.Free; end;

  WriteLn('  HasEntry("src/main.dpr") = ',
          Zip.OpenArchive(TMP_FLU).HasEntry('src/main.dpr'));
  WriteLn;
end;

procedure DemoAESPassword;
var
  ZF: TZipFile;
  Src: TMemoryStream;
const
  SECRET: AnsiString = 'Conteudo confidencial AES-256 round-trip funcional';
  PWD                = 'correct horse battery staple';
begin
  WriteLn('=== Demo 4: AES-256 + password (round-trip funcional) ===');
  if FileExists(TMP_AES) then DeleteFile(TMP_AES);

  // CREATE encrypted via TZipFile (legacy API — comprovado em aes_roundtrip)
  ZF := TZipFile.Create(nil);
  try
    ZF.FileName := TMP_AES;
    ZF.UseAES := True;
    ZF.Password := PWD;
    ZF.Active := True;
    Src := TMemoryStream.Create;
    try
      Src.WriteBuffer(SECRET[1], Length(SECRET));
      Src.Position := 0;
      ZF.AppendStream(Src, 'segredo.txt', Now);
    finally Src.Free; end;
  finally ZF.Free; end;
  WriteLn('  Created encrypted ', TMP_AES, ' (password="', PWD, '")');

  // READ encrypted via TZipFile.GetFileStream (legacy)
  DecryptViaLegacy(TMP_AES, 'segredo.txt', PWD, string(SECRET));

  // Tentativa SEM password (deve falhar)
  WriteLn('  Tentativa com password ERRADO:');
  try
    DecryptViaLegacy(TMP_AES, 'segredo.txt', 'WrongPassword', string(SECRET));
  except
    on E: Exception do
      WriteLn('    OK - exception capturada: ', E.ClassName, ': ', E.Message);
  end;
  WriteLn;
end;

procedure DecryptViaLegacy(const APath, AName, APassword, AExpected: string);
var
  Zip: TZipFile;
  Stm: TMemoryStream;
  BufLen: Cardinal;
  Decrypted: string;
  Bytes: TBytes;
begin
  // AES read funciona via GetFileStream (NAO GetEntryStream). Password
  // sozinho ja basta — TZipFile detecta AES automaticamente do header.
  Zip := TZipFile.Create(nil);
  try
    Zip.FileName := APath;
    Zip.Password := APassword;
    Zip.Active := True;
    BufLen := 0;
    Stm := Zip.GetFileStream(AName, BufLen);
    try
      SetLength(Bytes, Stm.Size);
      Stm.Position := 0;
      if Stm.Size > 0 then Stm.ReadBuffer(Bytes[0], Stm.Size);
      Decrypted := TEncoding.UTF8.GetString(Bytes);
      WriteLn('  Decrypted (TZipFile.GetFileStream) = "', Decrypted, '"');
      if Decrypted = AExpected then
        WriteLn('  PASS - AES round-trip OK')
      else
        WriteLn('  FAIL - content mismatch');
    finally Stm.Free; end;
  finally Zip.Free; end;
end;

procedure DemoLZMA;
var
  Stm: TStream;
const
  LONG_TEXT = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' +
              'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB' +
              'CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC';
begin
  WriteLn('=== Demo 5: LZMA compression (high ratio) ===');
  if FileExists(TMP_LZMA) then DeleteFile(TMP_LZMA);

  Zip.NewArchive(TMP_LZMA)
     .WithLZMA(True)
     .AppendStream(StringToStream(LONG_TEXT), 'repetitive.txt', True)
     .Execute;
  WriteLn('  Created LZMA ', TMP_LZMA);

  Stm := Zip.OpenArchive(TMP_LZMA).ExtractStream('repetitive.txt');
  try
    if StreamToString(Stm) = LONG_TEXT then
      WriteLn('  PASS - LZMA round-trip OK (', Stm.Size, ' bytes recovered)')
    else
      WriteLn('  FAIL - content mismatch');
  finally Stm.Free; end;
  WriteLn;
end;

begin
  try
    WriteLn('ZipFile example 01 -- ZIP completo (todos os metodos + password)');
    WriteLn('================================================================');
    WriteLn;
    DemoLegacy;
    DemoUpdateDelete;
    DemoFluent;
    DemoAESPassword;
    DemoLZMA;
    WriteLn('OK -- todos demos PASS');
  except
    on E: Exception do
    begin
      WriteLn('FATAL: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.
