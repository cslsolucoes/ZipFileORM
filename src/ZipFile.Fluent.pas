{ ZipFile.Fluent.pas
  Fluent builder API over TZipFile — opt-in convenience wrapper that does
  NOT change anything about the legacy TZipFile API. Use it when you want
  a chained, readable, single-expression build:

      IZipFileBuilder
        .NewArchive('out.zip')
        .WithUtf8(True)
        .WithAES('correct horse battery staple')
        .OnProgress(MyHandler)
        .AppendStream(stream, 'a.bin')
        .AppendFile('relatório.txt', 'relatório.txt')
        .Execute;

  Or to read:

      var entryStream := IZipFileBuilder
        .OpenArchive('in.zip')
        .WithPassword('correct horse battery staple')
        .ExtractStream('secret.bin');
      try ... finally entryStream.Free; end;

  The builder owns its internal TZipFile (created/destroyed inside .Execute
  and equivalent terminals) so users never have to manage lifecycle by hand.

  Dual-target Delphi (D24..D37) and FPC/Lazarus.
}
unit ZipFile.Fluent;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils, Classes, ZipFile, Commons.Progress;

type
  // Append intent recorded by the fluent chain; flushed lazily in .Execute.
  TZipBuilderItem = record
    Kind: (zbkStream, zbkFile, zbkDelete, zbkUpdate);
    ZipName: string;
    DiskFileName: string;
    Stream: TStream;
    OwnStream: Boolean;
  end;

  IZipFileBuilder = interface
    ['{B95B5C56-D5C8-4F8A-9C30-1F8E32D69A21}']
    // === Toggles / properties (todos chainable) ===
    function WithUtf8(AEnable: Boolean = True): IZipFileBuilder;
    function WithAES(const APassword: string): IZipFileBuilder;
    function WithPassword(const APassword: string): IZipFileBuilder;
    function WithLZMA(AEnable: Boolean = True): IZipFileBuilder;
    function WithForceZip64(AEnable: Boolean = True): IZipFileBuilder;
    function WithCompression(AMethod: TCompressionMethod): IZipFileBuilder;
    function WithReCompression(AMethod: TReCompressionMethod): IZipFileBuilder;
    function OnProgress(AEvent: TZipProgressEvent): IZipFileBuilder;
    function OnArchiveChanged(AEvent: TFileChangedEvent): IZipFileBuilder;
    // === Write intents (queued; emitted em .Execute) ===
    function AppendStream(AStream: TStream; const AZipName: string;
                         AOwnStream: Boolean = False): IZipFileBuilder;
    function AppendFile(const ADiskFileName, AZipName: string): IZipFileBuilder;
    function DeleteEntry(const AZipName: string): IZipFileBuilder;
    function UpdateEntry(AStream: TStream; const AZipName: string;
                         AOwnStream: Boolean = False): IZipFileBuilder;
    // === Terminais: write ===
    procedure Execute;
    // === Terminais: read (open-only) ===
    function ExtractStream(const AZipName: string): TStream;
    function HasEntry(const AZipName: string): Boolean;
    function CountEntries: Cardinal;
  end;

  TZipFileBuilder = class(TInterfacedObject, IZipFileBuilder)
  private
    FArchivePath: string;
    FOpenForUpdate: Boolean;
    FUseUtf8: Boolean;
    FUseAES: Boolean;
    FPassword: string;
    FUseLZMA: Boolean;
    FForceZip64: Boolean;
    FCompression: TCompressionMethod;
    FReCompression: TReCompressionMethod;
    FCompressionSet: Boolean;
    FReCompressionSet: Boolean;
    FOnProgress: TZipProgressEvent;
    FOnArchiveChanged: TFileChangedEvent;
    FItems: array of TZipBuilderItem;
    procedure ApplySettings(AZip: TZipFile);
  public
    constructor CreateNew(const APath: string);
    constructor CreateOpen(const APath: string);
    function WithUtf8(AEnable: Boolean = True): IZipFileBuilder;
    function WithAES(const APassword: string): IZipFileBuilder;
    function WithPassword(const APassword: string): IZipFileBuilder;
    function WithLZMA(AEnable: Boolean = True): IZipFileBuilder;
    function WithForceZip64(AEnable: Boolean = True): IZipFileBuilder;
    function WithCompression(AMethod: TCompressionMethod): IZipFileBuilder;
    function WithReCompression(AMethod: TReCompressionMethod): IZipFileBuilder;
    function OnProgress(AEvent: TZipProgressEvent): IZipFileBuilder;
    function OnArchiveChanged(AEvent: TFileChangedEvent): IZipFileBuilder;
    function AppendStream(AStream: TStream; const AZipName: string;
                         AOwnStream: Boolean = False): IZipFileBuilder;
    function AppendFile(const ADiskFileName, AZipName: string): IZipFileBuilder;
    function DeleteEntry(const AZipName: string): IZipFileBuilder;
    function UpdateEntry(AStream: TStream; const AZipName: string;
                         AOwnStream: Boolean = False): IZipFileBuilder;
    procedure Execute;
    function ExtractStream(const AZipName: string): TStream;
    function HasEntry(const AZipName: string): Boolean;
    function CountEntries: Cardinal;
  end;

  // Convenience: static-style factory class. Use the type itself as the
  // entry point: `IZipFileBuilder.NewArchive('out.zip').Execute;`. Because
  // Object Pascal doesn't support interface class methods, we expose the
  // factory via a sealed class with class methods.
  Zip = class
  public
    class function NewArchive(const APath: string): IZipFileBuilder;
    class function OpenArchive(const APath: string): IZipFileBuilder;
  end;

