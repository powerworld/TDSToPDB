unit TDSInfo;

interface

const
  Borland32BitSymbolFileSignatureForDelphi = $39304246; // 'FB09'
  Borland32BitSymbolFileSignatureForBCB    = $41304246; // 'FB0A'

type
  PUInt8 = ^UInt8;
  PUInt16 = ^UInt16;
  PUInt32 = ^UInt32;

  PTDSFileSignature = ^TTDSFileSignature;
  TTDSFileSignature = packed record
    Signature: UInt32;
    Offset: UInt32;
  end;

  { Subsection directory header structure }
  { The directory header structure is followed by the directory entries
    which specify the subsection type, module index, file offset, and size.
    The subsection directory gives the location (LFO) and size of each subsection,
    as well as its type and module number if applicable. }
  PTDS_DirectoryEntry = ^TTDS_DirectoryEntry;
  TTDS_DirectoryEntry = packed record
    subsection: UInt16; // Subdirectory type
    iMod: UInt16;    // Module index
    lfo: UInt32;         // Offset from the base offset lfoBase
    cb: UInt32;           // Number of bytes in subsection
  end;

  { The subsection directory is prefixed with a directory header structure
    indicating size and number of subsection directory entries that follow. }
  PTDS_DirectoryHeader = ^TTDS_DirectoryHeader;
  TTDS_DirectoryHeader = packed record
    cbDirHeader: UInt16;           // Length of this structure
    cbDirEntry: UInt16;   // Length of each directory entry
    cDir: UInt32;  // Number of directory entries
    lfoNextDir: UInt32;     // Offset from lfoBase of next directory.
    flags: UInt32;          // Flags describing directory and subsection tables.
    entries: array [0..0] of TTDS_DirectoryEntry;
  end;

const
  { Subsection Types }
  TDS_SUBSECTION_TYPE_MODULE         = $120;
  TDS_SUBSECTION_TYPE_TYPES          = $121;
  TDS_SUBSECTION_TYPE_SYMBOLS        = $124;
  TDS_SUBSECTION_TYPE_ALIGN_SYMBOLS  = $125;
  TDS_SUBSECTION_TYPE_SOURCE_MODULE  = $127;
  TDS_SUBSECTION_TYPE_GLOBAL_SYMBOLS = $129;
  TDS_SUBSECTION_TYPE_GLOBAL_TYPES   = $12B;
  TDS_SUBSECTION_TYPE_NAMES          = $130;

type
  // Section Headers
  PTDS_SegmentInfo = ^TDS_SegmentInfo;
  TDS_SegmentInfo = packed record
    seg: UInt16;
    flags: UInt16;
    offset: UInt32;
    cbSeg: UInt32;
  end;

  PTDS_ModuleSection = ^TDS_ModuleSection;
  TDS_ModuleSection = packed record
    ovlNumber: UInt16;
    iLib: UInt16;
    cSeg: UInt16;
    style: UInt16;
    name: UInt32;
    timestamp: UInt32;
    reserved: array [0..2] of UInt32;
    seginfo: array [0..0] of TDS_SegmentInfo;
  end;

  PTDS_SymbolSectionHeader = ^TDS_SymbolSectionHeader;
  TDS_SymbolSectionHeader = packed record
    sig: UInt32;
    data: array [0..0] of UInt8;
  end;

  PTDS_SourceModuleSectionOffsetPair = ^TDS_SourceModuleSectionOffsetPair;
  TDS_SourceModuleSectionOffsetPair = packed record
    start,
    &end: UInt32;
  end;

  PTDS_SegmentLineInfo = ^TDS_SegmentLineInfo;
  TDS_SegmentLineInfo = packed record
    seg: UInt16;
    cPair: UInt16;
    data: array [0..0] of UInt8;
    // data contains the following:
    // offset: array [0..cPair - 1] of UInt32;
    // linenumber: array [0..cPair - 1] of UInt16;
    function Getoffset: PUInt32; inline;
    function Getlinenumber: PUInt16; inline;
    property offset: PUInt32 read Getoffset;
    property linenumber: PUInt16 read Getlinenumber;
  end;

  PTDS_SourceFileEntry = ^TDS_SourceFileEntry;
  TDS_SourceFileEntry = packed record
    cSeg: UInt16;
    name: UInt32;
    data: array [0..0] of UInt8;
    // data contains the following:
    // baseSrcLn: array [0..cSeg - 1] of UInt32;
    // startend: array [0..cSeg - 1] of TSourceModuleSectionOffsetPair;
    function GetbaseSrcLn: PUInt32; inline;
    function Getstartend: PTDS_SourceModuleSectionOffsetPair; inline;
    property baseSrcLn: PUInt32 read GetbaseSrcLn;
    property startend: PTDS_SourceModuleSectionOffsetPair read Getstartend;

    function getbaseSrcLnPointer(Base: Pointer; Index: UInt16): PTDS_SegmentLineInfo;
  end;

  PTDS_SourceModuleSectionHeader = ^TDS_SourceModuleSectionHeader;
  TDS_SourceModuleSectionHeader = packed record
    cFile: UInt16;
    cSeg: UInt16;
    data: array [0..0] of UInt8;
    // data contains the following:
    // baseSrcFile: array [0..cFile - 1] of UInt32;
    // startend: array [0..cSeg - 1] of TSourceModuleSectionOffsetPair;
    // seg: array [0..cSeg - 1] of UInt16;
    function GetbaseSrcFile: PUInt32; inline;
    function Getstartend: PTDS_SourceModuleSectionOffsetPair; inline;
    function Getseg: PUInt16; inline;
    property baseSrcFile: PUInt32 read GetbaseSrcFile;
    property startend: PTDS_SourceModuleSectionOffsetPair read Getstartend;
    property seg: PUInt16 read Getseg;

    function GetbaseSrcFilePointer(Index: UInt16): PTDS_SourceFileEntry;
  end;

  PTDS_GlobalSymbolsSectionHeader = ^TDS_GlobalSymbolsSectionHeader;
  TDS_GlobalSymbolsSectionHeader = packed record
    symhash: UInt16;
    addrhash: UInt16;
    cbSymbol: UInt32;
    cbSymHash: UInt32;
    cbAddrHash: UInt32;
    unknown: array [0..3] of UInt32;
    symbols: array [0..0] of UInt8;
  end;

  PTDS_GlobalTypeSectionHeader = ^TDS_GlobalTypeSectionHeader;
  TDS_GlobalTypeSectionHeader = packed record
    sig: UInt32;
    cTypes: UInt32;
    offsets: array [0..0] of UInt32;
  end;

  PTDS_NamesSectionHeader = ^TDS_NamesSectionHeader;
  TDS_NamesSectionHeader = packed record
    cNames: UInt32;
    names: array [0..0] of UInt8; // Strings one after another, all length prefixed
  end;

  TDS_typ_t = UInt32;
  PTDS_typ_t = ^TDS_typ_t;

