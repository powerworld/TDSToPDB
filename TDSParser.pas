unit TDSParser;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, JclPeImage, TDSInfo;

type
  TTDSParser = class
  private const
    POOL_DELTA = 256 * 1024;
  private
    FBase: Pointer;
    FData: TCustomMemoryStream;
    FValidData: Boolean;
    FModules: TList<PTDS_ModuleSection>;
    FAlignSymbolsBases: TList<Pointer>;
    FAlignSymbols: TObjectList<TList<PTDS_SYMTYPE>>;
    FSourceModules: TList<PTDS_SourceModuleSectionHeader>;
    FGlobalSymbols: TList<PTDS_SYMTYPE>;
    FGlobalTypes: TList<PTDS_TYPTYPE>;
    FNames: TList<PAnsiChar>;
//    FBufferPool: TObjectList<TMemoryStream>;
//    FCurrentBuffer: TMemoryStream;
//    FFixedUpTypeData: TMemoryStream;
//    FFixedUpAlignSymData: TObjectList<TMemoryStream>;
//    FFixedUpGlobalSymData: TMemoryStream;
    procedure ParseTDSData;
//    procedure SortTypesAndFixupSymbols;
//    procedure InitNewPoolBuffer;
//    function PoolSize: Int64;
//    procedure CheckPool(Size: Int64);
//    procedure ClearPool;
    function LfaToVa(Lfa: NativeInt): Pointer;
  public
    constructor Create(const ATD32Data: TCustomMemoryStream); // Data mustn't be freed before the class is destroyed
    destructor Destroy; override;
    class function IsTD32Sign(const Sign: TTDSFileSignature): Boolean;
    class function IsTD32DebugInfoValid(const DebugData: Pointer; const DebugDataSize: UInt32): Boolean;
    property ValidData: Boolean read FValidData;
    property Modules: TList<PTDS_ModuleSection> read FModules;
    property AlignSymbolsBases: TList<Pointer> read FAlignSymbolsBases;
    property AlignSymbols: TObjectList<TList<PTDS_SYMTYPE>> read FAlignSymbols;
    property SourceModules: TList<PTDS_SourceModuleSectionHeader> read FSourceModules;
    property GlobalSymbols: TList<PTDS_SYMTYPE> read FGlobalSymbols;
    property GlobalTypes: TList<PTDS_TYPTYPE> read FGlobalTypes;
    property Names: TList<PAnsiChar> read FNames;
  end;

  // Adapted from the Project Jedi TJclPeBorTD32Image
  TPeBorTDSParserImage = class(TJclPeBorImage)
  private
    FIsTD32DebugPresent: Boolean;
    FTDSDebugData: TCustomMemoryStream;
    FTDSParser: TTDSParser;
  protected
    procedure AfterOpen; override;
    procedure Clear; override;
    procedure ClearDebugData;
    procedure CheckDebugData;
    function IsDebugInfoInImage(var DataStream: TCustomMemoryStream): Boolean;
    function IsDebugInfoInTds(var DataStream: TCustomMemoryStream): Boolean;
  public
    property IsTDSDebugPresent: Boolean read FIsTD32DebugPresent;
    property TDSDebugData: TCustomMemoryStream read FTDSDebugData;
    property TDSParser: TTDSParser read FTDSParser;
  end;

implementation

uses
  Winapi.Windows, JclSysUtils, JclFileUtils, TD32ToPDBResources, TDSUtils;

const
  TurboDebuggerSymbolExt = '.tds';

procedure TTDSParser.ParseTDSData;
var
  PDirHeader: PTDS_DirectoryHeader;
  I, J: Integer;
  PSymHeader: PTDS_SymbolSectionHeader;
  PSym,
  PSymEnd: PTDS_SYMTYPE;
  PGlobTypeHeader: PTDS_GlobalTypeSectionHeader;
  PNameHeader: PTDS_NamesSectionHeader;
  ByteLen: UInt8;
  Name: PAnsiChar;
