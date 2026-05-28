{ ZipFile.Tests.AES.pas
  Fixture DUnitX cobrindo o caminho AES-256 WinZip-AE-2:
   - encrypt + decrypt round-trip com senha correta
   - bad password rejeitado via EZipAESError
   - tamper (modificar 1 byte do ciphertext) detectado por HMAC mismatch
   - missing Password ao ler entry AES-encrypted levanta erro claro
}
unit ZipFile.Tests.AES;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TAESTests = class
  public
    [Test] procedure Encrypt_Decrypt_RoundTrip;
    [Test] procedure BadPassword_RaisesEZipAESError;
    [Test] procedure TamperedCiphertext_RaisesHmacError;
    [Test] procedure MissingPasswordOnRead_RaisesEZipAESError;
  end;

implementation

uses
  System.SysUtils, System.Classes, ZipFile, Commons.Encryption.AES, ZipFile.Tests.Shared;

const
  PLAIN_TXT: AnsiString = 'AES-256 WinZip-AE-2 round-trip canonical sample 12345';
  PWD_OK    = 'correct horse battery staple';
  PWD_BAD   = 'wrong horse battery staple';

procedure CreateEncryptedArchive(const APath: string);
var
  Zip: TZipFile;
  S: TMemoryStream;
begin
  Zip := TZipFile.Create(nil);
  try
    Zip.FileName := APath;
    Zip.UseAES := True;
    Zip.Password := PWD_OK;
    Zip.Active := True;
    S := TZipTestHelpers.MakeAnsiStream(PLAIN_TXT);
    try Zip.AppendStream(S, 'secret.bin', Now); finally S.Free; end;
  finally
    Zip.Free;
  end;
end;

procedure TAESTests.Encrypt_Decrypt_RoundTrip;
var
  Path: string;
  Zip: TZipFile;
  Got: TMemoryStream;
  BufLen: Cardinal;
begin
  Path := TZipTestHelpers.MakeTempPath('aes_rt.zip');
  try
    CreateEncryptedArchive(Path);
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Password := PWD_OK;
      Zip.Active := True;
      BufLen := 0;
      Got := Zip.GetFileStream('secret.bin', BufLen);
      try
        Assert.AreEqual<AnsiString>(PLAIN_TXT, TZipTestHelpers.StreamToAnsi(Got),
          'plaintext nao bateu apos decrypt');
      finally
        Got.Free;
      end;
    finally
      Zip.Free;
    end;
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

procedure TAESTests.BadPassword_RaisesEZipAESError;
var
  Path: string;
  Zip: TZipFile;
  BufLen: Cardinal;
  GotStream: TMemoryStream;
begin
  Path := TZipTestHelpers.MakeTempPath('aes_bad.zip');
  try
    CreateEncryptedArchive(Path);
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Password := PWD_BAD;
      Zip.Active := True;
      BufLen := 0;
      Assert.WillRaise(
        procedure begin GotStream := Zip.GetFileStream('secret.bin', BufLen); GotStream.Free; end,
        EZipAESError,
        'bad password devia levantar EZipAESError'
      );
    finally
      Zip.Free;
    end;
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

procedure TAESTests.TamperedCiphertext_RaisesHmacError;
var
  Path: string;
  Zip: TZipFile;
  Fs: TFileStream;
  Buf: Byte;
  TamperOffset: Int64;
  BufLen: Cardinal;
  GotStream: TMemoryStream;
begin
  Path := TZipTestHelpers.MakeTempPath('aes_tamper.zip');
  try
    CreateEncryptedArchive(Path);
    // Encontra um byte no meio do ciphertext e inverte.
    // Layout: LFH(30) + filename(10='secret.bin') + extra(11) + salt(16) +
    //         pwd_verify(2) + cipher(Length(PLAIN_TXT)) + hmac(10) + CD + EOCD
    // Modificamos um byte da regiao do cipher (offset estimado conservador 80).
    TamperOffset := 30 + 10 + 11 + 16 + 2 + 5;
    Fs := TFileStream.Create(Path, fmOpenReadWrite);
    try
      Fs.Position := TamperOffset;
      Fs.ReadBuffer(Buf, 1);
      Buf := Buf xor $FF;  // flip all bits
      Fs.Position := TamperOffset;
      Fs.WriteBuffer(Buf, 1);
    finally
      Fs.Free;
    end;
    // Agora a senha correta vai derivar keys OK, mas HMAC vai falhar.
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Password := PWD_OK;
      Zip.Active := True;
      BufLen := 0;
      Assert.WillRaise(
        procedure begin GotStream := Zip.GetFileStream('secret.bin', BufLen); GotStream.Free; end,
        EZipAESError,
        'cipher tampered devia falhar via HMAC mismatch'
      );
    finally
      Zip.Free;
    end;
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

procedure TAESTests.MissingPasswordOnRead_RaisesEZipAESError;
var
  Path: string;
  Zip: TZipFile;
  BufLen: Cardinal;
  GotStream: TMemoryStream;
begin
  Path := TZipTestHelpers.MakeTempPath('aes_nopwd.zip');
  try
    CreateEncryptedArchive(Path);
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      // Password deliberadamente vazia
      Zip.Active := True;
      BufLen := 0;
      Assert.WillRaise(
        procedure begin GotStream := Zip.GetFileStream('secret.bin', BufLen); GotStream.Free; end,
        EZipAESError,
        'leitura de entry AES sem Password devia levantar EZipAESError'
      );
    finally
      Zip.Free;
    end;
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TAESTests);

end.
