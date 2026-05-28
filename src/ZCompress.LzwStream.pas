{ ZCompress.LzwStream.pas

  .Z (Unix compress) format — LZW encoder/decoder pure-pascal.
  Patente Sperry/Unisys LZW US4558302 expirou em Jun/2003 — formato livre.

  Spec do formato .Z (3 bytes header + LZW codes packed):
    [0..1]: magic 0x1F, 0x9D
    [2]:    flags byte
              bit 7 = block mode (sempre 1 em modernos)
              bit 0..4 = max code bits (default 16)
    [3..]:  LZW packed codes (variable bit width 9..16)

  Implementacao:
   - Encoder (compress): table-based LZW classic
   - Decoder (uncompress): mantem dictionary syncronizado
   - Block mode: codigo 256 = clear table (reseta dict para 257)

  ROI: arquivos .Z legacy de sistemas Unix anos 80-90 ainda existem.
}
unit ZCompress.LzwStream;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils, Classes;

type
  EZCompressError = class(Exception);

const
  Z_MAGIC1 = $1F;
  Z_MAGIC2 = $9D;
  Z_BLOCK_MODE = $80;
  Z_BITS_MAX = 16;
  Z_FIRST_CODE = 257;  // 256 = clear, codes 0..255 = literals
  Z_CLEAR_CODE = 256;

function ZCompressBytes(const Src: TBytes; MaxBits: Integer = Z_BITS_MAX): TBytes;
function ZDecompressBytes(const Src: TBytes): TBytes;

procedure ZCompressStream(Src, Dst: TStream; MaxBits: Integer = Z_BITS_MAX);
procedure ZDecompressStream(Src, Dst: TStream);

implementation

// ============================================================================
//   BitWriter helper (packs variable-width codes LSB-first into byte stream)
// ============================================================================

type
  TBitWriter = record
    Stream: TStream;
    BitBuf: Cardinal;
    BitCount: Integer;
    procedure Init(AStream: TStream);
    procedure WriteBits(Value: Cardinal; NumBits: Integer);
    procedure Flush;
  end;

procedure TBitWriter.Init(AStream: TStream);
begin
  Stream := AStream;
  BitBuf := 0;
  BitCount := 0;
end;

procedure TBitWriter.WriteBits(Value: Cardinal; NumBits: Integer);
var
  B: Byte;
begin
  BitBuf := BitBuf or ((Value and ((Cardinal(1) shl NumBits) - 1)) shl BitCount);
  Inc(BitCount, NumBits);
  while BitCount >= 8 do
  begin
    B := Byte(BitBuf and $FF);
    Stream.WriteBuffer(B, 1);
    BitBuf := BitBuf shr 8;
    Dec(BitCount, 8);
  end;
end;

procedure TBitWriter.Flush;
var
  B: Byte;
begin
  if BitCount > 0 then
  begin
    B := Byte(BitBuf and $FF);
    Stream.WriteBuffer(B, 1);
    BitBuf := 0;
    BitCount := 0;
  end;
end;

// ============================================================================
//   BitReader helper
// ============================================================================

type
  TBitReader = record
    Stream: TStream;
    BitBuf: Cardinal;
    BitCount: Integer;
    EOF: Boolean;
    function ReadBits(NumBits: Integer): Cardinal;
    procedure Init(AStream: TStream);
  end;

procedure TBitReader.Init(AStream: TStream);
begin
  Stream := AStream;
  BitBuf := 0;
  BitCount := 0;
  EOF := False;
end;

function TBitReader.ReadBits(NumBits: Integer): Cardinal;
var
  B: Byte;
  ReadCount: Integer;
begin
  while (BitCount < NumBits) and not EOF do
  begin
    ReadCount := Stream.Read(B, 1);
    if ReadCount < 1 then
    begin
      EOF := True;
      Break;
    end;
    BitBuf := BitBuf or (Cardinal(B) shl BitCount);
    Inc(BitCount, 8);
  end;
  if EOF and (BitCount < NumBits) then
  begin
    Result := 0;
    Exit;
  end;
  Result := BitBuf and ((Cardinal(1) shl NumBits) - 1);
  BitBuf := BitBuf shr NumBits;
  Dec(BitCount, NumBits);
end;

// ============================================================================
//   Encoder: LZW classic (greedy)
// ============================================================================

function ZCompressBytes(const Src: TBytes; MaxBits: Integer): TBytes;
var
  Dst: TBytesStream;
begin
  Dst := TBytesStream.Create;
  try
    ZCompressStream(TBytesStream.Create(Src), Dst, MaxBits);
    SetLength(Result, Dst.Size);
    if Dst.Size > 0 then
    begin
      Dst.Position := 0;
      Dst.ReadBuffer(Result[0], Dst.Size);
    end;
  finally
    Dst.Free;
  end;
end;

procedure ZCompressStream(Src, Dst: TStream; MaxBits: Integer);
type
  TLzwEntry = record
    Prefix: Integer;  // index do prefix code
    Suffix: Byte;     // ultimo char
  end;
var
  Bw: TBitWriter;
  Dict: array of TLzwEntry;
  DictSize, MaxDictSize: Integer;
  CurBits: Integer;
  W, NewCode: Integer;
  K: Byte;
  Header: array[0..2] of Byte;
  ReadCount: Integer;
  Found: Boolean;
  I: Integer;
