(* ZipFileORM.LibraryPathReg.pas

   Unit design-time que adiciona os Library Paths do projeto ao IDE no
   momento em que a dcl*.bpl eh carregada (instalada via Component >
   Install Packages OU re-carregada no startup do IDE).

   Como funciona:
   1. initialization chama RegisterZipFileORMPaths.
   2. RegisterZipFileORMPaths le a chave base do IDE atual via ToolsAPI
      (IOTAServices.GetBaseRegistryKey -> e.g. 'Software\Embarcadero\BDS\23.0').
   3. Mapeia a versao do compilador (VER<XXX>) para a pasta RAD<xx>
      correspondente.
   4. Adiciona 2 paths (<root>\src e <root>\Lib\RAD<xx>\<Plat>) a 3 chaves
      (Search Path, LibraryPath, Browsing Path) em ambas as plataformas
      (Win32 e Win64), de forma idempotente.

   O root do projeto vem de ZipFileORM.ProjectRoot.inc (gerado em build-time
   pelo Build-AllDelphis.ps1).

   Mudancas no registro tomam efeito quando o IDE for re-aberto. Para
   refresh imediato em-memoria, o usuario pode fechar e reabrir o IDE
   apos instalar a package.

   Seguranca: TODO o codigo esta envelopado em try/except. Falhas nao
   propagam para o IDE - se a unidade nao conseguir ler a chave base ou
   o include nao estiver disponivel, simplesmente nao faz nada.
*)
unit ZipFileORM.LibraryPathReg;

interface

implementation

uses
  Winapi.Windows,
  System.SysUtils,
  System.Win.Registry,
  ToolsAPI;

{$I ZipFileORM.ProjectRoot.inc}

// Map compiler version to RAD folder name used by the build outputs.
{$IFDEF VER310}    const cRadFolder = 'RAD10.1';   {$ENDIF}   // D24 = 10.1 Berlin
{$IFDEF VER320}    const cRadFolder = 'RAD10.2';   {$ENDIF}   // D25 = 10.2 Tokyo
{$IFDEF VER330}    const cRadFolder = 'RAD10.3';   {$ENDIF}   // D26 = 10.3 Rio
{$IFDEF VER340}    const cRadFolder = 'RAD10.4';   {$ENDIF}   // D27 = 10.4 Sydney
{$IFDEF VER350}    const cRadFolder = 'RAD11';     {$ENDIF}   // D28 = 11 Alexandria
{$IFDEF VER360}    const cRadFolder = 'RAD12';     {$ENDIF}   // D29 = 12 Athens
{$IFDEF VER370}    const cRadFolder = 'RAD13';     {$ENDIF}   // D37 = 13 Florence

function AppendBackslash(const APath: string): string;
begin
  if (APath = '') or APath.EndsWith('\') then
    Result := APath
  else
    Result := APath + '\';
end;

// Add APath to ARegKey\AValueName (REG_SZ; semicolon-separated). Idempotent.
procedure AddPathToRegValue(const ARegKey, AValueName, APath: string);
var
  Reg: TRegistry;
  Current, Token: string;
  Tokens: TArray<string>;
  Exists: Boolean;
  I: Integer;
begin
  Reg := TRegistry.Create(KEY_READ or KEY_WRITE);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if not Reg.OpenKey(ARegKey, True) then Exit;
    try
      if Reg.ValueExists(AValueName) then
        Current := Reg.ReadString(AValueName)
      else
        Current := '';

      // Case-insensitive substring check by tokens.
      Tokens := Current.Split([';']);
      Exists := False;
      for I := 0 to High(Tokens) do
      begin
        Token := Tokens[I].Trim;
        if SameText(Token, APath) then
        begin
          Exists := True;
          Break;
        end;
      end;
      if Exists then Exit;

      // Append.
      if (Current <> '') and not Current.EndsWith(';') then
        Current := Current + ';';
      Current := Current + APath;
      Reg.WriteString(AValueName, Current);
    finally
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;

procedure AddPathsForPlatform(const ABaseLibKey, APlat, ASrcPath, ALibPath: string);
const
  cValueNames: array[0..2] of string = ('Search Path', 'LibraryPath', 'Browsing Path');
var
  PlatKey: string;
  I: Integer;
begin
  PlatKey := ABaseLibKey + '\' + APlat;
  for I := Low(cValueNames) to High(cValueNames) do
  begin
    AddPathToRegValue(PlatKey, cValueNames[I], ASrcPath);
    AddPathToRegValue(PlatKey, cValueNames[I], ALibPath);
  end;
end;

procedure RegisterZipFileORMPaths;
var
  Svc: IOTAServices;
  BaseKey, LibKey: string;
  Root, SrcPath, LibW32, LibW64: string;
begin
  // 1. Read IDE base registry key via ToolsAPI.
  if not Supports(BorlandIDEServices, IOTAServices, Svc) or (Svc = nil) then Exit;
  BaseKey := Svc.GetBaseRegistryKey;   // e.g. 'Software\Embarcadero\BDS\23.0'
  if BaseKey = '' then Exit;

  // 2. Compose paths from the compile-time project root + RAD folder.
  Root := AppendBackslash(cZipFileORMProjectRoot);
  if (Root = '') or (cRadFolder = '') then Exit;

  SrcPath := Root + 'src';
  LibW32 := Root + 'Lib\' + cRadFolder + '\Win32';
  LibW64 := Root + 'Lib\' + cRadFolder + '\Win64';

  // 3. Write to registry. Library key holds platform sub-keys.
  LibKey := BaseKey + '\Library';

  AddPathsForPlatform(LibKey, 'Win32', SrcPath, LibW32);
  AddPathsForPlatform(LibKey, 'Win64', SrcPath, LibW64);
end;

initialization
  try
    RegisterZipFileORMPaths;
  except
    // Never break IDE startup. Errors during registration are silently
    // suppressed - user can fall back to tools/Install-LibraryPaths.ps1.
  end;

end.
