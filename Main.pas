unit Main;

interface

procedure MainProc;

implementation

uses
  System.Types, System.Classes, System.SysUtils, System.IOUtils, System.Generics.Collections,
  System.Generics.Defaults, System.Win.ComObj, System.Variants, System.AnsiStrings, Winapi.Windows,
  Winapi.ActiveX, VSoft.CommandLine.Parser, VSoft.CommandLine.Options, CVInfo, PDBInfo, TDSParser,
  TDSTypesConv, TDSSymbolsConv, LLVMPDBCOM_TLB, Options, JclPeImage, JclWin32, TDSInfo, CVConst,
  System.StrUtils, System.Character, TDSUtils;

var
  FilesFound: TDictionary<string, string>;
  DCUsFound: TDictionary<string, string>;

function FindSourceFileInSearchPaths(FileName: string): string;
begin
  FileName := TPath.GetFileName(FileName);
  if not FilesFound.TryGetValue(FileName, Result) then begin
    Writeln(ErrOutput, Format('Could not find file in search paths: %s', [FileName]));
    ExitCode := -1;
    Halt;
  end;
end;

function FindDCUInSearchPaths(DCU: string): string;
begin
  if SameText(TPath.GetFileNameWithoutExtension(DCU),
              TPath.GetFileNameWithoutExtension(TTDSToPDBOptions.InputFile)) then
    Exit(TPath.GetFileNameWithoutExtension(DCU));
  DCU := TPath.GetFileName(DCU);
  if not DCUsFound.TryGetValue(DCU, Result) then begin
    Writeln(ErrOutput, Format('Could not find DCU in search paths: %s', [DCU]));
    ExitCode := -1;
    Halt;
  end;
end;

type
  TPDBBuildState = class;

  TPDBModule = class
    FModSec: PTDS_ModuleSection;
    FTDSModI: Integer;
    FModInfoBuilder: ILLVMDbiModuleDescriptorBuilder;
    FLinesSSBuilders: TList<ILLVMDebugLinesSubsection>;
    FChecksumSSBuilder: ILLVMDebugChecksumsSubsection;

    constructor Create(AModSec: PTDS_ModuleSection; ATDSModI: Integer);
    destructor Destroy; override;
    function CreateSectionContrib(BuildState: TPDBBuildState): LLVM_SectionContrib;
    procedure BuildSymbols(BuildState: TPDBBuildState);
    procedure BuildModuleSubsections(BuildState: TPDBBuildState);
    procedure AddUnit(BuildState: TPDBBuildState);
    procedure AddCommonLinkerModuleSymbols(BuildState: TPDBBuildState);
    procedure AddLinkerModuleSectionSymbols(BuildState: TPDBBuildState);
  end;

  // The structure is shamelessly stolen from LLVM's PDB.cpp in the LLD linker project.
  TPDBBuildState = class
  private const
    LINKER_NAME: UTF8String = '* Linker *';
    CONV_NAME: UTF8String = 'TDSToPDB Converter';
  private
    FBuildId: PCVDebugInfoInImage;

    FTDSParserImage: TPeBorTDSParserImage;
    FTDSParser: TTDSParser;
    FTypesConverter: TTDSToPDBTypesConverter;
    FSymbolsConverter: TTDSToPDBSymbolsConverter;

    FAllocator: ILLVMBumpPtrAllocator;
    FBuilder: ILLVMPDBFileBuilder;
    FMSFBuilder: ILLVMMSFBuilder;
    FInfoBuilder: ILLVMInfoStreamBuilder;
    FDBIBuilder: ILLVMDbiStreamBuilder;
    FStringTableSSBuilder: ILLVMDebugStringTableSubsection;
    FPDBUtils: ILLVMPDBUtilities;

    FPDBModules: TObjectList<TPDBModule>;
    FPublicSymbols: TList<PSYMTYPE>;
    FSectionTable: TArray<LLVM_COFF_Section>;
  public
    constructor Create(BuildId: PCVDebugInfoInImage; TDSParserImage: TPeBorTDSParserImage;
      TypesConverter: TTDSToPDBTypesConverter; SymbolsConverter: TTDSToPDBSymbolsConverter);
    destructor Destroy; override;
    procedure Initialize;
    procedure AddTypeInfo;
    procedure AddUnitsToPDB;
    procedure AddSections;
    procedure Commit;
  end;

constructor TPDBModule.Create(AModSec: PTDS_ModuleSection; ATDSModI: Integer);
begin
  inherited Create;
  FLinesSSBuilders := TList<ILLVMDebugLinesSubsection>.Create;
  FModSec := AModSec;
  FTDSModI := ATDSModI;
end;

destructor TPDBModule.Destroy;
begin
  FLinesSSBuilders.Free;
  inherited Destroy;
end;

constructor TPDBBuildState.Create(BuildId: PCVDebugInfoInImage; TDSParserImage: TPeBorTDSParserImage;
  TypesConverter: TTDSToPDBTypesConverter; SymbolsConverter: TTDSToPDBSymbolsConverter);
begin
  inherited Create;
  FBuildId := BuildId;
  FTDSParserImage := TDSParserImage;
  FTDSParser := TDSParserImage.TDSParser;
  FTypesConverter := TypesConverter;
  FSymbolsConverter := SymbolsConverter;
  FPDBModules := TObjectList<TPDBModule>.Create;
  FPDBUtils := CoLLVMPDBUtilities.Create;
  FPublicSymbols := TList<PSYMTYPE>.Create;

  FStringTableSSBuilder := CoLLVMDebugStringTableSubsection.Create;
  // This isn't strictly necessary, but link.exe usually puts an empty string
  // as the first "valid" string in the string table, so we do the same in
  // order to maintain as much byte-for-byte compatibility as possible.
  FStringTableSSBuilder.insert('');
end;

destructor TPDBBuildState.Destroy;
begin
  FPublicSymbols.Free;
  FPDBModules.Free;
  inherited Destroy;
end;

// Shamelessly adapted from PDBLinker::initialize()
procedure TPDBBuildState.Initialize;
var
  I: Integer;
begin
  FAllocator := CoLLVMBumpPtrAllocator.Create;
  FBuilder := CoLLVMPDBFileBuilder.Create;
  FBuilder.construct(FAllocator);

  FBuilder.initialize(4096); // 4096 is blocksize

  with FBuildId^.rsdsi do begin
    dwSig := PDB70;
    // Signature is set to a hash of the PDB contents when the PDB is done.
    guidSig := TGUID.Create('{00000000-0000-0000-0000-000000000000}');
    age := 1;
  end;

  // Create streams in MSF for predefined streams, namely
  // PDB, TPI, DBI and IPI.
  FMSFBuilder := FBuilder.getMsfBuilder;
  for I := SpecialStream_OldMSFDirectory + 1 to SpecialStream_kSpecialStreamCount - 1 do
    FMSFBuilder.addStream(0);

  // Add an Info stream.
  FInfoBuilder := FBuilder.getInfoBuilder;
  FInfoBuilder.setVersion(PdbImplVC70);
  FInfoBuilder.setHashPDBContentsToGUID(True);

  // Add an empty DBI stream.
  FDBIBuilder := FBuilder.getDbiBuilder;
  FDBIBuilder.setAge(FBuildId^.rsdsi.age);
  FDBIBuilder.setVersionHeader(PdbDbiV70);
  FDBIBuilder.setMachineType(FTDSParserImage.LoadedImage.FileHeader^.FileHeader.Machine);
  // Technically we are not link.exe 14.11, but there are known cases where
  // debugging tools on Windows expect Microsoft-specific version numbers or
  // they fail to work at all.  Since we know we produce PDBs that are
  // compatible with LINK 14.11, we set that version number here.
  FDBIBuilder.setBuildNumberMajorMinor(14, 11);
end;

