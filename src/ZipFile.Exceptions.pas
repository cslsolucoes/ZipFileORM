{ =============================================================================
  ZipFile.Exceptions - Exception classes of the ZIP module

  Descrição:
  Companion exception unit of ZipFile.pas. Split from ZipFile.pas per
  v4.1 Wave 3a refactor.

  Características:
  - EZipFileCancelled (raised when consumer callback aborts an operation)
  - EZipFileZip64NotSupported (raised when ZIP64 needed but disabled/unsupported)
  - Backward-compatible re-export via `type` aliases in ZipFile.pas
  - Cross-platform: Delphi (D24..D37 Win32+Win64) + FPC/Lazarus

  Project:        ZipFileORM
  ProjectVersion: 4.0.0
  FileVersion:    1.0.0
  Author:         CSL Softwares
  Date:           28/05/2026

  Changelog (file):
  - 1.0.0 (28/05/2026): created — split from ZipFile.pas (Wave 3a).
  ============================================================================= }
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
