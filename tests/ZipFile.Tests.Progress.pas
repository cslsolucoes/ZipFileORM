{ ZipFile.Tests.Progress.pas
  Fixture DUnitX cobrindo:
   - OnProgress dispara durante AppendStream com BytesDone/BytesTotal coerentes
   - Cancel:=True levanta EZipFileCancelled
}
unit ZipFile.Tests.Progress;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TProgressTests = class
  private
    FCallbackHits: Integer;
    FLastDone, FLastTotal: Int64;
    FCancelAt: Int64;
    procedure OnProgressHandler(Sender: TObject; BytesDone, BytesTotal: Int64; var Cancel: Boolean);
  public
    [Test] procedure OnProgress_Fires_DuringAppendStream;
    [Test] procedure OnProgress_Cancel_RaisesEZipFileCancelled;
  end;

implementation

uses
  System.SysUtils, System.Classes, ZipFile, Commons.Progress, ZipFile.Tests.Shared;

procedure TProgressTests.OnProgressHandler(Sender: TObject; BytesDone, BytesTotal: Int64; var Cancel: Boolean);
begin
  Inc(FCallbackHits);
  FLastDone := BytesDone;
  FLastTotal := BytesTotal;
  if (FCancelAt > 0) and (BytesDone >= FCancelAt) then
    Cancel := True;
end;

procedure TProgressTests.OnProgress_Fires_DuringAppendStream;
var
  Path: string;
  Zip: TZipFile;
  Big: TMemoryStream;
  Payload: TBytes;
  I: Integer;
begin
  Path := TZipTestHelpers.MakeTempPath('progress_fire.zip');
  FCallbackHits := 0;
  FCancelAt := 0;
  try
    // 256 KB de payload â€” forca pelo menos 4 chunks de 64KB no DoProgressChunkedCopy
    SetLength(Payload, 256 * 1024);
    for I := 0 to High(Payload) do
      Payload[I] := Byte(I);
    Big := TMemoryStream.Create;
    try
      Big.WriteBuffer(Payload[0], Length(Payload));
      Big.Position := 0;
      Zip := TZipFile.Create(nil);
      try
        Zip.FileName := Path;
        Zip.OnProgress := OnProgressHandler;
        Zip.Active := True;
        Zip.AppendStream(Big, 'big.bin', Now);
      finally
        Zip.Free;
      end;
    finally
      Big.Free;
    end;
    Assert.IsTrue(FCallbackHits > 0, 'OnProgress nao disparou nem uma vez');
    Assert.IsTrue(FLastTotal > 0, 'BytesTotal devia ser > 0 ao final');
    Assert.IsTrue(FLastDone <= FLastTotal,
      Format('BytesDone (%d) > BytesTotal (%d)', [FLastDone, FLastTotal]));
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

procedure TProgressTests.OnProgress_Cancel_RaisesEZipFileCancelled;
var
  Path: string;
  Zip: TZipFile;
  Big: TMemoryStream;
  Payload: TBytes;
  I: Integer;
begin
  Path := TZipTestHelpers.MakeTempPath('progress_cancel.zip');
  FCallbackHits := 0;
  FCancelAt := 32 * 1024; // cancela apos os primeiros 32 KB copiados
  try
    SetLength(Payload, 256 * 1024);
    for I := 0 to High(Payload) do
      Payload[I] := Byte(I);
    Big := TMemoryStream.Create;
    try
      Big.WriteBuffer(Payload[0], Length(Payload));
      Big.Position := 0;
      Zip := TZipFile.Create(nil);
      try
        Zip.FileName := Path;
        Zip.OnProgress := OnProgressHandler;
        Zip.Active := True;
        Assert.WillRaise(
          procedure begin Zip.AppendStream(Big, 'big.bin', Now); end,
          EZipFileCancelled,
          'Cancel:=True devia levantar EZipFileCancelled'
        );
      finally
        Zip.Free;
      end;
    finally
      Big.Free;
    end;
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TProgressTests);

end.
