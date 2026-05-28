{ ZipfileORM.pas

  Facade publica unica do ZipFileORM v4.0.0.

  Consumidor escreve:

    uses ZipfileORM;

  E ganha acesso a:
  - Todas as 10 classes T<Format>File (TZipFile, TTarFile, etc.) via re-export
  - TArchive class factory para auto-detect + abrir read-only
  - TArchiveFormat enum (cross-format)
  - TCompressionMethod enum (cross-format)
  - IArchive/IArchiveEntry interfaces (contrato uniforme)
  - Eventos compartilhados (TArchive*Event de ZipfileORM.Events)
  - Exceptions base (EArchive de Commons.Exceptions)

  Uso:

    // Detecta o formato e devolve dados read-only:
    var Fmt: TArchiveFormat;
    Fmt := TArchive.DetectFormat('arquivo.bin');

    // Cria componente do formato adequado:
    case Fmt of
      afZip: ...
      afTar: ...
    end;
}
unit ZipfileORM;

{$I Commons.FPC.inc}

interface

uses
  SysUtils, Classes,
  // Modulos format publicos (re-export):
  ZipFile, TarFile, TarGzFile, GzipFile, CabFile, SevenZFile,
  ArjFile, IsoFile, LhaFile, RarFile,
  // Facade contracts:
  ZipfileORM.Interfaces, ZipfileORM.Compression, ZipfileORM.Events,
  // Detection (delegate):
  Archive.Open,
  // Commons:
  Commons.Exceptions;

type
  // Re-export de TArchiveFormat para acesso direto via ZipfileORM.pas
  TArchiveFormat = Archive.Open.TArchiveFormat;

  // Re-export do erro de detecao
  EArchiveDetectError = Archive.Open.EArchiveDetectError;

  // Class factory + helpers cross-format
  TArchive = class
  public
    // Detecta formato pelo magic number
    class function DetectFormat(const AFileName: string): TArchiveFormat; overload;
    class function DetectFormat(AStream: TStream): TArchiveFormat; overload;
    class function FormatToString(AFormat: TArchiveFormat): string;

    // Cria componente do formato adequado pre-configurado.
    // Owner pode ser nil — caller assume responsabilidade pelo Free.
    class function CreateZip(AOwner: TComponent; const AFileName: string): TZipFile;
    class function CreateTar(AOwner: TComponent; const AFileName: string): TTarFile;
    class function CreateTarGz(AOwner: TComponent; const AFileName: string): TTarGzFile;
    class function CreateGzip(AOwner: TComponent; const AFileName: string): TGzipFile;
    class function CreateCab(AOwner: TComponent; const AFileName: string): TCabFile;
    class function CreateSevenZ(AOwner: TComponent; const AFileName: string): TSevenZFile;
    class function CreateArj(AOwner: TComponent; const AFileName: string): TArjFile;
    class function CreateIso(AOwner: TComponent; const AFileName: string): TIsoFile;
    class function CreateLha(AOwner: TComponent; const AFileName: string): TLhaFile;
    class function CreateRar(AOwner: TComponent; const AFileName: string): TRarFile;
  end;

  // Re-exports adicionais para uses-clause-clean consumers
  TCompressionMethod    = ZipfileORM.Compression.TCompressionMethod;
  TCompressionMethodSet = ZipfileORM.Compression.TCompressionMethodSet;

const
  ZipfileORM_VERSION = '4.0.0';
  ZipfileORM_BUILD_DATE = '2026-05-28';

implementation

class function TArchive.DetectFormat(const AFileName: string): TArchiveFormat;
begin
  Result := Archive.Open.DetectArchiveFormat(AFileName);
end;

class function TArchive.DetectFormat(AStream: TStream): TArchiveFormat;
begin
  Result := Archive.Open.DetectArchiveFormat(AStream);
end;

class function TArchive.FormatToString(AFormat: TArchiveFormat): string;
begin
  Result := Archive.Open.ArchiveFormatToString(AFormat);
end;

class function TArchive.CreateZip(AOwner: TComponent; const AFileName: string): TZipFile;
begin
  Result := TZipFile.Create(AOwner);
  Result.FileName := AFileName;
end;

class function TArchive.CreateTar(AOwner: TComponent; const AFileName: string): TTarFile;
begin
  Result := TTarFile.Create(AOwner);
  Result.FileName := AFileName;
end;

class function TArchive.CreateTarGz(AOwner: TComponent; const AFileName: string): TTarGzFile;
begin
  Result := TTarGzFile.Create(AOwner);
  Result.FileName := AFileName;
end;

class function TArchive.CreateGzip(AOwner: TComponent; const AFileName: string): TGzipFile;
begin
  Result := TGzipFile.Create(AOwner);
  Result.FileName := AFileName;
end;

class function TArchive.CreateCab(AOwner: TComponent; const AFileName: string): TCabFile;
begin
  Result := TCabFile.Create(AOwner);
  Result.FileName := AFileName;
end;

class function TArchive.CreateSevenZ(AOwner: TComponent; const AFileName: string): TSevenZFile;
begin
  Result := TSevenZFile.Create(AOwner);
  Result.FileName := AFileName;
end;

class function TArchive.CreateArj(AOwner: TComponent; const AFileName: string): TArjFile;
begin
  Result := TArjFile.Create(AOwner);
  Result.FileName := AFileName;
end;

class function TArchive.CreateIso(AOwner: TComponent; const AFileName: string): TIsoFile;
begin
  Result := TIsoFile.Create(AOwner);
  Result.FileName := AFileName;
end;

class function TArchive.CreateLha(AOwner: TComponent; const AFileName: string): TLhaFile;
begin
  Result := TLhaFile.Create(AOwner);
  Result.FileName := AFileName;
end;

class function TArchive.CreateRar(AOwner: TComponent; const AFileName: string): TRarFile;
begin
  Result := TRarFile.Create(AOwner);
  Result.FileName := AFileName;
end;

end.
