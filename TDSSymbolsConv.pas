unit TDSSymbolsConv;

interface

uses
  System.Classes, System.Generics.Defaults, System.Generics.Collections, TDSInfo, CVInfo, TDSParser,
  TDSTypesConv;

//  Symbol conversions:
//    TDS_S_COMPILE         ->  (nothing)
//    TDS_S_REGISTER        ->  S_LOCAL and S_DEFRANGE_REGISTER
//                              S_REGISTER
//    TDS_S_UDT             ->  S_UDT
//    TDS_S_SSEARCH         ->  (nothing)
//    TDS_S_END             ->  S_END
//    TDS_S_GPROCINFO       ->  (nothing) - Handled by GPROC32 below
//    TDS_S_UNITDEPS        ->  (nothing)
//    TDS_S_UNITDEPSV2      ->  (nothing)
//    TDS_S_UNITDEPSV3      ->  (nothing)
//    TDS_S_SCOPEDCONST     ->  (nothing)
//    TDS_S_BPREL32         ->  S_LOCAL and S_DEFRANGE_FRAMEPOINTER_REL
//                              S_BPREL32
//    TDS_S_LDATA32         ->  S_LDATA32
//    TDS_S_GDATA32         ->  S_GDATA32
//    TDS_S_LPROC32         ->  S_LPROC32
//    TDS_S_GPROC32         ->  S_GPROC32
//    TDS_S_WITH32          ->  (nothing)
//    TDS_S_REGVALIDRANGE   ->  S_LOCAL and S_DEFRANGE_REGISTER
//                              S_REGISTER
//    TDS_S_NESTEDPROCINFO  ->  (nothing) Try letting debugger figure out scoping

type
  TTDSToPDBSymbolsConverter = class;

  TTDSToCVTypeConverterBase = class abstract
  private
    FSymbolsConverter: TTDSToPDBSymbolsConverter;
  public
    constructor Create(SymbolsConverter: TTDSToPDBSymbolsConverter);
    function Convert(pInSym: PTDS_SYMTYPE): UInt32; virtual; abstract;
  end;

  TTDSToPDBSymbolsConverter = class
  private type
    TConverterInfo = class
      FConverter: TTDSToCVTypeConverterBase;
      FName: string;
      FCount: Integer;
      FPublicCount: Integer;
      FSize: Integer;
      constructor Create(AName: string; AConverter: TTDSToCVTypeConverterBase);
      function Convert(pInSym: PTDS_SYMTYPE): UInt32; inline;
      procedure Clear;
    end;
  private const
    POOL_DELTA = 256 * 1024;
  private
    FPEImage: TPeBorTDSParserImage;
    FTDSParser: TTDSParser;
    FTypesConverter: TTDSToPDBTypesConverter;
    FBufferPool: TObjectList<TMemoryStream>;
    FCurrentBuffer: TMemoryStream;
    FSymbolData: TObjectList<TMemoryStream>;
    FSymbolConverters: TObjectDictionary<UInt16, TConverterInfo>;
    FCVSymbols: TObjectList<TList<PSYMTYPE>>;
    FCVSymbolsSize: TList<UInt32>;
    FCVProcs: TObjectList<TList<PPROCSYM32>>;

    FTDSSymOffToCVSymIdx: TDictionary<UInt32, Integer>;
    FCurrentCVSymbols: TList<PSYMTYPE>;
    FCurrentModule: Integer;
    FLastTDSSymbol: PTDS_SYMTYPE;
    procedure AddConverters(Is64Bit: Boolean);
    function AddSymbol(Size: UInt16; out pSym: PSYMTYPE): UInt32;
    procedure Convert;
  public
    constructor Create(PEImage: TPeBorTDSParserImage; TDSParser: TTDSParser;
      TypesConverter: TTDSToPDBTypesConverter);
    destructor Destroy; override;
    property CVSymbols: TObjectList<TList<PSYMTYPE>> read FCVSymbols;
    property CVSymbolsSize: TList<UInt32> read FCVSymbolsSize;
    property CVSymbolData: TObjectList<TMemoryStream> read FSymbolData;
    property CVProcs: TObjectList<TList<PPROCSYM32>> read FCVProcs;
  end;

implementation

uses
  System.AnsiStrings, System.Math, System.SysUtils, JclPeImage, Range, CVConst, TDSUtils;

