unit PDBInfo;

interface

type
  // from Microsoft PDB sources langapi/include/pdb.h
  TAge = UInt32;
  TSig = UInt32;

  // from Microsoft PDB sources PDB/dbi/locator.h
  PNB10I = ^TNB10I;
  TNB10I = record
    dwSig: UInt32;
    dwOffset: UInt32;
    sig: TSig;
    age: TAge;
    szPdb: array [0..0] of PAnsiChar; // MAX_PATH length at most
  end;

  // from Microsoft PDB sources PDB/dbi/locator.h
  PRSDSI = ^TRSDSI;
  TRSDSI = record
    dwSig: UInt32;
    guidSig: TGUID;
    age: UInt32;
    szPdb: array [0..0] of AnsiChar; // MAX_PATH * 3 length at most
  end;

  PCVDebugInfoInImage = ^TCVDebugInfoInImage;
  TCVDebugInfoInImage = record
    class function Alloc(dwSig: UInt32; szPdb: UTF8String): PCVDebugInfoInImage; static;
    function Size: UInt32;
  case Integer of
    0: (
      dwSig: UInt32;
    );
    1: (
      nb10i: TNB10I;
    );
    2: (
      rsdsi: TRSDSI;
    );
  end;

const
  PDB70 = $53445352; // 'SDSR'
  PDB20 = $3031424e; // '01BN'

implementation

uses
  System.AnsiStrings;

class function TCVDebugInfoInImage.Alloc(dwSig: UInt32; szPdb: UTF8String): PCVDebugInfoInImage;
var
  Size: UInt32;
begin
  case dwSig of
    PDB70: begin
      Size := SizeOf(TRSDSI) - SizeOf(PRSDSI(nil)^.szPdb);
      Inc(Size, Length(szPdb) + 1);
      GetMem(Result, Size);
    end;
    PDB20: begin
      Size := SizeOf(TNB10I) - SizeOf(PNB10I(nil)^.szPdb);
      Inc(Size, Length(szPdb) + 1);
      GetMem(Result, Size);
    end;
  else
    Result := nil;
  end;
end;

function TCVDebugInfoInImage.Size: UInt32;
begin
  case dwSig of
    PDB70: begin
      Result := SizeOf(rsdsi) - SizeOf(rsdsi.szPdb);
      Inc(Result, StrLen(@rsdsi.szPdb[0]));
    end;
    PDB20: begin
      Result := SizeOf(nb10i) - SizeOf(nb10i.szPdb);
      Inc(Result, StrLen(@nb10i.szPdb[0]));
    end;
  else
    Result := 0;
  end;
end;

end.
