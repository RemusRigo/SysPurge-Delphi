unit libServices;

interface

uses
  WinSvc, Windows;

const
   SERVICE_STOPPED          = 1;
   SERVICE_START_PENDING    = 2;
   SERVICE_STOP_PENDING     = 3;
   SERVICE_RUNNING          = 4;
   SERVICE_CONTINUE_PENDING = 5;
   SERVICE_PAUSE_PENDING    = 6;
   SERVICE_PAUSED           = 7;

function ServiceControl(const ServiceName: string; Action: DWORD): Boolean;
function StopServiceAndWait(const ServiceName: string; TimeoutMs: DWORD = 10000): Boolean;
function GetServiceState(const ServiceName: string): DWORD;

implementation


function ServiceControl(const ServiceName: string; Action: DWORD): Boolean;
var
  hSCM, hService: SC_HANDLE;
  Status: TServiceStatus;
  Args: PChar;
begin
  Result := False;
  Args := nil;

  hSCM := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
  if hSCM = 0 then Exit;
  try
    hService := OpenService(hSCM, PChar(ServiceName), SERVICE_ALL_ACCESS);
    if hService = 0 then Exit;
    try
      case Action of
        SERVICE_CONTROL_STOP:
          Result := ControlService(hService, SERVICE_CONTROL_STOP, Status);
        0:
          Result := StartService(hService, 0, Args);
      end;
    finally
      CloseServiceHandle(hService);
    end;
  finally
    CloseServiceHandle(hSCM);
  end;
end;

function StopServiceAndWait(const ServiceName: string; TimeoutMs: DWORD = 10000): Boolean;
var
  hSCM, hService: SC_HANDLE;
  Status: TServiceStatus;
  StartTick: DWORD;
begin
  Result := False;

  hSCM := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
  if hSCM = 0 then Exit;
  try
    hService := OpenService(hSCM, PChar(ServiceName),
                  SERVICE_STOP or SERVICE_QUERY_STATUS);
    if hService = 0 then Exit;
    try
      // Send stop signal
      if not ControlService(hService, SERVICE_CONTROL_STOP, Status) then
        Exit;

      // Wait until stopped or timeout
      StartTick := GetTickCount;
      repeat
        Sleep(500);
        if not QueryServiceStatus(hService, Status) then Exit;
        if Status.dwCurrentState = SERVICE_STOPPED then
        begin
          Result := True;
          Exit;
        end;
      until (GetTickCount - StartTick) >= TimeoutMs;

    finally
      CloseServiceHandle(hService);
    end;
  finally
    CloseServiceHandle(hSCM);
  end;
end;

function GetServiceState(const ServiceName: string): DWORD;
var
  hSCM, hService: SC_HANDLE;
  Status: TServiceStatus;
begin
  Result := 0; // unknown

  hSCM := OpenSCManager(nil, nil, SC_MANAGER_CONNECT);
  if hSCM = 0 then Exit;
  try
    hService := OpenService(hSCM, PChar(ServiceName), SERVICE_QUERY_STATUS);
    if hService = 0 then Exit;
    try
      if QueryServiceStatus(hService, Status) then
        Result := Status.dwCurrentState;
    finally
      CloseServiceHandle(hService);
    end;
  finally
    CloseServiceHandle(hSCM);
  end;
end;

end.
