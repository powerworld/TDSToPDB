unit PDBInterface;

interface

uses
  Winapi.Windows, CVInfo;

const
  niNil        = 0;
  PDB_MAX_PATH = 260;
  cbErrMax     = 1024;

  wtiSymsNB09 = 0;
  wtiSymsNB10 = 1;

// Filter values for PDBCopyTo
  copyRemovePrivate       = $00000001;  // remove private debug information
  copyCreateNewSig        = $00000002;  // create new signature for target pdb
  copyKeepAnnotation      = $00000004;  // keep S_ANNOTATION symbols, filtering on the first string
  copyKeepAnnotation2     = $00000008;  // keep S_ANNOTATION symbols, filtering on both the first and last strings
  copyRemoveNamedStream   = $00000010;  // remove named stream only

type
  PInt32 = ^Int32;

  IMPV = ULONG;
  SIG = ULONG;
  AGE = ULONG;
  SZ_CONST = PAnsiChar;
  PV = Pointer;
  PCV = Pointer;

  SIG70 = TGUID;
  PSIG70 = PGUID;
  PCSIG70 = PGUID;

{$Z4} {$SCOPEDENUMS ON}
  PDBINTV = (
    _110    = 20091201,
    _80     = 20030901,
    _70     = 20001102,
    _70Dep  = 20000406,
    _69     = 19990511,
    _61     = 19980914,
    _50a    = 19970116,
    _60     = _50a,
    _50     = 19960502,
    _41     = 920924,
    Current = _110
  );
  INTV = PDBINTV;

  PDBIMPV = (
    VC2     = 19941610,
    VC4     = 19950623,
    VC41    = 19950814,
    VC50    = 19960307,
    VC98    = 19970604,
    VC70    = 20000404,
    VC70Dep = 19990604,  // deprecated vc70 implementation version
    VC80    = 20030901,
    VC110   = 20091201,
    VC140   = 20140508,
    Current = VC110
  );
{$SCOPEDENUMS OFF} {$Z1}

  TI = CV_typ_t;
  TI16 = CV_typ16_t;
  NI = UInt32;
  PTi = ^TI;
  PTi16 = ^TI16;
  ITSM = BYTE;
  PITSM = ^ITSM;

  PFNVALIDATEDEBUGINFOFILE = function (szFile: PAnsiChar; errcode: PULONG): BOOL; stdcall;

  PSEARCHDEBUGINFO = ^SEARCHDEBUGINFO;
  SEARCHDEBUGINFO = record
    cb:             DWORD;                                  // doubles as version detection
    fMainDebugFile: BOOL;                                   // indicates "core" or "ancilliary" file
                                                            // eg: main.exe has main.pdb and foo.lib->foo.pdb
    szMod:          PAnsiChar;                              // exe/dll
    szLib:          PAnsiChar;                              // lib if appropriate
    szObj:          PAnsiChar;                              // object file
    rgszTriedThese: PPAnsiChar;                             // list of ones that were tried,
                                                            // NULL terminated list of LSZ's
    szValidatedFile:
                    array [0..PDB_MAX_PATH-1] of AnsiChar;  // output of validated filename,
    _pfnValidateDebugInfoFile:
                    PFNVALIDATEDEBUGINFOFILE;               // validation function
    szExe:          PAnsiChar;                              // exe/dll
  end;

  PfnFindDebugInfoFile = function (_pSearchDebugInfo: PSEARCHDEBUGINFO): BOOL; stdcall;

  PPDB = class;
  PDBI = class;
  PPMod = ^PMod;
  PMod = class;
  PTPI = class;
  PGSI = class;
  PStream = class;
  PStreamImage = class;
  PNameMap = class;
  PEnum = class;
  PEnumNameMap = class;
  PEnumContrib = class;
  PDbg = class;
  PSrc = class;
  PEnumSrc = class;
  PSrcHash = class;
  PEnumLines = class;
  PEnumThunk = class;
  PEnumSyms = class;

{$Z4} {$SCOPEDENUMS ON}
  PDBErrors = (
    OK,                         // no problem
    USAGE,                      // invalid parameter or call order
    OUT_OF_MEMORY,              // out of heap
    FILE_SYSTEM,                // "pdb name", can't write file, out of disk, etc.
    NOT_FOUND,                  // "pdb name", PDB file not found
    INVALID_SIG,                // "pdb name", PDB::OpenValidate() and its clients only
    INVALID_AGE,                // "pdb name", PDB::OpenValidate() and its clients only
    PRECOMP_REQUIRED,           // "obj name", Mod::AddTypes() only
    OUT_OF_TI,                  // "pdb name", TPI::QueryTiForCVRecord() only
    NOT_IMPLEMENTED,            // -
    V1_PDB,                     // "pdb name", PDB::Open* only (obsolete)
    UNKNOWN_FORMAT = V1_PDB,    // pdb can't be opened because it has newer versions of stuff
    FORMAT,                     // accessing pdb with obsolete format
    LIMIT,
    CORRUPT,                    // cv info corrupt, recompile mod
    TI16,                       // no 16-bit type interface present
    ACCESS_DENIED,              // "pdb name", PDB file read-only
    ILLEGAL_TYPE_EDIT,          // trying to edit types in read-only mode
    INVALID_EXECUTABLE,         // not recogized as a valid executable
    DBG_NOT_FOUND,              // A required .DBG file was not found
    NO_DEBUG_INFO,              // No recognized debug info found
    INVALID_EXE_TIMESTAMP,      // Invalid timestamp on Openvalidate of exe
    CORRUPT_TYPEPOOL,           // A corrupted type record was found in a PDB
    DEBUG_INFO_NOT_IN_PDB,      // returned by OpenValidateX
    RPC,                        // Error occured during RPC
    UNKNOWN,                    // Unknown error
    BAD_CACHE_PATH,             // bad cache location specified with symsrv
    CACHE_FULL,                 // symsrv cache is full
    TOO_MANY_MOD_ADDTYPE,       // Addtype is called more then once per mod
    MAX
  );
  EC = PDBErrors;

// Type of callback arg to PDB::OpenValidate5

  POVC = (
    NotifyDebugDir,
    NotifyOpenDBG,
    NotifyOpenPDB,
    Reserved,
    ReadExecutableAt,
    ReadExecutableAtRVA,
    RestrictRegistry,
    RestrictSymsrv,
    RestrictSystemRoot,
    NotifyMiscPath,
    ReadMiscDebugData,
    ReadCodeViewDebugData,
    RestrictOriginalPath,
    RestrictReferencePath,
    RestrictDBG
  );
{$SCOPEDENUMS OFF} {$Z1}

  PfnPDBQueryCallback = function (pvClient: Pointer; _povc: POVC): Integer; cdecl;

  PfnPDBNotifyDebugDir = procedure (pvClient: Pointer; fExecutable: BOOL; const pdbgdir: _IMAGE_DEBUG_DIRECTORY); cdecl;
  PfnPDBNotifyOpenDBG = procedure (pvClient: Pointer; wszDbgPath: PChar; _ec: EC; wszError: PChar); cdecl;
  PfnPDBNotifyOpenPDB = procedure (pvClient: Pointer; wszPdbPath: PChar; _ec: EC; wszError: PChar); cdecl;
  PfnPDBReadExecutableAt = function (pvClient: Pointer; fo: DWORDLONG; cb: DWORD; _pv: Pointer): HRESULT; cdecl;
  PfnPDBReadExecutableAtRVA = function (pvClient: Pointer; rva: DWORD; cb: DWORD; _pv: Pointer): HRESULT; cdecl;
  PfnPDBRestrictRegistry = function (pvClient: Pointer): HRESULT; cdecl;
  PfnPDBRestrictSymsrv = function (pvClient: Pointer): HRESULT; cdecl;
  PfnPDBRestrictSystemRoot = function (pvClient: Pointer): HRESULT; cdecl;
  PfnPDBNotifyMiscPath = procedure (pvClient: Pointer; wszMiscPath: PChar);
  PfnPDBReadCodeViewDebugData = function (pvClient: Pointer; pcb: PDWORD; _pv: Pointer): HRESULT; cdecl;
  PfnPDBReadMiscDebugData = function (pvClient: Pointer; pdwTimeStampExe: PDWORD; pdwTimeStampDbg: PDWORD; pdwSizeOfImage: PDWORD; pcb: PDWORD; _pv: Pointer): HRESULT; cdecl;
  PfnPdbRestrictOriginalPath = function (pvClient: Pointer): HRESULT; cdecl;
  PfnPdbRestrictReferencePath = function (pvClient: Pointer): HRESULT; cdecl;
  PfnPdbRestrictDBG = function (pvClient: Pointer): HRESULT; cdecl;

// type of callback arg to PDB::GetRawBytes
  PFNfReadPDBRawBytes = function (pv: Pointer; cb: Integer): BOOL; cdecl;

// type of callback arg to DBI::FSetPfn*
{$Z4} {$SCOPEDENUMS ON}
  DOVC = (
    NotePdbUsed,
    NoteTypeMismatch,
    TmdTypeFilter
  );
{$SCOPEDENUMS OFF} {$Z1}

  PFNDBIQUERYCALLBACK = function (pvContext: Pointer; _dovc: DOVC): Integer; cdecl;

  PFNNOTEPDBUSED = procedure (
    pvContext:  Pointer;
    szFile:     PChar;
    fRead:      BOOL;
    fWrite:     BOOL); cdecl;

  PFNNOTETYPEMISMATCH = procedure (
    pvContext:  Pointer;
    szTypeName: PChar;
    szInfo:     PChar); cdecl;

  PFNTMDTYPEFILTER = function(
    pvContext:  Pointer;
    szUDT:      PChar): BOOL; cdecl;

// interface for error reporting
  IPDBError = interface
    function QueryLastError(szError: PChar; cchMax: NativeUInt): EC; cdecl;
    procedure SetLastError(_ec: EC; wszErr: PChar); cdecl;
    procedure Destroy(); cdecl;
  end;

  PfnPDBErrorCreate = function (_ppdb: PPDB): IPDBError; cdecl;

// WidenTi interface needs a couple of structures to communicate info back
// and forth.
  OffMap = record
    offOld: ULONG;
    offNew: ULONG;
  end;
  POffMap = ^OffMap;

  SymConvertInfo = record
    cbSyms:   ULONG;    // size necessary for converting a block
    cSyms:    ULONG;    // count of symbols, necessary to allocate
                        // mpoffOldoffNew array.
    pbSyms:   PBYTE;    // block of symbols (output side)
    rgOffMap: POffMap;  // OffMap rgOffMap[cSyms]
  end;

// PDBCopy callback signatures and function pointer types for PDB::CopyTo2 and CopyToW2
//
{$Z4} {$SCOPEDENUMS ON}
  PCC = (
    FilterPublics,
    FilterAnnotations,
    FilterStreamNames
  );
{$SCOPEDENUMS OFF} {$Z1}

  PfnPDBCopyQueryCallback = function (pvClientContext: Pointer; _pcc: PCC): BOOL; cdecl;

