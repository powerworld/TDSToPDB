unit TDSUtils;

interface

uses
  System.SysUtils, System.Generics.Collections, TDSInfo, CVInfo;

type
  ETD32ToPDBError = class(Exception);

function NextField(Input: PTDS_lfEasy): PTDS_lfEasy; overload;
function NextField(Input: PlfEasy): PlfEasy; overload;
function NextMethod(Input: PTDS_mlMethod): PTDS_mlMethod; overload;
function NextMethod(Input: PmlMethod): PmlMethod; overload;
function ListFieldCb(Input: PTDS_lfEasy): UInt16; overload;
function ListFieldCb(Input: PlfEasy): UInt16; overload;

function LeafUnsignedValue(Input: Pointer; out Value: UInt64): Pointer;
function LeafSignedValue(Input: Pointer; out Value: Int64): Pointer;
function UnsignedIntegerLeafCb(Input: UInt64): UInt16;
function SignedIntegerLeafCb(Input: Int64): UInt16;
function FillUnsignedIntegerLeaf(Input: UInt64; pLeaf: Pointer): Pointer;
function FillSignedIntegerLeaf(Input: Int64; pLeaf: Pointer): Pointer;
function NumericLeafCb(Input: Pointer): UInt16;

function GetTypeDependencies(pType: PTYPTYPE): TArray<CV_typ_t>;
function GetListFieldDependency(Input: PlfEasy): CV_typ_t;

procedure TranslateTypes(pType: PTYPTYPE; TypeTranslation: TDictionary<CV_typ_t, CV_typ_t>);
procedure TranslateTypesInListField(pLeaf: PlfEasy; TypeTranslation: TDictionary<CV_typ_t, CV_typ_t>);

function DumpType(idx: CV_typ_t; pType: PTYPTYPE): string;

function PadSymLen(BaseLen: Integer): Integer; inline;
function PadTypLen(BaseLen: Integer): Integer; inline;

implementation

uses
  System.AnsiStrings, TD32ToPDBResources, CVConst;

function NextField(Input: PTDS_lfEasy): PTDS_lfEasy;
begin
  Result := Input;
  Inc(PUInt8(Result), ListFieldCb(Input));
  if PUInt8(Result)^ >= LF_PAD0 then // If padded, adjust
    Inc(PUInt8(Result), PUInt8(Result)^ and (not LF_PAD0));
end;

function NextField(Input: PlfEasy): PlfEasy;
begin
  Result := Input;
  Inc(PUInt8(Result), ListFieldCb(Input));
  if PUInt8(Result)^ >= LF_PAD0 then // If padded, adjust
    Inc(PUInt8(Result), PUInt8(Result)^ and (not LF_PAD0));
end;

function NextMethod(Input: PTDS_mlMethod): PTDS_mlMethod;
begin
  Result := Input;
  case Input.attr.mprop of
    ATTR_MPROP_INTRO_VIRT,
    ATTR_MPROP_PURE_INTRO_VIRT:
      Inc(Result);
  else
    // No virtual info
    Inc(PUInt8(Result), SizeOf(TDS_mlMethod) - SizeOf(Input.vbaseoff));
  end;
end;

function NextMethod(Input: PmlMethod): PmlMethod;
begin
  Result := Input;
  case Input.attr.mprop of
    ATTR_MPROP_INTRO_VIRT,
    ATTR_MPROP_PURE_INTRO_VIRT:
      Inc(Result);
  else
    // No virtual info
    Inc(PUInt8(Result), SizeOf(TDS_mlMethod) - SizeOf(Input.vbaseoff));
  end;
end;

function ListFieldCb(Input: PTDS_lfEasy): UInt16;
begin
  case Input.leaf of
    TDS_LF_BCLASS:
      Result := SizeOf(TDS_lfBClass) - SizeOf(PTDS_lfBClass(Input).offset) +
        NumericLeafCb(@PTDS_lfBClass(Input).offset);
    TDS_LF_ENUMERATE:
      Result := SizeOf(TDS_lfEnumerate) - SizeOf(PTDS_lfEnumerate(Input).value) +
        NumericLeafCb(@PTDS_lfEnumerate(Input).value);
    TDS_LF_MEMBER:
      Result := SizeOf(TDS_lfMember) - SizeOf(PTDS_lfMember(Input).offset) +
        NumericLeafCb(@PTDS_lfMember(Input).offset);
    TDS_LF_STMEMBER:
      Result := SizeOf(TDS_lfSTMember);
    TDS_LF_METHOD:
      Result := SizeOf(TDS_lfMethod);
    TDS_LF_VFUNCTAB:
      Result := SizeOf(TDS_lfVFuncTab) - SizeOf(PTDS_lfVFuncTab(Input).offset) +
        NumericLeafCb(@PTDS_lfVFuncTab(Input).offset);
  else
    raise ETD32ToPDBError.CreateResFmt(@RsListFieldCbInvalidLeaf, [Input.leaf]);
  end;
end;

function ListFieldCb(Input: PlfEasy): UInt16; overload;
var
  sizeOfNumericLeaf: UInt16;
begin
{$POINTERMATH ON}
  case Input.leaf of
    LF_BCLASS:
      Result := SizeOf(lfBClass) - SizeOf(PlfBClass(Input).offset) +
        NumericLeafCb(@PlfBClass(Input).offset);
    LF_ENUMERATE: begin
      sizeOfNumericLeaf := NumericLeafCb(@PlfEnumerate(Input).value);
      Result := SizeOf(lfEnumerate) - SizeOf(PlfEnumerate(Input).value) + sizeOfNumericLeaf;
      Inc(Result, System.AnsiStrings.StrLen(PAnsiChar(PUInt8(@PlfEnumerate(Input).value) + sizeOfNumericLeaf)) + 1);
    end;
    LF_MEMBER: begin
      sizeOfNumericLeaf := NumericLeafCb(@PlfMember(Input).offset);
      Result := SizeOf(lfMember) - SizeOf(PlfMember(Input).offset) + sizeOfNumericLeaf;
      Inc(Result, System.AnsiStrings.StrLen(PAnsiChar(PUInt8(@PlfMember(Input).offset) + sizeOfNumericLeaf)) + 1);
    end;
    LF_STMEMBER:
      Result := SizeOf(lfSTMember) - SizeOf(PlfSTMember(Input).Name) +
        System.AnsiStrings.StrLen(PAnsiChar(@PlfSTMember(Input).Name[0])) + 1;
    LF_METHOD:
      Result := SizeOf(lfMethod) - SizeOf(PlfMethod(Input).Name) +
        System.AnsiStrings.StrLen(PAnsiChar(@PlfMethod(Input).Name[0])) + 1;
    LF_VFUNCTAB:
      Result := SizeOf(lfVFuncTab);
    LF_INDEX:
      Result := SizeOf(lfIndex);
  else
    Assert(False); // Shouldn't make it here
    Result := 0;
  end;
{$POINTERMATH OFF}
end;

function LeafUnsignedValue(Input: Pointer; out Value: UInt64): Pointer;
begin
  Result := Input;
  case PlfEasy(Input).leaf of
    LF_USHORT: begin
      Value := PlfUShort(Input).val;
      Inc(PlfUShort(Result));
    end;
    LF_ULONG: begin
      Value := PlfULong(Input).val;
      Inc(PlfULong(Result));
    end;
    LF_UQUADWORD: begin
      Value := PlfUQuad(Input).val;
      Inc(PlfUQuad(Result));
    end;
  else
    Assert(PlfEasy(Input).leaf < LF_NUMERIC);
    Value := PUInt16(Input)^;
    Inc(PUInt16(Result));
  end;
end;

function LeafSignedValue(Input: Pointer; out Value: Int64): Pointer;
begin
  Result := Input;
  case PlfEasy(Input).leaf of
    LF_CHAR: begin
      Value := PlfChar(Input).val;
      Inc(PlfChar(Result));
    end;
    LF_SHORT: begin
      Value := PlfShort(Input).val;
      Inc(PlfShort(Result));
    end;
    LF_USHORT: begin
      Value := PlfUShort(Input).val;
      Inc(PlfUShort(Result));
    end;
    LF_LONG: begin
      Value := PlfLong(Input).val;
      Inc(PlfLong(Result));
    end;
    LF_ULONG: begin
      Value := PlfULong(Input).val;
      Inc(PlfULong(Result));
    end;
    LF_QUADWORD: begin
      Value := PlfQuad(Input).val;
      Inc(PlfQuad(Result));
    end;
  else
    Assert(PlfEasy(Input).leaf < LF_NUMERIC);
    Value := PUInt16(Input)^;
    Inc(PUInt16(Result));
  end;
end;

function UnsignedIntegerLeafCb(Input: UInt64): UInt16;
var
  easy: lfEasy;
begin
  if Input < LF_NUMERIC then
    easy.leaf := Input
  else if Input <= UInt16.MaxValue then
    easy.leaf := LF_USHORT
  else if Input <= UInt32.MaxValue then
    easy.leaf := LF_ULONG
  else
    easy.leaf := LF_UQUADWORD;
  Result := NumericLeafCb(@easy);
end;

function SignedIntegerLeafCb(Input: Int64): UInt16;
var
  easy: lfEasy;
