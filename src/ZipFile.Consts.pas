{ =============================================================================
  ZipFile.Consts - Public string resources of the ZIP module

  Descrição:
  Companion resourcestrings unit of ZipFile.pas. Split from ZipFile.pas
  per v4.1 Wave 3a refactor — resourcestring identifiers are visible to
  any unit that has ZipFile.Consts in its uses chain, so transitive
  re-export works automatically via ZipFile.pas's `uses ZipFile.Consts`.

  Características:
  - 2 user-facing message templates (file-not-found errors)
  - Localizable: rebuild with translated resource section to localize messages
  - Cross-platform: Delphi (D24..D37 Win32+Win64) + FPC/Lazarus

  Project:        ZipFileORM
  ProjectVersion: 4.0.0
  FileVersion:    1.0.0
  Author:         CSL Softwares
  Date:           28/05/2026

  Changelog (file):
  - 1.0.0 (28/05/2026): created — split from ZipFile.pas (Wave 3a).
  ============================================================================= }
unit ZipFile.Consts;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

resourcestring
  rsFilenameSDoesNotExistInS = 'Filename %s does not exist in %s';
  rsZipFileSDoesNotExist = 'ZipFile %s does not exist';

implementation

end.
