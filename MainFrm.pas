unit MainFrm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  EditBtn, StdCtrls;

type

  { TMainForm }

  TMainForm = class(TForm)
    ProcessButton: TButton;
    DstFolderName: TDirectoryEdit;
    SrcFileName: TFileNameEdit;
    Label1: TLabel;
    Label2: TLabel;
    ResultLabel: TLabel;
    ProgressBar1: TProgressBar;
    procedure ProcessButtonClick(Sender: TObject);
  private
    procedure DeleteFileInFolder;
    procedure ProcessMailBox;

  public

  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

procedure TMainForm.ProcessButtonClick(Sender: TObject);
var AResult:Boolean;
begin
  if SrcFileName.FileName='' then
   begin
    ShowMessage('Unknown source file!');
    exit;
   end;

  if not FileExists(SrcFileName.FileName) then
   begin
    ShowMessage('A source file does not exists!');
    exit;
   end;

  if DstFolderName.Text='' then
   begin
    ShowMessage('Unknown destination folder!');
    exit;
   end;

  if DirectoryExists(DstFolderName.Text) then
   begin
    if MessageDlg('All files in folder by name '+DstFolderName.Text+' will be erased!'
      +#13'Continue?',mtConfirmation,[mbYes,mbNo],0)<>mrYes
       then exit;
   end else
   begin
    try
      AResult:=ForceDirectories(DstFolderName.Text);
    except
    end;

    if not AResult then
     begin
      ShowMessage('Can not create a folder by name '+DstFolderName.Text+'!');
      exit;
     end;
   end;

  DeleteFileInFolder;

  ProcessMailBox;
end;

procedure TMainForm.DeleteFileInFolder;
var AResult:Integer;
    ASR:TSearchRec;
begin
 AResult:=FindFirst(DstFolderName.Text+'\*.*',faAnyFile,ASR);

 while AResult=0 do
  begin
   try
     DeleteFile(DstFolderName.Text+'\'+ASR.Name);
   except
   end;

   AResult:=FindNext(ASR);
  end;

 FindClose(ASR);
end;

procedure TMainForm.ProcessMailBox;
var f1,f2:textFile;
    FileNo:LongInt;
    S:String;
begin
 FileNo:=0;

 ResultLabel.Caption:='Result: '+IntToStr(FileNo);
 ResultLabel.Repaint;

 ProgressBar1.Style:=pbstMarquee;

 ProcessButton.Enabled:=False;

 try
   assignFile(f1,SrcFileName.Text);
   reset(f1);
 except
   ShowMessage('Can not open '+SrcFileName.Text+'!');
   exit;
 end;

 while not eof(f1) do
  begin
   try
     readln(f1,S);
   except
     ShowMessage('Error on reading mailbox file!');
     Break;
   end;

   if (Pos('From - ',S)=1) then
    begin
     {$R-}
     if FileNo>0 then
      try
        closeFile(f2);
        if IOResult<>0 then;
      except
      end;
     {$R+}

     Inc(FileNo);

     ResultLabel.Caption:='Result: '+IntToStr(FileNo);
     ResultLabel.Repaint;

     assignFile(f2,DstFolderName.Text+'\'+IntToStr(FileNo)+'.eml');
     try
       rewrite(f2);
     except
       ShowMessage('Error on creating email file!');
       exit;
     end;

     Continue;
    end;

   if (Pos('X-Account-Key: ',S)=1)
    or (Pos('X-UIDL: ',S)=1)
     or (Pos('X-Mozilla-Status: ',S)=1)
      or (Pos('X-Mozilla-Status2: ',S)=1)
       or (Pos('X-Mozilla-Keys:',S)=1)
        then Continue;

   try
     writeln(f2,S);

     Application.ProcessMessages;

   except
     ShowMessage('Error on writing email file!');
     exit;
   end;
  end;

 closeFile(f2);
 closeFile(f1);

 ProgressBar1.Style:=pbstNormal;

 ProcessButton.Enabled:=True;

 ShowMessage('Done!');
end;

end.