begin
  if Input < 0 then begin
    if Input >= Int8.MinValue then
      easy.leaf := LF_CHAR
    else if Input >= Int16.MinValue then
      easy.leaf := LF_SHORT
    else if Input >= Int32.MinValue then
      easy.leaf := LF_LONG
    else
      easy.leaf := LF_QUADWORD;
  end
  else begin
    if Input < LF_NUMERIC then
      easy.leaf := Input
    else if Input <= UInt16.MaxValue then
      easy.leaf := LF_USHORT
    else if Input <= UInt32.MaxValue then
      easy.leaf := LF_ULONG
    else
      easy.leaf := LF_UQUADWORD;
  end;
  Result := NumericLeafCb(@easy);
end;

function FillUnsignedIntegerLeaf(Input: UInt64; pLeaf: Pointer): Pointer;
begin
  Result := pLeaf;
  if Input < LF_NUMERIC then begin
    PUInt16(pLeaf)^ := Input;
    Inc(PlfEasy(Result));
  end
  else if Input <= UInt16.MaxValue then with PlfUShort(pLeaf)^ do begin
    leaf := LF_USHORT;
    val := Input;
    Inc(PlfUShort(Result));
  end
  else if Input <= UInt32.MaxValue then with PlfULong(pLeaf)^ do begin
    leaf := LF_ULONG;
    val := Input;
    Inc(PlfULong(Result));
  end
  else with PlfUQuad(pLeaf)^ do begin
    leaf := LF_UQUADWORD;
    val := Input;
    Inc(PlfUQuad(Result));
  end;
end;

function FillSignedIntegerLeaf(Input: Int64; pLeaf: Pointer): Pointer;
begin
  Result := pLeaf;
  if Input < 0 then begin
    if Input >= Int8.MinValue then with PlfChar(pLeaf)^ do begin
      leaf := LF_CHAR;
      val := Input;
      Inc(PlfChar(Result));
    end
    else if Input >= Int16.MinValue then with PlfShort(pLeaf)^ do begin
      leaf := LF_SHORT;
      val := Input;
      Inc(PlfShort(Result));
    end
    else if Input >= Int32.MinValue then with PlfLong(pLeaf)^ do begin
      leaf := LF_LONG;
      val := Input;
      Inc(PlfLong(Result));
    end
    else with PlfQuad(pLeaf)^ do begin
      leaf := LF_QUADWORD;
      val := Input;
      Inc(PlfQuad(Result));
    end;
  end
  else begin
    if Input < LF_NUMERIC then begin
      PUInt16(pLeaf)^ := Input;
      Inc(PlfEasy(Result));
    end
    else if Input <= UInt16.MaxValue then with PlfUShort(pLeaf)^ do begin
      leaf := LF_USHORT;
      val := Input;
      Inc(PlfUShort(Result));
    end
    else if Input <= UInt32.MaxValue then with PlfULong(pLeaf)^ do begin
      leaf := LF_ULONG;
      val := Input;
      Inc(PlfULong(Result));
    end
    else with PlfUQuad(pLeaf)^ do begin
      leaf := LF_UQUADWORD;
      val := Input;
      Inc(PlfUQuad(Result));
    end;
  end;
end;

function NumericLeafCb(Input: Pointer): UInt16;
begin
  case PTDS_lfEasy(Input).leaf of
    LF_CHAR:        Result := SizeOf(lfChar);
    LF_SHORT:       Result := SizeOf(lfShort);
    LF_USHORT:      Result := SizeOf(lfUShort);
    LF_LONG:        Result := SizeOf(lfLong);
    LF_ULONG:       Result := SizeOf(lfULong);
    LF_REAL32:      Result := SizeOf(lfReal32);
    LF_REAL64:      Result := SizeOf(lfReal64);
    LF_REAL80:      Result := SizeOf(lfReal80);
    LF_REAL128:     Result := SizeOf(lfReal128);
    LF_QUADWORD:    Result := SizeOf(lfQuad);
    LF_UQUADWORD:   Result := SizeOf(lfUQuad);
    LF_REAL48:      Result := SizeOf(lfReal48);
    LF_COMPLEX32:   Result := SizeOf(lfCmplx32);
    LF_COMPLEX64:   Result := SizeOf(lfCmplx64);
    LF_COMPLEX80:   Result := SizeOf(lfCmplx80);
    LF_COMPLEX128:  Result := SizeOf(lfCmplx128);
    LF_VARSTRING:
      Result := SizeOf(lfVarString) - SizeOf(PlfVarString(Input).value) +
        PlfVarString(Input).len;
  else
    Assert(PlfEasy(Input).leaf < LF_NUMERIC);
    Result := 2;
  end;
end;

function GetTypeDependencies(pType: PTYPTYPE): TArray<CV_typ_t>;
const
  ResultDelta = 32;
var
  I: UInt32;
  pLeaf: PlfEasy;
  pMethod: PmlMethod;
  pTypeEnd: PTYPTYPE;
begin
{$POINTERMATH ON}
  // This is largely derived from discoverTypeIndices() in TypeIndexDiscover.cpp in LLVM
  case pType.leaf of
    LF_VTSHAPE: begin
      // Good
      SetLength(Result, 0);
    end;
    LF_POINTER: begin
      // Good
      if ((PlfPointer(@pType.leaf).attr.ptrmode = CV_PTR_MODE_PMEM) or
          (PlfPointer(@pType.leaf).attr.ptrmode = CV_PTR_MODE_PMFUNC)) then begin
        SetLength(Result, 2);
        Result[1] := PlfPointer(@pType.leaf).pmclass
      end
      else
        SetLength(Result, 1);
      Result[0] := PlfPointer(@pType.leaf).utype;
    end;
    LF_PROCEDURE: begin
      // Good
      SetLength(Result, 2);
      Result[0] := PlfProc(@pType.leaf).rvtype;
      Result[1] := PlfProc(@pType.leaf).arglist;
    end;
    LF_MFUNCTION: begin
      // Good
      SetLength(Result, 4);
      Result[0] := PlfMFunc(@pType.leaf).rvtype;
      Result[1] := PlfMFunc(@pType.leaf).classtype;
      Result[2] := PlfMFunc(@pType.leaf).thistype;
      Result[3] := PlfMFunc(@pType.leaf).arglist;
    end;
    LF_ARGLIST: begin
      // Good
      SetLength(Result, PlfArgList(@pType.leaf).count);
      if PlfArgList(@pType.leaf).count > 0 then
        for I := 0 to PlfArgList(@pType.leaf).count - 1 do
          Result[I] := PlfArgList(@pType.leaf).arg[I];
    end;
    LF_FIELDLIST: begin
      // Good
      pLeaf := @PlfFieldList(@pType.leaf).data[0];
      pTypeEnd := NextType(pType);
      SetLength(Result, 0);
      I := 0;
      while NativeUInt(pLeaf) < NativeUInt(pTypeEnd) do begin
        if I >= UInt32(Length(Result)) then
          SetLength(Result, Length(Result) + ResultDelta);
        Result[I] := GetListFieldDependency(pLeaf);
        if Result[I] <> 0 then Inc(I); // Only increment if dependency is returned
        pLeaf := NextField(pLeaf);
      end;
      SetLength(Result, I);
    end;
    LF_METHODLIST: begin
      // Good
      pMethod := @PlfMethodList(@pType.leaf).mList[0];
      pTypeEnd := NextType(pType);
      SetLength(Result, 0);
      I := 0;
      while NativeUInt(pMethod) < NativeUInt(pTypeEnd) do begin
        if I >= UInt32(Length(Result)) then
          SetLength(Result, Length(Result) + ResultDelta);
        Result[I] := PmlMethod(pMethod).index;
        Inc(I);
        pMethod := NextMethod(PmlMethod(pMethod));
      end;
      SetLength(Result, I);
    end;
    LF_DIMCONLU: begin
      // Good
      SetLength(Result, 1);
      Result[0] := PlfDimCon(@pType.leaf).typ;
    end;
    LF_BITFIELD: begin
      // Good
      SetLength(Result, 1);
      Result[0] := PlfBitfield(@pType.leaf).&type;
    end;
    LF_ARRAY: begin
      // Good
      SetLength(Result, 2);
      Result[0] := PlfArray(@pType.leaf).elemtype;
      Result[1] := PlfArray(@pType.leaf).idxtype;
    end;
    LF_CLASS: begin
      // Good
      SetLength(Result, 3);
      Result[0] := PlfClass(@pType.leaf).field;
      Result[1] := PlfClass(@pType.leaf).derived;
      Result[2] := PlfClass(@pType.leaf).vshape;
    end;
    LF_STRUCTURE: begin
      // Good
      SetLength(Result, 3);
      Result[0] := PlfStructure(@pType.leaf).field;
      Result[1] := PlfStructure(@pType.leaf).derived;
      Result[2] := PlfStructure(@pType.leaf).vshape;
    end;
    LF_UNION: begin
      // Good
      SetLength(Result, 1);
      Result[0] := PlfUnion(@pType.leaf).field;
    end;
    LF_ENUM: begin
      // Good
      SetLength(Result, 2);
      Result[0] := PlfEnum(@pType.leaf).utype;
      Result[1] := PlfEnum(@pType.leaf).field;
    end;
    LF_DIMARRAY: begin
      // Good
      SetLength(Result, 2);
      Result[0] := PlfDimArray(@pType.leaf).utype;
      Result[1] := PlfDimArray(@pType.leaf).diminfo;
    end;
  else
    Assert(False); // Shouldn't reach here
  end;
{$POINTERMATH OFF}
end;

