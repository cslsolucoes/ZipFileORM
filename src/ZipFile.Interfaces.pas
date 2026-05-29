{ ZipFile.Interfaces.pas

  Companion interfaces de ZipFile.pas conforme
  backend-pascal-unit-naming_V1.6.0 §2 — declara o builder fluent
  IZipFileBuilder (anteriormente em ZipFile.Fluent.pas) e os tipos
  que o contrato utiliza (TCompressionMethod, TReCompressionMethod,
  TFileChangedEvent).

  ZipFile.pas re-exporta os tipos via alias para preservar
  retro-compatibilidade dos consumidores que fazem `uses ZipFile`.
}
unit ZipFile.Interfaces;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils, Classes, Commons.Progress;

type
  TCompressionMethod = (cmNone, cmMaximal);
  TReCompressionMethod = (rmKeepOriginal, rmNone, rmMaximal);

  TFileChangedEvent = procedure(Sender: TObject) of object;

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

implementation

end.