function TPDBModule.CreateSectionContrib(BuildState: TPDBBuildState): LLVM_SectionContrib;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.ISect := FModSec.seginfo[0].seg;
  Result.Off := FModSec.seginfo[0].offset;
  Result.Size := FModSec.seginfo[0].cbSeg;
  Result.Characteristics := BuildState.FTDSParserImage.LoadedImage.Sections^.Characteristics;
  Result.Imod := FModInfoBuilder.getModuleIndex;
  // TODO: Maybe fill these in later?
  Result.DataCrc := 0;
  Result.RelocCrc := 0;
end;

procedure TPDBModule.BuildSymbols(BuildState: TPDBBuildState);
var
  gsiBuilder: ILLVMGSIStreamBuilder;
  symDataVar,
  globSymVar: OleVariant;
  rawData: Pointer;
  I: Integer;
  tempSym: PSYMTYPE;
  tempSymLen: Integer;
  pubSymList: TList<PSYMTYPE>;
begin
  gsiBuilder := BuildState.FBuilder.getGsiBuilder;

  // add symbols
  symDataVar := VarArrayCreate([0, BuildState.FSymbolsConverter.CVSymbolsSize[FTDSModI] - 1],
    varByte);
  rawData := VarArrayLock(symDataVar);
  try
    Move(BuildState.FSymbolsConverter.CVSymbols[FTDSModI][0]^, rawData^,
      BuildState.FSymbolsConverter.CVSymbolsSize[FTDSModI]);
  finally
    VarArrayUnlock(symDataVar);
  end;
  FModInfoBuilder.addSymbolsInBulk(symDataVar);
  symDataVar := Null;

  // add global & public symbols
  pubSymList := TList<PSYMTYPE>.Create;
  try
    for I := 0 to BuildState.FSymbolsConverter.CVSymbols[FTDSModI].Count - 1 do begin
      globSymVar := Null;
      tempSym := BuildState.FSymbolsConverter.CVSymbols[FTDSModI][I];
      case tempSym^.rectyp of
        S_CONSTANT,
        S_UDT,
        S_GDATA32,
        S_LDATA32: begin
          tempSymLen := tempSym^.reclen + SizeOf(tempSym^.reclen);
          globSymVar := VarArrayCreate([0, tempSymLen - 1], varByte);
          rawData := VarArrayLock(globSymVar);
          try
            Move(tempSym^, rawData^, tempSymLen);
          finally
            VarArrayUnlock(globSymVar);
          end;
        end;
        S_GPROC32,
        S_LPROC32: begin
          tempSymLen := SizeOf(PREFSYM2(rawData)^) - SizeOf(PREFSYM2(rawData)^.name) +
            System.AnsiStrings.StrLen(PAnsiChar(@PPROCSYM32(tempSym).name[0])) + 1;
          globSymVar := VarArrayCreate([0, tempSymLen - 1], varByte);
          rawData := VarArrayLock(globSymVar);
          try
            with PREFSYM2(rawData)^ do begin
              reclen := tempSymLen - SizeOf(PREFSYM2(rawData)^.reclen);
              if tempSym^.rectyp = S_GPROC32 then
                rectyp := S_PROCREF
              else
                rectyp := S_LPROCREF;
              sumName := 0;
              ibSym := UInt32(NativeUInt(tempSym) -
                NativeUInt(BuildState.FSymbolsConverter.CVSymbols[FTDSModI][0]));
              imod := FModInfoBuilder.getModuleIndex + 1;
              System.AnsiStrings.StrCopy(PAnsiChar(@name[0]),
                PAnsiChar(@PPROCSYM32(tempSym).name[0]));
            end;
          finally
            VarArrayUnlock(globSymVar);
          end;
        end;
      end;
      case tempSym^.rectyp of
        S_GDATA32,
        S_LDATA32,
        S_GPROC32,
        S_LPROC32:
          BuildState.FPublicSymbols.Add(tempSym);
      end;
      if not VarIsNull(globSymVar) then
        gsiBuilder.addGlobalSymbol(globSymVar);
    end;
  finally
    pubSymList.Free;
  end;
end;

procedure TPDBModule.BuildModuleSubsections(BuildState: TPDBBuildState);
var
  modLines: TList<TTDSParser.TSourceLine>;
  modProcs: TList<PPROCSYM32>;
  I: Integer;
  lineIdx: Integer;
  procEnd: CV_uoff32_t;
  fileName,
  fullFileName: string;
  chksummedFiles: TDictionary<string, Integer>;
  tempLinesSSBuilder: ILLVMDebugLinesSubsection;
begin
  FChecksumSSBuilder := CoLLVMDebugChecksumsSubsection.Create;
  FChecksumSSBuilder.construct(BuildState.FAllocator, BuildState.FStringTableSSBuilder);

  chksummedFiles := TDictionary<string, Integer>.Create;
  try
    modLines := BuildState.FTDSParser.SourceLines[FTDSModI];
    modProcs := BuildState.FSymbolsConverter.CVProcs[FTDSModI];
    if Assigned(modLines) and Assigned(modProcs) then begin
      for I := 0 to modProcs.Count - 1 do begin
        modLines.BinarySearch(TTDSParser.TSourceLine.Create(I, '', modProcs[I].seg,
          modProcs[I].off, 0), lineIdx);
        procEnd := modProcs[I].off + modProcs[I].len;
        fileName := '';
        tempLinesSSBuilder := CoLLVMDebugLinesSubsection.Create;
        tempLinesSSBuilder.construct(FChecksumSSBuilder, BuildState.FStringTableSSBuilder);
        tempLinesSSBuilder.setCodeSize(modProcs[I].len);
        tempLinesSSBuilder.setRelocationAddress(modProcs[I].seg, modProcs[I].off);
        FLinesSSBuilders.Add(tempLinesSSBuilder);
        while (lineIdx < modLines.Count) and (modLines[lineIdx].offset < procEnd) do begin
          if modLines[lineIdx].filename <> fileName then begin
            fileName := modLines[lineIdx].filename;
            if not chksummedFiles.ContainsKey(fileName) then begin
              chksummedFiles.Add(fileName, 0);
              fullFileName := FindSourceFileInSearchPaths(fileName);
              FChecksumSSBuilder.addChecksum(fullFileName, FileChecksumKind_None, Null);
              BuildState.FDBIBuilder.addModuleSourceFile(FModInfoBuilder, fullFileName);
            end;
            tempLinesSSBuilder.createBlock(FindSourceFileInSearchPaths(fileName));
          end;
          tempLinesSSBuilder.addLineInfo(modLines[lineIdx].offset - modProcs[I].off,
            modLines[lineIdx].linenumber, modLines[lineIdx].linenumber, True);
          Inc(lineIdx);
        end;
      end;

      for I := 0 to FLinesSSBuilders.Count - 1 do
        FModInfoBuilder.addDebugSubsection(FLinesSSBuilders[I]);
      FModInfoBuilder.addDebugSubsection(FChecksumSSBuilder);
    end;
  finally
    chksummedFiles.Free;
  end;
end;

procedure TPDBModule.AddUnit(BuildState: TPDBBuildState);
var
  DCUPath: string;
  SC: LLVM_SectionContrib;
begin
  // Add a module descriptor for every DCU file. We need to put an absolute
  // path to the DCU into the PDB.
  DCUPath := FindDCUInSearchPaths(string(UTF8String(BuildState.FTDSParser.Names[FModSec.name])) +
    '.dcu');
  FModInfoBuilder := BuildState.FDBIBuilder.addModuleInfo(DCUPath);
  FModInfoBuilder.setObjFileName(DCUPath);

  SC := CreateSectionContrib(BuildState);
  FModInfoBuilder.setFirstSectionContrib(SC);

  // Type information doesn't need to be merged as it's already merged from the TDS format

  // Add in symbols
  BuildSymbols(BuildState);

  // Create subsections:
  // 1) String Tables - Built here, but emitted globally as there's one per PDB.
  // 2) File Checksums - Built here, emitted in this module.
  // 3) Lines - Converted from loaded TDS info and emitted in this module.
  // 4) Frame Data - No TDS provided frame data, so it's not emitted globally.
  // 5) Symbols - Already in a global list, emitted globally.
  BuildModuleSubsections(BuildState);
