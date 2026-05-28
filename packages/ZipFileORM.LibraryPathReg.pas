(* ZipFileORM.LibraryPathReg.pas

   Unit design-time que adiciona os Library Paths do projeto ao IDE no
   momento em que a dcl*.bpl eh carregada (instalada via Component >
   Install Packages OU re-carregada no startup do IDE).

   Sem hardcoded:
   O root do projeto e DESCOBERTO em runtime a partir do caminho da
   propria BPL via GetModuleFileName(HInstance). Assume que a BPL esta
   em <root>\Lib\RAD<xx>\Win<plat>\dclZipFileORMD<XX>.bpl - sobe 4
   niveis para encontrar <root>, depois valida que <root>\src existe.

   Se a estrutura nao for reconhecida (ex.: BPL instalada de %BDSCOMMONDIR%
   ou outro lugar), a unit nao faz nada (silently). O usuario pode rodar
   tools\Install-LibraryPaths.ps1 manualmente como fallback.

   Como funciona:
   1. initialization chama RegisterZipFileORMPaths.
   2. GetModuleFileName(HInstance) -> caminho absoluto da BPL atual.
   3. Strip: <BPL>.bpl -> <Win32|Win64> -> <RAD<xx>> -> <Lib> -> <root>
   4. Se <root>\src nao existir, aborta.
   5. Le IOTAServices.GetBaseRegistryKey para chave do IDE atual.
   6. Mapeia VER<XXX> compile-time -> sufixo da plataforma.
   7. Adiciona 2 paths (<root>\src e <root>\Lib\RAD<xx>\<Plat>) a 3
      chaves (Search Path, LibraryPath, Browsing Path) em ambas
      plataformas, idempotente.

   Seguranca: try/except global - falhas nao quebram o IDE.
*)
unit ZipFileORM.LibraryPathReg;

interface

implementation

{$IFNDEF FPC}

uses
  Winapi.Windows,
  System.SysUtils,
  System.IOUtils,
  System.Win.Registry,
  ToolsAPI;

// Map compiler version to RAD folder name used by the build outputs.
{$IFDEF VER310}    const cRadFolder = 'RAD10.1';   {$ENDIF}   // D24 = 10.1 Berlin
{$IFDEF VER320}    const cRadFolder = 'RAD10.2';   {$ENDIF}   // D25 = 10.2 Tokyo
{$IFDEF VER330}    const cRadFolder = 'RAD10.3';   {$ENDIF}   // D26 = 10.3 Rio
{$IFDEF VER340}    const cRadFolder = 'RAD10.4';   {$ENDIF}   // D27 = 10.4 Sydney
{$IFDEF VER350}    const cRadFolder = 'RAD11';     {$ENDIF}   // D28 = 11 Alexandria
{$IFDEF VER360}    const cRadFolder = 'RAD12';     {$ENDIF}   // D29 = 12 Athens
{$IFDEF VER370}    const cRadFolder = 'RAD13';     {$ENDIF}   // D37 = 13 Florence

function GetThisBplPath: string;
var
  Buf: array[0..MAX_PATH] of Char;
  Len: DWORD;
begin
  Len := GetModuleFileName(HInstance, Buf, MAX_PATH);
  if Len = 0 then
    Result := ''
  else
    Result := string(Buf);
end;

// Discover project root by walking up from the BPL location:
//   <root>\Lib\RAD<xx>\Win<plat>\dclZipFileORMD<XX>.bpl
// Strip 4 levels: file -> Win<plat> -> RAD<xx> -> Lib -> <root>
function DiscoverProjectRoot: string;
var
  P: string;
begin
  Result := '';
  P := GetThisBplPath;
  if P = '' then Exit;
  // Strip filename
  P := TPath.GetDirectoryName(P);                  // <root>\Lib\RAD<xx>\Win<plat>
  if P = '' then Exit;
  P := TPath.GetDirectoryName(P);                  // <root>\Lib\RAD<xx>
  if P = '' then Exit;
  P := TPath.GetDirectoryName(P);                  // <root>\Lib
  if P = '' then Exit;
  P := TPath.GetDirectoryName(P);                  // <root>
  if P = '' then Exit;
  // Validate: <root>\src must exist (marker that this is a ZipFileORM project)
  if DirectoryExists(P + '\src') then
    Result := P;
end;

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
  // 1. Discover project root from BPL location at runtime.
  Root := DiscoverProjectRoot;
  if Root = '' then Exit;   // BPL not in expected <root>\Lib\RAD<xx>\Win<plat>\ tree

  // 2. Read IDE base registry key via ToolsAPI.
  if not Supports(BorlandIDEServices, IOTAServices, Svc) or (Svc = nil) then Exit;
  BaseKey := Svc.GetBaseRegistryKey;   // e.g. 'Software\Embarcadero\BDS\23.0'
  if BaseKey = '' then Exit;

  // 3. Compose paths.
  Root := AppendBackslash(Root);
  SrcPath := Root + 'src';
  LibW32 := Root + 'Lib\' + cRadFolder + '\Win32';
  LibW64 := Root + 'Lib\' + cRadFolder + '\Win64';

  // 4. Write to registry. Library key holds platform sub-keys.
  LibKey := BaseKey + '\Library';

  AddPathsForPlatform(LibKey, 'Win32', SrcPath, LibW32);
  AddPathsForPlatform(LibKey, 'Win64', SrcPath, LibW64);
end;

initialization
  try
    RegisterZipFileORMPaths;
  except
    // Never break IDE startup.
  end;

{$ENDIF} // not FPC

end.
