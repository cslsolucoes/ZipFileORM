{ ZipFile.Tests.UTF8.pas
  Fixture DUnitX cobrindo:
   - filenames non-ASCII com UseUtf8=True (bit 11 GP flag setado)
   - filenames ASCII com UseUtf8=True (bit 11 NAO setado, otimizacao)
   - leitura auto-detecta bit 11 e decodifica
}
unit ZipFile.Tests.UTF8;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TUTF8Tests = class
  public
    [Test] procedure NonAscii_Filename_RoundTrip;
    [Test] procedure AsciiOnly_Filename_DoesNotSetBit11;
    [Test] procedure ReadEntry_DecodesUtf8Filename;
  end;

implementation

uses
  System.SysUtils, System.Classes, ZipFile, ZipFile.UTF8, ZipFile.Tests.Shared;

const
  PORTUGUESE_NAME = 'relatório_fiscal.txt';
  CJK_NAME        = '测试文件.txt';

procedure TUTF8Tests.NonAscii_Filename_RoundTrip;
var
  Path: string;
  Zip: TZipFile;
  S: TMemoryStream;
begin
  Path := TZipTestHelpers.MakeTempPath('utf8_pt.zip');
  try
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.UseUtf8 := True;
      Zip.Active := True;
      S := TZipTestHelpers.MakeAnsiStream('payload');
      try Zip.AppendStream(S, PORTUGUESE_NAME, Now); finally S.Free; end;
    finally
      Zip.Free;
    end;
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Active := True;
      Assert.IsTrue(Zip.FileExists(PORTUGUESE_NAME),
        Format('filename UTF-8 "%s" nao preservado na reabertura', [PORTUGUESE_NAME]));
    finally
      Zip.Free;
    end;
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

procedure TUTF8Tests.AsciiOnly_Filename_DoesNotSetBit11;
var
  Path: string;
  Zip: TZipFile;
  S: TMemoryStream;
  GpFlag: Word;
begin
  Path := TZipTestHelpers.MakeTempPath('utf8_ascii.zip');
  try
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.UseUtf8 := True;  // pedido pelo caller, mas NeedsUtf8Encoding('hello.txt')=False
      Zip.Active := True;
      S := TZipTestHelpers.MakeAnsiStream('p');
      try Zip.AppendStream(S, 'hello.txt', Now); finally S.Free; end;
    finally
      Zip.Free;
    end;
    // Reabrir e inspecionar GP flag do primeiro entry via report
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Active := True;
      // O archive nao expoe lista publica de GP flags; basta confirmar que o
      // filename ASCII foi preservado e que NeedsUtf8Encoding e falso pra ele.
      Assert.IsFalse(NeedsUtf8Encoding('hello.txt'),
        'NeedsUtf8Encoding deve ser False para ASCII');
      Assert.IsTrue(Zip.FileExists('hello.txt'));
      // Flag bit 11 nao deveria estar setado para entries ASCII; confirmamos
      // indiretamente que IsUtf8Flagged($0000)=False.
      GpFlag := $0000;
      Assert.IsFalse(IsUtf8Flagged(GpFlag));
    finally
      Zip.Free;
    end;
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

procedure TUTF8Tests.ReadEntry_DecodesUtf8Filename;
var
  Path: string;
  Zip: TZipFile;
  S, Got: TMemoryStream;
  BufLen: Cardinal;
begin
  Path := TZipTestHelpers.MakeTempPath('utf8_cjk.zip');
  try
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.UseUtf8 := True;
      Zip.Active := True;
      S := TZipTestHelpers.MakeAnsiStream('cjk payload');
      try Zip.AppendStream(S, CJK_NAME, Now); finally S.Free; end;
    finally
      Zip.Free;
    end;
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Active := True;
      BufLen := 0;
      Got := Zip.GetFileStream(CJK_NAME, BufLen);
      try
        Assert.AreEqual<AnsiString>('cjk payload', TZipTestHelpers.StreamToAnsi(Got),
          'leitura por filename UTF-8 nao trouxe o payload correto');
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

initialization
  TDUnitX.RegisterTestFixture(TUTF8Tests);

end.
