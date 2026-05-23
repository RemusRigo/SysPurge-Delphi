program SysPurge;

uses
  Vcl.Forms,
  wndSysPurge in 'Forms\wndSysPurge.pas' {frmSysPurge},
  wndAbout in 'Forms\wndAbout.pas' {frmAbout},
  AppData in 'Units\AppData.pas',
  libRights in 'Units\libRights.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmSysPurge, frmSysPurge);
  Application.CreateForm(TfrmAbout, frmAbout);
  Application.Run;
end.
