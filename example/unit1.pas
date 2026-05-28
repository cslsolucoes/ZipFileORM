unit Unit1; 

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, Buttons,
  StdCtrls, ZipFile, ComCtrls, ExtCtrls, Menus;

type

  { TMainForm }

  TMainForm = class(TForm)
    ViewMenuItem: TMenuItem;
    AppendMenuItem: TMenuItem;
    DeleteMenuItem: TMenuItem;
    PopupMenu1: TPopupMenu;
    OpenZipFileButton: TButton;
    Panel1: TPanel;
    SaveReportButton: TButton;
    FileExistsButton: TButton;
    FileNameEdit: TEdit;
    FileListView: TListView;
    GetReportButton: TButton;
    OpenDialog1: TOpenDialog;
    ShowFilesTabSheet: TTabSheet;
    ZIPReportMemo: TMemo;
    PageControl: TPageControl;
    ReportTabSheet: TTabSheet;
    ZipFile1: TZipFile;
    procedure AppendMenuItemClick(Sender: TObject);
    procedure DeleteMenuItemClick(Sender: TObject);
    procedure FileExistsButtonClick(Sender: TObject);
    procedure FileListViewSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure GetReportButtonClick(Sender: TObject);
    procedure OpenZipFileButtonClick(Sender: TObject);
    procedure SaveReportButtonClick(Sender: TObject);
    procedure ViewMenuItemClick(Sender: TObject);
    procedure ZipFile1FileChanged(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  MainForm: TMainForm;

implementation

uses Unit2;

{ TMainForm }

procedure TMainForm.FileExistsButtonClick(Sender: TObject);
begin
  if ZipFile1.FileExists(FileNameEdit.Text) then
    ShowMessage(Format('File %s exists',[FileNameEdit.Text]))
  else
    ShowMessage(Format('File %s does not exist',[FileNameEdit.Text]));
end;

procedure TMainForm.AppendMenuItemClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
    ZipFile1.AppendFileFromDisk(OpenDialog1.FileName, ExtractFileName(OpenDialog1.FileName));
end;

procedure TMainForm.DeleteMenuItemClick(Sender: TObject);
begin
  if Assigned(FileListView.Selected) then
    ZipFile1.DeleteFile(FileListView.Selected.Caption);
end;

procedure TMainForm.FileListViewSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  FileNameEdit.Text := Item.Caption;
end;

procedure TMainForm.ZipFile1FileChanged(Sender: TObject);
var
  SearchResult: TZipSearchRec;
begin
  FileListView.Clear;

  if ZipFile1.FindFirst(SearchResult) = 0 then
  begin
    repeat
      with FileListView.Items.Add do
      begin
        Caption := SearchResult.Name;
        if SearchResult.USize > 1024 then
          SubItems.Add(Format('%d kb', [SearchResult.USize div 1024]))
        else
          SubItems.Add(Format('%d b', [SearchResult.USize]));

        SubItems.Add(DateTimeToStr(SearchResult.DateTime));
        if SearchResult.USize = 0 then
          SubItems.Add(Format('%d %%', [0]))
        else
          SubItems.Add(Format('%.0f %%', [100-SearchResult.CSize/SearchResult.USize*100]));
      end;
    until ZipFile1.FindNext(SearchResult) <> 0;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  PageControl.PageIndex := 0;
  ZipFile1.Activate;
  ZipFile1FileChanged(nil);
end;

procedure TMainForm.GetReportButtonClick(Sender: TObject);
begin
  ZipReportMemo.Clear;
  ZipReportMemo.Lines.AddStrings(ZipFile1.Report);
end;

procedure TMainForm.OpenZipFileButtonClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    ZipFile1.FileName := OpenDialog1.FileName;
    ZipFile1.Activate;
  end;
end;

procedure TMainForm.SaveReportButtonClick(Sender: TObject);
begin
  ZIPReportMemo.Lines.SaveToFile('report.txt');
end;

procedure TMainForm.ViewMenuItemClick(Sender: TObject);
var
  myfs: TMemoryStream;
  buflen: longword;
  stmp: string;
  memdata: TMemoryStream;
begin
  if Assigned(FileListView.Selected) then
  begin
    myfs := ZipFile1.GetFileStream(FileListView.Selected.Caption, buflen);
    SetLength(stmp, buflen);
    myfs.ReadBuffer(stmp[1], buflen);
    
    Form1.FileDataMemo.Lines.Text := stmp;
    Form1.FileName := FileListView.Selected.Caption;
    
    Form1.ShowModal;
    
    if Form1.DataChanged then
    begin
      if MessageDlg('Content changed, update file?',mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      begin
        memdata := TMemoryStream.Create;
        Form1.FileDataMemo.Lines.SaveToStream(memdata);
        memdata.Position := 0;

        ZipFile1.UpdateFile(memdata, FileListView.Selected.Caption);
      end;
    end;
  end;
end;

initialization
  {$I unit1.lrs}

end.

