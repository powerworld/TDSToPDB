unit TDSParser;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, JclPeImage, TDSInfo;

type
  TTDSParser = class
  public type
    TSourceLine = record
      module: Integer;
      filename: string;
      seg: UInt16;
      offset: UInt32;
      linenumber: UInt32;
      constructor Create(Amodule: Integer; Afilename: string; Aseg: UInt16; Aoffset,
        Alinenumber: UInt32);
    end;
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
    FSourceModulesSize: TList<UInt32>;
    FGlobalSymbols: TList<PTDS_SYMTYPE>;
    FGlobalTypes: TList<PTDS_TYPTYPE>;
    FNames: TList<PAnsiChar>;
    FSourceLines: TObjectList<TList<TSourceLine>>;
    procedure ParseTDSData;
    procedure FixupLineInfo;
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
    property SourceLines: TObjectList<TList<TSourceLine>> read FSourceLines;
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
  System.Generics.Defaults, Winapi.Windows, JclSysUtils, JclFileUtils, TD32ToPDBResources, TDSUtils;

const
  TurboDebuggerSymbolExt = '.tds';

constructor TTDSParser.TSourceLine.Create(Amodule: Integer; Afilename: string; Aseg: UInt16; Aoffset,
  Alinenumber: UInt32);
begin
  module := Amodule;
  filename := Afilename;
  seg := Aseg;
  offset := Aoffset;
  linenumber := Alinenumber;
end;

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
          if FSourceModules = nil then begin
            FSourceModules := TList<PTDS_SourceModuleSectionHeader>.Create;
            FSourceModulesSize := TList<UInt32>.Create;
          end;
          if FSourceModules.Count <= PDirHeader.entries[I].iMod then begin
            FSourceModules.Count := PDirHeader.entries[I].iMod + 1;
            FSourceModulesSize.Count := PDirHeader.entries[I].iMod + 1;
          end;
          FSourceModules[PDirHeader.entries[I].iMod] := LfaToVa(PDirHeader.entries[I].lfo);
          FSourceModulesSize[PDirHeader.entries[I].iMod] := PDirHeader.entries[I].cb;
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
{$POINTERMATH OFF}
end;

procedure TTDSParser.FixupLineInfo;
type
  TContribLineNumberInfo = record
    prevlinenumber,
    wrapnum: Integer;
  end;
var
  I, L: Integer;
  J, K: UInt16;
  srcMod: PTDS_SourceModuleSectionHeader;
  srcModFile: PTDS_SourceFileEntry;
  srcModFileSeg,
  srcModEnd,
  srcModFileEnd,
  srcModFileSegEnd: PTDS_SegmentLineInfo;
  lni: TContribLineNumberInfo;
  filename: string;
  seg: UInt16;
  PrevLineNumberInfo: TDictionary<string, TContribLineNumberInfo>;
begin
{$POINTERMATH ON}
  PrevLineNumberInfo := TDictionary<string, TContribLineNumberInfo>.Create;
  try
    for I := 0 to FSourceModules.Count - 1 do begin
      if FSourceLines = nil then
        FSourceLines := TObjectList<TList<TSourceLine>>.Create;
      FSourceLines.Add(
        TList<TSourceLine>.Create(
          TComparer<TSourceLine>.Construct(
            function(const Left, Right: TSourceLine): Integer
            begin
              if Left.seg < Right.seg then Result := -1
              else if Left.Seg > Right.seg then Result := 1
              else if Left.offset < Right.offset then Result := -1
              else if Left.offset > Right.offset then Result := 1
              else Result := 0;
            end)));
      srcMod := FSourceModules[I];
      srcModEnd := Pointer(NativeUInt(FSourceModules[I]) + FSourceModulesSize[I]);
      if (srcMod <> nil) and (srcMod.cFile <> 0) then begin
        for J := 0 to srcMod.cFile - 1 do begin
          srcModFile := srcMod.GetbaseSrcFilePointer(J);
          if (J < (srcMod.cFile - 1)) and (srcMod.GetbaseSrcFilePointer(J + 1).cSeg <> 0) then
            srcModFileEnd := srcMod.GetbaseSrcFilePointer(J + 1).getbaseSrcLnPointer(srcMod, 0)
          else
            srcModFileEnd := srcModEnd;
          filename := string(UTF8String(FNames[srcModFile.name]));
          if srcModFile.cSeg <> 0 then begin
            // Since we're on a single file now and line numbers can wrap around 65536, keep track
            // of previous line numbers. To handle line number wrapping we use the following logic:
            // 1) If we wrap from huge to small and the difference is greater than half the range,
            //    increment the line count offset.
            // 2) If we wrap from small to huge and the difference is greater than half the range,
            //    decrement the line count offset.
            // The rationale is that we should never see a loop spanning 32k lines and it's
            // extremely rare for line numbers to decrease, unless in a loop. This should handle all
            // line number increases and decreases with aplomb.
            //
            // Also, since contributions from files can be split up because of file inclusions, we
            // need to keep track of previous line numbers and wrap counts from previous contributions
            // from the same file.
            if not PrevLineNumberInfo.TryGetValue(filename, lni) then begin
              lni.prevlinenumber := 0;
              lni.wrapnum := 0;
            end;
            for K := 0 to srcModFile.cSeg - 1 do begin
              srcModFileSeg := srcModFile.getbaseSrcLnPointer(srcMod, K);
              if K < (srcModFile.cSeg - 1) then
                srcModFileSegEnd := srcModFile.getbaseSrcLnPointer(srcMod, K + 1)
              else
                srcModFileSegEnd := srcModFileEnd;
              seg := srcModFileSeg.seg;
              // Because of the way this whole section is structured, it's possible for line info to
              // exceed 65536 entries, so we just ensure that the line number pointer is strictly less
              // than the srcModFileSegEnd.
              L := 0;
              while NativeUInt(@srcModFileSeg.linenumber[L]) < NativeUInt(srcModFileSegEnd) do begin
                // This is where the previously described goofy line number wrapping logic comes
                // into play:
                if      ((lni.prevlinenumber and $8000) = $8000) and
                        ((srcModFileSeg.linenumber[L] and $8000) = $0000) and
                        ((lni.prevlinenumber - srcModFileSeg.linenumber[L]) > $8000) then
                  Inc(lni.wrapnum)
                else if ((lni.prevlinenumber and $8000) = $0000) and
                        ((srcModFileSeg.linenumber[L] and $8000) = $8000) and
                        ((srcModFileSeg.linenumber[L] - lni.prevlinenumber) > $8000) then
                  Dec(lni.wrapnum);
                FSourceLines[I].Add(TSourceLine.Create(I, filename, seg, srcModFileSeg.offset[L],
                  srcModFileSeg.linenumber[L] + lni.wrapnum * 65536));
                lni.prevlinenumber := srcModFileSeg.linenumber[L];
                Inc(L);
              end;
            end;
            PrevLineNumberInfo.AddOrSetValue(filename, lni);
          end;
        end;
      end;
      FSourceLines[I].Sort;
    end;
  finally
    PrevLineNumberInfo.Free;
  end;
{$POINTERMATH OFF}
end;

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
  FValidData := IsTD32DebugInfoValid(FBase, FData.Size);
  if FValidData then begin
    ParseTDSData;
    FixupLineInfo;
  end;
end;

destructor TTDSParser.Destroy;
begin
  FSourceLines.Free;
  FModules.Free;
  FAlignSymbolsBases.Free;
  FAlignSymbols.Free;
  FSourceModulesSize.Free;
  FSourceModules.Free;
  FGlobalSymbols.Free;
  FGlobalTypes.Free;
  FNames.Free;
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
