program TDSToPDB;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  PDBInterface in 'PDBInterface.pas',
  CVInfo in 'CVInfo.pas',
  Main in 'Main.pas',
  ThiscallInterceptor in 'ThiscallInterceptor.pas',
  Utils in 'Utils.pas',
  TDSInfo in 'TDSInfo.pas',
  TDSTypesConv in 'TDSTypesConv.pas',
  CVConst in 'CVConst.pas',
  TDSParser in 'TDSParser.pas',
  TD32ToPDBResources in 'TD32ToPDBResources.pas',
  TDSUtils in 'TDSUtils.pas',
  TDSSymbolsConv in 'TDSSymbolsConv.pas',
  Range in 'Range.pas';

begin
  try
    MainProc;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
