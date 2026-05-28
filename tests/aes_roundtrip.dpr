{ aes_roundtrip.lpr
  FPC console smoke-test for the v1.9 AES-256 WinZip-AE-2 path.
  Creates an archive with a single file, encrypts it, then re-opens
  the archive and verifies that GetFileStream returns the plaintext.
}
program aes_roundtrip;

{$IFDEF FPC}{$mode delphi}{$H+}{$ENDIF}
{$APPTYPE CONSOLE}

uses
  {$IFNDEF FPC}
  System.SysUtils, System.Classes,
  {$ELSE}
  SysUtils, Classes,
  {$ENDIF}
  ZipFile;

const
  TEST_ZIP      = 'aes_test.zip';
  ENTRY_NAME    = 'hello.txt';
  PASSWORD_OK   = 'correct horse battery staple';
  PASSWORD_BAD  = 'wrong horse battery staple';

var
  PLAINTEXT: AnsiString = 'The quick brown fox jumps over the lazy dog 1234567890 -- AES round trip.';

procedure WriteEncryptedArchive;
var
  Zip: TZipFile;
  Src: TMemoryStream;
begin
  if FileExists(TEST_ZIP) then
    DeleteFile(TEST_ZIP);
  Zip := TZipFile.Create(nil);
  try
    Zip.FileName := TEST_ZIP;
    Zip.UseAES := True;
    Zip.Password := PASSWORD_OK;
    Zip.Active := True;
    Src := TMemoryStream.Create;
    try
      Src.WriteBuffer(PLAINTEXT[1], Length(PLAINTEXT));
      Src.Position := 0;
      try
        Zip.AppendStream(Src, ENTRY_NAME, Now);
      except
        on E: Exception do
        begin
          WriteLn('FATAL AppendStream: ', E.ClassName, ' / ', E.Message);
          Halt(4);
        end;
      end;
    finally
      Src.Free;
    end;
  finally
    Zip.Free;
  end;
  WriteLn('OK  write encrypted archive (', TEST_ZIP, ')');
end;

procedure ReadAndVerify(const APassword: string; AExpectSuccess: Boolean);
var
  Zip: TZipFile;
  Stm: TMemoryStream;
  BufLen: Cardinal;
  Got: AnsiString;
begin
  Zip := TZipFile.Create(nil);
  try
    Zip.FileName := TEST_ZIP;
    Zip.Password := APassword;
    Zip.Active := True;
    try
      BufLen := 0;
      Stm := Zip.GetFileStream(ENTRY_NAME, BufLen);
      try
        SetLength(Got, Stm.Size);
        if Stm.Size > 0 then
          Move(PByte(Stm.Memory)^, Got[1], Stm.Size);
        if Got = PLAINTEXT then
          WriteLn('OK  decrypt + plaintext match  (', Length(Got), ' bytes)')
        else
        begin
          WriteLn('FAIL  plaintext mismatch');
          WriteLn('   got: ', Got);
          Halt(1);
        end;
      finally
        Stm.Free;
      end;
      if not AExpectSuccess then
      begin
        WriteLn('FAIL  expected exception with bad password but got success');
        Halt(1);
      end;
    except
      on E: Exception do
      begin
        if AExpectSuccess then
        begin
          WriteLn('FAIL  unexpected exception: ', E.ClassName, ' / ', E.Message);
          Halt(1);
        end;
        WriteLn('OK  bad password rejected: ', E.Message);
      end;
    end;
  finally
    Zip.Free;
  end;
end;

begin
  try
    Randomize;
    WriteEncryptedArchive;
    ReadAndVerify(PASSWORD_OK, True);
    ReadAndVerify(PASSWORD_BAD, False);
    WriteLn('--- AES round-trip suite passed ---');
  except
    on E: Exception do
    begin
      WriteLn('FATAL: ', E.ClassName, ' / ', E.Message);
      Halt(2);
    end;
  end;
end.
