unit TDSTypesConv;

interface

uses
  System.Classes, System.Generics.Collections, TDSParser, TDSInfo, CVInfo;

//  Leaf conversions:
//    Basic leaf types referenced from symbols:
//      TDS_LF_POINTER   ->  LF_POINTER
//      TDS_LF_CLASS     ->  LF_CLASS
//      TDS_LF_STRUCTURE ->  LF_STRUCTURE
//      TDS_LF_ENUM      ->  LF_ENUM
//      TDS_LF_PROCEDURE ->  LF_PROCEDURE
//      TDS_LF_MFUNCTION ->  LF_MFUNCTION
//      TDS_LF_VTSHAPE   ->  LF_VTSHAPE
//
//    Delphi leaf types referenced from symbols:
//      TDS_LF_DSET       -> LF_STRUCTURE, LF_FIELDLIST, LF_MEMBER, LF_BITFIELD (Delphi set type)
//      TDS_LF_DRANGED    -> leaf of base type (Delphi ranged type)
//      TDS_LF_DARRAY     -> LF_DIMARRAY (Delphi array)
//      TDS_LF_DSHORTSTR  -> LF_POINTER, T_RCHAR (Delphi short string)
//      TDS_LF_DMETHODREF -> LF_STRUCTURE, LF_MEMBER, LF_MFUNCTION (Delphi method reference)
//      TDS_LF_DPROPERTY  -> (nothing) (Delphi property)
//      TDS_LF_DANSISTR   -> LF_POINTER, T_RCHAR (Delphi AnsiString type)
//      TDS_LF_DVARIANT   -> LF_STRUCT, LF_UNION, LF_MEMBER, System.TVarData (Delphi Variant type)
//      TDS_LF_DMETACLASS -> LF_POINTER (Delphi metaclass type)
//      TDS_LF_DWIDESTR   -> LF_POINTER, T_WCHAR (Delphi WideString type)
//      TDS_LF_DUNISTR    -> LF_POINTER, T_WCHAR (Delphi unicode string type)
//
//    Leaf types referenced from other leaves:
//      TDS_LF_ARGLIST    -> LF_ARGLIST
//      TDS_LF_FIELDLIST  -> LF_FIELDLIST
//      TDS_LF_METHODLIST -> LF_METHODLIST
//
//    Leaf types referenced by complex lists:
//      TDS_LF_BCLASS     -> LF_BCLASS
//      TDS_LF_ENUMERATE  -> LF_ENUMERATE
//      TDS_LF_MEMBER     -> LF_MEMBER
//      TDS_LF_STMEMBER   -> LF_STMEMBER
//      TDS_LF_METHOD     -> LF_METHOD
//      TDS_LF_VFUNCTAB   -> LF_VFUNCTAB
//
//    Numeric leaf types:
//      TDS_LF_CHAR       -> LF_CHAR
//      TDS_LF_SHORT      -> LF_SHORT
//      TDS_LF_USHORT     -> LF_USHORT
//      TDS_LF_LONG       -> LF_LONG
//      TDS_LF_ULONG      -> LF_ULONG
//      TDS_LF_REAL32     -> LF_REAL32
//      TDS_LF_REAL64     -> LF_REAL64
//      TDS_LF_REAL80     -> LF_REAL80
//      TDS_LF_REAL128    -> LF_REAL128
//      TDS_LF_QUADWORD   -> LF_QUADWORD
//      TDS_LF_UQUADWORD  -> LF_UQUADWORD
//      TDS_LF_REAL48     -> LF_REAL48
//      TDS_LF_COMPLEX32  -> LF_COMPLEX32
//      TDS_LF_COMPLEX64  -> LF_COMPLEX64
//      TDS_LF_COMPLEX80  -> LF_COMPLEX80
//      TDS_LF_COMPLEX128 -> LF_COMPLEX128
//      TDS_LF_VARSTRING  -> LF_VARSTRING

type
  TTDSToPDBTypesConverter = class;

  TTDSToCVTypeConverterBase = class abstract
  private
    FTypesConverter: TTDSToPDBTypesConverter;
  public
    constructor Create(TypesConverter: TTDSToPDBTypesConverter);
    function Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t; virtual; abstract;
  end;

  TTDSToPDBTypesConverter = class
  private const
    POOL_DELTA = 256 * 1024;
  private
    FTDSParser: TTDSParser;
    FBufferPool: TObjectList<TMemoryStream>;
    FCurrentBuffer: TMemoryStream;
    FTypeData: TMemoryStream;
    FTypeConversions: TDictionary<TDS_typ_t, CV_typ_t>;
    FTypeConverters: TObjectDictionary<UInt16, TTDSToCVTypeConverterBase>;
    FTypeConverterNames: TDictionary<UInt16, string>;
    FCVTypes: TList<PTYPTYPE>;
    FTObjectRefType,
    FTObjectType,
    FTVarDataType: CV_typ_t;
    FCVTypeFixups: TList<PCV_typ_t>;
    FCVTypeConvFixups: TList<TDS_typ_t>;
    procedure AddConverter(leaf: UInt16; name: string; converter: TTDSToCVTypeConverterBase);
    procedure AddConverters;
    function AddType(Size: UInt16; out pTyp: PTYPTYPE): CV_typ_t;
    procedure Convert;
    procedure OnTypeFixupAdd(Sender: TObject; const Item: PCV_typ_t;
      Action: TCollectionNotification);
  public
    constructor Create(TDSParser: TTDSParser);
    destructor Destroy; override;
    property CVTypes: TList<PTYPTYPE> read FCVTypes;
    property CVTypeData: TMemoryStream read FTypeData;
    property TypeConversions: TDictionary<TDS_typ_t, CV_typ_t> read FTypeConversions;
  end;

implementation

uses
  System.AnsiStrings, System.Math, System.SysUtils, CVConst, TDSUtils, TD32ToPDBResources;

type
  TTDSToCVConverterPOINTER = class(TTDSToCVTypeConverterBase)
  public
    function Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t; override;
  end;

  TTDSToCVConverterCLASS = class(TTDSToCVTypeConverterBase)
  public
    function Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t; override;
  end;

  TTDSToCVConverterSTRUCTURE = TTDSToCVConverterCLASS;

  TTDSToCVConverterENUM = class(TTDSToCVTypeConverterBase)
  public
    function Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t; override;
  end;

  TTDSToCVConverterPROCEDURE = class(TTDSToCVTypeConverterBase)
  public
    function Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t; override;
  end;

  TTDSToCVConverterMFUNCTION = class(TTDSToCVTypeConverterBase)
  public
    function Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t; override;
  end;

  TTDSToCVConverterVTSHAPE = class(TTDSToCVTypeConverterBase)
  public
    function Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t; override;
  end;

  TTDSToCVConverterDSET = class(TTDSToCVTypeConverterBase)
  public
    function Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t; override;
  end;

  TTDSToCVConverterDRANGED = class(TTDSToCVTypeConverterBase)
  public
    function Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t; override;
  end;

  TTDSToCVConverterDARRAY = class(TTDSToCVTypeConverterBase)
  public
    function Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t; override;
  end;

  TTDSToCVConverterDSHORTSTR = class(TTDSToCVTypeConverterBase)
  public
    function Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t; override;
  end;

  TTDSToCVConverterDMETHODREF = class(TTDSToCVTypeConverterBase)
  public
    function Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t; override;
  end;

  TTDSToCVConverterDPROPERTY = class(TTDSToCVTypeConverterBase)
  public
    function Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t; override;
  end;

  TTDSToCVConverterDANSISTR = class(TTDSToCVTypeConverterBase)
  public
    function Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t; override;
  end;

  TTDSToCVConverterDVARIANT = class(TTDSToCVTypeConverterBase)
  public
    function Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t; override;
  end;

  TTDSToCVConverterDMETACLASS = class(TTDSToCVTypeConverterBase)
  public
    function Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t; override;
  end;

  TTDSToCVConverterDWIDESTR = class(TTDSToCVTypeConverterBase)
  public
    function Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t; override;
  end;

  TTDSToCVConverterDUNISTR = class(TTDSToCVTypeConverterBase)
  public
    function Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t; override;
  end;

  TTDSToCVConverterARGLIST = class(TTDSToCVTypeConverterBase)
  public
    function Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t; override;
  end;

  TTDSToCVConverterFIELDLIST = class(TTDSToCVTypeConverterBase)
  public
    function Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t; override;
  end;

  TTDSToCVConverterMETHODLIST = class(TTDSToCVTypeConverterBase)
  public
    function Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t; override;
  end;

function POINTER_Size(isPMEM: Boolean): UInt16;
begin
  Result := SizeOf(PlfPointer(nil).leaf) + SizeOf(PlfPointer(nil).utype) + SizeOf(PlfPointer(nil).attr);
  if isPMEM then begin
    Inc(Result, SizeOf(PlfPointer(nil).pmclass));
    Inc(Result, SizeOf(PlfPointer(nil).pmenum));
  end;
end;

procedure POINTER_Fill(pOutLeaf: PlfPointer; utype: CV_typ_t; ptrmode: UInt16; pmclass: CV_typ_t;
  pmtype: UInt16);
begin
  pOutLeaf.leaf := LF_POINTER;
  pOutLeaf.utype := utype;
  pOutLeaf.attr._props := 0; // Init and set all flags to false
  pOutLeaf.attr.ptrtype := CV_PTR_NEAR32;
  pOutLeaf.attr.ptrmode := ptrmode;
  Assert(ptrmode in [CV_PTR_MODE_PTR, CV_PTR_MODE_LVREF, CV_PTR_MODE_PMFUNC]);
  if ptrmode = CV_PTR_MODE_PMFUNC then begin
    pOutLeaf.pmclass := pmclass;
    pOutLeaf.pmenum := pmtype;
  end;
end;

function TTDSToCVConverterPOINTER.Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t;
var
  pInLeaf: PTDS_lfPointer;
  typSize: UInt16;
  pOutTyp: PTYPTYPE;
