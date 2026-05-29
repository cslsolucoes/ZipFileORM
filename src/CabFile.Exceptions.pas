{ CabFile.Exceptions.pas

  Exception hierarchy of the CAB module (split from CabFile.pas per v4.1
  Wave 3a refactor). Backward compat: CabFile.pas re-exports both types
  via `type` aliases — `uses CabFile` consumers see no change.
}
unit CabFile.Exceptions;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils;

type
  ECabError = class(Exception);
  ECabNotSupportedOnPlatform = class(ECabError);

implementation

end.