end;

function toCodeViewMachine(Machine: WORD): UInt16;
begin
  case Machine of
    IMAGE_FILE_MACHINE_I386:
      Result := CV_CFL_80386;
    IMAGE_FILE_MACHINE_AMD64:
      Result := CV_CFL_X64;
  else
    Writeln(ErrOutput, Format('Unknown machine type: %.4x', [Machine]));
    ExitCode := -1;
    Halt;
    Result := 0;
  end;
end;

function SkipFirstParam(Params: PChar): PChar;
begin
  Result := Params;
  // Skip initial whitespace
  while Result[0].IsWhiteSpace do Inc(Result);
  if Result[0] = '"' then begin
    Inc(Result);
    // Quoted
    while Result[0] <> #0 do begin
      if Result[0] = '"' then begin
        if Result[1] = '"' then
          Inc(Result, 2)
        else begin
          Inc(Result);
          Break;
        end;
      end
      else
        Inc(Result);
    end;
  end
  else
    // Unquoted
    while (Result^ <> #0) and (not Result^.IsWhiteSpace) do Inc(Result);
end;

procedure TPDBModule.AddCommonLinkerModuleSymbols(BuildState: TPDBBuildState);
var
  pONS: POBJNAMESYM;
  pCS: PCOMPILESYM3;
  pEBS: PENVBLOCKSYM;
  symLen: Integer;
  EBSStrs: TList<UTF8String>;
  tempCmdLine: string;
  I: Integer;
  envStr: PAnsiChar;
  symVar: OleVariant;
  rawData: Pointer;
begin
  pONS := nil;
  pCS := nil;
  pEBS := nil;
  EBSStrs := nil;
  try
    symLen := PadSymLen(SizeOf(OBJNAMESYM) - SizeOf(pONS^.name) +
      Length(BuildState.LINKER_NAME) + 1);
    GetMem(pONS, symLen);
    FillChar(pONS^, symLen, 0);
    with pONS^ do begin
      reclen := symLen - SizeOf(reclen);
      rectyp := S_OBJNAME;
      signature := 0;
      System.AnsiStrings.StrCopy(@name[0], PAnsiChar(BuildState.LINKER_NAME));
    end;

    symLen := PadSymLen(SizeOf(COMPILESYM3) - SizeOf(pCS^.verSz) + Length(BuildState.CONV_NAME) + 1);
    GetMem(pCS, symLen);
    FillChar(pCS^, symLen, 0);
    with pCS^ do begin
      reclen := symLen - SizeOf(reclen);
      rectyp := S_COMPILE3;
      machine := toCodeViewMachine(
        BuildState.FTDSParserImage.LoadedImage.FileHeader^.FileHeader.Machine);
      // Interestingly, if we set the string to 0.0.0.0, then when trying to view
      // local variables WinDbg emits an error that private symbols are not present.
      // By setting this to a valid MSVC linker version string, local variables are
      // displayed properly.   As such, even though it is not representative of
      // LLVM's version information, we need this for compatibility.
      verBuild := 25019;
      verMajor := 14;
      verMinor := 10;
      verQFE := 0;

      // MSVC also sets the frontend to 0.0.0.0 since this is specifically for the
      // linker module (which is by definition a backend), so we don't need to do
      // anything here.  Also, it seems we can use "LLVM Linker" for the linker name
      // without any problems.  Only the backend version has to be hardcoded to a
      // magic number.
      verFEBuild := 0;
      verFEMajor := 0;
      verFEMinor := 0;
      verFEQFE := 0;
      System.AnsiStrings.StrCopy(@verSz[0], PAnsiChar(BuildState.CONV_NAME));
      flags.iLanguage := CV_CFL_LINK;
    end;

    EBSStrs := TList<UTF8String>.Create;
    EBSStrs.Add('cwd');
    EBSStrs.Add(UTF8String(TDirectory.GetCurrentDirectory));
    EBSStrs.Add('exe');
    EBSStrs.Add(UTF8String(TPath.GetFullPath(ParamStr(0))));
    EBSStrs.Add('pdb');
    EBSStrs.Add(UTF8String(TTDSToPDBOptions.OutputFile));
    EBSStrs.Add('cmd');
    tempCmdLine := string(CmdLine);
    EBSStrs.Add(UTF8String(SkipFirstParam(PChar(tempCmdLine))));
    symLen := SizeOf(ENVBLOCKSYM) - SizeOf(pEBS^.rgsz) + EBSStrs.Count + 1;
    for I := 0 to EBSStrs.Count - 1 do
      Inc(symLen, Length(EBSStrs[I]));
    symLen := PadSymLen(symLen);
    GetMem(pEBS, symLen);
    FillChar(pEBS^, symLen, 0);
    with pEBS^ do begin
      reclen := symLen - SizeOf(reclen);
      rectyp := S_ENVBLOCK;
      envStr := @rgsz[0];
    end;
    for I := 0 to EBSStrs.Count - 1 do begin
      envStr := System.AnsiStrings.StrECopy(envStr, PAnsiChar(EBSStrs[I]));
      Inc(envStr);
    end;
    envStr^ := #0;

    symVar := VarArrayCreate([0, pONS^.reclen + SizeOf(pONS^.reclen) - 1], varByte);
    rawData := VarArrayLock(symVar);
    try
      Move(pONS^, rawData^, pONS^.reclen + SizeOf(pONS^.reclen));
    finally
      VarArrayUnlock(symVar);
    end;
    FModInfoBuilder.addSymbol(symVar);

    symVar := VarArrayCreate([0, pCS^.reclen + SizeOf(pCS^.reclen) - 1], varByte);
    rawData := VarArrayLock(symVar);
    try
      Move(pCS^, rawData^, pCS^.reclen + SizeOf(pCS^.reclen));
    finally
      VarArrayUnlock(symVar);
    end;
    FModInfoBuilder.addSymbol(symVar);

    symVar := VarArrayCreate([0, pEBS^.reclen + SizeOf(pEBS^.reclen) - 1], varByte);
    rawData := VarArrayLock(symVar);
    try
      Move(pEBS^, rawData^, pEBS^.reclen + SizeOf(pEBS^.reclen));
    finally
      VarArrayUnlock(symVar);
    end;
    FModInfoBuilder.addSymbol(symVar);
  finally
    FreeMem(pONS);
    FreeMem(pCS);
    FreeMem(pEBS);
    EBSStrs.Free;
  end;
end;

{$IF Defined(CPUX86) or Defined(CPUX64)}
function ExactLog2(Input: LongWord): LongWord;
asm
  BSR EAX, Input
end;
{$ENDIF}

procedure TPDBModule.AddLinkerModuleSectionSymbols(BuildState: TPDBBuildState);
var
  I,
  secIdx: Integer;
  secHead: TImageSectionHeader;
  pSecSym: PSECTIONSYM;
  symLen: Integer;
  secName: UTF8String;
  symVar: OleVariant;
  rawData: Pointer;
begin
  if FModSec <> nil then Exit; // Only applicable to '* Linker *' module
  secIdx := 1;
  for I := 0 to BuildState.FTDSParserImage.ImageSectionCount - 1 do begin
    secHead := BuildState.FTDSParserImage.ImageSectionHeaders[I];
    setLength(secName, 8);
    System.AnsiStrings.StrLCopy(@secName[1], @secHead.Name[0], SizeOf(secHead.Name));
    secName := UTF8String(PAnsiChar(secName));
    // The .debug section will be going away
    if secName = '.debug' then Continue;
    symLen := PadSymLen(SizeOf(SECTIONSYM) - SizeOf(pSecSym^.name) + Length(secName) + 1);
    GetMem(pSecSym, symLen);
    FillChar(pSecSym^, symLen, 0);
    with pSecSym^ do begin
      reclen := symLen - SizeOf(reclen);
      rectyp := S_SECTION;
      isec := secIdx;
      case BuildState.FTDSParserImage.Target of
        taWin32:
          align := ExactLog2(BuildState.FTDSParserImage.OptionalHeader32.SectionAlignment);
        taWin64:
          align := ExactLog2(BuildState.FTDSParserImage.OptionalHeader64.SectionAlignment);
      end;
      rva := secHead.VirtualAddress;
      cb := secHead.SizeOfRawData;
      characteristics := secHead.Characteristics;
      System.AnsiStrings.StrCopy(@name[0], PAnsiChar(secName));
      Inc(secIdx);
    end;

    symVar := VarArrayCreate([0, symLen - 1], varByte);
    rawData := VarArrayLock(symVar);
    try
      Move(pSecSym^, rawData^, symLen);
    finally
      VarArrayUnlock(symVar);
    end;
    FModInfoBuilder.addSymbol(symVar);
  end;
end;

procedure TPDBBuildState.AddTypeInfo;
var
  tpiBuilder: ILLVMTpiStreamBuilder;
  ipiBuilder: ILLVMTpiStreamBuilder;
  I: Integer;
  tempType: PTYPTYPE;
  typVar: OleVariant;
  rawData: Pointer;
  typLen: Integer;
  tempStr: UTF8String;
begin
  tpiBuilder := FBuilder.getTpiBuilder;
  tpiBuilder.setVersionHeader(PdbRaw_TpiVer_PdbTpiV80);
  for I := $1000 to FTypesConverter.CVTypes.Count - 1 do begin
    tempType := FTypesConverter.CVTypes[I];
    typVar := VarArrayCreate([0, tempType.len + SizeOf(tempType.len) - 1], varByte);
    rawData := VarArrayLock(typVar);
    try
      Move(FTypesConverter.CVTypes[I]^, rawData^, tempType.len + SizeOf(tempType.len));
    finally
      VarArrayUnlock(typVar);
    end;
    tpiBuilder.addTypeRecord(typVar, VarAsType(FPDBUtils.hashTypeRecord(typVar), varUInt32));
  end;

  // Unused, but we have to at least write one record for it to be valid
  ipiBuilder := FBuilder.getIpiBuilder;
  ipiBuilder.setVersionHeader(PdbRaw_TpiVer_PdbTpiV80);
  tempStr := 'Dummy string';
  typLen := PadTypLen(SizeOf(PTYPTYPE(nil).len) + SizeOf(lfStringId) -
    SizeOf(PlfStringId(nil).name) + Length(tempStr) + 1);
  typVar := VarArrayCreate([0, typLen - 1], varByte);
  rawData := VarArrayLock(typVar);
  try
    FillChar(rawData^, typLen, 0);
    PTYPTYPE(rawData)^.len := typLen - SizeOf(PTYPTYPE(rawData)^.len);
    with PlfStringId(@PTYPTYPE(rawData)^.leaf)^ do begin
      leaf := LF_STRING_ID;
      id := 0;
      System.AnsiStrings.StrCopy(@name[0], PAnsiChar(tempStr));
    end;
  finally
    VarArrayUnlock(typVar);
  end;
  ipiBuilder.addTypeRecord(typVar, VarAsType(FPDBUtils.hashTypeRecord(typVar), varUInt32));
end;

procedure TPDBBuildState.AddUnitsToPDB;
var
  I: Integer;
  TempMod: TPDBModule;
  tempSym: PSYMTYPE;
  tempSymLen: Integer;
  pubSymVar: OleVariant;
  rawData: Pointer;
  gsiBuilder: ILLVMGSIStreamBuilder;
begin
  for I := 0 to FTDSParser.Modules.Count - 1 do
    if FTDSParser.Modules[I] <> nil then begin
      TempMod := TPDBModule.Create(FTDSParser.Modules[I], I);
      FPDBModules.Add(TempMod);
      TempMod.AddUnit(Self);
    end;

  FBuilder.getStringTableBuilder.setStrings(FStringTableSSBuilder);

  AddTypeInfo;

  // Compute the public and global symbols.
  gsiBuilder := FBuilder.getGsiBuilder;
  // Sort the public symbols and add them to the stream.
  FPublicSymbols.Sort(TComparer<PSYMTYPE>.Construct(
    function(const Left, Right: PSYMTYPE): Integer
    var
      LeftStr, RightStr: PAnsiChar;
    begin
      LeftStr := nil;
      RightStr := nil;
      case Left^.rectyp of
        S_GDATA32,
        S_LDATA32:
          LeftStr := @PDATASYM32(Left)^.name[0];
        S_GPROC32,
        S_LPROC32:
          LeftStr := @PPROCSYM32(Left)^.name[0];
      end;
      case Right^.rectyp of
        S_GDATA32,
        S_LDATA32:
          RightStr := @PDATASYM32(Right)^.name[0];
        S_GPROC32,
        S_LPROC32:
          RightStr := @PPROCSYM32(Right)^.name[0];
      end;
      Result := System.AnsiStrings.StrComp(LeftStr, RightStr);
    end));
  for I := 0 to FPublicSymbols.Count - 1 do begin
    tempSym := FPublicSymbols[I];
    case tempSym^.rectyp of
      S_GDATA32,
      S_LDATA32: begin
        tempSymLen := SizeOf(PUBSYM32) - SizeOf(PPUBSYM32(nil).name) +
          System.AnsiStrings.StrLen(PAnsiChar(@PDATASYM32(tempSym)^.name[0])) + 1;
        pubSymVar := VarArrayCreate([0, tempSymLen - 1], varByte);
        rawData := VarArrayLock(pubSymVar);
        try
          FillChar(rawData^, tempSymLen, 0);
          with PPUBSYM32(rawData)^ do begin
            reclen := tempSymLen - SizeOf(PPUBSYM32(nil).reclen);
            rectyp := S_PUB32;
            off := PDATASYM32(tempSym)^.off;
            seg := PDATASYM32(tempSym)^.seg;
            System.AnsiStrings.StrCopy(PAnsiChar(@name[0]),
              PAnsiChar(@PDATASYM32(tempSym)^.name[0]));
          end;
        finally
          VarArrayUnlock(pubSymVar);
        end;
      end;
      S_GPROC32,
      S_LPROC32: begin
        tempSymLen := SizeOf(PUBSYM32) - SizeOf(PPUBSYM32(nil).name) +
          System.AnsiStrings.StrLen(PAnsiChar(@PPROCSYM32(tempSym)^.name[0])) + 1;
        pubSymVar := VarArrayCreate([0, tempSymLen - 1], varByte);
        rawData := VarArrayLock(pubSymVar);
        try
          FillChar(rawData^, tempSymLen, 0);
          with PPUBSYM32(rawData)^ do begin
            reclen := tempSymLen - SizeOf(PPUBSYM32(nil).reclen);
            rectyp := S_PUB32;
            pubsymflags.fFunction := 1;
            off := PPROCSYM32(tempSym)^.off;
            seg := PPROCSYM32(tempSym)^.seg;
            System.AnsiStrings.StrCopy(PAnsiChar(@name[0]),
              PAnsiChar(@PPROCSYM32(tempSym)^.name[0]));
          end;
        finally
          VarArrayUnlock(pubSymVar);
        end;
      end;
    end;
    gsiBuilder.addPublicSymbol(pubSymVar);
  end;
end;

procedure TPDBBuildState.AddSections;
type
  PLLVM_COFF_Section = ^LLVM_COFF_Section;
var
  PdbFilePathNI: ULONG;
  TempMod: TPDBModule;
  I: Integer;
  SC: LLVM_SectionContrib;
  secCount: Integer;
  secHeader: TImageSectionHeader;
  secTblVar: OleVariant;
  rawData: Pointer;
begin
  // It's not entirely clear what this is, but the * Linker * module uses it.
  PdbFilePathNI := FDBIBuilder.addECName(TTDSToPDBOptions.OutputFile);
  TempMod := TPDBModule.Create(nil, -1);
  FPDBModules.Add(TempMod);
  TempMod.FModInfoBuilder := FDbiBuilder.addModuleInfo(WideString(LINKER_NAME));
  TempMod.FModInfoBuilder.setPdbFilePathNI(PdbFilePathNI);
  TempMod.AddCommonLinkerModuleSymbols(Self);

  // Add section contributions. They must be ordered by ascending RVA.
  TempMod.AddLinkerModuleSectionSymbols(Self);
  for I := 0 to FPDBModules.Count - 1 do
    if FPDBModules[I].FModSec <> nil then begin
      SC := FPDBModules[I].CreateSectionContrib(Self);
      self.FDBIBuilder.addSectionContrib(SC);
    end;

  // Add Section Map stream.
  SetLength(FSectionTable, FTDSParserImage.ImageSectionCount);
  secCount := 0;
  for I := 0 to FTDSParserImage.ImageSectionCount - 1 do begin
    // The .debug section will be removed, so ignore it
    if FTDSParserImage.ImageSectionNames[I] = '.debug' then Continue;
    secHeader := FTDSParserImage.ImageSectionHeaders[I];
    FSectionTable[secCount] := PLLVM_COFF_Section(@secHeader)^;
    Inc(secCount);
  end;
  SetLength(FSectionTable, secCount);
  secTblVar := VarArrayCreate([0, SizeOf(LLVM_COFF_Section) * Length(FSectionTable) - 1], varByte);
  rawData := VarArrayLock(secTblVar);
  try
    Move(FSectionTable[0], rawData^, SizeOf(LLVM_COFF_Section) * Length(FSectionTable));
  finally
    VarArrayUnlock(secTblVar);
  end;
  FDBIBuilder.setSectionMap(secTblVar);

  // Add COFF section header stream.
  FDBIBuilder.addDbgStream(DbgHeaderType_SectionHdr, secTblVar);
end;

procedure TPDBBuildState.Commit;
begin
  FBuilder.commit(TTDSToPDBOptions.OutputFile, FBuildId^.rsdsi.guidSig);
end;

procedure CreatePDB(BuildId: PCVDebugInfoInImage; TDSParserImage: TPeBorTDSParserImage;
  TypesConverter: TTDSToPDBTypesConverter; SymbolsConverter: TTDSToPDBSymbolsConverter);
var
  PDBBuildState: TPDBBuildState;
begin
  PDBBuildState := TPDBBuildState.Create(BuildId, TDSParserImage, TypesConverter, SymbolsConverter);
  try
    PDBBuildState.Initialize;
    PDBBuildState.AddUnitsToPDB;
    PDBBuildState.AddSections;

    PDBBuildState.Commit;
  finally
    PDBBuildState.Free;
  end;
end;

(*procedure BuildPDB(TDSParser: TTDSParser; TypesConverter: TTDSToPDBTypesConverter;
  SymbolsConverter: TTDSToPDBSymbolsConverter; out PDBGUID: TGUID);
var
  I, J: Integer;
  pdbUtils: ILLVMPDBUtilities;
  allocator: ILLVMBumpPtrAllocator;
  builder: ILLVMPDBFileBuilder;
  msfBuilder: ILLVMMSFBuilder;
  infoBuilder: ILLVMInfoStreamBuilder;
  dbiBuilder: ILLVMDbiStreamBuilder;
  gsiBuilder: ILLVMGSIStreamBuilder;
  modiBuilders: TList<ILLVMDbiModuleDescriptorBuilder>;
  strTableSSBuilder: ILLVMDebugStringTableSubsection;
  chksumSSBuilder: ILLVMDebugChecksumsSubsection;
  linesSSBuilder: ILLVMDebugLinesSubsection;
  tpiBuilder: ILLVMTpiStreamBuilder;
  rawData: Pointer;
  modLines: TList<TTDSParser.TSourceLine>;
  modProcs: TList<PPROCSYM32>;
  lineIdx: Integer;
  procEnd: CV_uoff32_t;
  needNewStrTblBuilder,
  needNewChksumBuilder,
  needNewLineBuilder: Boolean;
  fileName,
  fullFileName: string;
  tempType: PTYPTYPE;
  chksummedFiles: TDictionary<string, Integer>;
  symVar: OleVariant;
  typVar: OleVariant;
  tempSym: PSYMTYPE;
  tempSymLen: Integer;
  globTypVar: OleVariant;

  globSymsName: string;
  globSyms: TStreamWriter;
begin
  chksummedFiles := nil;
  modiBuilders := nil;
  try
    pdbUtils := CoLLVMPDBUtilities.Create;
    allocator := CoLLVMBumpPtrAllocator.Create;
    builder := CoLLVMPDBFileBuilder.Create;
    builder.construct(allocator);
    builder.initialize(4096);
    msfBuilder := builder.getMsfBuilder;
    for I := 0 to SpecialStream_kSpecialStreamCount - 1 do
      msfBuilder.addStream(0);

    infoBuilder := builder.getInfoBuilder;
    infoBuilder.setVersion(PdbImplVC70);
    infoBuilder.setHashPDBContentsToGUID(True);

    // dummy subsection to gather strings for entire pdb...will be converted to pdb string table at
    // the end
    needNewStrTblBuilder := True;
    strTableSSBuilder := nil;

    // Build up modules and symbols
    dbiBuilder := builder.getDbiBuilder;
    dbiBuilder.setAge(1);
    dbiBuilder.setVersionHeader(PdbDbiV70);
    dbiBuilder.setMachineType(PDB_Machine_x86);
    dbiBuilder.setBuildNumberMajorMinor(14, 11);

    // Build up global symbols
    gsiBuilder := builder.getGsiBuilder;

    globSymsName :=
      TPath.Combine(
        TPath.GetDirectoryName(TTDSToPDBOptions.OutputFile),
        TPath.GetFileNameWithoutExtension(TTDSToPDBOptions.OutputFile) + '_GlobalSyms.txt');
    if TFile.Exists(globSymsName) then
      TFile.Delete(globSymsName);

    // for each module
    chksummedFiles := TDictionary<string, Integer>.Create;
    modiBuilders := TList<ILLVMDbiModuleDescriptorBuilder>.Create;
    modiBuilders.Count := TDSParser.Modules.Count;
    for I := 0 to TDSParser.Modules.Count-1 do
      if TDSParser.Modules[I] <> nil then begin
        chksummedFiles.Clear;
        modiBuilders[I] := dbiBuilder.addModuleInfo(
          string(UTF8String(TDSParser.Names[TDSParser.Modules[I].name])));
        modiBuilders[I].setObjFileName(string(UTF8String(TDSParser.Names[TDSParser.Modules[I].name])));

        // add symbols
        symVar := VarArrayCreate([0, SymbolsConverter.CVSymbolsSize[I] - 1], varByte);
        rawData := VarArrayLock(symVar);
        try
          Move(SymbolsConverter.CVSymbols[I][0]^, rawData^, SymbolsConverter.CVSymbolsSize[I]);
        finally
          VarArrayUnlock(symVar);
        end;
        modiBuilders[I].addSymbolsInBulk(symVar);

        // add global symbols
        globSyms := TStreamWriter.Create(globSymsName, True);
        for J := 0 to SymbolsConverter.CVSymbols[I].Count - 1 do begin
          globTypVar := Null;
          tempSym := SymbolsConverter.CVSymbols[I][J];
          case tempSym^.rectyp of
            S_CONSTANT,
            S_UDT,
            S_GDATA32,
            S_LDATA32: begin
              tempSymLen := tempSym^.reclen + SizeOf(tempSym^.reclen);
              globTypVar := VarArrayCreate([0, tempSymLen], varByte);
              rawData := VarArrayLock(globTypVar);
              try
                Move(tempSym^, rawData^, tempSymLen);
              finally
                VarArrayUnlock(globTypVar);
              end;
            end;
            S_GPROC32,
            S_LPROC32: begin
              tempSymLen := SizeOf(PREFSYM2(rawData)^) - SizeOf(PREFSYM2(rawData)^.name) +
                System.AnsiStrings.StrLen(PAnsiChar(@PPROCSYM32(tempSym).name[0])) + 1;
              globTypVar := VarArrayCreate([0, tempSymLen], varByte);
              rawData := VarArrayLock(globTypVar);
              try
                with PREFSYM2(rawData)^ do begin
                  reclen := tempSymLen - SizeOf(PREFSYM2(rawData)^.reclen);
                  if tempSym^.rectyp = S_GPROC32 then
                    rectyp := S_PROCREF
                  else
                    rectyp := S_LPROCREF;
                  sumName := 0;
                  ibSym := UInt32(NativeUInt(tempSym) - NativeUInt(SymbolsConverter.CVSymbols[I][0]));
                  imod := I + 1;
                  System.AnsiStrings.StrCopy(PAnsiChar(@name[0]), PAnsiChar(@PPROCSYM32(tempSym).name[0]));
                end;
              finally
                VarArrayUnlock(globTypVar);
              end;
            end;
          end;
//          case tempSym^.rectyp of
//            S_CONSTANT:
//              globSyms.WriteLine('S_CONSTANT: %s',
//                [UTF8String(PAnsiChar(@PCONSTSYM(tempSym)^.name[0]))]);
//            S_UDT: begin
//              globSyms.WriteLine('S_UDT: %s (%.8x)',
//                [UTF8String(PAnsiChar(@PUDTSYM(tempSym)^.name[0])), PUDTSYM(tempSym)^.typind]);
//            end;
//            S_GDATA32:
//              globSyms.WriteLine('S_GDATA32: %s',
//                [UTF8String(PAnsiChar(@PDATASYM32(tempSym)^.name[0]))]);
//            S_LDATA32:
//              globSyms.WriteLine('S_LDATA32: %s',
//                [UTF8String(PAnsiChar(@PDATASYM32(tempSym)^.name[0]))]);
//            S_GPROC32:
//              globSyms.WriteLine('S_GPROC32: %s',
//                [UTF8String(PAnsiChar(@PPROCSYM32(tempSym)^.name[0]))]);
//            S_LPROC32:
//              globSyms.WriteLine('S_LPROC32: %s',
//                [UTF8String(PAnsiChar(@PPROCSYM32(tempSym)^.name[0]))]);
//          end;
          if not VarIsNull(globTypVar) then gsiBuilder.addGlobalSymbol(globTypVar);
        end;
        FreeAndNil(globSyms);

        // add line info subsection and other prerequisites
        needNewChksumBuilder := True;
        modLines := TDSParser.SourceLines[I];
        modProcs := SymbolsConverter.CVProcs[I];
        if Assigned(modLines) and Assigned(modProcs) then begin
          for J := 0 to modProcs.Count - 1 do begin
            modLines.BinarySearch(TTDSParser.TSourceLine.Create(I, '', modProcs[J].seg,
              modProcs[J].off, 0), lineIdx);
            procEnd := modProcs[J].off + modProcs[J].len;
            needNewLineBuilder := True;
            fileName := '';
            linesSSBuilder := nil;
            while (lineIdx < modLines.Count) and (modLines[lineIdx].offset < procEnd) do begin
              if needNewLineBuilder then begin
                if needNewChksumBuilder then begin
                  if needNewStrTblBuilder then begin
                    strTableSSBuilder := CoLLVMDebugStringTableSubsection.Create;
                    needNewStrTblBuilder := False;
                  end;
                  chksumSSBuilder := CoLLVMDebugChecksumsSubsection.Create;
                  chksumSSBuilder.construct(BuildState.FAllocator, strTableSSBuilder);
                end;
                linesSSBuilder := CoLLVMDebugLinesSubsection.Create;
                linesSSBuilder.construct(chksumSSBuilder, strTableSSBuilder);
                linesSSBuilder.setCodeSize(modProcs[J].len);
                linesSSBuilder.setRelocationAddress(modProcs[J].seg, modProcs[J].off);
                needNewLineBuilder := False;
              end;
              if modLines[lineIdx].filename <> fileName then begin
                fileName := modLines[lineIdx].filename;
                if not chksummedFiles.ContainsKey(fileName) then begin
                  chksummedFiles.Add(fileName, 0);
                  fullFileName := FindSourceFileInSearchPaths(fileName);
                  chksumSSBuilder.addChecksum(fullFileName, FileChecksumKind_None, Null);
                  dbiBuilder.addModuleSourceFile(modiBuilders[I], fullFileName);
                end;
                linesSSBuilder.createBlock(FindSourceFileInSearchPaths(fileName));
              end;
              linesSSBuilder.addLineInfo(modLines[lineIdx].offset - modProcs[J].off,
                modLines[lineIdx].linenumber, modLines[lineIdx].linenumber, True);
              Inc(lineIdx);
            end;
            if linesSSBuilder <> nil then begin
              if needNewChksumBuilder then begin
                modiBuilders[I].addDebugSubsection(chksumSSBuilder);
                needNewChksumBuilder := False;
              end;
              modiBuilders[I].addDebugSubsection(linesSSBuilder);
            end;
          end;
        end;
      end;

    // add types
    tpiBuilder := builder.getTpiBuilder;
    tpiBuilder.setVersionHeader(PdbRaw_TpiVer_PdbTpiV80);
    for I := $1000 to TypesConverter.CVTypes.Count - 1 do begin
      tempType := TypesConverter.CVTypes[I];
      typVar := VarArrayCreate([0, tempType.len + SizeOf(tempType.len) - 1], varByte);
      rawData := VarArrayLock(typVar);
      try
        Move(TypesConverter.CVTypes[I]^, rawData^, tempType.len + SizeOf(tempType.len));
      finally
        VarArrayUnlock(typVar);
      end;
      tpiBuilder.addTypeRecord(typVar, VarAsType(pdbUtils.hashTypeRecord(typVar), varUInt32));
    end;

    // add pdb string table
    if strTableSSBuilder
     <> nil then
      builder.getStringTableBuilder.setStrings(strTableSSBuilder);

    builder.commit(TTDSToPDBOptions.OutputFile, PDBGUID);
  finally
    modiBuilders.Free;
    chksummedFiles.Free;
  end;
end;*)

function StripExecutableAndAddGUID(var ParserImage: TPeBorTDSParserImage;
  BuildId: PCVDebugInfoInImage): UInt32;
var
  DebugSizeActual,
  DebugSizeFile,
  OldDebugSizeFile,
  DebugSizeVirtual: UInt32;
  DebugSectionHeader: PImageSectionHeader;
  DataDir: PImageDataDirectory;
  NewDebugDirectoryPointer: PImageDebugDirectory;
  CVDataPointer: PByte;
  OldCheckSum: DWORD;
begin
  // Figure out required debug size. The updated section contains the updated debug directory and
  // the PDB locator information. Round up to a multiple of the PE/COFF file alignment and section
  // alignment.
  DebugSizeActual := SizeOf(TImageDebugDirectory) + BuildId^.Size;
  Assert(ParserImage.Target in [taWin32, taWin64]);
  case ParserImage.Target of
    taWin32: begin
      if DebugSizeActual mod ParserImage.OptionalHeader32.FileAlignment > 0 then
        DebugSizeFile := DebugSizeActual + ParserImage.OptionalHeader32.FileAlignment -
          (DebugSizeActual mod ParserImage.OptionalHeader32.FileAlignment)
      else
        DebugSizeFile := DebugSizeActual;
      if DebugSizeActual mod ParserImage.OptionalHeader32.SectionAlignment > 0 then
        DebugSizeVirtual := DebugSizeActual + ParserImage.OptionalHeader32.SectionAlignment -
          (DebugSizeActual mod ParserImage.OptionalHeader32.SectionAlignment)
      else
        DebugSizeVirtual := DebugSizeActual;
    end;
    taWin64: begin
      if DebugSizeActual mod ParserImage.OptionalHeader64.FileAlignment > 0 then
        DebugSizeFile := DebugSizeActual + ParserImage.OptionalHeader64.FileAlignment -
          (DebugSizeActual mod ParserImage.OptionalHeader64.FileAlignment)
      else
        DebugSizeFile := DebugSizeActual;
      if DebugSizeActual mod ParserImage.OptionalHeader64.SectionAlignment > 0 then
        DebugSizeVirtual := DebugSizeActual + ParserImage.OptionalHeader64.SectionAlignment -
          (DebugSizeActual mod ParserImage.OptionalHeader64.SectionAlignment)
      else
        DebugSizeVirtual := DebugSizeActual;
    end;
  else
    // won't ever reach here because of the assertion above
    DebugSizeFile := 0;
    DebugSizeVirtual := 0;
  end;

  // Ensure debugging information is *only* in .debug and that .debug is last as it ought to be.
  // Also ensure that current debugging section is sufficiently large to hold new information. There
  // shouldn't ever be a situation where this isn't the case (System.pas debug information by itself
  // is *huge*), but do the check anyway. Also check that there's no .buildid section.
  Assert(ParserImage.DirectoryExists[IMAGE_DIRECTORY_ENTRY_DEBUG]);
  Assert(
    ParserImage.ImageSectionNameFromRVA[
      ParserImage.Directories[IMAGE_DIRECTORY_ENTRY_DEBUG].VirtualAddress] =
    '.debug');
  Assert(ParserImage.ImageSectionNames[ParserImage.ImageSectionCount - 1] = '.debug');
  Assert(not ParserImage.GetSectionHeader('.buildid', DebugSectionHeader));
  Assert(ParserImage.GetSectionHeader('.debug', DebugSectionHeader));
  Assert(DebugSectionHeader.SizeOfRawData >= DebugSizeFile);

  // Ensure debug directory points to beginning of the section. We need to distinguish PE32 from
  // PE32+ because alignment changes in the optional header starting with the SizeOfStackReserve
  // entry.
  case ParserImage.Target of
    taWin32:
      DataDir :=
        @PImageNtHeaders32(ParserImage.LoadedImage.FileHeader)^.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_DEBUG];
    taWin64:
      DataDir :=
        @PImageNtHeaders64(ParserImage.LoadedImage.FileHeader)^.OptionalHeader.DataDirectory[IMAGE_DIRECTORY_ENTRY_DEBUG];
  else
    DataDir := nil; // won't ever reach here because of the assertion above
  end;
  DataDir^.VirtualAddress := DebugSectionHeader.VirtualAddress;
  DataDir^.Size := SizeOf(TImageDebugDirectory);

  // Get debug directory and CV data pointers
  NewDebugDirectoryPointer := ParserImage.RvaToVa(DataDir^.VirtualAddress);
  CVDataPointer := PByte(NewDebugDirectoryPointer);
  Inc(PImageDebugDirectory(CVDataPointer));

  // Zero out new debug section.
  FillChar(NewDebugDirectoryPointer^, DebugSizeFile, 0);

  // Set up debug directory in section
  with NewDebugDirectoryPointer^ do begin
    TimeDateStamp := ParserImage.LoadedImage.FileHeader^.FileHeader.TimeDateStamp;
    MajorVersion := 14;
    MinorVersion := 11;
    _Type := IMAGE_DEBUG_TYPE_CODEVIEW;
    SizeOfData := BuildId^.Size;
    AddressOfRawData := DebugSectionHeader^.VirtualAddress + NativeUInt(CVDataPointer) -
      NativeUInt(NewDebugDirectoryPointer);
    PointerToRawData := DebugSectionHeader^.PointerToRawData + NativeUInt(CVDataPointer) -
      NativeUInt(NewDebugDirectoryPointer);
  end;

  // Move PDB locator info to section
  Move(BuildId^, CVDataPointer^, BuildId^.Size);

  // Update section info
  with DebugSectionHeader^ do begin
    FillChar(Name, SizeOf(Name), 0);
    Move(PAnsiChar(UTF8String('.buildid'))^, Name, Length(UTF8String('.buildid')));
    Misc.VirtualSize := DebugSizeActual;
    OldDebugSizeFile := SizeOfRawData;
    SizeOfRawData := DebugSizeFile;
  end;

  // Calculate new executable file size
  Result := ParserImage.FileProperties.Size - OldDebugSizeFile + DebugSizeFile;

  // Update PE/COFF header. Because this just takes either the PE32 or PE32+ header, we can only
  // modify header entries before the SizeOfStackReserve entry without making a distinction.
  with ParserImage.LoadedImage.FileHeader^.OptionalHeader do begin
    SizeOfInitializedData := SizeOfInitializedData - OldDebugSizeFile + DebugSizeFile;
    SizeOfImage := DebugSectionHeader^.VirtualAddress + DebugSizeVirtual;
    // This must be done manually since we'll actually change the size of the executable
    CheckSumMappedFile(ParserImage.LoadedImage.MappedAddress, Result, OldCheckSum, CheckSum);
  end;