type
  TTDSToCVSymConverterNoOperation = class(TTDSToCVTypeConverterBase)
  public
    function Convert(pInSym: PTDS_SYMTYPE): UInt32; override;
  end;

  TTDSToCVSymConverterCOMPILE = class(TTDSToCVTypeConverterBase)
  public
    function Convert(pInSym: PTDS_SYMTYPE): UInt32; override;
  end;

  TTDSToCVSymConverterREGISTER = class(TTDSToCVTypeConverterBase)
  public
    function Convert(pInSym: PTDS_SYMTYPE): UInt32; override;
  end;

  TTDSToCVSymConverterUDT = class(TTDSToCVTypeConverterBase)
  public
    function Convert(pInSym: PTDS_SYMTYPE): UInt32; override;
  end;

  TTDSToCVSymConverterSSEARCH = class(TTDSToCVTypeConverterBase)
  public
    function Convert(pInSym: PTDS_SYMTYPE): UInt32; override;
  end;

  TTDSToCVSymConverterEND = class(TTDSToCVTypeConverterBase)
  public
    function Convert(pInSym: PTDS_SYMTYPE): UInt32; override;
  end;

  TTDSToCVSymConverterGPROCREF = class(TTDSToCVTypeConverterBase)
  public
    function Convert(pInSym: PTDS_SYMTYPE): UInt32; override;
  end;

  TTDSToCVSymConverterUSES = class(TTDSToCVTypeConverterBase)
  public
    function Convert(pInSym: PTDS_SYMTYPE): UInt32; override;
  end;

  TTDSToCVSymConverterNAMESPACE = class(TTDSToCVTypeConverterBase)
  public
    function Convert(pInSym: PTDS_SYMTYPE): UInt32; override;
  end;

  TTDSToCVSymConverterUSING = class(TTDSToCVTypeConverterBase)
  public
    function Convert(pInSym: PTDS_SYMTYPE): UInt32; override;
  end;

  TTDSToCVSymConverterPCONST = class(TTDSToCVTypeConverterBase)
  public
    function Convert(pInSym: PTDS_SYMTYPE): UInt32; override;
  end;

  TTDSToCVSymConverterBPREL32 = class(TTDSToCVTypeConverterBase)
  public
    function Convert(pInSym: PTDS_SYMTYPE): UInt32; override;
  end;

  TTDSToCVSymConverterDATA32 = class(TTDSToCVTypeConverterBase)
  public
    function Convert(pInSym: PTDS_SYMTYPE): UInt32; override;
  end;

  TTDSToCVSymConverterLDATA32 = TTDSToCVSymConverterDATA32;
  TTDSToCVSymConverterGDATA32 = TTDSToCVSymConverterDATA32;

  TTDSToCVSymConverterPROC32 = class(TTDSToCVTypeConverterBase)
  public
    function Convert(pInSym: PTDS_SYMTYPE): UInt32; override;
  end;

  TTDSToCVSymConverterLPROC32 = TTDSToCVSymConverterPROC32;
  TTDSToCVSymConverterGPROC32 = TTDSToCVSymConverterPROC32;

  TTDSToCVSymConverterWITH32 = class(TTDSToCVTypeConverterBase)
  public
    function Convert(pInSym: PTDS_SYMTYPE): UInt32; override;
  end;

  TTDSToCVSymConverterOPTVAR32 = class(TTDSToCVTypeConverterBase)
  public
    function Convert(pInSym: PTDS_SYMTYPE): UInt32; override;
  end;

  TTDSToCVSymConverterSLINK32 = class(TTDSToCVTypeConverterBase)
  public
    function Convert(pInSym: PTDS_SYMTYPE): UInt32; override;
  end;

function TTDSToCVSymConverterNoOperation.Convert(pInSym: PTDS_SYMTYPE): UInt32;
begin
  // do nothing
  Result := 0;
end;

function TTDSToCVSymConverterCOMPILE.Convert(pInSym: PTDS_SYMTYPE): UInt32;
begin
  // do nothing
  Result := 0;
end;

function LOCAL_Size(name: PAnsiChar): UInt16;
begin
  Result := SizeOf(LOCALSYM) - SizeOf(PLOCALSYM(nil).name);
  Inc(Result, System.AnsiStrings.StrLen(name) + 1);
end;

procedure LOCAL_Fill(pOutSym: PLOCALSYM; typind: CV_typ_t; name: PAnsiChar);
begin
  pOutSym.rectyp := S_LOCAL;
  pOutSym.typind := typind;
  pOutSym.flags._props := 0; // not doing anything with these right now
  if name = nil then
    pOutSym.name[0] := 0
  else
    System.AnsiStrings.StrCopy(@pOutSym.name[0], name);
end;

function DEFRANGE_REGISTER_Size(numgaps: Integer): UInt16;
begin
  Result := SizeOf(DEFRANGESYMREGISTER) - SizeOf(PDEFRANGESYMREGISTER(nil).gaps);
  Inc(Result, numgaps * SizeOf(CV_LVAR_ADDR_GAP));
end;

procedure DEFRANGE_REGISTER_Fill(pOutSym: PDEFRANGESYMREGISTER; reg: UInt16;
  const range: CV_LVAR_ADDR_RANGE; const ingap: TArray<CV_LVAR_ADDR_GAP>);
var
  I: Integer;
  gap: PCV_LVAR_ADDR_GAP;
begin
{$POINTERMATH ON}
  pOutSym.rectyp := S_DEFRANGE_REGISTER;
  pOutSym.reg := reg;
  pOutSym.attr._props := 0;
  pOutSym.range := range;
  gap := @pOutSym.gaps[0];
  for I := 0 to Length(ingap) - 1 do
    gap[I] := ingap[I];
{$POINTERMATH OFF}
end;

function REGISTER_Size(name: PAnsiChar): UInt16;
begin
  Result := SizeOf(REGSYM) - SizeOf(PREGSYM(nil).name);
  Inc(Result, System.AnsiStrings.StrLen(name) + 1);
end;

procedure REGISTER_Fill(pOutSym: PREGSYM; typind: CV_typ_t; reg: UInt16; name: PAnsiChar);
begin
  pOutSym.rectyp := S_REGISTER;
  pOutSym.typind := typind;
  pOutSym.reg := reg;
  if name = nil then
    pOutSym.name[0] := 0
  else
    System.AnsiStrings.StrCopy(@pOutSym.name[0], name);
end;

function TTDSToCVSymConverterREGISTER.Convert(pInSym: PTDS_SYMTYPE): UInt32;
var
  pTypedSym: PTDS_REGSYM;
  pOutSym: PREGSYM;
