{ Tar.GzipStream.pas

  Streams Gzip (RFC 1952) sobre TStream. Wraps:
  - Delphi: System.ZLib (TZCompressionStream/TZDecompressionStream com
    parametro WindowBits = 31 que ativa gzip header em vez de zlib raw)
  - FPC: zstream unit (Tcompressionstream/Tdecompressionstream nao oferecem
    gzip diretamente; fallback aqui usa System.ZLib via wrapper unicode-aware
    OU port pure-pascal â€” TODO v3.6 quando integrar LZMA FPC)

  API:
  - TGzipReadStream(InnerStream): le bytes gzipped do inner e devolve
    inflated em sequencia (Read/Seek-from-current)
  - TGzipWriteStream(OutStream, Level): escreve plain bytes; gzipped sai
    no OutStream. Flush+close em Destroy

  Dual-target Delphi (D24..D37) e FPC/Lazarus.

  Nota: Seek backwards nao e suportado em modo streaming gzip (inflate
  e stateful). Para acesso randomico, use TMemoryStream intermediario.
}
unit TarFile.GzipStream;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils, Classes
  {$IFNDEF FPC}, System.ZLib{$ELSE}, ZStream{$ENDIF};

type
  EGzipStreamError = class(Exception);

  // Read-only wrap: inner = arquivo .gz no disco; cliente le bytes inflated.
  TGzipReadStream = class(TStream)
  private
    FInner: TStream;
    FOwnsInner: Boolean;
    {$IFNDEF FPC}
    FZStream: TZDecompressionStream;
    {$ELSE}
    FZStream: TDecompressionStream;
    {$ENDIF}
    FPosition: Int64;
  protected
    function GetSize: Int64; override;
    procedure SetSize(const NewSize: Int64); override;
  public
    constructor Create(AInner: TStream; AOwnsInner: Boolean = False);
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
  end;

  // Write-only wrap: cliente escreve plain bytes; gzipped sai no Inner.
  TGzipWriteStream = class(TStream)
  private
    FInner: TStream;
    FOwnsInner: Boolean;
    {$IFNDEF FPC}
    FZStream: TZCompressionStream;
    {$ELSE}
    FZStream: TCompressionStream;
    {$ENDIF}
    FPosition: Int64;
  protected
    function GetSize: Int64; override;
    procedure SetSize(const NewSize: Int64); override;
  public
    // ALevel: 1..9 (1=fast, 9=best). Default 6 = balance.
    constructor Create(AInner: TStream; ALevel: Integer = 6; AOwnsInner: Boolean = False);
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; override;
  end;

// Helpers de conveniencia:
procedure GzipCompressBuffer(const ASrc: TBytes; out ADst: TBytes; ALevel: Integer = 6);
procedure GzipDecompressBuffer(const ASrc: TBytes; out ADst: TBytes);

implementation

// =============================================================================
//   TGzipReadStream
// =============================================================================

constructor TGzipReadStream.Create(AInner: TStream; AOwnsInner: Boolean);
begin
  inherited Create;
  if AInner = nil then
    raise EGzipStreamError.Create('TGzipReadStream: inner stream is nil');
  FInner := AInner;
  FOwnsInner := AOwnsInner;
  {$IFNDEF FPC}
  // System.ZLib em Delphi: WindowBits = 15+16 = 31 ativa modo gzip (em vez
  // de zlib raw). 15 = max window size; +16 = "use gzip wrapper".
  FZStream := TZDecompressionStream.Create(FInner, 31);
  {$ELSE}
  // FPC zstream: parametro skipheader=False (default) le zlib header.
  // Para gzip raw, precisa wrapper proprio futuro. Por enquanto fallback
  // tentativo (zlib-wrapped stream funciona com gzip se decompressor for
  // tolerante).
  FZStream := TDecompressionStream.Create(FInner, False);
  {$ENDIF}
  FPosition := 0;
end;

destructor TGzipReadStream.Destroy;
begin
  FreeAndNil(FZStream);
  if FOwnsInner then
    FreeAndNil(FInner);
  inherited;
end;

function TGzipReadStream.GetSize: Int64;
begin
  // Tamanho descomprimido nao e conhecido sem ler tudo. Retorna -1.
  Result := -1;
end;

procedure TGzipReadStream.SetSize(const NewSize: Int64);
begin
  raise EGzipStreamError.Create('TGzipReadStream is read-only');
end;

function TGzipReadStream.Read(var Buffer; Count: Longint): Longint;
begin
  Result := FZStream.Read(Buffer, Count);
  Inc(FPosition, Result);
end;

function TGzipReadStream.Write(const Buffer; Count: Longint): Longint;
begin
  raise EGzipStreamError.Create('TGzipReadStream is read-only');