begin
  pInLeaf := PTDS_lfPointer(@pInTyp.leaf);
  typSize := SizeOf(pOutTyp.len) + POINTER_Size(False);
  Result := FTypesConverter.AddType(typSize, pOutTyp);
  Assert(pInLeaf.ptrtype = TDS_PTR_NEAR32);
  Assert((pInLeaf.ptrmode = TDS_PTR_MODE_PTR) or (pInLeaf.ptrmode = TDS_PTR_MODE_REF));
  Assert(not (pInLeaf.isflat32 > 0));
  Assert(not (pInLeaf.isvolatile > 0));
  Assert(not (pInLeaf.isconst > 0));
  Assert(not (pInLeaf.isunaligned > 0));
  POINTER_Fill(
    @pOutTyp.leaf,
    pInLeaf.utype,
    pInLeaf.ptrmode,
    // not a pointer to member
    0, 0);
  // Fixups
  FTypesConverter.FCVTypeFixups.Add(@PlfPointer(@pOutTyp.leaf).utype);
  // Keep track of TObject reference type for future use
  if (pInLeaf.utype >= $1000) and (FTypesConverter.FTObjectRefType = 0) and
     (FTypesConverter.FTDSParser.GlobalTypes[pInLeaf.utype].leaf = TDS_LF_CLASS) then
    FTypesConverter.FTObjectRefType := inTypIdx;
end;

function CLASS_STRUCTURE_Size(instsize: UInt16; name: PAnsiChar): UInt16;
begin
  Result := SizeOf(lfClass) - SizeOf(PlfClass(nil).data);
  // Add instance size length
  if instsize >= LF_NUMERIC then
    Inc(Result, SizeOf(lfUShort))
  else
    Inc(Result, SizeOf(UInt16));
  // Add sz name length
  Inc(Result, System.AnsiStrings.StrLen(name) + 1);
end;

procedure CLASS_STRUCTURE_Fill(pOutLeaf: PlfClass; leaf: UInt16; count: UInt16; ctor: Boolean;
  field, vshape: CV_typ_t; instsize: UInt16; name: PAnsiChar);
var
  dataptr: PUInt8;
begin
  pOutLeaf.leaf := leaf;
  pOutLeaf.count := count;
  pOutLeaf.&property._props := 0; // init and set all props to false
  pOutLeaf.&property.ctor := IfThen(ctor, 1, 0);
  pOutLeaf.field := field;
  pOutLeaf.derived := 0;
  pOutLeaf.vshape := vshape;
  dataptr := @pOutLeaf.data[0];
  if instsize >= LF_NUMERIC then begin
    with PlfUShort(dataptr)^ do begin
      leaf := LF_USHORT;
      val := instsize;
    end;
    Inc(dataptr, SizeOf(lfUShort));
  end
  else begin
    PUInt16(@pOutLeaf.data[0])^ := instsize;
    Inc(dataptr, SizeOf(UInt16));
  end;
  if name = nil then
    dataptr^ := 0
  else
    System.AnsiStrings.StrCopy(PAnsiChar(dataptr), name);
end;

function TTDSToCVConverterCLASS.Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t;
var
  pInLeaf: PTDS_lfClass;
  pTempType: PTDS_TYPTYPE;
  pFieldTypeEnd: Pointer;
  pFieldLeaf: PTDS_lfFieldList;
  pFieldEntryLeaf: PTDS_lfEasy;
  pMetaClassLeaf: PTDS_lfDMetaClass;
  typSize: UInt16;
  pOutTyp: PTYPTYPE;
  outLeaf: UInt16;
  vshape: TDS_typ_t;
begin
  pInLeaf := PTDS_lfClass(@pInTyp.leaf);
  typSize := SizeOf(pOutTyp.len) +
    CLASS_STRUCTURE_Size(
      pInLeaf.instsize,
      FTypesConverter.FTDSParser.Names[pInLeaf.name]);
  Result := FTypesConverter.AddType(typSize, pOutTyp);
  if pInLeaf.leaf = TDS_LF_CLASS then
    outLeaf := LF_CLASS
  else
    outLeaf := LF_STRUCTURE;

  if outLeaf = LF_CLASS then begin
    // Find associated vshape type, this is a bit involved, since Delphi only has one link to the
    // vshape via the virtual function table pointer in the field listing.
    pTempType := FTypesConverter.FTDSParser.GlobalTypes[pInLeaf.field];
    Assert(pTempType <> nil);
    pFieldTypeEnd := TDS_NextType(pTempType);
    pFieldLeaf := @pTempType.leaf;
    pFieldEntryLeaf := @pFieldLeaf.data[0];
    pMetaClassLeaf := nil;
    vshape := 0;
    while NativeUInt(pFieldEntryLeaf) < NativeUInt(pFieldTypeEnd) do begin
      if pFieldEntryLeaf.leaf = TDS_LF_VFUNCTAB then begin
        pTempType := FTypesConverter.FTDSParser.GlobalTypes[PTDS_lfVFuncTab(pFieldEntryLeaf).&type];
        if pTempType.leaf = TDS_LF_VTSHAPE then
          vshape := PTDS_lfVFuncTab(pFieldEntryLeaf).&type
        else begin
          Assert((pTempType <> nil) and (pTempType.leaf = TDS_LF_DMETACLASS));
          pMetaClassLeaf := @pTempType.leaf;
        end;
        Break;
      end;
      pFieldEntryLeaf := NextField(pFieldEntryLeaf);
    end;
    if vshape = 0 then begin
      Assert(pMetaClassLeaf <> nil);
      vshape := pMetaClassLeaf.shape;
    end;
    Assert(vshape <> 0);
  end
  else
    vshape := 0;

  // If this is a class type, it should *always* have a vshape type. If this is a structure type, it
  // should *never* have a vshape type.
  Assert(((outLeaf = LF_CLASS) and (vshape <> 0)) or ((outLeaf = LF_STRUCTURE) and (vshape = 0)));
  CLASS_STRUCTURE_Fill(
    @pOutTyp.leaf,
    outLeaf,
    pInLeaf.count,
    (pInLeaf.&property.ctor > 0) or (pInLeaf.&property.dtor > 0),
    pInLeaf.field,
    vshape,
    pInLeaf.instsize,
    FTypesConverter.FTDSParser.Names[pInLeaf.name]);
  // Fixups
  FTypesConverter.FCVTypeFixups.Add(@PlfClass(@pOutTyp.leaf).field);
  FTypesConverter.FCVTypeFixups.Add(@PlfClass(@pOutTyp.leaf).vshape);
  // Keep track of TObject type for future use
  if (FTypesConverter.FTObjectType = 0) and (outLeaf = LF_CLASS) then
    FTypesConverter.FTObjectType := inTypIdx
  // Keep track of TVarData type for future use
  else if (FTypesConverter.FTVarDataType = 0) and (outLeaf = LF_STRUCTURE) and
     (System.AnsiStrings.StrComp(FTypesConverter.FTDSParser.Names[pInLeaf.name], 'TVarData') = 0) then
    FTypesConverter.FTVarDataType := inTypIdx;
end;

function ENUM_Size(name: PAnsiChar): UInt16;
begin
  Result := SizeOf(lfEnum) - SizeOf(PlfEnum(nil).Name);
  // Add sz name length
  Inc(Result, System.AnsiStrings.StrLen(name) + 1);
end;

procedure ENUM_Fill(pOutLeaf: PlfEnum; count: UInt16; utype, field: CV_typ_t; name: PAnsiChar);
begin
  pOutLeaf.leaf := LF_ENUM;
  pOutLeaf.count := count;
  pOutLeaf.&property._props := 0; // init and set all props to false
  pOutLeaf.utype := utype;
  pOutLeaf.field := field;
  if name = nil then
    PUInt8(@pOutLeaf.Name[0])^ := 0
  else
    System.AnsiStrings.StrCopy(PAnsiChar(@pOutLeaf.Name[0]), name);
end;

function TTDSToCVConverterENUM.Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t;
var
  pInLeaf: PTDS_lfEnum;
  typSize: UInt16;
  pOutTyp: PTYPTYPE;
begin
  pInLeaf := PTDS_lfEnum(@pInTyp.leaf);
  typSize := SizeOf(pOutTyp.len) + ENUM_Size(FTypesConverter.FTDSParser.Names[pInLeaf.name]);
  Result := FTypesConverter.AddType(typSize, pOutTyp);
  ENUM_Fill(
    @pOutTyp.leaf,
    pInLeaf.count,
    pInLeaf.utype,
    pInLeaf.field,
    FTypesConverter.FTDSParser.Names[pInLeaf.name]);
  // Fixups
  FTypesConverter.FCVTypeFixups.Add(@PlfEnum(@pOutTyp.leaf).utype);
  FTypesConverter.FCVTypeFixups.Add(@PlfEnum(@pOutTyp.leaf).field);
end;

function PROCEDURE_Size: UInt16;
begin
  Result := SizeOf(lfProc);
end;

procedure PROCEDURE_Fill(pOutLeaf: PlfProc; rvtype: CV_typ_t; calltype: UInt8; parmcount: UInt16;
  arglist: CV_typ_t);
begin
  pOutLeaf.leaf := LF_PROCEDURE;
  pOutLeaf.rvtype := rvtype;
  pOutLeaf.calltype := calltype;
  pOutLeaf.funcattr._props := 0; // init and set all props to 0/false
  pOutLeaf.parmcount := parmcount;
  pOutLeaf.arglist := arglist;
end;

function TTDSToCVConverterPROCEDURE.Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t;
var
  pInLeaf: PTDS_lfProc;
  typSize: UInt16;
  pOutTyp: PTYPTYPE;
begin
  pInLeaf := PTDS_lfProc(@pInTyp.leaf);
  typSize := SizeOf(pOutTyp.len) + PROCEDURE_Size;
  Result := FTypesConverter.AddType(typSize, pOutTyp);
  PROCEDURE_Fill(
    @pOutTyp.leaf,
    pInLeaf.rvtype,
    // There is no Borland fastcall equivalent
    IfThen(pInLeaf.calltype = TDS_CALL_BORLFAST, CV_CALL_GENERIC, pInLeaf.calltype),
    pInLeaf.parmcount,
    pInLeaf.arglist);
  // Fixups
  FTypesConverter.FCVTypeFixups.Add(@PlfProc(@pOutTyp.leaf).rvtype);
  FTypesConverter.FCVTypeFixups.Add(@PlfProc(@pOutTyp.leaf).arglist);
end;

function MFUNCTION_Size: UInt16;
begin
  Result := SizeOf(lfMFunc)
end;

procedure MFUNCTION_Fill(pOutLeaf: PlfMFunc; rvtype, classtype, thistype: CV_typ_t; calltype: UInt8;
  parmcount: UInt16; arglist: CV_typ_t);