begin
  // Currently local variables are only reliable in Win32
  if FSymbolsConverter.FPEImage.Target = taWin32 then begin
    pTypedSym := PTDS_REGSYM(pInSym);
    if pTypedSym.reg = 0 then
      Exit(0); // will be followed by TDS_S_REGVALIDRANGE
    Result := FSymbolsConverter.AddSymbol(
      REGISTER_Size(FSymbolsConverter.FTDSParser.Names[pTypedSym.nameind]),
      PSYMTYPE(pOutSym));
    REGISTER_Fill(
      pOutSym,
      FSymbolsConverter.FTypesConverter.TypeConversions[pTypedSym.typind],
      pTypedSym.reg,
      FSymbolsConverter.FTDSParser.Names[pTypedSym.nameind]);
  end
  else
    Result := 0;
end;

function UDT_Size(name: PAnsiChar): UInt16;
begin
  Result := SizeOf(UDTSYM) - SizeOf(PUDTSYM(nil).name);
  Inc(Result, System.AnsiStrings.StrLen(name) + 1);
end;

procedure UDT_Fill(pOutSym: PUDTSYM; typind: CV_typ_t; name: PAnsiChar);
begin
  pOutSym.rectyp := S_UDT;
  pOutSym.typind := typind;
  if name = nil then
    pOutSym.name[0] := 0
  else
    System.AnsiStrings.StrCopy(@pOutSym.name[0], name);
end;

function TTDSToCVSymConverterUDT.Convert(pInSym: PTDS_SYMTYPE): UInt32;
var
  pTypedSym: PTDS_UDTSYM;
  pOutSym: PUDTSYM;
begin
  pTypedSym := PTDS_UDTSYM(pInSym);
  Result := FSymbolsConverter.AddSymbol(
    UDT_Size(FSymbolsConverter.FTDSParser.Names[pTypedSym.nameind]),
    PSYMTYPE(pOutSym));
  UDT_Fill(
    pOutSym,
    FSymbolsConverter.FTypesConverter.TypeConversions[pTypedSym.typind],
    FSymbolsConverter.FTDSParser.Names[pTypedSym.nameind]);
end;

function SSEARCH_Size: UInt16;
begin
  Result := SizeOf(SEARCHSYM);
end;

procedure SSEARCH_Fill(pOutSym: PSEARCHSYM; startsym: UInt32; seg: UInt16);
begin
  pOutSym.rectyp := S_SSEARCH;
  pOutSym.startsym := startsym;
  pOutSym.seg := seg;
end;

function TTDSToCVSymConverterSSEARCH.Convert(pInSym: PTDS_SYMTYPE): UInt32;
var
  pTypedSym: PTDS_SEARCHSYM;
  pOutSym: PSEARCHSYM;
begin
  pTypedSym := PTDS_SEARCHSYM(pInSym);
  Result := FSymbolsConverter.AddSymbol(SSEARCH_Size, PSYMTYPE(pOutSym));
  SSEARCH_Fill(
    pOutSym,
    pTypedSym.startsym, // will be fixed up
    pTypedSym.seg);
end;

function END_Size: UInt16;
begin
  Result := SizeOf(SYMTYPE);
end;

procedure END_Fill(pOutSym: PSYMTYPE);
begin
  pOutSym.rectyp := S_END;
end;

function TTDSToCVSymConverterEND.Convert(pInSym: PTDS_SYMTYPE): UInt32;
var
  pOutSym: PSYMTYPE;
begin
  Result := FSymbolsConverter.AddSymbol(END_Size, pOutSym);
  END_Fill(pOutSym);
end;

function TTDSToCVSymConverterGPROCREF.Convert(pInSym: PTDS_SYMTYPE): UInt32;
begin
  // do nothing
  Result := 0;
end;

function TTDSToCVSymConverterUSES.Convert(pInSym: PTDS_SYMTYPE): UInt32;
begin
  // do nothing
  Result := 0;
end;

function TTDSToCVSymConverterNAMESPACE.Convert(pInSym: PTDS_SYMTYPE): UInt32;
begin
  // do nothing
  Result := 0;
end;

function TTDSToCVSymConverterUSING.Convert(pInSym: PTDS_SYMTYPE): UInt32;
begin
  // do nothing
  Result := 0;
end;

function TTDSToCVSymConverterPCONST.Convert(pInSym: PTDS_SYMTYPE): UInt32;
begin
  // do nothing
  Result := 0;
end;

function BPREL32_Size(name: PAnsiChar): UInt16;
begin
  Result := SizeOf(BPRELSYM32) - SizeOf(PBPRELSYM32(nil).name);
  Inc(Result, System.AnsiStrings.StrLen(name) + 1);
end;

procedure BPREL32_Fill(pOutSym: PBPRELSYM32; off: CV_off32_t; typind: CV_typ_t; name: PAnsiChar);
begin
  pOutSym.rectyp := S_BPREL32;
  pOutSym.off := off;
  pOutSym.typind := typind;
  if name = nil then
    pOutSym.name[0] := 0
  else
    System.AnsiStrings.StrCopy(@pOutSym.name[0], name);
end;

function DEFRANGE_FRAMEPOINTER_REL_FULL_SCOPE_Size: UInt16;
begin
  Result := SizeOf(DEFRANGESYMFRAMEPOINTERREL_FULL_SCOPE);
end;

procedure DEFRANGE_FRAMEPOINTER_REL_FULL_SCOPE_Fill(pOutSym: PDEFRANGESYMFRAMEPOINTERREL_FULL_SCOPE;
  offFramePointer: CV_off32_t);
begin
  pOutSym.rectyp := S_DEFRANGE_FRAMEPOINTER_REL_FULL_SCOPE;
  pOutSym.offFramePointer := offFramePointer;
end;


function TTDSToCVSymConverterBPREL32.Convert(pInSym: PTDS_SYMTYPE): UInt32;
var
  pTypedSym: PTDS_BPRELSYM;
  pOutSymBPRel: PBPRELSYM32;
  pOutSymLocal: PLOCALSYM;
  pOutSymDefRangeFramePtrRelFull: PDEFRANGESYMFRAMEPOINTERREL_FULL_SCOPE;
