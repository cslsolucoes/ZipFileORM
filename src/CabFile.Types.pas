{ CabFile.Types.pas

  Public types of the CAB module (split from CabFile.pas per v4.1 Wave 3a
  refactor). Backward compat: CabFile.pas re-exports via `type` aliases.

  Note: TCabCompressionType continues to live in CabFile.Interfaces.pas
  (where ICabFileBuilder needs it). Internal Win32 FDI* records remain
  in CabFile.pas implementation section (not public API).
}
unit CabFile.Types;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils;

type
  TCabEntry = record
    Name: string;
    Size: Int64;
    Date: TDateTime;
  end;

implementation

end.
