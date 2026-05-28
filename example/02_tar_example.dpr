{ 02_tar_example.dpr
  Demonstra TTarFile + TTarGzFile + Tar.Fluent.
  Cobre: AppendFile, AppendBytes, AppendString, AppendDirectoryEntry,
         GetEntryStream, ReadAsString, FileExists, EntryCount.
  Gzip wrap: WithGzipLevel(1..9).
}
program _02_tar_example;
{$APPTYPE CONSOLE}
{$IFDEF FPC}{$mode delphi}{$H+}{$ENDIF}
uses
  {$IFDEF FPC}SysUtils, Classes,{$ELSE}System.SysUtils, System.Classes,{$ENDIF}
  Tar.TarFile, Tar.TarGzFile, Tar.Fluent;

const
  TMP_TAR = 'example_02.tar';
  TMP_TGZ = 'example_02.tar.gz';

procedure DemoTar;
var
  Tar: TTarFile;
  Rec: TTarSearchRec;
  Status: Integer;
begin
  WriteLn('=== Demo 1: TTarFile WRITE+READ legacy ===');
  if FileExists(TMP_TAR) then DeleteFile(TMP_TAR);
  Tar := TTarFile.Create(nil);
  try
    Tar.FileName := TMP_TAR;
    Tar.Active := True;
    Tar.AppendString('First file content', 'first.txt');
    Tar.AppendBytes(TEncoding.UTF8.GetBytes('Binary blob'), 'bin/blob.dat');
    Tar.AppendDirectoryEntry('docs/', Now);
    Tar.AppendString('In subdir', 'docs/readme.md');
    WriteLn('  Wrote: EntryCount=', Tar.EntryCount);
  finally Tar.Free; end;

  Tar := TTarFile.Create(nil);
  try
    Tar.FileName := TMP_TAR;
    Tar.Active := True;
    WriteLn('  Read: EntryCount=', Tar.EntryCount);
    Status := Tar.FindFirst(Rec);
    while Status = 0 do
    begin
      WriteLn('    ', Rec.Name, '  size=', Rec.Size);
      Status := Tar.FindNext(Rec);
    end;
    WriteLn('  first.txt = "', Tar.ReadAsString('first.txt'), '"');
    WriteLn('  docs/readme.md = "', Tar.ReadAsString('docs/readme.md'), '"');
    WriteLn('  FileExists("first.txt") = ', Tar.FileExists('first.txt'));
  finally Tar.Free; end;
  WriteLn;
end;

procedure DemoTarFluent;
begin
  WriteLn('=== Demo 2: Tar.Fluent (TAR puro) ===');
  if FileExists(TMP_TAR) then DeleteFile(TMP_TAR);
  Tarball.NewArchive(TMP_TAR)
     .AppendString('Fluent string', 'fluent.txt')
     .AppendBytes(TEncoding.UTF8.GetBytes('Fluent bytes'), 'fluent.bin')
     .AppendDirectory('libs/')
     .Execute;
  WriteLn('  Created via Tar.NewArchive');
  WriteLn('  Read: CountEntries=', Tarball.OpenArchive(TMP_TAR).CountEntries);
  WriteLn('  fluent.txt = "', Tarball.OpenArchive(TMP_TAR).ReadAsString('fluent.txt'), '"');
  WriteLn;
end;

procedure DemoTarGz;
var
  TarGz: TTarGzFile;
const
  PAYLOAD = 'TarGz combined format payload — both TAR + Gzip wrap';
begin
  WriteLn('=== Demo 3: TTarGzFile (TAR + Gzip combo) legacy ===');
  if FileExists(TMP_TGZ) then DeleteFile(TMP_TGZ);
  TarGz := TTarGzFile.Create(nil);
  try
    TarGz.FileName := TMP_TGZ;
    TarGz.GzipLevel := 9;  // best compression
    TarGz.Active := True;
    TarGz.AppendString(PAYLOAD, 'log.txt');
    TarGz.AppendBytes(TEncoding.UTF8.GetBytes('Bytes via TarGz'), 'data.bin');
  finally TarGz.Free; end;

  TarGz := TTarGzFile.Create(nil);
  try
    TarGz.FileName := TMP_TGZ;
    TarGz.Active := True;
    WriteLn('  log.txt = "', TarGz.ReadAsString('log.txt'), '"');
    WriteLn('  EntryCount=', TarGz.EntryCount);
  finally TarGz.Free; end;
  WriteLn;
end;

procedure DemoTarGzFluent;
begin
  WriteLn('=== Demo 4: Tar.Fluent NewGzArchive (TAR.GZ) ===');
  if FileExists(TMP_TGZ) then DeleteFile(TMP_TGZ);
  Tarball.NewGzArchive(TMP_TGZ)
     .WithGzipLevel(9)
     .AppendString('Fluent gz string', 'a.txt')
     .AppendString('Outra entry', 'b.txt')
     .Execute;
  WriteLn('  Created via Tar.NewGzArchive (level 9)');
  WriteLn('  a.txt = "', Tarball.OpenGzArchive(TMP_TGZ).ReadAsString('a.txt'), '"');
  WriteLn('  b.txt = "', Tarball.OpenGzArchive(TMP_TGZ).ReadAsString('b.txt'), '"');
  WriteLn;
end;

begin
  try
    WriteLn('ZipFile example 02 -- TAR + Gzip + TarGz');
    WriteLn('=========================================');
    WriteLn;
    DemoTar;
    DemoTarFluent;
    DemoTarGz;
    DemoTarGzFluent;
    WriteLn('OK -- todos demos PASS');
  except
    on E: Exception do begin WriteLn('FATAL: ', E.ClassName, ': ', E.Message); Halt(1); end;
  end;
end.