begin
  // Currently local variables are only reliable in Win32
  if FSymbolsConverter.FPEImage.Target = taWin32 then begin
    pTypedSym := PTDS_BPRELSYM(pInSym);

    // write S_LOCAL
    FSymbolsConverter.AddSymbol(
      LOCAL_Size(FSymbolsConverter.FTDSParser.Names[pTypedSym.nameind]),
      PSYMTYPE(pOutSymLocal));
    LOCAL_Fill(
      pOutSymLocal,
      FSymbolsConverter.FTypesConverter.TypeConversions[pTypedSym.typind],
      FSymbolsConverter.FTDSParser.Names[pTypedSym.nameind]);

    // write S_DEFRANGE_FRAMEPOINTER_REL
    FSymbolsConverter.AddSymbol(
      DEFRANGE_FRAMEPOINTER_REL_FULL_SCOPE_Size,
      PSYMTYPE(pOutSymDefRangeFramePtrRelFull));
    DEFRANGE_FRAMEPOINTER_REL_FULL_SCOPE_Fill(
      pOutSymDefRangeFramePtrRelFull,
      pTypedSym.off);

    // write S_BPREL32
    Result := FSymbolsConverter.AddSymbol(
      BPREL32_Size(FSymbolsConverter.FTDSParser.Names[pTypedSym.nameind]),
      PSYMTYPE(pOutSymBPRel));
    BPREL32_Fill(
      pOutSymBPRel,
      pTypedSym.off,
      FSymbolsConverter.FTypesConverter.TypeConversions[pTypedSym.typind],
      FSymbolsConverter.FTDSParser.Names[pTypedSym.nameind]);
  end
  else
    Result := 0;
end;

function DATA32_Size(name: PAnsiChar): UInt32;
begin
  Result := SizeOf(DATASYM32) - SizeOf(PDATASYM32(nil).name);
  Inc(Result, System.AnsiStrings.StrLen(name) + 1);
end;

procedure DATA32_Fill(pOutSym: PDATASYM32; rectyp: UInt16; typind: CV_typ_t; off: CV_uoff32_t;
  seg: UInt16; name: PAnsiChar);
begin
  pOutSym.rectyp := rectyp;
  pOutSym.typind := typind;
  pOutSym.off := off;
  pOutSym.seg := seg;
  if name = nil then
    pOutSym.name[0] := 0
  else
    System.AnsiStrings.StrCopy(@pOutSym.name[0], name);
end;

function TTDSToCVSymConverterDATA32.Convert(pInSym: PTDS_SYMTYPE): UInt32;
var
  pTypedSym: PTDS_DATASYM;
  pOutSym: PDATASYM32;
begin
  pTypedSym := PTDS_DATASYM(pInSym);
  Result := FSymbolsConverter.AddSymbol(
    DATA32_Size(FSymbolsConverter.FTDSParser.Names[pTypedSym.nameind]),
    PSYMTYPE(pOutSym));
  DATA32_Fill(
    pOutSym,
    IfThen(pTypedSym.rectyp = TDS_S_GDATA32, S_GDATA32, S_LDATA32),
    FSymbolsConverter.FTypesConverter.TypeConversions[pTypedSym.typind],
    pTypedSym.off,
    pTypedSym.seg,
    FSymbolsConverter.FTDSParser.Names[pTypedSym.nameind]);
end;

function PROC32_Size(name: PAnsiChar): UInt16;
begin
  Result := SizeOf(PROCSYM32) - SizeOf(PPROCSYM32(nil).name);
  Inc(Result, System.AnsiStrings.StrLen(name) + 1);
end;

procedure PROC32_Fill(pOutSym: PPROCSYM32; rectyp: UInt16; pParent, pEnd, pNext, len, DbgStart,
  DbgEnd: UInt32; typind: CV_typ_t; off: CV_uoff32_t; seg: UInt16; name: PAnsiChar);
begin
  pOutSym.rectyp := rectyp;
  pOutSym.pParent := pParent;
  pOutSym.pEnd := pEnd;
  pOutSym.pNext := pNext;
  pOutSym.len := len;
  pOutSym.DbgStart := DbgStart;
  pOutSym.DbgEnd := DbgEnd;
  pOutSym.typind := typind;
  pOutSym.off := off;
  pOutSym.seg := seg;
  pOutSym.flags._props := 0;
  if name = nil then
    pOutSym.name[0] := 0
  else
    System.AnsiStrings.StrCopy(@pOutSym.name[0], name);
end;

function TTDSToCVSymConverterPROC32.Convert(pInSym: PTDS_SYMTYPE): UInt32;
var
  pTypedSym: PTDS_PROCSYM;
  pOutSym: PPROCSYM32;
begin
  pTypedSym := PTDS_PROCSYM(pInSym);
  Result := FSymbolsConverter.AddSymbol(
    PROC32_Size(FSymbolsConverter.FTDSParser.Names[pTypedSym.nameind]),
    PSYMTYPE(pOutSym));
  PROC32_Fill(
    pOutSym,
    IfThen(pTypedSym.rectyp = TDS_S_GPROC32, S_GPROC32, S_LPROC32),
    pTypedSym.pParent,  // will be fixed up
    pTypedSym.pEnd,     // will be fixed up
    pTypedSym.pNext,    // will be fixed up
    pTypedSym.len,
    pTypedSym.DbgStart,
    pTypedSym.DbgEnd,
    FSymbolsConverter.FTypesConverter.TypeConversions[pTypedSym.typind],
    pTypedSym.off,
    pTypedSym.seg,
    FSymbolsConverter.FTDSParser.Names[pTypedSym.nameind]);