// Return (true, pszNewPublic==NULL) to keep the name as is,
// (true, pszNewPublic!=NULL) changes name to pszNewPublic,
// false to discard public entirely.
//
  PfnPDBCopyFilterPublics = function (
    pvClientContext:  Pointer;
    dwFilterFlags:    DWORD;
    offPublic:        UInt32;
    sectPublic:       UInt32;
    grfPublic:        UInt32;     // see cvinfo.h, definition of CV_PUBSYMFLAGS_e and
                                  // CV_PUBSYMFLAGS give the format of this bitfield.
    szPublic:         PChar;
    szNewPublic:      PChar;
    cchNewPublic:     UInt32
    ): BOOL; cdecl;

// Return true to keep the annotation, false to discard it.
//
  PfnPDBCopyFilterAnnotations = function (
    pvClientContext:    Pointer;
    szFirstAnnotation:  PChar
    ): BOOL; cdecl;

// Return true to delete the named stream, false to keep it.
//
  PfnPDBCopyFilterStreamNames = function (
    pvClientContext:  Pointer;
    szStream:         PChar
    ): BOOL; cdecl;

{$Z4} {$SCOPEDENUMS ON}
  DBGTYPE = (
    FPO,
    Exception,   // deprecated
    Fixup,
    OmapToSrc,
    OmapFromSrc,
    SectionHdr,
    TokenRidMap,
    Xdata,
    Pdata,
    NewFPO,
    SectionHdrOrig,
    Max          // must be last!
  );
  PDBGTYPE = ^DBGTYPE;

// We add a slight bit of structure to dbg blobs so we can record extra
// relevant information there.  Generally, the blobs are lifted right out
// of an image, and need some extra info anyway.  In the case of Xdata, we
// store RVA base of the Xdata there.  This is used to interpret the
// UnwindInfoAddress RVA in the IA64 Pdata entries.
//
  VerDataBlob = (
    One = 1,
    XdataCur = One,
    PdataCur = One
  );
{$SCOPEDENUMS OFF} {$Z1}

// default blob header
//
  DbgBlob = record
    ver:    ULONG;
    cbHdr:  ULONG;
    cbData: ULONG;
    //rgbDataBlob:
    //      array [0..0] of BYTE;   // Data follows, but to enable simple embedding,
                                    // don't use a zero-sized array here.
  end;

// "store rva of the base and va of image base" blob header
//
  DbgRvaVaBlob = record
    ver:          ULONG;
    cbHdr:        ULONG;
    cbData:       ULONG;
    rvaDataBase:  ULONG;
    vaImageBase:  DWORDLONG;
    ulReserved1:  ULONG;    // reserved, must be 0
    ulReserved2:  ULONG;    // reserved, must be 0
    //rgbDataBlob[]:
    //            array [0..0] of BYTE;   // Data follows, but to enable simple embedding,
                                          // don't use a zero-sized array here.
  end;

{$Z4} {$SCOPEDENUMS ON}
// Linker data necessary for relinking an image.  Record contains two SZ strings
// off of the end of the record with two offsets from the base
//
  VerLinkInfo = (
    One = 1,
    Two = 2,
    Cur = Two
  );
{$SCOPEDENUMS OFF} {$Z1}

  LinkInfo = record
    _cb:          ULONG;        // size of the whole record.  computed as
                                //  sizeof(LinkInfo) + strlen(szCwd) + 1 +
                                //  strlen(szCommand) + 1
    _ver:         VerLinkInfo;  // version of this record (VerLinkInfo)
    offszCwd:     ULONG;        // offset from base of this record to szCwd
    offszCommand: ULONG;        // offset from base of this record
    ichOutfile:   ULONG;        // index of start of output file in szCommand
    offszLibs:    ULONG;        // offset from base of this record to szLibs

    // The command includes the full path to the linker, the -re and -out:...
    // swithches.
    // A sample might look like the following:
    // "c:\program files\msdev\bin\link.exe -re -out:debug\foo.exe"
    // with ichOutfile being 48.
    // the -out switch is guaranteed to be the last item in the command line.
    function Ver: VerLinkInfo;
    function Cb: ULONG;
    function SzCwd: PAnsiChar;
    function SzCommand: PAnsiChar;
    function SzOutFile: PAnsiChar;
    class function Create: LinkInfo; static;
    function SzLibs: PAnsiChar;
  end;

  LinkInfoW = record
    LI: LinkInfo;

    function Ver: VerLinkInfo;
    function Cb: ULONG;
    function SzCwdW: PChar;
    function SzCommandW: PChar;
    function SzOutFileW: PChar;
    class function Create: LinkInfoW; static;
    function SzLibsW: PChar;
  end;

  PLinkInfoW = ^LinkInfoW;

  PLinkInfo = ^LinkInfo;

//
// Source (Src) info
//
// This is the source file server for virtual and real source code.
// It is structured as an index on the object file name concatenated
// with
{$Z4} {$SCOPEDENUMS ON}
  SrcVer = (
    One = 19980827
  );

  SrcCompress = (
    None,
    RLE,
    Huffman,
    LZ
  );
{$SCOPEDENUMS OFF} {$Z1}

  SrcHeader = record
    cb:           ULONG;  // record length
    ver:          ULONG;  // header version
    sig:          ULONG;  // CRC of the data for uniqueness w/o full compare
    cbSource:     ULONG;  // count of bytes of the resulting source
    srccompress:  BYTE;   // compression algorithm used
    grFlags:      BYTE;   // fVirtual : 1   // file is a virtual file (injected)
                          // pad : 7        // must be zero
    szNames:      array [0..0] of AnsiChar;
                          // file names (szFile "\0" szObj "\0" szVirtual,
                          //  as in: "f.cpp" "\0" "f.obj" "\0" "*inj:1:f.obj")
                          // in the case of non-virtual files, szVirtual is
                          // the same as szFile.
  end;

  PSrcHeader = ^SrcHeader;
  PCSrcHeader = PSrcHeader;

  SrcHeaderW = record
    cb:           ULONG;  // record length
    ver:          ULONG;  // header version
    sig:          ULONG;  // CRC of the data for uniqueness w/o full compare
    cbSource:     ULONG;  // count of bytes of the resulting source
    srccompress:  BYTE;   // compression algorithm used
    grFlags:      BYTE;   // fVirtual : 1   // file is a virtual file (injected)
                          // pad : 7        // must be zero
    szNames:      array [0..0] of Char;
                          // see comment above
  end;

  PSrcHeaderW = ^SrcHeaderW;
  PCSrcHeaderW = PSrcHeaderW;

