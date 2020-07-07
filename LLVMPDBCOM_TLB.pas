unit LLVMPDBCOM_TLB;

// ************************************************************************ //
// WARNING                                                                    
// -------                                                                    
// The types declared in this file were generated from data read from a       
// Type Library. If this type library is explicitly or indirectly (via        
// another type library referring to this type library) re-imported, or the   
// 'Refresh' command of the Type Library Editor activated while editing the   
// Type Library, the contents of this file will be regenerated and all        
// manual modifications will be lost.                                         
// ************************************************************************ //

// $Rev: 98336 $
// File generated on 7/1/2020 4:32:19 PM from Type Library described below.

// ************************************************************************  //
// Type Lib: C:\pw\TDSToPDB\Win32\Debug\LLVMPDBCOM.dll (1)
// LIBID: {1AD0D8AA-7E3A-40B0-B209-05A677AF6131}
// LCID: 0
// Helpfile: 
// HelpString: 
// DepndLst: 
//   (1) v2.0 stdole, (C:\Windows\SysWOW64\stdole2.tlb)
// SYS_KIND: SYS_WIN32
// Errors:
//   Hint: Parameter 'File' of ILLVMDbiStreamBuilder.addModuleSourceFile changed to 'File_'
//   Hint: Parameter 'Type' of ILLVMDbiStreamBuilder.addDbgStream changed to 'Type_'
//   Hint: Parameter 'Type' of ILLVMTpiStreamBuilder.addTypeRecord changed to 'Type_'
//   Hint: Parameter 'Type' of ILLVMPDBUtilities.hashTypeRecord changed to 'Type_'
// ************************************************************************ //
{$TYPEDADDRESS OFF} // Unit must be compiled without type-checked pointers. 
{$WARN SYMBOL_PLATFORM OFF}
{$WRITEABLECONST ON}
{$VARPROPSETTER ON}
{$ALIGN 4}

interface

uses Winapi.Windows, System.Classes, System.Variants, System.Win.StdVCL, Vcl.Graphics, Vcl.OleServer, Winapi.ActiveX;
  

// *********************************************************************//
// GUIDS declared in the TypeLibrary. Following prefixes are used:        
//   Type Libraries     : LIBID_xxxx                                      
//   CoClasses          : CLASS_xxxx                                      
//   DISPInterfaces     : DIID_xxxx                                       
//   Non-DISP interfaces: IID_xxxx                                        
// *********************************************************************//
const
  // TypeLibrary Major and minor versions
  LLVMPDBCOMMajorVersion = 1;
  LLVMPDBCOMMinorVersion = 0;

  LIBID_LLVMPDBCOM: TGUID = '{1AD0D8AA-7E3A-40B0-B209-05A677AF6131}';

  IID_ILLVMBumpPtrAllocator: TGUID = '{24EDBAD8-37ED-4C53-8F92-521A75F0AB4E}';
  CLASS_LLVMBumpPtrAllocator: TGUID = '{2C35F922-C46A-48A3-8B29-446B4AA8D9F8}';
  IID_ILLVMMSFBuilder: TGUID = '{ECAE464F-C152-41AA-AF30-B3CA457245D7}';
  CLASS_LLVMMSFBuilder: TGUID = '{5271AA39-081F-476B-B48D-9156DA234C82}';
  IID_ILLVMInfoStreamBuilder: TGUID = '{44C32608-18A0-4B23-AD14-09352E32C841}';
  CLASS_LLVMInfoStreamBuilder: TGUID = '{59DEDB9B-CBAC-47E8-91E3-2F4150CBD3E8}';
  IID_ILLVMDebugSubsection: TGUID = '{1165F748-7FA5-45CE-A379-0FF5245AB77A}';
  IID_ILLVMDebugStringTableSubsection: TGUID = '{2AE682F6-E412-4579-A51C-11403B7A3460}';
  CLASS_LLVMDebugStringTableSubsection: TGUID = '{6F49A856-034E-4329-9A16-567A96439261}';
  IID_ILLVMDebugChecksumsSubsection: TGUID = '{19B614B3-FB79-46ED-ADBA-A9BF0A1C0B87}';
  CLASS_LLVMDebugChecksumsSubsection: TGUID = '{8B5DD35A-59D6-45C3-9BED-9A6947525D15}';
  IID_ILLVMDebugLinesSubsection: TGUID = '{DF11BF2F-A510-4294-9E26-783BB486D049}';
  CLASS_LLVMDebugLinesSubsection: TGUID = '{297E3879-B8AB-4A36-9D33-CF6B1A12E876}';
  IID_ILLVMDbiModuleDescriptorBuilder: TGUID = '{E92295A0-641E-4E60-AD36-AE09D6CDBB7B}';
  CLASS_LLVMDbiModuleDescriptorBuilder: TGUID = '{8D954FFF-3610-4FF1-AC56-000C8835C2E5}';
  IID_ILLVMDbiStreamBuilder: TGUID = '{5CE95A75-991B-42BE-804E-E5E002320081}';
  CLASS_LLVMDbiStreamBuilder: TGUID = '{FA6C39BF-7DFD-4265-97F2-68DAC89CFE98}';
  IID_ILLVMTpiStreamBuilder: TGUID = '{0A0A264A-CD80-4AF0-A70D-15DC59E4EE17}';
  CLASS_LLVMTpiStreamBuilder: TGUID = '{FB57BDAF-B937-4D6A-9B81-32C258CCE364}';
  IID_ILLVMGSIStreamBuilder: TGUID = '{2A9B611C-2859-4334-9178-DB1B9943B569}';
  CLASS_LLVMGSIStreamBuilder: TGUID = '{28AF174A-4751-42FC-A573-19B9F60E45F9}';
  IID_ILLVMPDBStringTableBuilder: TGUID = '{80055881-D8A2-4C07-B691-7FB8ED24EB15}';
  CLASS_LLVMPDBStringTableBuilder: TGUID = '{FF8BDB5A-3939-42DA-9EF9-6CF8E211A2D7}';
  IID_ILLVMPDBFileBuilder: TGUID = '{67216998-C556-4B16-B347-E7A0F0978B17}';
  CLASS_LLVMPDBFileBuilder: TGUID = '{84082637-A965-41B7-B6B7-4C185EB645A7}';
  IID_ILLVMPDBUtilities: TGUID = '{0AE83113-266D-4F92-BC35-9E472402FCC3}';
  CLASS_LLVMPDBUtilities: TGUID = '{A67E7148-9565-462A-98F9-E0D87EE01BE9}';