const
  // Leaf types
  TDS_LF_MODIFIER   = $0001;
  TDS_LF_POINTER    = $0002;
  TDS_LF_ARRAY      = $0003;
  TDS_LF_CLASS      = $0004;
  TDS_LF_STRUCTURE  = $0005;
  TDS_LF_UNION      = $0006;
  TDS_LF_ENUM       = $0007;
  TDS_LF_PROCEDURE  = $0008;
  TDS_LF_MFUNCTION  = $0009;
  TDS_LF_VTSHAPE    = $000A;
  TDS_LF_COBOL0     = $000B;
  TDS_LF_COBOL1     = $000C;
  TDS_LF_BARRAY     = $000D;
  TDS_LF_LABEL      = $000E;
  TDS_LF_NULL       = $000F;
  TDS_LF_NOTTRAN    = $0010;
  TDS_LF_DIMARRAY   = $0011;
  TDS_LF_VFTPATH    = $0012;

  // Delphi-specific leaves
  TDS_LF_DSET       = $0030; // Delphi set type
  TDS_LF_DRANGED    = $0031; // Delphi ranged type
  TDS_LF_DARRAY     = $0032; // Delphi array
  TDS_LF_DSHORTSTR  = $0033; // Delphi short string
  TDS_LF_DMETHODREF = $0034; // Delphi method reference
  TDS_LF_DPROPERTY  = $0035; // Delphi property
  TDS_LF_DANSISTR   = $0036; // Delphi AnsiString type
  TDS_LF_DVARIANT   = $0037; // Delphi Variant type
  TDS_LF_DMETACLASS = $0038; // Delphi metaclass type
  TDS_LF_DWIDESTR   = $0039; // Delphi WideString type
  TDS_LF_DUNISTR    = $003A; // Delphi unicode string type

  // Leaf indices for type records that can be referenced from other type records
  TDS_LF_SKIP       = $0200;
  TDS_LF_ARGLIST    = $0201;
  TDS_LF_DEFARG     = $0202;
  TDS_LF_LIST       = $0203;
  TDS_LF_FIELDLIST  = $0204;
  TDS_LF_DERIVED    = $0205;
  TDS_LF_BITFIELD   = $0206;
  TDS_LF_METHODLIST = $0207;
  TDS_LF_DIMCONU    = $0208;
  TDS_LF_DIMCONLU   = $0209;
  TDS_LF_DIMVARU    = $020A;
  TDS_LF_DIMVARLU   = $020B;
  TDS_LF_REFSYM     = $020C;

  // Leaf indices for fields of complex lists:
  TDS_LF_BCLASS     = $0400;
  TDS_LF_VBCLASS    = $0401;
  TDS_LF_IVBCLASS   = $0402;
  TDS_LF_ENUMERATE  = $0403;
  TDS_LF_FRIENDFCN  = $0404;
  TDS_LF_INDEX      = $0405;
  TDS_LF_MEMBER     = $0406;
  TDS_LF_STMEMBER   = $0407;
  TDS_LF_METHOD     = $0408;
  TDS_LF_NESTTYPE   = $0409;
  TDS_LF_VFUNCTAB   = $040a;
  TDS_LF_FRIENDCLS  = $040b;

  // Leaf indices for numeric fields of symbols and type records:
  TDS_LF_NUMERIC    = $8000;
  TDS_LF_CHAR       = $8000;
  TDS_LF_SHORT      = $8001;
  TDS_LF_USHORT     = $8002;
  TDS_LF_LONG       = $8003;
  TDS_LF_ULONG      = $8004;
  TDS_LF_REAL32     = $8005;
  TDS_LF_REAL64     = $8006;
  TDS_LF_REAL80     = $8007;
  TDS_LF_REAL128    = $8008;
  TDS_LF_QUADWORD   = $8009;
  TDS_LF_UQUADWORD  = $800a;
  TDS_LF_REAL48     = $800b;
  TDS_LF_COMPLEX32  = $800c;
  TDS_LF_COMPLEX64  = $800d;
  TDS_LF_COMPLEX80  = $800e;
  TDS_LF_COMPLEX128 = $800f;
  TDS_LF_VARSTRING  = $8010;

  TDS_LF_PAD0  = $f0;
  TDS_LF_PAD1  = $f1;
  TDS_LF_PAD2  = $f2;
  TDS_LF_PAD3  = $f3;
  TDS_LF_PAD4  = $f4;
  TDS_LF_PAD5  = $f5;
  TDS_LF_PAD6  = $f6;
  TDS_LF_PAD7  = $f7;
  TDS_LF_PAD8  = $f8;
  TDS_LF_PAD9  = $f9;
  TDS_LF_PAD10 = $fa;
  TDS_LF_PAD11 = $fb;
  TDS_LF_PAD12 = $fc;
  TDS_LF_PAD13 = $fd;
  TDS_LF_PAD14 = $fe;
  TDS_LF_PAD15 = $ff;

