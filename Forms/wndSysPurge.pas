unit wndSysPurge;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.ToolWin;

type
   TfrmSysPurge = class(TForm)
      ToolBar1: TToolBar;
      toolBtnPurge: TToolButton;
      lvSysPurge: TListView;
      procedure FormCreate(Sender: TObject);
      procedure FormResize(Sender: TObject);
      procedure toolBtnPurgeClick(Sender: TObject);
      procedure lvSysPurgeCustomDrawSubItem(Sender: TCustomListView; Item: TListItem;
         SubItem: Integer; State: TCustomDrawState; var DefaultDraw: Boolean);
      private
         procedure ResizeColumns;
         procedure BuildOptions;
         procedure ProcessActions;
         procedure SetTaskProgress(Item: TListItem; Bytes: Int64; Progress: Integer);
         procedure TaskCleanFolder(item: TListItem; const Path, Mask: string; Recursive: Boolean);
      public
   end;

var
  frmSysPurge: TfrmSysPurge;

implementation

{$R *.dfm}

uses
   AppData,
   libRights,
   System.IOUtils, System.Types;

const
   LVIR_BOUNDS        = 0;

   // ListView messages
   LVM_FIRST          = $1000; // First
   LVM_REDRAWITEMS    = LVM_FIRST + 21;
   LVM_GETCOLUMNWIDTH = LVM_FIRST + 29;
   LVM_GETSUBITEMRECT = LVM_FIRST + 56; // Get SubItem Rect


//-------------------------------------------------------------------------------------------------
// Resize columns
procedure TfrmSysPurge.ResizeColumns;
var
   w: Integer;
begin
   lvSysPurge.Columns[0].Width:=-1;
   lvSysPurge.Columns[1].Width:=-1;
   w:=SendMessage(lvSysPurge.Handle, LVM_GETCOLUMNWIDTH, 0, 0);
   w:=w+SendMessage(lvSysPurge.Handle, LVM_GETCOLUMNWIDTH, 1, 0);
   lvSysPurge.Columns[2].Width:=lvSysPurge.ClientWidth-w-GetSystemMetrics(SM_CXVSCROLL);;
end;

//-------------------------------------------------------------------------------------------------
// Build ListView items with groups
procedure TfrmSysPurge.BuildOptions;
var
   grp : TListGroup;
   item: TListItem;

   procedure CreateGroup(const name: String);
   begin
      grp:=lvSysPurge.Groups.Add;
      grp.Header:=name;
   end;

   procedure AddItem(const Caption: string; Checked: Boolean);
   begin
      item := lvSysPurge.Items.Add;
      item.Checked := Checked;
      item.Caption := Caption;
      item.SubItems.Add('');   // col 1 - size
      item.SubItems.Add('');   // col 2 - progress
      item.Data := Pointer(NativeInt(0));
      item.GroupID := grp.GroupID;
   end;
begin

   CreateGroup('Microsoft Windows');
   AddItem('Temp files', True);
   AddItem('Prefetch files', False);

   // resize columns
   ResizeColumns;
end;

//-------------------------------------------------------------------------------------------------
// Process Actions
procedure TfrmSysPurge.ProcessActions;
var
   i, g : Integer;
   grp  : TListGroup;
begin
   for i := 0 to lvSysPurge.Items.Count - 1 do
   begin
      if not lvSysPurge.Items[i].Checked then Continue;

      grp := nil;
      for g := 0 to lvSysPurge.Groups.Count - 1 do
         if lvSysPurge.Groups[g].GroupID = lvSysPurge.Items[i].GroupID then
         begin
            grp := lvSysPurge.Groups[g];
            Break;
         end;

      if not Assigned(grp) then Continue;

      if grp.Header = 'Microsoft Windows' then
      begin
         if lvSysPurge.Items[i].Caption = 'Temp files' then
         begin
            TaskCleanFolder(lvSysPurge.Items[i], TPath.GetTempPath, '*.*', True);
            if IsAppElevated then
               TaskCleanFolder(lvSysPurge.Items[i], TPath.Combine(GetEnvironmentVariable('SystemRoot'), 'Temp'), '*.*', True);
         end;

         if lvSysPurge.Items[i].Caption = 'Prefetch files' then
            TaskCleanFolder(lvSysPurge.Items[i], TPath.Combine(GetEnvironmentVariable('SystemRoot'), 'Prefetch'), '*.pf', False);
      end;
   end;
end;

//-------------------------------------------------------------------------------------------------
// SetTaskProgress
procedure TfrmSysPurge.SetTaskProgress(Item: TListItem; Bytes: Int64; Progress: Integer);
var
   FormattedSize: string;

   function FormatBytes(B: Int64): string;
   begin
      if      B >= 1073741824 then Result := Format('%.2f GB', [B / 1073741824])
      else if B >= 1048576    then Result := Format('%.2f MB', [B / 1048576])
      else if B >= 1024       then Result := Format('%.1f KB', [B / 1024])
      else                         Result := Format('%d B',    [B]);
   end;

begin
   FormattedSize:=FormatBytes(Bytes);
   TThread.Synchronize(nil, procedure
   begin
      Item.SubItems[0]:=FormattedSize;
      Item.Data := Pointer(NativeInt(EnsureRange(Progress, 0, 100)));
      ResizeColumns;
      SendMessage(lvSysPurge.Handle, LVM_REDRAWITEMS, WPARAM(Item.Index), LPARAM(Item.Index));
      lvSysPurge.Update;
   end);
