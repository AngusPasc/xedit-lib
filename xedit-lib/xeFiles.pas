unit xeFiles;

interface

  function NewFile(filename: PAnsiChar): Cardinal; StdCall;
  function FileByIndex(index: Integer): Cardinal; StdCall;
  function FileByLoadOrder(load_order: Integer): Cardinal; StdCall;
  function FileByName(name: PAnsiChar): Cardinal; StdCall;
  function FileByAuthor(author: PAnsiChar): Cardinal; StdCall;
  function GetElementFile(_id: Cardinal): Cardinal; StdCall;
  function SaveFile(_id: Cardinal): WordBool; StdCall;
  function GetFileNames(fileNames: PWideChar; len: Integer): WordBool; StdCall;

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
{ FILE HANDLING
  Methods for handling loaded files.
}
{******************************************************************************}

function NewFile(filename: PAnsiChar): Cardinal; StdCall;
var
  LoadOrder : Integer;
  _file: IwbFile;
  filePath: String;
begin
  Result := 0;
  try
    // fail if the file already exists
    filePath := wbDataPath + string(filename);
    if FileExists(filePath) then
      raise Exception.Create(Format('File with name %s already exists.', [filename]));

    // get load order for new file
    LoadOrder := 0;
    if Length(Files) > 0 then
      LoadOrder := Files[High(Files)].LoadOrder + 1;

    // fail if maximum load order reached
    if LoadOrder > 254 then
      raise Exception.Create('Maximum plugin count of 254 reached.');

    // create new file
    _file := wbNewFile(filePath, LoadOrder);
    SetLength(Files, Succ(Length(Files)));
    Files[High(Files)] := _file;
    _file._AddRef;

    // store the file and return the result
    Result := Store(_file);
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function FileByIndex(index: Integer): Cardinal; StdCall;
begin
  Result := 0;
  try
     Result := Store(Files[index]);
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function FileByLoadOrder(load_order: Integer): Cardinal; StdCall;
var
  i: Integer;
begin
  Result := 0;
  try
    for i := Low(Files) to High(Files) do
      if Files[i].LoadOrder = load_order then begin
        Result := Store(Files[i]);
        exit;
      end;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function FileByName(name: PAnsiChar): Cardinal; StdCall;
var
  i: Integer;
begin
  Result := 0;
  try
    for i := Low(Files) to High(Files) do
      if Files[i].FileName = string(name) then begin
        Result := Store(Files[i]);
        exit;
      end;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function FileByAuthor(author: PAnsiChar): Cardinal; StdCall;
var
  i: Integer;
begin
  Result := 0;
  try
    for i := Low(Files) to High(Files) do
      if Files[i].Header.ElementEditValues['Author'] = string(author) then begin
        Result := Store(Files[i]);
        exit;
      end;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetElementFile(_id: Cardinal): Cardinal; StdCall;
var
  element: IwbElement;
begin
  Result := 0;
  try
    if Supports(Resolve(_id), IwbElement, element) then
      Result := Store(element._File);
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function SaveFile(_id: Cardinal): WordBool; StdCall;
var
  _file: IwbFile;
  FileStream: TFileStream;
  path: String;
begin
  Result := false;
  try
    if Supports(Resolve(_id), IwbFile, _file) then begin
      path := wbDataPath + _file.FileName + '.save';
      FileStream := TFileStream.Create(path, fmCreate);
      try
        _file.WritetoStream(FileStream, false);
        // TODO: Need to handle renaming when library is finalized
      finally
        FileStream.Free;
      end;
    end;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetFileNames(fileNames: PWideChar; len: Integer): WordBool; StdCall;
var
  s: String;
  i: Integer;
begin
  Result := false;
  try
    s := '';
    for i := Low(Files) to High(Files) do
      s := s + Files[i].FileName + #13;
    StrLCopy(fileNames, PWideChar(WideString(Trim(s))), len);
    Result := true;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

end.
