{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.

  Refactored for ZipFileORM v4.0.0 - new namespaces (Commons.*, ZipFileORM.*).
}

unit ZipFilePkg;

{$warn 5023 off : no warning about unused units}
interface

uses
  // Commons cross-format
  Commons.Consts, Commons.Types, Commons.Exceptions, Commons.Progress,
  Commons.Compression.Consts, Commons.Compression.Base,
  Commons.Compression.None, Commons.Compression.ZLib,
  Commons.Compression.LZMA, Commons.Encryption.AES,
  // ZipFileORM facade
  ZipfileORM, ZipfileORM.Interfaces, ZipfileORM.Compression, ZipfileORM.Events,
  // Archive auto-detect
  Archive.Open,
  // ZIP module + sub-modules ZIP-only
  ZipFile, ZipFile.UTF8, ZipFile.ZIP64, ZipFile.Streaming, ZipFile.Fluent,
  // Other format modules
  TarFile, TarFile.GzipStream, Tar.Fluent,
  TarGzFile, GzipFile,
  CabFile, Cab.Fluent,
  SevenZFile, SevenZ.Fluent,
  ArjFile, IsoFile, LhaFile, RarFile,
  // Helper streams
  Bzip2.Stream, Bzip2.Fluent,
  UUE.Stream, UUE.Fluent,
  ZCompress.LzwStream, ZCompress.Fluent,
  // Lazarus integration
  LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('ZipFile', @ZipFile.Register);
end;

initialization
  RegisterPackage('ZipFilePkg', @Register);
end.
