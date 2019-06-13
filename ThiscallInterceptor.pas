unit ThiscallInterceptor;

interface

uses
  System.Generics.Collections;

type
  TThiscallVirtualInterceptor = class
  private const
    PAIRBLOCKSIZE = 512;
  private type
    TPointerPair = record
      ThunkVtable: Pointer;
      ThisPointer: Pointer;
      procedure Init(AThunk, AThis: Pointer);
    end;
    PPointerPair = ^TPointerPair;
  private class var
    FDelphiCppPairs: TList<PPointerPair>;
    class constructor Create;
    class destructor Destroy;
  private var
    FThunkBlockSize: NativeUInt;
    FThunkBlock: Pointer;
  public
    class procedure RemoveObjThunk(Thunk: Pointer); static;
    constructor Create(ClassType: TClass);
    destructor Destroy; override;
    function AddObjThunk(Obj: Pointer): Pointer;
  end;

implementation

uses
  System.SysUtils, System.Rtti, System.Generics.Defaults, Winapi.Windows;

const
  ThunkCode: array [0..9] of Byte = (
    $58,            // POP EAX              - pop return into EAX
    $59,            // POP ECX              - pop thunkobj self pointer into ECX (where thiscall wants it)
    $8B, $49, $04,  // MOV ECX, [ECX+4]     - get this pointer
    $50,            // PUSH EAX             - push return
    $8B, $01,       // MOV EAX, [ECX]       - get C++ vtable pointer
    $FF, $A0        // JMP [EAX + slotoff]  - index vtable to correct slot and jump
  );

procedure TThiscallVirtualInterceptor.TPointerPair.Init(AThunk, AThis: Pointer);
begin
  ThunkVtable := AThunk;
  ThisPointer := AThis;
end;

class constructor TThiscallVirtualInterceptor.Create;
begin
  FDelphiCppPairs := TList<PPointerPair>.Create;
end;

class destructor TThiscallVirtualInterceptor.Destroy;
var
  I: Integer;
begin
  for I := 0 to FDelphiCppPairs.Count - 1 do begin
    FDelphiCppPairs[I].Init(nil, nil);
    Dispose(FDelphiCppPairs[I]);
  end;
  FDelphiCppPairs.Free;
end;

constructor TThiscallVirtualInterceptor.Create(ClassType: TClass);
var
  Context: TRttiContext;
  InstanceType: TRttiInstanceType;
  VMTCount: Integer;
  NewVMTPtr: PPointer;
  ThunkPtr: PByte;
  I: Integer;
  OldProtect: DWORD;
begin
{$POINTERMATH ON}
  inherited Create;
  Context := TRttiContext.Create;
  InstanceType := Context.GetType(ClassType) as TRttiInstanceType;
  VMTCount := InstanceType.VmtSize div SizeOf(Pointer);

  // Block size is the thunk VMT size + thunk code size
  FThunkBlockSize := VMTCount * (SizeOf(Pointer) + Length(ThunkCode) + SizeOf(Int32));
  FThunkBlock := VirtualAlloc(nil, FThunkBlockSize, MEM_COMMIT, PAGE_READWRITE);
  if FThunkBlock = nil then RaiseLastOSError;
  NewVMTPtr := FThunkBlock;
  ThunkPtr := @PByte(FThunkBlock)[VMTCount * SizeOf(Pointer)]; // thunks are right after new VMT
  for I := 0 to VMTCount-1 do begin
    NewVMTPtr^ := ThunkPtr;
    Move(ThunkCode[0], ThunkPtr^, Length(ThunkCode));
    Inc(ThunkPtr, Length(ThunkCode));
    PInteger(ThunkPtr)^ := I * SizeOf(Pointer);
    Inc(NewVMTPtr);
    Inc(ThunkPtr, SizeOf(Integer));
  end;
  if not VirtualProtect(FThunkBlock, FThunkBlockSize, PAGE_EXECUTE_READ, OldProtect) then
    RaiseLastOSError;
{$POINTERMATH OFF}
end;

destructor TThiscallVirtualInterceptor.Destroy;
var
  OldProtect: DWORD;
begin
  if VirtualProtect(FThunkBlock, FThunkBlockSize, PAGE_READWRITE, OldProtect) then
    FillChar(FThunkBlock^, FThunkBlockSize, 0);
  VirtualFree(FThunkBlock, FThunkBlockSize, MEM_RELEASE);
  FThunkBlock := nil;
  FThunkBlockSize := 0;
  inherited Destroy;
end;

function TThiscallVirtualInterceptor.AddObjThunk(Obj: Pointer): Pointer;
var
  I: Integer;
begin
  PPointerPair(Result) := New(PPointerPair);
  PPointerPair(Result).Init(FThunkBlock, Obj);
  FDelphiCppPairs.BinarySearch(PPointerPair(Result), I);
  FDelphiCppPairs.Insert(I, PPointerPair(Result));
end;

class procedure TThiscallVirtualInterceptor.RemoveObjThunk(Thunk: Pointer);
var
  I: Integer;
begin
  PPointerPair(Thunk).Init(nil, nil);
  FDelphiCppPairs.BinarySearch(PPointerPair(Thunk), I);
  FDelphiCppPairs.Delete(I);
  Dispose(Thunk);
end;

end.