// *********************************************************************//
// Declaration of Enumerations defined in Type Library                    
// *********************************************************************//
// Constants for enum LLVM_FileChecksumKind
type
  LLVM_FileChecksumKind = TOleEnum;
const
  FileChecksumKind_None = $00000000;
  FileChecksumKind_MD5 = $00000001;
  FileChecksumKind_SHA1 = $00000002;
  FileChecksumKind_SHA256 = $00000003;

// Constants for enum LLVM_PDB_Machine
type
  LLVM_PDB_Machine = TOleEnum;
const
  PDB_Machine_Invalid = $0000FFFF;
  PDB_Machine_Unknown = $00000000;
  PDB_Machine_Am33 = $00000013;
  PDB_Machine_Amd64 = $00008664;
  PDB_Machine_Arm = $000001C0;
  PDB_Machine_ArmNT = $000001C4;
  PDB_Machine_Ebc = $00000EBC;
  PDB_Machine_x86 = $0000014C;
  PDB_Machine_Ia64 = $00000200;
  PDB_Machine_M32R = $00009041;
  PDB_Machine_Mips16 = $00000266;
  PDB_Machine_MipsFpu = $00000366;
  PDB_Machine_MipsFpu16 = $00000466;
  PDB_Machine_PowerPC = $000001F0;
  PDB_Machine_PowerPCFP = $000001F1;
  PDB_Machine_R4000 = $00000166;
  PDB_Machine_SH3 = $000001A2;
  PDB_Machine_SH3DSP = $000001A3;
  PDB_Machine_SH4 = $000001A6;
  PDB_Machine_SH5 = $000001A8;
  PDB_Machine_Thumb = $000001C2;
  PDB_Machine_WceMipsV2 = $00000169;

// Constants for enum LLVM_PdbRaw_DbiVer
type
  LLVM_PdbRaw_DbiVer = TOleEnum;
const
  PdbDbiVC41 = $000E33F3;
  PdbDbiV50 = $013091F3;
  PdbDbiV60 = $0130BA2E;
  PdbDbiV70 = $01310977;
  PdbDbiV110 = $01329141;

// Constants for enum LLVM_PdbRaw_FeatureSig
type
  LLVM_PdbRaw_FeatureSig = TOleEnum;
const
  PdbRaw_FeatureSig_VC110 = $01329141;
  PdbRaw_FeatureSig_VC140 = $013351DC;
  PdbRaw_FeatureSig_NoTypeMerge = $4D544F4E;
  PdbRaw_FeatureSig_MinimalDebugInfo = $494E494D;

// Constants for enum LLVM_PdbRaw_ImplVer
type
  LLVM_PdbRaw_ImplVer = TOleEnum;
const
  PdbImplVC2 = $013048EA;
  PdbImplVC4 = $01306C1F;
  PdbImplVC41 = $01306CDE;
  PdbImplVC50 = $013091F3;
  PdbImplVC98 = $0130BA2C;
  PdbImplVC70Dep = $0131084C;
  PdbImplVC70 = $01312E94;
  PdbImplVC80 = $0131A5B5;
  PdbImplVC110 = $01329141;
  PdbImplVC140 = $013351DC;

// Constants for enum LLVM_PdbRaw_TpiVer
type
  LLVM_PdbRaw_TpiVer = TOleEnum;
const
  PdbRaw_TpiVer_PdbTpiV40 = $01306B4A;
  PdbRaw_TpiVer_PdbTpiV41 = $01306E12;
  PdbRaw_TpiVer_PdbTpiV50 = $013094C7;
  PdbRaw_TpiVer_PdbTpiV70 = $01310977;
  PdbRaw_TpiVer_PdbTpiV80 = $0131CA0B;

// Constants for enum LLVM_SpecialStream
type
  LLVM_SpecialStream = TOleEnum;
const
  SpecialStream_OldMSFDirectory = $00000000;
  SpecialStream_StreamPDB = $00000001;
  SpecialStream_StreamTPI = $00000002;
  SpecialStream_StreamDBI = $00000003;
  SpecialStream_StreamIPI = $00000004;
  SpecialStream_kSpecialStreamCount = $00000005;

// Constants for enum LLVM_DbgHeaderType
type
  LLVM_DbgHeaderType = TOleEnum;
const
  DbgHeaderType_FPO = $00000000;
  DbgHeaderType_Exception = $00000001;
  DbgHeaderType_Fixup = $00000002;
  DbgHeaderType_OmapToSrc = $00000003;
  DbgHeaderType_OmapFromSrc = $00000004;
  DbgHeaderType_SectionHdr = $00000005;
  DbgHeaderType_TokenRidMap = $00000006;
  DbgHeaderType_Xdata = $00000007;
  DbgHeaderType_Pdata = $00000008;
  DbgHeaderType_NewFPO = $00000009;
  DbgHeaderType_SectionHdrOrig = $0000000A;
  DbgHeaderType_Max = $0000000B;

type

