{ SevenZ.Fluent.pas
  Fluent builder API over TSevenZFile. WRITE Store + LZMA2 + READ via factory.

  Uso (WRITE):

      SevenZ.NewArchive('out.7z')
            .WithLZMA2(5)        // ou .WithStore para Copy method
            .AppendFile('c:\src\a.txt', 'a.txt')
            .AppendBytes(bytes, 'embedded.bin')
            .Execute;

  Uso (READ — Delphi Win32/Win64 only):

      var S := SevenZ.OpenArchive('in.7z').ReadAsString('readme.txt');
}
unit SevenZ.Fluent;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils, Classes, SevenZFile;

type
  TSevenZMethod = (szmStore, szmLzma2);

  TSevenZBuilderItem = record
    Kind: (sbkFile, sbkBytes);
    EntryName: string;
    DiskFileName: string;
    Data: TBytes;
  end;

  ISevenZFileBuilder = interface
    ['{C9E1A5B2-3D8F-4C2A-8E11-7B5D4F8A39C2}']
    function WithStore: ISevenZFileBuilder;
    function WithLZMA2(ALevel: Integer = 5): ISevenZFileBuilder;
    function AppendFile(const ADiskFileName, AEntryName: string): ISevenZFileBuilder;
    function AppendBytes(const AData: TBytes; const AEntryName: string): ISevenZFileBuilder;
    procedure Execute;
    function ExtractStream(const AEntryName: string): TStream;
    function ReadAsBytes(const AEntryName: string): TBytes;
    function ReadAsString(const AEntryName: string): string;
    function HasEntry(const AEntryName: string): Boolean;
    function CountEntries: Integer;
  end;

  TSevenZFileBuilder = class(TInterfacedObject, ISevenZFileBuilder)
  private
    FArchivePath: string;
    FOpenForRead: Boolean;
    FMethod: TSevenZMethod;
    FLevel: Integer;
    FItems: array of TSevenZBuilderItem;
  public
    constructor CreateNew(const APath: string);
    constructor CreateOpen(const APath: string);
    function WithStore: ISevenZFileBuilder;
    function WithLZMA2(ALevel: Integer = 5): ISevenZFileBuilder;
    function AppendFile(const ADiskFileName, AEntryName: string): ISevenZFileBuilder;
    function AppendBytes(const AData: TBytes; const AEntryName: string): ISevenZFileBuilder;
    procedure Execute;
    function ExtractStream(const AEntryName: string): TStream;
    function ReadAsBytes(const AEntryName: string): TBytes;
    function ReadAsString(const AEntryName: string): string;
    function HasEntry(const AEntryName: string): Boolean;
    function CountEntries: Integer;
  end;

  SevenZip = class
  public
    class function NewArchive(const APath: string): ISevenZFileBuilder;
    class function OpenArchive(const APath: string): ISevenZFileBuilder;
  end;

implementation

constructor TSevenZFileBuilder.CreateNew(const APath: string);
begin
  inherited Create;
  FArchivePath := APath;
  FOpenForRead := False;
  FMethod := szmStore;
  FLevel := 5;
  if SysUtils.FileExists(APath) then SysUtils.DeleteFile(APath);
end;

constructor TSevenZFileBuilder.CreateOpen(const APath: string);
begin
  inherited Create;
  FArchivePath := APath;
  FOpenForRead := True;
end;

function TSevenZFileBuilder.WithStore: ISevenZFileBuilder;
begin
  FMethod := szmStore;
  Result := Self;
end;

function TSevenZFileBuilder.WithLZMA2(ALevel: Integer): ISevenZFileBuilder;
begin
  FMethod := szmLzma2;
  FLevel := ALevel;
  Result := Self;
end;

function TSevenZFileBuilder.AppendFile(const ADiskFileName, AEntryName: string): ISevenZFileBuilder;
var Item: TSevenZBuilderItem;
begin
  Item.Kind := sbkFile;
  Item.DiskFileName := ADiskFileName;
  Item.EntryName := AEntryName;
  SetLength(FItems, Length(FItems) + 1);
  FItems[High(FItems)] := Item;
  Result := Self;
