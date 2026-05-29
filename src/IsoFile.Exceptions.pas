{ =============================================================================
  IsoFile.Exceptions - Exception class of the ISO module

  Descrição:
  Companion exception unit of IsoFile.pas. Split from IsoFile.pas per
  v4.1 Wave 3b uniformity refactor.

  Características:
  - EIsoError (single class — raised on ISO 9660 parse errors, invalid
    volume descriptors, unsupported extensions, etc.)
  - Backward-compatible re-export via `type` alias in IsoFile.pas
  - Cross-platform: Delphi (D24..D37 Win32+Win64) + FPC/Lazarus

  Project:        ZipFileORM
  ProjectVersion: 4.0.0
  FileVersion:    1.0.0
  Author:         CSL Softwares
  Date:           28/05/2026

  Changelog (file):
  - 1.0.0 (28/05/2026): created — split from IsoFile.pas (Wave 3b).
  ============================================================================= }
unit IsoFile.Exceptions;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils;

type
  EIsoError = class(Exception);

implementation

end.