// *********************************************************************//
// Forward declaration of types defined in TypeLibrary                    
// *********************************************************************//
  ILLVMBumpPtrAllocator = interface;
  ILLVMBumpPtrAllocatorDisp = dispinterface;
  ILLVMMSFBuilder = interface;
  ILLVMMSFBuilderDisp = dispinterface;
  ILLVMInfoStreamBuilder = interface;
  ILLVMInfoStreamBuilderDisp = dispinterface;
  ILLVMDebugSubsection = interface;
  ILLVMDebugSubsectionDisp = dispinterface;
  ILLVMDebugStringTableSubsection = interface;
  ILLVMDebugStringTableSubsectionDisp = dispinterface;
  ILLVMDebugChecksumsSubsection = interface;
  ILLVMDebugChecksumsSubsectionDisp = dispinterface;
  ILLVMDebugLinesSubsection = interface;
  ILLVMDebugLinesSubsectionDisp = dispinterface;
  ILLVMDbiModuleDescriptorBuilder = interface;
  ILLVMDbiModuleDescriptorBuilderDisp = dispinterface;
  ILLVMDbiStreamBuilder = interface;
  ILLVMDbiStreamBuilderDisp = dispinterface;
  ILLVMTpiStreamBuilder = interface;
  ILLVMTpiStreamBuilderDisp = dispinterface;
  ILLVMGSIStreamBuilder = interface;
  ILLVMGSIStreamBuilderDisp = dispinterface;
  ILLVMPDBStringTableBuilder = interface;
  ILLVMPDBStringTableBuilderDisp = dispinterface;
  ILLVMPDBFileBuilder = interface;
  ILLVMPDBFileBuilderDisp = dispinterface;
  ILLVMPDBUtilities = interface;
  ILLVMPDBUtilitiesDisp = dispinterface;

// *********************************************************************//
// Declaration of CoClasses defined in Type Library                       
// (NOTE: Here we map each CoClass to its Default Interface)              
// *********************************************************************//
  LLVMBumpPtrAllocator = ILLVMBumpPtrAllocator;
  LLVMMSFBuilder = ILLVMMSFBuilder;
  LLVMInfoStreamBuilder = ILLVMInfoStreamBuilder;
  LLVMDebugStringTableSubsection = ILLVMDebugStringTableSubsection;
  LLVMDebugChecksumsSubsection = ILLVMDebugChecksumsSubsection;
  LLVMDebugLinesSubsection = ILLVMDebugLinesSubsection;
  LLVMDbiModuleDescriptorBuilder = ILLVMDbiModuleDescriptorBuilder;
  LLVMDbiStreamBuilder = ILLVMDbiStreamBuilder;
  LLVMTpiStreamBuilder = ILLVMTpiStreamBuilder;
  LLVMGSIStreamBuilder = ILLVMGSIStreamBuilder;
  LLVMPDBStringTableBuilder = ILLVMPDBStringTableBuilder;
  LLVMPDBFileBuilder = ILLVMPDBFileBuilder;
  LLVMPDBUtilities = ILLVMPDBUtilities;


// *********************************************************************//
// Declaration of structures, unions and aliases.                         
// *********************************************************************//
  PUserType1 = ^LLVM_SectionContrib; {*}

  LLVM_SectionContrib = record
    ISect: Word;
    Padding: array[0..1] of Shortint;
    Off: Integer;
    Size: Integer;
    Characteristics: LongWord;
    Imod: Word;
    Padding2: array[0..1] of Shortint;
    DataCrc: LongWord;
    RelocCrc: LongWord;
  end;

  LLVM_COFF_Section = record
    Name: array[0..7] of Shortint;
    VirtualSize: LongWord;
    VirtualAddress: LongWord;
    SizeOfRawData: LongWord;
    PointertoRawData: LongWord;
    PointerToRelocations: LongWord;
    PointerToLinenumbers: LongWord;
    NumberOfRelocations: Word;
    NumberOfLinenumbers: Word;
    Characteristics: LongWord;
  end;


// *********************************************************************//
// Interface: ILLVMBumpPtrAllocator
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {24EDBAD8-37ED-4C53-8F92-521A75F0AB4E}
// *********************************************************************//
  ILLVMBumpPtrAllocator = interface(IDispatch)
    ['{24EDBAD8-37ED-4C53-8F92-521A75F0AB4E}']
  end;

// *********************************************************************//
// DispIntf:  ILLVMBumpPtrAllocatorDisp
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {24EDBAD8-37ED-4C53-8F92-521A75F0AB4E}
// *********************************************************************//
  ILLVMBumpPtrAllocatorDisp = dispinterface
    ['{24EDBAD8-37ED-4C53-8F92-521A75F0AB4E}']
  end;

// *********************************************************************//
// Interface: ILLVMMSFBuilder
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {ECAE464F-C152-41AA-AF30-B3CA457245D7}
// *********************************************************************//
  ILLVMMSFBuilder = interface(IDispatch)
    ['{ECAE464F-C152-41AA-AF30-B3CA457245D7}']
    function addStream(Size: LongWord): LongWord; safecall;
  end;

// *********************************************************************//
// DispIntf:  ILLVMMSFBuilderDisp
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {ECAE464F-C152-41AA-AF30-B3CA457245D7}
// *********************************************************************//
  ILLVMMSFBuilderDisp = dispinterface
    ['{ECAE464F-C152-41AA-AF30-B3CA457245D7}']
    function addStream(Size: LongWord): LongWord; dispid 1;
  end;

// *********************************************************************//
// Interface: ILLVMInfoStreamBuilder
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {44C32608-18A0-4B23-AD14-09352E32C841}
// *********************************************************************//
  ILLVMInfoStreamBuilder = interface(IDispatch)
    ['{44C32608-18A0-4B23-AD14-09352E32C841}']
    procedure setVersion(V: LLVM_PdbRaw_ImplVer); safecall;
    procedure addFeature(Sig: LLVM_PdbRaw_FeatureSig); safecall;
    procedure setHashPDBContentsToGUID(B: WordBool); safecall;
    procedure setSignature(S: LongWord); safecall;
    procedure setAge(A: LongWord); safecall;
    procedure setGuid(G: TGUID); safecall;
    function getAge: LongWord; safecall;
    function getGuid: TGUID; safecall;
    function getSignature(out hasSignature: WordBool): LongWord; safecall;
    procedure finalizeMsfLayout; safecall;
  end;

// *********************************************************************//
// DispIntf:  ILLVMInfoStreamBuilderDisp
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {44C32608-18A0-4B23-AD14-09352E32C841}
// *********************************************************************//
  ILLVMInfoStreamBuilderDisp = dispinterface
    ['{44C32608-18A0-4B23-AD14-09352E32C841}']
    procedure setVersion(V: LLVM_PdbRaw_ImplVer); dispid 1;
    procedure addFeature(Sig: LLVM_PdbRaw_FeatureSig); dispid 2;
    procedure setHashPDBContentsToGUID(B: WordBool); dispid 3;
    procedure setSignature(S: LongWord); dispid 4;
    procedure setAge(A: LongWord); dispid 5;
    procedure setGuid(G: {NOT_OLEAUTO(TGUID)}OleVariant); dispid 6;
    function getAge: LongWord; dispid 7;
    function getGuid: {NOT_OLEAUTO(TGUID)}OleVariant; dispid 8;
    function getSignature(out hasSignature: WordBool): LongWord; dispid 9;
    procedure finalizeMsfLayout; dispid 10;
  end;

