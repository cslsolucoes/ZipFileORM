{ =============================================================================
  CabFile.Exceptions - Exception hierarchy of the CAB module

  Descrição:
  Companion exception unit of CabFile.pas, holding the ECabError root +
  ECabNotSupportedOnPlatform leaf. Split from CabFile.pas per v4.1 Wave 3a
  refactor (separation of concerns: implementation classes in CabFile.pas,
  exceptions here, types in CabFile.Types.pas, interfaces in
  CabFile.Interfaces.pas).

  Características:
  - 2 exception classes (ECabError base, ECabNotSupportedOnPlatform leaf)
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
unit CabFile.Exceptions;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils;

type
  ECabError = class(Exception);
  ECabNotSupportedOnPlatform = class(ECabError);

implementation

end.
