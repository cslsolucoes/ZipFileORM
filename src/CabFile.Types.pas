{ =============================================================================
  CabFile.Types - Public type definitions of the CAB module

  Descrição:
  Companion types unit of CabFile.pas, holding public-facing record types.
  Split from CabFile.pas per v4.1 Wave 3a refactor.

  Note: TCabCompressionType continues to live in CabFile.Interfaces.pas
  (where ICabFileBuilder needs it). Internal Win32 FDI* records remain
  in CabFile.pas implementation section (not public API).

  Características:
  - 1 public record (TCabEntry — entry metadata returned by enumeration)
  - Backward-compatible re-export via `type` aliases in CabFile.pas
  - Cross-platform: Delphi (D24..D37 Win32+Win64) + FPC/Lazarus

  Project:        ZipFileORM
  ProjectVersion: 4.0.0
  FileVersion:    1.0.0
  Author:         CSL Softwares
  Date:           28/05/2026

  Changelog (file):
  - 1.0.0 (28/05/2026): created — split from CabFile.pas (Wave 3a).
  ============================================================================= }
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