// *********************************************************************//
// Interface: ILLVMDebugSubsection
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {1165F748-7FA5-45CE-A379-0FF5245AB77A}
// *********************************************************************//
  ILLVMDebugSubsection = interface(IDispatch)
    ['{1165F748-7FA5-45CE-A379-0FF5245AB77A}']
  end;

// *********************************************************************//
// DispIntf:  ILLVMDebugSubsectionDisp
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {1165F748-7FA5-45CE-A379-0FF5245AB77A}
// *********************************************************************//
  ILLVMDebugSubsectionDisp = dispinterface
    ['{1165F748-7FA5-45CE-A379-0FF5245AB77A}']
  end;

// *********************************************************************//
// Interface: ILLVMDebugStringTableSubsection
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {2AE682F6-E412-4579-A51C-11403B7A3460}
// *********************************************************************//
  ILLVMDebugStringTableSubsection = interface(ILLVMDebugSubsection)
    ['{2AE682F6-E412-4579-A51C-11403B7A3460}']
    function insert(const S: WideString): LongWord; safecall;
    function getIdForString(const S: WideString): LongWord; safecall;
    function getStringForId(Id: LongWord): WideString; safecall;
  end;

// *********************************************************************//
// DispIntf:  ILLVMDebugStringTableSubsectionDisp
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {2AE682F6-E412-4579-A51C-11403B7A3460}
// *********************************************************************//
  ILLVMDebugStringTableSubsectionDisp = dispinterface
    ['{2AE682F6-E412-4579-A51C-11403B7A3460}']
    function insert(const S: WideString): LongWord; dispid 1;
    function getIdForString(const S: WideString): LongWord; dispid 2;
    function getStringForId(Id: LongWord): WideString; dispid 3;
  end;

// *********************************************************************//
// Interface: ILLVMDebugChecksumsSubsection
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {19B614B3-FB79-46ED-ADBA-A9BF0A1C0B87}
// *********************************************************************//
  ILLVMDebugChecksumsSubsection = interface(ILLVMDebugSubsection)
    ['{19B614B3-FB79-46ED-ADBA-A9BF0A1C0B87}']
    procedure construct(const Allocator: ILLVMBumpPtrAllocator; 
                        const Strings: ILLVMDebugStringTableSubsection); safecall;
    procedure addChecksum(const FileName: WideString; Kind: LLVM_FileChecksumKind; Bytes: OleVariant); safecall;
  end;

// *********************************************************************//
// DispIntf:  ILLVMDebugChecksumsSubsectionDisp
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {19B614B3-FB79-46ED-ADBA-A9BF0A1C0B87}
// *********************************************************************//
  ILLVMDebugChecksumsSubsectionDisp = dispinterface
    ['{19B614B3-FB79-46ED-ADBA-A9BF0A1C0B87}']
    procedure construct(const Allocator: ILLVMBumpPtrAllocator; 
                        const Strings: ILLVMDebugStringTableSubsection); dispid 1;
    procedure addChecksum(const FileName: WideString; Kind: LLVM_FileChecksumKind; Bytes: OleVariant); dispid 2;
  end;

// *********************************************************************//
// Interface: ILLVMDebugLinesSubsection
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {DF11BF2F-A510-4294-9E26-783BB486D049}
// *********************************************************************//
  ILLVMDebugLinesSubsection = interface(ILLVMDebugSubsection)
    ['{DF11BF2F-A510-4294-9E26-783BB486D049}']
    procedure construct(const Checksums: ILLVMDebugChecksumsSubsection; 
                        const Strings: ILLVMDebugStringTableSubsection); safecall;
    procedure setRelocationAddress(Segment: Word; Offset: LongWord); safecall;
    procedure setCodeSize(Size: LongWord); safecall;
    procedure createBlock(const FileName: WideString); safecall;
    procedure addLineInfo(Offset: LongWord; StartLine: LongWord; EndLine: LongWord; 
                          IsStatement: WordBool); safecall;
  end;

// *********************************************************************//
// DispIntf:  ILLVMDebugLinesSubsectionDisp
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {DF11BF2F-A510-4294-9E26-783BB486D049}
// *********************************************************************//
  ILLVMDebugLinesSubsectionDisp = dispinterface
    ['{DF11BF2F-A510-4294-9E26-783BB486D049}']
    procedure construct(const Checksums: ILLVMDebugChecksumsSubsection; 
                        const Strings: ILLVMDebugStringTableSubsection); dispid 1;
    procedure setRelocationAddress(Segment: Word; Offset: LongWord); dispid 2;
    procedure setCodeSize(Size: LongWord); dispid 3;
    procedure createBlock(const FileName: WideString); dispid 4;
    procedure addLineInfo(Offset: LongWord; StartLine: LongWord; EndLine: LongWord; 
                          IsStatement: WordBool); dispid 5;
  end;

// *********************************************************************//
// Interface: ILLVMDbiModuleDescriptorBuilder
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {E92295A0-641E-4E60-AD36-AE09D6CDBB7B}
// *********************************************************************//
  ILLVMDbiModuleDescriptorBuilder = interface(IDispatch)
    ['{E92295A0-641E-4E60-AD36-AE09D6CDBB7B}']
    procedure setObjFileName(const Name: WideString); safecall;
    procedure addSymbolsInBulk(BulkSymbols: OleVariant); safecall;
    function getObjFileName: WideString; safecall;
    procedure addDebugSubsection(const Subsection: ILLVMDebugSubsection); safecall;
    procedure setFirstSectionContrib(var SC: LLVM_SectionContrib); safecall;
    function getModuleIndex: LongWord; safecall;
    procedure setPdbFilePathNI(NI: LongWord); safecall;
    procedure addSymbol(Symbol: OleVariant); safecall;
  end;

