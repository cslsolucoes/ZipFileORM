{ Bzip2.Stream.Interfaces.pas

  Companion interfaces de Bzip2.Stream.pas conforme
  backend-pascal-unit-naming_V1.6.0 §2 — declara o builder fluent
  IBzip2Builder (anteriormente em Bzip2.Fluent.pas) na unit
  companion canônica.
}
unit Bzip2.Stream.Interfaces;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils, Classes;

type
  TBzip2Direction = (bzdCompress, bzdDecompress);

  IBzip2Builder = interface
    ['{D2A8F417-6B91-4C5E-9DA3-8F1E6C5B4321}']
    function WithLevel(ALevel: Integer): IBzip2Builder;
    function ToBytes: TBytes;
    function ToString: string;
    procedure ToStream(ADest: TStream);
    procedure ToFile(const APath: string);
  end;

implementation

end.
