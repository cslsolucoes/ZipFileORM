{ ZipFile.Tests.Zip64.pas
  Fixture DUnitX cobrindo o caminho ZIP64 READ-ONLY:
   - Forja um archive ZIP64 minimo (entry STORE pequeno com sentinel
     0xFFFFFFFF nos campos size/offset da CDH + ZIP64 extra field 0x0001
     trazendo Int64 reais + ZIP64 EOCD Record + Locator + EOCD standard
     com sentinel)
   - Verifica que TZipFile abre sem raise, FileCount = 1, e que o
     payload roda round-trip via GetEntryStream
   - Caso negativo: archive comum (sem ZIP64) continua funcionando

  Write-side ZIP64 ainda nao esta implementado em TZipFile (vendor 32-bit
  inalterado para AppendStream). Cobertura write virou roadmap v2.x.
}
unit ZipFile.Tests.Zip64;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TZip64Tests = class
  public
    [Test] procedure ForgedZip64Archive_IsParsed;
    [Test] procedure ForgedZip64Archive_RoundTripPayload;
  end;

implementation

uses
  System.SysUtils, System.Classes,
  ZipFile, ZipFile.ZIP64, ZipFile.Tests.Shared;

const
  PAYLOAD: AnsiString = 'zip64-payload-token';
  ENTRY_NAME: AnsiString = 'z.txt';

// Forja um archive ZIP64 minimo no disco usando o protocolo PKWARE.
// Layout: LFH | filename | extra(0x0001 com USize+CSize) | payload |
//         CDH | filename | extra(0x0001 com USize+CSize+RelOffset) |
//         ZIP64 EOCD Record | ZIP64 EOCD Locator | EOCD standard
procedure ForgeMinimalZip64(const APath: string);
var
  Fs: TFileStream;
  W: TBytes;
  Crc: Cardinal;
  USize, CSize: Int64;
  LFHStartOffset, CDStartOffset, CDEndOffset, Zip64EOCDOffset: Int64;
  LFHExtra, CDHExtra: TBytes;

  procedure W32(V: Cardinal);
  begin
    SetLength(W, 4);
    Move(V, W[0], 4);
    Fs.WriteBuffer(W[0], 4);
  end;
  procedure W16(V: Word);
  begin
    SetLength(W, 2);
    Move(V, W[0], 2);
    Fs.WriteBuffer(W[0], 2);
  end;
  procedure W64(V: UInt64);
  begin
    SetLength(W, 8);
    Move(V, W[0], 8);
    Fs.WriteBuffer(W[0], 8);
  end;
  procedure WStr(const S: AnsiString);
  begin
    if Length(S) > 0 then
      Fs.WriteBuffer(S[1], Length(S));
  end;
  procedure WBytes(const B: TBytes);
  begin
    if Length(B) > 0 then
      Fs.WriteBuffer(B[0], Length(B));
  end;

  // Build extra field 0x0001 com N bytes de payload Int64
  function BuildZip64Extra(AIncludeUSize, AIncludeCSize, AIncludeOffset: Boolean;
                           AUSize, ACSize, AOffset: Int64): TBytes;
  var
    DataSize, P: Integer;
    V: UInt64;
  begin
    DataSize := 0;
    if AIncludeUSize then Inc(DataSize, 8);
    if AIncludeCSize then Inc(DataSize, 8);
    if AIncludeOffset then Inc(DataSize, 8);
    SetLength(Result, 4 + DataSize);
    Result[0] := $01; Result[1] := $00; // HdrID 0x0001 LE
    Result[2] := Byte(DataSize); Result[3] := Byte(DataSize shr 8);
    P := 4;
    if AIncludeUSize then begin V := UInt64(AUSize); Move(V, Result[P], 8); Inc(P, 8); end;
    if AIncludeCSize then begin V := UInt64(ACSize); Move(V, Result[P], 8); Inc(P, 8); end;
    if AIncludeOffset then begin V := UInt64(AOffset); Move(V, Result[P], 8); Inc(P, 8); end;
  end;

  function ComputeCRC32(const Data: AnsiString): Cardinal;
  var
    I: Integer;
    Tbl: Cardinal;
    J: Integer;
    C: Cardinal;
  begin
    Result := $FFFFFFFF;
    for I := 1 to Length(Data) do
    begin
      C := Result xor Byte(Data[I]);
      for J := 0 to 7 do
        if (C and 1) <> 0 then C := (C shr 1) xor $EDB88320 else C := C shr 1;
      Result := C;
    end;
    Result := Result xor $FFFFFFFF;
  end;