end;

procedure WritelnWrapped(const OutputVar: Text; TheText, BreakStr: string; BreakChars: TArray<Char>;
  MaxLen: Integer);
var
  OutStrStart,
  OutStrTempEnd,
  OutStrEnd,
  Count: Integer;
  I: Integer;
begin
  OutStrStart := 1;
  OutStrTempEnd := 1;
  OutStrEnd := 1;
  Count := 0;
  while OutStrEnd <= Length(TheText) do begin
    if Count >= MaxLen then begin
      if OutStrTempEnd = OutStrStart then // no break chars
        OutStrTempEnd := OutStrEnd;
      Writeln(OutputVar, Copy(TheText, OutStrStart, OutStrTempEnd - OutStrStart + 1));
      Write(OutputVar, BreakStr);
      Count := Length(BreakStr) + OutStrEnd - OutStrTempEnd;
      OutStrStart := OutStrTempEnd + 1;
      OutStrTempEnd := OutStrStart;
    end;
    for I := 1 to Length(BreakChars) do
      if TheText[OutStrEnd] = BreakChars[I] then
        OutStrTempEnd := OutStrEnd;
    Inc(Count);
    Inc(OutStrEnd);
  end;
  if OutStrStart <= Length(TheText) then
    Writeln(OutputVar, Copy(TheText, OutStrStart, Length(TheText) - OutStrStart + 1));