function GetListFieldDependency(Input: PlfEasy): CV_typ_t;
begin
  case Input.leaf of
    // Good
    LF_BCLASS: Result := PlfBClass(Input).index;
    // Good
    LF_ENUMERATE: Result := 0; // no dependency
    // Good
    LF_MEMBER: Result := PlfMember(Input).index;
    // Good
    LF_STMEMBER: Result := PlfSTMember(Input).index;
    // Good
    LF_METHOD: Result := PlfMethod(Input).mList;
    // Good
    LF_VFUNCTAB: Result := PlfVFuncTab(Input).&type;
    LF_INDEX: Result := PlfIndex(Input).index;
  else
    Assert(False); // Shouldn't reach here
    Result := 0;
  end;
end;

procedure TranslateTypes(pType: PTYPTYPE; TypeTranslation: TDictionary<CV_typ_t, CV_typ_t>);
var
  typeNew: CV_typ_t;
  I: UInt32;
  pLeaf: PlfEasy;
  pMethod: PmlMethod;
  pTypeEnd: Pointer;
begin
  case pType.leaf of
    LF_VTSHAPE: begin
      // no translation required
    end;
    LF_POINTER: begin
      if TypeTranslation.TryGetValue(PlfPointer(@pType.leaf).utype, typeNew) then
        PlfPointer(@pType.leaf).utype := typeNew;
      if ((PlfPointer(@pType.leaf).attr.ptrmode = CV_PTR_MODE_PMEM) or
          (PlfPointer(@pType.leaf).attr.ptrmode = CV_PTR_MODE_PMFUNC)) and
         TypeTranslation.TryGetValue(PlfPointer(@pType.leaf).pmclass, typeNew) then
        PlfPointer(@pType.leaf).pmclass := typeNew;
    end;
    LF_PROCEDURE: begin
      if TypeTranslation.TryGetValue(PlfProc(@pType.leaf).rvtype, typeNew) then
        PlfProc(@pType.leaf).rvtype := typeNew;
      if TypeTranslation.TryGetValue(PlfProc(@pType.leaf).arglist, typeNew) then
        PlfProc(@pType.leaf).arglist := typeNew;
    end;
    LF_MFUNCTION: begin
      if TypeTranslation.TryGetValue(PlfMFunc(@pType.leaf).rvtype, typeNew) then
        PlfMFunc(@pType.leaf).rvtype := typeNew;
      if TypeTranslation.TryGetValue(PlfMFunc(@pType.leaf).classtype, typeNew) then
        PlfMFunc(@pType.leaf).classtype := typeNew;
      if TypeTranslation.TryGetValue(PlfMFunc(@pType.leaf).thistype, typeNew) then
        PlfMFunc(@pType.leaf).thistype := typeNew;
      if TypeTranslation.TryGetValue(PlfMFunc(@pType.leaf).arglist, typeNew) then
        PlfMFunc(@pType.leaf).arglist := typeNew;
    end;
    LF_ARGLIST: begin
      if PlfArgList(@pType.leaf).count > 0 then
        for I := 0 to PlfArgList(@pType.leaf).count - 1 do
          if TypeTranslation.TryGetValue(PlfArgList(@pType.leaf).arg[I], typeNew) then
            PlfArgList(@pType.leaf).arg[I] := typeNew;
    end;
    LF_FIELDLIST: begin
      pLeaf := @PlfFieldList(@pType.leaf).data[0];
      pTypeEnd := NextType(pType);
      while NativeUInt(pLeaf) < NativeUInt(pTypeEnd) do begin
        TranslateTypesInListField(pLeaf, TypeTranslation);
        pLeaf := NextField(pLeaf);
      end;
    end;
    LF_METHODLIST: begin
      pMethod := @PlfMethodList(@pType.leaf).mList[0];
      pTypeEnd := NextType(pType);
      while NativeUInt(pMethod) < NativeUInt(pTypeEnd) do begin
        if TypeTranslation.TryGetValue(PmlMethod(pMethod).index, typeNew) then
          PmlMethod(pMethod).index := typeNew;
        pMethod := NextMethod(PmlMethod(pMethod));
      end;
    end;
    LF_DIMCONLU: begin
      if TypeTranslation.TryGetValue(PlfDimCon(@pType.leaf).typ, typeNew) then
        PlfDimCon(@pType.leaf).typ := typeNew;
    end;
    LF_BITFIELD: begin
      if TypeTranslation.TryGetValue(PlfBitfield(@pType.leaf).&type, typeNew) then
        PlfBitfield(@pType.leaf).&type := typeNew;
    end;
    LF_ARRAY: begin
      if TypeTranslation.TryGetValue(PlfArray(@pType.leaf).elemtype, typeNew) then
        PlfArray(@pType.leaf).elemtype := typeNew;
      if TypeTranslation.TryGetValue(PlfArray(@pType.leaf).idxtype, typeNew) then
        PlfArray(@pType.leaf).idxtype := typeNew;
    end;
    LF_CLASS: begin
      if TypeTranslation.TryGetValue(PlfClass(@pType.leaf).field, typeNew) then
        PlfClass(@pType.leaf).field := typeNew;
      if TypeTranslation.TryGetValue(PlfClass(@pType.leaf).derived, typeNew) then
        PlfClass(@pType.leaf).derived := typeNew;
      if TypeTranslation.TryGetValue(PlfClass(@pType.leaf).vshape, typeNew) then
        PlfClass(@pType.leaf).vshape := typeNew;
    end;
    LF_STRUCTURE: begin
      if TypeTranslation.TryGetValue(PlfStructure(@pType.leaf).field, typeNew) then
        PlfStructure(@pType.leaf).field := typeNew;
      if TypeTranslation.TryGetValue(PlfStructure(@pType.leaf).derived, typeNew) then
        PlfStructure(@pType.leaf).derived := typeNew;
      if TypeTranslation.TryGetValue(PlfStructure(@pType.leaf).vshape, typeNew) then
        PlfStructure(@pType.leaf).vshape := typeNew;
    end;
    LF_UNION: begin
      if TypeTranslation.TryGetValue(PlfUnion(@pType.leaf).field, typeNew) then
        PlfUnion(@pType.leaf).field := typeNew;
    end;
    LF_ENUM: begin
      if TypeTranslation.TryGetValue(PlfEnum(@pType.leaf).utype, typeNew) then
        PlfEnum(@pType.leaf).utype := typeNew;
      if TypeTranslation.TryGetValue(PlfEnum(@pType.leaf).field, typeNew) then
        PlfEnum(@pType.leaf).field := typeNew;
    end;
    LF_DIMARRAY: begin
      if TypeTranslation.TryGetValue(PlfDimArray(@pType.leaf).utype, typeNew) then
        PlfDimArray(@pType.leaf).utype := typeNew;
      if TypeTranslation.TryGetValue(PlfDimArray(@pType.leaf).diminfo, typeNew) then
        PlfDimArray(@pType.leaf).diminfo := typeNew;
    end;
  else
    Assert(False); // Shouldn't reach here
  end;
end;

procedure TranslateTypesInListField(pLeaf: PlfEasy; TypeTranslation: TDictionary<CV_typ_t, CV_typ_t>);
var
  typeNew: CV_typ_t;
begin
  case pLeaf.leaf of
    LF_BCLASS:
      if TypeTranslation.TryGetValue(PlfBClass(pLeaf).index, typeNew) then
        PlfBClass(pLeaf).index := typeNew;
    LF_ENUMERATE: begin
      // nothing to translate
    end;
    LF_MEMBER:
      if TypeTranslation.TryGetValue(PlfMember(pLeaf).index, typeNew) then
        PlfMember(pLeaf).index := typeNew;
    LF_STMEMBER:
      if TypeTranslation.TryGetValue(PlfSTMember(pLeaf).index, typeNew) then
        PlfSTMember(pLeaf).index := typeNew;
    LF_METHOD:
      if TypeTranslation.TryGetValue(PlfMethod(pLeaf).mList, typeNew) then
        PlfMethod(pLeaf).mList := typeNew;
    LF_VFUNCTAB:
      if TypeTranslation.TryGetValue(PlfVFuncTab(pLeaf).&type, typeNew) then
        PlfVFuncTab(pLeaf).&type := typeNew;
    LF_INDEX:
      if TypeTranslation.TryGetValue(PlfIndex(pLeaf).index, typeNew) then
        PlfIndex(pLeaf).index := typeNew;
  else
    Assert(False); // Shouldn't reach here
  end;
end;

