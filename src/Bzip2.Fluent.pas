{ Bzip2.Fluent.pas
  Fluent builder API sobre stream codec BZIP2 (Bzip2.Bzip2Stream).

  Uso (compress):

      var Comp := Bzip2.Compress(plainBytes)
                       .WithLevel(9)
                       .ToBytes;

  Uso (decompress):

      var Plain := Bzip2.Decompress(compressedBytes).ToBytes;

  Stream variants:

      Bzip2.Compress(srcStream).WithLevel(9).ToStream(dstStream);
      Bzip2.Decompress(srcStream).ToStream(dstStream);

  File variants:

      Bzip2.CompressFile('big.log').ToFile('big.log.bz2');
}
unit Bzip2.Fluent;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils, Classes, Bzip2.Stream;

type
  TBzip2Direction = (bzdCompress, bzdDecompress);

  IBzip2Builder = interface
    ['{D2A8F417-6B91-4C5E-9DA3-8F1E6C5B4321}']
    function WithLevel(ALevel: Integer): IBzip2Builder;
    function ToBytes: TBytes;
    function ToString: string;
    procedure ToStream(ADest: TStream);
    procedure ToFile(const APath: string);
  end;

  TBzip2Builder = class(TInterfacedObject, IBzip2Builder)
  private
    FDirection: TBzip2Direction;
    FLevel: Integer;
    FSrcBytes: TBytes;
    function ProcessBytes: TBytes;
  public
    constructor Create(ADir: TBzip2Direction; const ASrc: TBytes);
    function WithLevel(ALevel: Integer): IBzip2Builder;
    function ToBytes: TBytes;
    function ToString: string; reintroduce;
    procedure ToStream(ADest: TStream);
    procedure ToFile(const APath: string);
  end;

  Bzip = class
  public
    class function Compress(const ASrc: TBytes): IBzip2Builder; overload;
    class function Compress(ASrc: TStream): IBzip2Builder; overload;
    class function Compress(const AText: string): IBzip2Builder; overload;
    class function CompressFile(const APath: string): IBzip2Builder;
    class function Decompress(const ASrc: TBytes): IBzip2Builder; overload;
    class function Decompress(ASrc: TStream): IBzip2Builder; overload;
    class function DecompressFile(const APath: string): IBzip2Builder;
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

constructor TBzip2Builder.Create(ADir: TBzip2Direction; const ASrc: TBytes);
begin
  inherited Create;
  FDirection := ADir;
  FLevel := 9;
  FSrcBytes := ASrc;
end;

function TBzip2Builder.WithLevel(ALevel: Integer): IBzip2Builder;
begin
  FLevel := ALevel;
  Result := Self;
end;

function TBzip2Builder.ProcessBytes: TBytes;
begin
  case FDirection of
    bzdCompress:   Result := Bz2CompressBytes(FSrcBytes, FLevel);
    bzdDecompress: Result := Bz2DecompressBytes(FSrcBytes);
  else SetLength(Result, 0);
  end;
end;

function TBzip2Builder.ToBytes: TBytes;
begin
  Result := ProcessBytes;
end;

function TBzip2Builder.ToString: string;
var B: TBytes;
begin
  B := ProcessBytes;
  if Length(B) = 0 then Result := ''
  else Result := TEncoding.UTF8.GetString(B);
end;

procedure TBzip2Builder.ToStream(ADest: TStream);
var B: TBytes;
begin
  B := ProcessBytes;
  if Length(B) > 0 then ADest.WriteBuffer(B[0], Length(B));
end;

procedure TBzip2Builder.ToFile(const APath: string);
var Fs: TFileStream;
begin
  Fs := TFileStream.Create(APath, fmCreate);
  try ToStream(Fs); finally Fs.Free; end;
end;

class function Bzip.Compress(const ASrc: TBytes): IBzip2Builder;
begin Result := TBzip2Builder.Create(bzdCompress, ASrc); end;

class function Bzip.Compress(ASrc: TStream): IBzip2Builder;
begin Result := TBzip2Builder.Create(bzdCompress, BytesFromStream(ASrc)); end;

class function Bzip.Compress(const AText: string): IBzip2Builder;
begin Result := TBzip2Builder.Create(bzdCompress, TEncoding.UTF8.GetBytes(AText)); end;

class function Bzip.CompressFile(const APath: string): IBzip2Builder;
begin Result := TBzip2Builder.Create(bzdCompress, BytesFromFile(APath)); end;

class function Bzip.Decompress(const ASrc: TBytes): IBzip2Builder;
begin Result := TBzip2Builder.Create(bzdDecompress, ASrc); end;

class function Bzip.Decompress(ASrc: TStream): IBzip2Builder;
begin Result := TBzip2Builder.Create(bzdDecompress, BytesFromStream(ASrc)); end;

class function Bzip.DecompressFile(const APath: string): IBzip2Builder;
begin Result := TBzip2Builder.Create(bzdDecompress, BytesFromFile(APath)); end;

end.
