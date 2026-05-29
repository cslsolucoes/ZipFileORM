{ ZipFile.Types.pas

  Public types of the ZIP module (split from ZipFile.pas per v4.1 Wave 3a
  refactor). Backward compat via type alias in ZipFile.pas.

  Scope: only TZipSearchRec (user-facing API record returned by FindFirst/
  FindNext). Internal wire-format records (TLocalFileHeader, TCDFileHeader,
  TEndOfCentralDirectoryRecord, TZipFileItem) stay in ZipFile.pas — they
  are implementation detail of the binary parser and not part of the
  public surface.
}
unit ZipFile.Types;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils;

type
  TZipSearchRec = record
    DateTime : TDateTime;
    USize : Int64;
    CSize: Int64;
    Name : TFileName;
  end;

implementation

end.
