{*
 * Commons.Types.pas
 *
 * Tipos compartilhados por todos os módulos do ZipFileORM:
 * - TArchiveSearchRec: registro tipo TSearchRec para entradas de archive
 * - TArchiveProgressInfo: dados de progresso de leitura/escrita
 * - TArchiveFormat: enum global de formatos suportados
 *
 * Esqueleto inicial — populado conforme cada módulo é refatorado (Onda 2).
 *
 * ZipFileORM v4.0.0 (c) 2026 CSL Softwares
 * Licença: LGPL-3.0
 *}

unit Commons.Types;

{$I Commons.FPC.inc}

interface

uses
  Classes, SysUtils;

type
  // Capacidades de cada formato (read-only vs read+write)
  // NOTA: TArchiveFormat (enum dos 10 formatos) vive em Archive.Open.pas — fonte canonica.
  TArchiveCapability = (acRead, acWrite, acEncrypt, acSplitVolume, acSolidArchive);
  TArchiveCapabilities = set of TArchiveCapability;

  // Registro de uma entrada (file/directory) dentro do archive
  TArchiveSearchRec = record
    Name           : string;
    DateTime       : TDateTime;
    UncompressedSize : Int64;
    CompressedSize : Int64;
    IsDirectory    : Boolean;
    IsEncrypted    : Boolean;
    Comment        : string;
  end;

  // Informação de progresso para callbacks
  TArchiveProgressInfo = record
    CurrentEntry      : string;
    EntryIndex        : Integer;
    TotalEntries      : Integer;
    BytesProcessed    : Int64;
    TotalBytes        : Int64;
    PercentComplete   : Double;
  end;

implementation

end.