end;

function TTDSToCVSymConverterWITH32.Convert(pInSym: PTDS_SYMTYPE): UInt32;
begin
  // do nothing
  Result := 0;
end;

procedure GenerateRegVarGapRanges(pSymProc: PPROCSYM32; const ValidRangeSet: TUInt32RangeSet;
  var Range: CV_LVAR_ADDR_RANGE; var Gaps: TArray<CV_LVAR_ADDR_GAP>);
var
  I: Integer;
  CompleteRangeSet,
  GapRangeSet: TUInt32RangeSet;
begin
  // The complete range is the valid range intersected with the debug range
  CompleteRangeSet := UInt32Range(ValidRangeSet.Start, ValidRangeSet._End);
  CompleteRangeSet := CompleteRangeSet and
    UInt32Range(0, pSymProc.len - 1);
  // Invert the valid range set and then find the intersection of that with the complete
  // range. This ends up getting us the final set of gaps (which may be empty).
  GapRangeSet := CompleteRangeSet and (not ValidRangeSet);

  // Set range arrays
  Range.offStart := CompleteRangeSet.Start;
  Range.isectStart := pSymProc.seg;
  Range.cbRange := CompleteRangeSet._End - Range.offStart + 1;
  SetLength(Gaps, GapRangeSet.Count);
  for I := 0 to GapRangeSet.Count - 1 do
    with Gaps[I], GapRangeSet[I] do begin
      gapStartOffset := Start;
      cbRange := _End - gapStartOffset + 1;
    end;
end;

function TTDSToCVSymConverterOPTVAR32.Convert(pInSym: PTDS_SYMTYPE): UInt32;
var
  pTypedSym: PTDS_OPTVARSYM;
  pSymProc: PPROCSYM32;
  pTDSSymReg: PTDS_REGSYM;
  pOutSymLocal: PLOCALSYM;
  pOutSymDefRangeReg: PDEFRANGESYMREGISTER;
  pOutSymReg: PREGSYM;
  I: Integer;
  CurrentReg: UInt16;
  RegArray: TArray<UInt16>;
  RangeArray: TArray<CV_LVAR_ADDR_RANGE>;
  GapArray: TArray<TArray<CV_LVAR_ADDR_GAP>>;
  ValidRangeSet: TUInt32RangeSet;
begin
  // Currently local variables are only reliable in Win32
  if FSymbolsConverter.FPEImage.Target = taWin32 then begin
    // Walk backward to find current proc symbol (S_GPROC32 or S_LPROC32) and last reg symbol
    // (S_REGISTER).
    pSymProc := nil;
    for I := FSymbolsConverter.FCurrentCVSymbols.Count - 1 downto 0 do begin
      if (FSymbolsConverter.FCurrentCVSymbols[I].rectyp = S_GPROC32) or
         (FSymbolsConverter.FCurrentCVSymbols[I].rectyp = S_LPROC32) then begin
        pSymProc := PPROCSYM32(FSymbolsConverter.FCurrentCVSymbols[I]);
        Break;
      end
      else
        // Must not reach an end symbol, otherwise we're drifting into another proc's scope
        Assert(FSymbolsConverter.FCurrentCVSymbols[I].rectyp <> S_END);
    end;
    // Must be within a procedure context
    Assert(pSymProc <> nil);
    // Last TDS symbol must have been a register symbol
    pTDSSymReg := PTDS_REGSYM(FSymbolsConverter.FLastTDSSymbol);
    Assert(pTDSSymReg.rectyp = TDS_S_REGISTER);

    pTypedSym := PTDS_OPTVARSYM(pInSym);

    // Convert valid ranges into gapped ranges
    CurrentReg := CV_REG_NONE;
    for I := 0 to pTypedSym.cRanges - 1 do begin
      if pTypedSym.ranges[I].reg <> CurrentReg then begin
        // Convert completed valid range set into one range with a set of gaps
        if CurrentReg <> CV_REG_NONE then begin
          GenerateRegVarGapRanges(pSymProc, ValidRangeSet, RangeArray[Length(RangeArray) - 1],
            GapArray[Length(GapArray) - 1]);
          RegArray[Length(RegArray) - 1] := CurrentReg;
        end;
        CurrentReg := pTypedSym.ranges[I].reg;
        SetLength(RegArray, Length(RegArray) + 1);
        SetLength(RangeArray, Length(RangeArray) + 1);
        SetLength(GapArray, Length(GapArray) + 1);
        ValidRangeSet.Clear;
      end;
      if pTypedSym.ranges[I].len = 0 then // just go to the end of the proc
        ValidRangeSet := ValidRangeSet or UInt32Range(pTypedSym.ranges[I].off, UInt32.MaxValue)
      else
        ValidRangeSet := ValidRangeSet or UInt32Range(pTypedSym.ranges[I].off,
          pTypedSym.ranges[I].off + pTypedSym.ranges[I].len - 1);
    end;
    // Add last range
    GenerateRegVarGapRanges(pSymProc, ValidRangeSet, RangeArray[Length(RangeArray) - 1],
      GapArray[Length(GapArray) - 1]);
    RegArray[Length(RegArray) - 1] := CurrentReg;

    // We should have *something* by now
    Assert((Length(RegArray) <> 0) and (Length(RangeArray) <> 0) and (Length(GapArray) <> 0));

    // write S_LOCAL
    FSymbolsConverter.AddSymbol(
      LOCAL_Size(FSymbolsConverter.FTDSParser.Names[pTDSSymReg.nameind]),
      PSYMTYPE(pOutSymLocal));
    LOCAL_Fill(
      pOutSymLocal,
      FSymbolsConverter.FTypesConverter.TypeConversions[pTDSSymReg.typind],
      FSymbolsConverter.FTDSParser.Names[pTDSSymReg.nameind]);

    // write one or more S_DEFRANGE_REGISTER
    for I := 0 to Length(RegArray) - 1 do begin
      FSymbolsConverter.AddSymbol(
        DEFRANGE_REGISTER_Size(Length(GapArray[I])),
        PSYMTYPE(pOutSymDefRangeReg));
      DEFRANGE_REGISTER_Fill(
        pOutSymDefRangeReg,
        RegArray[I],
        RangeArray[I],
        GapArray[I]);
    end;

    // write S_REGISTER
    Result := FSymbolsConverter.AddSymbol(
      REGISTER_Size(FSymbolsConverter.FTDSParser.Names[pTDSSymReg.nameind]),
      PSYMTYPE(pOutSymReg));
    REGISTER_FILL(
      pOutSymReg,
      FSymbolsConverter.FTypesConverter.TypeConversions[pTDSSymReg.typind],
      RegArray[0],
      FSymbolsConverter.FTDSParser.Names[pTDSSymReg.nameind]);
  end
  else
    Result := 0;
