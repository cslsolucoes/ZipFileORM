{ SevenZFile.Exceptions.pas

  Exception hierarchy of the 7Z module (split from SevenZFile.pas per
  v4.1 Wave 3a refactor). Backward compat via type aliases in SevenZFile.pas.
}
unit SevenZFile.Exceptions;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils;

type
  ESevenZError = class(Exception);
  ESevenZNotSupportedOnPlatform = class(ESevenZError);

implementation

end.
