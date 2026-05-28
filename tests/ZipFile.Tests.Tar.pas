{ ZipFile.Tests.Tar.pas
  Fixture DUnitX cobrindo v3.0 â€” TAR + Gzip + Tar.Gz + Archive.Open
}
unit ZipFile.Tests.Tar;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTarTests = class
  public
    [Test] procedure Tar_RoundTrip_SingleEntry;
    [Test] procedure Tar_RoundTrip_MultipleEntries;
    [Test] procedure Tar_AppendString_ReadAsString;
    [Test] procedure Gzip_CompressDecompress_BufferRoundTrip;
    [Test] procedure Archive_DetectFormat_ZipMagic;
    [Test] procedure Archive_DetectFormat_GzipMagic;
    [Test] procedure Archive_DetectFormat_TarUstar;
  end;

implementation

uses
  System.SysUtils, System.Classes,
  TarFile, TarFile.GzipStream, Archive.Open, ZipFile.Tests.Shared;

const
  PAYLOAD: AnsiString = 'TAR round-trip canonical test 0123456789 abcdefghij';

procedure TTarTests.Tar_RoundTrip_SingleEntry;
var
  Path: string;
  Tar: TTarFile;
  Src, Got: TStream;
begin
  Path := TZipTestHelpers.MakeTempPath('tar_single.tar');
  try
    Tar := TTarFile.Create(nil);
    try
      Tar.WithFileName(Path).ThatOpens;
      Src := TZipTestHelpers.MakeAnsiStream(PAYLOAD);
      try
        Tar.AppendStream(Src, 'p.txt', Now);
      finally Src.Free; end;
    finally Tar.Free; end;
    // Re-open
    Tar := TTarFile.Create(nil);
    try
      Tar.WithFileName(Path).ThatOpens;
      Assert.AreEqual<Integer>(1, Tar.EntryCount);
      Assert.IsTrue(Tar.FileExists('p.txt'));
      Got := Tar.GetEntryStream('p.txt');
      try
        Assert.AreEqual(PAYLOAD, TZipTestHelpers.StreamToAnsi(Got));
      finally Got.Free; end;
    finally Tar.Free; end;
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

procedure TTarTests.Tar_RoundTrip_MultipleEntries;
var
  Path: string;
  Tar: TTarFile;
  S1, S2: TStream;
begin
  Path := TZipTestHelpers.MakeTempPath('tar_multi.tar');
  try
    Tar := TTarFile.Create(nil);
    try
      Tar.WithFileName(Path).ThatOpens;
      S1 := TZipTestHelpers.MakeAnsiStream('first');
      try Tar.AppendStream(S1, 'a.txt', Now); finally S1.Free; end;
      S2 := TZipTestHelpers.MakeAnsiStream('second');
      try Tar.AppendStream(S2, 'b.txt', Now); finally S2.Free; end;
    finally Tar.Free; end;
    Tar := TTarFile.Create(nil);
    try
      Tar.WithFileName(Path).ThatOpens;
      Assert.AreEqual<Integer>(2, Tar.EntryCount, 'TAR devia ter 2 entries');
      Assert.IsTrue(Tar.FileExists('a.txt'));
      Assert.IsTrue(Tar.FileExists('b.txt'));
    finally Tar.Free; end;
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

procedure TTarTests.Tar_AppendString_ReadAsString;
const
  TXT = 'hello tar string helper';
var
  Path: string;
  Tar: TTarFile;
  Got: string;
begin
  Path := TZipTestHelpers.MakeTempPath('tar_str.tar');
  try
    Tar := TTarFile.Create(nil);
    try
      Tar.WithFileName(Path).ThatOpens;
      Tar.AppendString(TXT, 'msg.txt');
    finally Tar.Free; end;
    Tar := TTarFile.Create(nil);
    try
      Tar.WithFileName(Path).ThatOpens;
      Got := Tar.ReadAsString('msg.txt');
      Assert.AreEqual(TXT, Got);
    finally Tar.Free; end;
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

procedure TTarTests.Gzip_CompressDecompress_BufferRoundTrip;
var
  Plain, Comp, Got: TBytes;
  I: Integer;
begin
  SetLength(Plain, 4096);
  for I := 0 to High(Plain) do
    Plain[I] := Byte(I mod 23);
  GzipCompressBuffer(Plain, Comp, 6);
  Assert.IsTrue(Length(Comp) > 0, 'Gzip output deve ter bytes');
  Assert.IsTrue(Length(Comp) < Length(Plain), 'Gzip deve comprimir pattern repetitivo');
  GzipDecompressBuffer(Comp, Got);
  Assert.AreEqual<Integer>(Length(Plain), Length(Got));
  for I := 0 to High(Plain) do
    if Got[I] <> Plain[I] then
      Assert.Fail(Format('Gzip round-trip byte %d divergente', [I]));
end;

procedure TTarTests.Archive_DetectFormat_ZipMagic;
var
  Mem: TMemoryStream;
  Magic: array[0..3] of Byte;
begin
  Mem := TMemoryStream.Create;
  try
    Magic[0] := $50; Magic[1] := $4B; Magic[2] := $03; Magic[3] := $04;
    Mem.WriteBuffer(Magic[0], 4);
    Assert.AreEqual<Integer>(Ord(afZip), Ord(DetectArchiveFormat(Mem)));
  finally Mem.Free; end;
end;

procedure TTarTests.Archive_DetectFormat_GzipMagic;
var
  Mem: TMemoryStream;
  Magic: array[0..1] of Byte;
begin
  Mem := TMemoryStream.Create;
  try
    Magic[0] := $1F; Magic[1] := $8B;
    Mem.WriteBuffer(Magic[0], 2);
    // 2 bytes only â€” DetectArchiveFormat exige N>=4 mas Gzip detecta com 2 disponiveis
    // se buf >=4 (espera mais bytes para identificar). Vamos preencher.
    Mem.WriteBuffer(Magic[0], 2); // dummy fill
    Mem.Position := 0;
    Mem.WriteBuffer(Magic[0], 2);
    Assert.AreEqual<Integer>(Ord(afGzip), Ord(DetectArchiveFormat(Mem)));
  finally Mem.Free; end;
end;

procedure TTarTests.Archive_DetectFormat_TarUstar;
var
  Mem: TMemoryStream;
  Buf: array[0..511] of Byte;
begin
  Mem := TMemoryStream.Create;
  try
    FillChar(Buf[0], SizeOf(Buf), 0);
    // "ustar\x00" at offset 257
    Buf[257] := Ord('u'); Buf[258] := Ord('s');
    Buf[259] := Ord('t'); Buf[260] := Ord('a');
    Buf[261] := Ord('r'); Buf[262] := 0;
    Mem.WriteBuffer(Buf[0], SizeOf(Buf));
    Assert.AreEqual<Integer>(Ord(afTar), Ord(DetectArchiveFormat(Mem)));
  finally Mem.Free; end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTarTests);

end.
