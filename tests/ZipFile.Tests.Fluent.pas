{ ZipFile.Tests.Fluent.pas
  Fixture DUnitX cobrindo o fluent builder ZipFile.Fluent:
   - Zip.NewArchive(...).WithUtf8(True).AppendStream(...).Execute → ZIP valido
   - Zip.OpenArchive(...).CountEntries / HasEntry / ExtractStream
   - Encadeamento AES: Zip.NewArchive(...).WithAES(pwd).AppendStream(...).Execute
}
unit ZipFile.Tests.Fluent;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TFluentTests = class
  public
    [Test] procedure NewArchive_AppendStream_RoundTrip;
    [Test] procedure NewArchive_WithAES_RoundTrip;
    [Test] procedure OpenArchive_CountAndHasEntry;
  end;

implementation

uses
  System.SysUtils, System.Classes,
  ZipFile, ZipFile.Interfaces, ZipFile.Tests.Shared;

const
  PLAIN: AnsiString = 'Fluent builder canonical test payload';
  PWD = 'fluent-pwd-2026';

procedure TFluentTests.NewArchive_AppendStream_RoundTrip;
var
  Path: string;
  Src: TMemoryStream;
  Got: TStream;
begin
  Path := TZipTestHelpers.MakeTempPath('fluent_new.zip');
  try
    Src := TZipTestHelpers.MakeAnsiStream(PLAIN);
    Zip.NewArchive(Path)
       .WithUtf8(True)
       .AppendStream(Src, 'p.bin', True)  // OwnStream = True → builder frees
       .Execute;
    Got := Zip.OpenArchive(Path).ExtractStream('p.bin');
    try
      Assert.AreEqual(PLAIN, TZipTestHelpers.StreamToAnsi(Got),
        'fluent round-trip nao bateu payload');
    finally
      Got.Free;
    end;
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

procedure TFluentTests.NewArchive_WithAES_RoundTrip;
var
  Path: string;
  Src: TMemoryStream;
  Got: TStream;
begin
  Path := TZipTestHelpers.MakeTempPath('fluent_aes.zip');
  try
    Src := TZipTestHelpers.MakeAnsiStream(PLAIN);
    Zip.NewArchive(Path)
       .WithAES(PWD)
       .AppendStream(Src, 's.bin', True)
       .Execute;
    Got := Zip.OpenArchive(Path).WithPassword(PWD).ExtractStream('s.bin');
    try
      Assert.AreEqual(PLAIN, TZipTestHelpers.StreamToAnsi(Got),
        'fluent AES round-trip nao bateu payload');
    finally
      Got.Free;
    end;
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

procedure TFluentTests.OpenArchive_CountAndHasEntry;
var
  Path: string;
  S1, S2: TMemoryStream;
  B: IZipFileBuilder;
begin
  Path := TZipTestHelpers.MakeTempPath('fluent_open.zip');
  try
    S1 := TZipTestHelpers.MakeAnsiStream('one');
    S2 := TZipTestHelpers.MakeAnsiStream('two');
    Zip.NewArchive(Path)
       .AppendStream(S1, 'a.txt', True)
       .AppendStream(S2, 'b.txt', True)
       .Execute;
    B := Zip.OpenArchive(Path);
    Assert.AreEqual<Cardinal>(2, B.CountEntries, 'CountEntries falhou');
    Assert.IsTrue(Zip.OpenArchive(Path).HasEntry('a.txt'));
    Assert.IsTrue(Zip.OpenArchive(Path).HasEntry('b.txt'));
    Assert.IsFalse(Zip.OpenArchive(Path).HasEntry('missing.txt'));
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TFluentTests);

end.
