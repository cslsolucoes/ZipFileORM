{ SevenZFile.Interfaces.pas

  Companion interfaces de SevenZFile.pas conforme
  backend-pascal-unit-naming_V1.6.0 §2 — declara o builder fluent
  ISevenZFileBuilder (anteriormente em SevenZ.Fluent.pas) na unit
  companion canônica.
}
unit SevenZFile.Interfaces;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils, Classes;

type
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

implementation

end.
