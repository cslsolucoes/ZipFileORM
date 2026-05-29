{ ZipFile.Exceptions.pas

  Exceptions of the ZIP module (split from ZipFile.pas per v4.1 Wave 3a
  refactor). Backward compat via type aliases in ZipFile.pas.
}
unit ZipFile.Exceptions;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils;

type
  EZipFileCancelled = class(Exception);
  EZipFileZip64NotSupported = class(Exception);

implementation

end.