begin
{$POINTERMATH ON}
  PDirHeader := LfaToVa(PTDSFileSignature(LfaToVa(0)).Offset);
  Assert(PDirHeader.cbDirEntry = SizeOf(TTDS_DirectoryEntry));

  // Locate interesting sections
  while True do begin
    for I := 0 to PDirHeader.cDir - 1 do
      case PDirHeader.entries[I].subsection of
        TDS_SUBSECTION_TYPE_MODULE: begin
          if FModules = nil then
            FModules := TList<PTDS_ModuleSection>.Create;
          if FModules.Count <= PDirHeader.entries[I].iMod then
            FModules.Count := PDirHeader.entries[I].iMod + 1;
          FModules[PDirHeader.entries[I].iMod] := LfaToVa(PDirHeader.entries[I].lfo);
        end;
        TDS_SUBSECTION_TYPE_ALIGN_SYMBOLS: begin
          PSymHeader := LfaToVa(PDirHeader.entries[I].lfo);
          Assert(PSymHeader.sig = $00000001);
          if FAlignSymbols = nil then begin
            FAlignSymbols := TObjectList<TList<PTDS_SYMTYPE>>.Create;
            FAlignSymbolsBases := TList<Pointer>.Create;
          end;
          if FAlignSymbols.Count <= PDirHeader.entries[I].iMod then begin
            FAlignSymbols.Count := PDirHeader.entries[I].iMod + 1;
            FAlignSymbolsBases.Count := PDirHeader.entries[I].iMod + 1;
          end;
          FAlignSymbols[PDirHeader.entries[I].iMod] := TList<PTDS_SYMTYPE>.Create;
          FAlignSymbolsBases[PDirHeader.entries[I].iMod] := PSymHeader;
          with FAlignSymbols[PDirHeader.entries[I].iMod] do begin
            PSym := @PSymHeader.data;
            PSymEnd := PTDS_SYMTYPE(PUInt8(PSymHeader) + PDirHeader.entries[I].cb);
            while NativeUInt(PSym) < NativeUInt(PSymEnd) do begin
              Add(PSym);
              PSym := NextSym(PSym);
            end;
          end;
        end;
        TDS_SUBSECTION_TYPE_SOURCE_MODULE: begin
          if FSourceModules = nil then
            FSourceModules := TList<PTDS_SourceModuleSectionHeader>.Create;
          if FSourceModules.Count <= PDirHeader.entries[I].iMod then
            FSourceModules.Count := PDirHeader.entries[I].iMod + 1;
          FSourceModules[PDirHeader.entries[I].iMod] := LfaToVa(PDirHeader.entries[I].lfo);
        end;
        TDS_SUBSECTION_TYPE_GLOBAL_SYMBOLS: begin
          // we don't really care about the header
          PSym := @PTDS_GlobalSymbolsSectionHeader(LfaToVa(PDirHeader.entries[I].lfo)).symbols;
          PSymEnd := PTDS_SYMTYPE(PUInt8(LfaToVa(PDirHeader.entries[I].lfo)) + PDirHeader.entries[I].cb);
          Assert(FGlobalSymbols = nil);
          FGlobalSymbols := TList<PTDS_SYMTYPE>.Create;
          while NativeUInt(PSym) < NativeUInt(PSymEnd) do begin
            FGlobalSymbols.Add(PSym);
            PSym := NextSym(PSym);
          end;
        end;
        TDS_SUBSECTION_TYPE_GLOBAL_TYPES: begin
          Assert(FGlobalTypes = nil);
          FGlobalTypes := TList<PTDS_TYPTYPE>.Create;
          for J := 0 to $1000 - 1 do // Add in nil type info for basic types
            FGlobalTypes.Add(nil);
          PGlobTypeHeader := LfaToVa(PDirHeader.entries[I].lfo);
          Assert(PGlobTypeHeader.sig = $00000001);
          for J := 0 to PGlobTypeHeader.cTypes - 1 do
            FGlobalTypes.Add(PTDS_TYPTYPE(PUInt8(PGlobTypeHeader) + PGlobTypeHeader.offsets[J]));
        end;
        TDS_SUBSECTION_TYPE_NAMES: begin
          Assert(FNames = nil);
          FNames := TList<PAnsiChar>.Create;
          FNames.Add(nil); // Make entry 0 nil for ease later
          PNameHeader := LfaToVa(PDirHeader.entries[I].lfo);
          Name := @PNameHeader.names;
          for J := 0 to PNameHeader.cNames - 1 do begin
            ByteLen := UInt8(Name^);
            Inc(Name);
            FNames.Add(Name);
            Inc(Name, ByteLen);
            while Name^ <> #0 do
              Inc(Name, 256); // Length is modulo 256
            Inc(Name); // skip null
          end;
        end;
      else
        Writeln(ErrOutput,
          Format('Unexpected directory entry type $%0.4x',
            [PDirHeader.entries[I].subsection]));
      end;

    if PDirHeader.lfoNextDir <> 0 then
      PDirHeader := LfaToVa(PDirHeader.lfoNextDir)
    else
      Break;
  end;

  // Organize types in reverse dependency order as much as possible as this is the preferred
  // ordering for CodeView types. Once done, fixup symbols accordingly.
