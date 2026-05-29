{ ZCompress.LzwStream.Interfaces.pas

  Companion interfaces de ZCompress.LzwStream.pas conforme
  backend-pascal-unit-naming_V1.6.0 §2 — declara o builder fluent
  IZCompressBuilder (anteriormente em ZCompress.Fluent.pas) na unit
  companion canônica.
}
unit ZCompress.LzwStream.Interfaces;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils, Classes;

type
  TZCompressDirection = (zcdCompress, zcdDecompress);

  IZCompressBuilder = interface
    ['{E3B947C2-8D14-4F62-9A53-71BC4D8E6A12}']
    function WithMaxBits(ABits: Integer): IZCompressBuilder;
    function ToBytes: TBytes;
    function ToString: string;
    procedure ToStream(ADest: TStream);
    procedure ToFile(const APath: string);
  end;

implementation

end.
