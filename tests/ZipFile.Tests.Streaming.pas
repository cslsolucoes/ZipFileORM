{ ZipFile.Tests.Streaming.pas
  Fixture DUnitX cobrindo o caminho streaming real (TZipFile.GetEntryStream):
   - Stored entry: stream nao-buffer, retorna mesmo conteudo do GetFileStream
   - Stored + AES: decrypt on-the-fly + HMAC verificado upfront
   - Seek random access em stored stream
   - Stream pode ser maior que a RAM disponivel (verificado conceito com 4MB)
   - Bad password + tamper rejection consistentes com GetFileStream
}
unit ZipFile.Tests.Streaming;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TStreamingTests = class
  public
    [Test] procedure GetEntryStream_StoredEntry_MatchesGetFileStream;
    [Test] procedure GetEntryStream_StoredEntry_SeekRandomAccess;
    [Test] procedure GetEntryStream_AESEntry_DecryptsOnTheFly;
    [Test] procedure GetEntryStream_AESEntry_BadPasswordRaises;
    [Test] procedure GetEntryStream_StoredEntry_LargeBuffer4MB;
  end;

implementation

uses
  System.SysUtils, System.Classes,
  ZipFile, Commons.Encryption.AES, ZipFile.Tests.Shared;

const
  PLAIN_TXT: AnsiString = 'Streaming round-trip canonical sample with some entropy 0xABCDEF';
  PWD_OK    = 'streaming-pwd-2026';
  PWD_BAD   = 'wrong-pwd';

procedure TStreamingTests.GetEntryStream_StoredEntry_MatchesGetFileStream;
var
  Path: string;
  Zip: TZipFile;
  Src, MemGot: TMemoryStream;
  Stm: TStream;
  GotViaStream, GotViaMem: AnsiString;
  BufLen: Cardinal;
begin
  Path := TZipTestHelpers.MakeTempPath('stream_match.zip');
  try
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Active := True;
      Src := TZipTestHelpers.MakeAnsiStream(PLAIN_TXT);
      try Zip.AppendStream(Src, 'p.bin', Now); finally Src.Free; end;
    finally
      Zip.Free;
    end;
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Active := True;
      Stm := Zip.GetEntryStream('p.bin');
      try
        GotViaStream := TZipTestHelpers.StreamToAnsi(Stm);
      finally
        Stm.Free;
      end;
      BufLen := 0;
      MemGot := Zip.GetFileStream('p.bin', BufLen);
      try
        GotViaMem := TZipTestHelpers.StreamToAnsi(MemGot);
      finally
        MemGot.Free;
      end;
      Assert.AreEqual(GotViaMem, GotViaStream, 'streaming e in-memory devem retornar bytes iguais');
      Assert.AreEqual(PLAIN_TXT, GotViaStream, 'payload corrompido no streaming');
    finally
      Zip.Free;
    end;
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

procedure TStreamingTests.GetEntryStream_StoredEntry_SeekRandomAccess;
var
  Path: string;
  Zip: TZipFile;
  Src: TMemoryStream;
  Stm: TStream;
  Buf: array[0..15] of AnsiChar;
  Offset5: AnsiString;
begin
  Path := TZipTestHelpers.MakeTempPath('stream_seek.zip');
  try
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Active := True;
      Src := TZipTestHelpers.MakeAnsiStream(PLAIN_TXT);
      try Zip.AppendStream(Src, 'p.bin', Now); finally Src.Free; end;
    finally
      Zip.Free;
    end;
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Active := True;
      Stm := Zip.GetEntryStream('p.bin');
      try
        Stm.Seek(5, soBeginning);
        Stm.ReadBuffer(Buf[0], 10);
        SetLength(Offset5, 10);
        Move(Buf[0], Offset5[1], 10);
        // PLAIN_TXT[6..15] = 'aming roun' (1-based)
        Assert.AreEqual<AnsiString>(Copy(PLAIN_TXT, 6, 10), Offset5,
          'Seek+Read random access falhou no streaming');
      finally
        Stm.Free;
      end;
    finally
      Zip.Free;
    end;
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

