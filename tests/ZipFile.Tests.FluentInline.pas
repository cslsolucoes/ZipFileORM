{ ZipFile.Tests.FluentInline.pas
  Fixture DUnitX cobrindo o refactor v2.4: metodos Fluent inline em TZipFile
  (chaining direto sem builder externo, mantendo backward compat 100%).

  Cobertura:
   - WithUtf8/WithAES/WithPassword/WithLZMA/WithForceZip64 retornam Self
   - Chaining inline funciona em uma unica expressao
   - Properties tradicionais continuam funcionando IDENTICAS ao path fluent
   - WithFileName + Open (atalhos)
}
unit ZipFile.Tests.FluentInline;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TFluentInlineTests = class
  public
    [Test] procedure WithUtf8_ReturnsSameInstance;
    [Test] procedure WithAES_SetsUseAESAndPassword;
    [Test] procedure ChainInline_AllPropertiesApplied;
    [Test] procedure ChainInline_RoundTrip_EquivalentToLegacy;
    [Test] procedure WithFileName_AndOpen_Shortcut;
  end;

implementation

uses
  System.SysUtils, System.Classes, ZipFile, ZipFile.Tests.Shared;

const
  PLAIN: AnsiString = 'Fluent inline canonical test payload';
  PWD = 'inline-pwd-2026';

procedure TFluentInlineTests.WithUtf8_ReturnsSameInstance;
var
  Zip: TZipFile;
  Ret: TZipFile;
begin
  Zip := TZipFile.Create(nil);
  try
    Ret := Zip.WithUtf8(True);
    Assert.AreSame(Zip, Ret, 'WithUtf8 deve retornar Self para chaining');
    Assert.IsTrue(Zip.UseUtf8);
    Ret := Zip.WithUtf8(False);
    Assert.AreSame(Zip, Ret);
    Assert.IsFalse(Zip.UseUtf8);
  finally
    Zip.Free;
  end;
end;

procedure TFluentInlineTests.WithAES_SetsUseAESAndPassword;
var
  Zip: TZipFile;
begin
  Zip := TZipFile.Create(nil);
  try
    Zip.WithAES('secret-123');
    Assert.IsTrue(Zip.UseAES, 'WithAES devia setar UseAES=True');
    Assert.AreEqual<string>('secret-123', Zip.Password, 'WithAES devia setar Password');
  finally
    Zip.Free;
  end;
end;

procedure TFluentInlineTests.ChainInline_AllPropertiesApplied;
var
  Zip: TZipFile;
begin
  Zip := TZipFile.Create(nil);
  try
    // Chain inline em uma expressao unica
    Zip.WithUtf8(True)
       .WithAES('pwd-x')
       .WithForceZip64(True)
       .WithLZMA(False)
       .WithCompression(cmMaximal);
    Assert.IsTrue(Zip.UseUtf8);
    Assert.IsTrue(Zip.UseAES);
    Assert.AreEqual<string>('pwd-x', Zip.Password);
    Assert.IsTrue(Zip.ForceZip64);
    Assert.IsFalse(Zip.UseLZMA);
    Assert.AreEqual<Integer>(Ord(cmMaximal), Ord(Zip.Compression));
  finally
    Zip.Free;
  end;
end;

procedure TFluentInlineTests.ChainInline_RoundTrip_EquivalentToLegacy;
const
  ENTRY = 'p.bin';
var
  Path: string;
  Zip: TZipFile;
  Src, Got: TMemoryStream;
  BufLen: Cardinal;
begin
  // Build archive via chain inline
  Path := TZipTestHelpers.MakeTempPath('fluent_inline.zip');
  try
    Zip := TZipFile.Create(nil);
    try
      Zip.WithFileName(Path)
         .WithUtf8(True)
         .WithAES(PWD)
         .Open;  // atalho para Active := True
      Src := TZipTestHelpers.MakeAnsiStream(PLAIN);
      try
        Zip.AppendStream(Src, ENTRY, Now);
      finally
        Src.Free;
      end;
    finally
      Zip.Free;
    end;
    // Read back via path tradicional (legacy properties)
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;       // legacy
      Zip.Password := PWD;          // legacy
      Zip.Active := True;           // legacy
      BufLen := 0;
      Got := Zip.GetFileStream(ENTRY, BufLen);
      try
        Assert.AreEqual(PLAIN, TZipTestHelpers.StreamToAnsi(Got),
          'Round-trip inline fluent + legacy read divergente');
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

procedure TFluentInlineTests.WithFileName_AndOpen_Shortcut;
var
  Path: string;
  Zip: TZipFile;
begin
  Path := TZipTestHelpers.MakeTempPath('fluent_open.zip');
  try
    Zip := TZipFile.Create(nil);
    try
      Zip.WithFileName(Path).Open;
      Assert.IsTrue(Zip.Active, 'Open deve setar Active=True');
      Assert.AreEqual<string>(Path, Zip.FileName);
    finally
      Zip.Free;
    end;
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TFluentInlineTests);

end.
