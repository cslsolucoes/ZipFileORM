program smoke_fluent_compile;
{$APPTYPE CONSOLE}
uses
  System.SysUtils, System.Classes,
  Cab.Fluent      in '..\src\Cab.Fluent.pas',
  SevenZ.Fluent   in '..\src\SevenZ.Fluent.pas',
  Tar.Fluent      in '..\src\Tar.Fluent.pas',
  Bzip2.Fluent    in '..\src\Bzip2.Fluent.pas',
  ZCompress.Fluent in '..\src\ZCompress.Fluent.pas',
  UUE.Fluent      in '..\src\UUE.Fluent.pas';
begin
  WriteLn('Fluent units compile OK');
end.