begin
  pOutLeaf.leaf := LF_MFUNCTION;
  pOutLeaf.rvtype := rvtype;
  pOutLeaf.classtype := classtype;
  pOutLeaf.thistype := thistype;
  pOutLeaf.calltype := calltype;
  pOutLeaf.funcattr._props := 0; // init and set all props to 0/false
  pOutLeaf.parmcount := parmcount;
  pOutLeaf.arglist := arglist;
  pOutLeaf.thisadjust := 0;
end;

function TTDSToCVConverterMFUNCTION.Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t;
var
  pInLeaf: PTDS_lfMFunc;
  typSize: UInt16;
  pOutTyp: PTYPTYPE;
begin
  pInLeaf := PTDS_lfMFunc(@pInTyp.leaf);
  typSize := SizeOf(pOutTyp.len) + MFUNCTION_Size;
  Result := FTypesConverter.AddType(typSize, pOutTyp);
  MFUNCTION_Fill(
    @pOutTyp.leaf,
    pInLeaf.rvtype,
    pInLeaf.classtype,
    pInLeaf.thistype,
    // There is no Borland fastcall equivalent
    IfThen(pInLeaf.calltype = TDS_CALL_BORLFAST, CV_CALL_GENERIC, pInLeaf.calltype),
    pInLeaf.parmcount,
    pInLeaf.arglist);
  // Fixups
  FTypesConverter.FCVTypeFixups.Add(@PlfMFunc(@pOutTyp.leaf).rvtype);
  FTypesConverter.FCVTypeFixups.Add(@PlfMFunc(@pOutTyp.leaf).classtype);
  FTypesConverter.FCVTypeFixups.Add(@PlfMFunc(@pOutTyp.leaf).thistype);
  FTypesConverter.FCVTypeFixups.Add(@PlfMFunc(@pOutTyp.leaf).arglist);
end;

function VTSHAPE_Size(count: UInt16): UInt16;
begin
  Result := SizeOf(lfVTShape) - SizeOf(PlfVTShape(nil).desc);
  // Add desc array length, rounding up (4 bits per entry)
  Inc(Result, (count + 1) shr 1);
end;

procedure VTSHAPE_Fill(pOutLeaf: PlfVTShape; count: UInt16; desc: PUInt8);
var
  I: UInt16;
begin
{$POINTERMATH ON}
  pOutLeaf.leaf := LF_VTSHAPE;
  pOutLeaf.count := count;
  if count > 0 then // because I is unsigned
    for I := 0 to ((count + 1) shr 1) - 1 do begin
      pOutLeaf.desc[I] := desc[I];
  end;
{$POINTERMATH OFF}
end;

function TTDSToCVConverterVTSHAPE.Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t;
var
  pInLeaf: PTDS_lfVTShape;
  typSize: UInt16;
  pOutTyp: PTYPTYPE;
begin
  pInLeaf := PTDS_lfVTShape(@pInTyp.leaf);
  typSize := SizeOf(pOutTyp.len) +
    VTSHAPE_Size(
      pInLeaf.count);
  Result := FTypesConverter.AddType(typSize, pOutTyp);
  VTSHAPE_Fill(
    @pOutTyp.leaf,
    pInLeaf.count,
    @pInLeaf.desc[0]);
end;

function BITFIELD_Size: UInt16;
begin
  Result := SizeOf(lfBitfield);
end;

procedure BITFIELD_Fill(pOutLeaf: PlfBitfield; typ: CV_typ_t; position: UInt8);
begin
  pOutLeaf.leaf := LF_BITFIELD;
  pOutLeaf.&type := typ;
  pOutLeaf.length := 1;
  pOutLeaf.position := position;
end;

procedure PadSize(var size: UInt16);
begin
  if (size and 3) > 0 then
    Inc(size, 4 - (size and 3));
end;

function MEMBER_Size(offset: Int64; name: PAnsiChar): UInt16;
begin
  // Add in the lfMember size minus the dummy data field size:
  Result := SizeOf(lfMember) - SizeOf(PlfMember(nil).offset);
  // Add in the offset size:
  Inc(Result, SignedIntegerLeafCb(offset));
  // Add in the name length, including terminating null:
  Inc(Result, System.AnsiStrings.StrLen(name) + 1);
  PadSize(Result); // pad to make it up to 4 byte alignment
end;

procedure PadBuffer(var pData: Pointer);
begin
  while (NativeUInt(pData) and 3) > 0 do begin
    PUInt8(pData)^ := LF_PAD0 or (4 - (NativeUInt(pData) and 3));
    Inc(PUInt8(pData));
  end;
end;

function MEMBER_Fill(pOutLeaf: PlfMember; access: UInt16; typ: CV_typ_t; offset: Int64;
  name: PAnsiChar): Pointer;
var
  pData: PUInt8;
begin
  pOutLeaf.leaf := LF_MEMBER;
  pOutLeaf.attr._props := 0; // Init all fields to 0/false
  pOutLeaf.attr.access := access;
  pOutLeaf.index := typ;
  pData := @pOutLeaf.offset[0];
  pData := FillSignedIntegerLeaf(offset, pData);
  if name = nil then
    pData^ := 0
  else
    pData := PUInt8(System.AnsiStrings.StrECopy(PAnsiChar(pData), name));
  Inc(pData); // move past null char
  Result := pData; // return pointer to beginning of next member
  // Add in pad bytes to pad up to 4 byte alignment
  PadBuffer(Result);
end;

function FIELDLIST_Size(fieldListSize: UInt16): UInt16;
begin
  Result := SizeOf(lfFieldList) - SizeOf(PlfFieldList(nil).data);
  // Add in the lfMember list size:
  Inc(Result, fieldListSize);
end;

procedure FIELDLIST_Fill(pOutLeaf: PlfFieldList; out pOutListLeaf: Pointer);
begin
  pOutLeaf.leaf := LF_FIELDLIST;
  pOutListLeaf := @pOutLeaf.data[0];
end;

function ARRAY_Size(size: UInt64; name: PAnsiChar): UInt16;
begin
  Result := SizeOf(lfArray) - SizeOf(PlfArray(nil).data);
  // Add in array size
  Inc(Result, UnsignedIntegerLeafCb(size));
  Inc(Result, System.AnsiStrings.StrLen(name) + 1);
end;

procedure ARRAY_Fill(pOutLeaf: PlfArray; elemtype, idxtype: CV_typ_t; size: UInt64; name: PAnsiChar);
var
  pData: PUInt8;
begin
  pOutLeaf.leaf := LF_ARRAY;
  pOutLeaf.elemtype := elemtype;
  pOutLeaf.idxtype := idxtype;
  pData := @pOutLeaf.data[0];
  pData := FillUnsignedIntegerLeaf(size, pData);
  if name = nil then
    pData^ := 0 // Null for zero length string
  else
    System.AnsiStrings.StrCopy(PAnsiChar(pData), name);
end;

function TTDSToCVConverterDSET.Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t;
var
  pInLeaf: PTDS_lfDSet;
  bitfieldType: CV_typ_t;
  bitfieldTypStart: CV_typ_t;
  tdsElLeaf: PTDS_lfEnum;
  tdsElFieldsTyp: PTDS_TYPTYPE;
  tdsElField: PTDS_lfEnumerate;
  tdsElFieldEnd: Pointer;
  typSize: UInt16;
  pOutTyp: PTYPTYPE;
  pOutListLeaf: Pointer;
  structFieldsTyp: CV_typ_t;
  fieldListTypSize: UInt16;
  fieldSize,
  fieldCount: UInt16;
begin
{$POINTERMATH ON}
  pInLeaf := PTDS_lfDSet(@pInTyp.leaf);

  // Figure out bitfield base type
  if (pInLeaf.size mod 4) = 0 then begin
    bitfieldType := T_ULONG;
    fieldSize := 32;
    fieldCount := pInLeaf.size div 4;
  end
  else if (pInLeaf.size mod 2) = 0 then begin
    bitfieldType := T_USHORT;
    fieldSize := 16;
    fieldCount := pInLeaf.size div 2;
  end
  else begin
    bitfieldType := T_UCHAR;
    fieldSize := 8;
    fieldCount := pInLeaf.size;
  end;

  // Is this based on an enumerated type?
  tdsElFieldsTyp := nil;
  tdsElLeaf := nil;
  tdsElFieldEnd := nil;
  if pInLeaf.eltype >= $1000 then begin
    tdsElLeaf := @FTypesConverter.FTDSParser.GlobalTypes[pInLeaf.eltype].leaf;
    if tdsElLeaf.leaf = TDS_LF_ENUM then begin
      tdsElFieldsTyp := FTypesConverter.FTDSParser.GlobalTypes[PTDS_lfEnum(tdsElLeaf).field];
      tdsElFieldEnd := PUInt8(@tdsElFieldsTyp.leaf) + tdsElFieldsTyp.len;
    end;
  end;

  // Based on an enumerated type, so we build a struct (LF_STRUCTURE) that points to a field list
  // (LF_FIELDLIST) full of members (LF_MEMBER) that point to bitfield types (LF_BITFIELD).
  if tdsElFieldsTyp <> nil then begin // based on enumeration, so we can add fields
    // Build the LF_BITFIELD types
    bitfieldTypStart := 0;
    tdsElField := @PTDS_lfFieldList(@tdsElFieldsTyp.leaf).data[0];
    typSize := SizeOf(pOutTyp.len) + BITFIELD_Size;
    fieldListTypSize := 0;
    while NativeUInt(tdsElField) < NativeUInt(tdsElFieldEnd) do begin
      Assert(tdsElField.leaf = TDS_LF_ENUMERATE);
      Assert(PUInt16(@tdsElField.value[0])^ < TDS_LF_CHAR);
      if bitfieldTypStart = 0 then
        bitfieldTypStart := FTypesConverter.AddType(typSize, pOutTyp)
      else
        FTypesConverter.AddType(typSize, pOutTyp);
      BITFIELD_Fill(
        @pOutTyp.leaf,
        bitfieldType,
        PUInt16(@tdsElField.value[0])^ mod fieldSize);

      // Calculate the member leaf size for this enumeration value.
      Inc(fieldListTypSize,
        MEMBER_Size(
          // dummy offset...it'll never be negative or larger than 32
          0,
          FTypesConverter.FTDSParser.Names[tdsElField.name]));

      tdsElField := PTDS_lfEnumerate(NextField(PTDS_lfEasy(tdsElField)));
    end;
    tdsElField := @PTDS_lfFieldList(@tdsElFieldsTyp.leaf).data[0]; // save for name reference

    // Now build the LF_FIELDLIST type full of LF_MEMBER leaves
    // Calculate the total type size. First put in lfFieldList size minus the data placeholder at
    // the end:
    typSize := SizeOf(pOutTyp.len) +
      FIELDLIST_Size(
        fieldListTypSize);
    structFieldsTyp := FTypesConverter.AddType(typSize, pOutTyp);
    FIELDLIST_Fill(
      @pOutTyp.leaf,
      pOutListLeaf);
    while NativeUInt(tdsElField) < NativeUInt(tdsElFieldEnd) do begin
      pOutListLeaf :=
        MEMBER_Fill(
          pOutListLeaf,
          CV_public,
          bitfieldTypStart,
          PUInt16(@tdsElField.value[0])^ div fieldSize,
          FTypesConverter.FTDSParser.Names[tdsElField.name]);

      Inc(bitfieldTypStart);
      tdsElField := PTDS_lfEnumerate(NextField(PTDS_lfEasy(tdsElField)));
    end;

    // Finally, build the struct that holds all of this
    typSize := SizeOf(pOutTyp.len) +
      CLASS_STRUCTURE_Size(
        // Dummy size since it will be at most 32 bytes
        0,
        FTypesConverter.FTDSParser.Names[pInLeaf.name]);
    Result := FTypesConverter.AddType(typSize, pOutTyp);
    CLASS_STRUCTURE_Fill(
      @pOutTyp.leaf,
      LF_STRUCTURE,
      tdsElLeaf.count,
      False,
      structFieldsTyp,
      0,
      pInLeaf.size,
      FTypesConverter.FTDSParser.Names[pInLeaf.name]);
  end
  else begin // based on basic or ranged type, just emit basic type or array of type
    if fieldCount <> 1 then begin
      // Set up array type
      typSize := SizeOf(pOutTyp.len) +
        ARRAY_Size(
          // Dummy size since it will be at most 32 bytes
          0,
          // nil because type is anonymous
          FTypesConverter.FTDSParser.Names[pInLeaf.name]);
      Result := FTypesConverter.AddType(typSize, pOutTyp);
      ARRAY_Fill(
        @pOutTyp.leaf,
        bitfieldType,
        T_ULONG,
        fieldCount,
        FTypesConverter.FTDSParser.Names[pInLeaf.name]);
    end
    else
      Result := bitfieldType; // If not an array, just output the basic type
  end;
{$POINTERMATH OFF}
end;

