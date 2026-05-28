{ UUE.UUEStream.pas

  uuencode/uudecode pure-pascal (formato Unix tradicional).
  Stream-based + helpers para encoding/decoding de TBytes/string.

  Formato UUE:
   - Linha 1: "begin <mode-octal> <filename>"
   - Linhas 2..N: cada linha tem 1 char de length + 60 chars de payload
     codificado (45 bytes binarios -> 60 chars 7-bit ASCII)
   - Linha terminadora: "`" (backtick, length=0)
   - Linha final: "end"

  Cada grupo de 3 bytes binarios -> 4 chars ASCII (cada char = 6 bits + 0x20).
  Bytes nulos sao codificados como '`' (0x60).
}
unit UUE.Stream;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils, Classes;

type
  EUUEError = class(Exception);

function UuEncodeBytes(const Src: TBytes; const FileName: string;
  Mode: Cardinal = $1B6): string;
function UuEncodeStream(Src: TStream; const FileName: string;
  Mode: Cardinal = $1B6): string;

function UuDecodeBytes(const Encoded: string): TBytes;
procedure UuDecodeToStream(const Encoded: string; Dst: TStream);

implementation

const
  CR = #13;
  LF = #10;
  EOL = CR + LF;
  PAYLOAD_PER_LINE = 45;

function EncodeChar(B: Byte): Char; inline;
begin
  if (B and $3F) = 0 then
    Result := '`'
  else
    Result := Chr((B and $3F) + $20);
end;

function DecodeChar(C: Char): Byte; inline;
begin
  if C = '`' then
    Result := 0
  else
    Result := (Byte(C) - $20) and $3F;
end;

function IntToOct(V, Digits: Integer): string;
var
  S: string;
begin
  if V = 0 then S := '0'
  else begin
    S := '';
    while V > 0 do
    begin
      S := Chr(Ord('0') + (V and 7)) + S;
      V := V shr 3;
    end;
  end;
  while Length(S) < Digits do S := '0' + S;
  Result := S;
end;

function UuEncodeBytes(const Src: TBytes; const FileName: string;
  Mode: Cardinal): string;
var
  SB: TStringBuilder;
  I, LineLen, Idx, N: Integer;
  B1, B2, B3: Byte;
begin
  SB := TStringBuilder.Create;
  try
    SB.Append('begin ').Append(IntToOct(Integer(Mode), 3)).Append(' ')
      .Append(FileName).Append(EOL);

    N := Length(Src);
    Idx := 0;
    while Idx < N do
    begin
      LineLen := N - Idx;
      if LineLen > PAYLOAD_PER_LINE then LineLen := PAYLOAD_PER_LINE;
      SB.Append(EncodeChar(Byte(LineLen)));

      I := 0;
      while I < LineLen do
      begin
        if I < LineLen then B1 := Src[Idx + I] else B1 := 0;
        if I + 1 < LineLen then B2 := Src[Idx + I + 1] else B2 := 0;
        if I + 2 < LineLen then B3 := Src[Idx + I + 2] else B3 := 0;
        SB.Append(EncodeChar(B1 shr 2));
        SB.Append(EncodeChar(((B1 shl 4) and $30) or (B2 shr 4)));
        SB.Append(EncodeChar(((B2 shl 2) and $3C) or (B3 shr 6)));
        SB.Append(EncodeChar(B3 and $3F));
        Inc(I, 3);
      end;
      SB.Append(EOL);
      Inc(Idx, LineLen);
    end;

    SB.Append('`' + EOL).Append('end' + EOL);
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function UuEncodeStream(Src: TStream; const FileName: string;
  Mode: Cardinal): string;
var
  Buf: TBytes;
begin
  SetLength(Buf, Src.Size - Src.Position);
  if Length(Buf) > 0 then
    Src.ReadBuffer(Buf[0], Length(Buf));
  Result := UuEncodeBytes(Buf, FileName, Mode);
end;

function UuDecodeBytes(const Encoded: string): TBytes;
var
  Lines: TStringList;
  LIdx, I, LineLen, BytesEmitted: Integer;
  Line: string;
  C1, C2, C3, C4: Byte;
  TempByte: Byte;
  ResStream: TBytesStream;
begin
  Lines := TStringList.Create;
  ResStream := TBytesStream.Create;
  try
    Lines.Text := Encoded;
    LIdx := 0;
    while (LIdx < Lines.Count) and (Pos('begin ', Lines[LIdx]) <> 1) do
      Inc(LIdx);
    if LIdx >= Lines.Count then
      raise EUUEError.Create('UU: missing "begin" header');
    Inc(LIdx);

    while LIdx < Lines.Count do
    begin
      Line := Lines[LIdx];
      Inc(LIdx);
      if Line = '' then Continue;
      if (Line = '`') or (LowerCase(Trim(Line)) = 'end') then Break;

      LineLen := DecodeChar(Line[1]);
      if LineLen = 0 then Break;

      BytesEmitted := 0;
      I := 2;
      while (BytesEmitted < LineLen) and (I + 3 <= Length(Line)) do
      begin
        C1 := DecodeChar(Line[I]);
        C2 := DecodeChar(Line[I + 1]);
        C3 := DecodeChar(Line[I + 2]);
        C4 := DecodeChar(Line[I + 3]);
        if BytesEmitted < LineLen then
        begin
          TempByte := (C1 shl 2) or (C2 shr 4);
          ResStream.Write(TempByte, 1);
          Inc(BytesEmitted);
        end;
        if BytesEmitted < LineLen then
        begin
          TempByte := (C2 shl 4) or (C3 shr 2);
          ResStream.Write(TempByte, 1);
          Inc(BytesEmitted);
        end;
        if BytesEmitted < LineLen then
        begin
          TempByte := (C3 shl 6) or C4;
          ResStream.Write(TempByte, 1);
          Inc(BytesEmitted);
        end;
        Inc(I, 4);
      end;
    end;

    SetLength(Result, ResStream.Size);
    if Length(Result) > 0 then
    begin
      ResStream.Position := 0;
      ResStream.ReadBuffer(Result[0], Length(Result));
    end;
  finally
    ResStream.Free;
    Lines.Free;
  end;
end;

procedure UuDecodeToStream(const Encoded: string; Dst: TStream);
var
  B: TBytes;
begin
  B := UuDecodeBytes(Encoded);
  if Length(B) > 0 then
    Dst.WriteBuffer(B[0], Length(B));
end;

end.
