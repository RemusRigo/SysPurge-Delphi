unit wndSysPurge;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.ToolWin, System.ImageList,
  Vcl.ImgList;

const
   SYSMENU_ABOUT_ID = UINT(1000);

type
   TfrmSysPurge = class(TForm)
      ToolBar1: TToolBar;
      toolBtnPurge: TToolButton;
      lvSysPurge: TListView;
    imgListLV: TImageList;
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
         procedure TaskCleanFolder(item: TListItem; const Path, Mask: string; Recursive, DeleteFolders: Boolean);
         procedure TaskCleanRegistryMissingDLLFiles(item: TListItem; Root: HKEY; path: String);
      public
   end;

var
  frmSysPurge: TfrmSysPurge;

implementation

{$R *.dfm}

uses
   AppData, wndAbout,
   libRights, libReg, libMessages, libServices,
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

   procedure CreateGroup(const name: String; imgIndex: Integer);
   begin
      grp:=lvSysPurge.Groups.Add;
      grp.Header:=name;
      grp.TitleImage:=imgIndex;
   end;

   procedure AddItem(const caption: string; imgIndex: Integer; checked: Boolean);
   begin
      item:= lvSysPurge.Items.Add;
      item.Checked:=Checked;
      item.Caption:=Caption;
      item.SubItems.Add('');
      item.SubItems.Add('');
      item.Data := Pointer(NativeInt(0));
      item.ImageIndex:=imgIndex;
      item.GroupID:=grp.GroupID;
   end;
begin

   CreateGroup('Microsoft Windows FileSystem', 0);
   if IsAppElevated then
      AddItem('EventViewer logs', 0, True);
   AddItem('Log files (inside Windows)', 0, True);
   AddItem('Log files (System drive)', 0, False);
   AddItem('Prefetch files', 0, False);
   AddItem('Temp files (Current User)', 0, True);
   AddItem('Temp files (Windows)', 0, True);
   if IsAppElevated then
      AddItem('Windows Update cache', 0, True);

   CreateGroup('Microsoft Windows Registry', 1);
   AddItem('MRU list: Run', 1, True);
   if IsAppElevated then
      AddItem('Shared DLL''s', 1, True);

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
         // c:\Windows\*.log ----------------------------------------------------------------------
         if lvSysPurge.Items[i].Caption = 'EventViewer logs' then
         begin
            if IsAppElevated then
            begin
               if GetServiceState('eventlog') <> SERVICE_STOPPED then
               begin
                  if not StopServiceAndWait('eventlog', 10000) then
                     exit;
               end;
               TaskCleanFolder(lvSysPurge.Items[i], TPath.Combine(GetEnvironmentVariable('SystemRoot'), 'System32\winevt\Logs'), '*.evtx', False, False);
               ServiceControl('eventlog', 0); // restart
            end;
         end;

         // c:\Windows\*.log ----------------------------------------------------------------------
         if lvSysPurge.Items[i].Caption = 'Log files (inside Windows)' then
            TaskCleanFolder(lvSysPurge.Items[i], GetEnvironmentVariable('SystemRoot'), '*.log', False, False);

         // c:\Windows\*.log ----------------------------------------------------------------------
         if lvSysPurge.Items[i].Caption = 'Log files (inside Windows)' then
            TaskCleanFolder(lvSysPurge.Items[i], GetEnvironmentVariable('SystemRoot'), '*.log', False, False);

         // c:\*.log ------------------------------------------------------------------------------
         if lvSysPurge.Items[i].Caption = 'Log files (System drive)' then
            TaskCleanFolder(lvSysPurge.Items[i], GetEnvironmentVariable('SystemDrive'), '*.log', False, False);

         // %SystemRoot%\Prefetch\*.pf --------------------------------------------------------------
         if lvSysPurge.Items[i].Caption = 'Prefetch files' then
            TaskCleanFolder(lvSysPurge.Items[i], TPath.Combine(GetEnvironmentVariable('SystemRoot'), 'Prefetch'), '*.pf', False, False);

         // %Temp% --------------------------------------------------------------------------------
         if lvSysPurge.Items[i].Caption = 'Temp files (Current User)' then
         begin
            //TaskCleanFolder(lvSysPurge.Items[i], TPath.GetTempPath, '*.*', True);
            TaskCleanFolder(lvSysPurge.Items[i], GetEnvironmentVariable('tmp'), '*.*', True, True);
            TaskCleanFolder(lvSysPurge.Items[i], GetEnvironmentVariable('temp'), '*.*', True, True);
         end;

         // %SystemRoot%\Temp ---------------------------------------------------------------------
         if lvSysPurge.Items[i].Caption = 'Temp files (Windows)' then
         begin
            if IsAppElevated then
               TaskCleanFolder(lvSysPurge.Items[i], TPath.Combine(GetEnvironmentVariable('SystemRoot'), 'Temp'), '*.*', True, True);
         end;

         // %SystemRoot%\SoftwareDistribution\Download
         if lvSysPurge.Items[i].Caption = 'Windows Update cache' then
         begin
            if IsAppElevated then
            begin
               if GetServiceState('wuauserv') <> SERVICE_STOPPED then
               begin
                  if not StopServiceAndWait('wuauserv', 10000) then
                     exit;
               end;
               TaskCleanFolder(lvSysPurge.Items[i], TPath.Combine(GetEnvironmentVariable('SystemRoot'), 'SoftwareDistribution\Download'), '*.*', True, True);
               ServiceControl('wuauserv', 0); // restart
            end;
         end;
      end;

      // Windows Registry =========================================================================
      if grp.Header = 'Microsoft Windows Registry' then
      begin

         // MRU list: Run
            if lvSysPurge.Items[i].Caption = 'MRU list: Run' then
            begin
               RegDeleteAllValues(HKEY_CURRENT_USER, '\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU', False);

               replace with task, count deleted items
            end;

         // Shared DLL's
         if IsAppElevated then
            if lvSysPurge.Items[i].Caption = 'Shared DLL''s' then
               TaskCleanRegistryMissingDLLFiles(lvSysPurge.Items[i], HKEY_LOCAL_MACHINE, 'Software\Microsoft\Windows\CurrentVersion\SharedDLLs');
      end;

   end;
