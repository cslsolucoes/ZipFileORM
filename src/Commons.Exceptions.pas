{*
 * Commons.Exceptions.pas
 *
 * Hierarquia base de exceptions do ZipFileORM:
 *   EArchive (base)
 *     ├─ EArchiveNotFound
 *     ├─ EArchiveInvalidFormat
 *     ├─ EArchiveCorrupt
 *     ├─ EArchiveAlreadyOpen
 *     ├─ EArchiveNotOpen
 *     ├─ EArchivePasswordRequired
 *     ├─ EArchivePasswordIncorrect
 *     ├─ EArchiveWriteNotSupported
 *     └─ EArchivePlatformNotSupported
 *
 * Cada módulo herda suas exceptions específicas (EZipFile, ETarFile, etc.)
 * a partir de EArchive.
 *
 * ZipFileORM v4.0.0 (c) 2026 CSL Softwares
 * Licença: LGPL-3.0
 *}

unit Commons.Exceptions;

{$I Commons.FPC.inc}

interface

uses
  SysUtils;

type
  // Exception base — todos os erros do ZipFileORM herdam daqui
  EArchive = class(Exception);

  // Erros de acesso a archive
  EArchiveNotFound          = class(EArchive);
  EArchiveInvalidFormat     = class(EArchive);
  EArchiveCorrupt           = class(EArchive);
  EArchiveAlreadyOpen       = class(EArchive);
  EArchiveNotOpen           = class(EArchive);

  // Erros de criptografia
  EArchiveEncryption        = class(EArchive);
  EArchivePasswordRequired  = class(EArchiveEncryption);
  EArchivePasswordIncorrect = class(EArchiveEncryption);

  // Erros de operação
  EArchiveWriteNotSupported   = class(EArchive);
  EArchivePlatformNotSupported = class(EArchive);
  EArchiveEntryNotFound        = class(EArchive);

implementation

end.
