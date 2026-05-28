{ Tar.Fluent.pas
  Fluent builder API over TTarFile + TTarGzFile.

  Uso (TAR puro):

      Tar.NewArchive('out.tar')
         .AppendFile('c:\src\a.txt', 'a.txt')
         .AppendBytes(data, 'data.bin')
         .Execute;

  Uso (TAR.GZ):

      Tar.NewGzArchive('out.tar.gz')
         .WithGzipLevel(9)
         .AppendFile('c:\src\big.log', 'log.txt')
         .Execute;

  Uso (READ):

      var Stm := Tar.OpenArchive('in.tar').ExtractStream('readme.txt');
}
unit Tar.Fluent;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils, Classes, TarFile, TarGzFile;

type
  TTarBuilderItem = record
    Kind: (tbkFile, tbkBytes, tbkString, tbkDir);
    DiskFileName: string;
    EntryName: string;
    Data: TBytes;
    StrData: string;
    ModTime: TDateTime;
  end;

  ITarFileBuilder = interface
    ['{F8A3D912-4E6B-4C1A-9E51-2A8C7B3D911E}']
    function WithGzip(AEnable: Boolean = True): ITarFileBuilder;
    function WithGzipLevel(ALevel: Integer): ITarFileBuilder;
    function AppendFile(const ADiskFileName, AEntryName: string): ITarFileBuilder;
    function AppendBytes(const AData: TBytes; const AEntryName: string): ITarFileBuilder;
    function AppendString(const AContent, AEntryName: string): ITarFileBuilder;
    function AppendDirectory(const ADirName: string): ITarFileBuilder;
    procedure Execute;
    function ExtractStream(const AEntryName: string): TStream;
    function ReadAsBytes(const AEntryName: string): TBytes;
    function ReadAsString(const AEntryName: string): string;
    function HasEntry(const AEntryName: string): Boolean;
    function CountEntries: Integer;
  end;

  TTarFileBuilder = class(TInterfacedObject, ITarFileBuilder)
  private
    FArchivePath: string;
    FOpenForRead: Boolean;
    FUseGzip: Boolean;
    FGzipLevel: Integer;
    FItems: array of TTarBuilderItem;
    procedure ApplyItems(ATar: TTarFile);
  public
    constructor CreateNew(const APath: string; AGzip: Boolean);
    constructor CreateOpen(const APath: string; AGzip: Boolean);
    function WithGzip(AEnable: Boolean = True): ITarFileBuilder;
    function WithGzipLevel(ALevel: Integer): ITarFileBuilder;
    function AppendFile(const ADiskFileName, AEntryName: string): ITarFileBuilder;
    function AppendBytes(const AData: TBytes; const AEntryName: string): ITarFileBuilder;
    function AppendString(const AContent, AEntryName: string): ITarFileBuilder;
    function AppendDirectory(const ADirName: string): ITarFileBuilder;
    procedure Execute;
    function ExtractStream(const AEntryName: string): TStream;
    function ReadAsBytes(const AEntryName: string): TBytes;
    function ReadAsString(const AEntryName: string): string;
    function HasEntry(const AEntryName: string): Boolean;
    function CountEntries: Integer;
  end;

  Tarball = class
  public
    class function NewArchive(const APath: string): ITarFileBuilder;
    class function NewGzArchive(const APath: string): ITarFileBuilder;
    class function OpenArchive(const APath: string): ITarFileBuilder;
    class function OpenGzArchive(const APath: string): ITarFileBuilder;
  end;

implementation

constructor TTarFileBuilder.CreateNew(const APath: string; AGzip: Boolean);
begin
  inherited Create;
  FArchivePath := APath;
  FOpenForRead := False;
  FUseGzip := AGzip;
  FGzipLevel := 6;
  if SysUtils.FileExists(APath) then SysUtils.DeleteFile(APath);
end;

constructor TTarFileBuilder.CreateOpen(const APath: string; AGzip: Boolean);
begin
  inherited Create;
  FArchivePath := APath;
  FOpenForRead := True;
  FUseGzip := AGzip;
end;

function TTarFileBuilder.WithGzip(AEnable: Boolean): ITarFileBuilder;
begin
  FUseGzip := AEnable;
  Result := Self;
end;

function TTarFileBuilder.WithGzipLevel(ALevel: Integer): ITarFileBuilder;
begin
  FGzipLevel := ALevel;
  Result := Self;
end;

function TTarFileBuilder.AppendFile(const ADiskFileName, AEntryName: string): ITarFileBuilder;
var Item: TTarBuilderItem;
begin
  Item.Kind := tbkFile;
  Item.DiskFileName := ADiskFileName;
  Item.EntryName := AEntryName;
  SetLength(FItems, Length(FItems) + 1);
  FItems[High(FItems)] := Item;
  Result := Self;
end;

function TTarFileBuilder.AppendBytes(const AData: TBytes; const AEntryName: string): ITarFileBuilder;
var Item: TTarBuilderItem;
begin
  Item.Kind := tbkBytes;
  Item.Data := AData;
  Item.EntryName := AEntryName;
  SetLength(FItems, Length(FItems) + 1);
  FItems[High(FItems)] := Item;
  Result := Self;
end;

function TTarFileBuilder.AppendString(const AContent, AEntryName: string): ITarFileBuilder;
var Item: TTarBuilderItem;
begin
  Item.Kind := tbkString;
  Item.StrData := AContent;
  Item.EntryName := AEntryName;
  SetLength(FItems, Length(FItems) + 1);
  FItems[High(FItems)] := Item;
  Result := Self;
end;

