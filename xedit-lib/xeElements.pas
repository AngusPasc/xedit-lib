unit xeElements;

interface

uses
  Classes, SysUtils,
  // xedit modules
  wbInterface, wbImplementation,
  // xelib modules
  xeMeta;

  // ELEMENT HANDLING
  function GetElement(_element: Cardinal; key: PAnsiChar): Cardinal; StdCall;
  function NewElement(_element: Cardinal; key: PAnsiChar): Cardinal; StdCall;
  function RemoveElement(_element: Cardinal; key: PAnsiChar): WordBool; StdCall;
  function ElementExists(_element: Cardinal; key: PAnsiChar): WordBool; StdCall;
  function ElementCount(_element: Cardinal): Cardinal; StdCall;
  function ElementAssigned(_element: Cardinal): Cardinal; StdCall;
  function Equals(_element, _element2: Cardinal): WordBool; StdCall;
  function IsMaster(_element: Cardinal): WordBool; StdCall;
  function IsInjected(_element: Cardinal): WordBool; StdCall;
  function IsOverride(_element: Cardinal): WordBool; StdCall;
  function IsWinningOverride(_element: Cardinal): WordBool; StdCall;

implementation

{******************************************************************************}
{ ELEMENT HANDLING
  Methods for handling elements: groups, records, and subrecords.
}
{******************************************************************************}

function ParseIndex(key: PAnsiChar): Integer;
begin
  Result := -1;
  if key[0] = '[' then
    Result := StrToInt(Copy(key, 2, Length(key) - 2));
end;

// Replaces ElementByName, ElementByPath, ElementByIndex, GroupBySignature, and
// ElementBySignature.  Supports indexed paths.
function GetElement(_element: Cardinal; key: PAnsiChar): Cardinal; StdCall;
var
  element: IInterface;
  _file: IwbFile;
  container: IwbContainerElementRef;
begin
  element := Resolve(_element);
  if Supports(element, IwbFile, _file) then
    // TODO: perhaps also by group name?
    Result := Store(_file.GroupBySignature(StringToSignature(key)))
  else if Supports(element, IwbContainerElementRef, container) then
    // TODO: adjust logic here so we can check indexed paths
    Result := Store(container.ElementByPath(key));
end;

// replaces ElementAssign, Add, AddElement, and InsertElement
function NewElement(_element: Cardinal; key: PAnsiChar): Cardinal; StdCall;
var
  element: IInterface;
  container: IwbContainerElementRef;
  keyIndex: Integer;
begin
  element := Resolve(_element);
  if Supports(element, IwbContainerElementRef, container) then begin
    // Use Add for files and groups
    if Supports(element, IwbFile) or Supports(element, IwbGroupRecord) then
      Result := Store(container.Add(string(key), true))
    else begin
      // no key means we're doing ElementAssign
      if (not Assigned(key)) or (Length(key) = 0) then
        Result := Store(container.Assign(HighInteger, nil, false))
      else begin
        keyIndex := ParseIndex(key);
        // use InsertElement if index was given, else use Add
        if keyIndex > -1 then
          Result := Store(container.InsertElement(keyIndex, nil))
        else
          Result := Store(container.Add(string(key), true));
      end;
    end;
  end;
end;

function RemoveElement(_element: Cardinal; key: PAnsiChar): WordBool; StdCall;
var
  element: IInterface;
begin
  element := Resolve(_element);
end;

// Replaces HasGroup and ElementExists
function ElementExists(_element: Cardinal; key: PAnsiChar): WordBool; StdCall;
var
  element: IInterface;
  _file: IwbFile;
  container: IwbContainerElementRef;
begin
  Result := false;
  element := Resolve(_element);
  if Supports(element, IwbFile, _file) then
    // TODO: perhaps also by group name?
    Result := _file.HasGroup(StrToSignature(key))
  else if Supports(element, IwbContainerElementRef, container) then
    // TODO: adjust logic here so we can check paths
    Result := container.ElementExists[string(key)];
end;

function ElementCount(_element: Cardinal): Cardinal; StdCall;
var
  element: IInterface;
  container: IwbContainerElementRef;
begin
  Result := -1;
  element := Resolve(_element);
  if Supports(element, IwbContainerElementRef, container) then
    Result := container.ElementCount;
end;

function ElementAssigned(_element: Cardinal): Cardinal; StdCall;
var
  element: IInterface;
begin
  element := Resolve(_element);
  Result := Assigned(element);
end;

function Equals(_element, _element2: Cardinal): WordBool; StdCall;
var
  element, element2: IInterface;
begin
  Result := false;
  if Supports(Resolve(_element), IwbElement, element) then
    if Supports(Resolve(_element2), IwbElement, element2) then
      Result := element.Equals(element2);
end;

function IsMaster(_element: Cardinal): WordBool; StdCall;
var
  element: IInterface;
  rec: IwbMainRecord;
begin
  Result := false;
  element := Resolve(_element);
  if Supports(element, IwbMainRecord, rec) then
    Result := rec.IsMaster;
end;

function IsInjected(_element: Cardinal): WordBool; StdCall;
var
  element: IInterface;
  rec: IwbMainRecord;
begin
  Result := false;
  element := Resolve(_element);
  if Supports(element, IwbMainRecord, rec) then
    Result := rec.IsInjected;
end;

function IsOverride(_element: Cardinal): WordBool; StdCall;
var
  element: IInterface;
  rec: IwbMainRecord;
begin
  Result := false;
  element := Resolve(_element);
  if Supports(element, IwbMainRecord, rec) then
    Result := not rec.IsMaster;
end;

// TODO: Determine if subrecord is winner
function IsWinningOverride(_element: Cardinal): WordBool; StdCall;
var
  element: IInterface;
begin
  Result := false;
  element := Resolve(_element);
  if Supports(element, IwbMainRecord, rec) then
    Result := not rec.IsWinningOverride;
end;

end.