function TTDSToCVConverterDRANGED.Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t;
var
  pInLeaf: PTDS_lfDRanged;
begin
  // Just return the basic underlying type or the conversion of the underlying type
  pInLeaf := @pInTyp.leaf;
  Result := pInLeaf.utype;
  // Type conversion table fixups (because no types are created here)
  FTypesConverter.FCVTypeConvFixups.Add(inTypIdx);
end;

function DIMCON_Size(leaf, rank: UInt16; range: array of Int64): UInt16;
var
  I: Integer;
begin
  if leaf = LF_DIMCONLU then
    // LF_DIMCONLU must have twice rank number of values in range
    Assert(Length(range) = (rank shl 1))
  else
    // LF_DIMCONU has rank number of values in range
    Assert(Length(range) = rank);
  Result := SizeOf(lfDimCon) - SizeOf(PlfDimCon(nil).dim);
  for I := 0 to Length(range) - 1 do
    Inc(Result, SignedIntegerLeafCb(range[I]));
end;

procedure DIMCON_Fill(pOutLeaf: PlfDimCon; leaf: UInt16; typ: CV_typ_t; rank: UInt16;
  range: array of Int64);
var
  I: Integer;
  pData: PUInt8;
begin
  pOutLeaf.leaf := leaf;
  pOutLeaf.typ := typ;
  pOutLeaf.rank := rank;
  pData := @pOutLeaf.dim[0];
  for I := 0 to Length(range) - 1 do
    pData := FillSignedIntegerLeaf(range[I], pData);
end;

function DIMARRAY_Size(name: PAnsiChar): UInt16;
begin
  Result := SizeOf(lfDimArray) - SizeOf(PlfDimArray(nil).name);
  Inc(Result, System.AnsiStrings.StrLen(name) + 1);
end;

procedure DIMARRAY_Fill(pOutLeaf: PlfDimArray; elemtype, diminfo: CV_typ_t; name: PAnsiChar);
var
  pData: PAnsiChar;
begin
  pOutLeaf.leaf := LF_DIMARRAY;
  pOutLeaf.utype := elemtype;
  pOutLeaf.diminfo := diminfo;
  pData := @pOutLeaf.name[0];
  if name = nil then
    pData^ := #0
  else
    System.AnsiStrings.StrCopy(pData, name);
end;

function TTDSToCVConverterDARRAY.Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t;
var
  pInLeaf: PTDS_lfDArray;
  pInRangedLeaf: PTDS_lfDRanged;
  pOutTyp: PTYPTYPE;
  typSize: UInt16;
  dcluTyp: CV_typ_t;
  pData: PUInt8;
  arrSize: Int64;
  DimLow,
  DimHigh: Int64;
begin
  pInLeaf := @pInTyp.leaf;
  pData := @pInLeaf.data[0];
  LeafSignedValue(pData, arrSize);

  if (pInLeaf.rangetype < $1000) or
     (FTypesConverter.FTDSParser.GlobalTypes[pInLeaf.rangetype].leaf <> TDS_LF_DRANGED) then begin
    // non-ranged type, so just emit LF_ARRAY
    if arrSize = -1 then
      arrSize := 0;
    typSize := SizeOf(pOutTyp.len) +
      ARRAY_Size(
        arrSize,
        FTypesConverter.FTDSParser.Names[pInLeaf.name]);
    Result := FTypesConverter.AddType(typSize, pOutTyp);
    ARRAY_Fill(
      @pOutTyp.leaf,
      pInLeaf.elemtype,
      pInLeaf.rangetype,
      arrSize,
      FTypesConverter.FTDSParser.Names[pInLeaf.name]);
    // Fixups
    FTypesConverter.FCVTypeFixups.Add(@PlfArray(@pOutTyp.leaf).elemtype);
  end
  else begin
    // Set up array dimension descriptor type based on Delphi ranged type
    pInRangedLeaf := @FTypesConverter.FTDSParser.GlobalTypes[pInLeaf.rangetype].leaf;
    Assert(pInRangedLeaf.leaf = TDS_LF_DRANGED);
    if arrSize = -1 then begin
      // Infinite array, so just emit LF_ARRAY of size 0 based on the range's underlying type
      typSize := SizeOf(pOutTyp.len) +
        ARRAY_Size(
          0,
          FTypesConverter.FTDSParser.Names[pInLeaf.name]);
      Result := FTypesConverter.AddType(typSize, pOutTyp);
      ARRAY_Fill(
        @pOutTyp.leaf,
        pInLeaf.elemtype,
        pInRangedLeaf.utype,
        0,
        FTypesConverter.FTDSParser.Names[pInLeaf.name]);
      // Fixups
      FTypesConverter.FCVTypeFixups.Add(@PlfArray(@pOutTyp.leaf).elemtype);
      FTypesConverter.FCVTypeFixups.Add(@PlfArray(@pOutTyp.leaf).idxtype);
    end
    else begin
      pData := @pInRangedLeaf.data[0];
      pData := LeafSignedValue(pData, DimLow);
      LeafSignedValue(pData, DimHigh);
      typSize := SizeOf(pOutTyp.len) +
        DIMCON_Size(
          LF_DIMCONLU,
          1,
          [DimLow, DimHigh]);
      dcluTyp := FTypesConverter.AddType(typSize, pOutTyp);
      DIMCON_Fill(
        @pOutTyp.leaf,
        LF_DIMCONLU,
        pInRangedLeaf.utype,
        1,
        [DimLow, DimHigh]);
      // Fixups
      FTypesConverter.FCVTypeFixups.Add(@PlfDimCon(@pOutTyp.leaf).typ);

      // Set up array type
      typSize := SizeOf(pOutTyp.len) +
        DIMARRAY_Size(
          FTypesConverter.FTDSParser.Names[pInLeaf.name]);
      Result := FTypesConverter.AddType(typSize, pOutTyp);
      DIMARRAY_Fill(
        @pOutTyp.leaf,
        pInLeaf.elemtype,
        dcluTyp,
        FTypesConverter.FTDSParser.Names[pInLeaf.name]);
      // Fixups
      FTypesConverter.FCVTypeFixups.Add(@PlfDimArray(@pOutTyp.leaf).utype);
    end;
  end;
end;

function TTDSToCVConverterDSHORTSTR.Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t;
const
  FIELD_LEN: AnsiString = 'len';
  FIELD_STR: AnsiString = 'str';
var
  pInLeaf: PTDS_lfDShortStr;
  shortStrLen: Int64;
  pOutTyp: PTYPTYPE;
  typCharArr: CV_typ_t;
  typStructFields: CV_typ_t;
  typSize: UInt16;
  pOutListLeaf: Pointer;
begin
  pInLeaf := @pInTyp.leaf;
  LeafSignedValue(@pInLeaf.data[0], shortStrLen);
  if (shortStrLen < 0) or (shortStrLen > 255) then
    shortStrLen := 255; // maximum size
  Dec(shortStrLen); // Account for length byte

  // Build char array type
  typSize := SizeOf(pOutTyp.len) +
    ARRAY_Size(
      shortStrLen,
      '');
  typCharArr := FTypesConverter.AddType(typSize, pOutTyp);
  ARRAY_Fill(
    @pOutTyp.leaf,
    T_RCHAR,
    T_UCHAR,
    shortStrLen,
    '');

  // Build struct field list for ShortString
  typSize := 0;
  Inc(typSize, MEMBER_Size(0, PAnsiChar(FIELD_LEN)));
  Inc(typSize, MEMBER_Size(1, PAnsiChar(FIELD_STR)));
  typSize := SizeOf(pOutTyp.len) + FIELDLIST_Size(typSize);
  typStructFields := FTypesConverter.AddType(typSize, pOutTyp);
  FIELDLIST_Fill(
    @pOutTyp.leaf,
    pOutListLeaf);
  // add field for string length
  pOutListLeaf :=
    MEMBER_Fill(
      pOutListLeaf, // pOutLeaf
      CV_public,    // access
      T_UCHAR,      // typ
      0,            // offset
      PAnsiChar(FIELD_LEN));  // name
  // add field for string
  pOutListLeaf :=
    MEMBER_Fill(
      pOutListLeaf, // pOutLeaf
      CV_public,    // access
      typCharArr,   // typ
      1,            // offset
      PAnsiChar(FIELD_STR));  // name

  // Build struct for ShortString
  typSize := SizeOf(pOutTyp.len) +
    CLASS_STRUCTURE_Size(
      shortStrLen + 1,
      FTypesConverter.FTDSParser.Names[pInLeaf.name]);
  Result := FTypesConverter.AddType(typSize, pOutTyp);
  CLASS_STRUCTURE_Fill(
    @pOutTyp.leaf,    // pOutLeaf
    LF_STRUCTURE,     // leaf
    2,                // count
    False,            // ctor
    typStructFields,  // field
    0,                // vshape
    shortStrLen + 1,  // instsize
    FTypesConverter.FTDSParser.Names[pInLeaf.name]);  // name
