{ ZipFileORM.Interfaces.pas

  Contratos publicos cross-format do ZipFileORM:
  - IArchive: interface read-only comum para leitura de qualquer formato
  - IArchiveEntry: registro de entrada (file/directory) dentro do archive
  - IArchiveEnumerator: enumeracao das entries

  Cada modulo format (ZipFile, TarFile, etc.) pode implementar IArchive
  expondo sua leitura via um adapter — a facade ZipFileORM.pas usa esse
  contrato como output uniforme de TArchive.OpenFile().

  ZipFileORM v4.0.0 — facade public contracts.
}
unit ZipFileORM.Interfaces;

{$I Commons.FPC.inc}

interface

uses
  SysUtils, Classes,
  Commons.Types,
  ZipFileORM.Compression;

type
  // Entrada (file ou directory) dentro de um archive — visão read-only
  IArchiveEntry = interface
    ['{B5E7A1F0-9C3D-4E5A-8B7F-1234567890AB}']
    function GetName: string;
    function GetSize: Int64;
    function GetCompressedSize: Int64;
    function GetDateTime: TDateTime;
    function GetIsDirectory: Boolean;
    function GetIsEncrypted: Boolean;
    function GetMethod: TCompressionMethod;
    function GetComment: string;

    property Name: string read GetName;
    property Size: Int64 read GetSize;
    property CompressedSize: Int64 read GetCompressedSize;
    property DateTime: TDateTime read GetDateTime;
    property IsDirectory: Boolean read GetIsDirectory;
    property IsEncrypted: Boolean read GetIsEncrypted;
    property Method: TCompressionMethod read GetMethod;
    property Comment: string read GetComment;
  end;

  // Archive aberto — contrato read-only comum a todos os formatos
  IArchive = interface
    ['{C4D5E6F7-8901-2345-6789-ABCDEF012345}']
    function GetFileName: string;
    function GetEntryCount: Integer;
    function GetEntry(AIndex: Integer): IArchiveEntry;
    function FindEntry(const AName: string): IArchiveEntry;
    function EntryExists(const AName: string): Boolean;
    function ReadEntryAsBytes(const AName: string): TBytes;
    function ReadEntryAsString(const AName: string): string;
    procedure ExtractEntry(const AName: string; ATarget: TStream); overload;
    procedure ExtractEntry(const AName: string; const ATargetPath: string); overload;
    procedure Close;

    property FileName: string read GetFileName;
    property EntryCount: Integer read GetEntryCount;
    property Entries[Index: Integer]: IArchiveEntry read GetEntry; default;
  end;

  // Builder fluent base — cada formato write-capable estende esta interface
  IArchiveBuilder = interface
    ['{D5E6F708-9012-3456-789A-BCDEF0123456}']
    function WithFileName(const AFileName: string): IArchiveBuilder;
    function WithPassword(const APassword: string): IArchiveBuilder;
    function WithMethod(AMethod: TCompressionMethod): IArchiveBuilder;
    function Build: IArchive;
  end;

implementation

end.