function LeafToName(leaf: UInt16): string;
begin
  case leaf of
    LF_MODIFIER_16t: Result := 'LF_MODIFIER_16t';
    LF_POINTER_16t: Result := 'LF_POINTER_16t';
    LF_ARRAY_16t: Result := 'LF_ARRAY_16t';
    LF_CLASS_16t: Result := 'LF_CLASS_16t';
    LF_STRUCTURE_16t: Result := 'LF_STRUCTURE_16t';
    LF_UNION_16t: Result := 'LF_UNION_16t';
    LF_ENUM_16t: Result := 'LF_ENUM_16t';
    LF_PROCEDURE_16t: Result := 'LF_PROCEDURE_16t';
    LF_MFUNCTION_16t: Result := 'LF_MFUNCTION_16t';
    LF_VTSHAPE: Result := 'LF_VTSHAPE';
    LF_COBOL0_16t: Result := 'LF_COBOL0_16t';
    LF_COBOL1: Result := 'LF_COBOL1';
    LF_BARRAY_16t: Result := 'LF_BARRAY_16t';
    LF_LABEL: Result := 'LF_LABEL';
    LF_NULL: Result := 'LF_NULL';
    LF_NOTTRAN: Result := 'LF_NOTTRAN';
    LF_DIMARRAY_16t: Result := 'LF_DIMARRAY_16t';
    LF_VFTPATH_16t: Result := 'LF_VFTPATH_16t';
    LF_PRECOMP_16t: Result := 'LF_PRECOMP_16t';
    LF_ENDPRECOMP: Result := 'LF_ENDPRECOMP';
    LF_OEM_16t: Result := 'LF_OEM_16t';
    LF_TYPESERVER_ST: Result := 'LF_TYPESERVER_ST';
    LF_SKIP_16t: Result := 'LF_SKIP_16t';
    LF_ARGLIST_16t: Result := 'LF_ARGLIST_16t';
    LF_DEFARG_16t: Result := 'LF_DEFARG_16t';
    LF_LIST: Result := 'LF_LIST';
    LF_FIELDLIST_16t: Result := 'LF_FIELDLIST_16t';
    LF_DERIVED_16t: Result := 'LF_DERIVED_16t';
    LF_BITFIELD_16t: Result := 'LF_BITFIELD_16t';
    LF_METHODLIST_16t: Result := 'LF_METHODLIST_16t';
    LF_DIMCONU_16t: Result := 'LF_DIMCONU_16t';
    LF_DIMCONLU_16t: Result := 'LF_DIMCONLU_16t';
    LF_DIMVARU_16t: Result := 'LF_DIMVARU_16t';
    LF_DIMVARLU_16t: Result := 'LF_DIMVARLU_16t';
    LF_REFSYM: Result := 'LF_REFSYM';
    LF_BCLASS_16t: Result := 'LF_BCLASS_16t';
    LF_VBCLASS_16t: Result := 'LF_VBCLASS_16t';
    LF_IVBCLASS_16t: Result := 'LF_IVBCLASS_16t';
    LF_ENUMERATE_ST: Result := 'LF_ENUMERATE_ST';
    LF_FRIENDFCN_16t: Result := 'LF_FRIENDFCN_16t';
    LF_INDEX_16t: Result := 'LF_INDEX_16t';
    LF_MEMBER_16t: Result := 'LF_MEMBER_16t';
    LF_STMEMBER_16t: Result := 'LF_STMEMBER_16t';
    LF_METHOD_16t: Result := 'LF_METHOD_16t';
    LF_NESTTYPE_16t: Result := 'LF_NESTTYPE_16t';
    LF_VFUNCTAB_16t: Result := 'LF_VFUNCTAB_16t';
    LF_FRIENDCLS_16t: Result := 'LF_FRIENDCLS_16t';
    LF_ONEMETHOD_16t: Result := 'LF_ONEMETHOD_16t';
    LF_VFUNCOFF_16t: Result := 'LF_VFUNCOFF_16t';
    LF_TI16_MAX: Result := 'LF_TI16_MAX';
    LF_MODIFIER: Result := 'LF_MODIFIER';
    LF_POINTER: Result := 'LF_POINTER';
    LF_ARRAY_ST: Result := 'LF_ARRAY_ST';
    LF_CLASS_ST: Result := 'LF_CLASS_ST';
    LF_STRUCTURE_ST: Result := 'LF_STRUCTURE_ST';
    LF_UNION_ST: Result := 'LF_UNION_ST';
    LF_ENUM_ST: Result := 'LF_ENUM_ST';
    LF_PROCEDURE: Result := 'LF_PROCEDURE';
    LF_MFUNCTION: Result := 'LF_MFUNCTION';
    LF_COBOL0: Result := 'LF_COBOL0';
    LF_BARRAY: Result := 'LF_BARRAY';
    LF_DIMARRAY_ST: Result := 'LF_DIMARRAY_ST';
    LF_VFTPATH: Result := 'LF_VFTPATH';
    LF_PRECOMP_ST: Result := 'LF_PRECOMP_ST';
    LF_OEM: Result := 'LF_OEM';
    LF_ALIAS_ST: Result := 'LF_ALIAS_ST';
    LF_OEM2: Result := 'LF_OEM2';
    LF_SKIP: Result := 'LF_SKIP';
    LF_ARGLIST: Result := 'LF_ARGLIST';
    LF_DEFARG_ST: Result := 'LF_DEFARG_ST';
    LF_FIELDLIST: Result := 'LF_FIELDLIST';
    LF_DERIVED: Result := 'LF_DERIVED';
    LF_BITFIELD: Result := 'LF_BITFIELD';
    LF_METHODLIST: Result := 'LF_METHODLIST';
    LF_DIMCONU: Result := 'LF_DIMCONU';
    LF_DIMCONLU: Result := 'LF_DIMCONLU';
    LF_DIMVARU: Result := 'LF_DIMVARU';
    LF_DIMVARLU: Result := 'LF_DIMVARLU';
    LF_BCLASS: Result := 'LF_BCLASS';
    LF_VBCLASS: Result := 'LF_VBCLASS';
    LF_IVBCLASS: Result := 'LF_IVBCLASS';
    LF_FRIENDFCN_ST: Result := 'LF_FRIENDFCN_ST';
    LF_INDEX: Result := 'LF_INDEX';
    LF_MEMBER_ST: Result := 'LF_MEMBER_ST';
    LF_STMEMBER_ST: Result := 'LF_STMEMBER_ST';
    LF_METHOD_ST: Result := 'LF_METHOD_ST';
    LF_NESTTYPE_ST: Result := 'LF_NESTTYPE_ST';
    LF_VFUNCTAB: Result := 'LF_VFUNCTAB';
    LF_FRIENDCLS: Result := 'LF_FRIENDCLS';
    LF_ONEMETHOD_ST: Result := 'LF_ONEMETHOD_ST';
    LF_VFUNCOFF: Result := 'LF_VFUNCOFF';
    LF_NESTTYPEEX_ST: Result := 'LF_NESTTYPEEX_ST';
    LF_MEMBERMODIFY_ST: Result := 'LF_MEMBERMODIFY_ST';
    LF_MANAGED_ST: Result := 'LF_MANAGED_ST';
    LF_ST_MAX: Result := 'LF_ST_MAX';
    LF_TYPESERVER: Result := 'LF_TYPESERVER';
    LF_ENUMERATE: Result := 'LF_ENUMERATE';
    LF_ARRAY: Result := 'LF_ARRAY';
    LF_CLASS: Result := 'LF_CLASS';
    LF_STRUCTURE: Result := 'LF_STRUCTURE';
    LF_UNION: Result := 'LF_UNION';
    LF_ENUM: Result := 'LF_ENUM';
    LF_DIMARRAY: Result := 'LF_DIMARRAY';
    LF_PRECOMP: Result := 'LF_PRECOMP';
    LF_ALIAS: Result := 'LF_ALIAS';
    LF_DEFARG: Result := 'LF_DEFARG';
    LF_FRIENDFCN: Result := 'LF_FRIENDFCN';
    LF_MEMBER: Result := 'LF_MEMBER';
    LF_STMEMBER: Result := 'LF_STMEMBER';
    LF_METHOD: Result := 'LF_METHOD';
    LF_NESTTYPE: Result := 'LF_NESTTYPE';
    LF_ONEMETHOD: Result := 'LF_ONEMETHOD';
    LF_NESTTYPEEX: Result := 'LF_NESTTYPEEX';
    LF_MEMBERMODIFY: Result := 'LF_MEMBERMODIFY';
    LF_MANAGED: Result := 'LF_MANAGED';
    LF_TYPESERVER2: Result := 'LF_TYPESERVER2';
    LF_STRIDED_ARRAY: Result := 'LF_STRIDED_ARRAY';
    LF_HLSL: Result := 'LF_HLSL';
    LF_MODIFIER_EX: Result := 'LF_MODIFIER_EX';
    LF_INTERFACE: Result := 'LF_INTERFACE';
    LF_BINTERFACE: Result := 'LF_BINTERFACE';
    LF_VECTOR: Result := 'LF_VECTOR';
    LF_MATRIX: Result := 'LF_MATRIX';
    LF_VFTABLE: Result := 'LF_VFTABLE';
    LF_TYPE_LAST: Result := 'LF_TYPE_LAST';
    LF_FUNC_ID: Result := 'LF_FUNC_ID';
    LF_MFUNC_ID: Result := 'LF_MFUNC_ID';
    LF_BUILDINFO: Result := 'LF_BUILDINFO';
    LF_SUBSTR_LIST: Result := 'LF_SUBSTR_LIST';
    LF_STRING_ID: Result := 'LF_STRING_ID';
    LF_UDT_SRC_LINE: Result := 'LF_UDT_SRC_LINE';
    LF_UDT_MOD_SRC_LINE: Result := 'LF_UDT_MOD_SRC_LINE';
    LF_ID_LAST: Result := 'LF_ID_LAST';
    LF_CHAR: Result := 'LF_CHAR';
    LF_SHORT: Result := 'LF_SHORT';
    LF_USHORT: Result := 'LF_USHORT';
    LF_LONG: Result := 'LF_LONG';
    LF_ULONG: Result := 'LF_ULONG';
    LF_REAL32: Result := 'LF_REAL32';
    LF_REAL64: Result := 'LF_REAL64';
    LF_REAL80: Result := 'LF_REAL80';
    LF_REAL128: Result := 'LF_REAL128';
    LF_QUADWORD: Result := 'LF_QUADWORD';
    LF_UQUADWORD: Result := 'LF_UQUADWORD';
    LF_REAL48: Result := 'LF_REAL48';
    LF_COMPLEX32: Result := 'LF_COMPLEX32';
    LF_COMPLEX64: Result := 'LF_COMPLEX64';
    LF_COMPLEX80: Result := 'LF_COMPLEX80';
    LF_COMPLEX128: Result := 'LF_COMPLEX128';
    LF_VARSTRING: Result := 'LF_VARSTRING';
    LF_OCTWORD: Result := 'LF_OCTWORD';
    LF_UOCTWORD: Result := 'LF_UOCTWORD';
    LF_DECIMAL: Result := 'LF_DECIMAL';
    LF_DATE: Result := 'LF_DATE';
    LF_UTF8STRING: Result := 'LF_UTF8STRING';
    LF_REAL16: Result := 'LF_REAL16';
  else
    Assert(False);
  end;
