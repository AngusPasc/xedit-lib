unit xeGroups;

interface

  function HasGroup(_id: Cardinal; sig: string; _res: PWordBool): WordBool; StdCall;
  function AddGroup(_id: Cardinal; sig: string; _res: PCardinal): WordBool; StdCall;
  function GetGroups(_id: Cardinal; groups: PWideChar; len: Integer): WordBool; StdCall;
  function GetChildGroup(_id: Cardinal; _res: PCardinal): WordBool; StdCall;

implementation

uses
  Classes, SysUtils,
  // mte modules
  mteHelpers,
  // xedit modules
  wbInterface, wbImplementation,
  // xelib modules
  xeMessages, xeMeta, xeSetup;


{******************************************************************************}
{ GROUP HANDLING
  Methods for handling groups.
}
{******************************************************************************}

function HasGroup(_id: Cardinal; sig: string; _res: PWordBool): WordBool; StdCall;
var
  _file: IwbFile;
begin
  Result := false;
  try
    if Supports(Resolve(_id), IwbFile, _file) then begin
      _res^ := _file.HasGroup(TwbSignature(sig));
      Result := true;
    end;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function AddGroup(_id: Cardinal; sig: string; _res: PCardinal): WordBool; StdCall;
var
  _file: IwbFile;
  _sig: TwbSignature;
begin
  Result := false;
  try
    if Supports(Resolve(_id), IwbFile, _file) then begin
      _sig := TwbSignature(sig);
      if _file.HasGroup(_sig) then
        _res^ := Store(_file.GroupBySignature[_sig])
      else
        _res^ := Store(_file.Add(sig));
      Result := true;
    end;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetGroups(_id: Cardinal; groups: PWideChar; len: Integer): WordBool; StdCall;
var
  _file: IwbFile;
  s: String;
  i: Integer;
begin
  Result := false;
  try
    if Supports(Resolve(_id), IwbFile, _file) then begin
      s := '';
      for i := 1 to _file.ElementCount do
        s := s + string(IwbGroupRecord(_file.Elements[i]).Signature) + #13;
      StrLCopy(groups, PWideChar(s), len);
      Result := true;
    end;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

end.