// *********************************************************************//
// DispIntf:  ILLVMDbiModuleDescriptorBuilderDisp
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {E92295A0-641E-4E60-AD36-AE09D6CDBB7B}
// *********************************************************************//
  ILLVMDbiModuleDescriptorBuilderDisp = dispinterface
    ['{E92295A0-641E-4E60-AD36-AE09D6CDBB7B}']
    procedure setObjFileName(const Name: WideString); dispid 1;
    procedure addSymbolsInBulk(BulkSymbols: OleVariant); dispid 2;
    function getObjFileName: WideString; dispid 3;
    procedure addDebugSubsection(const Subsection: ILLVMDebugSubsection); dispid 4;
    procedure setFirstSectionContrib(var SC: {NOT_OLEAUTO(LLVM_SectionContrib)}OleVariant); dispid 5;
    function getModuleIndex: LongWord; dispid 6;
    procedure setPdbFilePathNI(NI: LongWord); dispid 7;
    procedure addSymbol(Symbol: OleVariant); dispid 8;
  end;

// *********************************************************************//
// Interface: ILLVMDbiStreamBuilder
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {5CE95A75-991B-42BE-804E-E5E002320081}
// *********************************************************************//
  ILLVMDbiStreamBuilder = interface(IDispatch)
    ['{5CE95A75-991B-42BE-804E-E5E002320081}']
    procedure setVersionHeader(V: LLVM_PdbRaw_DbiVer); safecall;
    procedure setAge(A: LongWord); safecall;
    procedure setBuildNumber(B: Word); safecall;
    procedure setBuildNumberMajorMinor(Major: Byte; Minor: Byte); safecall;
    procedure setPdbDllVersion(V: Word); safecall;
    procedure setPdbDllRbld(R: Word); safecall;
    procedure setFlags(F: Word); safecall;
    procedure setMachineType(M: LLVM_PDB_Machine); safecall;
    procedure setMachineTypeCOFF(M: LongWord); safecall;
    function addModuleInfo(const ModuleName: WideString): ILLVMDbiModuleDescriptorBuilder; safecall;
    procedure addModuleSourceFile(const Module: ILLVMDbiModuleDescriptorBuilder; 
                                  const File_: WideString); safecall;
    function addECName(const Name: WideString): LongWord; safecall;
    procedure addSectionContrib(var SC: LLVM_SectionContrib); safecall;
    procedure setSectionMap(SecMap: OleVariant); safecall;
    procedure addDbgStream(Type_: LLVM_DbgHeaderType; Data: OleVariant); safecall;
  end;

// *********************************************************************//
// DispIntf:  ILLVMDbiStreamBuilderDisp
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {5CE95A75-991B-42BE-804E-E5E002320081}
// *********************************************************************//
  ILLVMDbiStreamBuilderDisp = dispinterface
    ['{5CE95A75-991B-42BE-804E-E5E002320081}']
    procedure setVersionHeader(V: LLVM_PdbRaw_DbiVer); dispid 1;
    procedure setAge(A: LongWord); dispid 2;
    procedure setBuildNumber(B: Word); dispid 3;
    procedure setBuildNumberMajorMinor(Major: Byte; Minor: Byte); dispid 4;
    procedure setPdbDllVersion(V: Word); dispid 5;
    procedure setPdbDllRbld(R: Word); dispid 6;
    procedure setFlags(F: Word); dispid 7;
    procedure setMachineType(M: LLVM_PDB_Machine); dispid 8;
    procedure setMachineTypeCOFF(M: LongWord); dispid 9;
    function addModuleInfo(const ModuleName: WideString): ILLVMDbiModuleDescriptorBuilder; dispid 10;
    procedure addModuleSourceFile(const Module: ILLVMDbiModuleDescriptorBuilder; 
                                  const File_: WideString); dispid 11;
    function addECName(const Name: WideString): LongWord; dispid 12;
    procedure addSectionContrib(var SC: {NOT_OLEAUTO(LLVM_SectionContrib)}OleVariant); dispid 13;
    procedure setSectionMap(SecMap: OleVariant); dispid 14;
    procedure addDbgStream(Type_: LLVM_DbgHeaderType; Data: OleVariant); dispid 15;
  end;

// *********************************************************************//
// Interface: ILLVMTpiStreamBuilder
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {0A0A264A-CD80-4AF0-A70D-15DC59E4EE17}
// *********************************************************************//
  ILLVMTpiStreamBuilder = interface(IDispatch)
    ['{0A0A264A-CD80-4AF0-A70D-15DC59E4EE17}']
    procedure setVersionHeader(Version: LLVM_PdbRaw_TpiVer); safecall;
    procedure addTypeRecord(Type_: OleVariant; Hash: OleVariant); safecall;
  end;

// *********************************************************************//
// DispIntf:  ILLVMTpiStreamBuilderDisp
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {0A0A264A-CD80-4AF0-A70D-15DC59E4EE17}
// *********************************************************************//
  ILLVMTpiStreamBuilderDisp = dispinterface
    ['{0A0A264A-CD80-4AF0-A70D-15DC59E4EE17}']
    procedure setVersionHeader(Version: LLVM_PdbRaw_TpiVer); dispid 1;
    procedure addTypeRecord(Type_: OleVariant; Hash: OleVariant); dispid 2;
  end;

// *********************************************************************//
// Interface: ILLVMGSIStreamBuilder
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {2A9B611C-2859-4334-9178-DB1B9943B569}
// *********************************************************************//
  ILLVMGSIStreamBuilder = interface(IDispatch)
    ['{2A9B611C-2859-4334-9178-DB1B9943B569}']
    procedure addPublicSymbol(Pub: OleVariant); safecall;
    procedure addGlobalSymbol(Sym: OleVariant); safecall;
  end;

// *********************************************************************//
// DispIntf:  ILLVMGSIStreamBuilderDisp
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {2A9B611C-2859-4334-9178-DB1B9943B569}
// *********************************************************************//
  ILLVMGSIStreamBuilderDisp = dispinterface
    ['{2A9B611C-2859-4334-9178-DB1B9943B569}']
    procedure addPublicSymbol(Pub: OleVariant); dispid 1;
    procedure addGlobalSymbol(Sym: OleVariant); dispid 2;
  end;

