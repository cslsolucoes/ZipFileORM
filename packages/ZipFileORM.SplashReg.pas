(* ZipFileORM.SplashReg.pas

   Registra ZipFileORM na splash screen do RAD Studio e na pagina "Plugins"
   do dialogo Help → About. Usa as variaveis globais SplashScreenServices e
   BorlandIDEServices da unit ToolsAPI (pacote `designide`, ja em requires).

   CRITICAL (doc ToolsAPI):
     "IOTASplashScreenServices is the first service available during product
      startup, which is why it is available as a separate specific global
      variable. When this interface is created, the BorlandIDEServices
      interface is unavailable since it has yet to be initialized."

   Portanto a chamada de splash usa a global `SplashScreenServices` direto —
   nao via Supports(BorlandIDEServices, ...). Para o About box (que roda
   depois de o IDE inicializar BorlandIDEServices) o caminho usual eh ok.

   Bitmap 24x24 com pixel TRANSPARENTE no LOWER-LEFT (canto inferior esquerdo,
   coordenada (0, 23)) — convencao do splash conforme doc IOTA. *)
unit ZipFileORM.SplashReg;

interface

implementation

uses
  Winapi.Windows,
  System.SysUtils,
  System.Types,
  Vcl.Graphics,
  ToolsAPI;

const
  cProductName    = 'ZipFileORM';
  cProductTitle   = 'ZipFileORM';
  cProductDesc    = 'Multi-format archive component family — Zip/Tar/Gzip/Cab/7z/Arj/Iso/Lha/Rar for Delphi and FPC/Lazarus.';
  cLicenseStatus  = 'Free / Open-source';
  cSKU            = '4.0.0';

var
  GSplashBmp:  TBitmap = nil;
  GAboutIdx:   Integer = 0;
  GRegistered: Boolean = False;

function MakeSplashBitmap: TBitmap;
const
  cMagenta = TColor($00FF00FF);   // BBGGRR — used as the transparent indicator
begin
  Result := TBitmap.Create;
  Result.PixelFormat := pf24bit;
  Result.SetSize(24, 24);

  // Fundo: red brand square — DPI-aware DrawString preserves crispness.
  Result.Canvas.Brush.Color := $002030C8;          // BBGGRR — red
  Result.Canvas.FillRect(Rect(0, 0, 24, 24));

  // Texto "ZIP" centralizado.
  Result.Canvas.Font.Name  := 'Tahoma';
  Result.Canvas.Font.Size  := 7;
  Result.Canvas.Font.Style := [fsBold];
  Result.Canvas.Font.Color := clWhite;
  Result.Canvas.Brush.Style := bsClear;
  Result.Canvas.TextOut(2, 6, 'ZIP');

  // LOWER-LEFT pixel = transparent color (per IOTA convention).
  Result.Canvas.Pixels[0, Result.Height - 1] := cMagenta;
end;

procedure TryRegisterSplash;
begin
  // Use a global SplashScreenServices — BorlandIDEServices ainda eh nil
  // nesse ponto da inicializacao do IDE.
  if Assigned(SplashScreenServices) then
  begin
    SplashScreenServices.AddPluginBitmap(
      cProductName,
      GSplashBmp.Handle,
      False,                  // IsUnRegistered (False = nome em texto branco/preto, nao vermelho)
      cLicenseStatus,
      cSKU);
    GRegistered := True;
  end;
end;

procedure TryRegisterAbout;
var
  LAboutSvc: IOTAAboutBoxServices;
begin
  // About box pode ser registrado mais tarde — se BorlandIDEServices ainda
  // nao estiver pronto agora, tudo bem; nao tem fallback OnIdle aqui, mas
  // na pratica designide carrega BorlandIDEServices antes de chamar
  // initialization dos design packages.
  if (BorlandIDEServices <> nil) and
     Supports(BorlandIDEServices, IOTAAboutBoxServices, LAboutSvc) then
  begin
    GAboutIdx := LAboutSvc.AddPluginInfo(
      cProductTitle,
      cProductDesc,
      GSplashBmp.Handle,
      False,
      cLicenseStatus,
      cSKU);
  end;
end;

procedure UnregisterAbout;
var
  LAboutSvc: IOTAAboutBoxServices;
begin
  if (GAboutIdx <> 0) and
     (BorlandIDEServices <> nil) and
     Supports(BorlandIDEServices, IOTAAboutBoxServices, LAboutSvc) then
  begin
    LAboutSvc.RemovePluginInfo(GAboutIdx);
    GAboutIdx := 0;
  end;
end;

initialization
  GSplashBmp := MakeSplashBitmap;
  TryRegisterSplash;
  TryRegisterAbout;

finalization
  UnregisterAbout;
  FreeAndNil(GSplashBmp);

end.