end;

function TypeToName(intype: CV_typ_t): string;
begin
  case intype of
    T_NOTYPE: Result := 'T_NOTYPE';
    T_ABS: Result := 'T_ABS';
    T_SEGMENT: Result := 'T_SEGMENT';
    T_VOID: Result := 'T_VOID';
    T_HRESULT: Result := 'T_HRESULT';
    T_32PHRESULT: Result := 'T_32PHRESULT';
    T_64PHRESULT: Result := 'T_64PHRESULT';
    T_PVOID: Result := 'T_PVOID';
    T_PFVOID: Result := 'T_PFVOID';
    T_PHVOID: Result := 'T_PHVOID';
    T_32PVOID: Result := 'T_32PVOID';
    T_32PFVOID: Result := 'T_32PFVOID';
    T_64PVOID: Result := 'T_64PVOID';
    T_CURRENCY: Result := 'T_CURRENCY';
    T_NBASICSTR: Result := 'T_NBASICSTR';
    T_FBASICSTR: Result := 'T_FBASICSTR';
    T_NOTTRANS: Result := 'T_NOTTRANS';
    T_BIT: Result := 'T_BIT';
    T_PASCHAR: Result := 'T_PASCHAR';
    T_BOOL32FF: Result := 'T_BOOL32FF';
    T_CHAR: Result := 'T_CHAR';
    T_PCHAR: Result := 'T_PCHAR';
    T_PFCHAR: Result := 'T_PFCHAR';
    T_PHCHAR: Result := 'T_PHCHAR';
    T_32PCHAR: Result := 'T_32PCHAR';
    T_32PFCHAR: Result := 'T_32PFCHAR';
    T_64PCHAR: Result := 'T_64PCHAR';
    T_UCHAR: Result := 'T_UCHAR';
    T_PUCHAR: Result := 'T_PUCHAR';
    T_PFUCHAR: Result := 'T_PFUCHAR';
    T_PHUCHAR: Result := 'T_PHUCHAR';
    T_32PUCHAR: Result := 'T_32PUCHAR';
    T_32PFUCHAR: Result := 'T_32PFUCHAR';
    T_64PUCHAR: Result := 'T_64PUCHAR';
    T_RCHAR: Result := 'T_RCHAR';
    T_PRCHAR: Result := 'T_PRCHAR';
    T_PFRCHAR: Result := 'T_PFRCHAR';
    T_PHRCHAR: Result := 'T_PHRCHAR';
    T_32PRCHAR: Result := 'T_32PRCHAR';
    T_32PFRCHAR: Result := 'T_32PFRCHAR';
    T_64PRCHAR: Result := 'T_64PRCHAR';
    T_WCHAR: Result := 'T_WCHAR';
    T_PWCHAR: Result := 'T_PWCHAR';
    T_PFWCHAR: Result := 'T_PFWCHAR';
    T_PHWCHAR: Result := 'T_PHWCHAR';
    T_32PWCHAR: Result := 'T_32PWCHAR';
    T_32PFWCHAR: Result := 'T_32PFWCHAR';
    T_64PWCHAR: Result := 'T_64PWCHAR';
    T_CHAR16: Result := 'T_CHAR16';
    T_PCHAR16: Result := 'T_PCHAR16';
    T_PFCHAR16: Result := 'T_PFCHAR16';
    T_PHCHAR16: Result := 'T_PHCHAR16';
    T_32PCHAR16: Result := 'T_32PCHAR16';
    T_32PFCHAR16: Result := 'T_32PFCHAR16';
    T_64PCHAR16: Result := 'T_64PCHAR16';
    T_CHAR32: Result := 'T_CHAR32';
    T_PCHAR32: Result := 'T_PCHAR32';
    T_PFCHAR32: Result := 'T_PFCHAR32';
    T_PHCHAR32: Result := 'T_PHCHAR32';
    T_32PCHAR32: Result := 'T_32PCHAR32';
    T_32PFCHAR32: Result := 'T_32PFCHAR32';
    T_64PCHAR32: Result := 'T_64PCHAR32';
    T_INT1: Result := 'T_INT1';
    T_PINT1: Result := 'T_PINT1';
    T_PFINT1: Result := 'T_PFINT1';
    T_PHINT1: Result := 'T_PHINT1';
    T_32PINT1: Result := 'T_32PINT1';
    T_32PFINT1: Result := 'T_32PFINT1';
    T_64PINT1: Result := 'T_64PINT1';
    T_UINT1: Result := 'T_UINT1';
    T_PUINT1: Result := 'T_PUINT1';
    T_PFUINT1: Result := 'T_PFUINT1';
    T_PHUINT1: Result := 'T_PHUINT1';
    T_32PUINT1: Result := 'T_32PUINT1';
    T_32PFUINT1: Result := 'T_32PFUINT1';
    T_64PUINT1: Result := 'T_64PUINT1';
    T_SHORT: Result := 'T_SHORT';
    T_PSHORT: Result := 'T_PSHORT';
    T_PFSHORT: Result := 'T_PFSHORT';
    T_PHSHORT: Result := 'T_PHSHORT';
    T_32PSHORT: Result := 'T_32PSHORT';
    T_32PFSHORT: Result := 'T_32PFSHORT';
    T_64PSHORT: Result := 'T_64PSHORT';
    T_USHORT: Result := 'T_USHORT';
    T_PUSHORT: Result := 'T_PUSHORT';
    T_PFUSHORT: Result := 'T_PFUSHORT';
    T_PHUSHORT: Result := 'T_PHUSHORT';
    T_32PUSHORT: Result := 'T_32PUSHORT';
    T_32PFUSHORT: Result := 'T_32PFUSHORT';
    T_64PUSHORT: Result := 'T_64PUSHORT';
    T_INT2: Result := 'T_INT2';
    T_PINT2: Result := 'T_PINT2';
    T_PFINT2: Result := 'T_PFINT2';
    T_PHINT2: Result := 'T_PHINT2';
    T_32PINT2: Result := 'T_32PINT2';
    T_32PFINT2: Result := 'T_32PFINT2';
    T_64PINT2: Result := 'T_64PINT2';
    T_UINT2: Result := 'T_UINT2';
    T_PUINT2: Result := 'T_PUINT2';
    T_PFUINT2: Result := 'T_PFUINT2';
    T_PHUINT2: Result := 'T_PHUINT2';
    T_32PUINT2: Result := 'T_32PUINT2';
    T_32PFUINT2: Result := 'T_32PFUINT2';
    T_64PUINT2: Result := 'T_64PUINT2';
    T_LONG: Result := 'T_LONG';
    T_ULONG: Result := 'T_ULONG';
    T_PLONG: Result := 'T_PLONG';
    T_PULONG: Result := 'T_PULONG';
    T_PFLONG: Result := 'T_PFLONG';
    T_PFULONG: Result := 'T_PFULONG';
    T_PHLONG: Result := 'T_PHLONG';
    T_PHULONG: Result := 'T_PHULONG';
    T_32PLONG: Result := 'T_32PLONG';
    T_32PULONG: Result := 'T_32PULONG';
    T_32PFLONG: Result := 'T_32PFLONG';
    T_32PFULONG: Result := 'T_32PFULONG';
    T_64PLONG: Result := 'T_64PLONG';
    T_64PULONG: Result := 'T_64PULONG';
    T_INT4: Result := 'T_INT4';
    T_PINT4: Result := 'T_PINT4';
    T_PFINT4: Result := 'T_PFINT4';
    T_PHINT4: Result := 'T_PHINT4';
    T_32PINT4: Result := 'T_32PINT4';
    T_32PFINT4: Result := 'T_32PFINT4';
    T_64PINT4: Result := 'T_64PINT4';
    T_UINT4: Result := 'T_UINT4';
    T_PUINT4: Result := 'T_PUINT4';
    T_PFUINT4: Result := 'T_PFUINT4';
    T_PHUINT4: Result := 'T_PHUINT4';
    T_32PUINT4: Result := 'T_32PUINT4';
    T_32PFUINT4: Result := 'T_32PFUINT4';
    T_64PUINT4: Result := 'T_64PUINT4';
    T_QUAD: Result := 'T_QUAD';
    T_PQUAD: Result := 'T_PQUAD';
    T_PFQUAD: Result := 'T_PFQUAD';
    T_PHQUAD: Result := 'T_PHQUAD';
    T_32PQUAD: Result := 'T_32PQUAD';
    T_32PFQUAD: Result := 'T_32PFQUAD';
    T_64PQUAD: Result := 'T_64PQUAD';
    T_UQUAD: Result := 'T_UQUAD';
    T_PUQUAD: Result := 'T_PUQUAD';
    T_PFUQUAD: Result := 'T_PFUQUAD';
    T_PHUQUAD: Result := 'T_PHUQUAD';
    T_32PUQUAD: Result := 'T_32PUQUAD';
    T_32PFUQUAD: Result := 'T_32PFUQUAD';
    T_64PUQUAD: Result := 'T_64PUQUAD';
    T_INT8: Result := 'T_INT8';
    T_PINT8: Result := 'T_PINT8';
    T_PFINT8: Result := 'T_PFINT8';
    T_PHINT8: Result := 'T_PHINT8';
    T_32PINT8: Result := 'T_32PINT8';
    T_32PFINT8: Result := 'T_32PFINT8';
    T_64PINT8: Result := 'T_64PINT8';
    T_UINT8: Result := 'T_UINT8';
    T_PUINT8: Result := 'T_PUINT8';
    T_PFUINT8: Result := 'T_PFUINT8';
    T_PHUINT8: Result := 'T_PHUINT8';
    T_32PUINT8: Result := 'T_32PUINT8';
    T_32PFUINT8: Result := 'T_32PFUINT8';
    T_64PUINT8: Result := 'T_64PUINT8';
    T_OCT: Result := 'T_OCT';
    T_POCT: Result := 'T_POCT';
    T_PFOCT: Result := 'T_PFOCT';
    T_PHOCT: Result := 'T_PHOCT';
    T_32POCT: Result := 'T_32POCT';
    T_32PFOCT: Result := 'T_32PFOCT';
    T_64POCT: Result := 'T_64POCT';
    T_UOCT: Result := 'T_UOCT';
    T_PUOCT: Result := 'T_PUOCT';
    T_PFUOCT: Result := 'T_PFUOCT';
    T_PHUOCT: Result := 'T_PHUOCT';
    T_32PUOCT: Result := 'T_32PUOCT';
    T_32PFUOCT: Result := 'T_32PFUOCT';
    T_64PUOCT: Result := 'T_64PUOCT';
    T_INT16: Result := 'T_INT16';
    T_PINT16: Result := 'T_PINT16';
    T_PFINT16: Result := 'T_PFINT16';
    T_PHINT16: Result := 'T_PHINT16';
    T_32PINT16: Result := 'T_32PINT16';
    T_32PFINT16: Result := 'T_32PFINT16';
    T_64PINT16: Result := 'T_64PINT16';
    T_UINT16: Result := 'T_UINT16';
    T_PUINT16: Result := 'T_PUINT16';
    T_PFUINT16: Result := 'T_PFUINT16';
    T_PHUINT16: Result := 'T_PHUINT16';
    T_32PUINT16: Result := 'T_32PUINT16';
    T_32PFUINT16: Result := 'T_32PFUINT16';
    T_64PUINT16: Result := 'T_64PUINT16';
    T_REAL16: Result := 'T_REAL16';
    T_PREAL16: Result := 'T_PREAL16';
    T_PFREAL16: Result := 'T_PFREAL16';
    T_PHREAL16: Result := 'T_PHREAL16';
    T_32PREAL16: Result := 'T_32PREAL16';
    T_32PFREAL16: Result := 'T_32PFREAL16';
    T_64PREAL16: Result := 'T_64PREAL16';
    T_REAL32: Result := 'T_REAL32';
    T_PREAL32: Result := 'T_PREAL32';
    T_PFREAL32: Result := 'T_PFREAL32';
    T_PHREAL32: Result := 'T_PHREAL32';
    T_32PREAL32: Result := 'T_32PREAL32';
    T_32PFREAL32: Result := 'T_32PFREAL32';
    T_64PREAL32: Result := 'T_64PREAL32';
    T_REAL32PP: Result := 'T_REAL32PP';
    T_PREAL32PP: Result := 'T_PREAL32PP';
    T_PFREAL32PP: Result := 'T_PFREAL32PP';
    T_PHREAL32PP: Result := 'T_PHREAL32PP';
    T_32PREAL32PP: Result := 'T_32PREAL32PP';
    T_32PFREAL32PP: Result := 'T_32PFREAL32PP';
    T_64PREAL32PP: Result := 'T_64PREAL32PP';
    T_REAL48: Result := 'T_REAL48';
    T_PREAL48: Result := 'T_PREAL48';
    T_PFREAL48: Result := 'T_PFREAL48';
    T_PHREAL48: Result := 'T_PHREAL48';
    T_32PREAL48: Result := 'T_32PREAL48';
    T_32PFREAL48: Result := 'T_32PFREAL48';
    T_64PREAL48: Result := 'T_64PREAL48';
    T_REAL64: Result := 'T_REAL64';
    T_PREAL64: Result := 'T_PREAL64';
    T_PFREAL64: Result := 'T_PFREAL64';
    T_PHREAL64: Result := 'T_PHREAL64';
    T_32PREAL64: Result := 'T_32PREAL64';
    T_32PFREAL64: Result := 'T_32PFREAL64';
    T_64PREAL64: Result := 'T_64PREAL64';
    T_REAL80: Result := 'T_REAL80';
    T_PREAL80: Result := 'T_PREAL80';
    T_PFREAL80: Result := 'T_PFREAL80';
    T_PHREAL80: Result := 'T_PHREAL80';
    T_32PREAL80: Result := 'T_32PREAL80';
    T_32PFREAL80: Result := 'T_32PFREAL80';
    T_64PREAL80: Result := 'T_64PREAL80';
    T_REAL128: Result := 'T_REAL128';
    T_PREAL128: Result := 'T_PREAL128';
    T_PFREAL128: Result := 'T_PFREAL128';
    T_PHREAL128: Result := 'T_PHREAL128';
    T_32PREAL128: Result := 'T_32PREAL128';
    T_32PFREAL128: Result := 'T_32PFREAL128';
    T_64PREAL128: Result := 'T_64PREAL128';
    T_CPLX32: Result := 'T_CPLX32';
    T_PCPLX32: Result := 'T_PCPLX32';
    T_PFCPLX32: Result := 'T_PFCPLX32';
    T_PHCPLX32: Result := 'T_PHCPLX32';
    T_32PCPLX32: Result := 'T_32PCPLX32';
    T_32PFCPLX32: Result := 'T_32PFCPLX32';
    T_64PCPLX32: Result := 'T_64PCPLX32';
    T_CPLX64: Result := 'T_CPLX64';
    T_PCPLX64: Result := 'T_PCPLX64';
    T_PFCPLX64: Result := 'T_PFCPLX64';
    T_PHCPLX64: Result := 'T_PHCPLX64';
    T_32PCPLX64: Result := 'T_32PCPLX64';
    T_32PFCPLX64: Result := 'T_32PFCPLX64';
    T_64PCPLX64: Result := 'T_64PCPLX64';
    T_CPLX80: Result := 'T_CPLX80';
    T_PCPLX80: Result := 'T_PCPLX80';
    T_PFCPLX80: Result := 'T_PFCPLX80';
    T_PHCPLX80: Result := 'T_PHCPLX80';
    T_32PCPLX80: Result := 'T_32PCPLX80';
    T_32PFCPLX80: Result := 'T_32PFCPLX80';
    T_64PCPLX80: Result := 'T_64PCPLX80';
    T_CPLX128: Result := 'T_CPLX128';
    T_PCPLX128: Result := 'T_PCPLX128';
    T_PFCPLX128: Result := 'T_PFCPLX128';
    T_PHCPLX128: Result := 'T_PHCPLX128';
    T_32PCPLX128: Result := 'T_32PCPLX128';
    T_32PFCPLX128: Result := 'T_32PFCPLX128';
    T_64PCPLX128: Result := 'T_64PCPLX128';
    T_BOOL08: Result := 'T_BOOL08';
    T_PBOOL08: Result := 'T_PBOOL08';
    T_PFBOOL08: Result := 'T_PFBOOL08';
    T_PHBOOL08: Result := 'T_PHBOOL08';
    T_32PBOOL08: Result := 'T_32PBOOL08';
    T_32PFBOOL08: Result := 'T_32PFBOOL08';
    T_64PBOOL08: Result := 'T_64PBOOL08';
    T_BOOL16: Result := 'T_BOOL16';
    T_PBOOL16: Result := 'T_PBOOL16';
    T_PFBOOL16: Result := 'T_PFBOOL16';
    T_PHBOOL16: Result := 'T_PHBOOL16';
    T_32PBOOL16: Result := 'T_32PBOOL16';
    T_32PFBOOL16: Result := 'T_32PFBOOL16';
    T_64PBOOL16: Result := 'T_64PBOOL16';
    T_BOOL32: Result := 'T_BOOL32';
    T_PBOOL32: Result := 'T_PBOOL32';
    T_PFBOOL32: Result := 'T_PFBOOL32';
    T_PHBOOL32: Result := 'T_PHBOOL32';
    T_32PBOOL32: Result := 'T_32PBOOL32';
    T_32PFBOOL32: Result := 'T_32PFBOOL32';
    T_64PBOOL32: Result := 'T_64PBOOL32';
    T_BOOL64: Result := 'T_BOOL64';
    T_PBOOL64: Result := 'T_PBOOL64';
    T_PFBOOL64: Result := 'T_PFBOOL64';
    T_PHBOOL64: Result := 'T_PHBOOL64';
    T_32PBOOL64: Result := 'T_32PBOOL64';
    T_32PFBOOL64: Result := 'T_32PFBOOL64';
    T_64PBOOL64: Result := 'T_64PBOOL64';
    T_NCVPTR: Result := 'T_NCVPTR';
    T_FCVPTR: Result := 'T_FCVPTR';
    T_HCVPTR: Result := 'T_HCVPTR';
    T_32NCVPTR: Result := 'T_32NCVPTR';
    T_32FCVPTR: Result := 'T_32FCVPTR';
    T_64NCVPTR: Result := 'T_64NCVPTR';
  else
    Assert(False);
  end;
