unit xeElementValues;

interface

  function Name(_id: Integer; str: PWideChar; len: Integer): WordBool; StdCall;
  function EditorID(_id: Integer; str: PWideChar; len: Integer): WordBool; StdCall;
  function Signature(_id: Integer; str: PWideChar; len: Integer): WordBool; StdCall;
  function ShortName(_id: Integer; str: PWideChar; len: Integer): WordBool; StdCall;
  function SortKey(_id: Integer; str: PWideChar; len: Integer): WordBool; StdCall;
  function ElementType(_id: Integer; str: PWideChar; len: Integer): WordBool; StdCall;
  function DefType(_id: Integer; str: PWideChar; len: Integer): WordBool; StdCall;
  function GetValue(_id: Integer; path, str: PWideChar; len: Integer): WordBool; StdCall;
  function SetValue(_id: Integer; path, value: PWideChar): WordBool; StdCall;
  function GetIntValue(_id: Integer; path: PWideChar; value: Integer): WordBool; StdCall;
  function SetIntValue(_id: Integer; path: PWideChar; value: Integer): WordBool; StdCall;
  function GetUIntValue(_id: Integer; path: PWideChar; value: Cardinal): WordBool; StdCall;
  function SetUIntValue(_id: Integer; path: PWideChar; value: Cardinal): WordBool; StdCall;
  function GetFloatValue(_id: Integer; path: PWideChar; value: Double): WordBool; StdCall;
  function SetFloatValue(_id: Integer; path: PWideChar; value: Double): WordBool; StdCall;

implementation

uses
  Classes, SysUtils, Variants,
  // mte modules
  mteHelpers,
  // xedit modules
  wbInterface, wbImplementation,
  // xelib modules
  xeMessages, xeMeta;


function Name(_id: Integer; str: PWideChar; len: Integer): WordBool; StdCall;
var
  element: IwbElement;
begin
  Result := false;
  if Supports(Resolve(_id), IwbElement, element) then begin
    StrLCopy(str, PWideChar(WideString(element.Name)), len);
    Result := true;
  end;
end;

function EditorID(_id: Integer; str: PWideChar; len: Integer): WordBool; StdCall;
var
  rec: IwbMainRecord;
begin
  Result := false;
  if Supports(Resolve(_id), IwbMainRecord, rec) then begin
    StrLCopy(str, PWideChar(WideString(rec.EditorID)), len);
    Result := true;
  end;
end;

function Signature(_id: Integer; str: PWideChar; len: Integer): WordBool; StdCall;
var
  rec: IwbRecord;
begin
  Result := false;
  if Supports(Resolve(_id), IwbRecord, rec) then begin
    StrLCopy(str, PWideChar(WideString(rec.Signature)), len);
    Result := true;
  end;
end;

function ShortName(_id: Integer; str: PWideChar; len: Integer): WordBool; StdCall;
var
  element: IwbElement;
begin
  Result := false;
  if Supports(Resolve(_id), IwbElement, element) then begin
    StrLCopy(str, PWideChar(WideString(element.ShortName)), len);
    Result := true;
  end;
end;

function SortKey(_id: Integer; str: PWideChar; len: Integer): WordBool; StdCall;
var
  element: IwbElement;
begin
  Result := false;
  if Supports(Resolve(_id), IwbElement, element) then begin
    StrLCopy(str, PWideChar(WideString(element.SortKey[false])), len);
    Result := true;
  end;
end;

function etToString(et: Integer): String;
begin
  case Ord(et) of
    Ord(etFile): Result := 'etFile';
    Ord(etMainRecord): Result := 'etMainRecord';
    Ord(etMainRecord): Result := 'etMainRecord';
    Ord(etGroupRecord): Result := 'etGroupRecord';
    Ord(etSubRecord): Result := 'etSubRecord';
    Ord(etSubRecordStruct): Result := 'etSubRecordStruct';
    Ord(etSubRecordArray): Result := 'etSubRecordArray';
    Ord(etSubRecordUnion): Result := 'etSubRecordUnion';
    Ord(etArray): Result := 'etArray';
    Ord(etStruct): Result := 'etStruct';
    Ord(etValue): Result := 'etValue';
    Ord(etFlag): Result := 'etFlag';
    Ord(etStringListTerminator): Result := 'etStringListTerminator';
    Ord(etUnion): Result := 'etUnion';
    Ord(etStructChapter): Result := 'etStructChapter';
  end;
end;

function ElementType(_id: Integer; str: PWideChar; len: Integer): WordBool; StdCall;
var
  element: IwbElement;
  s: String;
begin
  Result := false;
  if Supports(Resolve(_id), IwbElement, element) then begin
    s = etToString(element.ElementType);
    StrLCopy(str, PWideChar(WideString(s)), len);
    Result := true;
  end;
end;