// *********************************************************************//
// Interface: ILLVMPDBStringTableBuilder
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {80055881-D8A2-4C07-B691-7FB8ED24EB15}
// *********************************************************************//
  ILLVMPDBStringTableBuilder = interface(IDispatch)
    ['{80055881-D8A2-4C07-B691-7FB8ED24EB15}']
    function insert(const S: WideString): LongWord; safecall;
    function getIdForString(const S: WideString): LongWord; safecall;
    function getStringForId(Id: LongWord): WideString; safecall;
    procedure setStrings(const Strings: ILLVMDebugStringTableSubsection); safecall;
  end;

// *********************************************************************//
// DispIntf:  ILLVMPDBStringTableBuilderDisp
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {80055881-D8A2-4C07-B691-7FB8ED24EB15}
// *********************************************************************//
  ILLVMPDBStringTableBuilderDisp = dispinterface
    ['{80055881-D8A2-4C07-B691-7FB8ED24EB15}']
    function insert(const S: WideString): LongWord; dispid 1;
    function getIdForString(const S: WideString): LongWord; dispid 2;
    function getStringForId(Id: LongWord): WideString; dispid 3;
    procedure setStrings(const Strings: ILLVMDebugStringTableSubsection); dispid 4;
  end;

// *********************************************************************//
// Interface: ILLVMPDBFileBuilder
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {67216998-C556-4B16-B347-E7A0F0978B17}
// *********************************************************************//
  ILLVMPDBFileBuilder = interface(IDispatch)
    ['{67216998-C556-4B16-B347-E7A0F0978B17}']
    procedure construct(const Allocator: ILLVMBumpPtrAllocator); safecall;
    procedure initialize(blockSize: LongWord); safecall;
    function getMsfBuilder: ILLVMMSFBuilder; safecall;
    function getInfoBuilder: ILLVMInfoStreamBuilder; safecall;
    function getDbiBuilder: ILLVMDbiStreamBuilder; safecall;
    function getTpiBuilder: ILLVMTpiStreamBuilder; safecall;
    function getIpiBuilder: ILLVMTpiStreamBuilder; safecall;
    function getGsiBuilder: ILLVMGSIStreamBuilder; safecall;
    function getStringTableBuilder: ILLVMPDBStringTableBuilder; safecall;
    procedure commit(const FileName: WideString; out guid: TGUID); safecall;
  end;

// *********************************************************************//
// DispIntf:  ILLVMPDBFileBuilderDisp
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {67216998-C556-4B16-B347-E7A0F0978B17}
// *********************************************************************//
  ILLVMPDBFileBuilderDisp = dispinterface
    ['{67216998-C556-4B16-B347-E7A0F0978B17}']
    procedure construct(const Allocator: ILLVMBumpPtrAllocator); dispid 1;
    procedure initialize(blockSize: LongWord); dispid 2;
    function getMsfBuilder: ILLVMMSFBuilder; dispid 3;
    function getInfoBuilder: ILLVMInfoStreamBuilder; dispid 4;
    function getDbiBuilder: ILLVMDbiStreamBuilder; dispid 5;
    function getTpiBuilder: ILLVMTpiStreamBuilder; dispid 6;
    function getIpiBuilder: ILLVMTpiStreamBuilder; dispid 7;
    function getGsiBuilder: ILLVMGSIStreamBuilder; dispid 8;
    function getStringTableBuilder: ILLVMPDBStringTableBuilder; dispid 9;
    procedure commit(const FileName: WideString; out guid: {NOT_OLEAUTO(TGUID)}OleVariant); dispid 10;
  end;

// *********************************************************************//
// Interface: ILLVMPDBUtilities
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {0AE83113-266D-4F92-BC35-9E472402FCC3}
// *********************************************************************//
  ILLVMPDBUtilities = interface(IDispatch)
    ['{0AE83113-266D-4F92-BC35-9E472402FCC3}']
    function hashTypeRecord(Type_: OleVariant): LongWord; safecall;
  end;

// *********************************************************************//
// DispIntf:  ILLVMPDBUtilitiesDisp
// Flags:     (4544) Dual NonExtensible OleAutomation Dispatchable
// GUID:      {0AE83113-266D-4F92-BC35-9E472402FCC3}
// *********************************************************************//
  ILLVMPDBUtilitiesDisp = dispinterface
    ['{0AE83113-266D-4F92-BC35-9E472402FCC3}']
    function hashTypeRecord(Type_: OleVariant): LongWord; dispid 1;
  end;

// *********************************************************************//
// The Class CoLLVMBumpPtrAllocator provides a Create and CreateRemote method to          
// create instances of the default interface ILLVMBumpPtrAllocator exposed by              
// the CoClass LLVMBumpPtrAllocator. The functions are intended to be used by             
// clients wishing to automate the CoClass objects exposed by the         
// server of this typelibrary.                                            
// *********************************************************************//
  CoLLVMBumpPtrAllocator = class
    class function Create: ILLVMBumpPtrAllocator;
    class function CreateRemote(const MachineName: string): ILLVMBumpPtrAllocator;
  end;

// *********************************************************************//
// The Class CoLLVMMSFBuilder provides a Create and CreateRemote method to          
// create instances of the default interface ILLVMMSFBuilder exposed by              
// the CoClass LLVMMSFBuilder. The functions are intended to be used by             
// clients wishing to automate the CoClass objects exposed by the         
// server of this typelibrary.                                            
// *********************************************************************//
  CoLLVMMSFBuilder = class
    class function Create: ILLVMMSFBuilder;
    class function CreateRemote(const MachineName: string): ILLVMMSFBuilder;
  end;

// *********************************************************************//
// The Class CoLLVMInfoStreamBuilder provides a Create and CreateRemote method to          
// create instances of the default interface ILLVMInfoStreamBuilder exposed by              
// the CoClass LLVMInfoStreamBuilder. The functions are intended to be used by             
// clients wishing to automate the CoClass objects exposed by the         
// server of this typelibrary.                                            
// *********************************************************************//
  CoLLVMInfoStreamBuilder = class
    class function Create: ILLVMInfoStreamBuilder;
    class function CreateRemote(const MachineName: string): ILLVMInfoStreamBuilder;
  end;