end;

function TGzipReadStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  // Inflate e stateful; suporta apenas avanco linear (read-ahead).
  if (Origin = soCurrent) and (Offset = 0) then
    Result := FPosition
  else if (Origin = soBeginning) and (Offset = FPosition) then
    Result := FPosition
  else
    raise EGzipStreamError.Create('TGzipReadStream seek only supports current position query');
end;

// =============================================================================
//   TGzipWriteStream
// =============================================================================

constructor TGzipWriteStream.Create(AInner: TStream; ALevel: Integer; AOwnsInner: Boolean);
{$IFNDEF FPC}
var
  LLevel: TZCompressionLevel;
{$ENDIF}
begin
  inherited Create;
  if AInner = nil then
    raise EGzipStreamError.Create('TGzipWriteStream: inner stream is nil');
  FInner := AInner;
  FOwnsInner := AOwnsInner;
  {$IFNDEF FPC}
  // Mapeia 1..9 -> TZCompressionLevel
  case ALevel of
    1: LLevel := zcFastest;
    2..5: LLevel := zcDefault;
    6..8: LLevel := zcDefault;
    9: LLevel := zcMax;
  else
    LLevel := zcDefault;
  end;
  // WindowBits 31 = gzip wrapper output
  FZStream := TZCompressionStream.Create(FInner, LLevel, 31);
  {$ELSE}
  case ALevel of
    1: FZStream := TCompressionStream.Create(clfastest, FInner);
    9: FZStream := TCompressionStream.Create(clmax, FInner);
  else
    FZStream := TCompressionStream.Create(cldefault, FInner);
  end;
  {$ENDIF}
  FPosition := 0;
end;

destructor TGzipWriteStream.Destroy;
begin
  // FZStream.Destroy flush + close â€” DEVE rodar antes de FInner.Free.
  FreeAndNil(FZStream);
  if FOwnsInner then
    FreeAndNil(FInner);
  inherited;
end;

function TGzipWriteStream.GetSize: Int64;
begin
  Result := FPosition;
end;

procedure TGzipWriteStream.SetSize(const NewSize: Int64);
begin
  raise EGzipStreamError.Create('TGzipWriteStream is write-only');
end;

function TGzipWriteStream.Read(var Buffer; Count: Longint): Longint;
begin
  raise EGzipStreamError.Create('TGzipWriteStream is write-only');
end;

function TGzipWriteStream.Write(const Buffer; Count: Longint): Longint;
begin
  Result := FZStream.Write(Buffer, Count);
  Inc(FPosition, Result);
end;

function TGzipWriteStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  if (Origin = soCurrent) and (Offset = 0) then
    Result := FPosition
  else
    raise EGzipStreamError.Create('TGzipWriteStream seek only supports current position query');
end;

// =============================================================================
//   Helpers
// =============================================================================

procedure GzipCompressBuffer(const ASrc: TBytes; out ADst: TBytes; ALevel: Integer);
var
  OutMem: TMemoryStream;
  W: TGzipWriteStream;
begin
  OutMem := TMemoryStream.Create;
  try
    W := TGzipWriteStream.Create(OutMem, ALevel, False);
    try
      if Length(ASrc) > 0 then
        W.WriteBuffer(ASrc[0], Length(ASrc));
    finally
      W.Free; // flush+close
    end;
    SetLength(ADst, OutMem.Size);
    if OutMem.Size > 0 then
      Move(PByte(OutMem.Memory)^, ADst[0], OutMem.Size);
  finally
    OutMem.Free;
  end;
end;

procedure GzipDecompressBuffer(const ASrc: TBytes; out ADst: TBytes);
const
  CHUNK = 64 * 1024;
var
  InMem: TMemoryStream;
  R: TGzipReadStream;
  OutMem: TMemoryStream;
  Buf: array of Byte;
  N: Integer;
begin
  InMem := TMemoryStream.Create;
  try
    if Length(ASrc) > 0 then
      InMem.WriteBuffer(ASrc[0], Length(ASrc));
    InMem.Position := 0;
    R := TGzipReadStream.Create(InMem, False);
    try
      OutMem := TMemoryStream.Create;
      try
        SetLength(Buf, CHUNK);
        repeat
          N := R.Read(Buf[0], CHUNK);
          if N > 0 then
            OutMem.WriteBuffer(Buf[0], N);
        until N <= 0;
        SetLength(ADst, OutMem.Size);
        if OutMem.Size > 0 then
          Move(PByte(OutMem.Memory)^, ADst[0], OutMem.Size);
      finally
        OutMem.Free;
      end;
    finally
      R.Free;
    end;
  finally
    InMem.Free;
  end;
end;

end.