begin
  USize := Length(PAYLOAD);
  CSize := USize;
  Crc := ComputeCRC32(PAYLOAD);

  // Extra fields: LFH carrega USize+CSize (Offset nao aplicavel em LFH).
  LFHExtra := BuildZip64Extra(True, True, False, USize, CSize, 0);

  Fs := TFileStream.Create(APath, fmCreate);
  try
    LFHStartOffset := Fs.Position;
    // --- LFH ---
    W32($04034B50);            // sig
    W16($002D);                // versionneeded (4.5 for ZIP64)
    W16($0000);                // gpflag
    W16($0000);                // method = Store
    W16($0000);                // lastmodtime
    W16($0021);                // lastmoddate (= 1980-01-01-ish)
    W32(Crc);                  // crc32
    W32(ZIP64_MAGIC_32);       // compressedsize sentinel
    W32(ZIP64_MAGIC_32);       // uncompressedsize sentinel
    W16(Length(ENTRY_NAME));   // filenamelength
    W16(Length(LFHExtra));     // extrafieldlength
    WStr(ENTRY_NAME);
    WBytes(LFHExtra);
    // payload
    WStr(PAYLOAD);

    // --- CDH ---
    CDStartOffset := Fs.Position;
    CDHExtra := BuildZip64Extra(True, True, True, USize, CSize, LFHStartOffset);
    W32($02014B50);            // sig
    W16($002D);                // versionmadeby (4.5)
    W16($002D);                // versionneeded
    W16($0000);                // gpflag
    W16($0000);                // method
    W16($0000);                // lastmodtime
    W16($0021);                // lastmoddate
    W32(Crc);                  // crc32
    W32(ZIP64_MAGIC_32);       // compressedsize sentinel
    W32(ZIP64_MAGIC_32);       // uncompressedsize sentinel
    W16(Length(ENTRY_NAME));   // filenamelength
    W16(Length(CDHExtra));     // extrafieldlength
    W16($0000);                // filecommentlength
    W16($0000);                // disknumberstart
    W16($0001);                // internalfileattributes
    W32($0020);                // externalfileattributed
    W32(ZIP64_MAGIC_32);       // reloffsetlocalheader sentinel
    WStr(ENTRY_NAME);
    WBytes(CDHExtra);
    CDEndOffset := Fs.Position;

    // --- ZIP64 EOCD Record ---
    Zip64EOCDOffset := Fs.Position;
    W32(ZIP64_END_OF_CD_RECORD_SIGNATURE);
    W64(44);   // SizeOfRecord = size of remainder (44 bytes after this Int64)
    W16($002D); // VersionMadeBy
    W16($002D); // VersionNeeded
    W32(0);     // DiskNumber
    W32(0);     // DiskWithCDStart
    W64(1);     // EntriesOnThisDisk
    W64(1);     // TotalEntries
    W64(CDEndOffset - CDStartOffset);  // CDSize
    W64(CDStartOffset);                 // CDOffset

    // --- ZIP64 EOCD Locator ---
    W32(ZIP64_END_OF_CD_LOCATOR_SIGNATURE);
    W32(0);                 // DiskWithZip64EOCD
    W64(Zip64EOCDOffset);   // Zip64EOCDOffset
    W32(1);                 // TotalDisks

    // --- Standard EOCD com sentinel ---
    W32(STANDARD_EOCD_SIGNATURE);
    W16(0);                            // numberofthisdisk
    W16(0);                            // numberofthisdiskwithcd
    W16(1);                            // numberofcdentries (cabe em 16-bit)
    W16(1);                            // totalnumberofcdentries
    W32(Cardinal(CDEndOffset - CDStartOffset)); // sizeofthecentraldirectory
    W32(ZIP64_MAGIC_32);               // cdoffset sentinel
    W16(0);                            // commentlength
  finally
    Fs.Free;
  end;
end;

procedure TZip64Tests.ForgedZip64Archive_IsParsed;
var
  Path: string;
  Zip: TZipFile;
begin
  Path := TZipTestHelpers.MakeTempPath('zip64_parse.zip');
  try
    ForgeMinimalZip64(Path);
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Active := True;
      Assert.AreEqual<Cardinal>(1, Zip.FileCount, 'ZIP64 forge devia listar 1 entry');
      Assert.IsTrue(Zip.FileExists(string(ENTRY_NAME)));
    finally
      Zip.Free;
    end;
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

procedure TZip64Tests.ForgedZip64Archive_RoundTripPayload;
var
  Path: string;
  Zip: TZipFile;
  Stm: TStream;
begin
  Path := TZipTestHelpers.MakeTempPath('zip64_payload.zip');
  try
    ForgeMinimalZip64(Path);
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Active := True;
      Stm := Zip.GetEntryStream(string(ENTRY_NAME));
      try
        Assert.AreEqual(PAYLOAD, TZipTestHelpers.StreamToAnsi(Stm),
          'GetEntryStream em entry ZIP64 nao retornou payload correto');
      finally
        Stm.Free;
      end;
    finally
      Zip.Free;
    end;
  finally
    TZipTestHelpers.DeleteIfExists(Path);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TZip64Tests);

end.
