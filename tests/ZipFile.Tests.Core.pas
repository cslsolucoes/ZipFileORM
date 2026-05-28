{ ZipFile.Tests.Core.pas
  Fixture DUnitX cobrindo o caminho legado da biblioteca:
   - criar archive
   - AppendStream / AppendFileFromDisk
   - FileCount / FileExists / FileNameIndex
   - GetFileStream round-trip
   - DeleteFile
   - reabrir archive existente
}
unit ZipFile.Tests.Core;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TCoreTests = class
  public
    [Test] procedure CreateEmpty_FileExistsAndIsEOCDOnly;
    [Test] procedure Append_TwoEntries_FileCountIsTwo;
    [Test] procedure Append_RoundTripBinaryPayload;
    [Test] procedure FileExists_ReportsCorrectly;
    [Test] procedure ReopenAfterClose_PreservesEntries;
    [Test] procedure DeleteFile_RemovesEntry;
  end;

implementation

uses
  System.SysUtils, System.Classes, ZipFile, ZipFile.Tests.Shared;

procedure TCoreTests.CreateEmpty_FileExistsAndIsEOCDOnly;
var
  Path: string;
  Zip: TZipFile;
begin
  Path := TZipTestHelpers.MakeTempPath('core_empty.zip');
  try
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Active := True;
    finally
      Zip.Free;
    end;
    Assert.IsTrue(FileExists(Path), 'archive vazio nao foi criado');
    // Layout minimo = somente EOCDR (22 bytes)
    with TFileStream.Create(Path, fmOpenRead) do
    try
      Assert.AreEqual<Int64>(22, Size, 'EOCD-only archive deve ter 22 bytes');
    finally
      Free;
    end;
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

procedure TCoreTests.Append_TwoEntries_FileCountIsTwo;
var
  Path: string;
  Zip: TZipFile;
  S1, S2: TMemoryStream;
begin
  Path := TZipTestHelpers.MakeTempPath('core_two.zip');
  try
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Active := True;
      S1 := TZipTestHelpers.MakeAnsiStream('hello world');
      try Zip.AppendStream(S1, 'a.txt', Now); finally S1.Free; end;
      S2 := TZipTestHelpers.MakeAnsiStream('second entry payload');
      try Zip.AppendStream(S2, 'b.txt', Now); finally S2.Free; end;
      Assert.AreEqual<Cardinal>(2, Zip.FileCount, 'devia ter 2 entries');
    finally
      Zip.Free;
    end;
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

procedure TCoreTests.Append_RoundTripBinaryPayload;
const
  PLAIN: AnsiString = 'Round-trip binary payload: 0123456789!@#$%^&*()_+';
var
  Path: string;
  Zip: TZipFile;
  Src, Got: TMemoryStream;
  BufLen: Cardinal;
begin
  Path := TZipTestHelpers.MakeTempPath('core_rt.zip');
  try
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Active := True;
      Src := TZipTestHelpers.MakeAnsiStream(PLAIN);
      try Zip.AppendStream(Src, 'payload.bin', Now); finally Src.Free; end;
    finally
      Zip.Free;
    end;
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Active := True;
      BufLen := 0;
      Got := Zip.GetFileStream('payload.bin', BufLen);
      try
        Assert.AreEqual(PLAIN, TZipTestHelpers.StreamToAnsi(Got), 'payload corrompido no round-trip');
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

procedure TCoreTests.FileExists_ReportsCorrectly;
var
  Path: string;
  Zip: TZipFile;
  S: TMemoryStream;
begin
  Path := TZipTestHelpers.MakeTempPath('core_exists.zip');
  try
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Active := True;
      S := TZipTestHelpers.MakeAnsiStream('content');
      try Zip.AppendStream(S, 'present.txt', Now); finally S.Free; end;
      Assert.IsTrue(Zip.FileExists('present.txt'), 'entry presente nao encontrada');
      Assert.IsFalse(Zip.FileExists('missing.txt'), 'entry inexistente reportada como presente');
    finally
      Zip.Free;
    end;
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

procedure TCoreTests.ReopenAfterClose_PreservesEntries;
var
  Path: string;
  Zip: TZipFile;
  S: TMemoryStream;
begin
  Path := TZipTestHelpers.MakeTempPath('core_reopen.zip');
  try
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Active := True;
      S := TZipTestHelpers.MakeAnsiStream('persist this');
      try Zip.AppendStream(S, 'persist.txt', Now); finally S.Free; end;
    finally
      Zip.Free;
    end;
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Active := True;
      Assert.AreEqual<Cardinal>(1, Zip.FileCount, 'reabertura nao preserva entries');
      Assert.IsTrue(Zip.FileExists('persist.txt'));
    finally
      Zip.Free;
    end;
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

procedure TCoreTests.DeleteFile_RemovesEntry;
var
  Path: string;
  Zip: TZipFile;
  S: TMemoryStream;
begin
  Path := TZipTestHelpers.MakeTempPath('core_del.zip');
  try
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Active := True;
      S := TZipTestHelpers.MakeAnsiStream('temp');
      try Zip.AppendStream(S, 'doomed.txt', Now); finally S.Free; end;
      S := TZipTestHelpers.MakeAnsiStream('keep');
      try Zip.AppendStream(S, 'keeper.txt', Now); finally S.Free; end;
      Assert.AreEqual<Cardinal>(2, Zip.FileCount);
      Zip.DeleteFile('doomed.txt');
      Assert.AreEqual<Cardinal>(1, Zip.FileCount, 'DeleteFile nao removeu entry');
      Assert.IsFalse(Zip.FileExists('doomed.txt'));
      Assert.IsTrue(Zip.FileExists('keeper.txt'));
    finally
      Zip.Free;
    end;
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TCoreTests);

end.