// header used for storing the info and for output to clients who are reading
//
  SrcHeaderOut = record
    cb:           ULONG;  // record length
    ver:          ULONG;  // header version
    sig:          ULONG;  // CRC of the data for uniqueness w/o full compare
    cbSource:     ULONG;  // count of bytes of the resulting source
    niFile:       ULONG;
    niObj:        ULONG;
    niVirt:       ULONG;
    srccompress:  ULONG;  // compression algorithm used
    grFlags:      BYTE;   // fVirtual : 1   // file is a virtual file (injected)
                          // pad : 7        // must be zero
    sPad:         SHORT;
    Reserved:     UInt64;
  end;

  PSrcHeaderOut = ^SrcHeaderOut;
  PCSrcHeaderOut = PSrcHeaderOut;

  SrcHeaderBlock = record
    ver:    Int32;
    cb:     Int32;
    ft:     FILETIME;
    age:    Int32;
    rgbPad: array [0..43] of BYTE;
  end;

  SO = record
    off:    Int32;
    isect:  USHORT;
    pad:    USHORT;
  end;
  PSO = ^SO;

  PPDB = class abstract                 // program database
  private
    class function __Open2W(
        wszPDB: PChar;
        szMode: PAnsiChar;
        out pec: EC;
        { out, cchErrMax } wszError: PChar;
        cchErrMax: NativeUInt;
        out pppdb: PPDB
        ): BOOL; cdecl; static;

    class function __OpenEx2W(
        wszPDB: PChar;
        szMode: PAnsiChar;
        cbPage: Integer;
        out pec: EC;
        { out, cchErrMax } wszError: PChar;
        cchErrMax: NativeUInt;
        out pppdb: PPDB
        ): BOOL; cdecl; static;

    class function __OpenValidate4(
        wszPDB: PChar;
        szMode: PAnsiChar;
        _pcsig70: PCSIG70;
        _sig: SIG;
        _age: AGE;
        out pec: EC;
        { out, cchErrMax } wszError: PChar;
        cchErrMax: NativeUInt;
        out pppdb: PPDB
        ): BOOL; cdecl; static;

    class function __OpenValidate5(
        wszExecutable: PChar;
        wszSearchPath: PChar;
        pvClient: Pointer;
        pfnQueryCallback: PfnPDBQueryCallback;
        out pec: EC;
        { out, cchErrMax } wszError: PChar;
        cchErrMax: NativeUInt;
        out pppdb: PPDB
        ): BOOL; cdecl; static;

    class function __OpenNgenPdb(
        wszNgenImage: PChar;
        wszPdbPath: PChar;
        out pec: EC;
        { out, cchErrMax } wszError: PChar;
        cchErrMax: NativeUInt;
        out pppdb: PPDB
        ): BOOL; cdecl; static;

  public
    class function Open2W(
        wszPDB: PChar;
        szMode: PAnsiChar;
        out pec: EC;
        { out, cchErrMax } wszError: PChar;
        cchErrMax: NativeUInt;
        out pppdb: PPDB
        ): BOOL; static;

    class function OpenEx2W(
        wszPDB: PChar;
        szMode: PAnsiChar;
        cbPage: Integer;
        out pec: EC;
        { out, cchErrMax } wszError: PChar;
        cchErrMax: NativeUInt;
        out pppdb: PPDB
        ): BOOL; static;

    class function OpenValidate4(
        wszPDB: PChar;
        szMode: PAnsiChar;
        _pcsig70: PCSIG70;
        _sig: SIG;
        _age: AGE;
        out pec: EC;
        { out, cchErrMax } wszError: PChar;
        cchErrMax: NativeUInt;
        out pppdb: PPDB
        ): BOOL; static;

    class function OpenValidate5(
        wszExecutable: PChar;
        wszSearchPath: PChar;
        pvClient: Pointer;
        pfnQueryCallback: PfnPDBQueryCallback;
        out pec: EC;
        { out, cchErrMax } wszError: PChar;
        cchErrMax: NativeUInt;
        out pppdb: PPDB
        ): BOOL; static;

    class function OpenNgenPdb(
        wszNgenImage: PChar;
        wszPdbPath: PChar;
        out pec: EC;
        { out, cchErrMax } wszError: PChar;
        cchErrMax: NativeUInt;
        out pppdb: PPDB
        ): BOOL; static;

    class function ExportValidateInterface(intv: INTV): BOOL; cdecl; static;
    class function ExportValidateImplementation(impv: IMPV): BOOL; cdecl; static;

    class function QueryImplementationVersionStatic: IMPV; cdecl; static;
    class function QueryInterfaceVersionStatic: INTV; cdecl; static;

    class function SetErrorHandlerAPI(pfn: PfnPDBErrorCreate): BOOL; cdecl; static;
    class function SetPDBCloseTimeout(t: DWORDLONG): BOOL; cdecl; static;
    class function ShutDownTimeoutManager: BOOL; cdecl; static;
    class function CloseAllTimeoutPDB: BOOL; cdecl; static;

    class function RPC: BOOL; cdecl; static;

    function QueryInterfaceVersion: INTV; virtual; stdcall; abstract;
    function QueryImplementationVersion: IMPV; virtual; stdcall; abstract;
    function QueryLastError({ out, cbErrMax } szError: PAnsiChar): EC; virtual; stdcall; abstract;
    function QueryPDBName({ out, PDB_MAX_PATH } szPDB: PAnsiChar): PAnsiChar; virtual; stdcall; abstract;
    function QuerySignature: SIG; virtual; stdcall; abstract;
    function QueryAge: AGE; virtual; stdcall; abstract;
  private
    function __CreateDBI(szTarget: PChar; out ppdbi: PDBI): BOOL; virtual; stdcall; abstract;
    function __OpenDBI(szTarget, szMode: PAnsiChar; out ppdbi: PDBI): BOOL; virtual; stdcall; abstract;
    function __OpenTpi(szMode: PAnsiChar; out pptpi: PTPI): BOOL; virtual; stdcall; abstract;
    function __OpenIpi(szMode: PAnsiChar; out pptpi: PTPI): BOOL; virtual; stdcall; abstract;
  public
    function CreateDBI(szTarget: PChar; out ppdbi: PDBI): BOOL;
    function OpenDBI(szTarget, szMode: PAnsiChar; out ppdbi: PDBI): BOOL;
    function OpenTpi(szMode: PAnsiChar; out pptpi: PTPI): BOOL;
    function OpenIpi(szMode: PAnsiChar; out pptpi: PTPI): BOOL;

    function Commit: BOOL; virtual; stdcall; abstract;
  private
    function __Close: BOOL; virtual; stdcall; abstract; // Kyle 4/22/19 destructor
    function __OpenStream(szStream: PAnsiChar; out ppstream: PStream): BOOL; virtual; stdcall; abstract;
    function __GetEnumStreamNameMap(out ppenum: PEnum): BOOL; virtual; stdcall; abstract;
  public
    function Close: BOOL;
    function OpenStream(szStream: PAnsiChar; out ppstream: PStream): BOOL;
    function GetEnumStreamNameMap(out ppenum: PEnum): BOOL;
    function GetRawBytes(pfnfSnarfRawBytes: PFNfReadPDBRawBytes): BOOL; virtual; stdcall; abstract;
    function QueryPdbImplementationVersion: IMPV; virtual; stdcall; abstract;

  private
    function __OpenDBIEx(szTarget, szMode: PAnsiChar; out ppdbi: PDBI; pfn: PfnFindDebugInfoFile=nil): BOOL; virtual; stdcall; abstract;
  public
    function OpenDBIEx(szTarget, szMode: PAnsiChar; out ppdbi: PDBI; pfn: PfnFindDebugInfoFile=nil): BOOL;

    function CopyTo(szDst: PAnsiChar; dwCopyFilter, dwReserved: DWORD): BOOL; virtual; stdcall; abstract;

    //
    // support for source file data
    //
  private
    function __OpenSrc(out ppsrc: PSrc): BOOL; virtual; stdcall; abstract;
  public
    function OpenSrc(out ppsrc: PSrc): BOOL;

    function QueryLastErrorExW({ out, cchMax } wszError: PChar; cchMax: NativeUInt): EC; virtual; stdcall; abstract;
    function QueryPDBNameExW({ out, cchMax } wszPDB: PChar; cchMax: NativeUInt): PChar; virtual; stdcall; abstract;
    function QuerySignature2(psig70: PSIG70): BOOL; virtual; stdcall; abstract;
    function CopyToW(szDst: PChar; dwCopyFilter, dwReserved: DWORD): BOOL; virtual; stdcall; abstract;
    function fIsSZPDB: BOOL; virtual; stdcall; abstract;

    // Implemented only on 7.0 and above versions.
    //
  private
    function __OpenStreamW(szStream: PChar; out ppstream: PStream): BOOL; virtual; stdcall; abstract;
  public
    function OpenStreamW(szStream: PChar; out ppstream: PStream): BOOL;

    // Implemented in both 6.0 and 7.0 builds

    function CopyToW2(
        szDst:            PChar;
        dwCopyFilter:     DWORD;
        pfnCallBack:      PfnPDBCopyQueryCallback;
        pvClientContext:  Pointer
        ): BOOL; virtual; stdcall; abstract;

    class function ValidateInterface: BOOL; inline; static;

  private
    function __OpenStreamEx(szStream, szMode: PChar; out ppStream: PStream): BOOL; virtual; stdcall; abstract;
  public
    function OpenStreamEx(szStream, szMode: PChar; out ppStream: PStream): BOOL;

    // Support for PDB mapping
    function RegisterPDBMapping(wszPDBFrom, wszPDBTo: PChar): BOOL; virtual; stdcall; abstract;

    function EnablePrefetching: BOOL; virtual; stdcall; abstract;

    function FLazy: BOOL; virtual; stdcall; abstract;
    function FMinimal: BOOL; virtual; stdcall; abstract;

    function ResetGUID(pb: PBYTE; cb: DWORD): BOOL; virtual; stdcall; abstract;
  end;

  // Review: a stream directory service would be more appropriate
  // than Stream::Delete, ...

  PStream = class abstract
  public
    function QueryCb: Int32; virtual; stdcall; abstract;
    function Read(off: Int32; var pvBuf; var pcbBuf: Int32): BOOL; virtual; stdcall; abstract;
    function Write(off: Int32; const pvBuf; cbBuf: Int32): BOOL; virtual; stdcall; abstract;
    function Replace(const pvBuf; cbBuf: Int32): BOOL; virtual; stdcall; abstract;
    function Append(const pvBuf; cbBuf: Int32): BOOL; virtual; stdcall; abstract;
    function Delete: BOOL; virtual; stdcall; abstract;
  private
    function __Release: BOOL; virtual; stdcall; abstract;
  public
    function Release: BOOL;
    function Read2(off: Int32; var pvBuf; cbBuf: Int32): BOOL; virtual; stdcall; abstract;
    function Truncate(cb: Int32): BOOL; virtual; stdcall; abstract;
  end;

  PStreamImage = class abstract
  private
    class function __open(pstream: PStream; cb: Int32; out ppsi: PStreamImage): BOOL; cdecl; static;
  public
    class function open(pstream: PStream; cb: Int32; out ppsi: PStreamImage): BOOL; static;
    function size: Int32; virtual; stdcall; abstract;
    function base: Pointer; virtual; stdcall; abstract;
    function noteRead(off, cb: Int32; out ppv: Pointer): BOOL; virtual; stdcall; abstract;
    function noteWrite(off, cb: Int32; out ppv: Pointer): BOOL; virtual; stdcall; abstract;
    function writeBack: BOOL; virtual; stdcall; abstract;
  private
    function __release: BOOL; virtual; stdcall; abstract;
  public
    function release: BOOL;
  end;

  PDBI = class abstract
  public
    function QueryImplementationVersion: IMPV; virtual; stdcall; abstract;
    function QueryInterfaceVersion: INTV; virtual; stdcall; abstract;
  private
    function __OpenMod(szModule, szFile: PAnsiChar; out ppmod: PMod): BOOL; virtual; stdcall; abstract;
  public
    function OpenMod(szModule, szFile: PAnsiChar; out ppmod: PMod): BOOL;
    function DeleteMod(szModule: PAnsiChar): BOOL; virtual; stdcall; abstract;
  private
    function __QueryNextMod(_pmod: PMod; out ppmodNext: PMod): BOOL; virtual; stdcall; abstract;
    function __OpenGlobals(out ppgsi: PGSI): BOOL; virtual; stdcall; abstract;
    function __OpenPublics(out ppgsi: PGSI): BOOL; virtual; stdcall; abstract;
  public
    function QueryNextMod(_pmod: PMod; out ppmodNext: PMod): BOOL;
    function OpenGlobals(out ppgsi: PGSI): BOOL;
    function OpenPublics(out ppgsi: PGSI): BOOL;
    function AddSec(isect, flags: USHORT; off, cb: Int32): BOOL; virtual; stdcall; abstract;
    //__declspec(deprecated)
    function QueryModFromAddr(isect: USHORT; off: Int32; out ppmod: PMod;
                    out pisect: USHORT; out poff: Int32; out pcb: Int32): BOOL; virtual; stdcall; abstract;
    function QuerySecMap({ out } pb: PBYTE; var pcb: Int32): BOOL; virtual; stdcall; abstract;
    function QueryFileInfo({ out } pb: PBYTE; var pcb: Int32): BOOL; virtual; stdcall; abstract;
    procedure DumpMods; virtual; stdcall; abstract;
    procedure DumpSecContribs; virtual; stdcall; abstract;
    procedure DumpSecMap; virtual; stdcall; abstract;

  private
    function __Close: BOOL; virtual; stdcall; abstract;
  public
    function Close: BOOL;
    function AddThunkMap(poffThunkMap: PInt32; nThunks: UInt32; cbSizeOfThunk: Int32;
                    psoSectMap: PSO; nSects: UInt32;
                    isectThunkTable: USHORT; offThunkTable: Int32): BOOL; virtual; stdcall; abstract;
    function AddPublic(szPublic: PAnsiChar; isect: USHORT; off: Int32): BOOL; virtual; stdcall; abstract;
  private
    function __getEnumContrib(out ppenum: PEnum): BOOL; virtual; stdcall; abstract;
    function __QueryTypeServer(itsm: ITSM; out pptpi: PTPI): BOOL; virtual; stdcall; abstract;
  public
    function getEnumContrib(out ppenum: PEnum): BOOL;
    function QueryTypeServer(itsm: ITSM; out pptpi: PTPI): BOOL;
    function QueryItsmForTi(ti: TI; out pitsm: ITSM): BOOL; virtual; stdcall; abstract;
    function QueryNextItsm(itsm: ITSM; out inext: ITSM): BOOL; virtual; stdcall; abstract;
    function QueryLazyTypes: BOOL; virtual; stdcall; abstract;
    function SetLazyTypes(fLazy: BOOL): BOOL; virtual; stdcall; abstract;   // lazy is default and can only be turned off
    function FindTypeServers(out pec: EC; { out, cbErrMax } szError: PAnsiChar): BOOL; virtual; stdcall; abstract;
    procedure DumpTypeServers; virtual; stdcall; abstract;
  private
    function __OpenDbg(dbgtype: DBGTYPE; out ppdbg: PDbg): BOOL; virtual; stdcall; abstract;
  public
    function OpenDbg(dbgtype: DBGTYPE; out ppdbg: PDbg): BOOL;
    function QueryDbgTypes({ out } pdbgtype: PDBGTYPE; var pcDbgtype: Int32): BOOL; virtual; stdcall; abstract;
    // apis to support EnC work
    function QueryAddrForSec(out pisect: USHORT; out poff: Int32;
            imod: USHORT; cb: Int32; dwDataCrc, dwRelocCrc: DWORD): BOOL; virtual; stdcall; abstract;
    function QueryAddrForSecEx(out pisect: USHORT; out poff: Int32; imod: USHORT;
            cb: Int32; dwDataCrc, dwRelocCrc, dwCharacteristics: DWORD): BOOL; virtual; stdcall; abstract;
    function QuerySupportsEC: BOOL; virtual; stdcall; abstract;
  private
    function __QueryPdb(out pppdb: PPDB): BOOL; virtual; stdcall; abstract;
  public
    function QueryPdb(out pppdb: PPDB): BOOL;
    function AddLinkInfo(const pli: LinkInfo): BOOL; virtual; stdcall; abstract;
    function QueryLinkInfo(out pli: LinkInfo; var pcb: Int32): BOOL; virtual; stdcall; abstract;
    // new to vc6
    function QueryAge: AGE; virtual; stdcall; abstract;
    function QueryHeader: Pointer; virtual; stdcall; abstract;
    procedure FlushTypeServers; virtual; stdcall; abstract;
    function QueryTypeServerByPdb(szPdb: PAnsiChar; out pitsm: ITSM): BOOL; virtual; stdcall; abstract;

    // Long filename support
  private
    function __OpenModW(szModule, szFile: PChar; out ppmod: PMod): BOOL; virtual; stdcall; abstract;
  public
    function OpenModW(szModule, szFile: PChar; out ppmod: PMod): BOOL;
    function DeleteModW(szModule: PChar): BOOL; virtual; stdcall; abstract;
    function AddPublicW(szPublic: PChar; isect: USHORT; off: Int32; cvpsf: CV_pubsymflag_t=0): BOOL; virtual; stdcall; abstract;
    function QueryTypeServerByPdbW(szPdb: PChar; out pitsm: ITSM): BOOL; virtual; stdcall; abstract;
    function AddLinkInfoW(const pli: LinkInfoW): BOOL; virtual; stdcall; abstract;
    function AddPublic2(szPublic: PAnsiChar; isect: USHORT; off: Int32; cvpsf: CV_pubsymflag_t=0): BOOL; virtual; stdcall; abstract;
    function QueryMachineType: USHORT; virtual; stdcall; abstract;
    procedure SetMachineType(wMachine: USHORT); virtual; stdcall; abstract;
    procedure RemoveDataForRva(rva, cb: ULONG); virtual; stdcall; abstract;
    function FStripped: BOOL; virtual; stdcall; abstract;
    function QueryModFromAddr2(isect: USHORT; off: Int32; out ppmod: PMod;
                    out pisect: USHORT; out poff: Int32; out pcb: Int32;
                    out pdwCharacteristics: ULONG): BOOL; virtual; stdcall; abstract;

    // Replacement for QueryNextMod() and QueryModFromAddr()
    function QueryNoOfMods(out cMods: Int32): BOOL; virtual; stdcall; abstract;
  private
    function __QueryMods(ppmodNext: PPMod; cMods: Int32): BOOL; virtual; stdcall; abstract;
  public
    function QueryMods(ppmodNext: PPMod; cMods: Int32): BOOL;
    function QueryImodFromAddr(isect: USHORT; off: Int32; out pimod: USHORT;
                    out pisect: USHORT; out poff: Int32; out pcb: Int32;
                    out pdwCharacteristics: ULONG): BOOL; virtual; stdcall; abstract;
    function OpenModFromImod(imod: USHORT; out ppmod: PMod): BOOL; virtual; stdcall; abstract;

    function QueryHeader2(cb: Int32; { out } pb: PByte; var pcbOut: Int32): BOOL; virtual; stdcall; abstract;

    function FAddSourceMappingItem(
        szMapTo:    PChar;
        szMapFrom:  PChar;
        grFlags:    ULONG     // must be zero; no flags defn'ed as yet
        ): BOOL; virtual; stdcall; abstract;

