{ =============================================================================
  ZipFile.Types - Public type definitions of the ZIP module

  Descrição:
  Companion types unit of ZipFile.pas. Holds the public-facing TZipSearchRec
  record returned by FindFirst/FindNext iteration over a ZIP central directory.

  Scope deliberately limited: internal wire-format records (TLocalFileHeader,
  TCDFileHeader, TEndOfCentralDirectoryRecord, TZipFileItem) remain in
  ZipFile.pas — they are implementation detail of the binary parser and not
  part of the public surface a consumer should depend on.

  Características:
  - 1 public record (TZipSearchRec — name + dates + sizes per entry)
  - Backward-compatible re-export via `type` alias in ZipFile.pas
  - Cross-platform: Delphi (D24..D37 Win32+Win64) + FPC/Lazarus

  Project:        ZipFileORM
  ProjectVersion: 4.0.0
  FileVersion:    1.0.0
  Author:         CSL Softwares
  Date:           28/05/2026

  Changelog (file):
  - 1.0.0 (28/05/2026): created — split from ZipFile.pas (Wave 3a).
  ============================================================================= }
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