end;

function TypeToString(intype: CV_typ_t): string; inline;
begin
  if intype < $1000 then
    Result := Format('%s(%.4x)', [TypeToName(intype), intype])
  else
    Result := Format('0x%.8x', [intype]);
end;

function CV_CALL_String(incall: UInt8): string; inline;
begin
  case incall of
    CV_CALL_NEAR_C: Result := 'C Near';
    CV_CALL_NEAR_PASCAL: Result := 'Pascal Near';
    CV_CALL_NEAR_FAST: Result := 'Fast Near';
    CV_CALL_NEAR_STD: Result := 'STD Near';
    CV_CALL_NEAR_SYS: Result := 'SYS Near';
    CV_CALL_THISCALL: Result := 'ThisCall';
    CV_CALL_GENERIC: Result := 'Generic';
    CV_CALL_CLRCALL: Result := 'ClrCall';
    CV_CALL_INLINE: Result := 'Inline';
    CV_CALL_NEAR_VECTOR: Result := 'Vector Near';
  else
    Assert(False);
  end;
end;

function CV_ACCESS_String(access: UInt32): string; inline;
begin
  case access of
    CV_private: Result := 'private';
    CV_protected: Result := 'protected';
    CV_public: Result := 'public';
  else
    Assert(False);
  end;