//  SortTypesAndFixupSymbols;
{$POINTERMATH OFF}
end;

(*procedure TTDSParser.SortTypesAndFixupSymbols;
const
  TypeStorageDelta = 65536;
var
  I, J: UInt32;
  NewTypeList: TList<PTDS_TYPTYPE>;
  TranslatedTypes: TDictionary<TDS_typ_t, TDS_typ_t>;
  TypesToProcess: TStack<UInt32>;
  Dependencies: TArray<TDS_typ_t>;
  CurrentType: TDS_typ_t;
  PrevCount: Integer;
  TypeSize: UInt16;
  SymSize: UInt16;
  NewType: PTDS_TYPTYPE;
  NewSym: PTDS_SYMTYPE;
  LogStream: TStreamWriter;
begin
{$POINTERMATH ON}
  LogStream := TStreamWriter.Create(TFileStream.Create('Reorderings.txt', fmCreate or fmShareDenyWrite));
  LogStream.OwnStream;
  NewTypeList := TList<PTDS_TYPTYPE>.Create;
  for I := 0 to $1000 - 1 do // add in basic types with nil PTYPTYPE
    NewTypeList.Add(nil);
  TranslatedTypes := TDictionary<TDS_typ_t, TDS_typ_t>.Create;
  TypesToProcess := nil;
  try
    // Sort types in reverse dependency order and keep track of changes
    TypesToProcess := TStack<UInt32>.Create;
    if FGlobalTypes.Count > $1000 then // process only non-basic types
      for I := $1000 to FGlobalTypes.Count - 1 do
        if not TranslatedTypes.ContainsKey(I) then begin
          TypesToProcess.Push(I);
          while TypesToProcess.Count > 0 do begin
            PrevCount := TypesToProcess.Count;
            CurrentType := TypesToProcess.Peek;
            TranslatedTypes.AddOrSetValue(CurrentType, 0); // Placeholder...breaks dependency cycles
            Dependencies := GetTypeDependencies(FGlobalTypes[CurrentType]);
            if Length(Dependencies) > 0 then // need this since J is unsigned
              for J := 0 to Length(Dependencies) - 1 do begin
                Assert(Dependencies[J] < UInt32(FGlobalTypes.Count));
                if (Dependencies[J] >= $1000) and
                   (not TranslatedTypes.ContainsKey(Dependencies[J])) then
                  TypesToProcess.Push(Dependencies[J]);
              end;
            if PrevCount = TypesToProcess.Count then begin // no unhandled dependencies
              TypesToProcess.Pop;
              TranslatedTypes[CurrentType] := NewTypeList.Add(FGlobalTypes[CurrentType]);
              LogStream.WriteLine('$%.8x -> $%.8x', [CurrentType, NewTypeList.Count - 1]);
            end;
          end;
        end;
    NewTypeList := AtomicExchange(Pointer(FGlobalTypes), Pointer(NewTypeList));

    // Update types within the types themselves
    if FGlobalTypes.Count > $1000 then begin // process only non-basic types
      for I := $1000 to FGlobalTypes.Count - 1 do begin
        // Copy type over to pool
        with FGlobalTypes[I]^ do begin
          TypeSize := len + SizeOf(len);
          CheckPool(TypeSize);
          NewType := Pointer(PUInt8(FCurrentBuffer.Memory) + FCurrentBuffer.Position);
          FCurrentBuffer.Position := FCurrentBuffer.Position + TypeSize;
        end;
        Move(FGlobalTypes[I]^, NewType^, TypeSize);
        // Modify type as necessary
        TranslateTDS2TDSTypes(NewType, TranslatedTypes);
        // Update global type list with copied and modified type
        FGlobalTypes[I] := NewType;
      end;
    end;

    if FGlobalTypes.Count > $1000 then begin // process only non-basic types
      // Move pool types over to a more permanent, contiguous buffer
      FFixedUpTypeData := TMemoryStream.Create;
      FFixedUpTypeData.Size := PoolSize;
      for I := $1000 to FGlobalTypes.Count - 1 do begin
        with FGlobalTypes[I]^ do begin
          TypeSize := len + SizeOf(len);
          CheckPool(TypeSize);
          NewType := Pointer(PUInt8(FFixedUpTypeData.Memory) + FFixedUpTypeData.Position);
          FFixedUpTypeData.Position := FFixedUpTypeData.Position + TypeSize;
        end;
        Move(FGlobalTypes[I]^, NewType^, TypeSize);
        FGlobalTypes[I] := NewType;
      end;
      ClearPool;
    end;

    // Update types in align symbols
    if FAlignSymbols.Count > 0 then begin // need this because I is unsigned
      FFixedUpAlignSymData.Count := FAlignSymbols.Count;
      for I := 0 to FAlignSymbols.Count - 1 do begin
        if (FAlignSymbols[I] <> nil) and (FAlignSymbols[I].Count > 0) then begin // need this because J is unsigned
          for J := 0 to FAlignSymbols[I].Count - 1 do begin
            // Copy symbol over to pool
            with FAlignSymbols[I][J]^ do begin
              SymSize := reclen + SizeOf(reclen);
              CheckPool(SymSize);
              NewSym := Pointer(PUInt8(FCurrentBuffer.Memory) + FCurrentBuffer.Position);
              FCurrentBuffer.Position := FCurrentBuffer.Position + SymSize;
            end;
            Move(FAlignSymbols[I][J]^, NewSym^, SymSize);
            // Modify symbol as necessary
            TranslateTDS2TDSTypes(NewSym, TranslatedTypes);
            // Update align symbol list with copied and modified symbol
            FAlignSymbols[I][J] := NewSym;
          end;
        end;

        if (FAlignSymbols[I] <> nil) and (FAlignSymbols[I].Count > 0) then begin // need this because J is unsigned
          // Move pool symbols to more permanent, contiguous buffer
          FFixedUpAlignSymData[I] := TMemoryStream.Create;
          FFixedUpAlignSymData[I].Size := PoolSize;
          FAlignSymbolsBases[I] := FFixedUpAlignSymData[I].Memory;
          for J := 0 to FAlignSymbols[I].Count - 1 do begin
            with FAlignSymbols[I][J]^ do begin
              SymSize := reclen + SizeOf(reclen);
              CheckPool(SymSize);
              NewSym := Pointer(PUInt8(FFixedUpAlignSymData[I].Memory) + FFixedUpAlignSymData[I].Position);
              FFixedUpAlignSymData[I].Position := FFixedUpAlignSymData[I].Position + SymSize;
            end;
            Move(FAlignSymbols[I][J]^, NewSym^, SymSize);
            FAlignSymbols[I][J] := NewSym;
          end;
        end;
        ClearPool;
      end;
    end;
    // Update types in global symbols
    if FGlobalSymbols.Count > 0 then begin // need this because I is unsigned
      for I := 0 to FGlobalSymbols.Count - 1 do begin
        // Copy symbol over to pool
        with FGlobalSymbols[I]^ do begin
          SymSize := reclen + SizeOf(reclen);
          CheckPool(SymSize);
          NewSym := Pointer(PUInt8(FCurrentBuffer.Memory) + FCurrentBuffer.Position);
          FCurrentBuffer.Position := FCurrentBuffer.Position + SymSize;
        end;
        Move(FGlobalSymbols[I]^, NewSym^, SymSize);
        // Modify symbol as necessary
        TranslateTDS2TDSTypes(NewSym, TranslatedTypes);
        // Update global symbol list with copied and modified symbol
        FGlobalSymbols[I] := NewSym;
      end;
    end;

    if FGlobalSymbols.Count > 0 then begin // need this because I is unsigned
      // Move pool symbols to more permanent, contiguous buffer
      FFixedUpGlobalSymData := TMemoryStream.Create;
      FFixedUpGlobalSymData.Size := PoolSize;
      for I := 0 to FGlobalSymbols.Count - 1 do begin
        with FGlobalSymbols[I]^ do begin
          SymSize := reclen + SizeOf(reclen);
          CheckPool(SymSize);
          NewSym := Pointer(PUInt8(FFixedUpGlobalSymData.Memory) + FFixedUpGlobalSymData.Position);
          FFixedUpGlobalSymData.Position := FFixedUpGlobalSymData.Position + SymSize;
        end;
        Move(FGlobalSymbols[I]^, NewSym^, SymSize);
        FGlobalSymbols[I] := NewSym;
      end;
      ClearPool;
    end;
  finally
    LogStream.Free;
    NewTypeList.Free; // Now should hold the old FGlobalTypes
    TypesToProcess.Free;
    TranslatedTypes.Free;
  end;
{$POINTERMATH OFF}
end;*)

