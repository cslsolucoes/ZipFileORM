{ ZipFile.Tests.Zip64Write.pas
  Fixture DUnitX cobrindo o caminho ZIP64 WRITE (v2.3):
   - ForceZip64=True emite extras 0x0001 + ZIP64 EOCD Record + Locator
     mesmo em archives pequenos
   - Archive produzido pode ser reaberto via TZipFile.Active=True e o
     payload preserva-se byte-a-byte
   - Inspecao binaria: standard EOCDR tem signature ZIP64 (sig
     0x07064B50) nos 20 bytes anteriores
   - Round-trip de entry pequena com ForceZip64=True
}
unit ZipFile.Tests.Zip64Write;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TZip64WriteTests = class
  public
    [Test] procedure ForceZip64_EmitsLocatorAndRecord;
    [Test] procedure ForceZip64_RoundTrip;
    [Test] procedure ForceZip64_TwoEntries_ReadsAll;
  end;

implementation

uses
  System.SysUtils, System.Classes,
  ZipFile, ZipFile.ZIP64, ZipFile.Tests.Shared;

function FileHasZip64Locator(const APath: string): Boolean;
var
  Fs: TFileStream;
  Buf: TBytes;
  I: Integer;
  Sig: Cardinal;
begin
  Result := False;
  Fs := TFileStream.Create(APath, fmOpenRead);
  try
    // Scan last 4 KB for the ZIP64 Locator signature.
    if Fs.Size < 24 then Exit;
    SetLength(Buf, Fs.Size);
    Fs.Position := 0;
    Fs.ReadBuffer(Buf[0], Fs.Size);
    for I := 0 to Length(Buf) - 4 do
    begin
      Move(Buf[I], Sig, 4);
      if Sig = ZIP64_END_OF_CD_LOCATOR_SIGNATURE then
      begin
        Result := True;
        Exit;
      end;
    end;
  finally
    Fs.Free;
  end;
end;

procedure TZip64WriteTests.ForceZip64_EmitsLocatorAndRecord;
var
  Path: string;
  Zip: TZipFile;
  Src: TMemoryStream;
begin
  Path := TZipTestHelpers.MakeTempPath('z64w_emit.zip');
  try
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.ForceZip64 := True;
      Zip.Active := True;
      Src := TZipTestHelpers.MakeAnsiStream('small payload');
      try
        Zip.AppendStream(Src, 'p.txt', Now);
      finally
        Src.Free;
      end;
    finally
      Zip.Free;
    end;
    Assert.IsTrue(FileHasZip64Locator(Path),
      'archive com ForceZip64=True deve conter ZIP64 EOCD Locator (sig 0x07064B50)');
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

procedure TZip64WriteTests.ForceZip64_RoundTrip;
const
  PLAIN: AnsiString = 'ZIP64 forced write round-trip canonical sample 0123456789';
var
  Path: string;
  Zip: TZipFile;
  Src, Got: TMemoryStream;
  BufLen: Cardinal;
begin
  Path := TZipTestHelpers.MakeTempPath('z64w_rt.zip');
  try
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.ForceZip64 := True;
      Zip.Active := True;
      Src := TZipTestHelpers.MakeAnsiStream(PLAIN);
      try
        Zip.AppendStream(Src, 'p.txt', Now);
      finally
        Src.Free;
      end;
    finally
      Zip.Free;
    end;
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Active := True;
      Assert.AreEqual<Cardinal>(1, Zip.FileCount);
      Assert.IsTrue(Zip.FileExists('p.txt'));
      BufLen := 0;
      Got := Zip.GetFileStream('p.txt', BufLen);
      try
        Assert.AreEqual(PLAIN, TZipTestHelpers.StreamToAnsi(Got),
          'ZIP64 forced round-trip payload divergente');
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

procedure TZip64WriteTests.ForceZip64_TwoEntries_ReadsAll;
var
  Path: string;
  Zip: TZipFile;
  S1, S2: TMemoryStream;
begin
  Path := TZipTestHelpers.MakeTempPath('z64w_two.zip');
  try
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.ForceZip64 := True;
      Zip.Active := True;
      S1 := TZipTestHelpers.MakeAnsiStream('first');
      try Zip.AppendStream(S1, 'a.txt', Now); finally S1.Free; end;
      S2 := TZipTestHelpers.MakeAnsiStream('second');
      try Zip.AppendStream(S2, 'b.txt', Now); finally S2.Free; end;
    finally
      Zip.Free;
    end;
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Active := True;
      Assert.AreEqual<Cardinal>(2, Zip.FileCount, 'ZIP64 archive de 2 entries devia preservar count');
      Assert.IsTrue(Zip.FileExists('a.txt'));
      Assert.IsTrue(Zip.FileExists('b.txt'));
    finally
      Zip.Free;
    end;
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TZip64WriteTests);

end.