end;

function CV_METHOD_TYPE_String(mprop: UInt32): string; inline;
begin
  case mprop of
    CV_MTvanilla: Result := 'VANILLA';
    CV_MTvirtual: Result := 'VIRTUAL';
    CV_MTstatic: Result := 'STATIC';
    CV_MTfriend: Result := 'FRIEND';
    CV_MTintro: Result := 'INTRODUCING VIRTUAL';
    CV_MTpurevirt: Result := 'PURE VIRTUAL';
    CV_MTpureintro: Result := 'PURE INTRODUCING VIRTUAL';
  else
    Assert(False);
  end;
end;

function DumpLeafInFieldList(pLeaf: PlfEasy): string;
var
  TempStr: string;
  TempValue: Int64;
  TempPtr: Pointer;
begin
  case pLeaf.leaf of
    LF_BCLASS: begin
      with PlfBClass(pLeaf)^ do begin
        TempStr := '';
        if attr.noinherit > 0 then TempStr := ', (noinherit)';
        if attr.noconstruct > 0 then TempStr := ', (noconstruct)';
        Assert(attr.access in [CV_private..CV_public]);
        LeafSignedValue(@offset[0], TempValue);
        Result := Format('%s, %s%s, type = 0x%.8x, offset = %d', [LeafToName(leaf),
          CV_ACCESS_String(attr.access), TempStr, index, TempValue]);
      end;
    end;
    LF_ENUMERATE: begin
      with PlfEnumerate(pLeaf)^ do begin
        Assert(attr.access in [CV_private..CV_public]);
        TempPtr := LeafSignedValue(@value[0], TempValue);
        Result := Format('%s, %s, value = %d, name = ''%s''', [LeafToName(leaf),
          CV_ACCESS_String(attr.access), TempValue, PAnsiChar(TempPtr)]);
      end;
    end;
    LF_MEMBER: begin
      with PlfMember(pLeaf)^ do begin
        Assert(attr.access in [CV_private..CV_public]);
        TempPtr := LeafSignedValue(@offset[0], TempValue);
        Result := Format('%s, %s, type = %s, offset = %d', [LeafToName(leaf),
          CV_ACCESS_String(attr.access), TypeToString(index), TempValue]);
        Result := Format('%s'#$0D#$0A'    member name = ''%s''', [Result, PAnsiChar(TempPtr)]);
      end;
    end;
    LF_STMEMBER: begin
      with PlfSTMember(pLeaf)^ do begin
        Assert(attr.access in [CV_private..CV_public]);
        Result := Format('%s, %s, type = %s, member name = ''%s''', [LeafToName(leaf),
          CV_ACCESS_String(attr.access), TypeToString(index), PAnsiChar(@Name[0])]);
      end;
    end;
    LF_METHOD: begin
      with PlfMethod(pLeaf)^ do begin
        Result := Format('%s, count = %d, list = 0x%.8x, name = ''%s''', [LeafToName(leaf),
          count, mList, PAnsiChar(@Name[0])]);
      end;
    end;
    LF_VFUNCTAB: begin
      with PlfVFuncTab(pLeaf)^ do begin
        Result := Format('%s, type = 0x%.8x', [LeafToName(leaf), &type]);
      end;
    end;
  else
    Assert(False); // Shouldn't reach here
  end;
end;

type
  TCommaOption = (coNone, coPrepend, coAppend);

function PropertyAttributesToString(const prop: CV_prop_t; CommaOption: TCommaOption): string;
begin
  Result := '';
  if prop.&packed > 0 then Result := Result + 'PACKED, ';
  if prop.ctor > 0 then Result := Result + 'CONSTRUCTOR, ';
  if prop.ovlops > 0 then Result := Result + 'OVERLOAD, ';
  if prop.isnested > 0 then Result := Result + 'IS NESTED, ';
  if prop.cnested > 0 then Result := Result + 'CONTAINS NESTED, ';
  if prop.opassign > 0 then Result := Result + 'OVERLOADED ASSIGNMENT, ';
  if prop.opcast > 0 then Result := Result + 'OVERLOADED CASTING, ';
  if prop.fwdref > 0 then Result := Result + 'FORWARD REF, ';
  if prop.scoped > 0 then Result := Result + 'SCOPED, ';
  if prop.sealed > 0 then Result := Result + 'SEALED, ';
  case prop.hfa of
    CV_HFA_float: Result := Result + 'HFA FLOAT, ';
    CV_HFA_double: Result := Result + 'HFA DOUBLE, ';
    CV_HFA_other: Result := Result + 'HFA OTHER, ';
  end;
  if prop.intrinsic > 0 then Result := Result + 'INTRINSIC, ';
  case prop.mocom of
    CV_MOCOM_UDT_ref: Result := Result + 'MOCOM REF, ';
    CV_MOCOM_UDT_value: Result := Result + 'MOCOM VALUE, ';
    CV_MOCOM_UDT_interface: Result := Result + 'MOCOM INTERFACE, ';
  end;
  if (Result <> '') then
    case CommaOption of
      coNone: Result := Copy(Result, 1, Length(Result) - 2);
      coPrepend: Result := ', ' + Copy(Result, 1, Length(Result) - 2);
    end;
end;

function DumpType(idx: CV_typ_t; pType: PTYPTYPE): string;
const
  VTSHAPE_ENTRIES: array[CV_VTS_near..CV_VTS_unused] of string = (
    'NEAR', 'FAR', 'THIN', 'OUTER', 'META', 'NEAR32','FAR32', 'UNUSED');
  PTR_TYPES: array[CV_PTR_NEAR..CV_PTR_UNUSEDPTR] of string = (
    'NEAR', 'FAR', 'HUGE', 'BASE_SEG', 'BASE_VAL', 'BASE_SEGVAL', 'BASE_ADDR', 'BASE_SEGADDR',
    'BASE_TYPE', 'BASE_SELF', 'NEAR32', 'FAR32', '64', 'UNUSEDPTR');
  PTR_MODES: array[CV_PTR_MODE_PTR..CV_PTR_MODE_RESERVED] of string = (
    'Pointer', 'L-value Reference', 'Pointer to member', 'Pointer to member function',
    'R-value Reference', 'Reserved');
  PTR_PMTYPES: array[CV_PMTYPE_Undef..CV_PMTYPE_F_General] of string = (
    'Undefined', 'Data, Single inheritance', 'Data, Multiple inheritance',
    'Data, Virtual inheritance', 'Data, General', 'Function, Single inheritance',
    'Function, Multiple inheritance', 'Function, Virtual inheritance', 'Function, General');
var
  I: UInt16;
  TempStr: string;
  Field, FieldEnd: PlfEasy;
  Method, MethodEnd: PmlMethod;
  Value, Value2: Int64;
  TempPtr: Pointer;
  Mask,
  Shift: UInt8;
begin
{$POINTERMATH ON}
  Result := Format('0x%.8x : Length = %d, Leaf = 0x%.4x %s', [idx, pType.len, pType.leaf,
    LeafToName(pType.leaf)]);
  case pType.leaf of
    LF_VTSHAPE: begin
      with PlfVTShape(@pType.leaf)^ do begin
        Result := Format('%s'#$0D#$0A'  Number of entries : %d', [Result, count]);
        if count > 0 then
          for I := 0 to count - 1 do begin
            Shift := (I and 1) shl 2;
            Mask := $F shl Shift;
            Result := Format('%s'#$0D#$0A'    [%d]: %s', [Result, I,
              VTSHAPE_ENTRIES[(desc[I shr 1] and Mask) shr Shift]]);
          end;
      end;
    end;
    LF_POINTER: begin
      with PlfPointer(@pType.leaf)^ do begin
        Assert(attr.ptrtype in [CV_PTR_NEAR32..CV_PTR_64]);
        Assert(attr.ptrmode < CV_PTR_MODE_RESERVED);
        Result := Format('%s'#$0D#$0A'  %s (%s), Size: %d', [Result, PTR_MODES[attr.ptrmode],
          PTR_TYPES[attr.ptrtype], attr.size]);
        Result := Format('%s'#$0D#$0A'  Element type : %s', [Result, TypeToString(utype)]);
        if attr.ptrmode in [CV_PTR_MODE_PMEM..CV_PTR_MODE_PMFUNC] then begin
          Assert(pmenum <= CV_PMTYPE_F_General);
          Result := Format('%s, Containing class = 0x%.8x', [Result, pmclass]);
          Result := Format('%s'#$0D#$0A'  Type of pointer to member = %s', [Result,
            PTR_PMTYPES[pmenum]]);
        end;
      end;
    end;
    LF_PROCEDURE: begin
      with PlfProc(@pType.leaf)^ do begin
        Result := Format('%s'#$0D#$0A'  Return type = %s, Call type = %s', [Result,
          TypeToString(rvtype), CV_CALL_String(calltype)]);
        TempStr := 'none';
        if funcattr.cxxreturnudt > 0 then TempStr := 'return UDT (C++ style';
        if funcattr.ctor > 0 then TempStr := 'instance constructor';
        if funcattr.ctorvbase > 0 then TempStr := 'instance constructor of a class with virtual base';
        Result := Format('%s'#$0D#$0A'  Func attr = %s', [Result, TempStr]);
        Result := Format('%s'#$0D#$0A'  # Parms = %d, Arg list type = 0x%.8x', [Result, parmcount,
          arglist]);
      end;
    end;
    LF_MFUNCTION: begin
      with PlfMFunc(@pType.leaf)^ do begin
        Result := Format('%s'#$0D#$0A'  Return type = %s, Class type = 0x%.8x, This type = 0x%.8x',
          [Result, TypeToString(rvtype), classtype, thistype]);
        TempStr := 'none';
        if funcattr.cxxreturnudt > 0 then TempStr := 'return UDT (C++ style';
        if funcattr.ctor > 0 then TempStr := 'instance constructor';
        if funcattr.ctorvbase > 0 then TempStr := 'instance constructor of a class with virtual base';
        Result := Format('%s'#$0D#$0A'  Call type = %s, Func attr = ', [Result,
          CV_CALL_String(calltype), TempStr]);
        Result := Format('%s'#$0D#$0A'  # Parms = %d, Arg list type = 0x%.8x, This adjust = %d',
          [Result, parmcount, arglist, thisadjust]);
      end;
    end;
    LF_ARGLIST: begin
      with PlfArgList(@pType.leaf)^ do begin
        Result := Format('%s argument count = %d', [Result, count]);
        if count > 0 then
          for I := 0 to count - 1 do
            Result := Format('%s'#$0D#$0A'  list[%d] = %s', [Result, I, TypeToString(arg[I])]);
      end;
    end;
    LF_FIELDLIST: begin
      FieldEnd := PlfEasy(PUInt8(pType) + SizeOf(pType.len) + pType.len);
      with PlfFieldList(@pType.leaf)^ do begin
        Field := @data[0];
        I := 0;
        while NativeUInt(Field) < NativeUInt(FieldEnd) do begin
          Result := Format('%s'#$0D#$0A'  list[%d] = %s', [Result, I, DumpLeafInFieldList(Field)]);
          Inc(I);
          Field := NextField(Field);
        end;
      end;
    end;
    LF_METHODLIST: begin
      MethodEnd := PmlMethod(PUInt8(pType) + SizeOf(pType.len) + pType.len);
      with PlfMethodList(@pType.leaf)^ do begin
        I := 0;
        Method := @mList[0];
        while NativeUInt(Method) < NativeUInt(MethodEnd) do with PmlMethod(Method)^ do begin
          TempStr := '';
          if attr.pseudo > 0 then TempStr := ', (pseudo)';
          if attr.compgenx > 0 then TempStr := ', (compgenx)';
          if attr.sealed > 0 then TempStr := ', (sealed)';
          Result := Format('%s'#$0D#$0A'  list[%d] = %s, %s%s, 0x%.8x', [Result, I,
            CV_ACCESS_String(attr.access), CV_METHOD_TYPE_String(attr.mprop), TempStr, index]);
          if attr.mprop in [CV_MTintro, CV_MTpureintro] then
            Result := Format('%s'#$0D#$0A'    vfptr offset = %d', [Result, vbaseoff]);
          Inc(I);
          Method := NextMethod(Method);
        end;
      end;
    end;
    LF_DIMCONLU: begin
      with PlfDimCon(@pType.leaf)^ do begin
        Result := Format('%s'#$0D#$0A'  index type = %s, rank = %d', [Result, TypeToString(typ),
          rank]);
        if rank > 0 then begin
          TempPtr := @dim[0];
          for I := 0 to rank - 1 do begin
            TempPtr := LeafSignedValue(TempPtr, Value);
            TempPtr := LeafSignedValue(TempPtr, Value2);
            Result := Format('%s'#$0D#$0A'    dim[%d]: Low = %d, High = %d', [Result, I, Value,
              Value2]);
          end;
        end;
      end;
    end;
    LF_BITFIELD: begin
      with PlfBitfield(@pType.leaf)^ do begin
        Result := Format('%s'#$0D#$0A'  bits = %d, starting position = %d, Type = %s', [Result,
          length, position, TypeToString(&type)]);
      end;
    end;
    LF_ARRAY: begin
      with PlfArray(@pType.leaf)^ do begin
        Result := Format('%s'#$0D#$0A'  Element type = %s', [Result, TypeToString(elemtype)]);
        Result := Format('%s'#$0D#$0A'  Index type = %s', [Result, TypeToString(idxtype)]);
        TempPtr := LeafSignedValue(@data[0], Value);
        Result := Format('%s'#$0D#$0A'  length = %d', [Result, Value]);
        Result := Format('%s'#$0D#$0A'  Name = %s', [Result, PAnsiChar(TempPtr)]);
      end;
    end;
    LF_CLASS,
    LF_STRUCTURE: begin
      with PlfClass(@pType.leaf)^ do begin
        Result := Format('%s'#$0D#$0A'  # members = %d, field list type 0x%.8x%s', [Result,
          count, field, PropertyAttributesToString(&property, coPrepend)]);
        Result := Format('%s'#$0D#$0A'  Derivation list type 0x%.8x, VT shape type 0x%.8x', [Result,
          derived, vshape]);
        TempPtr := LeafSignedValue(@data[0], Value);
        Result := Format('%s'#$0D#$0A'  Size = %d, class name = %s', [Result, Value,
          PAnsiChar(TempPtr)]);
        if &property.hasuniquename > 0 then begin
          Inc(PAnsiChar(TempPtr), System.AnsiStrings.StrLen(TempPtr) + 1);
          Result := Format('%s, unique name = %s', [Result, Value, PAnsiChar(TempPtr)]);
        end;
      end;
    end;
    LF_UNION: begin
      with PlfUnion(@pType.leaf)^ do begin
        Result := Format('%s'#$0D#$0A'  # members = %d, field list type 0x%.8x%s', [Result,
          count, field, PropertyAttributesToString(&property, coPrepend)]);
        TempPtr := LeafSignedValue(@data[0], Value);
        Result := Format('%s'#$0D#$0A'  Size = %d, class name = %s', [Result, Value,
          PAnsiChar(TempPtr)]);
        if &property.hasuniquename > 0 then begin
          Inc(PAnsiChar(TempPtr), System.AnsiStrings.StrLen(TempPtr) + 1);
          Result := Format('%s, unique name = %s', [Result, Value, PAnsiChar(TempPtr)]);
        end;
      end;
    end;
    LF_ENUM: begin
      with PlfEnum(@pType.leaf)^ do begin
        Result := Format('%s'#$0D#$0A'  # members = %d, type = %s, field list type 0x%.8x', [Result,
          count, TypeToString(utype), field]);
        Result := Format('%s'#$0D#$0A'  %s, enum name = %s', [Result,
          PropertyAttributesToString(&property, coAppend), PAnsiChar(@Name[0])]);
      end;
    end;
    LF_DIMARRAY: begin
      with PlfDimArray(@pType.leaf)^ do begin
        Result := Format('%s'#$0D#$0A'  type = %s, dim info = 0x%.8x, name = %s', [Result,
          TypeToString(utype), diminfo, PAnsiChar(@name[0])]);
      end;
    end;
  else
    Assert(False); // Shouldn't reach here
  end;
{$POINTERMATH OFF}
end;

function PadSymLen(BaseLen: Integer): Integer; inline;
begin
  if (BaseLen and 3) > 0 then
    Result := BaseLen + 4 - (BaseLen and 3)
  else
    Result := BaseLen;
end;

function PadTypLen(BaseLen: Integer): Integer; inline;
begin
  if (BaseLen and 3) > 0 then
    Result := BaseLen + 4 - (BaseLen and 3)
  else
    Result := BaseLen;
end;

end.