end;

function TTDSToCVConverterDMETHODREF.Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t;
const
  FIELD_CODE: AnsiString = 'code';
  FIELD_DATA: AnsiString = 'data';
var
  pInLeaf: PTDS_lfDMethodRef;
  pOutTyp: PTYPTYPE;
  mFuncTyp,
  ptrTyp,
  fieldTyp: CV_typ_t;
  typSize: UInt16;
  pOutListLeaf: Pointer;
begin
  pInLeaf := @pInTyp.leaf;

  // Build LF_MFUNCTION
  typSize := SizeOf(pOutTyp.len) + MFUNCTION_Size;
  mFuncTyp := FTypesConverter.AddType(typSize, pOutTyp);
  MFUNCTION_Fill(
    @pOutTyp.leaf,
    pInLeaf.rvtype,
    FTypesConverter.FTObjectType,
    FTypesConverter.FTObjectRefType,
    // There is no Borland fastcall equivalent
    IfThen(pInLeaf.calltype = TDS_CALL_BORLFAST, CV_CALL_GENERIC, pInLeaf.calltype),
    pInLeaf.parmcount,
    pInLeaf.arglist);
  // Fixups
  FTypesConverter.FCVTypeFixups.Add(@PlfMFunc(@pOutTyp.leaf).rvtype);
  FTypesConverter.FCVTypeFixups.Add(@PlfMFunc(@pOutTyp.leaf).classtype);
  FTypesConverter.FCVTypeFixups.Add(@PlfMFunc(@pOutTyp.leaf).thistype);
  FTypesConverter.FCVTypeFixups.Add(@PlfMFunc(@pOutTyp.leaf).arglist);

  // Build LF_POINTER -> created LF_MFUNCTION
  typSize := SizeOf(pOutTyp.len) + POINTER_Size(True);
  ptrTyp := FTypesConverter.AddType(typSize, pOutTyp);
  POINTER_Fill(
    @pOutTyp.leaf,
    mFuncTyp,
    CV_PTR_MODE_PMFUNC,
    FTypesConverter.FTObjectType,
    CV_PMTYPE_F_Single);
  // Fixups
  FTypesConverter.FCVTypeFixups.Add(@PlfPointer(@pOutTyp.leaf).pmclass);

// Build LF_FIELDLIST
  typSize := 0;
  Inc(typSize, MEMBER_Size(0, PAnsiChar(FIELD_CODE)));
  Inc(typSize, MEMBER_Size(4, PAnsiChar(FIELD_DATA)));
  typSize := SizeOf(pOutTyp.len) + FIELDLIST_Size(typSize);
  fieldTyp := FTypesConverter.AddType(typSize, pOutTyp);
  FIELDLIST_Fill(
    @pOutTyp.leaf,
    pOutListLeaf);

  //   - LF_MEMBER -> created LF_POINTER -> created LF_MFUNCTION
  pOutListLeaf :=
    MEMBER_Fill(
      pOutListLeaf,
      CV_public,
      ptrTyp,
      0,
      PAnsiChar(FIELD_CODE));

  //   - LF_MEMBER -> LF_POINTER of TObject
  pOutListLeaf :=
    MEMBER_Fill(
      pOutListLeaf,
      CV_public,
      FTypesConverter.FTObjectRefType,
      0,
      PAnsiChar(FIELD_DATA));
  // Fixups
  FTypesConverter.FCVTypeFixups.Add(@PlfMember(pOutListLeaf).index);

  // Build LF_STRUCTURE -> created LF_FIELDLIST
  typSize := SizeOf(pOutTyp.len) +
    CLASS_STRUCTURE_Size(
      8,  // instsize
      '');  // name
  Result := FTypesConverter.AddType(typSize, pOutTyp);
  CLASS_STRUCTURE_Fill(
    @pOutTyp.leaf,
    LF_STRUCTURE,   // leaf
    2,              // count
    False,          // ctor
    fieldTyp,       // field
    0,              // vshape
    8,              // instsize
    '');            // name
end;

function TTDSToCVConverterDPROPERTY.Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t;
begin
  Result := 0;  // Delphi properties aren't converted
end;

function GenerateStringType(FTypesConverter: TTDSToPDBTypesConverter; chartype: CV_typ_t;
  lengthOnly: Boolean): CV_typ_t;
const
  FIELD_codePage: AnsiString = 'codePage';
  FIELD_elemSize: AnsiString = 'elemSize';
  FIELD_refCnt: AnsiString = 'refCnt';
  FIELD_length: AnsiString = 'length';
  FIELD_str: AnsiString = 'str';
var
  arrTyp,
  fieldTyp,
  structTyp: CV_typ_t;
  typSize: UInt16;
  pOutTyp: PTYPTYPE;
  pOutListLeaf: Pointer;
  structSize: Int64;
  structCount: UInt16;
begin
  // Build LF_ARRAY of chartype
  typSize := SizeOf(pOutTyp.len) +
    ARRAY_Size(
      0,    // size
      '');  // name
  arrTyp := FTypesConverter.AddType(typSize, pOutTyp);
  ARRAY_Fill(
    @pOutTyp.leaf,  // pOutLeaf
    chartype,       // elemtype
    T_LONG,         // idxtype
    0,              // size
    '');            // name

  // Build LF_FIELDLIST
  typSize := 0;
  if not lengthOnly then begin
    Inc(typSize, MEMBER_Size(-12, PAnsiChar(FIELD_codePage)));
    Inc(typSize, MEMBER_Size(-10, PAnsiChar(FIELD_elemSize)));
    Inc(typSize, MEMBER_Size(-8, PAnsiChar(FIELD_refCnt)));
  end;
  Inc(typSize, MEMBER_Size(-4, PAnsiChar(FIELD_length)));
  Inc(typSize, MEMBER_Size(0, PAnsiChar(FIELD_str)));
  typSize := SizeOf(pOutTyp.len) + FIELDLIST_Size(typSize);
  fieldTyp := FTypesConverter.AddType(typSize, pOutTyp);
  FIELDLIST_Fill(
    @pOutTyp.leaf,  // pOutLeaf
    pOutListLeaf);  // pOutListLeaf

  if not lengthOnly then begin
    // - LF_MEMBER -> codePage (T_USHORT) - offset -12
    pOutListLeaf :=
      MEMBER_Fill(
        pOutListLeaf, // pOutLeaf
        CV_public,    // access
        T_USHORT,     // typ
        -12,          // offset
        PAnsiChar(FIELD_codePage)); // name

    // - LF_MEMBER -> elemSize (T_USHORT) - offset -10
    pOutListLeaf :=
      MEMBER_Fill(
        pOutListLeaf, // pOutLeaf
        CV_public,    // access
        T_USHORT,     // typ
        -10,          // offset
        PAnsiChar(FIELD_elemSize)); // name

    // - LF_MEMBER -> refCnt (T_LONG) - offset -8
    pOutListLeaf :=
      MEMBER_Fill(
        pOutListLeaf, // pOutLeaf
        CV_public,    // access
        T_LONG,       // typ
        -8,           // offset
        PAnsiChar(FIELD_refCnt)); // name
  end;

  // - LF_MEMBER -> length (T_LONG) - offset -4
  pOutListLeaf :=
    MEMBER_Fill(
      pOutListLeaf, // pOutLeaf
      CV_public,    // access
      T_LONG,       // typ
      -4,           // offset
      PAnsiChar(FIELD_length)); // name

  // - LF_MEMBER -> created LF_ARRAY of T_RCHAR - offset 0
  pOutListLeaf :=
    MEMBER_Fill(
      pOutListLeaf, // pOutLeaf
      CV_public,    // access
      arrTyp,       // typ
      0,            // offset
      PAnsiChar(FIELD_str));  // name

  // Build LF_STRUCTURE -> created LF_FIELDLIST
  if not lengthOnly then begin
    structSize := 12;
    structCount := 5;
  end
  else begin
    structSize := 4;
    structCount := 2;
  end;
  typSize := SizeOf(pOutTyp.len) +
    CLASS_STRUCTURE_SIZE(
      structSize,
      '');
  structTyp := FTypesConverter.AddType(typSize, pOutTyp);
  CLASS_STRUCTURE_FILL(
    @pOutTyp.leaf,  // pOutLeaf
    LF_STRUCTURE,   // leaf
    structCount,    // count
    False,          // ctor
    fieldTyp,       // field
    0,              // vshape
    structSize,     // instsize
    '');  // name

  // Build LF_POINTER -> created LF_STRUCTURE
  typSize := SizeOf(pOutTyp.len) + POINTER_Size(False);
  Result := FTypesConverter.AddType(typSize, pOutTyp);
  POINTER_Fill(
    @pOutTyp.leaf,    // pOutLeaf
    structTyp,        // utype
    CV_PTR_MODE_REF,  // ptrmode
    // not a pointer to member
    0, 0);
end;

function TTDSToCVConverterDANSISTR.Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t;
begin
  Result := GenerateStringType(FTypesConverter, T_RCHAR, False);
end;

function TTDSToCVConverterDVARIANT.Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t;
begin
  Result := FTypesConverter.FTVarDataType; // Already defined, just use it here
  // Type conversion table fixups (because no types are created here)
  FTypesConverter.FCVTypeConvFixups.Add(inTypIdx);
end;

function TTDSToCVConverterDMETACLASS.Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t;
var
  pInLeaf: PTDS_lfDMetaClass;
  typSize: UInt16;
  pOutTyp: PTYPTYPE;