//procedure TTDSParser.InitNewPoolBuffer;
//begin
//  FCurrentBuffer := TMemoryStream.Create;
//  FCurrentBuffer.Size := POOL_DELTA;
//  FBufferPool.Add(FCurrentBuffer);
//end;

//function TTDSParser.PoolSize: Int64;
//begin
//  Result := FBufferPool.Count * POOL_DELTA;
//end;
//
//procedure TTDSParser.CheckPool(Size: Int64);
//begin
//  Assert(Size <= POOL_DELTA);
//  if (FBufferPool[FBufferPool.Count - 1].Position + Size) >=
//     FBufferPool[FBufferPool.Count - 1].Size then
//    InitNewPoolBuffer;
//end;
//
//procedure TTDSParser.ClearPool;
//begin
//  FBufferPool.Clear;
//  InitNewPoolBuffer;
//end;

function TTDSParser.LfaToVa(Lfa: NativeInt): Pointer;
begin
{$POINTERMATH ON}
  Result := PUInt8(FBase) + Lfa;
{$POINTERMATH OFF}
end;

constructor TTDSParser.Create(const ATD32Data: TCustomMemoryStream);
begin
  Assert(Assigned(ATD32Data));
  inherited Create;
  FData := ATD32Data;
  FBase := FData.Memory;