end;

//-------------------------------------------------------------------------------------------------
// SetTaskProgress  (count size of files)
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
// SetTaskProgress (count files/items)
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
procedure TfrmSysPurge.TaskCleanFolder(item: TListItem; const Path, Mask: string; Recursive, DeleteFolders: Boolean);
var
   DeletedBytes : Int64;
   FileSize     : Int64;
   Files        : TStringDynArray;
   Folders      : TStringDynArray;
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

   // delete files
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

   // --- delete folders ---
   if DeleteFolders and Recursive then
   begin
      try
         Folders:=TDirectory.GetDirectories(Path, '*', TSearchOption.soAllDirectories);
      except
         Folders:=nil;
      end;

      // reverse order = deepest folders first
      for i := High(Folders) downto 0 do
      begin
         try
            TDirectory.Delete(Folders[i], False); // False = non-recursive, must be empty
         except
            // skip if not empty or access denied
         end;
      end;
   end;

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

//-------------------------------------------------------------------------------------------------
// lvSysPurge: CustomDrawSubItem
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
   lvCanvas : TCanvas;
   Text     : string;
begin
   // Draw ProGressBar on column 3 (sub-item 2)
   if SubItem <> 2 then Exit;

   DefaultDraw := False;
   lvCanvas := Sender.Canvas;

   // Retrieve the exact subitem bounding rect from the listview
   R.Top  := SubItem;
   R.Left := LVIR_BOUNDS;
   SendMessage(Sender.Handle, LVM_GETSUBITEMRECT, WPARAM(Item.Index), LPARAM(@R));

   // Shrink for visual padding
   InflateRect(R, -PADDING_H, -PADDING_V);

   Progress := Integer(NativeInt(Item.Data));   // 0..100

   // -- Background --
   lvCanvas.Brush.Color := COLOR_BG;
   lvCanvas.Brush.Style := bsSolid;
   lvCanvas.FillRect(R);

   // -- Filled portion --
   if Progress > 0 then
   begin
      FillRect := R;
      FillW := Round((R.Width) * Progress / 100);
      FillRect.Right := FillRect.Left + FillW;

      if Progress >= 100 then
         lvCanvas.Brush.Color := COLOR_FILL_DONE
      else
         lvCanvas.Brush.Color := COLOR_FILL_ACTIVE;

      lvCanvas.Brush.Style := bsSolid;
      lvCanvas.FillRect(FillRect);
   end;

   // -- Border --
   lvCanvas.Brush.Style := bsClear;
   lvCanvas.Pen.Color   := COLOR_BORDER;
   lvCanvas.Rectangle(R);

   // -- Percentage label, centred --
   if Progress > 0 then
   begin
      Text := IntToStr(Progress) + '%';
      lvCanvas.Brush.Style := bsClear;
      lvCanvas.Font.Color  := clBlack;
      lvCanvas.Font.Size   := 8;
      DrawText(lvCanvas.Handle, PChar(Text), -1, R, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
   end;
end;

//-------------------------------------------------------------------------------------------------
// toolBtnPurge: onClick
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
