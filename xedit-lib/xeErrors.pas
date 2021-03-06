unit xeErrors;

interface

uses
  Classes,
  //xedit units
  wbInterface,
  // xelib units
  xeMeta;

type
  TErrorTypeID = ( erUnknown, erITM, erITPO, erUDR, erUES, erURR, erUER );
  TErrorType = record
    id: TErrorTypeID;
    shortName: string[4];
    longName: string[32];
    expr: string[128];
  end;
  TRecordError = class
  public
    &type: TErrorType;
    signature: TwbSignature;
    formID: integer;
    name: string;
    path: string;
    data: string;
    constructor Create(rec: IwbMainRecord; id: TErrorTypeID); overload;
    constructor Create(rec: IwbMainRecord; id: TErrorTypeID;
      error: string); overload;
    constructor Create(rec: IwbMainRecord; element: IwbElement;
      error: string); overload;
  end;
  TErrorCheckThread = class(TThread)
  protected
    procedure Execute; override;
  end;

  function CheckForErrors(_id: Cardinal): WordBool; cdecl;
  function GetErrorThreadDone: WordBool; cdecl;
  function GetErrors(str: PWideChar; len: Integer): WordBool; cdecl;
  function GetErrorString(_id: Cardinal; error: PWideChar; len: Integer): WordBool; cdecl;

const
  ErrorTypes: array[0..6] of TErrorType = (
    (id: erUnknown; shortName: 'UNK'; longName: 'Unknown'; expr: ''),
    (id: erITM; shortName: 'ITM'; longName: 'Identical to Master'; expr: ''),
    (id: erITPO; shortName: 'ITPO'; longName: 'Identical to Previous Override';
      expr: ''),
    (id: erUDR; shortName: 'UDR'; longName: 'Undelete and Disable Reference';
      expr: 'Record marked as deleted but contains: (\w+)'),
    (id: erUES; shortName: 'UES'; longName: 'Unexpected Subrecord';
      expr: 'Error: Record ([a-zA-Z_]+) contains unexpected \(or out of order\) subrecord (\w+)'),
    (id: erURR; shortName: 'URR'; longName: 'Unresolved Reference';
      expr: '\[([0-9A-F]+)\] \< Error: Could not be resolved \>'),
    (id: erUER; shortName: 'UER'; longName: 'Unexpected Reference';
      expr: 'Found a ([a-zA-Z_]+) reference, expected: (\w+)')
  );

implementation

uses
  SysUtils, Masks, RegularExpressions,
  // mte units
  mteConflict,
  // xelib units
  xeMessages,
  // library units
  SuperObject;

var
  errors: TList;
  bErrorCheckThreadDone: Boolean;
  elementToCheck: IwbElement;


{******************************************************************************}
{ ERROR CHECKING
  Methods for checking for errors.
}
{******************************************************************************}

procedure CheckForSubrecordErrors(rec, lastRecord: IwbMainRecord);  
var
  error: String;  
  errorObj: TRecordError;      
begin
  error := rec.GetSubRecordErrors;
  if error <> '' then begin
    errorObj := TRecordError.Create(rec, erUES, Error);
    errorObj.Data := Error;
    errors.Add(errorObj);
  end;
end;  

procedure CheckForIdenticalErrors(rec, lastRecord: IwbMainRecord);      
var
  errorObj: TRecordError; 
begin
  if rec.IsMaster then exit;
  if Assigned(rec.ChildGroup) and (rec.ChildGroup.ElementCount > 0) then exit;
  if IsITM(rec) then begin
    errorObj := TRecordError.Create(rec, erITM);
    errors.Add(errorObj);
  end
  else if IsITPO(rec) then begin
    errorObj := TRecordError.Create(rec, erITPO);
    errors.Add(errorObj);
  end;
end;

function NativeCheckForErrors(element: IwbElement; lastRecord: IwbMainRecord): IwbMainRecord;
var
  rec: IwbMainRecord;
  error: String;                   
  errorObj: TRecordError;
  container: IwbContainerElementRef;
  i: Integer;
begin
  // special main record error checks (ITM, ITPO, UES)
  if Supports(element, IwbMainRecord, rec) then begin
    CheckForSubrecordErrors(rec, lastRecord);
    CheckForIdenticalErrors(rec, lastRecord);
  end;

  // general error checking                   
  error := element.Check;
  if error <> '' then begin
    Result := element.ContainingMainRecord;
    if Assigned(Result) then begin
      if (Result <> LastRecord) then
        AddMessage(Format('  %s', [Result.Name]));
      errorObj := TRecordError.Create(Result, element, error);
      errors.Add(errorObj);
    end;
    AddMessage(Format('  %s -> %s', [element.Path, error]));
  end;
  
  // recursion
  if Supports(element, IwbContainerElementRef, container) then
    for i := Pred(container.ElementCount) downto 0 do
      Result := NativeCheckForErrors(container.Elements[i], Result);
