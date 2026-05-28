{ ZipFile.Tests.LZMA.pas
  Fixture DUnitX cobrindo o caminho LZMA (PKWARE method 14):
   - Encode + decode round-trip de payload comprimivel
   - Compression ratio comprovada (entropy baixa â‡’ output << input)
   - Reabertura preserva entry
   - Sanity: tamanho compressedsize <= uncompressedsize+overhead
   - LZMA + AES juntos sao explicitamente rejeitados (v2.1 limita escopo)
}
unit ZipFile.Tests.LZMA;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TLZMATests = class
  public
    [Test] procedure LZMA_RoundTrip_RepeatedPattern;
    [Test] procedure LZMA_CompressionRatio_BetterThanStore;
    [Test] procedure LZMA_PlusAES_RaisesExplicit;
  end;

implementation

uses
  System.SysUtils, System.Classes, ZipFile,
  Commons.Compression.LZMA, ZipFile.Tests.Shared;

procedure TLZMATests.LZMA_RoundTrip_RepeatedPattern;
var
  Path: string;
  Zip: TZipFile;
  Src, Got: TMemoryStream;
  Payload: TBytes;
  I: Integer;
  BufLen: Cardinal;
begin
  Path := TZipTestHelpers.MakeTempPath('lzma_rt.zip');
  try
    SetLength(Payload, 4096);
    for I := 0 to High(Payload) do
      Payload[I] := Byte(I mod 23);  // compressible repeating pattern
    Src := TMemoryStream.Create;
    try
      Src.WriteBuffer(Payload[0], Length(Payload));
      Src.Position := 0;
      Zip := TZipFile.Create(nil);
      try
        Zip.FileName := Path;
        Zip.UseLZMA := True;
        Zip.Active := True;
        Zip.AppendStream(Src, 'p.bin', Now);
      finally
        Zip.Free;
      end;
    finally
      Src.Free;
    end;
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Active := True;
      BufLen := 0;
      Got := Zip.GetFileStream('p.bin', BufLen);
      try
        Assert.AreEqual<Int64>(4096, Got.Size, 'tamanho desempacotado incorreto');
        Got.Position := 0;
        for I := 0 to High(Payload) do
        begin
          var B: Byte;
          Got.ReadBuffer(B, 1);
          if B <> Payload[I] then
          begin
            Assert.Fail(Format('LZMA round-trip byte %d divergiu (esperado %d, lido %d)',
              [I, Payload[I], B]));
            Break;
          end;
        end;
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

procedure TLZMATests.LZMA_CompressionRatio_BetterThanStore;
var
  PathL, PathS: string;
  Zip: TZipFile;
  Src: TMemoryStream;
  Payload: TBytes;
  I: Integer;
  SizeL, SizeS: Int64;
  Fs: TFileStream;
begin
  PathL := TZipTestHelpers.MakeTempPath('lzma_size.zip');
  PathS := TZipTestHelpers.MakeTempPath('store_size.zip');
  try
    SetLength(Payload, 8192);
    for I := 0 to High(Payload) do
      Payload[I] := Byte(I mod 7);
    // LZMA archive
    Src := TMemoryStream.Create;
    try
      Src.WriteBuffer(Payload[0], Length(Payload));
      Src.Position := 0;
      Zip := TZipFile.Create(nil);
      try
        Zip.FileName := PathL;
        Zip.UseLZMA := True;
        Zip.Active := True;
        Zip.AppendStream(Src, 'p.bin', Now);
      finally
        Zip.Free;
      end;
    finally
      Src.Free;
    end;
    // STORE archive
    Src := TMemoryStream.Create;
    try
      Src.WriteBuffer(Payload[0], Length(Payload));
      Src.Position := 0;
      Zip := TZipFile.Create(nil);
      try
        Zip.FileName := PathS;
        Zip.Active := True;
        Zip.AppendStream(Src, 'p.bin', Now);
      finally
        Zip.Free;
      end;
    finally
      Src.Free;
    end;
    Fs := TFileStream.Create(PathL, fmOpenRead);
    try SizeL := Fs.Size; finally Fs.Free; end;
    Fs := TFileStream.Create(PathS, fmOpenRead);
    try SizeS := Fs.Size; finally Fs.Free; end;
    Assert.IsTrue(SizeL < SizeS,
      Format('LZMA (%d bytes) deveria ser menor que STORE (%d bytes)', [SizeL, SizeS]));
  finally
    TZipTestHelpers.DeleteIfExists(PathL);
    TZipTestHelpers.DeleteIfExists(PathS);
  end;
end;

procedure TLZMATests.LZMA_PlusAES_RaisesExplicit;
var
  Path: string;
  Zip: TZipFile;
  Src: TMemoryStream;
begin
  Path := TZipTestHelpers.MakeTempPath('lzma_aes_clash.zip');
  try
    Src := TZipTestHelpers.MakeAnsiStream('payload');
    try
      Zip := TZipFile.Create(nil);
      try
        Zip.FileName := Path;
        Zip.UseLZMA := True;
        Zip.UseAES := True;
        Zip.Password := 'x';
        Zip.Active := True;
        Assert.WillRaise(
          procedure begin Zip.AppendStream(Src, 'x.bin', Now); end,
          EZipLZMAError,
          'LZMA + AES juntos devem levantar EZipLZMAError (v2.1 limita escopo)'
        );
      finally
        Zip.Free;
      end;
    finally
      Src.Free;
    end;
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TLZMATests);

end.