//    typedef ::PFNNOTEPDBUSED  PFNNOTEPDBUSED;
    function FSetPfnNotePdbUsed(pvContext: Pointer; pfn: PFNNOTEPDBUSED): BOOL; virtual; stdcall; abstract;
//
    function FCTypes: BOOL; virtual; stdcall; abstract;
    function QueryFileInfo2({ out } pb: PBYTE; var pcb: Int32): BOOL; virtual; stdcall; abstract;
    function FSetPfnQueryCallback(pvContext: Pointer; pfn: PFNDBIQUERYCALLBACK): BOOL; virtual; stdcall; abstract;

//    typedef ::PFNNOTETYPEMISMATCH  PFNNOTETYPEMISMATCH;
    function FSetPfnNoteTypeMismatch(pvContext: Pointer; pfn: PFNNOTETYPEMISMATCH): BOOL; virtual; stdcall; abstract;
//
//    typedef ::PFNTMDTYPEFILTER PFNTMDTYPEFILTER;
    function FSetPfnTmdTypeFilter(pvContext: Pointer; pfn: PFNTMDTYPEFILTER): BOOL; virtual; stdcall; abstract;

    function RemovePublic(szPublic: PAnsiChar): BOOL; virtual; stdcall; abstract;

  private
    function __getEnumContrib2(out ppenum: PEnum): BOOL; virtual; stdcall; abstract;
  public
    function getEnumContrib2(out ppenum: PEnum): BOOL;

    function QueryModFromAddrEx(isect: USHORT; off: ULONG; out ppmod: PMod;
                    out pisect: USHORT; out pisectCoff: ULONG; out poff: ULONG; out pcb: ULONG;
                    out pdwCharacteristics: ULONG): BOOL; virtual; stdcall; abstract;

    function QueryImodFromAddrEx(isect: USHORT; off: ULONG; out pimod: USHORT;
                    out pisect: USHORT; out pisectCoff: ULONG; out poff: ULONG; out pcb: ULONG;
                    out pdwCharacteristics: ULONG): BOOL; virtual; stdcall; abstract;
  end;

  PMod = class abstract
  public
    function QueryInterfaceVersion: INTV; virtual; stdcall; abstract;
    function QueryImplementationVersion: IMPV; virtual; stdcall; abstract;
    function AddTypes(pbTypes: PBYTE; cb: Int32): BOOL; virtual; stdcall; abstract;
    function AddSymbols(pbSym: PBYTE; cb: Int32): BOOL; virtual; stdcall; abstract;
    function AddPublic(szPublic: PAnsiChar; isect: USHORT; off: Int32): BOOL; virtual; stdcall; abstract;
    function AddLines(szSrc: PAnsiChar; isect: USHORT; offCon, cbCon, doff: Int32;
                          lineStart: USHORT; pbCoff: PBYTE; cbCoff: Int32): BOOL; virtual; stdcall; abstract;
    function AddSecContrib(isect: USHORT; off, cb: Int32; dwCharacteristics: ULONG): BOOL; virtual; stdcall; abstract;
    function QueryCBName(out pcb: Int32): BOOL; virtual; stdcall; abstract;
    function QueryName({ out, PDB_MAX_PATH } szName: PAnsiChar; out pcb: Int32): BOOL; virtual; stdcall; abstract;
    function QuerySymbols({ out } pbSym: PBYTE; var pcb: Int32): BOOL; virtual; stdcall; abstract;
    function QueryLines({ out } pbLines: PBYTE; var pcb: Int32): BOOL; virtual; stdcall; abstract;

    function SetPvClient(pvClient: Pointer): BOOL; virtual; stdcall; abstract;
    function GetPvClient(out ppvClient: Pointer): BOOL; virtual; stdcall; abstract;
    function QueryFirstCodeSecContrib(out pisect: USHORT; out poff: Int32; out pcb: Int32; out pdwCharacteristics: ULONG): BOOL; virtual; stdcall; abstract;