end;

function TSevenZFileBuilder.AppendBytes(const AData: TBytes;
  const AEntryName: string): ISevenZFileBuilder;
var Item: TSevenZBuilderItem;
begin
  Item.Kind := sbkBytes;
  Item.EntryName := AEntryName;
  Item.Data := AData;
  SetLength(FItems, Length(FItems) + 1);
  FItems[High(FItems)] := Item;
  Result := Self;
end;

procedure TSevenZFileBuilder.Execute;
var
  Sz: TSevenZFile;
  Names: array of string;
  Datas: array of TBytes;
  I: Integer;
  Fs: TFileStream;
begin
  if Length(FItems) = 0 then
    raise Exception.Create('TSevenZFileBuilder.Execute: nenhum item appended');

  SetLength(Names, Length(FItems));
  SetLength(Datas, Length(FItems));
  for I := 0 to High(FItems) do
  begin
    Names[I] := FItems[I].EntryName;
    if FItems[I].Kind = sbkFile then
    begin
      Fs := TFileStream.Create(FItems[I].DiskFileName, fmOpenRead or fmShareDenyWrite);
      try
        SetLength(Datas[I], Fs.Size);
        if Fs.Size > 0 then Fs.ReadBuffer(Datas[I][0], Fs.Size);
      finally Fs.Free; end;
    end
    else
      Datas[I] := FItems[I].Data;
  end;

  Sz := TSevenZFile.Create(nil);
  try
    Sz.FileName := FArchivePath;
    case FMethod of
      szmStore: Sz.CreateFromBytes(Names, Datas);
      szmLzma2: Sz.CreateFromBytesLzma2(Names, Datas, FLevel);
    end;
  finally Sz.Free; end;
end;

function TSevenZFileBuilder.ExtractStream(const AEntryName: string): TStream;
var Sz: TSevenZFile;
begin
  Sz := TSevenZFile.Create(nil);
  try
    Sz.FileName := FArchivePath;
    Sz.Active := True;
    Result := Sz.GetEntryStream(AEntryName);
  finally Sz.Free; end;
end;

function TSevenZFileBuilder.ReadAsBytes(const AEntryName: string): TBytes;
var Sz: TSevenZFile;
begin
  Sz := TSevenZFile.Create(nil);
  try
    Sz.FileName := FArchivePath;
    Sz.Active := True;
    Result := Sz.ReadAsBytes(AEntryName);
  finally Sz.Free; end;
end;

function TSevenZFileBuilder.ReadAsString(const AEntryName: string): string;
var Sz: TSevenZFile;
begin
  Sz := TSevenZFile.Create(nil);
  try
    Sz.FileName := FArchivePath;
    Sz.Active := True;
    Result := Sz.ReadAsString(AEntryName);
  finally Sz.Free; end;
end;

function TSevenZFileBuilder.HasEntry(const AEntryName: string): Boolean;
var Sz: TSevenZFile;
begin
  Sz := TSevenZFile.Create(nil);
  try
    Sz.FileName := FArchivePath;
    Sz.Active := True;
    Result := Sz.FileExists(AEntryName);
  finally Sz.Free; end;
end;

function TSevenZFileBuilder.CountEntries: Integer;
var Sz: TSevenZFile;
begin
  Sz := TSevenZFile.Create(nil);
  try
    Sz.FileName := FArchivePath;
    Sz.Active := True;
    Result := Sz.EntryCount;
  finally Sz.Free; end;
end;

class function SevenZip.NewArchive(const APath: string): ISevenZFileBuilder;
begin
  Result := TSevenZFileBuilder.CreateNew(APath);
end;

class function SevenZip.OpenArchive(const APath: string): ISevenZFileBuilder;
begin
  Result := TSevenZFileBuilder.CreateOpen(APath);
end;

end.