end;

procedure PrintOption(const OutputVar: Text; const OptRec: TTDSToPDBOptions.TOptionRec);
const
  LineWidth: Integer = 80;
  LongWidth: Integer = 15;
  ShortWidth: Integer = 5;
  BreakChars: TArray<Char> = ['.', ',', #$09, '-', ' '];
var
  FormatSpec,
  OptionText,
  SpacingText,
  TempLongName,
  TempShortName: string;
begin
  FormatSpec := ' %-' + LongWidth.ToString + 's %-' + ShortWidth.ToString + 's ';
  if OptRec.Opt.IsUnnamed then begin
    TempLongName := OptRec.FakeName;
    TempShortName := '';
  end
  else begin
    TempLongName := OptRec.Opt.LongName;
    TempShortName := OptRec.Opt.ShortName;
    if not string.IsNullOrWhiteSpace(TempLongName) then TempLongName := '-' + TempLongName;
    if not string.IsNullOrWhiteSpace(TempShortName) then TempShortName := '(-' + TempShortName + ')';
  end;
  OptionText := Format(FormatSpec, [TempLongName, TempShortName]);
  SpacingText := StringOfChar(' ', Length(OptionText));
  WritelnWrapped(OutputVar, OptionText + OptRec.Opt.HelpText, SpacingText, BreakChars, LineWidth);
end;

procedure PrintUsage(const OutputVar: Text);
var
  I: Integer;
  SyntaxStr: string;
begin
  Writeln(OutputVar, 'Syntax:');
  SyntaxStr := ' %s [options] ';
  for I := 0 to TTDSToPDBOptions.Options.Count - 1 do begin
    if TTDSToPDBOptions.Options[I].Opt.IsUnnamed then begin
      if TTDSToPDBOptions.Options[I].Opt.Required then
        SyntaxStr := SyntaxStr + TTDSToPDBOptions.Options[I].FakeName + ' '
      else
        SyntaxStr := SyntaxStr + '[' + TTDSToPDBOptions.Options[I].FakeName + '] ';
    end;
  end;
  Writeln(OutputVar, Format(SyntaxStr, [TPath.GetFileNameWithoutExtension(ParamStr(0))]));
  Writeln(OutputVar);
  Writeln(OutputVar, 'Parameters:');
  for I := 0 to TTDSToPDBOptions.Options.Count - 1 do
    PrintOption(OutputVar, TTDSToPDBOptions.Options[I]);
end;

procedure ProcessOptions;
var
  CmdLineParseResult: ICommandLineParseResult;
  I, J: Integer;
  FileNames: TStringDynArray;
begin
  CmdLineParseResult := TOptionsRegistry.Parse;
  if CmdLineParseResult.HasErrors then begin
    Writeln(ErrOutput, Format('Invalid command line: %s', [CmdLineParseResult.ErrorText]));
    PrintUsage(ErrOutput);
    ExitCode := -1;
    Halt;
  end;

  if TTDSToPDBOptions.ShowHelp then begin
    PrintUsage(Output);
    Halt;
  end;

  // Check input file
  if string.IsNullOrWhiteSpace(TTDSToPDBOptions.InputFile) then begin
    Writeln(ErrOutput, 'Invalid command line: inputfile not specified.');
    Writeln(ErrOutput);
    PrintUsage(ErrOutput);
    ExitCode := -1;
    Halt;
  end;
  if not TFile.Exists(TTDSToPDBOptions.InputFile) then begin
    Writeln(ErrOutput,
      Format('Input file %s does not exist.', [TTDSToPDBOptions.InputFile]));
    ExitCode := -1;
    Halt;
  end;
  TTDSToPDBOptions.InputFile := TPath.GetFullPath(TTDSToPDBOptions.InputFile);

  // Set output file appropriately if necessary
  if string.IsNullOrWhiteSpace(TTDSToPDBOptions.OutputFile) then begin
    TTDSToPDBOptions.OutputFile := TPath.ChangeExtension(TTDSToPDBOptions.InputFile, 'pdb');
  end;
  TTDSToPDBOptions.OutputFile := TPath.GetFullPath(TTDSToPDBOptions.OutputFile);

  // Check all source file search paths
  for I := TTDSToPDBOptions.SearchPaths.Count - 1 downto 0 do begin
    if not TDirectory.Exists(TTDSToPDBOptions.SearchPaths[I].Path) then begin
      Writeln(ErrOutput,
        Format('Unit search path doesn''t exist: %s', [TTDSToPDBOptions.SearchPaths[I].Path]));
      ExitCode := -1;
      Halt;
    end;
    TTDSToPDBOptions.SearchPaths[I].Path := TPath.GetFullPath(TTDSToPDBOptions.SearchPaths[I].Path);
    // Enumerate all files and store them...much faster to build a dictionary now than to search all
    // the paths later.
    if TTDSToPDBOptions.SearchPaths[I].Recursive then
      FileNames := TDirectory.GetFiles(TTDSToPDBOptions.SearchPaths[I].Path, '*',
        TSearchOption.soAllDirectories)
    else
      FileNames := TDirectory.GetFiles(TTDSToPDBOptions.SearchPaths[I].Path, '*',
        TSearchOption.soTopDirectoryOnly);
    for J := Low(FileNames) to High(FileNames) do
      FilesFound.AddOrSetValue(TPath.GetFileName(FileNames[J]), FileNames[J]);
  end;

  // Check all DCU search paths
  for I := TTDSToPDBOptions.DCUSearchPaths.Count - 1 downto 0 do begin
    if not TDirectory.Exists(TTDSToPDBOptions.DCUSearchPaths[I]) then begin
      Writeln(ErrOutput,
        Format('DCU search path doesn''t exist: %s', [TTDSToPDBOptions.DCUSearchPaths[I]]));
      ExitCode := -1;
      Halt;
    end;
    TTDSToPDBOptions.DCUSearchPaths[I] := TPath.GetFullPath(TTDSToPDBOptions.DCUSearchPaths[I]);
    // Enumerate all files and store them...much faster to build a dictionary now than to search all
    // the paths later.
    FileNames := TDirectory.GetFiles(TTDSToPDBOptions.DCUSearchPaths[I], '*.dcu',
      TSearchOption.soTopDirectoryOnly);
    for J := Low(FileNames) to High(FileNames) do
      DCUsFound.AddOrSetValue(TPath.GetFileName(FileNames[J]), FileNames[J]);
  end;
end;

procedure MainProc;
var
  ParserImage: TPeBorTDSParserImage;
  TypesConverter: TTDSToPDBTypesConverter;
  SymbolsConverter: TTDSToPDBSymbolsConverter;
  ExecutableSize: UInt32;
  OutputFile: UTF8String;
  BuildId: PCVDebugInfoInImage;
begin
  ProcessOptions;
  OleCheck(CoInitializeEx(nil, COINIT_APARTMENTTHREADED));
  ParserImage := TPeBorTDSParserImage.Create;
  TypesConverter := nil;
  SymbolsConverter := nil;
  BuildId := nil;
  try
    ParserImage.ReadOnlyAccess := False; // We *will* be modifying it at the end!
    ParserImage.FileName := TTDSToPDBOptions.InputFile;
    if ParserImage.TDSParser = nil then begin
      Writeln(ErrOutput, 'Debug information doesn''t exist within input file.');
      ExitCode := -1;
      Halt;
    end;
    TypesConverter := TTDSToPDBTypesConverter.Create(ParserImage.TDSParser);
    SymbolsConverter := TTDSToPDBSymbolsConverter.Create(ParserImage,
      ParserImage.TDSParser, TypesConverter);

    OutputFile := UTF8String(TTDSToPDBOptions.OutputFile);
    BuildId := TCVDebugInfoInImage.Alloc(PDB70, OutputFile);
    System.AnsiStrings.StrCopy(@BuildId^.rsdsi.szPdb[0], PAnsiChar(OutputFile));

    CreatePDB(BuildId, ParserImage, TypesConverter, SymbolsConverter);
    ExecutableSize := StripExecutableAndAddGUID(ParserImage, BuildId);
  finally
    FreeMem(BuildId);
    SymbolsConverter.Free;
    TypesConverter.Free;
    ParserImage.Free;
    CoUninitialize;
  end;
  with TFile.Open(TTDSToPDBOptions.InputFile, TFileMode.fmOpen) do begin
    Size := ExecutableSize;
    Free;
  end;
end;

initialization
  FilesFound := TDictionary<string, string>.Create(TIStringComparer.Ordinal);
  DCUsFound := TDictionary<string, string>.Create(TIStringComparer.Ordinal);


finalization
  FreeAndNil(FilesFound);
  FreeAndNil(DCUsFound);

end.