type
  PTDS_TYPTYPE = ^TDS_TYPTYPE;
  TDS_TYPTYPE = packed record
    len: UInt16;
    leaf: UInt16;
    data: array [0..0] of UInt8;
  end;

  TDS_prop_t = packed record
    _props: UInt16;  // bitfield
                    // :1 - unknown1
                    // :1 - ctor
                    // :6 - unknown2
                    // :1 - dtor
                    // :7 - unknown3
    function Getunknown1: UInt8; inline;
    function Getctor: UInt8; inline;
    function Getunknown2: UInt8; inline;
    function Getdtor: UInt8; inline;
    function Getunknown3: UInt8; inline;
    procedure Setunknown1(Value: UInt8); inline;
    procedure Setctor(Value: UInt8); inline;
    procedure Setunknown2(Value: UInt8); inline;
    procedure Setdtor(Value: UInt8); inline;
    procedure Setunknown3(Value: UInt8); inline;
    property unknown1: UInt8 read Getunknown1 write Setunknown1;
    property ctor: UInt8 read Getctor write Setctor;
    property unknown2: UInt8 read Getunknown2 write Setunknown2;
    property dtor: UInt8 read Getdtor write Setdtor;
    property unknown3: UInt8 read Getunknown3 write Setunknown3;
  end;

  TDS_propattr_t = packed record
    _props: UInt16;  // bitfield
                    // :1 - hasdefault
                    // :1 - hasgetfunc
                    // :1 - hassetfunc
                    // :13 - unknown
    function Gethasdefault: UInt8;
    function Gethasgetfunc: UInt8;
    function Gethassetfunc: UInt8;
    function Getunknown: UInt8;
    procedure Sethasdefault(Value: UInt8);
    procedure Sethasgetfunc(Value: UInt8);
    procedure Sethassetfunc(Value: UInt8);
    procedure Setunknown(Value: UInt8);
    property hasdefault: UInt8 read Gethasdefault write Sethasdefault;
    property hasgetfunc: UInt8 read Gethasgetfunc write Sethasgetfunc;
    property hassetfunc: UInt8 read Gethassetfunc write Sethassetfunc;
    property unknown: UInt8 read Getunknown write Setunknown;
  end;

const
  ATTR_ACC_NONE               = $0000;
  ATTR_ACC_PRIVATE            = $0001;
  ATTR_ACC_PROTECTED          = $0002;
  ATTR_ACC_PUBLIC             = $0003;

  ATTR_MPROP_VANILLA          = $0000;
  ATTR_MPROP_VIRTUAL          = $0001;
  ATTR_MPROP_STATIC           = $0002;
  ATTR_MPROP_FRIEND           = $0003;
  ATTR_MPROP_INTRO_VIRT       = $0004;
  ATTR_MPROP_PURE_VIRT        = $0005;
  ATTR_MPROP_PURE_INTRO_VIRT  = $0006;
  ATTR_MPROP_RESERVED         = $0007;

type
  TDS_fldattr_t = packed record
    _props: UInt16;  // bitfield
                    // :2 - access TDS_access_t
                    // :3 - mprop TDS_methodprop_t
                    // :5 - unknown1
                    // :1 - ctor
                    // :1 - dtor
                    // :4 - unknown2
    function Getaccess: UInt8;
    function Getmprop: UInt8;
    function Getunknown1: UInt8;
    function Getctor: UInt8;
    function Getdtor: UInt8;
    function Getunknown2: UInt8;
    procedure Setaccess(Value: UInt8);
    procedure Setmprop(Value: UInt8);
    procedure Setunknown1(Value: UInt8);
    procedure Setctor(Value: UInt8);
    procedure Setdtor(Value: UInt8);
    procedure Setunknown2(Value: UInt8);
    property access: UInt8 read Getaccess write Setaccess;
    property mprop: UInt8 read Getmprop write Setmprop;
    property unknown1: UInt8 read Getunknown1 write Setunknown1;
    property ctor: UInt8 read Getctor write Setctor;
    property dtor: UInt8 read Getdtor write Setdtor;
    property unknown2: UInt8 read Getunknown2 write Setunknown2;
  end;

function TDS_NextType(pType: PTDS_TYPTYPE): PTDS_TYPTYPE; inline;

type
  PTDS_lfEasy = ^TDS_lfEasy; // Handy for list member casting
  TDS_lfEasy = packed record
    leaf: UInt16;
  end;

const
  TDS_PTR_NEAR         = $00; // 16 bit pointer
  TDS_PTR_FAR          = $01; // 16:16 far pointer
  TDS_PTR_HUGE         = $02; // 16:16 huge pointer
  TDS_PTR_BASE_SEG     = $03; // based on segment
  TDS_PTR_BASE_VAL     = $04; // based on value of base
  TDS_PTR_BASE_SEGVAL  = $05; // based on segment value of base
  TDS_PTR_BASE_ADDR    = $06; // based on address of base
  TDS_PTR_BASE_SEGADDR = $07; // based on segment address of base
  TDS_PTR_BASE_TYPE    = $08; // based on type
  TDS_PTR_BASE_SELF    = $09; // based on self
  TDS_PTR_NEAR32       = $0a; // 32 bit pointer
  TDS_PTR_FAR32        = $0b; // 16:32 pointer

  TDS_PTR_MODE_PTR     = $00; // "normal" pointer
  TDS_PTR_MODE_REF     = $01; // reference
  TDS_PTR_MODE_PMEM    = $02; // pointer to data member
  TDS_PTR_MODE_PMFUNC  = $03; // pointer to member function

