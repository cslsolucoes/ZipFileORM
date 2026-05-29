program smoke_fluent_compile;
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  CabFile                          in '..\src\CabFile.pas',
  CabFile.Interfaces               in '..\src\CabFile.Interfaces.pas',
  SevenZFile                       in '..\src\SevenZFile.pas',
  SevenZFile.Interfaces            in '..\src\SevenZFile.Interfaces.pas',
  TarFile                          in '..\src\TarFile.pas',
  TarFile.Interfaces               in '..\src\TarFile.Interfaces.pas',
  Bzip2.Stream                     in '..\src\Bzip2.Stream.pas',
  Bzip2.Stream.Interfaces          in '..\src\Bzip2.Stream.Interfaces.pas',
  ZCompress.LzwStream              in '..\src\ZCompress.LzwStream.pas',
  ZCompress.LzwStream.Interfaces   in '..\src\ZCompress.LzwStream.Interfaces.pas',
  UUE.Stream                       in '..\src\UUE.Stream.pas',
  UUE.Stream.Interfaces            in '..\src\UUE.Stream.Interfaces.pas';
begin
  WriteLn('Fluent (dissolved) units compile OK');
end.
