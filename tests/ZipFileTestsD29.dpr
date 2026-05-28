{ ZipFileTestsD29.dpr
  DUnitX console runner para a testsuite ZipFile/.
  Executavel: ZipFileTestsD29.exe (Delphi 12 Athens / D29).
  Carrega todas as fixtures via initialization sections.
}
program ZipFileTestsD29;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ENDIF }
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  ZipFile.Tests.Shared in 'ZipFile.Tests.Shared.pas',
  ZipFile.Tests.Core in 'ZipFile.Tests.Core.pas',
  ZipFile.Tests.UTF8 in 'ZipFile.Tests.UTF8.pas',
  ZipFile.Tests.AES in 'ZipFile.Tests.AES.pas',
  ZipFile.Tests.Progress in 'ZipFile.Tests.Progress.pas',
  ZipFile.Tests.Streaming in 'ZipFile.Tests.Streaming.pas',
  ZipFile.Tests.Zip64 in 'ZipFile.Tests.Zip64.pas',
  ZipFile.Tests.Fluent in 'ZipFile.Tests.Fluent.pas',
  ZipFile.Tests.LZMA in 'ZipFile.Tests.LZMA.pas',
  ZipFile.Tests.Zip64Write in 'ZipFile.Tests.Zip64Write.pas',
  ZipFile.Tests.FluentInline in 'ZipFile.Tests.FluentInline.pas',
  ZipFile.Tests.Tar in 'ZipFile.Tests.Tar.pas';

var
  Runner: ITestRunner;
  Results: IRunResults;
  Logger: ITestLogger;
  NUnit: ITestLogger;
  ExitCode: Integer;
begin
  try
    TDUnitX.CheckCommandLine;
    Runner := TDUnitX.CreateRunner;
    Runner.UseRTTI := True;
    Runner.FailsOnNoAsserts := False;

    Logger := TDUnitXConsoleLogger.Create(True);
    Runner.AddLogger(Logger);
    NUnit := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    Runner.AddLogger(NUnit);

    Results := Runner.Execute;

    if Results.AllPassed then
      ExitCode := 0
    else
      ExitCode := 1;

    {$IFNDEF CI}
    if not Results.AllPassed then
    begin
      Write('Done — press Enter to exit.');
      ReadLn;
    end;
    {$ENDIF}

    System.ExitCode := ExitCode;
  except
    on E: Exception do
    begin
      WriteLn('Test runner exception: ', E.ClassName, ' / ', E.Message);
      System.ExitCode := 2;
    end;
  end;
end.