implementation

// =============================================================================
//   TZipFileBuilder
// =============================================================================

constructor TZipFileBuilder.CreateNew(const APath: string);
begin
  inherited Create;
  FArchivePath := APath;
  FOpenForUpdate := False;
  // For "new", remove any previous file so AppendStream produces a clean output.
  if SysUtils.FileExists(APath) then
    SysUtils.DeleteFile(APath);
end;

constructor TZipFileBuilder.CreateOpen(const APath: string);
begin
  inherited Create;
  FArchivePath := APath;
  FOpenForUpdate := True;
end;

function TZipFileBuilder.WithUtf8(AEnable: Boolean): IZipFileBuilder;
begin
  FUseUtf8 := AEnable;
  Result := Self;
end;

function TZipFileBuilder.WithAES(const APassword: string): IZipFileBuilder;
begin
  FUseAES := True;
  FPassword := APassword;
  Result := Self;
end;

function TZipFileBuilder.WithPassword(const APassword: string): IZipFileBuilder;
begin
  FPassword := APassword;
  Result := Self;
end;

function TZipFileBuilder.WithLZMA(AEnable: Boolean): IZipFileBuilder;
begin
  FUseLZMA := AEnable;
  Result := Self;
end;

function TZipFileBuilder.WithForceZip64(AEnable: Boolean): IZipFileBuilder;
begin
  FForceZip64 := AEnable;
  Result := Self;
end;

function TZipFileBuilder.WithCompression(AMethod: TCompressionMethod): IZipFileBuilder;
begin
  FCompression := AMethod;
  FCompressionSet := True;
  Result := Self;
end;

function TZipFileBuilder.WithReCompression(AMethod: TReCompressionMethod): IZipFileBuilder;
begin
  FReCompression := AMethod;
  FReCompressionSet := True;
  Result := Self;
end;

function TZipFileBuilder.OnProgress(AEvent: TZipProgressEvent): IZipFileBuilder;
begin
  FOnProgress := AEvent;
  Result := Self;
end;

function TZipFileBuilder.OnArchiveChanged(AEvent: TFileChangedEvent): IZipFileBuilder;
begin
  FOnArchiveChanged := AEvent;
  Result := Self;
end;

function TZipFileBuilder.AppendStream(AStream: TStream; const AZipName: string;
                                      AOwnStream: Boolean = False): IZipFileBuilder;
var
  Idx: Integer;
begin
  Idx := Length(FItems);
  SetLength(FItems, Idx + 1);
  FItems[Idx].Kind := zbkStream;
  FItems[Idx].ZipName := AZipName;
  FItems[Idx].Stream := AStream;
  FItems[Idx].OwnStream := AOwnStream;
  Result := Self;
end;

function TZipFileBuilder.AppendFile(const ADiskFileName, AZipName: string): IZipFileBuilder;
var
  Idx: Integer;
begin
  Idx := Length(FItems);
  SetLength(FItems, Idx + 1);
  FItems[Idx].Kind := zbkFile;
  FItems[Idx].ZipName := AZipName;
  FItems[Idx].DiskFileName := ADiskFileName;
  Result := Self;
end;

function TZipFileBuilder.DeleteEntry(const AZipName: string): IZipFileBuilder;
var
  Idx: Integer;
