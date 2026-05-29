{ ArjFile.Exceptions.pas

  Exception hierarchy of the ARJ module (split from ArjFile.pas per
  v4.1 Wave 3b uniformity refactor). Backward compat via type aliases
  in ArjFile.pas.
}
unit ArjFile.Exceptions;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils;

type
  EArjError = class(Exception);
  EArjMethodNotSupported = class(EArjError);

implementation

end.