//
// Make all users of this api use the real one, as this is exactly what it was
// supposed to query in the first place
//
    function QuerySecContrib(out pisect: USHORT; out poff: Int32; out pcb: Int32; out pdwCharacteristics: ULONG): BOOL; inline;

    function QueryImod(out pimod: USHORT): BOOL; virtual; stdcall; abstract;
  private
    function __QueryDBI(out ppdbi: PDBI): BOOL; virtual; stdcall; abstract;
    function __Close: BOOL; virtual; stdcall; abstract;
  public
    function QueryDBI(out ppdbi: PDBI): BOOL;
    function Close: BOOL;
    function QueryCBFile(out pcb: Int32): BOOL; virtual; stdcall; abstract;
    function QueryFile({ out, PDB_MAX_PATH } szFile: PAnsiChar; out pcb: Int32): BOOL; virtual; stdcall; abstract;
  private
    function __QueryTpi(out pptpi: PTPI): BOOL; virtual; stdcall; abstract; // return this Mod's Tpi
  public
    function QueryTpi(out pptpi: PTPI): BOOL;
    // apis to support EnC work
    function AddSecContribEx(isect: USHORT; off, cb: Int32; dwCharacteristics: ULONG; dwDataCrc, dwRelocCrc: DWORD): BOOL; virtual; stdcall; abstract;
    function QueryItsm(out pitsm: USHORT): BOOL; virtual; stdcall; abstract;
    function QuerySrcFile({ out, PDB_MAX_PATH } szFile: PAnsiChar; out pcb: Int32): BOOL; virtual; stdcall; abstract;
    function QuerySupportsEC: BOOL; virtual; stdcall; abstract;
    function QueryPdbFile({ out, PDB_MAX_PATH } szFile: PAnsiChar; out pcb: Int32): BOOL; virtual; stdcall; abstract;
    function ReplaceLines(pbLines: PBYTE; cb: Int32): BOOL; virtual; stdcall; abstract;

    // V7 line number support
  private
    function __GetEnumLines(out ppenum: PEnumLines): ByteBool; virtual; stdcall; abstract;
  public
    function GetEnumLines(out ppenum: PEnumLines): ByteBool;
    function QueryLineFlags(out pdwFlags: DWORD): ByteBool; virtual; stdcall; abstract;    // what data is present?
    function QueryFileNameInfo(
                    fileId:             DWORD;      // source file identifier
                    { out } szFilename: PChar;      // file name string
                    var pccFilename:    DWORD;      // length of string
                    out pChksumType:    DWORD;      // type of chksum
                    { out } pbChksum:   PBYTE;      // pointer to buffer for chksum data
                    var pcbChksum:      DWORD       // number of bytes of chksum (in/out)
                    ): ByteBool; virtual; stdcall; abstract;
    // Long filenames support
    function AddPublicW(szPublic: PChar; isect: USHORT; off: Int32; cvpsf: CV_pubsymflag_t=0): BOOL; virtual; stdcall; abstract;
    function AddLinesW(szSrc: PChar; isect: USHORT; offCon, cbCon, doff: Int32;
                          lineStart: ULONG; pbCoff: PBYTE; cbCoff: Int32): BOOL; virtual; stdcall; abstract;
    function QueryNameW({ out, PDB_MAX_PATH } szName: PChar; out pcb: Int32): BOOL; virtual; stdcall; abstract;
    function QueryFileW({ out, PDB_MAX_PATH } szFile: PChar; out pcb: Int32): BOOL; virtual; stdcall; abstract;
    function QuerySrcFileW({ out, PDB_MAX_PATH } szFile: PChar; out pcb: Int32): BOOL; virtual; stdcall; abstract;
    function QueryPdbFileW({ out, PDB_MAX_PATH } szFile: PChar; out pcb: Int32): BOOL; virtual; stdcall; abstract;
    function AddPublic2(szPublic: PAnsiChar; isect: USHORT; off: Int32; cvpsf: CV_pubsymflag_t=0): BOOL; virtual; stdcall; abstract;
    function InsertLines(pbLines: PBYTE; cb: Int32): BOOL; virtual; stdcall; abstract;
    function QueryLines2(cbLines: Int32; { out } pbLines: PBYTE; var pcbLines: Int32): BOOL; virtual; stdcall; abstract;
    function QueryCrossScopeExports(cb: DWORD; { out } pb: PBYTE; var pcb: DWORD): BOOL; virtual; stdcall; abstract;
    function QueryCrossScopeImports(cb: DWORD; { out } pb: PBYTE; var pcb: DWORD): BOOL; virtual; stdcall; abstract;
    function QueryInlineeLines(cb: DWORD; { out } pb: PBYTE; var pcb: DWORD): BOOL; virtual; stdcall; abstract;
    function TranslateFileId(id: DWORD; out pid: DWORD): BOOL; virtual; stdcall; abstract;
    function QueryFuncMDTokenMap(cb: DWORD; { out } pb: PBYTE; var pcb: DWORD): BOOL; virtual; stdcall; abstract;
    function QueryTypeMDTokenMap(cb: DWORD; { out } pb: PBYTE; var pcb: DWORD): BOOL; virtual; stdcall; abstract;
    function QueryMergedAssemblyInput(cb: DWORD; { out } pb: PBYTE; var pcb: DWORD): BOOL; virtual; stdcall; abstract;
    function QueryILLines(cb: DWORD; { out } pb: PBYTE; var pcb: DWORD): BOOL; virtual; stdcall; abstract;
  private
    function __GetEnumILLines(out ppenum: PEnumLines): ByteBool; virtual; stdcall; abstract;
  public
    function GetEnumILLines(out ppenum: PEnumLines): ByteBool;
    function QueryILLineFlags(out pdwFlags: DWORD): ByteBool; virtual; stdcall; abstract;
    function MergeTypes(pb: PBYTE; cb: DWORD): BOOL; virtual; stdcall; abstract;
    function IsTypeServed(index: DWORD; fID: BOOL): BOOL; virtual; stdcall; abstract;
    function QueryTypes({ out } pb: PBYTE; var pcb: DWORD): BOOL; virtual; stdcall; abstract;
    function QueryIDs({ out } pb: PBYTE; var pcb: DWORD): BOOL; virtual; stdcall; abstract;
    function QueryCVRecordForTi(index: DWORD; fID: BOOL; { out } pb: PBYTE; var pcb: DWORD): BOOL; virtual; stdcall; abstract;
    function QueryPbCVRecordForTi(index: DWORD; fID: BOOL; out ppb: PBYTE): BOOL; virtual; stdcall; abstract;
    function QueryTiForUDT(sz: PAnsiChar; fCase: BOOL; out pti: TI): BOOL; virtual; stdcall; abstract;
    function QueryCoffSymRVAs({ out } pb: PBYTE; var pcb: DWORD): BOOL; virtual; stdcall; abstract;
    function AddSecContrib2(isect: USHORT; off, isectCoff, cb, dwCharacteristics: DWORD): BOOL; virtual; stdcall; abstract;
    function AddSecContrib2Ex(isect: USHORT; off, isecfCoff, cb, dwCharacteristics, dwDataCrc, dwRelocCrc: DWORD): BOOL; virtual; stdcall; abstract;
    function AddSymbols2(pbSym: PBYTE; cb, isectCoff: DWORD): BOOL; virtual; stdcall; abstract;
    function RemoveGlobalRefs: BOOL; virtual; stdcall; abstract;
    function QuerySrcLineForUDT(ti: TI; out pszSrc: PAnsiChar; out pLine: DWORD): BOOL; virtual; stdcall; abstract;
  end;

  PTPI = class abstract
  public
    function QueryInterfaceVersion: INTV; virtual; stdcall; abstract;
    function QueryImplementationVersion: IMPV; virtual; stdcall; abstract;

    function QueryTi16ForCVRecord(pb: PBYTE; out pti: TI16): BOOL; virtual; stdcall; abstract;
    function QueryCVRecordForTi16(ti: TI16; { out } pb: PBYTE; var pcb: Int32): BOOL; virtual; stdcall; abstract;
    function QueryPbCVRecordForTi16(ti: TI16; out ppb: PBYTE): BOOL; virtual; stdcall; abstract;
    function QueryTi16Min: TI16; virtual; stdcall; abstract;
    function QueryTi16Mac: TI16; virtual; stdcall; abstract;

    function QueryCb: Int32; virtual; stdcall; abstract;
  private
    function __Close: BOOL; virtual; stdcall; abstract;
  public
    function Close: BOOL;
    function Commit: BOOL; virtual; stdcall; abstract;

    function QueryTi16ForUDT(sz: PAnsiChar; fCase: BOOL; out pti: TI16): BOOL; virtual; stdcall; abstract;
    function SupportQueryTiForUDT: BOOL; virtual; stdcall; abstract;

    // the new versions that truly take 32-bit types
    function fIs16bitTypePool: BOOL; virtual; stdcall; abstract;
    function QueryTiForUDT(sz: PAnsiChar; fCase: BOOL; pti: TI): BOOL; virtual; stdcall; abstract;
    function QueryTiForCVRecord(pb: PBYTE; out pti: TI): BOOL; virtual; stdcall; abstract;
    function QueryCVRecordForTi(ti: TI; { out } pb: PBYTE; var pcb: Int32): BOOL; virtual; stdcall; abstract;
    function QueryPbCVRecordForTi(ti: TI; out ppb: PBYTE): BOOL; virtual; stdcall; abstract;
    function QueryTiMin: TI; virtual; stdcall; abstract;
    function QueryTiMac: TI; virtual; stdcall; abstract;
    function AreTypesEqual(ti1, ti2: TI): BOOL; virtual; stdcall; abstract;
    function IsTypeServed(ti: TI): BOOL; virtual; stdcall; abstract;
    function QueryTiForUDTW(wcs: PChar; fCase: BOOL; out pti: TI): BOOL; virtual; stdcall; abstract;
    function QueryModSrcLineForUDTDefn(tiUdt: TI; out pimod: USHORT; out psrcId: NI; out pline: DWORD): BOOL; virtual; stdcall; abstract;
  end;

  PGSI = class abstract
  public
    function QueryInterfaceVersion: INTV; virtual; stdcall; abstract;
    function QueryImplementationVersion: IMPV; virtual; stdcall; abstract;
    function NextSym(pbSym: PBYTE): PBYTE; virtual; stdcall; abstract;
    function HashSym(szName: PAnsiChar; pbSym: PBYTE): PBYTE; virtual; stdcall; abstract;
    function NearestSym(isect: USHORT; off: Int32; out pdisp: Int32): PBYTE; virtual; stdcall; abstract;      //currently only supported for publics
  private
    function __Close: BOOL; virtual; stdcall; abstract;
    function __getEnumThunk(isect: USHORT; off: Int32; out ppenum: PEnumThunk): BOOL; virtual; stdcall; abstract;
  public
    function Close: BOOL;
    function getEnumThunk(isect: USHORT; off: Int32; out ppenum: PEnumThunk): BOOL;
    function OffForSym(pbSym: PBYTE): UInt32; virtual; stdcall; abstract;
    function SymForOff(off: UInt32): PBYTE; virtual; stdcall; abstract;
    function HashSymW(wcsName: PChar; pbSym: PBYTE): PBYTE; virtual; stdcall; abstract;
  private
    function __getEnumByAddr(out ppEnum: PEnumSyms): BOOL; virtual; stdcall; abstract;
  public
    function getEnumByAddr(out ppEnum: PEnumSyms): BOOL;
  end;

  PNameMap = class abstract
  private
    class function __open(ppdb: PPDB; fWrite: BOOL; out ppnm: PNameMap): BOOL; cdecl; static;
    function __close: BOOL; virtual; stdcall; abstract;
  public
    class function open(ppdb: PPDB; fWrite: BOOL; out ppnm: PNameMap): BOOL;
    function close: BOOL;
    function reinitialize: BOOL; virtual; stdcall; abstract;
    function getNi(sz: PAnsiChar; out pni: NI): BOOL; virtual; stdcall; abstract;
    function getName(ni: NI; out psz: PAnsiChar): BOOL; virtual; stdcall; abstract;
  private
    function __getEnumNameMap(out ppenum: PEnum): BOOL; virtual; stdcall; abstract;
  public
    function getEnumNameMap(out ppenum: PEnum): BOOL;
    function contains(sz: PAnsiChar; out pni: NI): BOOL; virtual; stdcall; abstract;
    function commit: BOOL; virtual; stdcall; abstract;
    function isValidNi(ni: NI): BOOL; virtual; stdcall; abstract;
    function getNiW(sz: PChar; out pni: NI): BOOL; virtual; stdcall; abstract;
    function getNameW(ni: NI; { out, pcch } szName: PChar; var pcch: NativeUInt): BOOL; virtual; stdcall; abstract;
    function containsW(sz: PChar; out pni: NI): BOOL; virtual; stdcall; abstract;
    function containsUTF8(sz: PAnsiChar; out pni: NI): BOOL; virtual; stdcall; abstract;
    function getNiUTF8(sz: PAnsiChar; out pni: NI): BOOL; virtual; stdcall; abstract;
    function getNameA(ni: NI; out psz: PAnsiChar): BOOL; virtual; stdcall; abstract;
    function getNameW2(ni: NI; out pwsz: PChar): BOOL; virtual; stdcall; abstract;
  end;

  PEnum = class abstract
  private
    procedure __release; virtual; stdcall; abstract;
  public
    procedure release;
    procedure reset; virtual; stdcall; abstract;
    function next: BOOL; virtual; stdcall; abstract;
  end;

  PEnumNameMap = class abstract (PEnum)
  public
    procedure get(out psz: PAnsiChar; out pni: NI); virtual; stdcall; abstract;
  end;

  PEnumContrib = class abstract (PEnum)
  public
    procedure get(out pimod: USHORT; out pisect: USHORT; out poff: Int32; out pcb: Int32; out pdwCharacteristics: ULONG); virtual; stdcall; abstract;
    procedure getCrcs(out pcrcData: DWORD; out pcrcReloc: DWORD); virtual; stdcall; abstract;
    function fUpdate(off, cb: Int32): ByteBool; virtual; stdcall; abstract;
    function prev: BOOL; virtual; stdcall; abstract;
  private
    function __clone(out ppEnum: PEnumContrib): BOOL; virtual; stdcall; abstract;
  public
    function clone(out ppEnum: PEnumContrib): BOOL;
    function locate(isect, off: Int32): BOOL; virtual; stdcall; abstract;
    procedure get2(out pimod: USHORT; out pisect: USHORT; out poff: DWORD; out pisectCoff: DWORD; out pcb: DWORD; out pdwCharacteristics: ULONG); virtual; stdcall; abstract;
  end;

  PEnumThunk = class abstract (PEnum)
  public
    procedure get(out pisect: USHORT; out poff: Int32; out pcb: Int32); virtual; stdcall; abstract;
  end;

  PEnumSyms = class abstract (PEnum)
  public
    procedure get(out ppbSym: PBYTE); virtual; stdcall; abstract;
    function prev: BOOL; virtual; stdcall; abstract;
  private
    function __clone(out ppEnum: PEnumSyms): BOOL; virtual; stdcall; abstract;
  public
    function clone(out ppEnum: PEnumSyms): BOOL;
    function locate(isect, off: Int32): BOOL; virtual; stdcall; abstract;
  end;

  PEnumLines = class abstract (PEnum)
  public
    //
    // Blocks of lines are always in offset order, lines within blocks are also ordered by offset
    //
    function getLines(
        out fileId:   DWORD;    // id for the filename
        out poffset:  DWORD;    // offset part of address
        out pseg:     WORD;     // segment part of address
        out pcb:      DWORD;    // count of bytes of code described by this block
        var pcLines:  DWORD;    // number of lines (in/out)
        out pLines:   CV_Line_t // pointer to buffer for line info
        ): ByteBool; virtual; stdcall; abstract;
    function getLinesColumns(
        out fileId:   DWORD;          // id for the filename
        out poffset:  DWORD;          // offset part of address
        out pseg:     WORD;           // segment part of address
        out pcb:      DWORD;          // count of bytes of code described by this block
        var pcLines:  DWORD;          // number of lines (in/out)
        out pLines:   CV_Line_t;      // pointer to buffer for line info
        out pColumns: CV_Column_t     // pointer to buffer for column info
        ): ByteBool; virtual; stdcall; abstract;
  private
    function __clone(
        out ppEnum: PEnumLines      // return pointer to the clone
        ): ByteBool; virtual; stdcall; abstract;
  public
    function clone(
        out ppEnum: PEnumLines
        ): ByteBool;
  end;