end;

function TTDSToCVSymConverterSLINK32.Convert(pInSym: PTDS_SYMTYPE): UInt32;
begin
  // do nothing
  Result := 0;
end;

constructor TTDSToCVTypeConverterBase.Create(SymbolsConverter: TTDSToPDBSymbolsConverter);
begin
  FSymbolsConverter := SymbolsConverter;
end;

constructor TTDSToPDBSymbolsConverter.TConverterInfo.Create(AName: string; AConverter: TTDSToCVTypeConverterBase);
begin
  FName := AName;
  FConverter := AConverter;
  Clear;
end;

function TTDSToPDBSymbolsConverter.TConverterInfo.Convert(pInSym: PTDS_SYMTYPE): UInt32;
begin
  Result := FConverter.Convert(pInSym);
  Inc(FCount);
  Inc(FSize, pInSym.reclen + SizeOf(pInSym.reclen));
  case pInSym.rectyp of
    TDS_S_GPROC32,
    TDS_S_GDATA32:
      Inc(FPublicCount);
    TDS_S_UDT:
      if (PTDS_UDTSYM(pInSym).props and $4) > 0 then
        Inc(FPublicCount);
    TDS_S_PCONST:
      if (PTDS_SCOPEDCONSTSYM(pInSym).props and $4) > 0 then
        Inc(FPublicCount);
  end;
end;

procedure TTDSToPDBSymbolsConverter.TConverterInfo.Clear;
begin
  FCount := 0;
  FPublicCount := 0;
  FSize := 0;
end;

procedure TTDSToPDBSymbolsConverter.AddConverters(Is64Bit: Boolean);
begin
  FSymbolConverters.Add(TDS_S_COMPILE, TConverterInfo.Create('TDS_S_COMPILE', TTDSToCVSymConverterCOMPILE.Create(Self)));
  if Is64Bit then
    FSymbolConverters.Add(TDS_S_REGISTER, TConverterInfo.Create('TDS_S_REGISTER', TTDSToCVSymConverterNoOperation.Create(Self)))
  else
    FSymbolConverters.Add(TDS_S_REGISTER, TConverterInfo.Create('TDS_S_REGISTER', TTDSToCVSymConverterREGISTER.Create(Self)));
  FSymbolConverters.Add(TDS_S_UDT, TConverterInfo.Create('TDS_S_UDT', TTDSToCVSymConverterUDT.Create(Self)));
  FSymbolConverters.Add(TDS_S_SSEARCH, TConverterInfo.Create('TDS_S_SSEARCH', TTDSToCVSymConverterSSEARCH.Create(Self)));
  FSymbolConverters.Add(TDS_S_END, TConverterInfo.Create('TDS_S_END', TTDSToCVSymConverterEND.Create(Self)));
  FSymbolConverters.Add(TDS_S_GPROCREF, TConverterInfo.Create('TDS_S_GPROCREF', TTDSToCVSymConverterGPROCREF.Create(Self)));
  FSymbolConverters.Add(TDS_S_USES, TConverterInfo.Create('TDS_S_USES', TTDSToCVSymConverterUSES.Create(Self)));
  FSymbolConverters.Add(TDS_S_NAMESPACE, TConverterInfo.Create('TDS_S_NAMESPACE', TTDSToCVSymConverterNAMESPACE.Create(Self)));
  FSymbolConverters.Add(TDS_S_USING, TConverterInfo.Create('TDS_S_USING', TTDSToCVSymConverterUSING.Create(Self)));
  FSymbolConverters.Add(TDS_S_PCONST, TConverterInfo.Create('TDS_S_PCONST', TTDSToCVSymConverterPCONST.Create(Self)));
  if Is64Bit then
    FSymbolConverters.Add(TDS_S_BPREL32, TConverterInfo.Create('TDS_S_BPREL32', TTDSToCVSymConverterNoOperation.Create(Self)))
  else
    FSymbolConverters.Add(TDS_S_BPREL32, TConverterInfo.Create('TDS_S_BPREL32', TTDSToCVSymConverterBPREL32.Create(Self)));
  FSymbolConverters.Add(TDS_S_LDATA32, TConverterInfo.Create('TDS_S_LDATA32', TTDSToCVSymConverterLDATA32.Create(Self)));
  FSymbolConverters.Add(TDS_S_GDATA32, TConverterInfo.Create('TDS_S_GDATA32', TTDSToCVSymConverterGDATA32.Create(Self)));
  FSymbolConverters.Add(TDS_S_LPROC32, TConverterInfo.Create('TDS_S_LPROC32', TTDSToCVSymConverterLPROC32.Create(Self)));
  FSymbolConverters.Add(TDS_S_GPROC32, TConverterInfo.Create('TDS_S_GPROC32', TTDSToCVSymConverterGPROC32.Create(Self)));
  FSymbolConverters.Add(TDS_S_WITH32, TConverterInfo.Create('TDS_S_WITH32', TTDSToCVSymConverterWITH32.Create(Self)));
  if Is64Bit then
    FSymbolConverters.Add(TDS_S_OPTVAR32, TConverterInfo.Create('TDS_S_OPTVAR32', TTDSToCVSymConverterNoOperation.Create(Self)))
  else
    FSymbolConverters.Add(TDS_S_OPTVAR32, TConverterInfo.Create('TDS_S_OPTVAR32', TTDSToCVSymConverterOPTVAR32.Create(Self)));
  FSymbolConverters.Add(TDS_S_SLINK32, TConverterInfo.Create('TDS_S_SLINK32', TTDSToCVSymConverterSLINK32.Create(Self)));