begin
  if (MaxBits < 9) or (MaxBits > 16) then
    raise EZCompressError.Create('MaxBits must be 9..16');

  // Write header
  Header[0] := Z_MAGIC1;
  Header[1] := Z_MAGIC2;
  Header[2] := Byte(MaxBits) or Z_BLOCK_MODE;
  Dst.WriteBuffer(Header[0], 3);

  Bw.Init(Dst);
  MaxDictSize := 1 shl MaxBits;
  SetLength(Dict, MaxDictSize);
  DictSize := Z_FIRST_CODE;
  CurBits := 9;

  // Read first byte
  ReadCount := Src.Read(K, 1);
  if ReadCount < 1 then
  begin
    Bw.Flush;
    Exit;
  end;
  W := K;

  while True do
  begin
    ReadCount := Src.Read(K, 1);
    if ReadCount < 1 then Break;

    // Procurar W+K no dicionario (linear search; OK para Z compat)
    Found := False;
    NewCode := -1;
    for I := Z_FIRST_CODE to DictSize - 1 do
    begin
      if (Dict[I].Prefix = W) and (Dict[I].Suffix = K) then
      begin
        W := I;
        Found := True;
        Break;
      end;
    end;
    if not Found then
    begin
      Bw.WriteBits(Cardinal(W), CurBits);
      if DictSize < MaxDictSize then
      begin
        Dict[DictSize].Prefix := W;
        Dict[DictSize].Suffix := K;
        Inc(DictSize);
        // Bump bit width quando dict cresce alem do alcance atual
        if (DictSize > (1 shl CurBits)) and (CurBits < MaxBits) then
          Inc(CurBits);
      end;
      W := K;
    end;
  end;

  // Emit ultimo W
  Bw.WriteBits(Cardinal(W), CurBits);
  Bw.Flush;
end;

// ============================================================================
//   Decoder: LZW classic
// ============================================================================

function ZDecompressBytes(const Src: TBytes): TBytes;
var
  SrcS: TBytesStream;
  Dst: TBytesStream;
begin
  SrcS := TBytesStream.Create(Src);
  Dst := TBytesStream.Create;
  try
    ZDecompressStream(SrcS, Dst);
    SetLength(Result, Dst.Size);
    if Dst.Size > 0 then
    begin
      Dst.Position := 0;
      Dst.ReadBuffer(Result[0], Dst.Size);
    end;
  finally
    Dst.Free;
    SrcS.Free;
  end;
end;

procedure ZDecompressStream(Src, Dst: TStream);
type
  TByteSeq = TBytes;
var
  Header: array[0..2] of Byte;
  MaxBits: Integer;
  Br: TBitReader;
  Dict: array of TByteSeq;
  DictSize, MaxDictSize: Integer;
  CurBits: Integer;
  Code, PrevCode: Integer;
  FirstByte: Byte;
  I: Integer;
  Seq: TBytes;
begin
  if Src.Read(Header[0], 3) <> 3 then
    raise EZCompressError.Create('Z: truncated header');
  if (Header[0] <> Z_MAGIC1) or (Header[1] <> Z_MAGIC2) then
    raise EZCompressError.Create('Z: bad magic');
  MaxBits := Header[2] and $1F;
  if (MaxBits < 9) or (MaxBits > 16) then
    raise EZCompressError.CreateFmt('Z: bad max bits %d', [MaxBits]);

  Br.Init(Src);
  MaxDictSize := 1 shl MaxBits;
  SetLength(Dict, MaxDictSize);
  for I := 0 to 255 do
  begin
    SetLength(Dict[I], 1);
    Dict[I][0] := Byte(I);
  end;
  DictSize := Z_FIRST_CODE;
  CurBits := 9;
  PrevCode := -1;

  while True do
  begin
    Code := Integer(Br.ReadBits(CurBits));
    if Br.EOF then Break;

    if Code = Z_CLEAR_CODE then
    begin
      DictSize := Z_FIRST_CODE;
      CurBits := 9;
      PrevCode := -1;
      Continue;
    end;

    if Code < DictSize then
      Seq := Dict[Code]
    else if (Code = DictSize) and (PrevCode >= 0) then
    begin
      Seq := Copy(Dict[PrevCode], 0, Length(Dict[PrevCode]));
      SetLength(Seq, Length(Seq) + 1);
      Seq[High(Seq)] := Dict[PrevCode][0];
    end
    else
      raise EZCompressError.CreateFmt('Z: invalid code %d (dict %d)', [Code, DictSize]);

    if Length(Seq) > 0 then
      Dst.WriteBuffer(Seq[0], Length(Seq));

    if (PrevCode >= 0) and (DictSize < MaxDictSize) and (Length(Seq) > 0) then
    begin
      FirstByte := Seq[0];
      SetLength(Dict[DictSize], Length(Dict[PrevCode]) + 1);
      if Length(Dict[PrevCode]) > 0 then
        Move(Dict[PrevCode][0], Dict[DictSize][0], Length(Dict[PrevCode]));
      Dict[DictSize][Length(Dict[PrevCode])] := FirstByte;
      Inc(DictSize);
      if (DictSize >= (1 shl CurBits)) and (CurBits < MaxBits) then
        Inc(CurBits);
    end;

    PrevCode := Code;
  end;
end;

end.