type
  PTDS_lfPointer = ^TDS_lfPointer;
  TDS_lfPointer = packed record
    leaf: UInt16;
    attr: UInt16; // bit packed:
                  // :5 - pointer type
                  // :3 - pointer mode
                  // :1 - true if 16:32 pointer
                  // :1 - true if volatile
                  // :1 - true if const
                  // :1 - true if unaligned
                  // :4 - reserved
    utype: TDS_typ_t;
    pbase: array [0..0] of UInt8; // unused in Delphi
    function Getptrtype: UInt8; inline;
    function Getptrmode: UInt8; inline;
    function Getisflat32: UInt8; inline;
    function Getisvolatile: UInt8; inline;
    function Getisconst: UInt8; inline;
    function Getisunaligned: UInt8; inline;
    function Getunused: UInt8; inline;
    procedure Setptrtype(Value: UInt8); inline;
    procedure Setptrmode(Value: UInt8); inline;
    procedure Setisflat32(Value: UInt8); inline;
    procedure Setisvolatile(Value: UInt8); inline;
    procedure Setisconst(Value: UInt8); inline;
    procedure Setisunaligned(Value: UInt8); inline;
    procedure Setunused(Value: UInt8); inline;
    property ptrtype: UInt8 read Getptrtype write Setptrtype;
    property ptrmode: UInt8 read Getptrmode write Setptrmode;
    property isflat32: UInt8 read Getisflat32 write Setisflat32;
    property isvolatile: UInt8 read Getisvolatile write Setisvolatile;
    property isconst: UInt8 read Getisconst write Setisconst;
    property isunaligned: UInt8 read Getisunaligned write Setisunaligned;
    property unused: UInt8 read Getunused write Setunused;
  end;

  PTDS_lfClass = ^TDS_lfClass;
  TDS_lfClass = packed record
    leaf: UInt16;
    count: UInt16;
    field: TDS_typ_t;
    &property: TDS_prop_t;
    unused1,
    unused2,
    unused3: UInt32;
    name: UInt32;
    instsize: UInt16;
  end;

  PTDS_lfStructure = ^TDS_lfStructure;
  TDS_lfStructure = TDS_lfClass;

  PTDS_lfEnum = ^TDS_lfEnum;
  TDS_lfEnum = packed record
    leaf: UInt16;
    count: UInt16;
    utype: TDS_typ_t;
    field: TDS_typ_t;
    &property: TDS_prop_t;
    reserved: UInt16;
    name: UInt32;
  end;

const
  TDS_CALL_NEAR_C      = $00;  // near right to left push, caller pops stack
  TDS_CALL_FAR_C       = $01;  // far right to left push, caller pops stack
  TDS_CALL_NEAR_PASCAL = $02;  // near left to right push, callee pops stack
  TDS_CALL_FAR_PASCAL  = $03;  // far left to right push, callee pops stack
  TDS_CALL_NEAR_FAST   = $04;  // near left to right push with regs, callee pops stack
  TDS_CALL_FAR_FAST    = $05;  // far left to right push with regs, callee pops stack
  TDS_CALL_SKIPPED     = $06;  // skipped (unused) call index
  TDS_CALL_NEAR_STD    = $07;  // near standard call
  TDS_CALL_FAR_STD     = $08;  // far standard call
  TDS_CALL_NEAR_SYS    = $09;  // near sys call
  TDS_CALL_FAR_SYS     = $0a;  // far sys call
  TDS_CALL_THISCALL    = $0b;  // this call (this passed in register)
  TDS_CALL_BORLFAST    = $0c;  // Borland fastcall, first three EAX, EDX, ECX, rest left to right push, callee pops stack

