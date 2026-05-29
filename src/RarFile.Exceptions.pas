{ =============================================================================
  RarFile.Exceptions - Exception hierarchy of the RAR module

  Descrição:
  Companion exception unit of RarFile.pas. Split from RarFile.pas per
  v4.1 Wave 3b uniformity refactor.

  Características:
  - ERarError (base) raised on generic RAR parse errors
  - ERarMethodNotSupported raised on compressed entries (current reader
    is metadata-only — full RAR decoder is v5.0 scope)
  - ERarUnsupportedFormat raised when archive is neither RAR4 nor RAR5
    or uses encryption headers not yet handled
  - Backward-compatible re-export via `type` aliases in RarFile.pas
  - Cross-platform: Delphi (D24..D37 Win32+Win64) + FPC/Lazarus

  Project:        ZipFileORM
  ProjectVersion: 4.0.0
  FileVersion:    1.0.0
  Author:         CSL Softwares
  Date:           28/05/2026

  Changelog (file):
  - 1.0.0 (28/05/2026): created — split from RarFile.pas (Wave 3b).
  ============================================================================= }
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
