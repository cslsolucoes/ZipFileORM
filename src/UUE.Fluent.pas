{ UUE.Fluent.pas
  Fluent builder API sobre UUE codec (UUE.UUEStream).

  Uso (encode):

      var Encoded := UUE.Encode(plainBytes)
                        .WithFileName('attachment.bin')
                        .WithMode($1B6)        // unix-style octal
                        .ToString;

  Uso (decode):

      var Plain := UUE.Decode(encodedText).ToBytes;
}
unit UUE.Fluent;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils, Classes, UUE.Stream;

type
  TUueDirection = (uudEncode, uudDecode);

  IUueBuilder = interface
    ['{A7E2D158-9F4B-4C5E-AB12-3E8F9D5C4B17}']
    function WithFileName(const AName: string): IUueBuilder;
    function WithMode(AMode: Cardinal): IUueBuilder;
    function ToString: string;
    function ToBytes: TBytes;
    procedure ToStream(ADest: TStream);
    procedure ToFile(const APath: string);
  end;

  TUueBuilder = class(TInterfacedObject, IUueBuilder)
  private
    FDirection: TUueDirection;
    FFileName: string;
    FMode: Cardinal;
    FSrcBytes: TBytes;
    FSrcText: string;
  public
    constructor CreateEncode(const ASrc: TBytes);
    constructor CreateDecode(const AText: string);
    function WithFileName(const AName: string): IUueBuilder;
    function WithMode(AMode: Cardinal): IUueBuilder;
    function ToString: string; reintroduce;
    function ToBytes: TBytes;
    procedure ToStream(ADest: TStream);
    procedure ToFile(const APath: string);
  end;

  Uu = class
  public
    class function Encode(const ASrc: TBytes): IUueBuilder; overload;
    class function Encode(ASrc: TStream): IUueBuilder; overload;
    class function Encode(const AText: string): IUueBuilder; overload;
    class function EncodeFile(const APath: string): IUueBuilder;
    class function Decode(const AText: string): IUueBuilder;
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

constructor TUueBuilder.CreateEncode(const ASrc: TBytes);
begin
  inherited Create;
  FDirection := uudEncode;
  FSrcBytes := ASrc;
  FFileName := 'data.bin';
  FMode := $1B6;  // 0o666 standard
end;

constructor TUueBuilder.CreateDecode(const AText: string);
begin
  inherited Create;
  FDirection := uudDecode;
  FSrcText := AText;
end;

function TUueBuilder.WithFileName(const AName: string): IUueBuilder;
begin
  FFileName := AName;
  Result := Self;
end;

function TUueBuilder.WithMode(AMode: Cardinal): IUueBuilder;
begin
  FMode := AMode;
  Result := Self;
end;

function TUueBuilder.ToString: string;
begin
  if FDirection = uudEncode then
    Result := UuEncodeBytes(FSrcBytes, FFileName, FMode)
  else
    Result := TEncoding.UTF8.GetString(UuDecodeBytes(FSrcText));
end;

function TUueBuilder.ToBytes: TBytes;
begin
  if FDirection = uudEncode then
    Result := TEncoding.UTF8.GetBytes(UuEncodeBytes(FSrcBytes, FFileName, FMode))
  else
    Result := UuDecodeBytes(FSrcText);
end;

procedure TUueBuilder.ToStream(ADest: TStream);
var B: TBytes;
begin
  B := ToBytes;
  if Length(B) > 0 then ADest.WriteBuffer(B[0], Length(B));
end;

procedure TUueBuilder.ToFile(const APath: string);
var Fs: TFileStream;
begin
  Fs := TFileStream.Create(APath, fmCreate);
  try ToStream(Fs); finally Fs.Free; end;
end;

class function Uu.Encode(const ASrc: TBytes): IUueBuilder;
begin Result := TUueBuilder.CreateEncode(ASrc); end;

class function Uu.Encode(ASrc: TStream): IUueBuilder;
begin Result := TUueBuilder.CreateEncode(BytesFromStream(ASrc)); end;

class function Uu.Encode(const AText: string): IUueBuilder;
begin Result := TUueBuilder.CreateEncode(TEncoding.UTF8.GetBytes(AText)); end;

class function Uu.EncodeFile(const APath: string): IUueBuilder;
var B: IUueBuilder;
begin
  B := TUueBuilder.CreateEncode(BytesFromFile(APath));
  B.WithFileName(ExtractFileName(APath));
  Result := B;
end;

class function Uu.Decode(const AText: string): IUueBuilder;
begin Result := TUueBuilder.CreateDecode(AText); end;

end.
