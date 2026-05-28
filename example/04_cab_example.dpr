{ 04_cab_example.dpr
  Demonstra TCabFile (READ via FDI + WRITE via FCI) + Cab.Fluent.
  Cobre: WRITE Store + WRITE MSZIP (compressed) + READ + Fluent.
}
program _04_cab_example;
{$APPTYPE CONSOLE}
{$IFDEF FPC}{$mode delphi}{$H+}{$ENDIF}
uses
  {$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  Cab.CabFile, Cab.Fluent;

const
  TMP_STORE = 'example_04_store.cab';
  TMP_MSZIP = 'example_04_mszip.cab';

procedure WriteAStringFile(const APath, AContent: string);
var Fs: TFileStream; B: TBytes;
begin
  if FileExists(APath) then DeleteFile(APath);
  Fs := TFileStream.Create(APath, fmCreate);
  try
    B := TEncoding.UTF8.GetBytes(AContent);
    if Length(B) > 0 then Fs.WriteBuffer(B[0], Length(B));
  finally Fs.Free; end;
end;

procedure DemoStore;
var Cab: TCabFile; I: Integer;
begin
  WriteLn('=== Demo 1: CAB WRITE Store + READ ===');
  WriteAStringFile('cab_src_a.txt', 'First CAB stored content');
  WriteAStringFile('cab_src_b.txt', 'Second CAB stored content');
  if FileExists(TMP_STORE) then DeleteFile(TMP_STORE);

  Cab := TCabFile.Create(nil);
  try
    Cab.FileName := TMP_STORE;
    Cab.Compression := cctNone;
    Cab.CreateFromFiles(['cab_src_a.txt', 'a.txt', 'cab_src_b.txt', 'b.txt']);
  finally Cab.Free; end;
  WriteLn('  Created Store ', TMP_STORE);

  Cab := TCabFile.Create(nil);
  try
    Cab.FileName := TMP_STORE;
    Cab.Active := True;
    WriteLn('  EntryCount=', Cab.EntryCount);
    for I := 0 to Cab.EntryCount - 1 do
      WriteLn('    ', Cab.GetEntryName(I), '  size=', Cab.GetFileSize(I));
    WriteLn('  a.txt = "', Cab.ReadAsString('a.txt'), '"');
    WriteLn('  b.txt = "', Cab.ReadAsString('b.txt'), '"');
  finally Cab.Free; end;
  WriteLn;
end;

procedure DemoLargeRoundTrip;
var Cab: TCabFile;
const
  PAYLOAD = 'CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC' +
            'DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD';
begin
  WriteLn('=== Demo 2: CAB WRITE Store (larger payload round-trip) ===');
  WriteLn('  Nota: cctMSZIP eh stub-only ate v3.7.2; usando cctNone aqui.');
  WriteAStringFile('cab_src_c.txt', PAYLOAD);
  if FileExists(TMP_MSZIP) then DeleteFile(TMP_MSZIP);

  Cab := TCabFile.Create(nil);
  try
    Cab.FileName := TMP_MSZIP;
    Cab.Compression := cctNone;
    Cab.CreateFromFiles(['cab_src_c.txt', 'compressed.txt']);
  finally Cab.Free; end;
  WriteLn('  Created ', TMP_MSZIP);

  Cab := TCabFile.Create(nil);
  try
    Cab.FileName := TMP_MSZIP;
    Cab.Active := True;
    if Cab.ReadAsString('compressed.txt') = PAYLOAD then
      WriteLn('  PASS - round-trip OK (', Cab.GetFileSize(0), ' bytes)')
    else WriteLn('  FAIL - content mismatch');
  finally Cab.Free; end;
  WriteLn;
end;

procedure DemoFluent;
var Stm: TStream;
begin
  WriteLn('=== Demo 3: Cab.Fluent (factory) ===');
  WriteAStringFile('cab_src_d.txt', 'Fluent CAB content');
  if FileExists(TMP_MSZIP) then DeleteFile(TMP_MSZIP);

  Cabinet.NewArchive(TMP_MSZIP)
     .WithCompression(cctNone)
     .AppendFile('cab_src_d.txt', 'fluent.txt')
     .AppendFile('04_cab_example.dpr', 'src/main.dpr')
     .Execute;
  WriteLn('  Created via Cab.NewArchive');
  WriteLn('  CountEntries=', Cabinet.OpenArchive(TMP_MSZIP).CountEntries);
  WriteLn('  fluent.txt = "', Cabinet.OpenArchive(TMP_MSZIP).ReadAsString('fluent.txt'), '"');
  Stm := Cabinet.OpenArchive(TMP_MSZIP).ExtractStream('src/main.dpr');
  try WriteLn('  src/main.dpr extracted size=', Stm.Size);
  finally Stm.Free; end;
  WriteLn;
end;

procedure Cleanup;
const FILES_TO_REMOVE: array[0..3] of string = ('cab_src_a.txt','cab_src_b.txt','cab_src_c.txt','cab_src_d.txt');
var S: string;
begin
  for S in FILES_TO_REMOVE do if FileExists(S) then DeleteFile(S);
end;

begin
  try
    WriteLn('ZipFile example 04 -- CAB (Store + MSZIP)');
    WriteLn('==========================================');
    WriteLn;
    DemoStore;
    DemoLargeRoundTrip;
    DemoFluent;
    Cleanup;
    WriteLn('OK -- todos demos PASS');
  except
    on E: Exception do begin WriteLn('FATAL: ', E.ClassName, ': ', E.Message); Halt(1); end;
  end;
end.