type
  PTDS_lfProc = ^TDS_lfProc;
  TDS_lfProc = packed record
    leaf: UInt16;
    rvtype: TDS_typ_t;
    calltype: UInt8;
    reserved: UInt8;
    parmcount: UInt16;
    arglist: TDS_typ_t;
  end;

  PTDS_lfMFunc = ^TDS_lfMFunc;
  TDS_lfMFunc = packed record
    leaf: UInt16;
    rvtype: TDS_typ_t;
    classtype: TDS_typ_t;
    thistype: TDS_typ_t;
    calltype: UInt8;
    reserved: UInt8;
    parmcount: UInt16;
    arglist: TDS_typ_t;
    reserved2: Int32;
  end;

  PTDS_lfVTShape = ^TDS_lfVTShape;
  TDS_lfVTShape = packed record
    leaf: UInt16;
    count: UInt16;
    desc: array [0..0] of UInt8;
  end;

  PTDS_lfDSet = ^TDS_lfDSet;
  TDS_lfDSet = packed record
    leaf: UInt16;
    eltype: TDS_typ_t;
    name: UInt32;
    reserved: UInt16;
    size: UInt16;
  end;

  PTDS_lfDRanged = ^TDS_lfDRanged;
  TDS_lfDRanged = packed record
    leaf: UInt16;
    utype: TDS_typ_t;
    name: UInt32;
    data: array [0..0] of UInt8;
    // data contains:
    // low: (leaf type) numeric leaf for low value
    // high: (leaf type) numeric leaf for high value
    // size: UInt16 size of variable
  end;

  PTDS_lfDArray = ^TDS_lfDArray;
  TDS_lfDArray = packed record
    leaf: UInt16;
    elemtype: TDS_typ_t;
    rangetype: TDS_typ_t;
    name: UInt32;
    data: array [0..0] of UInt8;
    // data contains:
    // size: (leaf type) numeric leaf for array size in bytes
    // count: (leaf type) numeric leaf for array count
  end;

  PTDS_lfDShortStr = ^TDS_lfDShortStr;
  TDS_lfDShortStr = TDS_lfDArray;

  PTDS_lfDMethodRef = ^TDS_lfDMethodRef;
  TDS_lfDMethodRef = packed record
    leaf: UInt16;
    rvtype: TDS_typ_t;
    calltype: UInt8;
    reserved: UInt8;
    parmcount: UInt16;
    arglist: TDS_typ_t;
  end;

  PTDS_lfDProperty = ^TDS_lfDProperty;
  TDS_lfDProperty = packed record
    leaf: UInt16;
    utype: TDS_typ_t;
    propattr: TDS_propattr_t;
  end;

  PTDS_lfDAnsiStr = ^TDS_lfDAnsiStr;
  TDS_lfDAnsiStr = packed record
    leaf: UInt16;
    name: UInt32;
  end;

  PTDS_lfDVariant = ^TDS_lfDVariant;
  TDS_lfDVariant = TDS_lfDAnsiStr;

  PTDS_lfDMetaclass = ^TDS_lfDMetaclass;
  TDS_lfDMetaclass = packed record
    leaf: UInt16;
    classtype: TDS_typ_t;
    shape: TDS_typ_t;
  end;

  PTDS_lfDWideStr = ^TDS_lfDWideStr;
  TDS_lfDWideStr = TDS_lfDAnsiStr;

  PTDS_lfDUnicodeStr = ^TDS_lfDUnicodeStr;
  TDS_lfDUnicodeStr = TDS_lfDAnsiStr;

  PTDS_lfArgList = ^TDS_lfArgList;
  TDS_lfArgList = packed record
    leaf: UInt16;
    count: UInt16;
    arg: array [0..0] of TDS_typ_t;
  end;

  PTDS_lfFieldList = ^TDS_lfFieldList;
  TDS_lfFieldList = packed record
    leaf: UInt16;
    data: array [0..0] of UInt8;
  end;

  PTDS_mlMethod = ^TDS_mlMethod;
  TDS_mlMethod = packed record
    attr: TDS_fldattr_t;
    index: TDS_typ_t;
    unknown: UInt32;
    vbaseoff: UInt32; // *optional*
  end;

  PTDS_lfMethodList = ^TDS_lfMethodList;
  TDS_lfMethodList = packed record
    leaf: UInt16;
    mList: array [0..0] of UInt8;
  end;

  PTDS_lfBClass = ^TDS_lfBClass;
  TDS_lfBClass = packed record
    leaf: UInt16;
    index: TDS_typ_t;
    attr: TDS_fldattr_t;
    offset: array [0..0] of UInt8; // numeric leaf
  end;

  PTDS_lfEnumerate = ^TDS_lfEnumerate;
  TDS_lfEnumerate = packed record
    leaf: UInt16;
    attr: TDS_fldattr_t;
    name: UInt32;
    reserved: UInt32;
    value: array [0..0] of UInt8; // numeric leaf
  end;

  PTDS_lfMember = ^TDS_lfMember;
  TDS_lfMember = packed record
    leaf: UInt16;
    index: TDS_typ_t;
    attr: TDS_fldattr_t;
    name: UInt32;
    reserved: UInt32;
    offset: array [0..0] of UInt8; // numeric leaf
  end;

  PTDS_lfSTMember = ^TDS_lfSTMember;
  TDS_lfSTMember = packed record
    leaf: UInt16;
    index: TDS_typ_t;
    attr: TDS_fldattr_t;
    name: UInt32;
    reserved: UInt32;
  end;

  PTDS_lfMethod = ^TDS_lfMethod;
  TDS_lfMethod = packed record
    leaf: UInt16;
    count: UInt16;
    mList: TDS_typ_t;
    name: UInt32;
  end;

  PTDS_lfVFuncTab = ^TDS_lfVFuncTab;
  TDS_lfVFuncTab = packed record
    leaf: UInt16;
    &type: TDS_typ_t;
    offset: array [0..0] of UInt8; // numeric leaf...should be 0
  end;

  PTDS_lfChar = ^TDS_lfChar;
  TDS_lfChar = packed record
    leaf: UInt16;
    val: Int8;
  end;

  PTDS_lfShort = ^TDS_lfShort;
  TDS_lfShort = packed record
    leaf: UInt16;
    val: Int16;
  end;

  PTDS_lfUShort = ^TDS_lfUShort;
  TDS_lfUShort = packed record
    leaf: UInt16;
    val: UInt16;
  end;

  PTDS_lfLong = ^TDS_lfLong;
  TDS_lfLong = packed record
    leaf: UInt16;
    val: Int32;
  end;

  PTDS_lfULong = ^TDS_lfULong;
  TDS_lfULong = packed record
    leaf: UInt16;
    val: UInt32;
  end;

  PTDS_lfQuad = ^TDS_lfQuad;
  TDS_lfQuad = packed record
    leaf: UInt16;
    val: Int64;
  end;

  PTDS_lfUQuad = ^TDS_lfUQuad;
  TDS_lfUQuad = packed record
    leaf: UInt16;
    val: UInt64;
  end;

  PTDS_lfOct = ^TDS_lfOct;
  TDS_lfOct = packed record
    leaf: UInt16;
    val: array [0..15] of UInt8;
  end;

  PTDS_lfUOct = ^TDS_lfUOct;
  TDS_lfUOct = packed record
    leaf: UInt16;
    val: array [0..15] of UInt8;
  end;

  PTDS_lfReal16 = ^TDS_lfReal16;
  TDS_lfReal16 = packed record
    leaf: UInt16;
    val: UInt16;
  end;

  PTDS_lfReal32 = ^TDS_lfReal32;
  TDS_lfReal32 = packed record
    leaf: UInt16;
    val: Single;
  end;

  PTDS_lfReal48 = ^TDS_lfReal48;
  TDS_lfReal48 = packed record
    leaf: UInt16;
    val: array [0..5] of UInt8;
  end;

  PTDS_lfReal64 = ^TDS_lfReal64;
  TDS_lfReal64 = packed record
    leaf: UInt16;
    val: Double;
  end;

  PTDS_lfReal80 = ^TDS_lfReal80;
  TDS_lfReal80 = packed record
    leaf: UInt16;
    val: TExtended80Rec;
  end;

  PTDS_lfReal128 = ^TDS_lfReal128;
  TDS_lfReal128 = packed record
    leaf: UInt16;
    val: array [0..15] of UInt8;
  end;

  PTDS_lfCmplx32 = ^TDS_lfCmplx32;
  TDS_lfCmplx32 = packed record
    leaf: UInt16;
    val_real,
    val_imag: Single;
  end;

  PTDS_lfCmplx64 = ^TDS_lfCmplx64;
  TDS_lfCmplx64 = packed record
    leaf: UInt16;
    val_real,
    val_imag: Double;
  end;

  PTDS_lfCmplx80 = ^TDS_lfCmplx80;
  TDS_lfCmplx80 = packed record
    leaf: UInt16;
    val_real,
    val_imag: TExtended80Rec;
  end;

  PTDS_lfCmplx128 = ^TDS_lfCmplx128;
  TDS_lfCmplx128 = packed record
    leaf: UInt16;
    val_real,
    val_imag: array [0..15] of UInt8;
  end;

  PTDS_lfVarString = ^TDS_lfVarString;
  TDS_lfVarString = packed record
    leaf: UInt16;
    len: UInt16;
    value: array [0..0] of UInt8;
  end;

