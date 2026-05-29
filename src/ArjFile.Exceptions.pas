{ =============================================================================
  ArjFile.Exceptions - Exception hierarchy of the ARJ module

  Descrição:
  Companion exception unit of ArjFile.pas. Split from ArjFile.pas per
  v4.1 Wave 3b uniformity refactor (mirrors the Wave 3a pattern applied
  to CabFile/SevenZFile/ZipFile).

  Características:
  - EArjError (base) raised on generic ARJ parse/decode errors
  - EArjMethodNotSupported raised when entry uses ARJ method >0 (Wxx) —
    only method 0 (Store) is decoded by the pure-pascal v3.x reader
  - Backward-compatible re-export via `type` aliases in ArjFile.pas
  - Cross-platform: Delphi (D24..D37 Win32+Win64) + FPC/Lazarus

  Project:        ZipFileORM
  ProjectVersion: 4.0.0
  FileVersion:    1.0.0
  Author:         CSL Softwares
  Date:           28/05/2026

  Changelog (file):
  - 1.0.0 (28/05/2026): created — split from ArjFile.pas (Wave 3b).
  ============================================================================= }
unit ArjFile.Exceptions;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils;

type
  EArjError = class(Exception);
  EArjMethodNotSupported = class(EArjError);

implementation

end.
