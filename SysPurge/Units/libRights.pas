unit libRights;

interface

function IsAppElevated: Boolean;

implementation

uses
  Winapi.Windows, Winapi.ShellAPI;

function IsAppElevated: Boolean;
var
   hToken: THandle;
   Elevation: TTokenElevation;
   ReturnLength: DWORD;
begin
   Result:=False;
   if OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, hToken) then
   begin
      try
         if GetTokenInformation(hToken, TokenElevation, @Elevation, SizeOf(Elevation), ReturnLength) then
            Result:=Elevation.TokenIsElevated <> 0;
      finally
         CloseHandle(hToken);
      end;
   end;
end;

end.
