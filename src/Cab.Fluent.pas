{ Cab.Fluent.pas
  Fluent builder API over TCabFile — opt-in convenience wrapper para builder
  chain de criacao + leitura. Pattern espelha ZipFile.Fluent.

  Uso (WRITE):

      Cab.NewArchive('out.cab')
         .WithCompression(cctMSZIP)
         .AppendFile('c:\src\a.txt', 'a.txt')
         .AppendFile('c:\src\b.txt', 'b.txt')
         .Execute;

  Uso (READ):

      var Stm := Cab.OpenArchive('in.cab').ExtractStream('readme.txt');
      try ... finally Stm.Free; end;

  Builder owns internal TCabFile (criado/destruido em terminals).
}
unit Cab.Fluent;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils, Classes, CabFile;

type
  TCabBuilderItem = record
    DiskFileName: string;
    EntryName: string;
  end;

  ICabFileBuilder = interface
    ['{4B7A3E84-2C95-4A11-BA42-E6F1A3D29111}']
    function WithCompression(AKind: TCabCompressionType): ICabFileBuilder;
    function AppendFile(const ADiskFileName, AEntryName: string): ICabFileBuilder;
    procedure Execute;
    function ExtractStream(const AEntryName: string): TStream;
    function ReadAsBytes(const AEntryName: string): TBytes;
    function ReadAsString(const AEntryName: string): string;
    function HasEntry(const AEntryName: string): Boolean;
    function CountEntries: Integer;
  end;

  TCabFileBuilder = class(TInterfacedObject, ICabFileBuilder)
  private
    FArchivePath: string;
    FOpenForRead: Boolean;
    FCompression: TCabCompressionType;
    FItems: array of TCabBuilderItem;
  public
    constructor CreateNew(const APath: string);
    constructor CreateOpen(const APath: string);
    function WithCompression(AKind: TCabCompressionType): ICabFileBuilder;
    function AppendFile(const ADiskFileName, AEntryName: string): ICabFileBuilder;
    procedure Execute;
    function ExtractStream(const AEntryName: string): TStream;
    function ReadAsBytes(const AEntryName: string): TBytes;
    function ReadAsString(const AEntryName: string): string;
    function HasEntry(const AEntryName: string): Boolean;
    function CountEntries: Integer;
  end;

  Cabinet = class
  public
    class function NewArchive(const APath: string): ICabFileBuilder;
    class function OpenArchive(const APath: string): ICabFileBuilder;
  end;

implementation

constructor TCabFileBuilder.CreateNew(const APath: string);
begin
  inherited Create;
  FArchivePath := APath;
  FOpenForRead := False;
  FCompression := cctNone;
  if SysUtils.FileExists(APath) then SysUtils.DeleteFile(APath);
end;

constructor TCabFileBuilder.CreateOpen(const APath: string);
begin
  inherited Create;
  FArchivePath := APath;
  FOpenForRead := True;
end;

function TCabFileBuilder.WithCompression(AKind: TCabCompressionType): ICabFileBuilder;
begin
  FCompression := AKind;
  Result := Self;
end;

function TCabFileBuilder.AppendFile(const ADiskFileName, AEntryName: string): ICabFileBuilder;
var Item: TCabBuilderItem;
begin
  Item.DiskFileName := ADiskFileName;
  Item.EntryName := AEntryName;
  SetLength(FItems, Length(FItems) + 1);
  FItems[High(FItems)] := Item;
  Result := Self;
end;

procedure TCabFileBuilder.Execute;
var
  Cab: TCabFile;
  List: array of string;
  I: Integer;
begin
  if Length(FItems) = 0 then
    raise Exception.Create('TCabFileBuilder.Execute: nenhum file appended');
  Cab := TCabFile.Create(nil);
  try
    Cab.FileName := FArchivePath;
    Cab.Compression := FCompression;
    SetLength(List, Length(FItems) * 2);
    for I := 0 to High(FItems) do
    begin
      List[I * 2]     := FItems[I].DiskFileName;
      List[I * 2 + 1] := FItems[I].EntryName;
    end;
    Cab.CreateFromFiles(List);
  finally Cab.Free; end;
end;

function TCabFileBuilder.ExtractStream(const AEntryName: string): TStream;
var Cab: TCabFile;
begin
  Cab := TCabFile.Create(nil);
  try
    Cab.FileName := FArchivePath;
    Cab.Active := True;
    Result := Cab.GetEntryStream(AEntryName);
  finally Cab.Free; end;
end;

function TCabFileBuilder.ReadAsBytes(const AEntryName: string): TBytes;
var Cab: TCabFile;
begin
  Cab := TCabFile.Create(nil);
  try
    Cab.FileName := FArchivePath;
    Cab.Active := True;
    Result := Cab.ReadAsBytes(AEntryName);
  finally Cab.Free; end;
end;

function TCabFileBuilder.ReadAsString(const AEntryName: string): string;
var Cab: TCabFile;
begin
  Cab := TCabFile.Create(nil);
  try
    Cab.FileName := FArchivePath;
    Cab.Active := True;
    Result := Cab.ReadAsString(AEntryName);
  finally Cab.Free; end;
end;

function TCabFileBuilder.HasEntry(const AEntryName: string): Boolean;
var Cab: TCabFile;
begin
  Cab := TCabFile.Create(nil);
  try
    Cab.FileName := FArchivePath;
    Cab.Active := True;
    Result := Cab.FileExists(AEntryName);
  finally Cab.Free; end;
end;

function TCabFileBuilder.CountEntries: Integer;
var Cab: TCabFile;
begin
  Cab := TCabFile.Create(nil);
  try
    Cab.FileName := FArchivePath;
    Cab.Active := True;
    Result := Cab.EntryCount;
  finally Cab.Free; end;
end;

class function Cabinet.NewArchive(const APath: string): ICabFileBuilder;
begin
  Result := TCabFileBuilder.CreateNew(APath);
end;

class function Cabinet.OpenArchive(const APath: string): ICabFileBuilder;
begin
  Result := TCabFileBuilder.CreateOpen(APath);
end;

end.