//
// interface to use to widen type indices from 16 to 32 bits
// and store the results in a new location.
//
  PWidenTi = class abstract
  private
    class function
    __fCreate (
        out ppwt: PWidenTi;
        cTypeInitialCache: UInt32=256;
        fNB10Syms: BOOL=BOOL(wtiSymsNB09)
        ): BOOL; cdecl; static;

    procedure
    __release; virtual; stdcall; abstract;
  public
    class function
    fCreate (
        out ppwt: PWidenTi;
        cTypeInitialCache: UInt32=256;
        fNB10Syms: BOOL=BOOL(wtiSymsNB09)
        ): BOOL;

    procedure
    release;

    function
    pTypeWidenTi(ti16: TI; pb: PBYTE { PTYPTYPE }): PBYTE { PTYPTYPE }; virtual; stdcall; abstract;

    function
    pSymWidenTi(pb: PBYTE { SYMTYPE }): PBYTE { PSYMTYPE }; virtual; stdcall; abstract;

    function
    fTypeWidenTiNoCache(pbTypeDst, pbTypeSrc: PBYTE; var cbDst: Int32): BOOL; virtual; stdcall; abstract;

    function
    fSymWidenTiNoCache (pbSymDst, pbSymSrc: PBYTE; var cbDst: Int32): BOOL; virtual; stdcall; abstract;

    function
    fTypeNeedsWidening (pbType: PBYTE): BOOL; virtual; stdcall; abstract;

    function
    fSymNeedsWidening (pbSym: PBYTE): BOOL; virtual; stdcall; abstract;

    function
    freeRecord (pv: Pointer): BOOL; virtual; stdcall; abstract;

    // symbol block converters/query.  symbols start at doff from pbSymIn,
    // converted symbols will go at sci.pbSyms + doff, cbSyms are all including
    // doff.
    function
    fQuerySymConvertInfo (
        out sciOut: SymConvertInfo;
        pbSym:      PBYTE;
        cbSym:      Int32;
        doff:       Int32=0
        ): BOOL; virtual; stdcall; abstract;

    function
    fConvertSymbolBlock (
        out sciOut: SymConvertInfo;
        pbSymIn:    PBYTE;
        cbSymIn:    Int32;
        doff:       Int32=0
        ): BOOL; virtual; stdcall; abstract;
  end;

// interface for managing Dbg data
  PDbg = class abstract
  private
    // close Dbg Interface
    function __Close: BOOL; virtual; stdcall; abstract;
  public
    function Close: BOOL;
    // return number of elements (NOT bytes)
    function QuerySize: Int32; virtual; stdcall; abstract;
    // reset enumeration index
    procedure Reset; virtual; stdcall; abstract;
    // skip next celt elements (move enumeration index)
    function Skip(celt: ULONG): BOOL; virtual; stdcall; abstract;
    // query next celt elements into user-supplied buffer
    function QueryNext(celt: ULONG; { out } rgelt: Pointer): BOOL; virtual; stdcall; abstract;
    // search for an element and fill in the entire struct given a field.
    // Only supported for the following debug types and fields:
    // DBG_FPO              'ulOffStart' field of FPO_DATA
    // DBG_FUNC             'StartingAddress' field of IMAGE_FUNCTION_ENTRY
    // DBG_OMAP             'rva' field of OMAP
    function Find({ var } pelt: Pointer): BOOL; virtual; stdcall; abstract;
    // remove debug data
    function Clear: BOOL; virtual; stdcall; abstract;
    // append celt elements
    function Append(celt: ULONG; rgelt: Pointer): BOOL; virtual; stdcall; abstract;
    // replace next celt elements
    function ReplaceNext(celt: ULONG; rgelt: Pointer): BOOL; virtual; stdcall; abstract;
    // create a clone of this interface
    function Clone(out ppDbg: PDbg): BOOL; virtual; stdcall; abstract;

    // return size of one element
    function QueryElementSize: Int32; virtual; stdcall; abstract;
  end;

  PSrc = class abstract
  private
    // close and commit the changes (when open for write)
    function
    __Close: ByteBool; virtual; stdcall; abstract;
  public
    function
    Close: ByteBool;

    // add a source file or file-ette
    function
    Add(psrcheader: PCSrcHeader; pvData: Pointer): ByteBool; virtual; stdcall; abstract;

    // remove a file or file-ette or all of the injected code for
    // one particular compiland (using the object file name)
    function
    Remove(szFile: SZ_CONST): ByteBool; virtual; stdcall; abstract;

    // query and copy the header/control data to the output buffer
    function
    QueryByName(szFile: SZ_CONST; { out } psrcheaderOut: PSrcHeaderOut): ByteBool; virtual; stdcall; abstract;

    // copy the file data (the size of the buffer is in the SrcHeaderOut
    // structure) to the output buffer.
    function
    GetData(pcsrcheader: PCSrcHeaderOut; { out } pvData: Pointer): ByteBool; virtual; stdcall; abstract;

    // create an enumerator to traverse all of the files included
    // in the mapping.
    function
    GetEnum(out ppenum: PEnumSrc): ByteBool; virtual; stdcall; abstract;

    // Get the header block (master header) of the Src data.
    // Includes age, time stamp, version, and size of the master stream
    function GetHeaderBlock(out shb: SrcHeaderBlock): ByteBool; virtual; stdcall; abstract;
    function RemoveW(wcsFile: PChar): ByteBool; virtual; stdcall; abstract;
    function QueryByNameW(wcsFile: PChar; { out } psrcheaderOut: PSrcHeaderOut): ByteBool; virtual; stdcall; abstract;
    function AddW(psrcheader: PCSrcHeaderW; pvData: Pointer): ByteBool; virtual; stdcall; abstract;
  end;

  PEnumSrc = class abstract (PEnum)
  public
    procedure get(ppcsrcheader: PCSrcHeaderOut); virtual; stdcall; abstract;
  end;

  PSrcHash = class abstract
  public type
    // Various types we need
    //

    // Tri-state return type
    //
{$Z4} {$SCOPEDENUMS ON}
    TriState = (
      Yes,
      No,
      Maybe
    );

    // Hash identifier
    //
    HID = (
      None,
      MD5,
      SHA1,
      SHA256,
      Max
    );
{$SCOPEDENUMS OFF} {$Z1}

    // Define machine independent types for storage of HashID and size_t
    //
    HashID_t = Int32;
    CbHash_t = UInt32;

  private
    // Create a SrcHash object with the usual two-stage construction technique
    //
    class function
    __FCreateSrcHash(out psh: PSrcHash; hid: HID): ByteBool; cdecl; static;
  public
    class function
    FCreateSrcHash(out psh: PSrcHash; hid: HID): ByteBool; static;

    // Accumulate more bytes into the hash
    //
    function
    FHashBuffer(pvBuf: PCV; cbBuf: NativeUInt): ByteBool; virtual; stdcall; abstract;

    // Query the hash id
    //
    function
    HashID: HashID_t; virtual; stdcall; abstract;

    // Query the size of the hash
    //
    function
    CbHash: CbHash_t; virtual; stdcall; abstract;

    // Copy the hash bytes to the client buffer
    //
    function
    FGetHash({ out } pvHash: PV; cbHash: CbHash_t): ByteBool; virtual; stdcall; abstract;

    // Verify the incoming hash against a target buffer of bytes
    // returning a yes it matches, no it doesn't, or indeterminate.
    //
    function
    TsVerifyHash(
        hid: HID;
        cbHash: CbHash_t;
        pvHash: PCV;
        cbBuf: NativeUInt;
        pvBuf: PCV
        ): TriState; virtual; stdcall; abstract;

    // Reset this object to pristine condition
    //
    function
    FReset: ByteBool; virtual; stdcall; abstract;

  private
    // Close off and release this object
    //
    procedure
    __Close; virtual; stdcall; abstract;
  public
    procedure
    Close;
  end;

const
  cbNil   = Int32(-1);
  tsNil   = PTPI(nil);
  tiNil   = TI(0);
  imodNil = USHORT(-1);

  pdbFSCompress         = 'C';
  pdbVC120              = 'L';
  pdbTypeAppend         = 'a';
  pdbGetRecordsOnly     = 'c';
  pdbFullBuild          = 'f';
  pdbGetTiOnly          = 'i';
  pdbNoTypeMergeLink    = 'l';
  pdbTypeMismatchesLink = 'm';
  pdbNewNameMap         = 'n';
  pdbMinimalLink        = 'o';
  pdbRead               = 'r';
  pdbWriteShared        = 's';
  pdbCTypes             = 't';
  pdbWrite              = 'w';
  pdbExclusive          = 'x';
  pdbRepro              = 'z';

implementation

uses
  System.SysUtils, ThiscallInterceptor;

var
  PDBInterceptor,
  DBIInterceptor,
  TPIInterceptor,
  StreamInterceptor,
  EnumNameMapInterceptor,
  SrcInterceptor,
  StreamImageInterceptor,
  ModInterceptor,
  GSIInterceptor,
  EnumContribInterceptor,
  DbgInterceptor,
  EnumLinesInterceptor,
  EnumThunkInterceptor,
  EnumSymsInterceptor,
  NameMapInterceptor,
  WidenTiInterceptor,
  SrcHashInterceptor: TThiscallVirtualInterceptor;

const
  PDBDLL = 'mspdbcore.dll';

function LinkInfo.Ver: VerLinkInfo;
begin
  Result := _ver;
end;

function LinkInfo.Cb: ULONG;
begin
  Result := _cb;
end;

function LinkInfo.SzCwd: PAnsiChar;
begin
{$POINTERMATH ON}
  Result := @PByte(@Self)[offszCwd];
{$POINTERMATH OFF}
end;

function LinkInfo.SzCommand: PAnsiChar;
begin
{$POINTERMATH ON}
  Result := @PByte(@Self)[offszCommand];
{$POINTERMATH OFF}
end;

function LinkInfo.SzOutFile: PAnsiChar;
begin
{$POINTERMATH ON}
  Result := @PByte(SzCommand)[ichOutFile];
{$POINTERMATH OFF}
end;