begin
  pInLeaf := PTDS_lfDMetaClass(@pInTyp.leaf);
  typSize := SizeOf(pOutTyp.len) + POINTER_Size(False);
  Result := FTypesConverter.AddType(typSize, pOutTyp);
  POINTER_Fill(
    @pOutTyp.leaf,
    pInLeaf.shape,
    CV_PTR_MODE_REF,
    // not a pointer to member
    0, 0);
  FTypesConverter.FCVTypeFixups.Add(@PlfPointer(@pOutTyp.leaf).utype);
end;

function TTDSToCVConverterDWIDESTR.Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t;
begin
  Result := GenerateStringType(FTypesConverter, T_WCHAR, True);
end;

function TTDSToCVConverterDUNISTR.Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t;
begin
  Result := GenerateStringType(FTypesConverter, T_WCHAR, False);
end;

function ARGLIST_Size(count: UInt16): UInt16;
begin
  Result := SizeOf(lfArgList) - SizeOf(PlfArgList(nil).arg);
  Inc(Result, count * SizeOf(CV_typ_t));
end;

procedure ARGLIST_Fill(pOutLeaf: PlfArgList; count: UInt16; arg: array of CV_typ_t);
var
  I: UInt16;
begin
  pOutLeaf.leaf := LF_ARGLIST;
  pOutLeaf.count := count;
  Assert(Length(arg) = count);
  if count > 0 then // necessary because I is unsigned
    for I := 0 to count - 1 do
      pOutLeaf.arg[I] := arg[I];
end;

function TTDSToCVConverterARGLIST.Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t;
var
  pInLeaf: PTDS_lfArgList;
  typSize: UInt16;
  pOutTyp: PTYPTYPE;
  I: UInt16;
  arg: TArray<CV_typ_t>;
begin
  pInLeaf := PTDS_lfArgList(@pInTyp.leaf);
  typSize := SizeOf(pOutTyp.len) + ARGLIST_Size(pInLeaf.count);
  Result := FTypesConverter.AddType(typSize, pOutTyp);
  SetLength(arg, pInLeaf.count);
  if pInLeaf.count > 0 then // necessary because I is unsigned
    for I := 0 to pInLeaf.count - 1 do
      arg[I] := pInLeaf.arg[I];
  ARGLIST_Fill(
    @pOutTyp.leaf,
    pInLeaf.count,
    arg);
  // Fixups
  if pInLeaf.count > 0 then // needed because I is unsigned
    for I := 0 to pInLeaf.count - 1 do
      FTypesConverter.FCVTypeFixups.Add(@PlfArgList(@pOutTyp.leaf).arg[I]);
end;

function BCLASS_Size: UInt16;
begin
  Result := SizeOf(lfBClass) - SizeOf(PlfBClass(nil).offset);
  Inc(Result, SignedIntegerLeafCb(0));
  PadSize(Result); // pad to make it up to 4 byte alignment
end;

function BCLASS_Fill(pOutLeaf: PlfBClass; index: CV_typ_t): Pointer;
var
  pData: PUInt8;
begin
  pOutLeaf.leaf := LF_BCLASS;
  pOutLeaf.attr._props := 0;
  pOutLeaf.attr.access := CV_public;
  pOutLeaf.attr.mprop := CV_MTvanilla;
  pOutLeaf.index := index;
  pData := FillSignedIntegerLeaf(0, @pOutLeaf.offset[0]);
  Result := pData; // return pointer to beginning of next member
  PadBuffer(Result); // need to pad field lists
end;

function ENUMERATE_Size(value: Int64; name: PAnsiChar): UInt16;
begin
  Result := SizeOf(lfEnumerate) - SizeOf(PlfEnumerate(nil).value);
  Inc(Result, SignedIntegerLeafCb(value));
  Inc(Result, System.AnsiStrings.StrLen(name) + 1);
  PadSize(Result); // pad to make it up to 4 byte alignment
end;

function ENUMERATE_Fill(pOutLeaf: PlfEnumerate; value: Int64; name: PAnsiChar): Pointer;
var
  pData: PUInt8;
begin
  pOutLeaf.leaf := LF_ENUMERATE;
  pOutLeaf.attr._props := 0; // Init all fields to 0/false
  pOutLeaf.attr.access := CV_public;
  pData := @pOutLeaf.value[0];
  pData := FillSignedIntegerLeaf(value, pData);
  if name = nil then
    pData^ := 0
  else
    pData := PUInt8(System.AnsiStrings.StrECopy(PAnsiChar(pData), name));
  Inc(pData); // move past null char
  // Add in pad bytes to pad up to 4 byte alignment
  Result := pData; // return pointer to beginning of next member
  PadBuffer(Result);
end;

function STMEMBER_Size(name: PAnsiChar): UInt16;
begin
  Result := SizeOf(lfSTMember) - SizeOf(PlfSTMember(nil).Name);
  Inc(Result, System.AnsiStrings.StrLen(name) + 1);
  PadSize(Result); // pad to make it up to 4 byte alignment
end;

function STMEMBER_Fill(pOutLeaf: PlfSTMember; access: UInt16; index: CV_typ_t; name: PAnsiChar): Pointer;
var
  pData: PUInt8;
begin
  pOutLeaf.leaf := LF_STMEMBER;
  pOutLeaf.attr._props := 0;
  pOutLeaf.attr.access := access;
  pOutLeaf.index := index;
  pData := @pOutLeaf.Name[0];
  if name = nil then
    pData^ := 0
  else
    pData := PUInt8(System.AnsiStrings.StrECopy(PAnsiChar(pData), name));
  Inc(pData); // move past null char
  // Add in pad bytes to pad up to 4 byte alignment
  Result := pData; // return pointer to beginning of next member
  PadBuffer(Result); // need to pad field lists
end;

function METHOD_Size(name: PAnsiChar): UInt16;
begin
  Result := SizeOf(lfMember) - SizeOf(PlfMethod(nil).Name);
  Inc(Result, System.AnsiStrings.StrLen(name) + 1);
  PadSize(Result); // pad to make it up to 4 byte alignment
end;

function METHOD_Fill(pOutLeaf: PlfMethod; count: UInt16; mList: CV_typ_t; name: PAnsiChar): Pointer;
var
  pData: PUInt8;
begin
  pOutLeaf.leaf := LF_METHOD;
  pOutLeaf.count := count;
  pOutLeaf.mList := mList;
  pData := @pOutLeaf.Name[0];
  if name = nil then
    pData^ := 0
  else
    pData := PUInt8(System.AnsiStrings.StrECopy(PAnsiChar(pData), name));
  Inc(pData); // move past null char
  // Add in pad bytes to pad up to 4 byte alignment
  Result := pData; // return pointer to beginning of next member
  PadBuffer(Result); // need to pad field lists
end;

function VFUNCTAB_Size: UInt16;
begin
  Result := SizeOf(lfVFuncTab);
end;

function VFUNCTAB_Fill(pOutLeaf: PlfVFuncTab; &type: CV_typ_t): Pointer;
begin
  pOutLeaf.leaf := LF_VFUNCTAB;
  pOutLeaf.pad0 := 0;
  pOutLeaf.&type := &type;
  Inc(pOutLeaf);
  Result := pOutLeaf;
  // padding not needed since this isn't variably sized and the record is already internally padded.
end;

function TTDSToCVConverterFIELDLIST.Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t;
var
  pInLeaf: PTDS_lfFieldList;
  typSize: UInt16;
  pOutTyp: PTYPTYPE;
  pInData,
  pOutListLeaf,
  pEnd: Pointer;
  value: Int64;
  tempType: PTDS_TYPTYPE;
  ptrType: CV_typ_t;