const
  // Symbol types
  TDS_S_COMPILE        = $0001; // Compile flags symbol
  TDS_S_REGISTER       = $0002; // Register variable
  TDS_S_CONSTANT       = $0003; // Constant symbol
  TDS_S_UDT            = $0004; // User-defined Type
  TDS_S_SSEARCH        = $0005; // Start search
  TDS_S_END            = $0006; // End block, procedure, with, or thunk
  TDS_S_SKIP           = $0007; // Skip - Reserve symbol space
  TDS_S_CVRESERVE      = $0008; // Reserved for Code View internal use
  TDS_S_OBJNAME        = $0009; // Specify name of object file

  TDS_S_GPROCINFO      = $0020; // Global section declared procedure
  TDS_S_UNITDEPS       = $0024; // Unit dependencies?
  TDS_S_UNITDEPSV2     = $0025; // Unit dependencies?
  TDS_S_UNITDEPSV3     = $0026; // Unit dependencies?
  TDS_S_SCOPEDCONST    = $0027; // Scoped constant symbol

  TDS_S_BPREL16        = $0100; // BP relative 16:16
  TDS_S_LDATA16        = $0101; // Local data 16:16
  TDS_S_GDATA16        = $0102; // Global data 16:16
  TDS_S_PUB16          = $0103; // Public symbol 16:16
  TDS_S_LPROC16        = $0104; // Local procedure start 16:16
  TDS_S_GPROC16        = $0105; // Global procedure start 16:16
  TDS_S_THUNK16        = $0106; // Thunk start 16:16
  TDS_S_BLOCK16        = $0107; // Block start 16:16
  TDS_S_WITH16         = $0108; // With start 16:16
  TDS_S_LABEL16        = $0109; // Code label 16:16
  TDS_S_CEXMODEL16     = $010A; // Change execution model 16:16
  TDS_S_VFTPATH16      = $010B; // Virtual function table path descriptor 16:16

  TDS_S_BPREL32        = $0200; // BP relative 16:32
  TDS_S_LDATA32        = $0201; // Local data 16:32
  TDS_S_GDATA32        = $0202; // Global data 16:32
  TDS_S_PUB32          = $0203; // Public symbol 16:32
  TDS_S_LPROC32        = $0204; // Local procedure start 16:32
  TDS_S_GPROC32        = $0205; // Global procedure start 16:32
  TDS_S_THUNK32        = $0206; // Thunk start 16:32
  TDS_S_BLOCK32        = $0207; // Block start 16:32
  TDS_S_WITH32         = $0208; // With start 16:32
  TDS_S_LABEL32        = $0209; // Label 16:32
  TDS_S_CEXMODEL32     = $020A; // Change execution model 16:32
  TDS_S_VFTPATH32      = $020B; // Virtual function table path descriptor 16:32

  TDS_S_REGVALIDRANGE  = $0211; // Register variable valid range

  TDS_S_NESTEDPROCINFO = $0230; // Nested procedure information

type
  PTDS_SYMTYPE = ^TDS_SYMTYPE;
  TDS_SYMTYPE = packed record
    reclen: UInt16;
    rectyp: UInt16;
    data: array [0..0] of UInt8;
  end;

function NextSym(pSym: PTDS_SYMTYPE): PTDS_SYMTYPE; inline;

type
  PTDS_REGSYM = ^TDS_REGSYM;
  TDS_REGSYM = packed record
    reclen: UInt16;
    rectyp: UInt16; // TDS_S_REGISTER
    typind: TDS_typ_t;
    reg: UInt16;
    nameind: UInt32;
    reserved: UInt32;
  end;

  PTDS_UDTSYM = ^TDS_UDTSYM;
  TDS_UDTSYM = packed record
    reclen: UInt16;
    rectyp: UInt16; // TDS_S_UDT
    typind: TDS_typ_t;
    props: UInt16;
    nameind: UInt32;
    reserved: UInt32;
  end;

  PTDS_SEARCHSYM = ^TDS_SEARCHSYM;
  TDS_SEARCHSYM = packed record
    reclen: UInt16;
    rectyp: UInt16; // TDS_S_SSEARCH
    startsym: UInt32;
    seg: UInt16;
    code: UInt16;
    data: UInt16;
    dataoff: UInt32;
  end;

  PTDS_GPROCINFOSYM = ^TDS_GPROCINFOSYM;
  TDS_GPROCINFOSYM = packed record
    reclen: UInt16;
    rectyp: UInt16; // TDS_S_GPROCINFO
    reserved1: UInt32;
    typind: TDS_typ_t;
    nameind: UInt32;
    reserved2: UInt32;
    off: UInt32;
    seg: UInt16;
    reserved3: UInt16;
  end;

  PTDS_SCOPEDCONSTSYM = ^TDS_SCOPEDCONSTSYM;
  TDS_SCOPEDCONSTSYM = packed record
    reclen: UInt16;
    rectyp: UInt16; // TDS_S_SCOPEDCONST
    typind: TDS_typ_t;
    props: UInt16;
    nameind: UInt32;
    reserved: UInt32;
    value: UInt32; // gibberish unless numeric and 4 bytes or smaller
  end;

  PTDS_BPRELSYM = ^TDS_BPRELSYM;
  TDS_BPRELSYM = packed record
    reclen: UInt16;
    rectyp: UInt16; // TDS_S_BPREL32
    off: Int32;
    typind: TDS_typ_t;
    nameind: UInt32;
    reserved: UInt32;
  end;

  PTDS_DATASYM = ^TDS_DATASYM;
  TDS_DATASYM = packed record
    reclen: UInt16;
    rectyp: UInt16; // TDS_S_LDATA32, TDS_S_GDATA32
    off: UInt32;
    seg: UInt16;
    reserved: UInt16;
    typind: TDS_typ_t;
    nameind: UInt32;
    reserved2: UInt32;
  end;

  PTDS_PROCSYM = ^TDS_PROCSYM;
  TDS_PROCSYM = packed record
    reclen: UInt16;
    rectyp: UInt16; // TDS_S_LPROC32, TDS_S_GPROC32
    pParent: UInt32;
    pEnd: UInt32;
    pNext: UInt32;
    len: UInt32;
    DbgStart: UInt32;
    DbgEnd: UInt32;
    off: UInt32;
    seg: UInt16;
    reserved: UInt16;
    typind: TDS_typ_t;
    nameind: UInt32;
    reserved2: UInt32;
  end;

  PTDS_LPROCSYM = ^TDS_LPROCSYM;
  TDS_LPROCSYM = TDS_PROCSYM;

  PTDS_GPROCSYM = ^TDS_GPROCSYM;
  TDS_GPROCSYM = packed record
    basic: TDS_PROCSYM;
    name: array [0..0] of UTF8Char; // length-prefixed name
  end;

  PTDS_WITHSYM = ^TDS_WITHSYM;
  TDS_WITHSYM = packed record
    reclen: UInt16;
    rectyp: UInt16; // TDS_S_WITH32
    pParent: UInt32;
    len: UInt32;
    off: UInt32;
    seg: UInt16;
    reserved: UInt16;
    typind: TDS_typ_t;
    nameind: UInt32;
    reserved2: UInt32;
  end;

  TDS_rvrRANGE = packed record
    off: UInt32;
    len: UInt32;
    reg: UInt16;
  end;

  PTDS_REGVALIDRANGESYM = ^TDS_REGVALIDRANGESYM;
  TDS_REGVALIDRANGESYM = packed record
    reclen: UInt16;
    rectyp: UInt16; // TDS_S_REGVALIDRANGE
    cRanges: UInt16;
    ranges: array [0..0] of TDS_rvrRANGE;
  end;

  PTDS_NESTPROCINFOSYM = ^TDS_NESTPROCINFOSYM;
  TDS_NESTPROCINFOSYM = packed record
    reclen: UInt16;
    rectyp: UInt16; // TDS_S_NESTEDPROCINFO
    off: UInt32; // frame relative offset to outer frame pointer
  end;

