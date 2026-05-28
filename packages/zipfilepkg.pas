{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit ZipFilePkg;

{$warn 5023 off : no warning about unused units}
interface

uses
  ZipFile, ZipFile.UTF8, ZipFile.ZIP64, ZipFile.Progress, 
  ZipFile.Encryption.AES, ZipFile.Streaming, ZipFile.Fluent, 
  ZipFile.Compression.LZMA, Tar.GzipStream, TarFile, TarGzFile, 
  Archive.Open, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('ZipFile', @ZipFile.Register);
end;

initialization
  RegisterPackage('ZipFilePkg', @Register);
end.
