unit Options;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, VSoft.CommandLine.Options;

type
  TTDSToPDBOptions = class
  public type
    TOptionRec = record
      FakeName: string;
      Opt: IOptionDefinition;
      constructor Create(AFakeName: string; AOpt: IOptionDefinition);
    end;
    TSearchRec = class
      Path: string;
      Recursive: Boolean;
      constructor Create(APath: string; ARecursive: Boolean);
    end;
  public class var
    Options: TList<TOptionRec>;
    InputFile,
    OutputFile: string;
    SearchPaths: TObjectList<TSearchRec>;
    DCUSearchPaths: TList<string>;
    ShowHelp: Boolean;
    class constructor Create;
    class destructor Destroy;
    class procedure AddOption(AFakeName: string; AOpt: IOptionDefinition); static;
  end;

implementation

constructor TTDSToPDBOptions.TOptionRec.Create(AFakeName: string; AOpt: IOptionDefinition);
begin
  FakeName := AFakeName;
  Opt := AOpt;
end;

constructor TTDSToPDBOptions.TSearchRec.Create(APath: string; ARecursive: Boolean);
begin
  Path := APath;
  Recursive := ARecursive;
end;

class constructor TTDSToPDBOptions.Create;
begin
  SearchPaths := TObjectList<TSearchRec>.Create;
  DCUSearchPaths := TList<string>.Create;
  Options := TList<TOptionRec>.Create;
end;

class destructor TTDSToPDBOptions.Destroy;
begin
  FreeAndNil(Options);
  FreeAndNil(DCUSearchPaths);
  FreeAndNil(SearchPaths);
end;

class procedure TTDSToPDBOptions.AddOption(AFakeName: string; AOpt: IOptionDefinition);
begin
  Options.Add(TOptionRec.Create(AFakeName, AOpt));
end;

procedure ConfigureOptions;
var
  TempOption: IOptionDefinition;
begin
  TempOption := TOptionsRegistry.RegisterUnNamedOption<string>('The executable containing symbols' +
    ' to be converted to PDB and stripped.',
    procedure(const Value: string)
    begin
      TTDSToPDBOptions.InputFile := Value;
    end);
  TempOption.Required := True;
  TTDSToPDBOptions.AddOption('inputfile', TempOption);

  TempOption := TOptionsRegistry.RegisterUnNamedOption<string>('The PDB file. When not specified,' +
    ' the outfile will be the same as the infile with the extension changed to ''pdb''.',
    procedure(const Value: string)
    begin
      TTDSToPDBOptions.OutputFile := Value;
    end);
  TempOption.Required := False;
  TTDSToPDBOptions.AddOption('outputfile', TempOption);

  TempOption := TOptionsRegistry.RegisterOption<string>('dcusearch', 'd', 'Add provided path to ' +
    'DCU search path.',
    procedure(const Value: string)
    begin
      TTDSToPDBOptions.DCUSearchPaths.Add(Value);
    end);
  TempOption.Required := False;
  TTDSToPDBOptions.AddOption('', TempOption);

  TempOption := TOptionsRegistry.RegisterOption<string>('search', 's', 'Add provided path to ' +
    'source file search path.',
    procedure(const Value: string)
    begin
      TTDSToPDBOptions.SearchPaths.Add(TTDSToPDBOptions.TSearchRec.Create(Value, False));
    end);
  TempOption.HasValue := True;
  TempOption.Required := False;
  TempOption.AllowMultiple := True;
  TTDSToPDBOptions.AddOption('', TempOption);

  TempOption := TOptionsRegistry.RegisterOption<string>('searchrecur', 'r', 'Add provided path to' +
    ' source file search path to be searched recursively.',
    procedure(const Value: string)
    begin
      TTDSToPDBOptions.SearchPaths.Add(TTDSToPDBOptions.TSearchRec.Create(Value, True));
    end);
  TempOption.HasValue := True;
  TempOption.Required := False;
  TempOption.AllowMultiple := True;
  TTDSToPDBOptions.AddOption('', TempOption);

  TempOption := TOptionsRegistry.RegisterOption<Boolean>('help', 'h', 'Show this help.',
    procedure(const Value: Boolean)
    begin
      TTDSToPDBOptions.ShowHelp := Value;
    end);
  TempOption.HasValue := False;
  TempOption.Required := False;
  TTDSToPDBOptions.AddOption('', TempOption);
end;

initialization
  ConfigureOptions;

end.