begin
{$POINTERMATH ON}
  pInLeaf := PTDS_lfFieldList(@pInTyp.leaf);
  pEnd := PUInt8(@pInTyp.leaf) + pInTyp.len;

  // Gather field list size
  typSize := 0;
  pInData := @pInLeaf.data[0];
  while NativeUInt(pInData) < NativeUInt(pEnd) do begin
    case PTDS_lfEasy(pInData).leaf of
      TDS_LF_BCLASS:
        Inc(typSize, BCLASS_Size);
      TDS_LF_ENUMERATE: begin
        LeafSignedValue(@PTDS_lfEnumerate(pInData).value[0], value);
        Inc(typSize,
          ENUMERATE_Size(
            value,
            FTypesConverter.FTDSParser.Names[PTDS_lfEnumerate(pInData).name]));
      end;
      TDS_LF_MEMBER: begin
        // Ignore Delphi properties
        if (PTDS_lfMember(pInData).index < $1000) or
           (FTypesConverter.FTDSParser.GlobalTypes[PTDS_lfMember(pInData).index].leaf <> TDS_LF_DPROPERTY) then begin
          LeafSignedValue(@PTDS_lfMember(pInData).offset[0], value);
          Inc(typSize,
            MEMBER_Size(
              value,
              FTypesConverter.FTDSParser.Names[PTDS_lfMember(pInData).name]));
        end;
      end;
      TDS_LF_STMEMBER:
        Inc(typSize,
          STMEMBER_Size(
            FTypesConverter.FTDSParser.Names[PTDS_lfSTMember(pInData).name]));
      TDS_LF_METHOD:
        Inc(typSize,
          METHOD_Size(
            FTypesConverter.FTDSParser.Names[PTDS_lfMethod(pInData).name]));
      TDS_LF_VFUNCTAB:
        Inc(typSize, VFUNCTAB_Size);
    else
      Assert(False);
    end;
    pInData := NextField(PTDS_lfEasy(pInData));
  end;

  typSize := SizeOf(pOutTyp.len) + FIELDLIST_Size(typSize);
  Result := FTypesConverter.AddType(typSize, pOutTyp);

  // Build CV field list
  FIELDLIST_Fill(
    @pOutTyp.leaf,
    pOutListLeaf);
  pInData := @pInLeaf.data[0];
  while NativeUInt(pInData) < NativeUInt(pEnd) do begin
    case PTDS_lfEasy(pInData).leaf of
      TDS_LF_BCLASS: begin
        // Fixups - must do before because of pOutListLeaf assignment
        FTypesConverter.FCVTypeFixups.Add(@PlfBClass(pOutListLeaf).index);
        pOutListLeaf :=
          BCLASS_Fill(
            pOutListLeaf,
            PTDS_lfBClass(pInData).index);
      end;
      TDS_LF_ENUMERATE: begin
        LeafSignedValue(@PTDS_lfEnumerate(pInData).value[0], value);
        pOutListLeaf :=
          ENUMERATE_Fill(
            pOutListLeaf,
            value,
            FTypesConverter.FTDSParser.Names[PTDS_lfEnumerate(pInData).name]);
      end;
      TDS_LF_MEMBER: begin
        // Ignore Delphi properties
        if (PTDS_lfMember(pInData).index < $1000) or
           (FTypesConverter.FTDSParser.GlobalTypes[PTDS_lfMember(pInData).index].leaf <> TDS_LF_DPROPERTY) then begin
          // Fixups - must do before because of pOutListLeaf assignment
          FTypesConverter.FCVTypeFixups.Add(@PlfMember(pOutListLeaf).index);
          LeafSignedValue(@PTDS_lfMember(pInData).offset[0], value);
          pOutListLeaf :=
            MEMBER_Fill(
              pOutListLeaf,
              PTDS_lfMember(pInData).attr.access,
              PTDS_lfMember(pInData).index,
              value,
              FTypesConverter.FTDSParser.Names[PTDS_lfMember(pInData).name]);
        end;
      end;
      TDS_LF_STMEMBER: begin
        // Fixups - must do before because of pOutListLeaf assignment
        FTypesConverter.FCVTypeFixups.Add(@PlfSTMember(pOutListLeaf).index);
        pOutListLeaf :=
          STMEMBER_Fill(
            pOutListLeaf,
            PTDS_lfSTMember(pInData).attr.access,
            PTDS_lfSTMember(pInData).index,
            FTypesConverter.FTDSParser.Names[PTDS_lfSTMember(pInData).name]);
      end;
      TDS_LF_METHOD: begin
        // Fixups - must do before because of pOutListLeaf assignment
        FTypesConverter.FCVTypeFixups.Add(@PlfMethod(pOutListLeaf).mList);
        pOutListLeaf :=
          METHOD_Fill(
            pOutListLeaf,
            PTDS_lfMethod(pInData).count,
            PTDS_lfMethod(pInData).mList,
            FTypesConverter.FTDSParser.Names[PTDS_lfMethod(pInData).name]);
      end;
      TDS_LF_VFUNCTAB: begin
        tempType := FTypesConverter.FTDSParser.GlobalTypes[PTDS_lfVFuncTab(pInData).&type];
        Assert(tempType <> nil);
        if tempType.leaf = TDS_LF_DMETACLASS then begin
          // class type vfunctab
          // Fixups - must do before because of pOutListLeaf assignment
          FTypesConverter.FCVTypeFixups.Add(@PlfVFuncTab(pOutListLeaf).&type);
          pOutListLeaf :=
            VFUNCTAB_Fill(
              pOutListLeaf,
              PTDS_lfVFuncTab(pInData).&type);
        end
        else begin
          // interface type vfunctab
          Assert(tempType.leaf = TDS_LF_VTSHAPE);
          // vfunctab never points directly to LF_VTSHAPE in codeview...instead it points to a
          // pointer which then points to LF_VTSHAPE. Emit a pointer and then the vfunctab that
          // points to it.
          typSize := SizeOf(pOutTyp.len) + POINTER_Size(false);
          ptrType := FTypesConverter.AddType(typSize, pOutTyp);
          POINTER_Fill(
            @pOutTyp.leaf,
            PTDS_lfVFuncTab(pInData).&type,
            CV_PTR_MODE_REF,
            0, 0);
          FTypesConverter.FCVTypeFixups.Add(@PlfPointer(@pOutTyp.leaf).utype);
          pOutListLeaf :=
            VFUNCTAB_Fill(
              pOutListLeaf,
              ptrType);
        end;
      end;
    else
      Assert(False);
    end;
    pInData := NextField(PTDS_lfEasy(pInData));
  end;
{$POINTERMATH OFF}
end;

function METHODLIST_Size(count, cVirtuals: Integer): UInt16;
begin
  Result := SizeOf(lfMethodList) - SizeOf(PlfMethodList(nil).mList);
  Inc(Result, count * (SizeOf(mlMethod) - SizeOf(PmlMethod(nil).vbaseoff)));
  Inc(Result, cVirtuals * SizeOf(PmlMethod(nil).vbaseoff));
end;

procedure METHODLIST_Fill(pOutLeaf: PlfMethodList; out pOutMeth: PmlMethod);
begin
  pOutLeaf.leaf := LF_METHODLIST;
  pOutMeth := @pOutLeaf.mList[0];
end;

function METHODLIST_mlMethod_Fill(pOutMeth: PmlMethod; access: UInt16; isintro: Boolean;
  index: CV_typ_t; vbaseoff: UInt32): PmlMethod;
begin
  pOutMeth.attr._props := 0;
  pOutMeth.attr.access := access;
  if isintro then
    pOutMeth.attr.mprop := CV_MTintro
  else
    pOutMeth.attr.mprop := CV_MTvanilla;
  pOutMeth.index := index;
  if isintro then
    pOutMeth.vbaseoff := vbaseoff;
  Result := NextMethod(pOutMeth);
end;

function TTDSToCVConverterMETHODLIST.Convert(inTypIdx: TDS_typ_t; pInTyp: PTDS_TYPTYPE): CV_typ_t;
var
  pInLeaf: PTDS_lfMethodList;
  typSize: UInt16;
  pOutTyp: PTYPTYPE;
  pEnd: PUInt8;
  pTDSMeth: PTDS_mlMethod;
  pMeth,
  pMethNext: PmlMethod;
  count,
  cVirtuals: Integer;
begin
{$POINTERMATH ON}
  pInLeaf := PTDS_lfMethodList(@pInTyp.leaf);
  pEnd := PUInt8(@pInTyp.leaf) + pInTyp.len;
  count := 0;
  cVirtuals := 0;
  pTDSMeth := @pInLeaf.mList[0];
  while NativeUInt(pTDSMeth) < NativeUInt(pEnd) do begin
    if pTDSMeth.attr.mprop = ATTR_MPROP_INTRO_VIRT then
      Inc(cVirtuals);
    pTDSMeth := NextMethod(pTDSMeth);
    Inc(count);
  end;
  typSize := SizeOf(pOutTyp.len) +
    METHODLIST_Size(
      count,
      cVirtuals);
  Result := FTypesConverter.AddType(typSize, pOutTyp);
  METHODLIST_Fill(
    @pOutTyp.leaf,
    pMeth);
  pTDSMeth := @pInLeaf.mList[0];
  while NativeUInt(pTDSMeth) < NativeUInt(pEnd) do begin
    pMethNext := METHODLIST_mlMethod_Fill(
      pMeth,
      pTDSMeth.attr.access,
      pTDSMeth.attr.mprop = ATTR_MPROP_INTRO_VIRT,
      pTDSMeth.index,
      IfThen(pTDSMeth.attr.mprop = ATTR_MPROP_INTRO_VIRT, pTDSMeth.vbaseoff, 0));
    // Fixups
    FTypesConverter.FCVTypeFixups.Add(@PmlMethod(pMeth).index);
    pMeth := pMethNext;
    pTDSMeth := NextMethod(pTDSMeth);
  end;
{$POINTERMATH OFF}
end;

constructor TTDSToCVTypeConverterBase.Create(TypesConverter: TTDSToPDBTypesConverter);
begin
  FTypesConverter := TypesConverter;
end;

procedure TTDSToPDBTypesConverter.AddConverter(leaf: UInt16; name: string; converter: TTDSToCVTypeConverterBase);
begin
  FTypeConverters.Add(leaf, converter);
  FTypeConverterNames.Add(leaf, name);
end;

procedure TTDSToPDBTypesConverter.AddConverters;
begin
  AddConverter(TDS_LF_POINTER,    'TDS_LF_POINTER',     TTDSToCVConverterPOINTER.Create(Self));
  AddConverter(TDS_LF_CLASS,      'TDS_LF_CLASS',       TTDSToCVConverterCLASS.Create(Self));
  AddConverter(TDS_LF_STRUCTURE,  'TDS_LF_STRUCTURE',   TTDSToCVConverterSTRUCTURE.Create(Self));
  AddConverter(TDS_LF_ENUM,       'TDS_LF_ENUM',        TTDSToCVConverterENUM.Create(Self));
  AddConverter(TDS_LF_PROCEDURE,  'TDS_LF_PROCEDURE',   TTDSToCVConverterPROCEDURE.Create(Self));
  AddConverter(TDS_LF_MFUNCTION,  'TDS_LF_MFUNCTION',   TTDSToCVConverterMFUNCTION.Create(Self));
  AddConverter(TDS_LF_VTSHAPE,    'TDS_LF_VTSHAPE',     TTDSToCVConverterVTSHAPE.Create(Self));
  AddConverter(TDS_LF_DSET,       'TDS_LF_DSET',        TTDSToCVConverterDSET.Create(Self));
  AddConverter(TDS_LF_DRANGED,    'TDS_LF_DRANGED',     TTDSToCVConverterDRANGED.Create(Self));
  AddConverter(TDS_LF_DARRAY,     'TDS_LF_DARRAY',      TTDSToCVConverterDARRAY.Create(Self));
  AddConverter(TDS_LF_DSHORTSTR,  'TDS_LF_DSHORTSTR',   TTDSToCVConverterDSHORTSTR.Create(Self));
  AddConverter(TDS_LF_DMETHODREF, 'TDS_LF_DMETHODREF',  TTDSToCVConverterDMETHODREF.Create(Self));
  AddConverter(TDS_LF_DPROPERTY,  'TDS_LF_DPROPERTY',   TTDSToCVConverterDPROPERTY.Create(Self));
  AddConverter(TDS_LF_DANSISTR,   'TDS_LF_DANSISTR',    TTDSToCVConverterDANSISTR.Create(Self));
  AddConverter(TDS_LF_DVARIANT,   'TDS_LF_DVARIANT',    TTDSToCVConverterDVARIANT.Create(Self));
  AddConverter(TDS_LF_DMETACLASS, 'TDS_LF_DMETACLASS',  TTDSToCVConverterDMETACLASS.Create(Self));
  AddConverter(TDS_LF_DWIDESTR,   'TDS_LF_DWIDESTR',    TTDSToCVConverterDWIDESTR.Create(Self));
  AddConverter(TDS_LF_DUNISTR,    'TDS_LF_DUNISTR',     TTDSToCVConverterDUNISTR.Create(Self));
  AddConverter(TDS_LF_ARGLIST,    'TDS_LF_ARGLIST',     TTDSToCVConverterARGLIST.Create(Self));
  AddConverter(TDS_LF_FIELDLIST,  'TDS_LF_FIELDLIST',   TTDSToCVConverterFIELDLIST.Create(Self));
  AddConverter(TDS_LF_METHODLIST, 'TDS_LF_METHODLIST',  TTDSToCVConverterMETHODLIST.Create(Self));