end;

function TTDSToPDBSymbolsConverter.AddSymbol(Size: UInt16; out pSym: PSYMTYPE): UInt32;
begin
{$POINTERMATH ON}
  // Pad Size to multiple of 4 for natural alignment
//  if (Size and 3) > 0 then
//    Inc(Size, 4 - (Size and 3));
  Size := PadSymLen(Size);

//  Assert(Size <= POOL_DELTA); - Always true
  if (FBufferPool[FBufferPool.Count - 1].Position + Size) >=
     FBufferPool[FBufferPool.Count - 1].Size then begin
    FCurrentBuffer := TMemoryStream.Create;
    FCurrentBuffer.Size := POOL_DELTA;
    FBufferPool.Add(FCurrentBuffer);
  end;
  pSym := PSYMTYPE(PUInt8(FCurrentBuffer.Memory) + FCurrentBuffer.Position);
  FillChar(pSym^, Size, 0);
  pSym.reclen := Size - SizeOf(pSym.reclen);
  FCurrentBuffer.Position := FCurrentBuffer.Position + Size;
  Result := FCurrentCVSymbols.Add(pSym) + 1; // Make the minimum index 1, so 0 is a sentinel
{$POINTERMATH OFF}
end;

procedure TTDSToPDBSymbolsConverter.Convert;
var
  I, J: Integer;
  symLen: UInt16;
  symIdx: UInt32;
  SymbolDataBase,
  SymbolDataCur: Pointer;
  CurrentSymbolData: TMemoryStream;
  CurrentCVSymbolsSize: UInt32;
  TempList: TList<UInt16>;
  UDTNames: TDictionary<CV_typ_t, UTF8String>;