begin
  Idx := Length(FItems);
  SetLength(FItems, Idx + 1);
  FItems[Idx].Kind := zbkDelete;
  FItems[Idx].ZipName := AZipName;
  Result := Self;
end;

function TZipFileBuilder.UpdateEntry(AStream: TStream; const AZipName: string;
                                     AOwnStream: Boolean = False): IZipFileBuilder;
var
  Idx: Integer;
begin
  Idx := Length(FItems);
  SetLength(FItems, Idx + 1);
  FItems[Idx].Kind := zbkUpdate;
  FItems[Idx].ZipName := AZipName;
  FItems[Idx].Stream := AStream;
  FItems[Idx].OwnStream := AOwnStream;
  Result := Self;
end;

procedure TZipFileBuilder.ApplySettings(AZip: TZipFile);
begin
  AZip.UseUtf8     := FUseUtf8;
  AZip.UseAES      := FUseAES;
  AZip.Password    := FPassword;
  AZip.UseLZMA     := FUseLZMA;
  AZip.ForceZip64  := FForceZip64;
  if FCompressionSet   then AZip.Compression   := FCompression;
  if FReCompressionSet then AZip.ReCompression := FReCompression;
  if Assigned(FOnProgress)       then AZip.OnProgress    := FOnProgress;
  if Assigned(FOnArchiveChanged) then AZip.OnFileChanged := FOnArchiveChanged;
end;

procedure TZipFileBuilder.Execute;
var
  Zip: TZipFile;
  I: Integer;
begin
  Zip := TZipFile.Create(nil);
  try
    Zip.FileName := FArchivePath;
    ApplySettings(Zip);
    Zip.Active := True;
    for I := 0 to High(FItems) do
    begin
      case FItems[I].Kind of
        zbkStream:
          try
            Zip.AppendStream(FItems[I].Stream, FItems[I].ZipName, Now);
          finally
            if FItems[I].OwnStream then
              FreeAndNil(FItems[I].Stream);
          end;
        zbkFile:
          Zip.AppendFileFromDisk(FItems[I].DiskFileName, FItems[I].ZipName);
        zbkDelete:
          Zip.DeleteFile(FItems[I].ZipName);
        zbkUpdate:
          try
            Zip.UpdateFile(FItems[I].Stream, FItems[I].ZipName);
          finally
            if FItems[I].OwnStream then
              FreeAndNil(FItems[I].Stream);
          end;
      end;
    end;
  finally
    Zip.Free;
  end;
  SetLength(FItems, 0);
end;

function TZipFileBuilder.ExtractStream(const AZipName: string): TStream;
var
  Zip: TZipFile;
  EntryStm: TStream;
  Mem: TMemoryStream;
begin
  // For reads we DO need to fully read into a TMemoryStream because the inner
  // TZipFile/TFileStream is destroyed when we exit. Caller owns the result.
  Zip := TZipFile.Create(nil);
  try
    Zip.FileName := FArchivePath;
    ApplySettings(Zip);
    Zip.Active := True;
    EntryStm := Zip.GetEntryStream(AZipName);
    try
      Mem := TMemoryStream.Create;
      try
        Mem.CopyFrom(EntryStm, EntryStm.Size);
        Mem.Position := 0;
        Result := Mem;
      except
        Mem.Free;
        raise;
      end;
    finally
      EntryStm.Free;
    end;
  finally
    Zip.Free;
  end;
end;

function TZipFileBuilder.HasEntry(const AZipName: string): Boolean;
var
  Zip: TZipFile;
begin
  Zip := TZipFile.Create(nil);
  try
    Zip.FileName := FArchivePath;
    ApplySettings(Zip);
    Zip.Active := True;
    Result := Zip.FileExists(AZipName);
  finally
    Zip.Free;
  end;
end;

function TZipFileBuilder.CountEntries: Cardinal;
var
  Zip: TZipFile;
begin
  Zip := TZipFile.Create(nil);
  try
    Zip.FileName := FArchivePath;
    ApplySettings(Zip);
    Zip.Active := True;
    Result := Zip.FileCount;
  finally
    Zip.Free;
  end;
end;

// =============================================================================
//   Zip (factory)
// =============================================================================

class function Zip.NewArchive(const APath: string): IZipFileBuilder;
begin
  Result := TZipFileBuilder.CreateNew(APath);
end;

class function Zip.OpenArchive(const APath: string): IZipFileBuilder;
begin
  Result := TZipFileBuilder.CreateOpen(APath);
end;

end.
