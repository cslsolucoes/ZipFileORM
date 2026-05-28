{ ZipFile.Tests.Shared.pas
  Helpers compartilhados pelos fixtures DUnitX (paths temp, criacao de
  streams de teste, comparacao binaria).
}
unit ZipFile.Tests.Shared;

interface

uses
  System.SysUtils, System.Classes;

type
  TZipTestHelpers = class
  public
    class function MakeTempPath(const ASuffix: string): string;
    class function MakeAnsiStream(const APlain: AnsiString): TMemoryStream;
    class function StreamToAnsi(AStream: TStream): AnsiString;
    class procedure DeleteIfExists(const APath: string);
  end;

implementation

uses
  Winapi.Windows;

function GetTempPathSafe: string;
begin
  Result := GetEnvironmentVariable('TEMP');
  if Result = '' then
    Result := GetEnvironmentVariable('TMP');
  if Result = '' then
    Result := '.';
end;

class function TZipTestHelpers.MakeTempPath(const ASuffix: string): string;
var
  TempDir, Base: string;
  Counter: Cardinal;
begin
  TempDir := IncludeTrailingPathDelimiter(GetTempPathSafe);
  Counter := GetTickCount;
  repeat
    Base := Format('zf_test_%x_%s', [Counter, ASuffix]);
    Result := TempDir + Base;
    Inc(Counter);
  until not FileExists(Result);
end;

class function TZipTestHelpers.MakeAnsiStream(const APlain: AnsiString): TMemoryStream;
begin
  Result := TMemoryStream.Create;
  if Length(APlain) > 0 then
    Result.WriteBuffer(APlain[1], Length(APlain));
  Result.Position := 0;
end;

class function TZipTestHelpers.StreamToAnsi(AStream: TStream): AnsiString;
begin
  SetLength(Result, AStream.Size);
  if AStream.Size > 0 then
  begin
    AStream.Position := 0;
    AStream.ReadBuffer(Result[1], AStream.Size);
  end;
end;

class procedure TZipTestHelpers.DeleteIfExists(const APath: string);
begin
  if FileExists(APath) then
    System.SysUtils.DeleteFile(APath);
end;

end.
