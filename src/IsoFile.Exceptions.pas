{ IsoFile.Exceptions.pas

  Exception class of the ISO module (split from IsoFile.pas per v4.1
  Wave 3b uniformity refactor). Backward compat via type alias in
  IsoFile.pas.
}
unit IsoFile.Exceptions;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils;

type
  EIsoError = class(Exception);

implementation

end.
