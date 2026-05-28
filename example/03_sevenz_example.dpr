{ 03_sevenz_example.dpr
  Demonstra TSevenZFile (READ Win32/Win64 via SDK) + SevenZ.Fluent.
  Cobre: WRITE Store + WRITE LZMA2 + READ + Fluent factory.
}
program _03_sevenz_example;
{$APPTYPE CONSOLE}
{$IFDEF FPC}{$mode delphi}{$H+}{$ENDIF}
uses
  {$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  SevenZ.SevenZFile, SevenZ.Fluent;

const
  TMP_STORE = 'example_03_store.7z';
  TMP_LZMA2 = 'example_03_lzma2.7z';

procedure DemoStore;
var
  Sz: TSevenZFile;
  Names: array of string;
  Datas: array of TBytes;
const
  TXT1 = 'First 7z stored payload (method Copy)';
  TXT2 = 'Second 7z entry, longer for ratio test';
begin
  WriteLn('=== Demo 1: WRITE Store (method Copy) ===');
  if FileExists(TMP_STORE) then DeleteFile(TMP_STORE);
  SetLength(Names, 2); SetLength(Datas, 2);
  Names[0] := 'first.txt'; Datas[0] := TEncoding.UTF8.GetBytes(TXT1);
  Names[1] := 'second.txt'; Datas[1] := TEncoding.UTF8.GetBytes(TXT2);

  Sz := TSevenZFile.Create(nil);
  try
    Sz.FileName := TMP_STORE;
    Sz.CreateFromBytes(Names, Datas);
  finally Sz.Free; end;
  WriteLn('  Created Store ', TMP_STORE);

  // READ
  Sz := TSevenZFile.Create(nil);
  try
    Sz.FileName := TMP_STORE;
    Sz.Active := True;
    WriteLn('  EntryCount=', Sz.EntryCount);
    WriteLn('  first.txt  = "', Sz.ReadAsString('first.txt'), '"');
    WriteLn('  second.txt = "', Sz.ReadAsString('second.txt'), '"');
  finally Sz.Free; end;
  WriteLn;
end;

procedure DemoLZMA2;
var
  Sz: TSevenZFile;
  Names: array of string;
  Datas: array of TBytes;
const
  LONG = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' +
         'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB' +
         'CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC';
begin
  WriteLn('=== Demo 2: WRITE LZMA2 (compressed) ===');
  if FileExists(TMP_LZMA2) then DeleteFile(TMP_LZMA2);
  SetLength(Names, 1); SetLength(Datas, 1);
  Names[0] := 'compressed.txt';
  Datas[0] := TEncoding.UTF8.GetBytes(LONG);

  Sz := TSevenZFile.Create(nil);
  try
    Sz.FileName := TMP_LZMA2;
    Sz.CreateFromBytesLzma2(Names, Datas, 5);  // level 5
  finally Sz.Free; end;
  WriteLn('  Created LZMA2 ', TMP_LZMA2);

  Sz := TSevenZFile.Create(nil);
  try
    Sz.FileName := TMP_LZMA2;
    Sz.Active := True;
    WriteLn('  compressed.txt size=', Sz.GetFileSize(0));
    if Sz.ReadAsString('compressed.txt') = LONG then
      WriteLn('  PASS - LZMA2 round-trip')
    else WriteLn('  FAIL - content mismatch');
  finally Sz.Free; end;
  WriteLn;
end;

procedure DemoFluent;
var
  Stm: TStream;
const
  TXT = 'Hello SevenZ fluent';
begin
  WriteLn('=== Demo 3: SevenZ.Fluent (factory) ===');
  if FileExists(TMP_LZMA2) then DeleteFile(TMP_LZMA2);
  SevenZip.NewArchive(TMP_LZMA2)
        .WithLZMA2(5)
        .AppendBytes(TEncoding.UTF8.GetBytes(TXT), 'fluent.txt')
        .AppendFile('03_sevenz_example.dpr', 'src/main.dpr')
        .Execute;
  WriteLn('  Created via SevenZ.NewArchive');
  WriteLn('  fluent.txt = "', SevenZip.OpenArchive(TMP_LZMA2).ReadAsString('fluent.txt'), '"');
  WriteLn('  CountEntries=', SevenZip.OpenArchive(TMP_LZMA2).CountEntries);
  Stm := SevenZip.OpenArchive(TMP_LZMA2).ExtractStream('src/main.dpr');
  try WriteLn('  src/main.dpr extracted size=', Stm.Size);
  finally Stm.Free; end;
  WriteLn;
end;

begin
  try
    WriteLn('ZipFile example 03 -- 7zip (Store + LZMA2)');
    WriteLn('===========================================');
    WriteLn;
    DemoStore;
    DemoLZMA2;
    DemoFluent;
    WriteLn('OK -- todos demos PASS');
  except
    on E: Exception do begin WriteLn('FATAL: ', E.ClassName, ': ', E.Message); Halt(1); end;
  end;
end.