end;

procedure TErrorCheckThread.Execute;
begin
  NativeCheckForErrors(elementToCheck, nil);
  bErrorCheckThreadDone := true;
end;

function CheckForErrors(_id: Cardinal): WordBool; cdecl;
var
  element: IwbElement;
begin
  Result := false;
  try
    if not bErrorCheckThreadDone then
      raise Exception.Create('You''re currently checking a plugin for errors.');
    errors := TList.Create;
    bErrorCheckThreadDone := False;
    if Supports(Resolve(_id), IwbElement, element) then begin
      elementToCheck := element;
      TErrorCheckThread.Create;
      Result := true;
    end;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetErrorThreadDone: WordBool; cdecl;
begin
  Result := bErrorCheckThreadDone;
end;

function GetErrors(str: PWideChar; len: Integer): WordBool; cdecl;
var
  i: Integer;      
  obj, childObj: ISuperObject;
  error: TRecordError;
begin
  Result := false;
  try
    obj := SO;
    obj.O['errors'] := SA([]);
    for i := 0 to Pred(errors.Count) do begin
      error := TRecordError(errors[i]);
      childObj := SO;
      childObj.I['group'] := Ord(error.&type.id);
      childObj.S['signature'] := string(error.signature);
      childObj.I['form_id'] := error.formID;
      childObj.S['name'] := error.name;
      if error.path <> '' then
        childObj.S['path'] := error.path;
      if error.data <> '' then
        childObj.S['data'] := error.data;
      obj.A['errors'].Add(childObj);
    end;
    StrLCopy(str, PWideChar(WideString(obj.AsJSon)), len);
    errors.Free;
    Result := true;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetErrorString(_id: Cardinal; error: PWideChar; len: Integer): WordBool; cdecl;
var
  element: IwbElement;
begin
  Result := false;
  try
    if Supports(Resolve(_id), IwbElement, element) then begin
      StrLCopy(error, PWideChar(WideString(element.Check)), len);
      Result := true;
    end;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function MatchesError(error: string; errorID: TErrorTypeID;
  i1, i2: Integer; var &type: TErrorType; var data: string): boolean;
var
  errorType: TErrorType;
  regex: TRegex;
  match: TMatch;
begin
  errorType := ErrorTypes[Ord(errorID)];
  regex := TRegex.Create(string(errorType.expr));
  match := regex.Match(error);
  Result := match.success;

  // if the expression matches the error, use its type and
  // parse data from regex groups
  if match.success then begin
    &type := errorType;
    if i1 > 0 then begin
      data := match.Groups.Item[i1].Value;
      if i2 > 0 then
        data := data + ',' + match.Groups.Item[i2].Value;
    end;
  end;
end;

procedure ParseError(error: string; var &type: TErrorType;
  var data: string);
begin
  // test errors with regex expressions, and if they match use
  // their type and parse data from the correct regex groups
  if MatchesError(error, erUDR, 1, 0, &type, data)
  or MatchesError(error, erUES, 2, 0, &type, data)
  or MatchesError(error, erURR, 1, 0, &type, data)
  or MatchesError(error, erUER, 1, 2, &type, data) then
    exit;

  // error unknown
  &type := ErrorTypes[Ord(erUnknown)];
  data := error;
end;

{ TRecordError }
constructor TRecordError.Create(rec: IwbMainRecord; id: TErrorTypeID);
begin
  signature := rec.signature;
  formID := rec.FixedFormID;
  name := rec.Name;
  &type := ErrorTypes[Ord(id)];
end;

constructor TRecordError.Create(rec: IwbMainRecord; id: TErrorTypeID;
  error: string);
begin
  signature := rec.signature;
  formID := rec.FixedFormID;
  name := rec.Name;
  &type := ErrorTypes[Ord(id)];
  data := error;
end;

constructor TRecordError.Create(rec: IwbMainRecord; element: IwbElement;
  error: string);
begin
  signature := rec.signature;
  formID := rec.FixedFormID;
  name := rec.Name;
  path := element.Path;
  ParseError(error, &type, data);
end;


initialization
  bErrorCheckThreadDone := true;

end.