// *********************************************************************//
// The Class CoLLVMDebugStringTableSubsection provides a Create and CreateRemote method to          
// create instances of the default interface ILLVMDebugStringTableSubsection exposed by              
// the CoClass LLVMDebugStringTableSubsection. The functions are intended to be used by             
// clients wishing to automate the CoClass objects exposed by the         
// server of this typelibrary.                                            
// *********************************************************************//
  CoLLVMDebugStringTableSubsection = class
    class function Create: ILLVMDebugStringTableSubsection;
    class function CreateRemote(const MachineName: string): ILLVMDebugStringTableSubsection;
  end;

// *********************************************************************//
// The Class CoLLVMDebugChecksumsSubsection provides a Create and CreateRemote method to          
// create instances of the default interface ILLVMDebugChecksumsSubsection exposed by              
// the CoClass LLVMDebugChecksumsSubsection. The functions are intended to be used by             
// clients wishing to automate the CoClass objects exposed by the         
// server of this typelibrary.                                            
// *********************************************************************//
  CoLLVMDebugChecksumsSubsection = class
    class function Create: ILLVMDebugChecksumsSubsection;
    class function CreateRemote(const MachineName: string): ILLVMDebugChecksumsSubsection;
  end;

// *********************************************************************//
// The Class CoLLVMDebugLinesSubsection provides a Create and CreateRemote method to          
// create instances of the default interface ILLVMDebugLinesSubsection exposed by              
// the CoClass LLVMDebugLinesSubsection. The functions are intended to be used by             
// clients wishing to automate the CoClass objects exposed by the         
// server of this typelibrary.                                            
// *********************************************************************//
  CoLLVMDebugLinesSubsection = class
    class function Create: ILLVMDebugLinesSubsection;
    class function CreateRemote(const MachineName: string): ILLVMDebugLinesSubsection;
  end;

// *********************************************************************//
// The Class CoLLVMDbiModuleDescriptorBuilder provides a Create and CreateRemote method to          
// create instances of the default interface ILLVMDbiModuleDescriptorBuilder exposed by              
// the CoClass LLVMDbiModuleDescriptorBuilder. The functions are intended to be used by             
// clients wishing to automate the CoClass objects exposed by the         
// server of this typelibrary.                                            
// *********************************************************************//
  CoLLVMDbiModuleDescriptorBuilder = class
    class function Create: ILLVMDbiModuleDescriptorBuilder;
    class function CreateRemote(const MachineName: string): ILLVMDbiModuleDescriptorBuilder;
  end;

// *********************************************************************//
// The Class CoLLVMDbiStreamBuilder provides a Create and CreateRemote method to          
// create instances of the default interface ILLVMDbiStreamBuilder exposed by              
// the CoClass LLVMDbiStreamBuilder. The functions are intended to be used by             
// clients wishing to automate the CoClass objects exposed by the         
// server of this typelibrary.                                            
// *********************************************************************//
  CoLLVMDbiStreamBuilder = class
    class function Create: ILLVMDbiStreamBuilder;
    class function CreateRemote(const MachineName: string): ILLVMDbiStreamBuilder;
  end;

// *********************************************************************//
// The Class CoLLVMTpiStreamBuilder provides a Create and CreateRemote method to          
// create instances of the default interface ILLVMTpiStreamBuilder exposed by              
// the CoClass LLVMTpiStreamBuilder. The functions are intended to be used by             
// clients wishing to automate the CoClass objects exposed by the         
// server of this typelibrary.                                            
// *********************************************************************//
  CoLLVMTpiStreamBuilder = class
    class function Create: ILLVMTpiStreamBuilder;
    class function CreateRemote(const MachineName: string): ILLVMTpiStreamBuilder;
  end;

// *********************************************************************//
// The Class CoLLVMGSIStreamBuilder provides a Create and CreateRemote method to          
// create instances of the default interface ILLVMGSIStreamBuilder exposed by              
// the CoClass LLVMGSIStreamBuilder. The functions are intended to be used by             
// clients wishing to automate the CoClass objects exposed by the         
// server of this typelibrary.                                            
// *********************************************************************//
  CoLLVMGSIStreamBuilder = class
    class function Create: ILLVMGSIStreamBuilder;
    class function CreateRemote(const MachineName: string): ILLVMGSIStreamBuilder;
  end;

// *********************************************************************//
// The Class CoLLVMPDBStringTableBuilder provides a Create and CreateRemote method to          
// create instances of the default interface ILLVMPDBStringTableBuilder exposed by              
// the CoClass LLVMPDBStringTableBuilder. The functions are intended to be used by             
// clients wishing to automate the CoClass objects exposed by the         
// server of this typelibrary.                                            
// *********************************************************************//
  CoLLVMPDBStringTableBuilder = class
    class function Create: ILLVMPDBStringTableBuilder;
    class function CreateRemote(const MachineName: string): ILLVMPDBStringTableBuilder;
  end;

// *********************************************************************//
// The Class CoLLVMPDBFileBuilder provides a Create and CreateRemote method to          
// create instances of the default interface ILLVMPDBFileBuilder exposed by              
// the CoClass LLVMPDBFileBuilder. The functions are intended to be used by             
// clients wishing to automate the CoClass objects exposed by the         
// server of this typelibrary.                                            
// *********************************************************************//
  CoLLVMPDBFileBuilder = class
    class function Create: ILLVMPDBFileBuilder;
    class function CreateRemote(const MachineName: string): ILLVMPDBFileBuilder;
  end;

// *********************************************************************//
// The Class CoLLVMPDBUtilities provides a Create and CreateRemote method to          
// create instances of the default interface ILLVMPDBUtilities exposed by              
// the CoClass LLVMPDBUtilities. The functions are intended to be used by             
// clients wishing to automate the CoClass objects exposed by the         
// server of this typelibrary.                                            
// *********************************************************************//
  CoLLVMPDBUtilities = class
    class function Create: ILLVMPDBUtilities;
    class function CreateRemote(const MachineName: string): ILLVMPDBUtilities;
  end;

