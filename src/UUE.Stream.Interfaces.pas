{ UUE.Stream.Interfaces.pas

  Companion interfaces de UUE.Stream.pas conforme
  backend-pascal-unit-naming_V1.6.0 §2 — declara o builder fluent
  IUueBuilder (anteriormente em UUE.Fluent.pas) na unit companion
  canônica.
}
unit UUE.Stream.Interfaces;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils, Classes;

type
  TUueDirection = (uudEncode, uudDecode);

  IUueBuilder = interface
    ['{A7E2D158-9F4B-4C5E-AB12-3E8F9D5C4B17}']
    function WithFileName(const AName: string): IUueBuilder;
    function WithMode(AMode: Cardinal): IUueBuilder;
    function ToString: string;
    function ToBytes: TBytes;
    procedure ToStream(ADest: TStream);
    procedure ToFile(const APath: string);
  end;

implementation

end.