end;

function TTDSToPDBTypesConverter.AddType(Size: UInt16; out pTyp: PTYPTYPE): CV_typ_t;
begin
{$POINTERMATH ON}
  // Pad Size to multiple of 4 for natural alignment
  if (Size and 3) > 0 then
    Inc(Size, 4 - (Size and 3));

//  Assert(Size <= POOL_DELTA); - Always true
  if (FBufferPool[FBufferPool.Count - 1].Position + Size) >=
     FBufferPool[FBufferPool.Count - 1].Size then begin
    FCurrentBuffer := TMemoryStream.Create;
    FCurrentBuffer.Size := POOL_DELTA;
    FBufferPool.Add(FCurrentBuffer);
  end;
  pTyp := PTYPTYPE(PUInt8(FCurrentBuffer.Memory) + FCurrentBuffer.Position);
  pTyp.len := Size - SizeOf(pTyp.len);
  FCurrentBuffer.Position := FCurrentBuffer.Position + Size;
  Result := FCVTypes.Add(pTyp);
{$POINTERMATH OFF}
end;

procedure TTDSToPDBTypesConverter.Convert;
var
  I, J: Integer;
  currentType,
  newType: CV_typ_t;
  typLen: UInt16;
  TypeDataBase,
  TypeDataCur: Pointer;
  LogStream,
  ConvLog: TStreamWriter;
  TDSType: TDS_typ_t;
  NewTypeList: TList<PTYPTYPE>;
  TranslatedTypes: TDictionary<CV_typ_t, CV_typ_t>;
  TypesToProcess: TStack<UInt32>;
  PrevCount: Integer;
  Dependencies: TArray<CV_typ_t>;
begin
{$POINTERMATH ON}
  // Set up type translations for basic types to be identities
  for I := 0 to $1000 - 1 do
    FTypeConversions.Add(I, I);

  // Convert all types
  ConvLog := TStreamWriter.Create(TFileStream.Create('ConvLog.txt', fmCreate or fmShareDenyWrite));
  try
    ConvLog.OwnStream;
    if FTDSParser.GlobalTypes.Count > $1000 then // Only translate non-basic types
      for I := $1000 to FTDSParser.GlobalTypes.Count - 1 do begin
        newType := FTypeConverters[FTDSParser.GlobalTypes[I].leaf].Convert(I, FTDSParser.GlobalTypes[I]);
        if newType <> 0 then
          FTypeConversions.Add(I, newType);
        ConvLog.WriteLine('$%.8x -> $%.8x (%s)', [I, newType, FTypeConverterNames[FTDSParser.GlobalTypes[I].leaf]]);
      end;
  finally
    ConvLog.Free;
  end;

  // Fixup all assigned TDS types to CV types:
  if FCVTypeConvFixups.Count > 0 then begin
    // First, fixup any type conversion list issues. This happens when no type is emitted, rather a
    // direct equivalence is made from one TDS type to another. This TDS type is stored in the place
    // of the CV type, so we must grab the false CV type, convert it and then assign it back to
    // where the old TDS type was.
    for I := 0 to FCVTypeConvFixups.Count - 1 do
      FTypeConversions[FCVTypeConvFixups[I]] := FTypeConversions[FTypeConversions[FCVTypeConvFixups[I]]];
  end;
  FCVTypeConvFixups.Clear;
  if FCVTypeFixups.Count > 0 then begin
    // Now, fixup all TDS types placed within CV type variables in the newly emitted types. During
    // type construction, we store a list of pointers to these type variables that need fixing.
    for I := 0 to FCVTypeFixups.Count - 1 do
      FCVTypeFixups[I]^ := FTypeConversions[FCVTypeFixups[I]^];
  end;
  FCVTypeFixups.Clear;

  // Sort types in reverse dependency order and keep track of changes
  NewTypeList := TList<PTYPTYPE>.Create;
  for I := 0 to $1000 - 1 do // add in basic types with nil PTYPTYPE
    NewTypeList.Add(nil);
  TranslatedTypes := TDictionary<CV_typ_t, CV_typ_t>.Create;
  TypesToProcess := nil;
  try
    // Sort types in reverse dependency order and keep track of changes
    TypesToProcess := TStack<UInt32>.Create;
    if FCVTypes.Count > $1000 then begin // process only non-basic types
      for I := FCVTypes.Count - 1 downto $1000 do
        TypesToProcess.Push(I);

      LogStream := TStreamWriter.Create(TFileStream.Create('Reorderings.txt', fmCreate or fmShareDenyWrite));
      try
        LogStream.OwnStream;
        while TypesToProcess.Count > 0 do begin
          currentType := TypesToProcess.Peek; // Don't pop until we are ready to process it, or if we already have
          if (not TranslatedTypes.TryGetValue(currentType, newType)) or (newType = 0) then begin
            TranslatedTypes.AddOrSetValue(currentType, 0); // Not fully defined, but used to break dependency cycles
            Dependencies := GetTypeDependencies(FCVTypes[currentType]);
            PrevCount := TypesToProcess.Count;
            if Length(Dependencies) > 0 then
              for J := 0 to Length(Dependencies) - 1 do begin
                Assert(Dependencies[J] < UInt32(FCVTypes.Count));
                if (Dependencies[J] >= $1000) and
                   (not TranslatedTypes.ContainsKey(Dependencies[J])) then
                  TypesToProcess.Push(Dependencies[J]);
              end;
            if PrevCount = TypesToProcess.Count then begin // no unhandled dependencies
              TypesToProcess.Pop;
              TranslatedTypes[currentType] := NewTypeList.Add(FCVTypes[currentType]);
              LogStream.WriteLine('$%.8x -> $%.8x', [currentType, NewTypeList.Count - 1]);
            end;
          end
          else
            TypesToProcess.Pop;
        end;
      finally
        LogStream.Free;
      end;
    end;
    NewTypeList := AtomicExchange(Pointer(FCVTypes), Pointer(NewTypeList));

    // Update types within the types themselves
    if FCVTypes.Count > $1000 then // process only non-basic types
      for I := $1000 to FCVTypes.Count - 1 do
        TranslateTypes(FCVTypes[I], TranslatedTypes);

    // Now update type conversion list
    if FTypeConversions.Count > $1000 then
      for TDSType in FTypeConversions.Keys do
        if (TDSType >= $1000) and (FTypeConversions[TDSType] >= $1000) then begin
          FTypeConversions[TDSType] := TranslatedTypes[FTypeConversions[TDSType]];
        end;
    LogStream := TStreamWriter.Create(TFileStream.Create('ConvLogReordered.txt', fmCreate or fmShareDenyWrite));
    try
      LogStream.OwnStream;
      if FTypeConversions.Count > $1000 then
        for I := $1000 to FTypeConversions.Count - 1 do
          if FTypeConversions.TryGetValue(I, newType) then
            ConvLog.WriteLine('$%.8x -> $%.8x (%s)', [I, newType, FTypeConverterNames[FTDSParser.GlobalTypes[I].leaf]]);
    finally
      LogStream.Free;
    end;
  finally
    NewTypeList.Free; // Now should hold the old FGlobalTypes
    TypesToProcess.Free;
    TranslatedTypes.Free;
  end;

  // Merge type pool into one single buffer
  FTypeData := TMemoryStream.Create;
  FTypeData.Size := FBufferPool.Count * POOL_DELTA;
  TypeDataBase := FTypeData.Memory;
  TypeDataCur := TypeDataBase;
  LogStream := TStreamWriter.Create(TFileStream.Create('DumpTypes.txt', fmCreate or fmShareDenyWrite));
  LogStream.OwnStream;
  try
    if FCVTypes.Count > $1000 then
      for I := $1000 to FCVTypes.Count - 1 do begin
        typLen := FCVTypes[I].len + SizeOf(FCVTypes[I].len);
        Move(FCVTypes[I]^, TypeDataCur^, typLen);
        FCVTypes[I] := TypeDataCur;
        LogStream.WriteLine(DumpType(I, FCVTypes[I]));
        LogStream.WriteLine;
        Inc(PUInt8(TypeDataCur), typLen);
      end;
  finally
    LogStream.Free;
  end;
  FBufferPool.Free;
  FBufferPool := nil;
  FCurrentBuffer := nil;
{$POINTERMATH OFF}
end;

procedure TTDSToPDBTypesConverter.OnTypeFixupAdd(Sender: TObject; const Item: PCV_typ_t;
  Action: TCollectionNotification);
begin
//  if (Action = cnAdded) and (Item^ = $40DA) then asm
//    INT 3
//  end;
end;

constructor TTDSToPDBTypesConverter.Create(TDSParser: TTDSParser);
var
  I: Integer;
begin
  inherited Create;
  FTypeConversions := TDictionary<TDS_typ_t, CV_typ_t>.Create;
  FTypeConverters := TObjectDictionary<UInt16, TTDSToCVTypeConverterBase>.Create([doOwnsValues]);
  FTypeConverterNames := TDictionary<UInt16, string>.Create;
  FBufferPool := TObjectList<TMemoryStream>.Create;
  FCurrentBuffer := TMemoryStream.Create;
  FCurrentBuffer.Size := POOL_DELTA;
  FBufferPool.Add(FCurrentBuffer);
  FTDSParser := TDSParser;
  FCVTypes := TList<PTYPTYPE>.Create;
  for I := 0 to $1000 - 1 do // add in nil PTYPTYPEs for basic types
    FCVTypes.Add(nil);
  FCVTypeFixups := TList<PCV_typ_t>.Create;
  FCVTypeFixups.OnNotify := OnTypeFixupAdd;
  FCVTypeConvFixups := TList<TDS_typ_t>.Create;
  FTypeData := nil;
  FTObjectRefType := 0;
  FTObjectType := 0;
  FTVarDataType := 0;
  AddConverters;
  Convert;
end;

destructor TTDSToPDBTypesConverter.Destroy;
begin
  FCVTypeConvFixups.Free;
  FCVTypeFixups.Free;
  FCVTypes.Free;
  FTypeConversions.Free;
  FTypeConverters.Free;
  FTypeConverterNames.Free;
  FBufferPool.Free;
  FTypeData.Free;
  inherited Destroy;
end;

end.