class function LinkInfo.Create: LinkInfo;
begin
  with Result do begin
    _cb := 0;
    _ver := VerLinkInfo.Cur;
    offszCwd := 0;
    offszCommand := 0;
    ichOutfile := 0;
    offszLibs := 0;
  end;
end;

function LinkInfo.SzLibs: PAnsiChar;
begin
{$POINTERMATH ON}
  Result := @PByte(@Self)[offszLibs];
{$POINTERMATH OFF}
end;

function LinkInfoW.Ver: VerLinkInfo;
begin
  Result := LI.Ver;
end;

function LinkInfoW.Cb: ULONG;
begin
  Result := LI.Cb;
end;

function LinkInfoW.SzCwdW: PChar;
begin
{$POINTERMATH ON}
  Result := @PByte(@Self)[LI.offszCwd];
{$POINTERMATH OFF}
end;

function LinkInfoW.SzCommandW: PChar;
begin
{$POINTERMATH ON}
  Result := @PByte(@Self)[LI.offszCommand];
{$POINTERMATH OFF}
end;

function LinkInfoW.SzOutFileW: PChar;
begin
{$POINTERMATH ON}
  Result := @PByte(LI.SzCommand)[LI.ichOutFile];
{$POINTERMATH OFF}
end;

class function LinkInfoW.Create: LinkInfoW;
begin
  Result.LI := LinkInfo.Create;
end;

function LinkInfoW.SzLibsW: PChar;
begin
{$POINTERMATH ON}
  Result := @PByte(@Self)[LI.offszLibs];
{$POINTERMATH OFF}
end;

class function PPDB.__Open2W(
    wszPDB: PChar;
    szMode: PAnsiChar;
    out pec: EC;
    { out, cchErrMax } wszError: PChar;
    cchErrMax: NativeUInt;
    out pppdb: PPDB
    ): BOOL; cdecl; external PDBDLL name 'PDBOpen2W';

class function PPDB.__OpenEx2W(
    wszPDB: PChar;
    szMode: PAnsiChar;
    cbPage: Integer;
    out pec: EC;
    { out, cchErrMax } wszError: PChar;
    cchErrMax: NativeUInt;
    out pppdb: PPDB
    ): BOOL; cdecl; external PDBDLL name 'PDBOpenEx2W';

class function PPDB.__OpenValidate4(
    wszPDB: PChar;
    szMode: PAnsiChar;
    _pcsig70: PCSIG70;
    _sig: SIG;
    _age: AGE;
    out pec: EC;
    { out, cchErrMax } wszError: PChar;
    cchErrMax: NativeUInt;
    out pppdb: PPDB
    ): BOOL; cdecl; external PDBDLL name 'PDBOpenValidate4';

class function PPDB.__OpenValidate5(
    wszExecutable: PChar;
    wszSearchPath: PChar;
    pvClient: Pointer;
    pfnQueryCallback: PfnPDBQueryCallback;
    out pec: EC;
    { out, cchErrMax } wszError: PChar;
    cchErrMax: NativeUInt;
    out pppdb: PPDB
    ): BOOL; cdecl; external PDBDLL name 'PDBOpenValidate5';

class function PPDB.__OpenNgenPdb(
    wszNgenImage: PChar;
    wszPdbPath: PChar;
    out pec: EC;
    { out, cchErrMax } wszError: PChar;
    cchErrMax: NativeUInt;
    out pppdb: PPDB
    ): BOOL; cdecl; external PDBDLL name 'PDBOpenNgenPdb';

class function PPDB.Open2W(
    wszPDB: PChar;
    szMode: PAnsiChar;
    out pec: EC;
    { out, cchErrMax } wszError: PChar;
    cchErrMax: NativeUInt;
    out pppdb: PPDB
    ): BOOL;
begin
  Result := __Open2W(wszPDB, szMode, pec, wszError, cchErrMax, pppdb);
  pppdb := PPDB(PDBInterceptor.AddObjThunk(pppdb));
end;

class function PPDB.OpenEx2W(
    wszPDB: PChar;
    szMode: PAnsiChar;
    cbPage: Integer;
    out pec: EC;
    { out, cchErrMax } wszError: PChar;
    cchErrMax: NativeUInt;
    out pppdb: PPDB
    ): BOOL;
begin
  Result := __OpenEx2W(wszPDB, szMode, cbPage, pec, wszError, cchErrMax, pppdb);
  pppdb := PPDB(PDBInterceptor.AddObjThunk(pppdb));
end;

class function PPDB.OpenValidate4(
    wszPDB: PChar;
    szMode: PAnsiChar;
    _pcsig70: PCSIG70;
    _sig: SIG;
    _age: AGE;
    out pec: EC;
    { out, cchErrMax } wszError: PChar;
    cchErrMax: NativeUInt;
    out pppdb: PPDB
    ): BOOL;
begin
  Result := __OpenValidate4(wszPDB, szMode, _pcsig70, _sig, _age, pec, wszError, cchErrMax, pppdb);
  pppdb := PPDB(PDBInterceptor.AddObjThunk(pppdb));
end;

class function PPDB.OpenValidate5(
    wszExecutable: PChar;
    wszSearchPath: PChar;
    pvClient: Pointer;
    pfnQueryCallback: PfnPDBQueryCallback;
    out pec: EC;
    { out, cchErrMax } wszError: PChar;
    cchErrMax: NativeUInt;
    out pppdb: PPDB
    ): BOOL;
begin
  Result := __OpenValidate5(wszExecutable, wszSearchPath, pvClient, pfnQueryCallback, pec, wszError, cchErrMax, pppdb);
  pppdb := PPDB(PDBInterceptor.AddObjThunk(pppdb));
end;

class function PPDB.OpenNgenPdb(
    wszNgenImage: PChar;
    wszPdbPath: PChar;
    out pec: EC;
    { out, cchErrMax } wszError: PChar;
    cchErrMax: NativeUInt;
    out pppdb: PPDB
    ): BOOL;
begin
  Result := __OpenNgenPdb(wszNgenImage, wszPdbPath, pec, wszError, cchErrMax, pppdb);
  pppdb := PPDB(PDBInterceptor.AddObjThunk(pppdb));
end;

function PPDB.CreateDBI(szTarget: PChar; out ppdbi: PDBI): BOOL;
begin
  Result := __CreateDBI(szTarget, ppdbi);
  ppdbi := PDBI(DBIInterceptor.AddObjThunk(ppdbi));
end;

function PPDB.OpenDBI(szTarget, szMode: PAnsiChar; out ppdbi: PDBI): BOOL;
begin
  Result := __OpenDBI(szTarget, szMode, ppdbi);
  ppdbi := PDBI(DBIInterceptor.AddObjThunk(ppdbi));
end;

function PPDB.OpenTpi(szMode: PAnsiChar; out pptpi: PTPI): BOOL;
begin
  Result := __OpenTpi(szMode, pptpi);
  pptpi := PTPI(TPIInterceptor.AddObjThunk(pptpi));
end;

function PPDB.OpenIpi(szMode: PAnsiChar; out pptpi: PTPI): BOOL;
begin
  Result := __OpenIpi(szMode, pptpi);
  pptpi := PTPI(TPIInterceptor.AddObjThunk(pptpi));
end;

function PPDB.Close: BOOL;
begin
  Result := __Close;
  TThiscallVirtualInterceptor.RemoveObjThunk(Self);
end;

function PPDB.OpenStream(szStream: PAnsiChar; out ppstream: PStream): BOOL;
begin
  Result := __OpenStream(szStream, ppstream);
  ppstream := PStream(StreamInterceptor.AddObjThunk(ppstream));
end;

function PPDB.GetEnumStreamNameMap(out ppenum: PEnum): BOOL;
begin
  Result := __GetEnumStreamNameMap(ppenum);
  ppenum := PEnum(EnumNameMapInterceptor.AddObjThunk(ppenum));
end;

function PPDB.OpenDBIEx(szTarget, szMode: PAnsiChar; out ppdbi: PDBI; pfn: PfnFindDebugInfoFile=nil): BOOL;
begin
  Result := __OpenDBIEx(szTarget, szMode, ppdbi, pfn);
  ppdbi := PDBI(DBIInterceptor.AddObjThunk(ppdbi));
end;

function PPDB.OpenSrc(out ppsrc: PSrc): BOOL;
begin
  Result := __OpenSrc(ppsrc);
  ppsrc := PSrc(SrcInterceptor.AddObjThunk(ppsrc));
end;

function PPDB.OpenStreamW(szStream: PChar; out ppstream: PStream): BOOL;
begin
  Result := __OpenStreamW(szStream, ppstream);
  ppstream := PStream(StreamInterceptor.AddObjThunk(ppstream));
end;

function PPDB.OpenStreamEx(szStream, szMode: PChar; out ppStream: PStream): BOOL;
begin
  Result := __OpenStreamEx(szStream, szMode, ppstream);
  ppstream := PStream(StreamInterceptor.AddObjThunk(ppstream));
end;

// a dbi client should never call PDBExportValidateInterface directly - use PDBValidateInterface
class function PPDB.ExportValidateInterface(intv: INTV): BOOL; cdecl; external PDBDLL name 'PDBExportValidateInterface';
class function PPDB.ExportValidateImplementation(impv: IMPV): BOOL; cdecl; external PDBDLL name 'PDBExportValidateImplementation';

class function PPDB.QueryImplementationVersionStatic: IMPV; cdecl; external PDBDLL name 'PDBQueryImplementationVersionStatic';
class function PPDB.QueryInterfaceVersionStatic: INTV; cdecl; external PDBDLL name 'PDBQueryInterfaceVersionStatic';

class function PPDB.SetErrorHandlerAPI(pfn: PfnPDBErrorCreate): BOOL; cdecl; external PDBDLL name '?SetErrorHandlerAPI@PDB@@SAHP6APAUIPDBError@@PAU1@@Z@Z';
class function PPDB.SetPDBCloseTimeout(t: DWORDLONG): BOOL; cdecl; external PDBDLL name '?SetPDBCloseTimeout@PDB@@SAH_K@Z';
class function PPDB.ShutDownTimeoutManager: BOOL; cdecl; external PDBDLL name '?ShutDownTimeoutManager@PDB@@SAHXZ';
class function PPDB.CloseAllTimeoutPDB: BOOL; cdecl; external PDBDLL name '?CloseAllTimeoutPDB@PDB@@SAHXZ';

class function PPDB.RPC: BOOL; cdecl; external PDBDLL name 'PDBRPC';

class function PPDB.ValidateInterface: BOOL;
begin
  Result := ExportValidateInterface(INTV.Current);
end;

function PStream.Release: BOOL;
begin
  Result := __Release;
  TThiscallVirtualInterceptor.RemoveObjThunk(Self);
end;

function PStreamImage.release: BOOL;
begin
  Result := __release;
  TThiscallVirtualInterceptor.RemoveObjThunk(Self);
end;

function PDBI.getEnumContrib(out ppenum: PEnum): BOOL;
begin
  Result := __getEnumContrib(ppenum);
  ppenum := PEnumContrib(EnumContribInterceptor.AddObjThunk(ppenum));
end;

function PDBI.QueryTypeServer(itsm: ITSM; out pptpi: PTPI): BOOL;
begin
  Result := __QueryTypeServer(itsm, pptpi);
  pptpi := PTPI(TPIInterceptor.AddObjThunk(pptpi));