function TTarFileBuilder.AppendDirectory(const ADirName: string): ITarFileBuilder;
var Item: TTarBuilderItem;
begin
  Item.Kind := tbkDir;
  Item.EntryName := ADirName;
  Item.ModTime := Now;
  SetLength(FItems, Length(FItems) + 1);
  FItems[High(FItems)] := Item;
  Result := Self;
end;

procedure TTarFileBuilder.ApplyItems(ATar: TTarFile);
var I: Integer;
begin
  for I := 0 to High(FItems) do
    case FItems[I].Kind of
      tbkFile:   ATar.AppendFileFromDisk(FItems[I].DiskFileName, FItems[I].EntryName);
      tbkBytes:  ATar.AppendBytes(FItems[I].Data, FItems[I].EntryName);
      tbkString: ATar.AppendString(FItems[I].StrData, FItems[I].EntryName);
      tbkDir:    ATar.AppendDirectoryEntry(FItems[I].EntryName, FItems[I].ModTime);
    end;
end;

procedure TTarFileBuilder.Execute;
var
  Tar: TTarFile;
  TarGz: TTarGzFile;
  I: Integer;
begin
  if Length(FItems) = 0 then
    raise Exception.Create('TTarFileBuilder.Execute: nenhum item appended');
  if FUseGzip then
  begin
    // TTarGzFile expoe AppendFileFromDisk/AppendBytes/AppendString diretamente
    // (delega internamente). AppendDirectoryEntry nao esta exposto — skipped.
    TarGz := TTarGzFile.Create(nil);
    try
      TarGz.FileName := FArchivePath;
      TarGz.GzipLevel := FGzipLevel;
      TarGz.Active := True;
      for I := 0 to High(FItems) do
        case FItems[I].Kind of
          tbkFile:   TarGz.AppendFileFromDisk(FItems[I].DiskFileName, FItems[I].EntryName);
          tbkBytes:  TarGz.AppendBytes(FItems[I].Data, FItems[I].EntryName);
          tbkString: TarGz.AppendString(FItems[I].StrData, FItems[I].EntryName);
          tbkDir:    ; // TTarGzFile nao expoe AppendDirectoryEntry
        end;
    finally TarGz.Free; end;
  end
  else
  begin
    Tar := TTarFile.Create(nil);
    try
      Tar.FileName := FArchivePath;
      Tar.Active := True;
      ApplyItems(Tar);
    finally Tar.Free; end;
  end;
end;

function TTarFileBuilder.ExtractStream(const AEntryName: string): TStream;
var
  Tar: TTarFile;
  TarGz: TTarGzFile;
begin
  if FUseGzip then
  begin
    TarGz := TTarGzFile.Create(nil);
    try
      TarGz.FileName := FArchivePath;
      TarGz.Active := True;
      Result := TarGz.GetEntryStream(AEntryName);
    finally TarGz.Free; end;
  end
  else
  begin
    Tar := TTarFile.Create(nil);
    try
      Tar.FileName := FArchivePath;
      Tar.Active := True;
      Result := Tar.GetEntryStream(AEntryName);
    finally Tar.Free; end;
  end;
end;

function TTarFileBuilder.ReadAsBytes(const AEntryName: string): TBytes;
var Stm: TStream;
begin
  Stm := ExtractStream(AEntryName);
  try
    SetLength(Result, Stm.Size);
    Stm.Position := 0;
    if Stm.Size > 0 then Stm.ReadBuffer(Result[0], Stm.Size);
  finally Stm.Free; end;
end;

function TTarFileBuilder.ReadAsString(const AEntryName: string): string;
var B: TBytes;
begin
  B := ReadAsBytes(AEntryName);
  if Length(B) = 0 then Result := ''
  else Result := TEncoding.UTF8.GetString(B);
end;

function TTarFileBuilder.HasEntry(const AEntryName: string): Boolean;
var
  Tar: TTarFile;
  TarGz: TTarGzFile;
begin
  if FUseGzip then
  begin
    TarGz := TTarGzFile.Create(nil);
    try
      TarGz.FileName := FArchivePath;
      TarGz.Active := True;
      Result := TarGz.FileExists(AEntryName);
    finally TarGz.Free; end;
  end
  else
  begin
    Tar := TTarFile.Create(nil);
    try
      Tar.FileName := FArchivePath;
      Tar.Active := True;
      Result := Tar.FileExists(AEntryName);
    finally Tar.Free; end;
  end;
end;

function TTarFileBuilder.CountEntries: Integer;
var
  Tar: TTarFile;
  TarGz: TTarGzFile;
begin
  if FUseGzip then
  begin
    TarGz := TTarGzFile.Create(nil);
    try
      TarGz.FileName := FArchivePath;
      TarGz.Active := True;
      Result := TarGz.EntryCount;
    finally TarGz.Free; end;
  end
  else
  begin
    Tar := TTarFile.Create(nil);
    try
      Tar.FileName := FArchivePath;
      Tar.Active := True;
      Result := Tar.EntryCount;
    finally Tar.Free; end;
  end;
end;

class function Tarball.NewArchive(const APath: string): ITarFileBuilder;
begin Result := TTarFileBuilder.CreateNew(APath, False); end;

class function Tarball.NewGzArchive(const APath: string): ITarFileBuilder;
begin Result := TTarFileBuilder.CreateNew(APath, True); end;

class function Tarball.OpenArchive(const APath: string): ITarFileBuilder;
begin Result := TTarFileBuilder.CreateOpen(APath, False); end;

class function Tarball.OpenGzArchive(const APath: string): ITarFileBuilder;
begin Result := TTarFileBuilder.CreateOpen(APath, True); end;

end.
