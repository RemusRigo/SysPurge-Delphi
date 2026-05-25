//-------------------------------------------------------------------------------------------------
// libReg - Registry functions
//    © 2026 Remus Rigo
//       v1.0 2026-05-08
//-------------------------------------------------------------------------------------------------
unit libReg;

interface

uses
  Windows, Registry;

function RegReadBool  (Root: HKEY; const Path, Name: string): Boolean;
function RegWriteBool (Root: HKEY; const Path, Name: string; Value: Boolean): Boolean;

function RegReadDWord  (Root: HKEY; const Path, Name: string): Integer;
function RegWriteDWord (Root: HKEY; const Path, Name: string; Value: Cardinal): Boolean;

function RegReadSZ  (Root: HKEY; const Path, Name: string): string;
function RegWriteSZ (Root: HKEY; const Path, Name, Value: string): Boolean;

function RegValueExists(root: HKEY; const path, valueName : string): Boolean;
function RegDeleteValue (Root: HKEY; const Path, Name: string): Boolean;

implementation

//-------------------------------------------------------------------------------------------------
// Read Boolean
function RegReadBool(root: HKEY; const path, name: string): Boolean;
var
   reg: TRegistry;
begin
   result := False;
   reg := TRegistry.Create(KEY_READ);
   try
      reg.RootKey := Root;
      if reg.OpenKeyReadOnly(path) then
      try
         if reg.ValueExists(name) then
            result := reg.ReadInteger(name) <> 0;
      finally
         reg.CloseKey;
      end;
   finally
      reg.Free;
   end;
end;

//--------------------------------------------------------------------------------------------------
// Write Boolean
function RegWriteBool(Root: HKEY; const Path, Name: string; Value: Boolean): Boolean;
var
   reg: TRegistry;
begin
   result := False;
   reg := TRegistry.Create(KEY_WRITE);
   try
      reg.RootKey := Root;
      if Reg.OpenKey(path, True) then
      try
         Reg.WriteInteger(Name, Ord(Value));
         Result := True;
      finally
        Reg.CloseKey;
      end;
   finally
      reg.Free;
   end;
end;

//--------------------------------------------------------------------------------------------------
// Read DWord | Integer
function RegReadDWord(root: HKEY; const path, name: string): Integer;
var
   reg: TRegistry;
begin
   result := 0;
   reg := TRegistry.Create(KEY_READ);
   try
      reg.RootKey := Root;
      if reg.OpenKeyReadOnly(path) then
      try
         if reg.ValueExists(name) then
            result := Cardinal(reg.ReadInteger(Name));
      finally
         Reg.CloseKey;
      end;
   finally
      Reg.Free;
   end;
end;

//--------------------------------------------------------------------------------------------------
// Write DWord | Integer (Cardinal)
function RegWriteDWord(root: HKEY; const path, name: string; value: Cardinal): Boolean;
var
   reg: TRegistry;
begin
   result := False;
   reg := TRegistry.Create(KEY_WRITE);
   try
      reg.RootKey := Root;
      if reg.OpenKey(path, True) then
      try
         reg.WriteInteger(name, Integer(value));
         result := True;
      finally
         reg.CloseKey;
      end;
   finally
      reg.Free;
   end;
end;

//--------------------------------------------------------------------------------------------------
// Read SZ | String
function RegReadSZ(root: HKEY; const path, name: string): string;
var
   reg: TRegistry;
begin
   result := '';
   reg := TRegistry.Create(KEY_READ);
   try
      reg.RootKey := Root;
      if not Reg.OpenKeyReadOnly(Path) then Exit;
      try
        if not Reg.ValueExists(Name) then Exit;
        // Guard against type mismatch — only read REG_SZ values
        if reg.GetDataType(Name) in [rdString, rdExpandString] then
          result := Reg.ReadString(name);
      finally
         reg.CloseKey;
      end;
   finally
      reg.Free;
   end;
end;

//--------------------------------------------------------------------------------------------------
// Write SZ | String
function RegWriteSZ(root: HKEY; const path, name, value: string): Boolean;
var
   reg: TRegistry;
begin
   result := False;
   reg := TRegistry.Create(KEY_WRITE);
   try
      reg.RootKey := Root;
      if reg.OpenKey(path, True) then
      try
         reg.WriteString(name, value);
         result := True;
      finally
         reg.CloseKey;
      end;
   finally
      reg.Free;
   end;
end;

//--------------------------------------------------------------------------------------------------
// Check if value exists
function RegValueExists(root: HKEY; const path, valueName : string): Boolean;
var
   reg: TRegistry;
begin
   result := False;
   reg := TRegistry.Create(KEY_READ);
   try
      reg.RootKey := Root;
      if reg.OpenKeyReadOnly(path) then
      try
         result := Reg.ValueExists(valueName);
      finally
         reg.CloseKey;
      end;
   finally
      reg.Free;
   end;
end;

//--------------------------------------------------------------------------------------------------
// Delete value
function RegDeleteValue(root: HKEY; const path, name: string): Boolean;
var
   reg: TRegistry;
begin
   result := False;
   reg := TRegistry.Create(KEY_WRITE);
   try
      reg.RootKey := Root;
      if reg.OpenKey(Path, False) then
      try
        try
          reg.DeleteValue(name);
          result := True;
        except on E: ERegistryException do
          // Value didn't exist or access denied — Result stays False
        end;
      finally
        reg.CloseKey;
      end;
   finally
      reg.Free;
   end;
end;

end.