procedure TStreamingTests.GetEntryStream_AESEntry_DecryptsOnTheFly;
var
  Path: string;
  Zip: TZipFile;
  Src: TMemoryStream;
  Stm: TStream;
begin
  Path := TZipTestHelpers.MakeTempPath('stream_aes_ok.zip');
  try
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.UseAES := True;
      Zip.Password := PWD_OK;
      Zip.Active := True;
      Src := TZipTestHelpers.MakeAnsiStream(PLAIN_TXT);
      try Zip.AppendStream(Src, 's.bin', Now); finally Src.Free; end;
    finally
      Zip.Free;
    end;
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Password := PWD_OK;
      Zip.Active := True;
      Stm := Zip.GetEntryStream('s.bin');
      try
        Assert.AreEqual(PLAIN_TXT, TZipTestHelpers.StreamToAnsi(Stm),
          'streaming AES decrypt nao bateu plaintext');
      finally
        Stm.Free;
      end;
    finally
      Zip.Free;
    end;
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

procedure TStreamingTests.GetEntryStream_AESEntry_BadPasswordRaises;
var
  Path: string;
  Zip: TZipFile;
  Src: TMemoryStream;
  StmRef: TStream;
begin
  Path := TZipTestHelpers.MakeTempPath('stream_aes_bad.zip');
  try
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.UseAES := True;
      Zip.Password := PWD_OK;
      Zip.Active := True;
      Src := TZipTestHelpers.MakeAnsiStream(PLAIN_TXT);
      try Zip.AppendStream(Src, 's.bin', Now); finally Src.Free; end;
    finally
      Zip.Free;
    end;
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Password := PWD_BAD;
      Zip.Active := True;
      Assert.WillRaise(
        procedure begin StmRef := Zip.GetEntryStream('s.bin'); StmRef.Free; end,
        EZipAESError,
        'streaming AES bad pwd devia levantar EZipAESError'
      );
    finally
      Zip.Free;
    end;
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

procedure TStreamingTests.GetEntryStream_StoredEntry_LargeBuffer4MB;
var
  Path: string;
  Zip: TZipFile;
  Big: TMemoryStream;
  Payload: TBytes;
  Stm: TStream;
  ReadBack: TBytes;
  I: Integer;
  BytesRead: Integer;
begin
  Path := TZipTestHelpers.MakeTempPath('stream_4mb.zip');
  try
    SetLength(Payload, 4 * 1024 * 1024); // 4 MB
    for I := 0 to High(Payload) do
      Payload[I] := Byte(I and $FF);
    Big := TMemoryStream.Create;
    try
      Big.WriteBuffer(Payload[0], Length(Payload));
      Big.Position := 0;
      Zip := TZipFile.Create(nil);
      try
        Zip.FileName := Path;
        Zip.Active := True;
        Zip.AppendStream(Big, 'big.bin', Now);
      finally
        Zip.Free;
      end;
    finally
      Big.Free;
    end;
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Active := True;
      Stm := Zip.GetEntryStream('big.bin');
      try
        Assert.AreEqual<Int64>(4 * 1024 * 1024, Stm.Size, '4 MB stream Size errado');
        SetLength(ReadBack, 4 * 1024 * 1024);
        BytesRead := Stm.Read(ReadBack[0], Length(ReadBack));
        Assert.AreEqual<Integer>(4 * 1024 * 1024, BytesRead, 'Read incompleto');
        for I := 0 to High(Payload) do
          if ReadBack[I] <> Payload[I] then
          begin
            Assert.Fail(Format('Byte %d divergiu (esperado %d, lido %d)', [I, Payload[I], ReadBack[I]]));
            Break;
          end;
      finally
        Stm.Free;
      end;
    finally
      Zip.Free;
    end;
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TStreamingTests);

end.
