unit wndSysPurge;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.ToolWin;

const
   SYSMENU_ABOUT_ID = UINT(1000);

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
      protected
         procedure CreateWnd; override;
         procedure WndProc(var Message: TMessage); override;
      private
         procedure ResizeColumns;
         procedure BuildOptions;
         procedure ProcessActions;
         procedure SetTaskProgress(Item: TListItem; Bytes: Int64; Progress: Integer); overload;
         procedure SetTaskProgress(Item: TListItem; count: Integer; Progress: Integer); overload;
         procedure TaskCleanFolder(item: TListItem; const Path, Mask: string; Recursive: Boolean);
         procedure TaskCleanRegistryMissingDLLFiles(item: TListItem; Root: HKEY; path: String);
      public
   end;

var
  frmSysPurge: TfrmSysPurge;

implementation

{$R *.dfm}

uses
   AppData, wndAbout,
   libRights, libReg, libMessages,
   System.IOUtils, System.Types, Registry;

procedure TfrmSysPurge.CreateWnd;
var
   hSysMenu: HMENU;
begin
   inherited;
   hSysMenu := GetSystemMenu(Handle, False);
   AppendMenu(hSysMenu, MF_SEPARATOR, 0, nil);
   AppendMenu(hSysMenu, MF_STRING,    SYSMENU_ABOUT_ID, 'About...');
end;

//-------------------------------------------------------------------------------------------------
// WndProc
procedure TfrmSysPurge.WndProc(var Message: TMessage);
var
  frm: TfrmAbout;
begin
   inherited;
   if Message.Msg = WM_SYSCOMMAND then
      if UINT(Message.WParam) = SYSMENU_ABOUT_ID then
      begin
         frm:=TfrmAbout.Create(Self);
         try
            frm.ShowModal;
         finally
            frm.Free;
         end;
      end;
end;

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

   CreateGroup('Microsoft Windows FileSystem');
   AddItem('Temp files', True);
   AddItem('Log files (inside Windows)', True);
   AddItem('Log files (System drive)', False);
   AddItem('Prefetch files', False);

   CreateGroup('Microsoft Windows Registry');
   if IsAppElevated then
      AddItem('Shared DLL''s', True);

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

      // Windows FileSystem =======================================================================
      if grp.Header = 'Microsoft Windows FileSystem' then
      begin

         // %Temp% --------------------------------------------------------------------------------
         if lvSysPurge.Items[i].Caption = 'Temp files' then
         begin
            //TaskCleanFolder(lvSysPurge.Items[i], TPath.GetTempPath, '*.*', True);
            TaskCleanFolder(lvSysPurge.Items[i], GetEnvironmentVariable('tmp'), '*.*', True);
            TaskCleanFolder(lvSysPurge.Items[i], GetEnvironmentVariable('temp'), '*.*', True);
            if IsAppElevated then
               TaskCleanFolder(lvSysPurge.Items[i], TPath.Combine(GetEnvironmentVariable('SystemRoot'), 'Temp'), '*.*', True);
         end;

         // c:\Windows\*.log ----------------------------------------------------------------------
         if lvSysPurge.Items[i].Caption = 'Log files (inside Windows)' then
            TaskCleanFolder(lvSysPurge.Items[i], GetEnvironmentVariable('SystemRoot'), '*.log', False);

         // c:\*.log ------------------------------------------------------------------------------
         if lvSysPurge.Items[i].Caption = 'Log files (System drive)' then
            TaskCleanFolder(lvSysPurge.Items[i], GetEnvironmentVariable('SystemDrive'), '*.log', False);

         // c:\Windows\Prefetch\*.pf --------------------------------------------------------------
         if lvSysPurge.Items[i].Caption = 'Prefetch files' then
            TaskCleanFolder(lvSysPurge.Items[i], TPath.Combine(GetEnvironmentVariable('SystemRoot'), 'Prefetch'), '*.pf', False);
      end;

      // Windows Registry =========================================================================
      if grp.Header = 'Microsoft Windows Registry' then
      begin

         // Shared DLL's
         if IsAppElevated then
            if lvSysPurge.Items[i].Caption = 'Shared DLL''s' then
               TaskCleanRegistryMissingDLLFiles(lvSysPurge.Items[i], HKEY_LOCAL_MACHINE, 'Software\Microsoft\Windows\CurrentVersion\SharedDLLs');
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

procedure TfrmSysPurge.SetTaskProgress(Item: TListItem; count: Integer; Progress: Integer);
var
   FormattedCount : string;
begin
   FormattedCount:=Format('%d entries', [count]);
   TThread.Synchronize(nil, procedure
   begin
      Item.SubItems[0]:=FormattedCount;
      Item.Data:=Pointer(NativeInt(EnsureRange(Progress, 0, 100)));
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
// Task: Clean Missing files from Registry
procedure TfrmSysPurge.TaskCleanRegistryMissingDLLFiles(item: TListItem; root: HKEY; path: String);
var
   i          : Integer;
   reg        : TRegistry;
   names      : TStringList;
   deleted    : Integer;
   lastUpdate : Cardinal;
   filePath   : String;
begin
   SetTaskProgress(Item, 0, 0);
   deleted:=0;
   lastUpdate:=0;
   reg:=TRegistry.Create(KEY_READ or KEY_SET_VALUE or KEY_WOW64_64KEY);
   names:=TStringList.Create;
   try
      reg.RootKey:=root;

      if not Reg.OpenKey(path, False) then
      begin
         ShowMessage('exit');
         SetTaskProgress(Item, 0, 100);
         Exit;
      end;

      reg.GetValueNames(names);

      for i:=0 to Names.Count - 1 do
      begin
         // expand any environment strings e.g. %SystemRoot%
         filePath:=ExpandUNCFileName(names[i]);
         if not TFile.Exists(filePath) then
         begin
            try
         ShowMessage(filePath);
         ShowMessage(names[i]);
               Reg.DeleteValue(names[i]);
               Inc(Deleted);
            except
               // skip values we can't delete (permissions etc.)
            end;
         end;

         if GetTickCount - LastUpdate >= 25 then
         begin
            SetTaskProgress(item, deleted, Round((i + 1) / names.Count * 100));
            LastUpdate:=GetTickCount;
         end;
      end;

      reg.CloseKey;
      SetTaskProgress(item, deleted, 100);
   finally
      names.Free;
      reg.Free;
   end;
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