implementation

uses System.Win.ComObj;

class function CoLLVMBumpPtrAllocator.Create: ILLVMBumpPtrAllocator;
begin
  Result := CreateComObject(CLASS_LLVMBumpPtrAllocator) as ILLVMBumpPtrAllocator;
end;

class function CoLLVMBumpPtrAllocator.CreateRemote(const MachineName: string): ILLVMBumpPtrAllocator;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_LLVMBumpPtrAllocator) as ILLVMBumpPtrAllocator;
end;

class function CoLLVMMSFBuilder.Create: ILLVMMSFBuilder;
begin
  Result := CreateComObject(CLASS_LLVMMSFBuilder) as ILLVMMSFBuilder;
end;

class function CoLLVMMSFBuilder.CreateRemote(const MachineName: string): ILLVMMSFBuilder;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_LLVMMSFBuilder) as ILLVMMSFBuilder;
end;

class function CoLLVMInfoStreamBuilder.Create: ILLVMInfoStreamBuilder;
begin
  Result := CreateComObject(CLASS_LLVMInfoStreamBuilder) as ILLVMInfoStreamBuilder;
end;

class function CoLLVMInfoStreamBuilder.CreateRemote(const MachineName: string): ILLVMInfoStreamBuilder;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_LLVMInfoStreamBuilder) as ILLVMInfoStreamBuilder;
end;

class function CoLLVMDebugStringTableSubsection.Create: ILLVMDebugStringTableSubsection;
begin
  Result := CreateComObject(CLASS_LLVMDebugStringTableSubsection) as ILLVMDebugStringTableSubsection;
end;

class function CoLLVMDebugStringTableSubsection.CreateRemote(const MachineName: string): ILLVMDebugStringTableSubsection;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_LLVMDebugStringTableSubsection) as ILLVMDebugStringTableSubsection;
end;

class function CoLLVMDebugChecksumsSubsection.Create: ILLVMDebugChecksumsSubsection;
begin
  Result := CreateComObject(CLASS_LLVMDebugChecksumsSubsection) as ILLVMDebugChecksumsSubsection;
end;

class function CoLLVMDebugChecksumsSubsection.CreateRemote(const MachineName: string): ILLVMDebugChecksumsSubsection;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_LLVMDebugChecksumsSubsection) as ILLVMDebugChecksumsSubsection;
end;

class function CoLLVMDebugLinesSubsection.Create: ILLVMDebugLinesSubsection;
begin
  Result := CreateComObject(CLASS_LLVMDebugLinesSubsection) as ILLVMDebugLinesSubsection;
end;

class function CoLLVMDebugLinesSubsection.CreateRemote(const MachineName: string): ILLVMDebugLinesSubsection;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_LLVMDebugLinesSubsection) as ILLVMDebugLinesSubsection;
end;

class function CoLLVMDbiModuleDescriptorBuilder.Create: ILLVMDbiModuleDescriptorBuilder;
begin
  Result := CreateComObject(CLASS_LLVMDbiModuleDescriptorBuilder) as ILLVMDbiModuleDescriptorBuilder;
end;

class function CoLLVMDbiModuleDescriptorBuilder.CreateRemote(const MachineName: string): ILLVMDbiModuleDescriptorBuilder;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_LLVMDbiModuleDescriptorBuilder) as ILLVMDbiModuleDescriptorBuilder;
end;

class function CoLLVMDbiStreamBuilder.Create: ILLVMDbiStreamBuilder;
begin
  Result := CreateComObject(CLASS_LLVMDbiStreamBuilder) as ILLVMDbiStreamBuilder;
end;

class function CoLLVMDbiStreamBuilder.CreateRemote(const MachineName: string): ILLVMDbiStreamBuilder;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_LLVMDbiStreamBuilder) as ILLVMDbiStreamBuilder;
end;

class function CoLLVMTpiStreamBuilder.Create: ILLVMTpiStreamBuilder;
begin
  Result := CreateComObject(CLASS_LLVMTpiStreamBuilder) as ILLVMTpiStreamBuilder;
end;

class function CoLLVMTpiStreamBuilder.CreateRemote(const MachineName: string): ILLVMTpiStreamBuilder;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_LLVMTpiStreamBuilder) as ILLVMTpiStreamBuilder;
end;

class function CoLLVMGSIStreamBuilder.Create: ILLVMGSIStreamBuilder;
begin
  Result := CreateComObject(CLASS_LLVMGSIStreamBuilder) as ILLVMGSIStreamBuilder;
end;

class function CoLLVMGSIStreamBuilder.CreateRemote(const MachineName: string): ILLVMGSIStreamBuilder;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_LLVMGSIStreamBuilder) as ILLVMGSIStreamBuilder;
end;

class function CoLLVMPDBStringTableBuilder.Create: ILLVMPDBStringTableBuilder;
begin
  Result := CreateComObject(CLASS_LLVMPDBStringTableBuilder) as ILLVMPDBStringTableBuilder;
end;

class function CoLLVMPDBStringTableBuilder.CreateRemote(const MachineName: string): ILLVMPDBStringTableBuilder;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_LLVMPDBStringTableBuilder) as ILLVMPDBStringTableBuilder;
end;

class function CoLLVMPDBFileBuilder.Create: ILLVMPDBFileBuilder;
begin
  Result := CreateComObject(CLASS_LLVMPDBFileBuilder) as ILLVMPDBFileBuilder;
end;

class function CoLLVMPDBFileBuilder.CreateRemote(const MachineName: string): ILLVMPDBFileBuilder;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_LLVMPDBFileBuilder) as ILLVMPDBFileBuilder;
end;

class function CoLLVMPDBUtilities.Create: ILLVMPDBUtilities;
begin
  Result := CreateComObject(CLASS_LLVMPDBUtilities) as ILLVMPDBUtilities;
end;

class function CoLLVMPDBUtilities.CreateRemote(const MachineName: string): ILLVMPDBUtilities;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_LLVMPDBUtilities) as ILLVMPDBUtilities;
end;

end.