implementation

function TDS_SegmentLineInfo.Getoffset: PUInt32;
begin
{$POINTERMATH ON}
  Result := @data;
{$POINTERMATH OFF}
end;

function TDS_SegmentLineInfo.Getlinenumber: PUInt16;
begin
{$POINTERMATH ON}
  Result := Pointer(offset + cPair);
{$POINTERMATH OFF}
end;

function TDS_SourceFileEntry.GetbaseSrcLn: PUInt32;
begin
{$POINTERMATH ON}
  Result := @data;
{$POINTERMATH OFF}
end;

function TDS_SourceFileEntry.Getstartend: PTDS_SourceModuleSectionOffsetPair;
begin
{$POINTERMATH ON}
  Result := Pointer(baseSrcLn + cSeg);
{$POINTERMATH OFF}
end;

function TDS_SourceFileEntry.getbaseSrcLnPointer(Base: Pointer; Index: UInt16): PTDS_SegmentLineInfo;
begin
{$POINTERMATH ON}
  Result := PTDS_SegmentLineInfo(PUInt8(Base) + baseSrcLn[Index]);
{$POINTERMATH OFF}
end;

function TDS_SourceModuleSectionHeader.GetbaseSrcFile: PUInt32;
begin
{$POINTERMATH ON}
  Result := @data;
{$POINTERMATH OFF}
end;

function TDS_SourceModuleSectionHeader.Getstartend: PTDS_SourceModuleSectionOffsetPair;
begin
{$POINTERMATH ON}
  Result := Pointer(baseSrcFile + cFile);
{$POINTERMATH OFF}
end;

function TDS_SourceModuleSectionHeader.Getseg: PUInt16;
begin
{$POINTERMATH ON}
  Result := Pointer(startend + cSeg);
{$POINTERMATH OFF}
end;

function TDS_SourceModuleSectionHeader.GetbaseSrcFilePointer(Index: UInt16): PTDS_SourceFileEntry;
begin
{$POINTERMATH ON}
  Result := PTDS_SourceFileEntry(PUInt8(@Self) + baseSrcFile[Index]);
{$POINTERMATH OFF}
end;

function TDS_prop_t.Getunknown1: UInt8;
begin
  Result := (_props and (((1 shl 1)-1) shl 0)) shr 0;
end;

function TDS_prop_t.Getctor: UInt8;
begin
  Result := (_props and (((1 shl 1)-1) shl 1)) shr 1;
end;

function TDS_prop_t.Getunknown2: UInt8;
begin
  Result := (_props and (((1 shl 6)-1) shl 2)) shr 2;
end;

function TDS_prop_t.Getdtor: UInt8;
begin
  Result := (_props and (((1 shl 1)-1) shl 8)) shr 8;
end;

function TDS_prop_t.Getunknown3: UInt8;
begin
  Result := (_props and (((1 shl 7)-1) shl 9)) shr 9;
end;

procedure TDS_prop_t.Setunknown1(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 0))) or ((Value and ((1 shl 1)-1)) shl 0);
end;

procedure TDS_prop_t.Setctor(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 1))) or ((Value and ((1 shl 1)-1)) shl 1);
end;

procedure TDS_prop_t.Setunknown2(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 6)-1) shl 2))) or ((Value and ((1 shl 6)-1)) shl 2);
end;

procedure TDS_prop_t.Setdtor(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 8))) or ((Value and ((1 shl 1)-1)) shl 8);
end;

procedure TDS_prop_t.Setunknown3(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 7)-1) shl 9))) or ((Value and ((1 shl 7)-1)) shl 9);
end;

function TDS_propattr_t.Gethasdefault: UInt8;
begin
  Result := (_props and (((1 shl 1)-1) shl 0)) shr 0;
end;

