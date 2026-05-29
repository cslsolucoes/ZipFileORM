{ RarFile.Exceptions.pas

  Exception hierarchy of the RAR module (split from RarFile.pas per
  v4.1 Wave 3b uniformity refactor). Backward compat via type aliases
  in RarFile.pas.
}
unit RarFile.Exceptions;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils;

type
  ERarError = class(Exception);
  ERarMethodNotSupported = class(ERarError);
  ERarUnsupportedFormat = class(ERarError);

implementation

end.
