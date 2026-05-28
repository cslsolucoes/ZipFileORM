{ Commons.Progress.pas

  Progress event type for long-running ZIP operations
  (AppendStream, GetFileStream, UpdateFile, DeleteFile).
  Dual-target Delphi (D24..D37) and FPC/Lazarus.

  Caller assigns TZipFile.OnProgress; engine fires it periodically with
  BytesDone / BytesTotal. Setting Cancel := True aborts the operation
  (caller is responsible for cleanup / exception handling).
}
unit Commons.Progress;

{$IFDEF FPC}
{$mode delphi}{$H+}
{$ENDIF}

interface

uses
  SysUtils;

type
  TZipProgressEvent = procedure(
    Sender: TObject;
    BytesDone, BytesTotal: Int64;
    var Cancel: Boolean
  ) of object;

implementation

end.
