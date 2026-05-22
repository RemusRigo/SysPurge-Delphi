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
         procedure SetActionProgress(Item: TListItem; Progress: Integer);
      public
   end;

var
  frmSysPurge: TfrmSysPurge;

implementation

{$R *.dfm}

uses
   AppData;

const
   LVIR_BOUNDS        = 0;

   // ListView messages
   LVM_FIRST          = $1000; // First
   LVM_GETSUBITEMRECT = $1038; // Get SubItem Rect
   LVM_REDRAWITEMS    = $1015;

//-------------------------------------------------------------------------------------------------
// Resize columns
procedure TfrmSysPurge.ResizeColumns;
begin
   lvSysPurge.Columns[0].Width:=-1;
   lvSysPurge.Columns[1].Width:=Self.ClientWidth-lvSysPurge.Columns[0].Width-175;
end;

//-------------------------------------------------------------------------------------------------
// Build ListView items with groups
procedure TfrmSysPurge.BuildOptions;
var
  grp : TListGroup;
  item: TListItem;
begin
   // Microsoft Windows
   grp:=lvSysPurge.Groups.Add;
   grp.Header:='Microsoft Windows';

   // Temp files
   item:=lvSysPurge.Items.Add;
   item.Checked:=True;
   item.Caption:='Temp files';
   item.SubItems.Add('');
   item.Data:=Pointer(NativeInt(0));
   item.GroupID:=grp.GroupID;

   // %SystemRoot%\prefetch\*.pf
   item:=lvSysPurge.Items.Add;
   item.Caption:= 'Prefetch files';
   item.SubItems.Add('');
   item.Data:=Pointer(NativeInt(0));
   item.GroupID:=grp.GroupID;

   // resize columns
   ResizeColumns;
end;

procedure TfrmSysPurge.SetActionProgress(Item: TListItem; Progress: Integer);
begin
   Item.Data:=Pointer(NativeInt(EnsureRange(Progress, 0, 100)));
   // Repaint only this specific row — cheap and flicker-free
   SendMessage(lvSysPurge.Handle, LVM_REDRAWITEMS, WPARAM(Item.Index), LPARAM(Item.Index));
   lvSysPurge.Update;
   Application.ProcessMessages;
end;

//-------------------------------------------------------------------------------------------------
// Process Actions
procedure TfrmSysPurge.ProcessActions;
var
  i, g: Integer;
  grp: TListGroup;
begin
   for i:=0 to lvSysPurge.Items.Count - 1 do
   begin
      if lvSysPurge.Items[i].Checked then
      begin
         grp:=nil;

         for g:=0 to lvSysPurge.Groups.Count - 1 do
            if lvSysPurge.Groups[g].GroupID = lvSysPurge.Items[i].GroupID then
            begin
               grp:=lvSysPurge.Groups[g];
               Break;
            end;

      if Assigned(grp) then
      begin
        if (grp.Header = 'Microsoft Windows' )then
        begin
           if (lvSysPurge.Items[i].Caption = 'Temp files') then
           begin
              // delete files from %temp%
              // delete files from %SystemRoot%\Temp
           end;

        end;
      end
      else
        // no group defined
      end;
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
   if SubItem <> 1 then Exit;

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
   ProcessActions;
end;

end.