function TDS_propattr_t.Gethasgetfunc: UInt8;
begin
  Result := (_props and (((1 shl 1)-1) shl 1)) shr 1;
end;

function TDS_propattr_t.Gethassetfunc: UInt8;
begin
  Result := (_props and (((1 shl 1)-1) shl 2)) shr 2;
end;

function TDS_propattr_t.Getunknown: UInt8;
begin
  Result := (_props and (((1 shl 13)-1) shl 3)) shr 3;
end;

procedure TDS_propattr_t.Sethasdefault(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 0))) or ((Value and ((1 shl 1)-1)) shl 0);
end;

procedure TDS_propattr_t.Sethasgetfunc(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 1))) or ((Value and ((1 shl 1)-1)) shl 1);
end;

procedure TDS_propattr_t.Sethassetfunc(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 2))) or ((Value and ((1 shl 1)-1)) shl 2);
end;

procedure TDS_propattr_t.Setunknown(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 13)-1) shl 3))) or ((Value and ((1 shl 13)-1)) shl 3);
end;

function TDS_fldattr_t.Getaccess: UInt8;
begin
  Result := (_props and (((1 shl 2)-1) shl 0)) shr 0;
end;

function TDS_fldattr_t.Getmprop: UInt8;
begin
  Result := (_props and (((1 shl 3)-1) shl 2)) shr 2;
end;

function TDS_fldattr_t.Getunknown1: UInt8;
begin
  Result := (_props and (((1 shl 5)-1) shl 5)) shr 5;
end;

function TDS_fldattr_t.Getctor: UInt8;
begin
  Result := (_props and (((1 shl 1)-1) shl 10)) shr 10;
end;

function TDS_fldattr_t.Getdtor: UInt8;
begin
  Result := (_props and (((1 shl 1)-1) shl 11)) shr 11;
end;

function TDS_fldattr_t.Getunknown2: UInt8;
begin
  Result := (_props and (((1 shl 4)-1) shl 12)) shr 12;
end;

procedure TDS_fldattr_t.Setaccess(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 2)-1) shl 0))) or ((Value and ((1 shl 2)-1)) shl 0);
end;

procedure TDS_fldattr_t.Setmprop(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 3)-1) shl 2))) or ((Value and ((1 shl 3)-1)) shl 2);
end;

procedure TDS_fldattr_t.Setunknown1(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 5)-1) shl 5))) or ((Value and ((1 shl 5)-1)) shl 5);
end;

procedure TDS_fldattr_t.Setctor(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 10))) or ((Value and ((1 shl 1)-1)) shl 10);
end;

procedure TDS_fldattr_t.Setdtor(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 11))) or ((Value and ((1 shl 1)-1)) shl 11);
end;

procedure TDS_fldattr_t.Setunknown2(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 4)-1) shl 12))) or ((Value and ((1 shl 4)-1)) shl 12);
end;

function TDS_NextType(pType: PTDS_TYPTYPE): PTDS_TYPTYPE; inline;
begin
{$POINTERMATH ON}
  Result := PTDS_TYPTYPE(PUInt8(pType) + pType.len + SizeOf(pType.len));
{$POINTERMATH OFF}
end;

function TDS_lfPointer.Getptrtype: UInt8;
begin
  Result := (attr and (((1 shl 5)-1) shl 0)) shr 0;
end;

function TDS_lfPointer.Getptrmode: UInt8;
begin
  Result := (attr and (((1 shl 3)-1) shl 5)) shr 5;
end;

function TDS_lfPointer.Getisflat32: UInt8;
begin
  Result := (attr and (((1 shl 1)-1) shl 8)) shr 8;
end;

function TDS_lfPointer.Getisvolatile: UInt8;
begin
  Result := (attr and (((1 shl 1)-1) shl 9)) shr 9;
end;

function TDS_lfPointer.Getisconst: UInt8;
begin
  Result := (attr and (((1 shl 1)-1) shl 10)) shr 10;
end;

function TDS_lfPointer.Getisunaligned: UInt8;
begin
  Result := (attr and (((1 shl 1)-1) shl 11)) shr 11;
end;

function TDS_lfPointer.Getunused: UInt8;
begin
  Result := (attr and (((1 shl 4)-1) shl 12)) shr 12;
end;

procedure TDS_lfPointer.Setptrtype(Value: UInt8);
begin
  attr := (attr and (not (((1 shl 5)-1) shl 0))) or ((Value and ((1 shl 5)-1)) shl 0);
end;

procedure TDS_lfPointer.Setptrmode(Value: UInt8);
begin
  attr := (attr and (not (((1 shl 3)-1) shl 5))) or ((Value and ((1 shl 3)-1)) shl 5);
end;

procedure TDS_lfPointer.Setisflat32(Value: UInt8);
begin
  attr := (attr and (not (((1 shl 1)-1) shl 8))) or ((Value and ((1 shl 1)-1)) shl 8);
end;

procedure TDS_lfPointer.Setisvolatile(Value: UInt8);
begin
  attr := (attr and (not (((1 shl 1)-1) shl 9))) or ((Value and ((1 shl 1)-1)) shl 9);
end;

procedure TDS_lfPointer.Setisconst(Value: UInt8);
begin
  attr := (attr and (not (((1 shl 1)-1) shl 10))) or ((Value and ((1 shl 1)-1)) shl 10);
end;

procedure TDS_lfPointer.Setisunaligned(Value: UInt8);
begin
  attr := (attr and (not (((1 shl 1)-1) shl 11))) or ((Value and ((1 shl 1)-1)) shl 11);
end;

procedure TDS_lfPointer.Setunused(Value: UInt8);
begin
  attr := (attr and (not (((1 shl 4)-1) shl 12))) or ((Value and ((1 shl 4)-1)) shl 12);
end;

function NextSym(pSym: PTDS_SYMTYPE): PTDS_SYMTYPE; inline;
begin
{$POINTERMATH ON}
  Result := PTDS_SYMTYPE(PUInt8(pSym) + pSym.reclen + SizeOf(pSym.reclen));
{$POINTERMATH OFF}
end;

end.