//  FBufferPool := TObjectList<TMemoryStream>.Create;
//  FCurrentBuffer := TMemoryStream.Create;
//  FCurrentBuffer.Size := POOL_DELTA;
//  FBufferPool.Add(FCurrentBuffer);
  FValidData := IsTD32DebugInfoValid(FBase, FData.Size);
//  FFixedUpAlignSymData := TObjectList<TMemoryStream>.Create;
  if FValidData then
    ParseTDSData;
end;

destructor TTDSParser.Destroy;
begin
  FModules.Free;
  FAlignSymbolsBases.Free;
  FAlignSymbols.Free;
  FSourceModules.Free;
  FGlobalSymbols.Free;
  FGlobalTypes.Free;
  FNames.Free;
//  FBufferPool.Free;
//  FFixedUpTypeData.Free;
//  FFixedUpAlignSymData.Free;
//  FFixedUpGlobalSymData.Free;
  inherited Destroy;
end;

class function TTDSParser.IsTD32Sign(const Sign: TTDSFileSignature): Boolean;
begin
//  Result := (Sign.Signature = Borland32BitSymbolFileSignatureForDelphi) or
//    (Sign.Signature = Borland32BitSymbolFileSignatureForBCB);
// Only support Delphi TD32 info at the moment
  Result := Sign.Signature = Borland32BitSymbolFileSignatureForDelphi;
