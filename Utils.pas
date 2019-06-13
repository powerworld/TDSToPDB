unit Utils;

interface

function FindLowestZeroBit(BitArray: TArray<UInt32>; out ArrIndex: Int32; out BitIndex: Int8): Boolean;

implementation

function FindLowestZeroBit(BitArray: TArray<UInt32>; out ArrIndex: Int32; out BitIndex: Int8): Boolean;
asm
  MOV ECX, Length(BitArray)
  TEST ECX, ECX
  JNZ @StartSearch
  MOV Result, CL
  JZ @Leave
@StartSearch:
  MOV EDX, ECX
  XOR EAX, EAX
  SUB EAX, 1
  REPE SCAS BitArray[0]
  SETNZ Result
  JECXZ @Leave
  SUB EDX, ECX
  MOV ArrIndex, EDX
  BSF ECX, BitArray[EDX]
  MOV BitIndex, ECX
  SETNZ Result
@Leave:
end;

end.
