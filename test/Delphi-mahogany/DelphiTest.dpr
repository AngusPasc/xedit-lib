program DelphiTest;

{$APPTYPE CONSOLE}

uses
  ShareMem,
  SysUtils,
  maMain in 'lib\maMain.pas',
  txElementHandling in 'txElementHandling.pas',
  txFileHandling in 'txFileHandling.pas',
  txFileValues in 'txFileValues.pas',
  txElementValues in 'txElementValues.pas',
  txSetup in 'txSetup.pas',
  txMeta in 'txMeta.pas';

procedure BuildXETests;
begin
  TestFileHandling;
  TestFileValues;
  //TestElementHandling;
end;

procedure RunXETests;
var
  LogToConsole: TMessageProc;
begin
  // log messages to the console
  LogToConsole := procedure(msg: String)
    begin
      WriteLn(msg);
    end;

  // run the tests
  Initialize;
  LoadXEdit;
  RunTests(LogToConsole);
  Finalize;

  // report testing results
  WriteLn(' ');
  ReportResults(LogToConsole);
end;

begin
  try
    BuildXETests;
    RunXETests;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  ReadLn;
end.