end;

class function TTDSParser.IsTD32DebugInfoValid(const DebugData: Pointer;
  const DebugDataSize: UInt32): Boolean;
var
  Sign: TTDSFileSignature;
  EndOfDebugData: PUInt8;
begin
{$POINTERMATH ON}
  Assert(not IsBadReadPtr(DebugData, DebugDataSize));
  Result := False;
  EndOfDebugData := PUInt8(DebugData) + DebugDataSize;
  if DebugDataSize > SizeOf(Sign) then
  begin
    Sign := PTDSFileSignature(EndOfDebugData - SizeOf(Sign))^;
    if IsTD32Sign(Sign) and (Sign.Offset <= DebugDataSize) then
    begin
      Sign := PTDSFileSignature(EndOfDebugData - Sign.Offset)^;
      Result := IsTD32Sign(Sign);
    end;
  end;
{$POINTERMATH OFF}
end;

procedure TPeBorTDSParserImage.AfterOpen;
begin
  inherited AfterOpen;
  CheckDebugData;
end;

procedure TPeBorTDSParserImage.CheckDebugData;
begin
  FIsTD32DebugPresent := IsDebugInfoInImage(FTDSDebugData);
  if not FIsTD32DebugPresent then
    FIsTD32DebugPresent := IsDebugInfoInTds(FTDSDebugData);
  if FIsTD32DebugPresent then
  begin
    FTDSParser := TTDSParser.Create(FTDSDebugData);
    if not FTDSParser.ValidData then
    begin
      ClearDebugData;
      if not NoExceptions then
        raise ETD32ToPDBError.CreateResFmt(@RsNoTD32Info, [FileName]);
    end;
  end;
end;

procedure TPeBorTDSParserImage.Clear;
begin
  ClearDebugData;
  inherited Clear;
end;

procedure TPeBorTDSParserImage.ClearDebugData;
begin
  FIsTD32DebugPresent := False;
  FreeAndNil(FTDSParser);
  FreeAndNil(FTDSDebugData);
end;

function TPeBorTDSParserImage.IsDebugInfoInImage(var DataStream: TCustomMemoryStream): Boolean;
var
  DebugDir: TImageDebugDirectory;
  BugDataStart: Pointer;
  DebugDataSize: Integer;
begin
  Result := False;
  DataStream := nil;
  if IsBorlandImage and (DebugList.Count = 1) then
  begin
    DebugDir := DebugList[0];
    if DebugDir._Type = IMAGE_DEBUG_TYPE_UNKNOWN then
    begin
      BugDataStart := RvaToVa(DebugDir.AddressOfRawData);
      DebugDataSize := DebugDir.SizeOfData;
      Result := TTDSParser.IsTD32DebugInfoValid(BugDataStart, DebugDataSize);
      if Result then
        DataStream := TJclReferenceMemoryStream.Create(BugDataStart, DebugDataSize);
    end;
  end;
end;

function TPeBorTDSParserImage.IsDebugInfoInTds(var DataStream: TCustomMemoryStream): Boolean;
var
  TdsFileName: TFileName;
  TempStream: TCustomMemoryStream;
begin
  Result := False;
  DataStream := nil;
  TdsFileName := ChangeFileExt(FileName, TurboDebuggerSymbolExt);
  if FileExists(TdsFileName) then
  begin
    TempStream := TJclFileMappingStream.Create(TdsFileName, fmOpenRead or fmShareDenyNone);
    try
      Result := TTDSParser.IsTD32DebugInfoValid(TempStream.Memory, TempStream.Size);
      if Result then
        DataStream := TempStream
      else
        TempStream.Free;
    except
      TempStream.Free;
      raise;
    end;
  end;
end;

end.