begin
{$POINTERMATH ON}
  UDTNames := TDictionary<CV_typ_t, UTF8String>.Create;
  try
    // Convert all align symbols
    // First, loop through each module
    for I := 0 to FTDSParser.AlignSymbols.Count - 1 do
      if FTDSParser.AlignSymbols[I] <> nil then begin
        FCurrentCVSymbols := TList<PSYMTYPE>.Create;
        FCVSymbols.Add(FCurrentCVSymbols);
        FCVSymbolsSize.Add(0); // Add dummy entry that will be updated
        FCVProcs.Add(TList<PPROCSYM32>.Create);
        CurrentCVSymbolsSize := 0;

        FCurrentModule := I;
        FLastTDSSymbol := nil;

        // Loop through symbols in module
        for J := 0 to FTDSParser.AlignSymbols[I].Count - 1 do begin
          symIdx := FSymbolConverters[FTDSParser.AlignSymbols[I][J].rectyp].Convert(FTDSParser.AlignSymbols[I][J]);
          FLastTDSSymbol := FTDSParser.AlignSymbols[I][J];
          if symIdx <> 0 then begin
            Dec(symIdx);
            FTDSSymOffToCVSymIdx.Add(NativeUInt(FLastTDSSymbol) -
              NativeUInt(FTDSParser.AlignSymbolsBases[I]), symIdx);
          end;
        end;

        TempList := TList<UInt16>.Create(FSymbolConverters.Keys);
        TempList.Sort;
  //        LogStream.WriteLine('Symbol,Count,Count Hex,Public,Public Hex,Size,Size Hex');
        for J := 0 to TempList.Count - 1 do
          with FSymbolConverters[TempList[J]] do begin
  //            LogStream.WriteLine('%0:s,%1:d,"=""%1:.8x""",%2:d,"=""%2:.8x""",%3:d,"=""%3:.8x"""',
  //              [FName, FCount, FPublicCount, FSize]);
            Clear;
          end;

        // Merge type pool into one single buffer
        CurrentSymbolData := TMemoryStream.Create;
        FSymbolData.Add(CurrentSymbolData);
        CurrentSymbolData.Size := SizeOf(UInt32) + FBufferPool.Count * POOL_DELTA;
        SymbolDataBase := CurrentSymbolData.Memory;
        SymbolDataCur := SymbolDataBase;
        // set proper symbol section signature
        PUInt32(SymbolDataCur)^ := CV_SIGNATURE_C13;
        Inc(PUInt8(SymbolDataCur), SizeOf(UInt32));

        if FCurrentCVSymbols.Count > 0 then
          for J := 0 to FCurrentCVSymbols.Count - 1 do begin
            // move symbol into new buffer
            symLen := FCurrentCVSymbols[J].reclen + SizeOf(FCurrentCVSymbols[J].reclen);
            Move(FCurrentCVSymbols[J]^, SymbolDataCur^, symLen);
            FCurrentCVSymbols[J] := SymbolDataCur;
            Inc(PUInt8(SymbolDataCur), symLen);
            Inc(CurrentCVSymbolsSize, symLen);

            case FCurrentCVSymbols[J].rectyp of
              // once moved, take note of S_LPROC32 and S_GPROC32 symbols as they will be used to
              // figure out line information contributions later
              S_LPROC32,
              S_GPROC32: CVProcs[I].Add(PPROCSYM32(FCurrentCVSymbols[J]));
              // Also keep track of UDT names corresponding with CV type indices
              S_UDT:
                with PUDTSYM(FCurrentCVSymbols[J])^ do
                  UDTNames.AddOrSetValue(typind, UTF8String(PAnsiChar(@name[0])));
            end;
          end;
        FBufferPool.Clear;
        FCurrentBuffer := TMemoryStream.Create;
        FCurrentBuffer.Size := POOL_DELTA;
        FBufferPool.Add(FCurrentBuffer);

        // Set the module total symbol size
        FCVSymbolsSize[FCVSymbolsSize.Count - 1] := CurrentCVSymbolsSize;

        // Fixup linked symbols. Only S_SSEARCH, S_LPROC32 and S_GPROC32 symbols need this, but
        // their startsym, pParent, pEnd and pNext pointers are initially set to the TDS symbol
        // equivalents. We add linkages from the TDS symbol offset to the CV symbol index in a
        // dictionary used here to fix the linkages after symbol consolidation. Here's the sequence
        // for how we fix the symbols:
        // 1) Iterate through the current symbol list.
        // 2) If the current symbol is a procedure, do the following for the pParent, pEnd and pNext
        //    pointers:
        //   a) Take the TDS pointer and find the CV index.
        //   b) Take the CV index and get the new symbol pointer.
        //   c) Subtract the new symbol pointer from the symbol section base to get the new offset.
        //   d) Assign the offset back to the symbol
        // 3) If the current symbol is the start search symbol, do the following for startsym:
        //   a) Take the TDS pointer and find the CV index.
        //   b) If this mapping doesn't exist, set startsym to 0 as there are no procedures to link
        //      to.
        //   c) Take the CV index and get the new symbol pointer.
        //   d) Subtract the new symbol pointer from the symbol section base to get the new offset.
        //   e) Assign the offset back to the symbol
        for J := 0 to FCurrentCVSymbols.Count - 1 do
          if (FCurrentCVSymbols[J].rectyp = S_LPROC32) or
             (FCurrentCVSymbols[J].rectyp = S_GPROC32) then
            with PPROCSYM32(FCurrentCVSymbols[J])^ do begin
              if pParent <> 0 then
                pParent := NativeUInt(FCurrentCVSymbols[FTDSSymOffToCVSymIdx[pParent]]) -
                  NativeUInt(SymbolDataBase);
              if pEnd <> 0 then
                pEnd := NativeUInt(FCurrentCVSymbols[FTDSSymOffToCVSymIdx[pEnd]]) -
                  NativeUInt(SymbolDataBase);
              pNext := 0; // not needed anymore
            end
          else if FCurrentCVSymbols[J].rectyp = S_SSEARCH then
            with PSEARCHSYM(FCurrentCVSymbols[J])^ do
              if (startsym <> 0) then
                if FTDSSymOffToCVSymIdx.ContainsKey(startsym) then
                  startsym := NativeUInt(FCurrentCVSymbols[FTDSSymOffToCVSymIdx[startsym]]) -
                    NativeUInt(SymbolDataBase)
                else
                  startsym := 0;
        FTDSSymOffToCVSymIdx.Clear;
      end
      else begin
        Assert(I = 0); // Should only happen for non-existent module 0
        FCVSymbols.Add(nil);
        FCVProcs.Add(nil);
        FCVSymbolsSize.Add(0);
      end;
    FTypesConverter.UpdateUDTNames(UDTNames);
  finally
    UDTNames.Free;
  end;

  FBufferPool.Free;
  FBufferPool := nil;
  FCurrentBuffer := nil;
{$POINTERMATH OFF}
end;

constructor TTDSToPDBSymbolsConverter.Create(PEImage: TPeBorTDSParserImage;
  TDSParser: TTDSParser; TypesConverter: TTDSToPDBTypesConverter);
begin
  inherited Create;
  FPEImage := PEImage;
  FTDSParser := TDSParser;
  FTypesConverter := TypesConverter;
  FBufferPool := TObjectList<TMemoryStream>.Create;
  FCurrentBuffer := TMemoryStream.Create;
  FCurrentBuffer.Size := POOL_DELTA;
  FBufferPool.Add(FCurrentBuffer);
  FSymbolData := TObjectList<TMemoryStream>.Create;
  FSymbolConverters := TObjectDictionary<UInt16, TConverterInfo>.Create;
  FTDSSymOffToCVSymIdx := TDictionary<UInt32, Integer>.Create;
  FCVSymbols := TObjectList<TList<PSYMTYPE>>.Create;
  FCVSymbolsSize := TList<UInt32>.Create;
  FCVProcs := TObjectList<TList<PPROCSYM32>>.Create;
  FCurrentCVSymbols := nil;
  FLastTDSSymbol := nil;
  AddConverters(PEImage.Target = taWin64);
  Convert;
end;

destructor TTDSToPDBSymbolsConverter.Destroy;
begin
  FBufferPool.Free;
  FSymbolData.Free;
  FSymbolConverters.Free;
  FTDSSymOffToCVSymIdx.Free;
  FCVProcs.Free;
  FCVSymbolsSize.Free;
  FCVSymbols.Free;
  inherited Destroy;
end;

end.
