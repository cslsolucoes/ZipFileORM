{ LhaFile.Exceptions.pas

  Exception hierarchy of the LHA module (split from LhaFile.pas per
  v4.1 Wave 3b uniformity refactor). Backward compat via type aliases
  in LhaFile.pas.
}
unit LhaFile.Exceptions;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils;

type
  ELhaError = class(Exception);
  ELhaMethodNotSupported = class(ELhaError);

implementation

end.