end;

//-------------------------------------------------------------------------------------------------
// Task: Clean Folder
procedure TfrmSysPurge.TaskCleanFolder(item: TListItem; const Path, Mask: string; Recursive: Boolean);
var
   DeletedBytes : Int64;
   FileSize     : Int64;
   Files        : TStringDynArray;
   SearchOpt    : TSearchOption;
   i            : Integer;
   LastUpdate   : Cardinal;
begin
   DeletedBytes:=0;
   LastUpdate:=0;
   SetTaskProgress(item, DeletedBytes, 0);

   if not TDirectory.Exists(Path) then
   begin
      SetTaskProgress(item, DeletedBytes, 100);
      Exit;
   end;

   if Recursive then
      SearchOpt:=TSearchOption.soAllDirectories
   else
      SearchOpt:=TSearchOption.soTopDirectoryOnly;

   try
      Files := TDirectory.GetFiles(Path, Mask, SearchOpt);
   except
      SetTaskProgress(item, DeletedBytes, 100);
      Exit;
   end;

   if Length(Files) = 0 then
   begin
      SetTaskProgress(item, DeletedBytes, 100);
      Exit;
   end;

   for i:= 0 to High(Files) do
   begin
      try
         FileSize := TFile.GetSize(Files[i]); // read before deleting
         TFile.Delete(Files[i]);              // delete file
         Inc(DeletedBytes, FileSize);         // add new file size to total size
      except
         // skip locked / access-denied files silently
      end;

      if GetTickCount - LastUpdate >= 25 then
      begin
         SetTaskProgress(Item, DeletedBytes, Round((i + 1) / Length(Files) * 100));
         LastUpdate := GetTickCount;
      end;
   end;

   SetTaskProgress(Item, DeletedBytes, 100);  // ensure final state is always shown
end;

//-------------------------------------------------------------------------------------------------
// frmSysPurge: onCreate
procedure TfrmSysPurge.FormCreate(Sender: TObject);
begin
   Self.Caption:=appCaption;
   BuildOptions;
end;

//-------------------------------------------------------------------------------------------------
// frmSysPurge: onResize
procedure TfrmSysPurge.FormResize(Sender: TObject);
begin
   ResizeColumns;
end;

procedure TfrmSysPurge.lvSysPurgeCustomDrawSubItem(Sender: TCustomListView; Item: TListItem;
  SubItem: Integer; State: TCustomDrawState; var DefaultDraw: Boolean);
const
   COLOR_FILL_ACTIVE : TColor = $00D07800;   // blue-ish (BGR)
   COLOR_FILL_DONE   : TColor = $0050B000;   // green (BGR)
   COLOR_BORDER      : TColor = $00AAAAAA;
   COLOR_BG          : TColor = clWindow;
   PADDING_H = 3;
   PADDING_V = 4;
var
   R        : TRect;
   Progress : Integer;
   FillW    : Integer;
   FillRect : TRect;
   Cvs      : TCanvas;
   Text     : string;
begin
   // Draw ProGressBar on column 3 (sub-item 2)
   if SubItem <> 2 then Exit;

   DefaultDraw := False;
   Cvs := Sender.Canvas;

   // Retrieve the exact subitem bounding rect from the listview
   R.Top  := SubItem;
   R.Left := LVIR_BOUNDS;
   SendMessage(Sender.Handle, LVM_GETSUBITEMRECT, WPARAM(Item.Index), LPARAM(@R));

   // Shrink for visual padding
   InflateRect(R, -PADDING_H, -PADDING_V);

   Progress := Integer(NativeInt(Item.Data));   // 0..100

   // -- Background --
   Cvs.Brush.Color := COLOR_BG;
   Cvs.Brush.Style := bsSolid;
   Cvs.FillRect(R);

   // -- Filled portion --
   if Progress > 0 then
   begin
      FillRect := R;
      FillW := Round((R.Width) * Progress / 100);
      FillRect.Right := FillRect.Left + FillW;

      if Progress >= 100 then
         Cvs.Brush.Color := COLOR_FILL_DONE
      else
         Cvs.Brush.Color := COLOR_FILL_ACTIVE;

      Cvs.Brush.Style := bsSolid;
      Cvs.FillRect(FillRect);
   end;

   // -- Border --
   Cvs.Brush.Style := bsClear;
   Cvs.Pen.Color   := COLOR_BORDER;
   Cvs.Rectangle(R);

   // -- Percentage label, centred --
   if Progress > 0 then
   begin
      Text := IntToStr(Progress) + '%';
      Cvs.Brush.Style := bsClear;
      Cvs.Font.Color  := clBlack;
      Cvs.Font.Size   := 8;
      DrawText(Cvs.Handle, PChar(Text), -1, R,
         DT_CENTER or DT_VCENTER or DT_SINGLELINE);
   end;
end;

procedure TfrmSysPurge.toolBtnPurgeClick(Sender: TObject);
begin
   toolBtnPurge.Enabled:=False;

   TThread.CreateAnonymousThread(procedure
   begin
      try
         ProcessActions;
      finally
         TThread.Synchronize(nil, procedure
         begin
            toolBtnPurge.Enabled:=True;
         end);
      end;
   end).Start;
end;

end.
