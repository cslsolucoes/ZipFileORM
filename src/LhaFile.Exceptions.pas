{ =============================================================================
  LhaFile.Exceptions - Exception hierarchy of the LHA module

  Descrição:
  Companion exception unit of LhaFile.pas. Split from LhaFile.pas per
  v4.1 Wave 3b uniformity refactor.

  Características:
  - ELhaError (base) raised on generic LHA parse/header errors
  - ELhaMethodNotSupported raised when entry uses method other than -lh0-
    (Store) — actual decoding is limited in the pure-pascal v3.x reader
  - Backward-compatible re-export via `type` aliases in LhaFile.pas
  - Cross-platform: Delphi (D24..D37 Win32+Win64) + FPC/Lazarus

  Project:        ZipFileORM
  ProjectVersion: 4.0.0
  FileVersion:    1.0.0
  Author:         CSL Softwares
  Date:           28/05/2026

  Changelog (file):
  - 1.0.0 (28/05/2026): created — split from LhaFile.pas (Wave 3b).
  ============================================================================= }
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
