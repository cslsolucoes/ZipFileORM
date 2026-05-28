{ smoke_linux.pas — FPC cross-target sanity test for ZipFile.pas

  Compila para Linux x86_64 via FPC cross com:
    ppcx64 -Tlinux -Px86_64 -Fu../src smoke_linux.pas

  Cobre apenas o core sem extensões dependentes de runtime Win
  (sem AES/LZMA — esses são Delphi-Win-only por enquanto).
}
program smoke_linux;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, ZipFile;

const
  N = 1024 * 64;   // 64KB payload
var
  Path: string;
  Zip: TZipFile;
  Big: TMemoryStream;
  Payload: array[0..N-1] of Byte;
  I: Integer;
begin
  Path := 'smoke_linux.zip';
  if FileExists(Path) then DeleteFile(Path);

  for I := 0 to N - 1 do Payload[I] := Byte(I);

  WriteLn('ZipFile FPC Linux smoke — write...');
  Big := TMemoryStream.Create;
  try
    Big.WriteBuffer(Payload[0], N);
    Big.Position := 0;
    Zip := TZipFile.Create(nil);
    try
      Zip.FileName := Path;
      Zip.Active := True;
      Zip.AppendStream(Big, 'payload.bin', Now);
      WriteLn('   AppendStream OK');
    finally
      Zip.Free;
    end;
  finally
    Big.Free;
  end;

  WriteLn('ZipFile FPC Linux smoke — read...');
  Zip := TZipFile.Create(nil);
  try
    Zip.FileName := Path;
    Zip.Active := True;
    if Zip.FileCount = 1 then
      WriteLn('   FileCount=1 OK')
    else
      WriteLn('   FAIL — FileCount<>1');
  finally
    Zip.Free;
  end;

  WriteLn('Done.');
end.