end;

function PDBI.OpenDbg(dbgtype: DBGTYPE; out ppdbg: PDbg): BOOL;
begin
  Result := __OpenDbg(dbgtype, ppdbg);
  ppdbg := PDbg(DbgInterceptor.AddObjThunk(ppdbg));
end;

function PDBI.QueryPdb(out pppdb: PPDB): BOOL;
begin
  Result := __QueryPdb(pppdb);
  pppdb := PPDB(PDBInterceptor.AddObjThunk(pppdb));
end;

function PDBI.OpenModW(szModule, szFile: PChar; out ppmod: PMod): BOOL;
begin
  Result := __OpenModW(szModule, szFile, ppmod);
  ppmod := PMod(ModInterceptor.AddObjThunk(ppmod));
end;

function PDBI.QueryMods(ppmodNext: PPMod; cMods: Int32): BOOL;
var
  I: Integer;
begin
{$POINTERMATH ON}
  Result := __QueryMods(ppmodNext, cMods);
  for I := 0 to cMods - 1 do
    ppmodNext[I] := PMod(ModInterceptor.AddObjThunk(ppmodNext[I]));
{$POINTERMATH OFF}
end;

function PDBI.getEnumContrib2(out ppenum: PEnum): BOOL;
begin
  Result := __getEnumContrib2(ppenum);
  ppenum := PEnumContrib(EnumContribInterceptor.AddObjThunk(ppenum));
end;

function PMod.QueryDBI(out ppdbi: PDBI): BOOL;
begin
  Result := __QueryDBI(ppdbi);
  ppdbi := PDBI(DBIInterceptor.AddObjThunk(ppdbi));
end;

function PMod.Close: BOOL;
begin
  Result := __Close;
  TThiscallVirtualInterceptor.RemoveObjThunk(Self);
end;

function PMod.QueryTpi(out pptpi: PTPI): BOOL;
begin
  Result := __QueryTpi(pptpi);
  pptpi := PTPI(TPIInterceptor.AddObjThunk(pptpi));
end;

function PMod.GetEnumLines(out ppenum: PEnumLines): ByteBool;
begin
  Result := __GetEnumLines(ppenum);
  ppenum := PEnumLines(EnumLinesInterceptor.AddObjThunk(ppenum));
end;

function PMod.GetEnumILLines(out ppenum: PEnumLines): ByteBool;
begin
  Result := __GetEnumILLines(ppenum);
  ppenum := PEnumLines(EnumLinesInterceptor.AddObjThunk(ppenum));
end;

function PTPI.Close: BOOL;
begin
  Result := __Close;
  TThiscallVirtualInterceptor.RemoveObjThunk(Self);
end;

function PGSI.Close: BOOL;
begin
  Result := __Close;
  TThiscallVirtualInterceptor.RemoveObjThunk(Self);
end;

function PGSI.getEnumThunk(isect: USHORT; off: Int32; out ppenum: PEnumThunk): BOOL;
begin
  Result := __getEnumThunk(isect, off, ppenum);
  ppenum := PEnumThunk(EnumThunkInterceptor.AddObjThunk(ppenum));
end;

function PGSI.getEnumByAddr(out ppEnum: PEnumSyms): BOOL;
begin
  Result := __getEnumByAddr(ppenum);
  ppenum := PEnumSyms(EnumSymsInterceptor.AddObjThunk(ppenum));
end;

class function PNameMap.open(ppdb: PPDB; fWrite: BOOL; out ppnm: PNameMap): BOOL;
begin
  Result := __open(ppdb, fWrite, ppnm);
  ppnm := PNameMap(NameMapInterceptor.AddObjThunk(ppnm));
end;

function PNameMap.close: BOOL;
begin
  Result := __close;
  TThiscallVirtualInterceptor.RemoveObjThunk(Self);
end;

class function PStreamImage.__open(pstream: PStream; cb: Int32; out ppsi: PStreamImage): BOOL; cdecl; external PDBDLL name '?open@StreamImage@@SAHPAUStream@@JPAPAU1@@Z';

class function PStreamImage.open(pstream: PStream; cb: Int32; out ppsi: PStreamImage): BOOL;
begin
  Result := __open(pstream, cb, ppsi);
  ppsi := PStreamImage(StreamImageInterceptor.AddObjThunk(ppsi));
end;

function PDBI.OpenMod(szModule, szFile: PAnsiChar; out ppmod: PMod): BOOL;
begin
  Result := __OpenMod(szModule, szFile, ppmod);
  ppmod := PMod(ModInterceptor.AddObjThunk(ppmod));
end;

function PDBI.QueryNextMod(_pmod: PMod; out ppmodNext: PMod): BOOL;
begin
  Result := __QueryNextMod(_pmod, ppmodNext);
  ppmodNext := PMod(ModInterceptor.AddObjThunk(ppmodNext));
end;

function PDBI.Close: BOOL;
begin
  Result := __Close;
  TThiscallVirtualInterceptor.RemoveObjThunk(Self);
end;

function PDBI.OpenGlobals(out ppgsi: PGSI): BOOL;
begin
  Result := __OpenGlobals(ppgsi);
  ppgsi := PGSI(GSIInterceptor.AddObjThunk(ppgsi));
end;

function PDBI.OpenPublics(out ppgsi: PGSI): BOOL;
begin
  Result := __OpenPublics(ppgsi);
  ppgsi := PGSI(GSIInterceptor.AddObjThunk(ppgsi));
end;

function PMod.QuerySecContrib(out pisect: USHORT; out poff: Int32; out pcb: Int32; out pdwCharacteristics: ULONG): BOOL;
begin
  Result := QueryFirstCodeSecContrib(pisect, poff, pcb, pdwCharacteristics);
end;

class function PNameMap.__open(ppdb: PPDB; fWrite: BOOL; out ppnm: PNameMap): BOOL; cdecl; external PDBDLL name 'NameMapOpen';

function PNameMap.getEnumNameMap(out ppenum: PEnum): BOOL;
begin
  Result := __getEnumNameMap(ppenum);
  ppenum := PEnum(EnumNameMapInterceptor.AddObjThunk(ppenum));
end;

procedure PEnum.release;
begin
  __release;
  TThiscallVirtualInterceptor.RemoveObjThunk(Self);
end;

function PEnumContrib.clone(out ppEnum: PEnumContrib): BOOL;
begin
  Result := __clone(ppEnum);
  ppEnum := PEnumContrib(EnumContribInterceptor.AddObjThunk(ppEnum));
end;

function PEnumSyms.clone(out ppEnum: PEnumSyms): BOOL;
begin
  Result := __clone(ppEnum);
  ppEnum := PEnumSyms(EnumSymsInterceptor.AddObjThunk(ppEnum));
end;

function
PEnumLines.clone(
  out ppEnum: PEnumLines
  ): ByteBool;
begin
  Result := __clone(ppEnum);
  ppEnum := PEnumLines(EnumLinesInterceptor.AddObjThunk(ppEnum));
end;


class function
PWidenTi.__fCreate (
    out ppwt: PWidenTi;
    cTypeInitialCache: UInt32=256;
    fNB10Syms: BOOL=BOOL(wtiSymsNB09)
    ): BOOL; cdecl; external PDBDLL name '?fCreate@WidenTi@@SAHAAPAU1@IH@Z';

class function
PWidenTi.fCreate (
    out ppwt: PWidenTi;
    cTypeInitialCache: UInt32=256;
    fNB10Syms: BOOL=BOOL(wtiSymsNB09)
    ): BOOL;
begin
  Result := __fCreate(ppwt, cTypeInitialCache, fNB10Syms);
  ppwt := PWidenTi(WidenTiInterceptor.AddObjThunk(ppwt));
end;

procedure
PWidenTi.release;
begin
  __release;
  TThiscallVirtualInterceptor.RemoveObjThunk(Self);
end;

function PDbg.Close: BOOL;
begin
  Result := __Close;
  TThiscallVirtualInterceptor.RemoveObjThunk(Self);
end;

function
PSrc.Close: ByteBool;
begin
  Result := __Close;
  TThiscallVirtualInterceptor.RemoveObjThunk(Self);
end;

class function
PSrcHash.__FCreateSrcHash(out psh: PSrcHash; hid: HID): ByteBool; cdecl; external PDBDLL name '?FCreateSrcHash@SrcHash@@SA_NAAPAU1@W4HID@1@@Z';

class function
PSrcHash.FCreateSrcHash(out psh: PSrcHash; hid: HID): ByteBool;
begin
  Result := __FCreateSrcHash(psh, hid);
  psh := PSrcHash(SrcHashInterceptor.AddObjThunk(psh));
end;

procedure
PSrcHash.Close;
begin
  __Close;
  TThiscallVirtualInterceptor.RemoveObjThunk(Self);
end;

procedure InitThunks;
begin
  PDBInterceptor := TThiscallVirtualInterceptor.Create(PPDB);
  DBIInterceptor := TThiscallVirtualInterceptor.Create(PDBI);
  TPIInterceptor := TThiscallVirtualInterceptor.Create(PTPI);
  StreamInterceptor := TThiscallVirtualInterceptor.Create(PStream);
  EnumNameMapInterceptor := TThiscallVirtualInterceptor.Create(PEnumNameMap);
  SrcInterceptor := TThiscallVirtualInterceptor.Create(PSrc);
  StreamImageInterceptor := TThiscallVirtualInterceptor.Create(PStreamImage);
  ModInterceptor := TThiscallVirtualInterceptor.Create(PMod);
  GSIInterceptor := TThiscallVirtualInterceptor.Create(PGSI);
  EnumContribInterceptor := TThiscallVirtualInterceptor.Create(PEnumContrib);
  DbgInterceptor := TThiscallVirtualInterceptor.Create(PDbg);
  EnumLinesInterceptor := TThiscallVirtualInterceptor.Create(PEnumLines);
  EnumThunkInterceptor := TThiscallVirtualInterceptor.Create(PEnumThunk);
  EnumSymsInterceptor := TThiscallVirtualInterceptor.Create(PEnumSyms);
  NameMapInterceptor := TThiscallVirtualInterceptor.Create(PNameMap);
  WidenTiInterceptor := TThiscallVirtualInterceptor.Create(PWidenTi);
  SrcHashInterceptor := TThiscallVirtualInterceptor.Create(PSrcHash);
end;

procedure FinitThunks;
begin
  FreeAndNil(PDBInterceptor);
  FreeAndNil(DBIInterceptor);
  FreeAndNil(TPIInterceptor);
  FreeAndNil(StreamInterceptor);
  FreeAndNil(EnumNameMapInterceptor);
  FreeAndNil(SrcInterceptor);
  FreeAndNil(StreamImageInterceptor);
  FreeAndNil(ModInterceptor);
  FreeAndNil(GSIInterceptor);
  FreeAndNil(EnumContribInterceptor);
  FreeAndNil(DbgInterceptor);
  FreeAndNil(EnumLinesInterceptor);
  FreeAndNil(EnumThunkInterceptor);
  FreeAndNil(EnumSymsInterceptor);
  FreeAndNil(NameMapInterceptor);
  FreeAndNil(WidenTiInterceptor);
  FreeAndNil(SrcHashInterceptor);
end;

initialization
  InitThunks;

finalization
  FinitThunks;

end.
