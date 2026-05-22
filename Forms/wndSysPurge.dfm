object frmSysPurge: TfrmSysPurge
  Left = 0
  Top = 0
  Caption = 'frmSysPurge'
  ClientHeight = 575
  ClientWidth = 913
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnResize = FormResize
  TextHeight = 15
  object ToolBar1: TToolBar
    Left = 0
    Top = 0
    Width = 913
    Height = 29
    Caption = 'ToolBar1'
    TabOrder = 0
    object toolBtnPurge: TToolButton
      Left = 0
      Top = 0
      Hint = 'Purge'
      Caption = 'Purge'
      ImageIndex = 0
      ParentShowHint = False
      ShowHint = True
      OnClick = toolBtnPurgeClick
    end
  end
  object lvSysPurge: TListView
    Left = 0
    Top = 29
    Width = 913
    Height = 546
    Align = alClient
    Checkboxes = True
    Columns = <
      item
        Caption = 'Action'
        Width = 100
      end
      item
        Caption = 'Progress'
        Width = 100
      end>
    GridLines = True
    GroupView = True
    RowSelect = True
    TabOrder = 1
    ViewStyle = vsReport
    OnCustomDrawSubItem = lvSysPurgeCustomDrawSubItem
  end
end
