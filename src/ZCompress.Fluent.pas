{ ZCompress.Fluent.pas
  Fluent builder API sobre Z LZW stream codec (ZCompress.LzwStream).

  Uso:

      var Comp := ZCompress.Compress(plain).WithMaxBits(16).ToBytes;
      var Plain := ZCompress.Decompress(comp).ToBytes;
}
unit ZCompress.Fluent;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils, Classes, ZCompress.LzwStream;

type
  TZCompressDirection = (zcdCompress, zcdDecompress);

  IZCompressBuilder = interface
    ['{E3B947C2-8D14-4F62-9A53-71BC4D8E6A12}']
    function WithMaxBits(ABits: Integer): IZCompressBuilder;
    function ToBytes: TBytes;
    function ToString: string;
    procedure ToStream(ADest: TStream);
    procedure ToFile(const APath: string);
  end;

  TZCompressBuilder = class(TInterfacedObject, IZCompressBuilder)
  private
    FDirection: TZCompressDirection;
    FMaxBits: Integer;
    FSrcBytes: TBytes;
    function ProcessBytes: TBytes;
  public
    constructor Create(ADir: TZCompressDirection; const ASrc: TBytes);
    function WithMaxBits(ABits: Integer): IZCompressBuilder;
    function ToBytes: TBytes;
    function ToString: string; reintroduce;
    procedure ToStream(ADest: TStream);
    procedure ToFile(const APath: string);
  end;

  Zlw = class
  public
    class function Compress(const ASrc: TBytes): IZCompressBuilder; overload;
    class function Compress(ASrc: TStream): IZCompressBuilder; overload;
    class function Compress(const AText: string): IZCompressBuilder; overload;
    class function CompressFile(const APath: string): IZCompressBuilder;
    class function Decompress(const ASrc: TBytes): IZCompressBuilder; overload;
    class function Decompress(ASrc: TStream): IZCompressBuilder; overload;
    class function DecompressFile(const APath: string): IZCompressBuilder;
  end;

implementation

function BytesFromStream(AStream: TStream): TBytes;
begin
  AStream.Position := 0;
  SetLength(Result, AStream.Size);
  if AStream.Size > 0 then AStream.ReadBuffer(Result[0], AStream.Size);
end;

function BytesFromFile(const APath: string): TBytes;
var Fs: TFileStream;
begin
  Fs := TFileStream.Create(APath, fmOpenRead or fmShareDenyWrite);
  try Result := BytesFromStream(Fs); finally Fs.Free; end;
end;

constructor TZCompressBuilder.Create(ADir: TZCompressDirection; const ASrc: TBytes);
begin
  inherited Create;
  FDirection := ADir;
  FMaxBits := Z_BITS_MAX;
  FSrcBytes := ASrc;
end;

function TZCompressBuilder.WithMaxBits(ABits: Integer): IZCompressBuilder;
begin
  FMaxBits := ABits;
  Result := Self;
end;

function TZCompressBuilder.ProcessBytes: TBytes;
begin
  case FDirection of
    zcdCompress:   Result := ZCompressBytes(FSrcBytes, FMaxBits);
    zcdDecompress: Result := ZDecompressBytes(FSrcBytes);
  else SetLength(Result, 0);
  end;
end;

function TZCompressBuilder.ToBytes: TBytes;
begin Result := ProcessBytes; end;

function TZCompressBuilder.ToString: string;
var B: TBytes;
begin
  B := ProcessBytes;
  if Length(B) = 0 then Result := '' else Result := TEncoding.UTF8.GetString(B);
end;

procedure TZCompressBuilder.ToStream(ADest: TStream);
var B: TBytes;
begin
  B := ProcessBytes;
  if Length(B) > 0 then ADest.WriteBuffer(B[0], Length(B));
end;

procedure TZCompressBuilder.ToFile(const APath: string);
var Fs: TFileStream;
begin
  Fs := TFileStream.Create(APath, fmCreate);
  try ToStream(Fs); finally Fs.Free; end;
end;

class function Zlw.Compress(const ASrc: TBytes): IZCompressBuilder;
begin Result := TZCompressBuilder.Create(zcdCompress, ASrc); end;

class function Zlw.Compress(ASrc: TStream): IZCompressBuilder;
begin Result := TZCompressBuilder.Create(zcdCompress, BytesFromStream(ASrc)); end;

class function Zlw.Compress(const AText: string): IZCompressBuilder;
begin Result := TZCompressBuilder.Create(zcdCompress, TEncoding.UTF8.GetBytes(AText)); end;

class function Zlw.CompressFile(const APath: string): IZCompressBuilder;
begin Result := TZCompressBuilder.Create(zcdCompress, BytesFromFile(APath)); end;

class function Zlw.Decompress(const ASrc: TBytes): IZCompressBuilder;
begin Result := TZCompressBuilder.Create(zcdDecompress, ASrc); end;

class function Zlw.Decompress(ASrc: TStream): IZCompressBuilder;
begin Result := TZCompressBuilder.Create(zcdDecompress, BytesFromStream(ASrc)); end;

class function Zlw.DecompressFile(const APath: string): IZCompressBuilder;
begin Result := TZCompressBuilder.Create(zcdDecompress, BytesFromFile(APath)); end;

end.