function dtToString(dt: Integer): String;
begin
  case Ord(dt) of
    Ord(dtRecord): Result := 'dtRecord';
    Ord(dtSubRecord): Result := 'dtSubRecord';
    Ord(dtSubRecordArray): Result := 'dtSubRecordArray';
    Ord(dtSubRecordStruct): Result := 'dtSubRecordStruct';
    Ord(dtSubRecordUnion): Result := 'dtSubRecordUnion';
    Ord(dtString): Result := 'dtString';
    Ord(dtLString): Result := 'dtLString';
    Ord(dtLenString): Result := 'dtLenString';
    Ord(dtByteArray): Result := 'dtByteArray';
    Ord(dtInteger): Result := 'dtInteger';
    Ord(dtIntegerFormater): Result := 'dtIntegerFormater';
    Ord(dtIntegerFormaterUnion): Result := 'dtIntegerFormaterUnion';
    Ord(dtFlag): Result := 'dtFlag';
    Ord(dtFloat): Result := 'dtFloat';
    Ord(dtArray): Result := 'dtArray';
    Ord(dtStruct): Result := 'dtStruct';
    Ord(dtUnion): Result := 'dtUnion';
    Ord(dtEmpty): Result := 'dtEmpty';
    Ord(dtStructChapter): Result := 'dtStructChapter';
  end;
end;

function DefType(_id: Integer; str: PWideChar; len: Integer): WordBool; StdCall;
var
  element: IwbElement;
  s: String;
begin
  Result := false;
  if Supports(Resolve(_id), IwbElement, element) then begin
    s := dtToString(element.ValueDef.DefType);
    StrLCopy(str, PWideChar(WideString(s)), len);
    Result := true;
  end;
end;

function GetValue(_id: Integer; path, str: PWideChar; len: Integer): WordBool; StdCall;
var
  e: IInterface;
  container: IwbContainerElementRef;
  element: IwbElement;
  s: string;
begin
  Result := false;
  e := Resolve(_id);
  if Supports(e, IwbContainerElementRef, container) then begin
    s := container.ElementEditValues[string(path)];
    StrLCopy(str, PWideChar(WideString(s)), len);
    Result := true;
  end
  else if Supports(e, IwbElement, element) then begin
    s := element.EditValue;
    StrLCopy(str, PWideChar(WideString(s)), len);
    Result := true;
  end;
end;

function SetValue(_id: Integer; path, value: PWideChar): WordBool; StdCall;
var
  e: IInterface;
  container: IwbContainerElementRef;
  element: IwbElement;
begin
  Result := false;
  e := Resolve(_id);
  if Supports(e, IwbContainerElementRef, container) then begin
    container.ElementEditValues[string(path)] := value;
    Result := true;
  end
  else if Supports(e, IwbElement, element) then begin
    element.EditValue := value;
    Result := true;
  end;
end;

function GetNativeValue(_id: Integer; path: PWideChar): Variant;
var
  e: IInterface;
  container: IwbContainerElementRef;
  element: IwbElement;
begin
  Result := nil;
  e := Resolve(_id);
  if Supports(e, IwbContainerElementRef, container) then
    Result := container.ElementNativeValues[string(path)]
  else if Supports(e, IwbElement, element) then
    Result := element.NativeValue;
end;

function SetNativeValue(_id: Integer; path: PWideChar; value: Variant): WordBool;
var
  e: IInterface;
  container: IwbContainerElementRef;
  element: IwbElement;
begin
  Result := false;
  e := Resolve(_id);
  if Supports(e, IwbContainerElementRef, container) then
    container.ElementNativeValues[string(path)] := value
  else if Supports(e, IwbElement, element) then
    element.NativeValue := value;
  Result := true;
end;

function GetIntValue(_id: Integer; path: PWideChar; value: Integer): WordBool; StdCall;
begin
  Result := false;
  try
    value := GetNativeValue(_id, path);
    Result := true;
  except
    on x: Exception do
      AddMessage('GetIntValue: '+x.Message);
  end;
end;

function SetIntValue(_id: Integer; path: PWideChar; value: Integer): WordBool; StdCall;
begin
  Result := false;
  try
    Result := SetNativeValue(_id, path, value);
  except
    on x: Exception do
      AddMessage('SetIntValue: '+x.Message);
  end;
end;

function GetUIntValue(_id: Integer; path: PWideChar; value: Cardinal): WordBool; StdCall;
begin
  Result := false;
  try
    value := GetNativeValue(_id, path);
    Result := true;
  except
    on x: Exception do
      AddMessage('GetUIntValue: '+x.Message);
  end;
end;

function SetUIntValue(_id: Integer; path: PWideChar; value: Cardinal): WordBool; StdCall;
begin
  Result := false;
  try
    Result := SetNativeValue(_id, path, value);
  except
    on x: Exception do
      AddMessage('SetUIntValue: '+x.Message);
  end;
end;

function GetFloatValue(_id: Integer; path: PWideChar; value: Double): WordBool; StdCall;
begin
  Result := false;
  try
    value := GetNativeValue(_id, path);
    Result := true;
  except
    on x: Exception do
      AddMessage('GetFloatValue: '+x.Message);
  end;
end;

function SetFloatValue(_id: Integer; path: PWideChar; value: Double): WordBool; StdCall;
begin
  Result := false;
  try
    Result := SetNativeValue(_id, path, value);
  except
    on x: Exception do
      AddMessage('SetFloatValue: '+x.Message);
  end;
end;

end.
