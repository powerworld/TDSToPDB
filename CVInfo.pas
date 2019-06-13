unit CVInfo;

interface

// =================================================================================================
// FROM cfinfo.h
// =================================================================================================

type
  PUInt8          = ^UInt8;
  CV_uoff32_t     = UInt32;
  PCV_uoff32_t    = CV_uoff32_t;
  CV_off32_t      = Int32;
  CV_uoff16_t     = UInt16;
  CV_off16_t      = Int16;
  CV_typ16_t      = UInt16;
  CV_typ_t        = UInt32;
  PCV_typ_t       = ^CV_typ_t;
  CV_pubsymflag_t = UInt32;     // must be same as CV_typ_t.
  _2BYTEPAD       = UInt16;
  CV_tkn_t        = UInt32;

  FLOAT10 = TExtendedRec;

const
  CV_SIGNATURE_C6       = 0;  // Actual signature is >64K
  CV_SIGNATURE_C7       = 1;  // First explicit signature
  CV_SIGNATURE_C11      = 2;  // C11 (vc5.x) 32-bit types
  CV_SIGNATURE_C13      = 4;  // C13 (vc7.x) zero terminated names
  CV_SIGNATURE_RESERVED = 5;  // All signatures from 5 to 64K are reserved

  CV_MAXOFFSET = $ffffffff;

type
  SIG70 = TGUID;      // new to 7.0 are 16-byte guid-like signatures
  PSIG70 = ^SIG70;
  PCSIG70 = PSIG70;



(**     CodeView Symbol and Type OMF type information is broken up into two
 *      ranges.  Type indices less than 0x1000 describe type information
 *      that is frequently used.  Type indices above 0x1000 are used to
 *      describe more complex features such as functions, arrays and
 *      structures.
 *)



(**     Primitive types have predefined meaning that is encoded in the
 *      values of the various bit fields in the value.
 *
 *      A CodeView primitive type is defined as:
 *
 *      1 1
 *      1 089  7654  3  210
 *      r mode type  r  sub
 *
 *      Where
 *          mode is the pointer mode
 *          type is a type indicator
 *          sub  is a subtype enumeration
 *          r    is a reserved field
 *
 *      See Microsoft Symbol and Type OMF (Version 4.0) for more
 *      information.
 *)

const
  CV_MMASK       = $700;        // mode mask
  CV_TMASK       = $0f0;        // type mask

// can we use the reserved bit ??
  CV_SMASK       = $00f;        // subtype mask

  CV_MSHIFT      = 8;           // primitive mode right shift count
  CV_TSHIFT      = 4;           // primitive type right shift count
  CV_SSHIFT      = 0;           // primitive subtype right shift count

// macros to extract primitive mode, type and size

function CV_MODE(typ: CV_typ_t): CV_typ_t; inline;
function CV_TYPE(typ: CV_typ_t): CV_typ_t; inline;
function CV_SUBT(typ: CV_typ_t): CV_typ_t; inline;

// macros to insert new primitive mode, type and size

function CV_NEWMODE(typ: CV_typ_t; nm: UInt32): CV_typ_t; inline;
function CV_NEWTYPE(typ: CV_typ_t; nt: UInt32): CV_typ_t; inline;
function CV_NEWSUBT(typ: CV_typ_t; ns: UInt32): CV_typ_t; inline;


const
//     pointer mode enumeration values
  CV_TM_DIRECT = 0;       // mode is not a pointer
  CV_TM_NPTR   = 1;       // mode is a near pointer
  CV_TM_FPTR   = 2;       // mode is a far pointer
  CV_TM_HPTR   = 3;       // mode is a huge pointer
  CV_TM_NPTR32 = 4;       // mode is a 32 bit near pointer
  CV_TM_FPTR32 = 5;       // mode is a 32 bit far pointer
  CV_TM_NPTR64 = 6;       // mode is a 64 bit near pointer
  CV_TM_NPTR128 = 7;      // mode is a 128 bit near pointer




//      type enumeration values


  CV_SPECIAL      = $00;          // special type size values
  CV_SIGNED       = $01;          // signed integral size values
  CV_UNSIGNED     = $02;          // unsigned integral size values
  CV_BOOLEAN      = $03;          // Boolean size values
  CV_REAL         = $04;          // real number size values
  CV_COMPLEX      = $05;          // complex number size values
  CV_SPECIAL2     = $06;          // second set of special types
  CV_INT          = $07;          // integral (int) values
  CV_CVRESERVED   = $0f;




//      subtype enumeration values for CV_SPECIAL


  CV_SP_NOTYPE    = $00;
  CV_SP_ABS       = $01;
  CV_SP_SEGMENT   = $02;
  CV_SP_VOID      = $03;
  CV_SP_CURRENCY  = $04;
  CV_SP_NBASICSTR = $05;
  CV_SP_FBASICSTR = $06;
  CV_SP_NOTTRANS  = $07;
  CV_SP_HRESULT   = $08;




//      subtype enumeration values for CV_SPECIAL2


  CV_S2_BIT       = $00;
  CV_S2_PASCHAR   = $01;          // Pascal CHAR
  CV_S2_BOOL32FF  = $02;          // 32-bit BOOL where true is 0xffffffff





//      subtype enumeration values for CV_SIGNED, CV_UNSIGNED and CV_BOOLEAN


  CV_IN_1BYTE     = $00;
  CV_IN_2BYTE     = $01;
  CV_IN_4BYTE     = $02;
  CV_IN_8BYTE     = $03;
  CV_IN_16BYTE    = $04;





//      subtype enumeration values for CV_REAL and CV_COMPLEX


  CV_RC_REAL32    = $00;
  CV_RC_REAL64    = $01;
  CV_RC_REAL80    = $02;
  CV_RC_REAL128   = $03;
  CV_RC_REAL48    = $04;
  CV_RC_REAL32PP  = $05;    // 32-bit partial precision real
  CV_RC_REAL16    = $06;




//      subtype enumeration values for CV_INT (really int)


  CV_RI_CHAR      = $00;
  CV_RI_INT1      = $00;
  CV_RI_WCHAR     = $01;
  CV_RI_UINT1     = $01;
  CV_RI_INT2      = $02;
  CV_RI_UINT2     = $03;
  CV_RI_INT4      = $04;
  CV_RI_UINT4     = $05;
  CV_RI_INT8      = $06;
  CV_RI_UINT8     = $07;
  CV_RI_INT16     = $08;
  CV_RI_UINT16    = $09;
  CV_RI_CHAR16    = $0a;  // char16_t
  CV_RI_CHAR32    = $0b;  // char32_t


// macros to check the type of a primitive

function CV_TYP_IS_DIRECT(typ: CV_typ_t): Boolean; inline;
function CV_TYP_IS_PTR(typ: CV_typ_t): Boolean; inline;
function CV_TYP_IS_NPTR(typ: CV_typ_t): Boolean; inline;
function CV_TYP_IS_FPTR(typ: CV_typ_t): Boolean; inline;
function CV_TYP_IS_HPTR(typ: CV_typ_t): Boolean; inline;
function CV_TYP_IS_NPTR32(typ: CV_typ_t): Boolean; inline;
function CV_TYP_IS_FPTR32(typ: CV_typ_t): Boolean; inline;
function CV_TYP_IS_SIGNED(typ: CV_typ_t): Boolean; inline;
function CV_TYP_IS_UNSIGNED(typ: CV_typ_t): Boolean; inline;
function CV_TYP_IS_REAL(typ: CV_typ_t): Boolean; inline;

const
  CV_FIRST_NONPRIM = $1000;

function CV_IS_PRIMITIVE(typ: CV_typ_t): Boolean; inline;
function CV_TYP_IS_COMPLEX(typ: CV_typ_t): Boolean; inline;
function CV_IS_INTERNAL_PTR(typ: CV_typ_t): Boolean; inline;






// selected values for type_index - for a more complete definition, see
// Microsoft Symbol and Type OMF document




//      Special Types

const
//      Special Types

  T_NOTYPE        = $0000;    // uncharacterized type (no type)
  T_ABS           = $0001;    // absolute symbol
  T_SEGMENT       = $0002;    // segment type
  T_VOID          = $0003;    // void
  T_HRESULT       = $0008;    // OLE/COM HRESULT
  T_32PHRESULT    = $0408;    // OLE/COM HRESULT __ptr32 *
  T_64PHRESULT    = $0608;    // OLE/COM HRESULT __ptr64 *

  T_PVOID         = $0103;    // near pointer to void
  T_PFVOID        = $0203;    // far pointer to void
  T_PHVOID        = $0303;    // huge pointer to void
  T_32PVOID       = $0403;    // 32 bit pointer to void
  T_32PFVOID      = $0503;    // 16:32 pointer to void
  T_64PVOID       = $0603;    // 64 bit pointer to void
  T_CURRENCY      = $0004;    // BASIC 8 byte currency value
  T_NBASICSTR     = $0005;    // Near BASIC string
  T_FBASICSTR     = $0006;    // Far BASIC string
  T_NOTTRANS      = $0007;    // type not translated by cvpack
  T_BIT           = $0060;    // bit
  T_PASCHAR       = $0061;    // Pascal CHAR
  T_BOOL32FF      = $0062;    // 32-bit BOOL where true is $ffffffff


//      Character types

  T_CHAR          = $0010;    // 8 bit signed
  T_PCHAR         = $0110;    // 16 bit pointer to 8 bit signed
  T_PFCHAR        = $0210;    // 16:16 far pointer to 8 bit signed
  T_PHCHAR        = $0310;    // 16:16 huge pointer to 8 bit signed
  T_32PCHAR       = $0410;    // 32 bit pointer to 8 bit signed
  T_32PFCHAR      = $0510;    // 16:32 pointer to 8 bit signed
  T_64PCHAR       = $0610;    // 64 bit pointer to 8 bit signed

  T_UCHAR         = $0020;    // 8 bit unsigned
  T_PUCHAR        = $0120;    // 16 bit pointer to 8 bit unsigned
  T_PFUCHAR       = $0220;    // 16:16 far pointer to 8 bit unsigned
  T_PHUCHAR       = $0320;    // 16:16 huge pointer to 8 bit unsigned
  T_32PUCHAR      = $0420;    // 32 bit pointer to 8 bit unsigned
  T_32PFUCHAR     = $0520;    // 16:32 pointer to 8 bit unsigned
  T_64PUCHAR      = $0620;    // 64 bit pointer to 8 bit unsigned


//      really a character types

  T_RCHAR         = $0070;    // really a char
  T_PRCHAR        = $0170;    // 16 bit pointer to a real char
  T_PFRCHAR       = $0270;    // 16:16 far pointer to a real char
  T_PHRCHAR       = $0370;    // 16:16 huge pointer to a real char
  T_32PRCHAR      = $0470;    // 32 bit pointer to a real char
  T_32PFRCHAR     = $0570;    // 16:32 pointer to a real char
  T_64PRCHAR      = $0670;    // 64 bit pointer to a real char


//      really a wide character types

  T_WCHAR         = $0071;    // wide char
  T_PWCHAR        = $0171;    // 16 bit pointer to a wide char
  T_PFWCHAR       = $0271;    // 16:16 far pointer to a wide char
  T_PHWCHAR       = $0371;    // 16:16 huge pointer to a wide char
  T_32PWCHAR      = $0471;    // 32 bit pointer to a wide char
  T_32PFWCHAR     = $0571;    // 16:32 pointer to a wide char
  T_64PWCHAR      = $0671;    // 64 bit pointer to a wide char

//      really a 16-bit unicode char

  T_CHAR16         = $007a;   // 16-bit unicode char
  T_PCHAR16        = $017a;   // 16 bit pointer to a 16-bit unicode char
  T_PFCHAR16       = $027a;   // 16:16 far pointer to a 16-bit unicode char
  T_PHCHAR16       = $037a;   // 16:16 huge pointer to a 16-bit unicode char
  T_32PCHAR16      = $047a;   // 32 bit pointer to a 16-bit unicode char
  T_32PFCHAR16     = $057a;   // 16:32 pointer to a 16-bit unicode char
  T_64PCHAR16      = $067a;   // 64 bit pointer to a 16-bit unicode char

//      really a 32-bit unicode char

  T_CHAR32         = $007b;   // 32-bit unicode char
  T_PCHAR32        = $017b;   // 16 bit pointer to a 32-bit unicode char
  T_PFCHAR32       = $027b;   // 16:16 far pointer to a 32-bit unicode char
  T_PHCHAR32       = $037b;   // 16:16 huge pointer to a 32-bit unicode char
  T_32PCHAR32      = $047b;   // 32 bit pointer to a 32-bit unicode char
  T_32PFCHAR32     = $057b;   // 16:32 pointer to a 32-bit unicode char
  T_64PCHAR32      = $067b;   // 64 bit pointer to a 32-bit unicode char

//      8 bit int types

  T_INT1          = $0068;    // 8 bit signed int
  T_PINT1         = $0168;    // 16 bit pointer to 8 bit signed int
  T_PFINT1        = $0268;    // 16:16 far pointer to 8 bit signed int
  T_PHINT1        = $0368;    // 16:16 huge pointer to 8 bit signed int
  T_32PINT1       = $0468;    // 32 bit pointer to 8 bit signed int
  T_32PFINT1      = $0568;    // 16:32 pointer to 8 bit signed int
  T_64PINT1       = $0668;    // 64 bit pointer to 8 bit signed int

  T_UINT1         = $0069;    // 8 bit unsigned int
  T_PUINT1        = $0169;    // 16 bit pointer to 8 bit unsigned int
  T_PFUINT1       = $0269;    // 16:16 far pointer to 8 bit unsigned int
  T_PHUINT1       = $0369;    // 16:16 huge pointer to 8 bit unsigned int
  T_32PUINT1      = $0469;    // 32 bit pointer to 8 bit unsigned int
  T_32PFUINT1     = $0569;    // 16:32 pointer to 8 bit unsigned int
  T_64PUINT1      = $0669;    // 64 bit pointer to 8 bit unsigned int


//      16 bit short types

  T_SHORT         = $0011;    // 16 bit signed
  T_PSHORT        = $0111;    // 16 bit pointer to 16 bit signed
  T_PFSHORT       = $0211;    // 16:16 far pointer to 16 bit signed
  T_PHSHORT       = $0311;    // 16:16 huge pointer to 16 bit signed
  T_32PSHORT      = $0411;    // 32 bit pointer to 16 bit signed
  T_32PFSHORT     = $0511;    // 16:32 pointer to 16 bit signed
  T_64PSHORT      = $0611;    // 64 bit pointer to 16 bit signed

  T_USHORT        = $0021;    // 16 bit unsigned
  T_PUSHORT       = $0121;    // 16 bit pointer to 16 bit unsigned
  T_PFUSHORT      = $0221;    // 16:16 far pointer to 16 bit unsigned
  T_PHUSHORT      = $0321;    // 16:16 huge pointer to 16 bit unsigned
  T_32PUSHORT     = $0421;    // 32 bit pointer to 16 bit unsigned
  T_32PFUSHORT    = $0521;    // 16:32 pointer to 16 bit unsigned
  T_64PUSHORT     = $0621;    // 64 bit pointer to 16 bit unsigned


//      16 bit int types

  T_INT2          = $0072;    // 16 bit signed int
  T_PINT2         = $0172;    // 16 bit pointer to 16 bit signed int
  T_PFINT2        = $0272;    // 16:16 far pointer to 16 bit signed int
  T_PHINT2        = $0372;    // 16:16 huge pointer to 16 bit signed int
  T_32PINT2       = $0472;    // 32 bit pointer to 16 bit signed int
  T_32PFINT2      = $0572;    // 16:32 pointer to 16 bit signed int
  T_64PINT2       = $0672;    // 64 bit pointer to 16 bit signed int

  T_UINT2         = $0073;    // 16 bit unsigned int
  T_PUINT2        = $0173;    // 16 bit pointer to 16 bit unsigned int
  T_PFUINT2       = $0273;    // 16:16 far pointer to 16 bit unsigned int
  T_PHUINT2       = $0373;    // 16:16 huge pointer to 16 bit unsigned int
  T_32PUINT2      = $0473;    // 32 bit pointer to 16 bit unsigned int
  T_32PFUINT2     = $0573;    // 16:32 pointer to 16 bit unsigned int
  T_64PUINT2      = $0673;    // 64 bit pointer to 16 bit unsigned int


//      32 bit long types

  T_LONG          = $0012;    // 32 bit signed
  T_ULONG         = $0022;    // 32 bit unsigned
  T_PLONG         = $0112;    // 16 bit pointer to 32 bit signed
  T_PULONG        = $0122;    // 16 bit pointer to 32 bit unsigned
  T_PFLONG        = $0212;    // 16:16 far pointer to 32 bit signed
  T_PFULONG       = $0222;    // 16:16 far pointer to 32 bit unsigned
  T_PHLONG        = $0312;    // 16:16 huge pointer to 32 bit signed
  T_PHULONG       = $0322;    // 16:16 huge pointer to 32 bit unsigned

  T_32PLONG       = $0412;    // 32 bit pointer to 32 bit signed
  T_32PULONG      = $0422;    // 32 bit pointer to 32 bit unsigned
  T_32PFLONG      = $0512;    // 16:32 pointer to 32 bit signed
  T_32PFULONG     = $0522;    // 16:32 pointer to 32 bit unsigned
  T_64PLONG       = $0612;    // 64 bit pointer to 32 bit signed
  T_64PULONG      = $0622;    // 64 bit pointer to 32 bit unsigned


//      32 bit int types

  T_INT4          = $0074;    // 32 bit signed int
  T_PINT4         = $0174;    // 16 bit pointer to 32 bit signed int
  T_PFINT4        = $0274;    // 16:16 far pointer to 32 bit signed int
  T_PHINT4        = $0374;    // 16:16 huge pointer to 32 bit signed int
  T_32PINT4       = $0474;    // 32 bit pointer to 32 bit signed int
  T_32PFINT4      = $0574;    // 16:32 pointer to 32 bit signed int
  T_64PINT4       = $0674;    // 64 bit pointer to 32 bit signed int

  T_UINT4         = $0075;    // 32 bit unsigned int
  T_PUINT4        = $0175;    // 16 bit pointer to 32 bit unsigned int
  T_PFUINT4       = $0275;    // 16:16 far pointer to 32 bit unsigned int
  T_PHUINT4       = $0375;    // 16:16 huge pointer to 32 bit unsigned int
  T_32PUINT4      = $0475;    // 32 bit pointer to 32 bit unsigned int
  T_32PFUINT4     = $0575;    // 16:32 pointer to 32 bit unsigned int
  T_64PUINT4      = $0675;    // 64 bit pointer to 32 bit unsigned int


//      64 bit quad types

  T_QUAD          = $0013;    // 64 bit signed
  T_PQUAD         = $0113;    // 16 bit pointer to 64 bit signed
  T_PFQUAD        = $0213;    // 16:16 far pointer to 64 bit signed
  T_PHQUAD        = $0313;    // 16:16 huge pointer to 64 bit signed
  T_32PQUAD       = $0413;    // 32 bit pointer to 64 bit signed
  T_32PFQUAD      = $0513;    // 16:32 pointer to 64 bit signed
  T_64PQUAD       = $0613;    // 64 bit pointer to 64 bit signed

  T_UQUAD         = $0023;    // 64 bit unsigned
  T_PUQUAD        = $0123;    // 16 bit pointer to 64 bit unsigned
  T_PFUQUAD       = $0223;    // 16:16 far pointer to 64 bit unsigned
  T_PHUQUAD       = $0323;    // 16:16 huge pointer to 64 bit unsigned
  T_32PUQUAD      = $0423;    // 32 bit pointer to 64 bit unsigned
  T_32PFUQUAD     = $0523;    // 16:32 pointer to 64 bit unsigned
  T_64PUQUAD      = $0623;    // 64 bit pointer to 64 bit unsigned


//      64 bit int types

  T_INT8          = $0076;    // 64 bit signed int
  T_PINT8         = $0176;    // 16 bit pointer to 64 bit signed int
  T_PFINT8        = $0276;    // 16:16 far pointer to 64 bit signed int
  T_PHINT8        = $0376;    // 16:16 huge pointer to 64 bit signed int
  T_32PINT8       = $0476;    // 32 bit pointer to 64 bit signed int
  T_32PFINT8      = $0576;    // 16:32 pointer to 64 bit signed int
  T_64PINT8       = $0676;    // 64 bit pointer to 64 bit signed int

  T_UINT8         = $0077;    // 64 bit unsigned int
  T_PUINT8        = $0177;    // 16 bit pointer to 64 bit unsigned int
  T_PFUINT8       = $0277;    // 16:16 far pointer to 64 bit unsigned int
  T_PHUINT8       = $0377;    // 16:16 huge pointer to 64 bit unsigned int
  T_32PUINT8      = $0477;    // 32 bit pointer to 64 bit unsigned int
  T_32PFUINT8     = $0577;    // 16:32 pointer to 64 bit unsigned int
  T_64PUINT8      = $0677;    // 64 bit pointer to 64 bit unsigned int


//      128 bit octet types

  T_OCT           = $0014;    // 128 bit signed
  T_POCT          = $0114;    // 16 bit pointer to 128 bit signed
  T_PFOCT         = $0214;    // 16:16 far pointer to 128 bit signed
  T_PHOCT         = $0314;    // 16:16 huge pointer to 128 bit signed
  T_32POCT        = $0414;    // 32 bit pointer to 128 bit signed
  T_32PFOCT       = $0514;    // 16:32 pointer to 128 bit signed
  T_64POCT        = $0614;    // 64 bit pointer to 128 bit signed

  T_UOCT          = $0024;    // 128 bit unsigned
  T_PUOCT         = $0124;    // 16 bit pointer to 128 bit unsigned
  T_PFUOCT        = $0224;    // 16:16 far pointer to 128 bit unsigned
  T_PHUOCT        = $0324;    // 16:16 huge pointer to 128 bit unsigned
  T_32PUOCT       = $0424;    // 32 bit pointer to 128 bit unsigned
  T_32PFUOCT      = $0524;    // 16:32 pointer to 128 bit unsigned
  T_64PUOCT       = $0624;    // 64 bit pointer to 128 bit unsigned


//      128 bit int types

  T_INT16         = $0078;    // 128 bit signed int
  T_PINT16        = $0178;    // 16 bit pointer to 128 bit signed int
  T_PFINT16       = $0278;    // 16:16 far pointer to 128 bit signed int
  T_PHINT16       = $0378;    // 16:16 huge pointer to 128 bit signed int
  T_32PINT16      = $0478;    // 32 bit pointer to 128 bit signed int
  T_32PFINT16     = $0578;    // 16:32 pointer to 128 bit signed int
  T_64PINT16      = $0678;    // 64 bit pointer to 128 bit signed int

  T_UINT16        = $0079;    // 128 bit unsigned int
  T_PUINT16       = $0179;    // 16 bit pointer to 128 bit unsigned int
  T_PFUINT16      = $0279;    // 16:16 far pointer to 128 bit unsigned int
  T_PHUINT16      = $0379;    // 16:16 huge pointer to 128 bit unsigned int
  T_32PUINT16     = $0479;    // 32 bit pointer to 128 bit unsigned int
  T_32PFUINT16    = $0579;    // 16:32 pointer to 128 bit unsigned int
  T_64PUINT16     = $0679;    // 64 bit pointer to 128 bit unsigned int


//      16 bit real types

  T_REAL16        = $0046;    // 16 bit real
  T_PREAL16       = $0146;    // 16 bit pointer to 16 bit real
  T_PFREAL16      = $0246;    // 16:16 far pointer to 16 bit real
  T_PHREAL16      = $0346;    // 16:16 huge pointer to 16 bit real
  T_32PREAL16     = $0446;    // 32 bit pointer to 16 bit real
  T_32PFREAL16    = $0546;    // 16:32 pointer to 16 bit real
  T_64PREAL16     = $0646;    // 64 bit pointer to 16 bit real


//      32 bit real types

  T_REAL32        = $0040;    // 32 bit real
  T_PREAL32       = $0140;    // 16 bit pointer to 32 bit real
  T_PFREAL32      = $0240;    // 16:16 far pointer to 32 bit real
  T_PHREAL32      = $0340;    // 16:16 huge pointer to 32 bit real
  T_32PREAL32     = $0440;    // 32 bit pointer to 32 bit real
  T_32PFREAL32    = $0540;    // 16:32 pointer to 32 bit real
  T_64PREAL32     = $0640;    // 64 bit pointer to 32 bit real


//      32 bit partial-precision real types

  T_REAL32PP      = $0045;    // 32 bit PP real
  T_PREAL32PP     = $0145;    // 16 bit pointer to 32 bit PP real
  T_PFREAL32PP    = $0245;    // 16:16 far pointer to 32 bit PP real
  T_PHREAL32PP    = $0345;    // 16:16 huge pointer to 32 bit PP real
  T_32PREAL32PP   = $0445;    // 32 bit pointer to 32 bit PP real
  T_32PFREAL32PP  = $0545;    // 16:32 pointer to 32 bit PP real
  T_64PREAL32PP   = $0645;    // 64 bit pointer to 32 bit PP real


//      48 bit real types

  T_REAL48        = $0044;    // 48 bit real
  T_PREAL48       = $0144;    // 16 bit pointer to 48 bit real
  T_PFREAL48      = $0244;    // 16:16 far pointer to 48 bit real
  T_PHREAL48      = $0344;    // 16:16 huge pointer to 48 bit real
  T_32PREAL48     = $0444;    // 32 bit pointer to 48 bit real
  T_32PFREAL48    = $0544;    // 16:32 pointer to 48 bit real
  T_64PREAL48     = $0644;    // 64 bit pointer to 48 bit real


//      64 bit real types

  T_REAL64        = $0041;    // 64 bit real
  T_PREAL64       = $0141;    // 16 bit pointer to 64 bit real
  T_PFREAL64      = $0241;    // 16:16 far pointer to 64 bit real
  T_PHREAL64      = $0341;    // 16:16 huge pointer to 64 bit real
  T_32PREAL64     = $0441;    // 32 bit pointer to 64 bit real
  T_32PFREAL64    = $0541;    // 16:32 pointer to 64 bit real
  T_64PREAL64     = $0641;    // 64 bit pointer to 64 bit real


//      80 bit real types

  T_REAL80        = $0042;    // 80 bit real
  T_PREAL80       = $0142;    // 16 bit pointer to 80 bit real
  T_PFREAL80      = $0242;    // 16:16 far pointer to 80 bit real
  T_PHREAL80      = $0342;    // 16:16 huge pointer to 80 bit real
  T_32PREAL80     = $0442;    // 32 bit pointer to 80 bit real
  T_32PFREAL80    = $0542;    // 16:32 pointer to 80 bit real
  T_64PREAL80     = $0642;    // 64 bit pointer to 80 bit real


//      128 bit real types

  T_REAL128       = $0043;    // 128 bit real
  T_PREAL128      = $0143;    // 16 bit pointer to 128 bit real
  T_PFREAL128     = $0243;    // 16:16 far pointer to 128 bit real
  T_PHREAL128     = $0343;    // 16:16 huge pointer to 128 bit real
  T_32PREAL128    = $0443;    // 32 bit pointer to 128 bit real
  T_32PFREAL128   = $0543;    // 16:32 pointer to 128 bit real
  T_64PREAL128    = $0643;    // 64 bit pointer to 128 bit real


//      32 bit complex types

  T_CPLX32        = $0050;    // 32 bit complex
  T_PCPLX32       = $0150;    // 16 bit pointer to 32 bit complex
  T_PFCPLX32      = $0250;    // 16:16 far pointer to 32 bit complex
  T_PHCPLX32      = $0350;    // 16:16 huge pointer to 32 bit complex
  T_32PCPLX32     = $0450;    // 32 bit pointer to 32 bit complex
  T_32PFCPLX32    = $0550;    // 16:32 pointer to 32 bit complex
  T_64PCPLX32     = $0650;    // 64 bit pointer to 32 bit complex


//      64 bit complex types

  T_CPLX64        = $0051;    // 64 bit complex
  T_PCPLX64       = $0151;    // 16 bit pointer to 64 bit complex
  T_PFCPLX64      = $0251;    // 16:16 far pointer to 64 bit complex
  T_PHCPLX64      = $0351;    // 16:16 huge pointer to 64 bit complex
  T_32PCPLX64     = $0451;    // 32 bit pointer to 64 bit complex
  T_32PFCPLX64    = $0551;    // 16:32 pointer to 64 bit complex
  T_64PCPLX64     = $0651;    // 64 bit pointer to 64 bit complex


//      80 bit complex types

  T_CPLX80        = $0052;    // 80 bit complex
  T_PCPLX80       = $0152;    // 16 bit pointer to 80 bit complex
  T_PFCPLX80      = $0252;    // 16:16 far pointer to 80 bit complex
  T_PHCPLX80      = $0352;    // 16:16 huge pointer to 80 bit complex
  T_32PCPLX80     = $0452;    // 32 bit pointer to 80 bit complex
  T_32PFCPLX80    = $0552;    // 16:32 pointer to 80 bit complex
  T_64PCPLX80     = $0652;    // 64 bit pointer to 80 bit complex


//      128 bit complex types

  T_CPLX128       = $0053;    // 128 bit complex
  T_PCPLX128      = $0153;    // 16 bit pointer to 128 bit complex
  T_PFCPLX128     = $0253;    // 16:16 far pointer to 128 bit complex
  T_PHCPLX128     = $0353;    // 16:16 huge pointer to 128 bit real
  T_32PCPLX128    = $0453;    // 32 bit pointer to 128 bit complex
  T_32PFCPLX128   = $0553;    // 16:32 pointer to 128 bit complex
  T_64PCPLX128    = $0653;    // 64 bit pointer to 128 bit complex


//      boolean types

  T_BOOL08        = $0030;    // 8 bit boolean
  T_PBOOL08       = $0130;    // 16 bit pointer to  8 bit boolean
  T_PFBOOL08      = $0230;    // 16:16 far pointer to  8 bit boolean
  T_PHBOOL08      = $0330;    // 16:16 huge pointer to  8 bit boolean
  T_32PBOOL08     = $0430;    // 32 bit pointer to 8 bit boolean
  T_32PFBOOL08    = $0530;    // 16:32 pointer to 8 bit boolean
  T_64PBOOL08     = $0630;    // 64 bit pointer to 8 bit boolean

  T_BOOL16        = $0031;    // 16 bit boolean
  T_PBOOL16       = $0131;    // 16 bit pointer to 16 bit boolean
  T_PFBOOL16      = $0231;    // 16:16 far pointer to 16 bit boolean
  T_PHBOOL16      = $0331;    // 16:16 huge pointer to 16 bit boolean
  T_32PBOOL16     = $0431;    // 32 bit pointer to 18 bit boolean
  T_32PFBOOL16    = $0531;    // 16:32 pointer to 16 bit boolean
  T_64PBOOL16     = $0631;    // 64 bit pointer to 18 bit boolean

  T_BOOL32        = $0032;    // 32 bit boolean
  T_PBOOL32       = $0132;    // 16 bit pointer to 32 bit boolean
  T_PFBOOL32      = $0232;    // 16:16 far pointer to 32 bit boolean
  T_PHBOOL32      = $0332;    // 16:16 huge pointer to 32 bit boolean
  T_32PBOOL32     = $0432;    // 32 bit pointer to 32 bit boolean
  T_32PFBOOL32    = $0532;    // 16:32 pointer to 32 bit boolean
  T_64PBOOL32     = $0632;    // 64 bit pointer to 32 bit boolean

  T_BOOL64        = $0033;    // 64 bit boolean
  T_PBOOL64       = $0133;    // 16 bit pointer to 64 bit boolean
  T_PFBOOL64      = $0233;    // 16:16 far pointer to 64 bit boolean
  T_PHBOOL64      = $0333;    // 16:16 huge pointer to 64 bit boolean
  T_32PBOOL64     = $0433;    // 32 bit pointer to 64 bit boolean
  T_32PFBOOL64    = $0533;    // 16:32 pointer to 64 bit boolean
  T_64PBOOL64     = $0633;    // 64 bit pointer to 64 bit boolean


//      ???

  T_NCVPTR        = $01f0;    // CV Internal type for created near pointers
  T_FCVPTR        = $02f0;    // CV Internal type for created far pointers
  T_HCVPTR        = $03f0;    // CV Internal type for created huge pointers
  T_32NCVPTR      = $04f0;    // CV Internal type for created near 32-bit pointers
  T_32FCVPTR      = $05f0;    // CV Internal type for created far 32-bit pointers
  T_64NCVPTR      = $06f0;    // CV Internal type for created near 64-bit pointers

(**     No leaf index can have a value of 0x0000.  The leaf indices are
 *      separated into ranges depending upon the use of the type record.
 *      The second range is for the type records that are directly referenced
 *      in symbols. The first range is for type records that are not
 *      referenced by symbols but instead are referenced by other type
 *      records.  All type records must have a starting leaf index in these
 *      first two ranges.  The third range of leaf indices are used to build
 *      up complex lists such as the field list of a class type record.  No
 *      type record can begin with one of the leaf indices. The fourth ranges
 *      of type indices are used to represent numeric data in a symbol or
 *      type record. These leaf indices are greater than 0x8000.  At the
 *      point that type or symbol processor is expecting a numeric field, the
 *      next two bytes in the type record are examined.  If the value is less
 *      than 0x8000, then the two bytes contain the numeric value.  If the
 *      value is greater than 0x8000, then the data follows the leaf index in
 *      a format specified by the leaf index. The final range of leaf indices
 *      are used to force alignment of subfields within a complex type record..
 *)


const
  // leaf indices starting records but referenced from symbol records

  LF_MODIFIER_16t     = $0001;
  LF_POINTER_16t      = $0002;
  LF_ARRAY_16t        = $0003;
  LF_CLASS_16t        = $0004;
  LF_STRUCTURE_16t    = $0005;
  LF_UNION_16t        = $0006;
  LF_ENUM_16t         = $0007;
  LF_PROCEDURE_16t    = $0008;
  LF_MFUNCTION_16t    = $0009;
  LF_VTSHAPE          = $000a;
  LF_COBOL0_16t       = $000b;
  LF_COBOL1           = $000c;
  LF_BARRAY_16t       = $000d;
  LF_LABEL            = $000e;
  LF_NULL             = $000f;
  LF_NOTTRAN          = $0010;
  LF_DIMARRAY_16t     = $0011;
  LF_VFTPATH_16t      = $0012;
  LF_PRECOMP_16t      = $0013;       // not referenced from symbol
  LF_ENDPRECOMP       = $0014;       // not referenced from symbol
  LF_OEM_16t          = $0015;       // oem definable type string
  LF_TYPESERVER_ST    = $0016;       // not referenced from symbol

  // leaf indices starting records but referenced only from type records

  LF_SKIP_16t         = $0200;
  LF_ARGLIST_16t      = $0201;
  LF_DEFARG_16t       = $0202;
  LF_LIST             = $0203;
  LF_FIELDLIST_16t    = $0204;
  LF_DERIVED_16t      = $0205;
  LF_BITFIELD_16t     = $0206;
  LF_METHODLIST_16t   = $0207;
  LF_DIMCONU_16t      = $0208;
  LF_DIMCONLU_16t     = $0209;
  LF_DIMVARU_16t      = $020a;
  LF_DIMVARLU_16t     = $020b;
  LF_REFSYM           = $020c;

  LF_BCLASS_16t       = $0400;
  LF_VBCLASS_16t      = $0401;
  LF_IVBCLASS_16t     = $0402;
  LF_ENUMERATE_ST     = $0403;
  LF_FRIENDFCN_16t    = $0404;
  LF_INDEX_16t        = $0405;
  LF_MEMBER_16t       = $0406;
  LF_STMEMBER_16t     = $0407;
  LF_METHOD_16t       = $0408;
  LF_NESTTYPE_16t     = $0409;
  LF_VFUNCTAB_16t     = $040a;
  LF_FRIENDCLS_16t    = $040b;
  LF_ONEMETHOD_16t    = $040c;
  LF_VFUNCOFF_16t     = $040d;

// 32-bit type index versions of leaves, all have the $1000 bit set
//
  LF_TI16_MAX         = $1000;

  LF_MODIFIER         = $1001;
  LF_POINTER          = $1002;
  LF_ARRAY_ST         = $1003;
  LF_CLASS_ST         = $1004;
  LF_STRUCTURE_ST     = $1005;
  LF_UNION_ST         = $1006;
  LF_ENUM_ST          = $1007;
  LF_PROCEDURE        = $1008;
  LF_MFUNCTION        = $1009;
  LF_COBOL0           = $100a;
  LF_BARRAY           = $100b;
  LF_DIMARRAY_ST      = $100c;
  LF_VFTPATH          = $100d;
  LF_PRECOMP_ST       = $100e;       // not referenced from symbol
  LF_OEM              = $100f;       // oem definable type string
  LF_ALIAS_ST         = $1010;       // alias (typedef) type
  LF_OEM2             = $1011;       // oem definable type string

  // leaf indices starting records but referenced only from type records

  LF_SKIP             = $1200;
  LF_ARGLIST          = $1201;
  LF_DEFARG_ST        = $1202;
  LF_FIELDLIST        = $1203;
  LF_DERIVED          = $1204;
  LF_BITFIELD         = $1205;
  LF_METHODLIST       = $1206;
  LF_DIMCONU          = $1207;
  LF_DIMCONLU         = $1208;
  LF_DIMVARU          = $1209;
  LF_DIMVARLU         = $120a;

  LF_BCLASS           = $1400;
  LF_VBCLASS          = $1401;
  LF_IVBCLASS         = $1402;
  LF_FRIENDFCN_ST     = $1403;
  LF_INDEX            = $1404;
  LF_MEMBER_ST        = $1405;
  LF_STMEMBER_ST      = $1406;
  LF_METHOD_ST        = $1407;
  LF_NESTTYPE_ST      = $1408;
  LF_VFUNCTAB         = $1409;
  LF_FRIENDCLS        = $140a;
  LF_ONEMETHOD_ST     = $140b;
  LF_VFUNCOFF         = $140c;
  LF_NESTTYPEEX_ST    = $140d;
  LF_MEMBERMODIFY_ST  = $140e;
  LF_MANAGED_ST       = $140f;

  // Types w/ SZ names

  LF_ST_MAX           = $1500;

  LF_TYPESERVER       = $1501;       // not referenced from symbol
  LF_ENUMERATE        = $1502;
  LF_ARRAY            = $1503;
  LF_CLASS            = $1504;
  LF_STRUCTURE        = $1505;
  LF_UNION            = $1506;
  LF_ENUM             = $1507;
  LF_DIMARRAY         = $1508;
  LF_PRECOMP          = $1509;       // not referenced from symbol
  LF_ALIAS            = $150a;       // alias (typedef) type
  LF_DEFARG           = $150b;
  LF_FRIENDFCN        = $150c;
  LF_MEMBER           = $150d;
  LF_STMEMBER         = $150e;
  LF_METHOD           = $150f;
  LF_NESTTYPE         = $1510;
  LF_ONEMETHOD        = $1511;
  LF_NESTTYPEEX       = $1512;
  LF_MEMBERMODIFY     = $1513;
  LF_MANAGED          = $1514;
  LF_TYPESERVER2      = $1515;

  LF_STRIDED_ARRAY    = $1516;    // same as LF_ARRAY, but with stride between adjacent elements
  LF_HLSL             = $1517;
  LF_MODIFIER_EX      = $1518;
  LF_INTERFACE        = $1519;
  LF_BINTERFACE       = $151a;
  LF_VECTOR           = $151b;
  LF_MATRIX           = $151c;

  LF_VFTABLE          = $151d;     // a virtual function table
  LF_ENDOFLEAFRECORD  = LF_VFTABLE;

  LF_TYPE_LAST        = $151e;     // one greater than the last type record
  LF_TYPE_MAX         = LF_TYPE_LAST - 1;

  LF_FUNC_ID          = $1601;    // global func ID
  LF_MFUNC_ID         = $1602;    // member func ID
  LF_BUILDINFO        = $1603;    // build info: tool, version, command line, src/pdb file
  LF_SUBSTR_LIST      = $1604;    // similar to LF_ARGLIST, for list of sub strings
  LF_STRING_ID        = $1605;    // string ID

  LF_UDT_SRC_LINE     = $1606;    // source and line on where an UDT is defined
                                  // only generated by compiler

  LF_UDT_MOD_SRC_LINE = $1607;    // module, source and line on where an UDT is defined
                                  // only generated by linker

  LF_ID_LAST          = $1608;    // one greater than the last ID record
  LF_ID_MAX           = LF_ID_LAST - 1;

  LF_NUMERIC          = $8000;
  LF_CHAR             = $8000;
  LF_SHORT            = $8001;
  LF_USHORT           = $8002;
  LF_LONG             = $8003;
  LF_ULONG            = $8004;
  LF_REAL32           = $8005;
  LF_REAL64           = $8006;
  LF_REAL80           = $8007;
  LF_REAL128          = $8008;
  LF_QUADWORD         = $8009;
  LF_UQUADWORD        = $800a;
  LF_REAL48           = $800b;
  LF_COMPLEX32        = $800c;
  LF_COMPLEX64        = $800d;
  LF_COMPLEX80        = $800e;
  LF_COMPLEX128       = $800f;
  LF_VARSTRING        = $8010;

  LF_OCTWORD          = $8017;
  LF_UOCTWORD         = $8018;

  LF_DECIMAL          = $8019;
  LF_DATE             = $801a;
  LF_UTF8STRING       = $801b;

  LF_REAL16           = $801c;

  LF_PAD0             = $f0;
  LF_PAD1             = $f1;
  LF_PAD2             = $f2;
  LF_PAD3             = $f3;
  LF_PAD4             = $f4;
  LF_PAD5             = $f5;
  LF_PAD6             = $f6;
  LF_PAD7             = $f7;
  LF_PAD8             = $f8;
  LF_PAD9             = $f9;
  LF_PAD10            = $fa;
  LF_PAD11            = $fb;
  LF_PAD12            = $fc;
  LF_PAD13            = $fd;
  LF_PAD14            = $fe;
  LF_PAD15            = $ff;


// end of leaf indices




//      Type enum for pointer records
//      Pointers can be one of the following types


    CV_PTR_NEAR         = $00; // 16 bit pointer
    CV_PTR_FAR          = $01; // 16:16 far pointer
    CV_PTR_HUGE         = $02; // 16:16 huge pointer
    CV_PTR_BASE_SEG     = $03; // based on segment
    CV_PTR_BASE_VAL     = $04; // based on value of base
    CV_PTR_BASE_SEGVAL  = $05; // based on segment value of base
    CV_PTR_BASE_ADDR    = $06; // based on address of base
    CV_PTR_BASE_SEGADDR = $07; // based on segment address of base
    CV_PTR_BASE_TYPE    = $08; // based on type
    CV_PTR_BASE_SELF    = $09; // based on self
    CV_PTR_NEAR32       = $0a; // 32 bit pointer
    CV_PTR_FAR32        = $0b; // 16:32 pointer
    CV_PTR_64           = $0c; // 64 bit pointer
    CV_PTR_UNUSEDPTR    = $0d; // first unused pointer type





//      Mode enum for pointers
//      Pointers can have one of the following modes
//
//  To support for l-value and r-value reference, we added CV_PTR_MODE_LVREF
//  and CV_PTR_MODE_RVREF.  CV_PTR_MODE_REF should be removed at some point.
//  We keep it now so that old code that uses it won't be broken.
//

    CV_PTR_MODE_PTR     = $00; // "normal" pointer
    CV_PTR_MODE_REF     = $01; // "old" reference
    CV_PTR_MODE_LVREF   = $01; // l-value reference
    CV_PTR_MODE_PMEM    = $02; // pointer to data member
    CV_PTR_MODE_PMFUNC  = $03; // pointer to member function
    CV_PTR_MODE_RVREF   = $04; // r-value reference
    CV_PTR_MODE_RESERVED= $05; // first unused pointer mode


//      enumeration for pointer-to-member types

    CV_PMTYPE_Undef     = $00; // not specified (pre VC8)
    CV_PMTYPE_D_Single  = $01; // member data, single inheritance
    CV_PMTYPE_D_Multiple= $02; // member data, multiple inheritance
    CV_PMTYPE_D_Virtual = $03; // member data, virtual inheritance
    CV_PMTYPE_D_General = $04; // member data, most general
    CV_PMTYPE_F_Single  = $05; // member function, single inheritance
    CV_PMTYPE_F_Multiple= $06; // member function, multiple inheritance
    CV_PMTYPE_F_Virtual = $07; // member function, virtual inheritance
    CV_PMTYPE_F_General = $08; // member function, most general

//      enumeration for method properties

    CV_MTvanilla        = $00;
    CV_MTvirtual        = $01;
    CV_MTstatic         = $02;
    CV_MTfriend         = $03;
    CV_MTintro          = $04;
    CV_MTpurevirt       = $05;
    CV_MTpureintro      = $06;




//      enumeration for virtual shape table entries

    CV_VTS_near         = $00;
    CV_VTS_far          = $01;
    CV_VTS_thin         = $02;
    CV_VTS_outer        = $03;
    CV_VTS_meta         = $04;
    CV_VTS_near32       = $05;
    CV_VTS_far32        = $06;
    CV_VTS_unused       = $07;




//      enumeration for LF_LABEL address modes

    CV_LABEL_NEAR = 0;       // near return
    CV_LABEL_FAR  = 4;       // far return



//      enumeration for LF_MODIFIER values
type

  PCV_modifier_t = ^CV_modifier_t;
  CV_modifier_t = packed record
    _props: UInt16;
    function GetMOD_const: UInt16; inline;
    function GetMOD_volatile: UInt16; inline;
    function GetMOD_unaligned: UInt16; inline;
    function GetMOD_unused: UInt16; inline;
    procedure SetMOD_const(Value: UInt16); inline;
    procedure SetMOD_volatile(Value: UInt16); inline;
    procedure SetMOD_unaligned(Value: UInt16); inline;
    procedure SetMOD_unused(Value: UInt16); inline;
    property MOD_const: UInt16 read GetMOD_const write SetMOD_const;
    property MOD_volatile: UInt16 read GetMOD_volatile write SetMOD_volatile;
    property MOD_unaligned: UInt16 read GetMOD_unaligned write SetMOD_unaligned;
    property MOD_unused: UInt16 read GetMOD_unused write SetMOD_unused;
//    unsigned short  MOD_const       :1;
//    unsigned short  MOD_volatile    :1;
//    unsigned short  MOD_unaligned   :1;
//    unsigned short  MOD_unused      :13;
  end;




//  enumeration for HFA kinds

const
   CV_HFA_none   =  0;
   CV_HFA_float  =  1;
   CV_HFA_double =  2;
   CV_HFA_other  =  3;

//  enumeration for MoCOM UDT kinds

    CV_MOCOM_UDT_none      = 0;
    CV_MOCOM_UDT_ref       = 1;
    CV_MOCOM_UDT_value     = 2;
    CV_MOCOM_UDT_interface = 3;

//  bit field structure describing class/struct/union/enum properties

type
  PCV_prop_t = ^CV_prop_t;
  CV_prop_t = packed record
    _props: UInt16;
    function Getpacked: UInt16; inline;
    function Getctor: UInt16; inline;
    function Getovlops: UInt16; inline;
    function Getisnested: UInt16; inline;
    function Getcnested: UInt16; inline;
    function Getopassign: UInt16; inline;
    function Getopcast: UInt16; inline;
    function Getfwdref: UInt16; inline;
    function Getscoped: UInt16; inline;
    function Gethasuniquename: UInt16; inline;
    function Getsealed: UInt16; inline;
    function Gethfa: UInt16; inline;
    function Getintrinsic: UInt16; inline;
    function Getmocom: UInt16; inline;
    procedure Setpacked(Value: UInt16); inline;
    procedure Setctor(Value: UInt16); inline;
    procedure Setovlops(Value: UInt16); inline;
    procedure Setisnested(Value: UInt16); inline;
    procedure Setcnested(Value: UInt16); inline;
    procedure Setopassign(Value: UInt16); inline;
    procedure Setopcast(Value: UInt16); inline;
    procedure Setfwdref(Value: UInt16); inline;
    procedure Setscoped(Value: UInt16); inline;
    procedure Sethasuniquename(Value: UInt16); inline;
    procedure Setsealed(Value: UInt16); inline;
    procedure Sethfa(Value: UInt16); inline;
    procedure Setintrinsic(Value: UInt16); inline;
    procedure Setmocom(Value: UInt16); inline;
    property &packed: UInt16 read Getpacked write Setpacked;
    property ctor: UInt16 read Getctor write Setctor;
    property ovlops: UInt16 read Getovlops write Setovlops;
    property isnested: UInt16 read Getisnested write Setisnested;
    property cnested: UInt16 read Getcnested write Setcnested;
    property opassign: UInt16 read Getopassign write Setopassign;
    property opcast: UInt16 read Getopcast write Setopcast;
    property fwdref: UInt16 read Getfwdref write Setfwdref;
    property scoped: UInt16 read Getscoped write Setscoped;
    property hasuniquename: UInt16 read Gethasuniquename write Sethasuniquename;
    property &sealed: UInt16 read Getsealed write Setsealed;
    property hfa: UInt16 read Gethfa write Sethfa;
    property intrinsic: UInt16 read Getintrinsic write Setintrinsic;
    property mocom: UInt16 read Getmocom write Setmocom;
//    unsigned short  packed      :1;     // true if structure is packed
//    unsigned short  ctor        :1;     // true if constructors or destructors present
//    unsigned short  ovlops      :1;     // true if overloaded operators present
//    unsigned short  isnested    :1;     // true if this is a nested class
//    unsigned short  cnested     :1;     // true if this class contains nested types
//    unsigned short  opassign    :1;     // true if overloaded assignment (=)
//    unsigned short  opcast      :1;     // true if casting methods
//    unsigned short  fwdref      :1;     // true if forward reference (incomplete defn)
//    unsigned short  scoped      :1;     // scoped definition
//    unsigned short  hasuniquename :1;   // true if there is a decorated name following the regular name
//    unsigned short  sealed      :1;     // true if class cannot be used as a base class
//    unsigned short  hfa         :2;     // CV_HFA_e
//    unsigned short  intrinsic   :1;     // true if class is an intrinsic type (e.g. __m128d)
//    unsigned short  mocom       :2;     // CV_MOCOM_UDT_e
  end;




//  class field attribute

  PCV_fldattr_t = ^CV_fldattr_t;
  CV_fldattr_t = packed record
    _props: UInt16;
    function Getaccess: UInt16; inline;
    function Getmprop: UInt16; inline;
    function Getpseudo: UInt16; inline;
    function Getnoinherit: UInt16; inline;
    function Getnoconstruct: UInt16; inline;
    function Getcompgenx: UInt16; inline;
    function Getsealed: UInt16; inline;
    function Getunused: UInt16; inline;
    procedure Setaccess(Value: UInt16); inline;
    procedure Setmprop(Value: UInt16); inline;
    procedure Setpseudo(Value: UInt16); inline;
    procedure Setnoinherit(Value: UInt16); inline;
    procedure Setnoconstruct(Value: UInt16); inline;
    procedure Setcompgenx(Value: UInt16); inline;
    procedure Setsealed(Value: UInt16); inline;
    procedure Setunused(Value: UInt16); inline;
    property access: UInt16 read Getaccess write Setaccess;
    property mprop: UInt16 read Getmprop write Setmprop;
    property pseudo: UInt16 read Getpseudo write Setpseudo;
    property noinherit: UInt16 read Getnoinherit write Setnoinherit;
    property noconstruct: UInt16 read Getnoconstruct write Setnoconstruct;
    property compgenx: UInt16 read Getcompgenx write Setcompgenx;
    property &sealed: UInt16 read Getsealed write Setsealed;
    property unused: UInt16 read Getunused write Setunused;
//    unsigned short  access      :2;     // access protection CV_access_t
//    unsigned short  mprop       :3;     // method properties CV_methodprop_t
//    unsigned short  pseudo      :1;     // compiler generated fcn and does not exist
//    unsigned short  noinherit   :1;     // true if class cannot be inherited
//    unsigned short  noconstruct :1;     // true if class cannot be constructed
//    unsigned short  compgenx    :1;     // compiler generated fcn and does exist
//    unsigned short  sealed      :1;     // true if method cannot be overridden
//    unsigned short  unused      :6;     // unused
  end;


//  function flags

  PCV_funcattr_t = ^CV_funcattr_t;
  CV_funcattr_t = packed record
    _props: UInt8;
    function Getcxxreturnudt: UInt8; inline;
    function Getctor: UInt8; inline;
    function Getctorvbase: UInt8; inline;
    function Getunused: UInt8; inline;
    procedure Setcxxreturnudt(Value: UInt8); inline;
    procedure Setctor(Value: UInt8); inline;
    procedure Setctorvbase(Value: UInt8); inline;
    procedure Setunused(Value: UInt8); inline;
    property cxxreturnudt: UInt8 read Getcxxreturnudt write Setcxxreturnudt;
    property ctor: UInt8 read Getctor write Setctor;
    property ctorvbase: UInt8 read Getctorvbase write Setctorvbase;
    property unused: UInt8 read Getunused write Setunused;
//    unsigned char  cxxreturnudt :1;  // true if C++ style ReturnUDT
//    unsigned char  ctor         :1;  // true if func is an instance constructor
//    unsigned char  ctorvbase    :1;  // true if func is an instance constructor of a class with virtual bases
//    unsigned char  unused       :5;  // unused
  end;


//  matrix flags

  PCV_matrixattr_t = ^CV_matrixattr_t;
  CV_matrixattr_t = packed record
    _props: UInt8;
    function Getrow_major: UInt8; inline;
    function Getunused: UInt8; inline;
    procedure Setrow_major(Value: UInt8); inline;
    procedure Setunused(Value: UInt8); inline;
    property row_major: UInt8 read Getrow_major write Setrow_major;
    property unused: UInt8 read Getunused write Setunused;
//    unsigned char  row_major   :1;   // true if matrix has row-major layout (column-major is default)
//    unsigned char  unused      :7;   // unused
  end;


//  Structures to access to the type records


  PTYPTYPE = ^TYPTYPE;
  TYPTYPE = packed record
    len: UInt16;
    leaf: UInt16;
    data: array [0..0] of UInt8;
  end;

function NextType(pType: PTYPTYPE): PTYPTYPE; inline;

const
    CV_PDM16_NONVIRT    = $00; // 16:16 data no virtual fcn or base
    CV_PDM16_VFCN       = $01; // 16:16 data with virtual functions
    CV_PDM16_VBASE      = $02; // 16:16 data with virtual bases
    CV_PDM32_NVVFCN     = $03; // 16:32 data w/wo virtual functions
    CV_PDM32_VBASE      = $04; // 16:32 data with virtual bases

    CV_PMF16_NEARNVSA   = $05; // 16:16 near method nonvirtual single address point
    CV_PMF16_NEARNVMA   = $06; // 16:16 near method nonvirtual multiple address points
    CV_PMF16_NEARVBASE  = $07; // 16:16 near method virtual bases
    CV_PMF16_FARNVSA    = $08; // 16:16 far method nonvirtual single address point
    CV_PMF16_FARNVMA    = $09; // 16:16 far method nonvirtual multiple address points
    CV_PMF16_FARVBASE   = $0a; // 16:16 far method virtual bases

    CV_PMF32_NVSA       = $0b; // 16:32 method nonvirtual single address point
    CV_PMF32_NVMA       = $0c; // 16:32 method nonvirtual multiple address point
    CV_PMF32_VBASE      = $0d; // 16:32 method virtual bases



//  memory representation of pointer to member.  These representations are
//  indexed by the enumeration above in the LF_POINTER record




//  representation of a 16:16 pointer to data for a class with no
//  virtual functions or virtual bases


type
  PCV_PDMR16_NONVIRT = ^CV_PDMR16_NONVIRT;
  CV_PDMR16_NONVIRT = packed record
    mdisp: CV_off16_t;          // displacement to data (NULL = -1)
  end;




//  representation of a 16:16 pointer to data for a class with virtual
//  functions


  PCV_PMDR16_VFCN = ^CV_PMDR16_VFCN;
  CV_PMDR16_VFCN = packed record
    mdisp: CV_off16_t;          // displacement to data ( NULL = 0)
  end;




//  representation of a 16:16 pointer to data for a class with
//  virtual bases


  PCV_PDMR16_VBASE = ^CV_PDMR16_VBASE;
  CV_PDMR16_VBASE = packed record
    mdisp: CV_off16_t;          // displacement to data
    pdisp: CV_off16_t;          // this pointer displacement to vbptr
    vdisp: CV_off16_t;          // displacement within vbase table
                                // NULL = (,,0xffff)
  end;




//  representation of a 32 bit pointer to data for a class with
//  or without virtual functions and no virtual bases


  PCV_PDMR32_NVVFCN = ^CV_PDMR32_NVVFCN;
  CV_PDMR32_NVVFCN = packed record
    mdisp: CV_off32_t;          // displacement to data (NULL = 0x80000000)
  end;




//  representation of a 32 bit pointer to data for a class
//  with virtual bases


  PCV_PDMR32_VBASE = ^CV_PDMR32_VBASE;
  CV_PDMR32_VBASE = packed record
    mdisp: CV_off32_t;          // displacement to data
    pdisp: CV_off32_t;          // this pointer displacement
    vdisp: CV_off32_t;          // vbase table displacement
                                // NULL = (,,0xffffffff)
  end;




//  representation of a 16:16 pointer to near member function for a
//  class with no virtual functions or bases and a single address point


  PCV_PMFR16_NEARNVSA = ^CV_PMFR16_NEARNVSA;
  CV_PMFR16_NEARNVSA = packed record
    off:   CV_uoff16_t;         // near address of function (NULL = 0)
  end;



//  representation of a 16 bit pointer to member functions of a
//  class with no virtual bases and multiple address points


  PCV_PMFR16_NEARNVMA = ^CV_PMFR16_NEARNVMA;
  CV_PMFR16_NEARNVMA = packed record
    off:   CV_uoff16_t;         // offset of function (NULL = 0,x)
    disp:  Int16;
  end;




//  representation of a 16 bit pointer to member function of a
//  class with virtual bases


  PCV_PMFR16_NEARVBASE = ^CV_PMFR16_NEARVBASE;
  CV_PMFR16_NEARVBASE = packed record
    off:   CV_uoff16_t;         // offset of function (NULL = 0,x,x,x)
    mdisp: CV_off16_t;          // displacement to data
    pdisp: CV_off16_t;          // this pointer displacement
    vdisp: CV_off16_t;          // vbase table displacement
  end;




//  representation of a 16:16 pointer to far member function for a
//  class with no virtual bases and a single address point


  PCV_PMFR16_FARNVSA = ^CV_PMFR16_FARNVSA;
  CV_PMFR16_FARNVSA = packed record
    off:   CV_uoff16_t;         // offset of function (NULL = 0:0)
    seg:   UInt16;              // segment of function
  end;




//  representation of a 16:16 far pointer to member functions of a
//  class with no virtual bases and multiple address points


  PCV_PMFR16_FARNVMA = ^CV_PMFR16_FARNVMA;
  CV_PMFR16_FARNVMA = packed record
    off:   CV_uoff16_t;         // offset of function (NULL = 0:0,x)
    seg:   UInt16;
    disp:  Int16;
  end;




//  representation of a 16:16 far pointer to member function of a
//  class with virtual bases


  PCV_PMFR16_FARVBASE = ^CV_PMFR16_FARVBASE;
  CV_PMFR16_FARVBASE = packed record
    off:   CV_uoff16_t;         // offset of function (NULL = 0:0,x,x,x)
    seg:   UInt16;
    mdisp: CV_off16_t;          // displacement to data
    pdisp: CV_off16_t;          // this pointer displacement
    vdisp: CV_off16_t;          // vbase table displacement
  end;




//  representation of a 32 bit pointer to member function for a
//  class with no virtual bases and a single address point


  PCV_PMFR32_NVSA = ^CV_PMFR32_NVSA;
  CV_PMFR32_NVSA = packed record
    off:   CV_uoff32_t;         // near address of function (NULL = 0L)
  end;




//  representation of a 32 bit pointer to member function for a
//  class with no virtual bases and multiple address points


  PCV_PMFR32_NVMA = ^CV_PMFR32_NVMA;
  CV_PMFR32_NVMA = packed record
    off:  CV_uoff32_t;          // near address of function (NULL = 0L,x)
    disp: CV_off32_t;
  end;




//  representation of a 32 bit pointer to member function for a
//  class with virtual bases


  PCV_PMFR32_VBASE = ^CV_PMFR32_VBASE;
  CV_PMFR32_VBASE = packed record
    off:   CV_uoff32_t;         // near address of function (NULL = 0L,x,x,x)
    mdisp: CV_off32_t;          // displacement to data
    pdisp: CV_off32_t;          // this pointer displacement
    vdisp: CV_off32_t;          // vbase table displacement
  end;





//  Easy leaf - used for generic casting to reference leaf field
//  of a subfield of a complex list

  PlfEasy = ^lfEasy;
  lfEasy = packed record
    leaf: UInt16;                 // LF_...
  end;


(**     The following type records are basically variant records of the
 *      above structure.  The "unsigned short leaf" of the above structure and
 *      the "unsigned short leaf" of the following type definitions are the same
 *      symbol.  When the OMF record is locked via the MHOMFLock API
 *      call, the address of the "unsigned short leaf" is returned
 *)

(**     Notes on alignment
 *      Alignment of the fields in most of the type records is done on the
 *      basis of the TYPTYPE record base.  That is why in most of the lf*
 *      records that the CV_typ_t (32-bit types) is located on what appears to
 *      be a offset mod 4 == 2 boundary.  The exception to this rule are those
 *      records that are in a list (lfFieldList, lfMethodList), which are
 *      aligned to their own bases since they don't have the length field
 *)

(**** Change log for 16-bit to 32-bit type and symbol records

    Record type         Change (f == field arrangement, p = padding added)
    ----------------------------------------------------------------------
    lfModifer           f
    lfPointer           fp
    lfClass             f
    lfStructure         f
    lfUnion             f
    lfEnum              f
    lfVFTPath           p
    lfPreComp           p
    lfOEM               p
    lfArgList           p
    lfDerived           p
    mlMethod            p   (method list member)
    lfBitField          f
    lfDimCon            f
    lfDimVar            p
    lfIndex             p   (field list member)
    lfBClass            f   (field list member)
    lfVBClass           f   (field list member)
    lfFriendCls         p   (field list member)
    lfFriendFcn         p   (field list member)
    lfMember            f   (field list member)
    lfSTMember          f   (field list member)
    lfVFuncTab          p   (field list member)
    lfVFuncOff          p   (field list member)
    lfNestType          p   (field list member)

    DATASYM32           f
    PROCSYM32           f
    VPATHSYM32          f
    REGREL32            f
    THREADSYM32         f
    PROCSYMMIPS         f


*)

//      Type record for LF_MODIFIER

  PlfModifier_16t = ^lfModifier_16t;
  lfModifier_16t = packed record
    leaf: UInt16;                   // LF_MODIFIER_16t
    attr: CV_modifier_t;            // modifier attribute modifier_t
    &type: CV_typ16_t;              // modified type
  end;

  PlfModifier = ^lfModifier;
  lfModifier = packed record
    leaf: UInt16;                   // LF_MODIFIER
    &type: CV_typ_t;                // modified type
    attr: CV_modifier_t;            // modifier attribute modifier_t
  end;




//      type record for LF_POINTER

  PlfPointer_16t = ^lfPointer_16t;
  lfPointer_16t = packed record
  public type
    PlfPointerAttr_16t = ^lfPointerAttr_16t;
    lfPointerAttr_16t = packed record
      _props: UInt16;
      function Getptrtype: UInt16; inline;
      function Getptrmode: UInt16; inline;
      function Getisflat32: UInt16; inline;
      function Getisvolatile: UInt16; inline;
      function Getisconst: UInt16; inline;
      function Getisunaligned: UInt16; inline;
      function Getunused: UInt16; inline;
      procedure Setptrtype(Value: UInt16); inline;
      procedure Setptrmode(Value: UInt16); inline;
      procedure Setisflat32(Value: UInt16); inline;
      procedure Setisvolatile(Value: UInt16); inline;
      procedure Setisconst(Value: UInt16); inline;
      procedure Setisunaligned(Value: UInt16); inline;
      procedure Setunused(Value: UInt16); inline;
      property ptrtype: UInt16 read Getptrtype write Setptrtype;
      property ptrmode: UInt16 read Getptrmode write Setptrmode;
      property isflat32: UInt16 read Getisflat32 write Setisflat32;
      property isvolatile: UInt16 read Getisvolatile write Setisvolatile;
      property isconst: UInt16 read Getisconst write Setisconst;
      property isunaligned: UInt16 read Getisunaligned write Setisunaligned;
      property unused: UInt16 read Getunused write Setunused;
//      unsigned char   ptrtype     :5; // ordinal specifying pointer type (CV_ptrtype_e)
//      unsigned char   ptrmode     :3; // ordinal specifying pointer mode (CV_ptrmode_e)
//      unsigned char   isflat32    :1; // true if 0:32 pointer
//      unsigned char   isvolatile  :1; // TRUE if volatile pointer
//      unsigned char   isconst     :1; // TRUE if const pointer
//      unsigned char   isunaligned :1; // TRUE if unaligned pointer
//      unsigned char   unused      :4;
    end;
  public
    leaf: UInt16;                   // LF_POINTER_16t
    attr: lfPointerAttr_16t;
    utype: CV_typ16_t;              // type index of the underlying type
  case Integer of
    0: (
      pmclass: CV_typ16_t;          // index of containing class for pointer to member
      pmenum: UInt16;               // enumeration specifying pm format (CV_pmtype_e)
    );
    1: (
      bseg: UInt16;                 // base segment if PTR_BASE_SEG
    );
    2: (
      Sym: array [0..0] of UInt8;   // copy of base symbol record (including length)
    );
    3: (
      index: CV_typ16_t;            // type index if CV_PTR_BASE_TYPE
      name: array [0..0] of UInt8;  // name of base type
    );
  end;

  PlfPointer = ^lfPointer;
  lfPointer = packed record
  public type
    PlfPointerAttr = ^lfPointerAttr;
    lfPointerAttr = packed record
      _props: UInt32;
      function Getptrtype: UInt32; inline;
      function Getptrmode: UInt32; inline;
      function Getisflat32: UInt32; inline;
      function Getisvolatile: UInt32; inline;
      function Getisconst: UInt32; inline;
      function Getisunaligned: UInt32; inline;
      function Getisrestrict: UInt32; inline;
      function Getsize: UInt32; inline;
      function Getismocom: UInt32; inline;
      function Getislref: UInt32; inline;
      function Getisrref: UInt32; inline;
      function Getunused: UInt32; inline;
      procedure Setptrtype(Value: UInt32); inline;
      procedure Setptrmode(Value: UInt32); inline;
      procedure Setisflat32(Value: UInt32); inline;
      procedure Setisvolatile(Value: UInt32); inline;
      procedure Setisconst(Value: UInt32); inline;
      procedure Setisunaligned(Value: UInt32); inline;
      procedure Setisrestrict(Value: UInt32); inline;
      procedure Setsize(Value: UInt32); inline;
      procedure Setismocom(Value: UInt32); inline;
      procedure Setislref(Value: UInt32); inline;
      procedure Setisrref(Value: UInt32); inline;
      procedure Setunused(Value: UInt32); inline;
      property ptrtype: UInt32 read Getptrtype write Setptrtype;
      property ptrmode: UInt32 read Getptrmode write Setptrmode;
      property isflat32: UInt32 read Getisflat32 write Setisflat32;
      property isvolatile: UInt32 read Getisvolatile write Setisvolatile;
      property isconst: UInt32 read Getisconst write Setisconst;
      property isunaligned: UInt32 read Getisunaligned write Setisunaligned;
      property isrestrict: UInt32 read Getisrestrict write Setisrestrict;
      property size: UInt32 read Getsize write Setsize;
      property ismocom: UInt32 read Getismocom write Setismocom;
      property islref: UInt32 read Getislref write Setislref;
      property isrref: UInt32 read Getisrref write Setisrref;
      property unused: UInt32 read Getunused write Setunused;
//      unsigned long   ptrtype     :5; // ordinal specifying pointer type (CV_ptrtype_e)
//      unsigned long   ptrmode     :3; // ordinal specifying pointer mode (CV_ptrmode_e)
//      unsigned long   isflat32    :1; // true if 0:32 pointer
//      unsigned long   isvolatile  :1; // TRUE if volatile pointer
//      unsigned long   isconst     :1; // TRUE if const pointer
//      unsigned long   isunaligned :1; // TRUE if unaligned pointer
//      unsigned long   isrestrict  :1; // TRUE if restricted pointer (allow agressive opts)
//      unsigned long   size        :6; // size of pointer (in bytes)
//      unsigned long   ismocom     :1; // TRUE if it is a MoCOM pointer (^ or %)
//      unsigned long   islref      :1; // TRUE if it is this pointer of member function with & ref-qualifier
//      unsigned long   isrref      :1; // TRUE if it is this pointer of member function with && ref-qualifier
//      unsigned long   unused      :10;// pad out to 32-bits for following cv_typ_t's
    end;
  public
    leaf: UInt16;                   // LF_POINTER
    utype: CV_typ_t;                // type index of the underlying type
    attr: lfPointerAttr;
  case Integer of
    0: (
      pmclass: CV_typ_t;            // index of containing class for pointer to member
      pmenum: UInt16;               // enumeration specifying pm format (CV_pmtype_e)
    );
    1: (
      bseg: UInt16;                 // base segment if PTR_BASE_SEG
    );
    2: (
      Sym: array [0..0] of UInt8;   // copy of base symbol record (including length)
    );
    3: (
      index: CV_typ_t;              // type index if CV_PTR_BASE_TYPE
      name: array [0..0] of UInt8;  // name of base type
    );
  end;




//      type record for LF_ARRAY


  PlfArray_16t = ^lfArray_16t;
  lfArray_16t = packed record
    leaf:     UInt16;               // LF_ARRAY_16t
    elemtype: CV_typ16_t;           // type index of element type
    idxtype:  CV_typ16_t;           // type index of indexing type
    data:     array [0..0] of UInt8;          // variable length data specifying
                                    // size in bytes and name
  end;

  PlfArray = ^lfArray;
  lfArray = packed record
    leaf:     UInt16;               // LF_ARRAY
    elemtype: CV_typ_t;             // type index of element type
    idxtype:  CV_typ_t;             // type index of indexing type
    data:     array [0..0] of UInt8;          // variable length data specifying
                                    // size in bytes and name
  end;

  PlfStridedArray = ^lfStridedArray;
  lfStridedArray = packed record
    leaf:     UInt16;               // LF_ARRAY
    elemtype: CV_typ_t;             // type index of element type
    idxtype:  CV_typ_t;             // type index of indexing type
    stride:   UInt32;
    data:     array [0..0] of UInt8;          // variable length data specifying
                                    // size in bytes and name
  end;




//      type record for LF_VECTOR


  PlfVector = ^lfVector;
  lfVector = packed record
    leaf:     UInt16;               // LF_VECTOR
    elemtype: CV_typ_t;             // type index of element type
    count:    UInt32;               // number of elements in the vector
    data:     array [0..0] of UInt8;          // variable length data specifying
                                    // size in bytes and name
  end;




//      type record for LF_MATRIX


  PlfMatrix = ^lfMatrix;
  lfMatrix = packed record
    leaf:        UInt16;            // LF_MATRIX
    elemtype:    CV_typ_t;          // type index of element type
    rows:        UInt32;            // number of rows
    cols:        UInt32;            // number of columns
    majorStride: UInt32;
    matattr:     CV_matrixattr_t;   // attributes
    data:        array [0..0] of UInt8;       // variable length data specifying
                                    // size in bytes and name
  end;




//      type record for LF_CLASS, LF_STRUCTURE


  PlfClass_16t = ^lfClass_16t;
  lfClass_16t = packed record
    leaf:      UInt16;              // LF_CLASS_16t, LF_STRUCT_16t
    count:     UInt16;              // count of number of elements in class
    field:     CV_typ16_t;          // type index of LF_FIELD descriptor list
    &property: CV_prop_t;           // property attribute field (prop_t)
    derived:   CV_typ16_t;          // type index of derived from list if not zero
    vshape:    CV_typ16_t;          // type index of vshape table for this class
    data:      array [0..0] of UInt8;         // data describing length of structure in
                                    // bytes and name
  end;
  PlfStructure_16t = PlfClass_16t;
  lfStructure_16t = lfClass_16t;


  PlfClass = ^lfClass;
  lfClass = packed record
    leaf:      UInt16;              // LF_CLASS, LF_STRUCT, LF_INTERFACE
    count:     UInt16;              // count of number of elements in class
    &property: CV_prop_t;           // property attribute field (prop_t)
    field:     CV_typ_t;            // type index of LF_FIELD descriptor list
    derived:   CV_typ_t;            // type index of derived from list if not zero
    vshape:    CV_typ_t;            // type index of vshape table for this class
    data:      array [0..0] of UInt8;         // data describing length of structure in
                                    // bytes and name
  end;
  PlfStructure = PlfClass;
  lfStructure = lfClass;
  PlfInterface = PlfClass;
  lfInterface = lfClass;

//      type record for LF_UNION


  PlfUnion_16t = ^lfUnion_16t;
  lfUnion_16t = packed record
    leaf:      UInt16;              // LF_UNION_16t
    count:     UInt16;              // count of number of elements in class
    field:     CV_typ16_t;          // type index of LF_FIELD descriptor list
    &property: CV_prop_t;           // property attribute field
    data:      array [0..0] of UInt8;         // variable length data describing length of
                                    // structure and name
  end;


  PlfUnion = ^lfUnion;
  lfUnion = packed record
    leaf:      UInt16;              // LF_UNION
    count:     UInt16;              // count of number of elements in class
    &property: CV_prop_t;           // property attribute field
    field:     CV_typ_t;            // type index of LF_FIELD descriptor list
    data:      array [0..0] of UInt8;         // variable length data describing length of
                                    // structure and name
  end;


//      type record for LF_ALIAS

  lfAlias = packed record
    leaf:  UInt16;                  // LF_ALIAS
    utype: CV_typ_t;                // underlying type
    Name:  array [0..0] of UInt8;   // alias name
  end;

// Item Id is a stricter typeindex which may referenced from symbol stream.
// The code item always had a name.

  CV_ItemId = CV_typ_t;

  PlfFuncId = ^lfFuncId;
  lfFuncId = packed record
    leaf:    UInt16;                // LF_FUNC_ID
    scopeId: CV_ItemId;             // parent scope of the ID, 0 if global
    &type:   CV_typ_t;              // function type
    name:    array [0..0] of UInt8;
  end;

  PlfMFuncId = ^lfMFuncId;
  lfMFuncId = packed record
    leaf:       UInt16;             // LF_MFUNC_ID
    parentType: CV_typ_t;           // type index of parent
    &type:      CV_typ_t;           // function type
    name:       array [0..0] of UInt8;
  end;

  PlfStringId = ^lfStringId;
  lfStringId = packed record
    leaf: UInt16;                   // LF_STRING_ID
    id:   CV_ItemId;                // ID to list of sub string IDs
    name: array [0..0] of UInt8;
  end;

  PlfUdtSrcLine = ^lfUdtSrcLine;
  lfUdtSrcLine = packed record
    leaf:  UInt16;                  // LF_UDT_SRC_LINE
    &type: CV_typ_t;                // UDT's type index
    src:   CV_ItemId;               // index to LF_STRING_ID record where source file name is saved
    line:  UInt32;                  // line number
  end;

  PlfUdtModSrcLine = ^lfUdtModSrcLine;
  lfUdtModSrcLine = packed record
    leaf:  UInt16;                  // LF_UDT_MOD_SRC_LINE
    &type: CV_typ_t;                // UDT's type index
    src:   CV_ItemId;               // index into string table where source file name is saved
    line:  UInt32;                  // line number
    imod:  UInt16;                  // module that contributes this UDT definition
  end;

const
  CV_BuildInfo_CurrentDirectory = 0;
  CV_BuildInfo_BuildTool        = 1;    // Cl.exe
  CV_BuildInfo_SourceFile       = 2;    // foo.cpp
  CV_BuildInfo_ProgramDatabaseFile = 3; // foo.pdb
  CV_BuildInfo_CommandArguments = 4;    // -I etc
  CV_BUILDINFO_KNOWN = 5;

// type record for build information

type
  PlfBuildInfo = ^lfBuildInfo;
  lfBuildInfo = packed record
    leaf:  UInt16;                  // LF_BUILDINFO
    count: UInt16;                  // number of arguments
    arg:   array [0..CV_BUILDINFO_KNOWN - 1] of CV_ItemId;  // arguments as CodeItemId
  end;

//      type record for LF_MANAGED

  PlfManaged = ^lfManaged;
  lfManaged = packed record
    leaf: UInt16;                   // LF_MANAGED
    Name: array [0..0] of UInt8;    // utf8, zero terminated managed type name
  end;


//      type record for LF_ENUM


  PlfEnum_16t = ^lfEnum_16t;
  lfEnum_16t = packed record
    leaf:      UInt16;              // LF_ENUM_16t
    count:     UInt16;              // count of number of elements in class
    utype:     CV_typ16_t;          // underlying type of the enum
    field:     CV_typ16_t;          // type index of LF_FIELD descriptor list
    &property: CV_prop_t;           // property attribute field
    Name:      array [0..0] of UInt8; // length prefixed name of enum
  end;

  PlfEnum = ^lfEnum;
  lfEnum = packed record
    leaf:      UInt16;              // LF_ENUM
    count:     UInt16;              // count of number of elements in class
    &property: CV_prop_t;           // property attribute field
    utype:     CV_typ_t;            // underlying type of the enum
    field:     CV_typ_t;            // type index of LF_FIELD descriptor list
    Name:      array [0..0] of UInt8; // length prefixed name of enum
  end;



//      Type record for LF_PROCEDURE


  PlfProc_16t = ^lfProc_16t;
  lfProc_16t = packed record
    leaf:      UInt16;              // LF_PROCEDURE_16t
    rvtype:    CV_typ16_t;          // type index of return value
    calltype:  UInt8;               // calling convention (CV_call_t)
    funcattr:  CV_funcattr_t;       // attributes
    parmcount: UInt16;              // number of parameters
    arglist:   CV_typ16_t;          // type index of argument list
  end;

  PlfProc = ^lfProc;
  lfProc = packed record
    leaf:      UInt16;              // LF_PROCEDURE
    rvtype:    CV_typ_t;            // type index of return value
    calltype:  UInt8;               // calling convention (CV_call_t)
    funcattr:  CV_funcattr_t;       // attributes
    parmcount: UInt16;              // number of parameters
    arglist:   CV_typ_t;            // type index of argument list
  end;



//      Type record for member function


  PlfMFunc_16t = ^lfMFunc_16t;
  lfMFunc_16t = packed record
    leaf:       UInt16;             // LF_MFUNCTION_16t
    rvtype:     CV_typ16_t;         // type index of return value
    classtype:  CV_typ16_t;         // type index of containing class
    thistype:   CV_typ16_t;         // type index of this pointer (model specific)
    calltype:   UInt8;              // calling convention (call_t)
    funcattr:   CV_funcattr_t;      // attributes
    parmcount:  UInt16;             // number of parameters
    arglist:    CV_typ16_t;         // type index of argument list
    thisadjust: Int32;              // this adjuster (long because pad required anyway)
  end;

  PlfMFunc = ^lfMFunc;
  lfMFunc = packed record
    leaf:       UInt16;             // LF_MFUNCTION
    rvtype:     CV_typ_t;           // type index of return value
    classtype:  CV_typ_t;           // type index of containing class
    thistype:   CV_typ_t;           // type index of this pointer (model specific)
    calltype:   UInt8;              // calling convention (call_t)
    funcattr:   CV_funcattr_t;      // attributes
    parmcount:  UInt16;             // number of parameters
    arglist:    CV_typ_t;           // type index of argument list
    thisadjust: Int32;              // this adjuster (long because pad required anyway)
  end;




//     type record for virtual function table shape


  PlfVTShape = ^lfVTShape;
  lfVTShape = packed record
    leaf:  UInt16;                  // LF_VTSHAPE
    count: UInt16;                  // number of entries in vfunctable
    desc:  array [0..0] of UInt8;   // 4 bit (CV_VTS_desc) descriptors
  end;

//     type record for a virtual function table
  PlfVftable = ^lfVftable;
  lfVftable = packed record
    leaf:                 UInt16;     // LF_VFTABLE
    &type:                CV_typ_t;   // class/structure that owns the vftable
    baseVftable:          CV_typ_t;   // vftable from which this vftable is derived
    offsetInObjectLayout: UInt32;     // offset of the vfptr to this table, relative to the start of the object layout.
    len:                  UInt32;     // length of the Names array below in bytes.
    Names:                array [0..0] of UInt8;  // array of names.
                                      // The first is the name of the vtable.
                                      // The others are the names of the methods.
                                      // TS-TODO: replace a name with a NamedCodeItem once Weiping is done, to
                                      //    avoid duplication of method names.
  end;

//      type record for cobol0


  PlfCobol0_16t = ^lfCobol0_16t;
  lfCobol0_16t = packed record
    leaf:  UInt16;                  // LF_COBOL0_16t
    &type: CV_typ16_t;              // parent type record index
    data:  array [0..0] of UInt8;
  end;

  PlfCobol0 = ^lfCobol0;
  lfCobol0 = packed record
    leaf:  UInt16;                  // LF_COBOL0
    &type: CV_typ_t;                // parent type record index
    data:  array [0..0] of UInt8;
  end;




//      type record for cobol1


  PlfCobol1 = ^lfCobol1;
  lfCobol1 = packed record
    leaf:  UInt16;                  // LF_COBOL1
    data:  array [0..0] of UInt8;
  end;




//      type record for basic array


  PlfBArray_16t = ^lfBArray_16t;
  lfBArray_16t = packed record
    leaf:  UInt16;                  // LF_BARRAY_16t
    utype: CV_typ16_t;              // type index of underlying type
  end;

  PlfBArray = ^lfBArray;
  lfBArray = packed record
    leaf:  UInt16;                  // LF_BARRAY
    utype: CV_typ_t;                // type index of underlying type
  end;

//      type record for assembler labels


  PlfLabel = ^lfLabel;
  lfLabel = packed record
    leaf: UInt16;                   // LF_LABEL
    mode: UInt16;                   // addressing mode of label
  end;



//      type record for dimensioned arrays


  PlfDimArray_16t = ^lfDimArray_16t;
  lfDimArray_16t = packed record
    leaf:    UInt16;                // LF_DIMARRAY_16t
    utype:   CV_typ16_t;            // underlying type of the array
    diminfo: CV_typ16_t;            // dimension information
    name:    array [0..0] of UInt8; // length prefixed name
  end;

  PlfDimArray = ^lfDimArray;
  lfDimArray = packed record
    leaf:    UInt16;                // LF_DIMARRAY
    utype:   CV_typ_t;              // underlying type of the array
    diminfo: CV_typ_t;              // dimension information
    name:    array [0..0] of UInt8; // length prefixed name
  end;



//      type record describing path to virtual function table


  PlfVFTPath_16t = ^lfVFTPath_16t;
  lfVFTPath_16t = packed record
    leaf:  UInt16;                  // LF_VFTPATH_16t
    count: UInt16;                  // count of number of bases in path
    base:  array [0..0] of CV_typ16_t;  // bases from root to leaf
  end;

  PlfVFTPath = ^lfVFTPath;
  lfVFTPath = packed record
    leaf:  UInt16;                  // LF_VFTPATH
    count: UInt16;                  // count of number of bases in path
    base:  array [0..0] of CV_typ_t;  // bases from root to leaf
  end;


//      type record describing inclusion of precompiled types


  PlfPreComp_16t = ^lfPreComp_16t;
  lfPreComp_16t = packed record
    leaf:      UInt16;              // LF_PRECOMP_16t
    start:     UInt16;              // starting type index included
    count:     UInt16;              // number of types in inclusion
    signature: UInt32;              // signature
    name:      array [0..0] of UInt8; // length prefixed name of included type file
  end;

  PlfPreComp = ^lfPreComp;
  lfPreComp = packed record
    leaf:      UInt16;              // LF_PRECOMP
    start:     UInt32;              // starting type index included
    count:     UInt32;              // number of types in inclusion
    signature: UInt32;              // signature
    name:      array [0..0] of UInt8; // length prefixed name of included type file
  end;



//      type record describing end of precompiled types that can be
//      included by another file


  PlfEndPreComp = ^lfEndPreComp;
  lfEndPreComp = packed record
    leaf:      UInt16;              // LF_ENDPRECOMP
    signature: UInt32;              // signature
  end;





//      type record for OEM definable type strings


  PlfOEM_16t = ^lfOEM_16t;
  lfOEM_16t = packed record
    leaf:   UInt16;                 // LF_OEM_16t
    cvOEM:  UInt16;                 // MS assigned OEM identified
    recOEM: UInt16;                 // OEM assigned type identifier
    count:  UInt16;                 // count of type indices to follow
    index:  array [0..0] of CV_typ16_t; // array of type indices followed
                                    // by OEM defined data
  end;

  lfOEM = packed record
    leaf:   UInt16;                 // LF_OEM
    cvOEM:  UInt16;                 // MS assigned OEM identified
    recOEM: UInt16;                 // OEM assigned type identifier
    count:  UInt32;                 // count of type indices to follow
    index:  array [0..0] of CV_typ_t; // array of type indices followed
                                    // by OEM defined data
  end;

const
  OEM_MS_FORTRAN90      = $F090;
  OEM_ODI               = $0010;
  OEM_THOMSON_SOFTWARE  = $5453;
  OEM_ODI_REC_BASELIST  = $0000;

type
  PlfOEM2 = ^lfOEM2;
  lfOEM2 = packed record
    leaf:  UInt16;                  // LF_OEM2
    idOem: array [0..15] of UInt8;  // an oem ID (GUID)
    count: UInt32;                  // count of type indices to follow
    index: array [0..0] of CV_typ_t;  // array of type indices followed
                                    // by OEM defined data
  end;

//      type record describing using of a type server

  PlfTypeServer = ^lfTypeServer;
  lfTypeServer = packed record
    leaf:      UInt16;              // LF_TYPESERVER
    signature: UInt32;              // signature
    age:       UInt32;              // age of database used by this module
    name:      array [0..0] of UInt8; // length prefixed name of PDB
  end;

//      type record describing using of a type server with v7 (GUID) signatures

  PlfTypeServer2 = ^lfTypeServer2;
  lfTypeServer2 = packed record
    leaf:  UInt16;                  // LF_TYPESERVER2
    sig70: SIG70;                   // guid signature
    age:   UInt32;                  // age of database used by this module
    name:  array [0..0] of UInt8;   // length prefixed name of PDB
  end;

//      description of type records that can be referenced from
//      type records referenced by symbols



//      type record for skip record


  PlfSkip_16t = ^lfSkip_16t;
  lfSkip_16t = packed record
    leaf:  UInt16;                  // LF_SKIP_16t
    &type: CV_typ16_t;              // next valid index
    data:  array [0..0] of UInt8;   // pad data
  end;

  PlfSkip = ^lfSkip;
  lfSkip = packed record
    leaf:  UInt16;                  // LF_SKIP
    &type: CV_typ_t;                // next valid index
    data:  array [0..0] of UInt8;   // pad data
  end;



//      argument list leaf


  PlfArgList_16t = ^lfArgList_16t;
  lfArgList_16t = packed record
    leaf:  UInt16;                  // LF_ARGLIST_16t
    count: UInt16;                  // number of arguments
    arg:   array [0..0] of CV_typ16_t;  // number of arguments
  end;

  PlfArgList = ^lfArgList;
  lfArgList = packed record
    leaf:  UInt16;                  // LF_ARGLIST
    count: UInt32;                  // number of arguments
    arg:   array [0..0] of CV_typ_t;  // number of arguments
  end;




//      derived class list leaf


  PlfDerived_16t = ^lfDerived_16t;
  lfDerived_16t = packed record
    leaf:    UInt16;                // LF_DERIVED_16t
    count:   UInt16;                // number of arguments
    drvdcls: array [0..0] of CV_typ16_t;  // type indices of derived classes
  end;

  PlfDerived = ^lfDerived;
  lfDerived = packed record
    leaf:    UInt16;                // LF_DERIVED
    count:   UInt32;                // number of arguments
    drvdcls: array [0..0] of CV_typ_t;  // type indices of derived classes
  end;




//      leaf for default arguments


  PlfDefArg_16t = ^lfDefArg_16t;
  lfDefArg_16t = packed record
    leaf:  UInt16;                  // LF_DEFARG_16t
    &type: CV_typ16_t;              // type of resulting expression
    expr:  array [0..0] of UInt8;   // length prefixed expression string
  end;

  PlfDefArg = ^lfDefArg;
  lfDefArg = packed record
    leaf:  UInt16;                  // LF_DEFARG
    &type: CV_typ_t;                // type of resulting expression
    expr:  array [0..0] of UInt8;   // length prefixed expression string
  end;



//      list leaf
//          This list should no longer be used because the utilities cannot
//          verify the contents of the list without knowing what type of list
//          it is.  New specific leaf indices should be used instead.


  PlfList = ^lfList;
  lfList = packed record
    leaf: UInt16;                   // LF_LIST
    data: array [0..0] of Int8;     // data format specified by indexing type
  end;




//      field list leaf
//      This is the header leaf for a complex list of class and structure
//      subfields.


  PlfFieldList_16t = ^lfFieldList_16t;
  lfFieldList_16t = packed record
    leaf: UInt16;                   // LF_FIELDLIST_16t
    data: array [0..0] of Int8;     // field list sub lists
  end;


  PlfFieldList = ^lfFieldList;
  lfFieldList = packed record
    leaf: UInt16;                   // LF_FIELDLIST
    data: array [0..0] of Int8;     // field list sub lists
  end;







//  type record for non-static methods and friends in overloaded method list

  PmlMethod_16t = ^mlMethod_16t;
  mlMethod_16t = packed record
    attr:     CV_fldattr_t;         // method attribute
    index:    CV_typ16_t;           // index to type record for procedure
    vbaseoff: UInt32;               // offset in vfunctable if intro virtual
  end;

  PmlMethod = ^mlMethod;
  mlMethod = packed record
    attr:     CV_fldattr_t;         // method attribute
    pad0:     _2BYTEPAD;            // internal padding, must be 0
    index:    CV_typ_t;             // index to type record for procedure
    vbaseoff: UInt32;               // offset in vfunctable if intro virtual
  end;


  PlfMethodList_16t = ^lfMethodList_16t;
  lfMethodList_16t = packed record
    leaf:  UInt16;
    mList: array [0..0] of UInt8;   // really a mlMethod_16t type
  end;

  PlfMethodList = ^lfMethodList;
  lfMethodList = packed record
    leaf:  UInt16;
    mList: array [0..0] of UInt8;   // really a mlMethod type
  end;





//      type record for LF_BITFIELD


  PlfBitfield_16t = ^lfBitfield_16t;
  lfBitfield_16t = packed record
    leaf:     UInt16;               // LF_BITFIELD_16t
    length:   UInt8;
    position: UInt8;
    &type:    CV_typ16_t;           // type of bitfield
  end;

  PlfBitfield = ^lfBitfield;
  lfBitfield = packed record
    leaf:     UInt16;               // LF_BITFIELD_16t
    &type:    CV_typ_t;             // type of bitfield
    length:   UInt8;
    position: UInt8;
  end;



//      type record for dimensioned array with constant bounds


  PlfDimCon_16t = ^lfDimCon_16t;
  lfDimCon_16t = packed record
    leaf: UInt16;                   // LF_DIMCONU_16t or LF_DIMCONLU_16t
    rank: UInt16;                   // number of dimensions
    typ:  CV_typ16_t;               // type of index
    dim:  array [0..0] of UInt8;    // array of dimension information with
                                    // either upper bounds or lower/upper bound
  end;

  PlfDimCon = ^lfDimCon;
  lfDimCon = packed record
    leaf: UInt16;                   // LF_DIMCONU or LF_DIMCONLU
    typ:  CV_typ_t;                 // type of index
    rank: UInt16;                   // number of dimensions
    dim:  array [0..0] of UInt8;    // array of dimension information with
                                    // either upper bounds or lower/upper bound
  end;




//      type record for dimensioned array with variable bounds


  PlfDimVar_16t = ^lfDimVar_16t;
  lfDimVar_16t = packed record
    leaf: UInt16;                   // LF_DIMVARU_16t or LF_DIMVARLU_16t
    rank: UInt16;                   // number of dimensions
    typ:  CV_typ16_t;               // type of index
    dim:  array [0..0] of CV_typ16_t; // array of type indices for either
                                    // variable upper bound or variable
                                    // lower/upper bound.  The referenced
                                    // types must be LF_REFSYM or T_VOID
  end;

  PlfDimVar = ^lfDimVar;
  lfDimVar = packed record
    leaf: UInt16;                   // LF_DIMVARU or LF_DIMVARLU
    rank: UInt32;                   // number of dimensions
    typ:  CV_typ_t;                 // type of index
    dim:  array [0..0] of CV_typ_t; // array of type indices for either
                                    // variable upper bound or variable
                                    // lower/upper bound.  The count of type
                                    // indices is rank or rank*2 depending on
                                    // whether it is LFDIMVARU or LF_DIMVARLU.
                                    // The referenced types must be
                                    // LF_REFSYM or T_VOID
  end;




//      type record for referenced symbol


  PlfRefSym = ^lfRefSym;
  lfRefSym = packed record
    leaf: UInt16;                   // LF_REFSYM
    Sym:  array [0..0] of UInt8;    // copy of referenced symbol record
                                    // (including length)
  end;



//      type record for generic HLSL type


  PlfHLSL = ^lfHLSL;
  lfHLSL = packed record
    leaf: UInt16;                   // LF_HLSL
    subtype: CV_typ_t;              // sub-type index, if any
    kind: UInt16;                   // kind of built-in type from CV_builtin_e
    _props: UInt16;
//    unsigned short  numprops :  4;        // number of numeric properties
//    unsigned short  unused   : 12;        // padding, must be 0
    data: array [0..0] of UInt8;    // variable-length array of numeric properties
                                    // followed by byte size
    function Getnumprops: UInt16; inline;
    function Getunused: UInt16; inline;
    procedure Setnumprops(Value: UInt16); inline;
    procedure Setunused(Value: UInt16); inline;
    property numprops: UInt16 read Getnumprops write Setnumprops;
    property unused: UInt16 read Getunused write Setunused;
  end;




//      type record for a generalized built-in type modifier


  PlfModifierEx = ^lfModifierEx;
  lfModifierEx = packed record
    leaf:  UInt16;                  // LF_MODIFIER_EX
    &type: CV_typ_t;                // type being modified
    count: UInt16;                  // count of modifier values
    mods:  array [0..0] of UInt16;  // modifiers from CV_modifier_e
  end;




(**     the following are numeric leaves.  They are used to indicate the
 *      size of the following variable length data.  When the numeric
 *      data is a single byte less than 0x8000, then the data is output
 *      directly.  If the data is more the 0x8000 or is a negative value,
 *      then the data is preceeded by the proper index.
 *)



//      signed character leaf

  PlfChar = ^lfChar;
  lfChar = packed record
    leaf: UInt16;                   // LF_CHAR
    val:  Int8;                     // signed 8-bit value
  end;




//      signed short leaf

  PlfShort = ^lfShort;
  lfShort = packed record
    leaf: UInt16;                   // LF_SHORT
    val:  Int16;                    // signed 16-bit value
  end;




//      unsigned short leaf

  PlfUShort = ^lfUShort;
  lfUShort = packed record
    leaf: UInt16;                   // LF_unsigned short
    val:  UInt16;                   // unsigned 16-bit value
  end;




//      signed long leaf

  PlfLong = ^lfLong;
  lfLong = packed record
    leaf: UInt16;                   // LF_LONG
    val:  Int32;                    // signed 32-bit value
  end;




//      unsigned long leaf

  PlfULong = ^lfULong;
  lfULong = packed record
    leaf: UInt16;                   // LF_ULONG
    val:  UInt32;                   // unsigned 32-bit value
  end;




//      signed quad leaf

  PlfQuad = ^lfQuad;
  lfQuad = packed record
    leaf: UInt16;                   // LF_QUAD
    val:  Int64;                    // signed 64-bit value
  end;




//      unsigned quad leaf

  PlfUQuad = ^lfUQuad;
  lfUQuad = packed record
    leaf: UInt16;                   // LF_UQUAD
    val:  UInt64;                   // unsigned 64-bit value
  end;


//      signed int128 leaf

  PlfOct = ^lfOct;
  lfOct = packed record
    leaf: UInt16;                   // LF_OCT
    val:  array [0..15] of UInt8;   // signed 128-bit value
  end;

//      unsigned int128 leaf

  PlfUOct = ^lfUOct;
  lfUOct = packed record
    leaf: UInt16;                   // LF_UOCT
    val:  array [0..15] of UInt8;   // unsigned 128-bit value
  end;




//      real 16-bit leaf

  PlfReal16 = ^lfReal16;
  lfReal16 = packed record
    leaf: UInt16;                   // LF_REAL16
    val:  UInt16;                   // 16-bit real value
  end;




//      real 32-bit leaf

  PlfReal32 = ^lfReal32;
  lfReal32 = packed record
    leaf: UInt16;                   // LF_REAL32
    val:  Single;                   // 32-bit real value
  end;




//      real 48-bit leaf

  PlfReal48 = ^lfReal48;
  lfReal48 = packed record
    leaf: UInt16;                   // LF_REAL48
    val: array [0..5] of UInt8;     // 48-bit real value
  end;




//      real 64-bit leaf

  PlfReal64 = ^lfReal64;
  lfReal64 = packed record
    leaf: UInt16;                   // LF_REAL64
    val:  Double;                   // 64-bit real value
  end;




//      real 80-bit leaf

  PlfReal80 = ^lfReal80;
  lfReal80 = packed record
    leaf: UInt16;                   // LF_REAL80
    val:  TExtended80Rec;           // real 80-bit value
  end;




//      real 128-bit leaf

  PlfReal128 = ^lfReal128;
  lfReal128 = packed record
    leaf: UInt16;                   // LF_REAL128
    val:  array [0..15] of Int8;    // real 128-bit value
  end;




//      complex 32-bit leaf

  PlfCmplx32 = ^lfCmplx32;
  lfCmplx32 = packed record
    leaf:     UInt16;               // LF_COMPLEX32
    val_real: Single;               // real component
    val_imag: Single;               // imaginary component
  end;




//      complex 64-bit leaf

  PlfCmplx64 = ^lfCmplx64;
  lfCmplx64 = packed record
    leaf:     UInt16;               // LF_COMPLEX64
    val_real: Double;               // real component
    val_imag: Double;               // imaginary component
  end;




//      complex 80-bit leaf

  PlfCmplx80 = ^lfCmplx80;
  lfCmplx80 = packed record
    leaf:     UInt16;               // LF_COMPLEX80
    val_real: TExtended80Rec;       // real component
    val_imag: TExtended80Rec;       // imaginary component
  end;




//      complex 128-bit leaf

  PlfCmplx128 = ^lfCmplx128;
  lfCmplx128 = packed record
    leaf: UInt16;                   // LF_COMPLEX128
    val_real: array [0..15] of Int8;  // real component
    val_imag: array [0..15] of Int8;  // imaginary component
  end;



//  variable length numeric field

  PlfVarString = ^lfVarString;
  lfVarString = packed record
    leaf: UInt16;                   // LF_VARSTRING
    len: UInt16;                    // length of value in bytes
    value: array [0..0] of UInt8;   // value
  end;

//***********************************************************************


//      index leaf - contains type index of another leaf
//      a major use of this leaf is to allow the compilers to emit a
//      long complex list (LF_FIELD) in smaller pieces.

  PlfIndex_16t = ^lfIndex_16t;
  lfIndex_16t = packed record
    leaf:  UInt16;                  // LF_INDEX_16t
    index: CV_typ16_t;              // type index of referenced leaf
  end;

  PlfIndex = ^lfIndex;
  lfIndex = packed record
    leaf:  UInt16;                  // LF_INDEX
    pad0:  _2BYTEPAD;               // internal padding, must be 0
    index: CV_typ_t;                // type index of referenced leaf
  end;


//      subfield record for base class field

  PlfBClass_16t = ^lfBClass_16t;
  lfBClass_16t = packed record
    leaf:   UInt16;                 // LF_BCLASS_16t
    index:  CV_typ16_t;             // type index of base class
    attr:   CV_fldattr_t;           // attribute
    offset: array [0..0] of UInt8;  // variable length offset of base within class
  end;

  PlfBClass = ^lfBClass;
  lfBClass = packed record
    leaf:   UInt16;                 // LF_BCLASS, LF_BINTERFACE
    attr:   CV_fldattr_t;           // attribute
    index:  CV_typ_t;               // type index of base class
    offset: array [0..0] of UInt8;  // variable length offset of base within class
  end;
  PlfBInterface = PlfBClass;
  lfBInterface = lfBClass;




//      subfield record for direct and indirect virtual base class field

  PlfVBClass_16t = ^lfVBClass_16t;
  lfVBClass_16t = packed record
    leaf:   UInt16;                 // LF_VBCLASS_16t | LV_IVBCLASS_16t
    index:  CV_typ16_t;             // type index of direct virtual base class
    vbptr:  CV_typ16_t;             // type index of virtual base pointer
    attr:   CV_fldattr_t;           // attribute
    vbpoff: array [0..0] of UInt8;  // virtual base pointer offset from address point
                                    // followed by virtual base offset from vbtable
  end;

  PlfVBClass = ^lfVBClass;
  lfVBClass = packed record
    leaf:   UInt16;                 // LF_VBCLASS | LV_IVBCLASS
    attr:   CV_fldattr_t;           // attribute
    index:  CV_typ_t;               // type index of direct virtual base class
    vbptr:  CV_typ_t;               // type index of virtual base pointer
    vbpoff: array [0..0] of UInt8;  // virtual base pointer offset from address point
                                    // followed by virtual base offset from vbtable
  end;





//      subfield record for friend class


  PlfFriendCls_16t = ^lfFriendCls_16t;
  lfFriendCls_16t = packed record
    leaf:  UInt16;                  // LF_FRIENDCLS_16t
    index: CV_typ16_t;              // index to type record of friend class
  end;

  PlfFriendCls = ^lfFriendCls;
  lfFriendCls = packed record
    leaf:  UInt16;                  // LF_FRIENDCLS
    pad0:  _2BYTEPAD;               // internal padding, must be 0
    index: CV_typ_t;                // index to type record of friend class
  end;





//      subfield record for friend function


  PlfFriendFcn_16t = ^lfFriendFcn_16t;
  lfFriendFcn_16t = packed record
    leaf:  UInt16;                  // LF_FRIENDFCN_16t
    index: CV_typ16_t;              // index to type record of friend function
    Name:  array [0..0] of UInt8;   // name of friend function
  end;

  PlfFriendFcn = ^lfFriendFcn;
  lfFriendFcn = packed record
    leaf:  UInt16;                  // LF_FRIENDFCN
    pad0:  _2BYTEPAD;               // internal padding, must be 0
    index: CV_typ_t;                // index to type record of friend function
    Name:  array [0..0] of UInt8;   // name of friend function
  end;



//      subfield record for non-static data members

  PlfMember_16t = ^lfMember_16t;
  lfMember_16t = packed record
    leaf:   UInt16;                 // LF_MEMBER_16t
    index:  CV_typ16_t;             // index of type record for field
    attr:   CV_fldattr_t;           // attribute mask
    offset: array [0..0] of UInt8;  // variable length offset of field followed
                                    // by length prefixed name of field
  end;

  PlfMember = ^lfMember;
  lfMember = packed record
    leaf:   UInt16;                 // LF_MEMBER
    attr:   CV_fldattr_t;           // attribute mask
    index:  CV_typ_t;               // index of type record for field
    offset: array [0..0] of UInt8;  // variable length offset of field followed
                                    // by length prefixed name of field
  end;



//  type record for static data members

  PlfSTMember_16t = ^lfSTMember_16t;
  lfSTMember_16t = packed record
    leaf:  UInt16;                  // LF_STMEMBER_16t
    index: CV_typ16_t;              // index of type record for field
    attr:  CV_fldattr_t;            // attribute mask
    Name:  array [0..0] of UInt8;   // length prefixed name of field
  end;

  PlfSTMember = ^lfSTMember;
  lfSTMember = packed record
    leaf:  UInt16;                  // LF_STMEMBER
    attr:  CV_fldattr_t;            // attribute mask
    index: CV_typ_t;                // index of type record for field
    Name:  array [0..0] of UInt8;   // length prefixed name of field
  end;



//      subfield record for virtual function table pointer

  PlfVFuncTab_16t = ^lfVFuncTab_16t;
  lfVFuncTab_16t = packed record
    leaf:  UInt16;                  // LF_VFUNCTAB_16t
    &type: CV_typ16_t;              // type index of pointer
  end;

  PlfVFuncTab = ^lfVFuncTab;
  lfVFuncTab = packed record
    leaf: UInt16;                   // LF_VFUNCTAB
    pad0: _2BYTEPAD;                // internal padding, must be 0
    &type: CV_typ_t;                // type index of pointer
  end;



//      subfield record for virtual function table pointer with offset

  PlfVFuncOff_16t = ^lfVFuncOff_16t;
  lfVFuncOff_16t = packed record
    leaf:   UInt16;                 // LF_VFUNCOFF_16t
    &type:  CV_typ16_t;             // type index of pointer
    offset: CV_off32_t;             // offset of virtual function table pointer
  end;

  PlfVFuncOff = ^lfVFuncOff;
  lfVFuncOff = packed record
    leaf:   UInt16;                 // LF_VFUNCOFF
    pad0:   _2BYTEPAD;              // internal padding, must be 0.
    &type:  CV_typ_t;               // type index of pointer
    offset: CV_off32_t;             // offset of virtual function table pointer
  end;



//      subfield record for overloaded method list


  PlfMethod_16t = ^lfMethod_16t;
  lfMethod_16t = packed record
    leaf:  UInt16;                  // LF_METHOD_16t
    count: UInt16;                  // number of occurrences of function
    mList: CV_typ16_t;              // index to LF_METHODLIST record
    Name:  array [0..0] of UInt8;   // length prefixed name of method
  end;

  PlfMethod = ^lfMethod;
  lfMethod = packed record
    leaf:  UInt16;                  // LF_METHOD
    count: UInt16;                  // number of occurrences of function
    mList: CV_typ_t;                // index to LF_METHODLIST record
    Name:  array [0..0] of UInt8;   // length prefixed name of method
  end;



//      subfield record for nonoverloaded method


  PlfOneMethod_16t = ^lfOneMethod_16t;
  lfOneMethod_16t = packed record
    leaf:     UInt16;               // LF_ONEMETHOD_16t
    attr:     CV_fldattr_t;         // method attribute
    index:    CV_typ16_t;           // index to type record for procedure
    vbaseoff: array [0..0] of UInt32; // offset in vfunctable if
                                    // intro virtual followed by
                                    // length prefixed name of method
  end;

  PlfOneMethod = ^lfOneMethod;
  lfOneMethod = packed record
    leaf:     UInt16;               // LF_ONEMETHOD
    attr:     CV_fldattr_t;         // method attribute
    index:    CV_typ_t;             // index to type record for procedure
    vbaseoff: array [0..0] of UInt32; // offset in vfunctable if
                                    // intro virtual followed by
                                    // length prefixed name of method
  end;


//      subfield record for enumerate

  PlfEnumerate = ^lfEnumerate;
  lfEnumerate = packed record
    leaf:  UInt16;                  // LF_ENUMERATE
    attr:  CV_fldattr_t;            // access
    value: array [0..0] of UInt8;   // variable length value field followed
                                    // by length prefixed name
  end;


//  type record for nested (scoped) type definition

  PlfNestType_16t = ^lfNestType_16t;
  lfNestType_16t = packed record
    leaf:  UInt16;                  // LF_NESTTYPE_16t
    index: CV_typ16_t;              // index of nested type definition
    Name:  array [0..0] of UInt8;   // length prefixed type name
  end;

  PlfNestType = ^lfNestType;
  lfNestType = packed record
    leaf:  UInt16;                  // LF_NESTTYPE
    pad0:  _2BYTEPAD;               // internal padding, must be 0
    index: CV_typ_t;                // index of nested type definition
    Name:  array [0..0] of UInt8;   // length prefixed type name
  end;

//  type record for nested (scoped) type definition, with attributes
//  new records for vC v5.0, no need to have 16-bit ti versions.

  PlfNestTypeEx = ^lfNestTypeEx;
  lfNestTypeEx = packed record
    leaf:  UInt16;                  // LF_NESTTYPEEX
    attr:  CV_fldattr_t;            // member access
    index: CV_typ_t;                // index of nested type definition
    Name:  array [0..0] of UInt8;   // length prefixed type name
  end;

//  type record for modifications to members

  PlfMemberModify = ^lfMemberModify;
  lfMemberModify = packed record
    leaf:  UInt16;                  // LF_MEMBERMODIFY
    attr:  CV_fldattr_t;            // the new attributes
    index: CV_typ_t;                // index of base class type definition
    Name:  array [0..0] of UInt8;   // length prefixed member name
  end;

//  type record for pad leaf

  lfPad = packed record
    leaf: UInt8;
  end;



//  Symbol definitions

const
  S_COMPILE       =  $0001;  // Compile flags symbol
  S_REGISTER_16t  =  $0002;  // Register variable
  S_CONSTANT_16t  =  $0003;  // constant symbol
  S_UDT_16t       =  $0004;  // User defined type
  S_SSEARCH       =  $0005;  // Start Search
  S_END           =  $0006;  // Block, procedure, "with" or thunk end
  S_SKIP          =  $0007;  // Reserve symbol space in $$Symbols table
  S_CVRESERVE     =  $0008;  // Reserved symbol for CV internal use
  S_OBJNAME_ST    =  $0009;  // path to object file name
  S_ENDARG        =  $000a;  // end of argument/return list
  S_COBOLUDT_16t  =  $000b;  // special UDT for cobol that does not symbol pack
  S_MANYREG_16t   =  $000c;  // multiple register variable
  S_RETURN        =  $000d;  // return description symbol
  S_ENTRYTHIS     =  $000e;  // description of this pointer on entry

  S_BPREL16       =  $0100;  // BP-relative
  S_LDATA16       =  $0101;  // Module-local symbol
  S_GDATA16       =  $0102;  // Global data symbol
  S_PUB16         =  $0103;  // a public symbol
  S_LPROC16       =  $0104;  // Local procedure start
  S_GPROC16       =  $0105;  // Global procedure start
  S_THUNK16       =  $0106;  // Thunk Start
  S_BLOCK16       =  $0107;  // block start
  S_WITH16        =  $0108;  // with start
  S_LABEL16       =  $0109;  // code label
  S_CEXMODEL16    =  $010a;  // change execution model
  S_VFTABLE16     =  $010b;  // address of virtual function table
  S_REGREL16      =  $010c;  // register relative address

  S_BPREL32_16t   =  $0200;  // BP-relative
  S_LDATA32_16t   =  $0201;  // Module-local symbol
  S_GDATA32_16t   =  $0202;  // Global data symbol
  S_PUB32_16t     =  $0203;  // a public symbol (CV internal reserved)
  S_LPROC32_16t   =  $0204;  // Local procedure start
  S_GPROC32_16t   =  $0205;  // Global procedure start
  S_THUNK32_ST    =  $0206;  // Thunk Start
  S_BLOCK32_ST    =  $0207;  // block start
  S_WITH32_ST     =  $0208;  // with start
  S_LABEL32_ST    =  $0209;  // code label
  S_CEXMODEL32    =  $020a;  // change execution model
  S_VFTABLE32_16t =  $020b;  // address of virtual function table
  S_REGREL32_16t  =  $020c;  // register relative address
  S_LTHREAD32_16t =  $020d;  // local thread storage
  S_GTHREAD32_16t =  $020e;  // global thread storage
  S_SLINK32       =  $020f;  // static link for MIPS EH implementation

  S_LPROCMIPS_16t =  $0300;  // Local procedure start
  S_GPROCMIPS_16t =  $0301;  // Global procedure start

  // if these ref symbols have names following then the names are in ST format
  S_PROCREF_ST    =  $0400;  // Reference to a procedure
  S_DATAREF_ST    =  $0401;  // Reference to data
  S_ALIGN         =  $0402;  // Used for page alignment of symbols

  S_LPROCREF_ST   =  $0403;  // Local Reference to a procedure
  S_OEM           =  $0404;  // OEM defined symbol

  // sym records with 32-bit types embedded instead of 16-bit
  // all have $1000 bit set for easy identification
  // only do the 32-bit target versions since we don't really
  // care about 16-bit ones anymore.
  S_TI16_MAX          =  $1000;

  S_REGISTER_ST   =  $1001;  // Register variable
  S_CONSTANT_ST   =  $1002;  // constant symbol
  S_UDT_ST        =  $1003;  // User defined type
  S_COBOLUDT_ST   =  $1004;  // special UDT for cobol that does not symbol pack
  S_MANYREG_ST    =  $1005;  // multiple register variable
  S_BPREL32_ST    =  $1006;  // BP-relative
  S_LDATA32_ST    =  $1007;  // Module-local symbol
  S_GDATA32_ST    =  $1008;  // Global data symbol
  S_PUB32_ST      =  $1009;  // a public symbol (CV internal reserved)
  S_LPROC32_ST    =  $100a;  // Local procedure start
  S_GPROC32_ST    =  $100b;  // Global procedure start
  S_VFTABLE32     =  $100c;  // address of virtual function table
  S_REGREL32_ST   =  $100d;  // register relative address
  S_LTHREAD32_ST  =  $100e;  // local thread storage
  S_GTHREAD32_ST  =  $100f;  // global thread storage

  S_LPROCMIPS_ST  =  $1010;  // Local procedure start
  S_GPROCMIPS_ST  =  $1011;  // Global procedure start

  S_FRAMEPROC     =  $1012;  // extra frame and proc information
  S_COMPILE2_ST   =  $1013;  // extended compile flags and info

  // new symbols necessary for 16-bit enumerates of IA64 registers
  // and IA64 specific symbols

  S_MANYREG2_ST   =  $1014;  // multiple register variable
  S_LPROCIA64_ST  =  $1015;  // Local procedure start (IA64)
  S_GPROCIA64_ST  =  $1016;  // Global procedure start (IA64)

  // Local symbols for IL
  S_LOCALSLOT_ST  =  $1017;  // local IL sym with field for local slot index
  S_PARAMSLOT_ST  =  $1018;  // local IL sym with field for parameter slot index

  S_ANNOTATION    =  $1019;  // Annotation string literals

  // symbols to support managed code debugging
  S_GMANPROC_ST   =  $101a;  // Global proc
  S_LMANPROC_ST   =  $101b;  // Local proc
  S_RESERVED1     =  $101c;  // reserved
  S_RESERVED2     =  $101d;  // reserved
  S_RESERVED3     =  $101e;  // reserved
  S_RESERVED4     =  $101f;  // reserved
  S_LMANDATA_ST   =  $1020;
  S_GMANDATA_ST   =  $1021;
  S_MANFRAMEREL_ST=  $1022;
  S_MANREGISTER_ST=  $1023;
  S_MANSLOT_ST    =  $1024;
  S_MANMANYREG_ST =  $1025;
  S_MANREGREL_ST  =  $1026;
  S_MANMANYREG2_ST=  $1027;
  S_MANTYPREF     =  $1028;  // Index for type referenced by name from metadata
  S_UNAMESPACE_ST =  $1029;  // Using namespace

  // Symbols w/ SZ name fields. All name fields contain utf8 encoded strings.
  S_ST_MAX        =  $1100;  // starting point for SZ name symbols

  S_OBJNAME       =  $1101;  // path to object file name
  S_THUNK32       =  $1102;  // Thunk Start
  S_BLOCK32       =  $1103;  // block start
  S_WITH32        =  $1104;  // with start
  S_LABEL32       =  $1105;  // code label
  S_REGISTER      =  $1106;  // Register variable
  S_CONSTANT      =  $1107;  // constant symbol
  S_UDT           =  $1108;  // User defined type
  S_COBOLUDT      =  $1109;  // special UDT for cobol that does not symbol pack
  S_MANYREG       =  $110a;  // multiple register variable
  S_BPREL32       =  $110b;  // BP-relative
  S_LDATA32       =  $110c;  // Module-local symbol
  S_GDATA32       =  $110d;  // Global data symbol
  S_PUB32         =  $110e;  // a public symbol (CV internal reserved)
  S_LPROC32       =  $110f;  // Local procedure start
  S_GPROC32       =  $1110;  // Global procedure start
  S_REGREL32      =  $1111;  // register relative address
  S_LTHREAD32     =  $1112;  // local thread storage
  S_GTHREAD32     =  $1113;  // global thread storage

  S_LPROCMIPS     =  $1114;  // Local procedure start
  S_GPROCMIPS     =  $1115;  // Global procedure start
  S_COMPILE2      =  $1116;  // extended compile flags and info
  S_MANYREG2      =  $1117;  // multiple register variable
  S_LPROCIA64     =  $1118;  // Local procedure start (IA64)
  S_GPROCIA64     =  $1119;  // Global procedure start (IA64)
  S_LOCALSLOT     =  $111a;  // local IL sym with field for local slot index
  S_SLOT          = S_LOCALSLOT;  // alias for LOCALSLOT
  S_PARAMSLOT     =  $111b;  // local IL sym with field for parameter slot index

  // symbols to support managed code debugging
  S_LMANDATA      =  $111c;
  S_GMANDATA      =  $111d;
  S_MANFRAMEREL   =  $111e;
  S_MANREGISTER   =  $111f;
  S_MANSLOT       =  $1120;
  S_MANMANYREG    =  $1121;
  S_MANREGREL     =  $1122;
  S_MANMANYREG2   =  $1123;
  S_UNAMESPACE    =  $1124;  // Using namespace

  // ref symbols with name fields
  S_PROCREF       =  $1125;  // Reference to a procedure
  S_DATAREF       =  $1126;  // Reference to data
  S_LPROCREF      =  $1127;  // Local Reference to a procedure
  S_ANNOTATIONREF =  $1128;  // Reference to an S_ANNOTATION symbol
  S_TOKENREF      =  $1129;  // Reference to one of the many MANPROCSYM's

  // continuation of managed symbols
  S_GMANPROC      =  $112a;  // Global proc
  S_LMANPROC      =  $112b;  // Local proc

  // short; light-weight thunks
  S_TRAMPOLINE    =  $112c;  // trampoline thunks
  S_MANCONSTANT   =  $112d;  // constants with metadata type info

  // native attributed local/parms
  S_ATTR_FRAMEREL =  $112e;  // relative to virtual frame ptr
  S_ATTR_REGISTER =  $112f;  // stored in a register
  S_ATTR_REGREL   =  $1130;  // relative to register (alternate frame ptr)
  S_ATTR_MANYREG  =  $1131;  // stored in >1 register

  // Separated code (from the compiler) support
  S_SEPCODE       =  $1132;

  S_LOCAL_2005    =  $1133;  // defines a local symbol in optimized code
  S_DEFRANGE_2005 =  $1134;  // defines a single range of addresses in which symbol can be evaluated
  S_DEFRANGE2_2005 =  $1135;  // defines ranges of addresses in which symbol can be evaluated

  S_SECTION       =  $1136;  // A COFF section in a PE executable
  S_COFFGROUP     =  $1137;  // A COFF group
  S_EXPORT        =  $1138;  // A export

  S_CALLSITEINFO  =  $1139;  // Indirect call site information
  S_FRAMECOOKIE   =  $113a;  // Security cookie information

  S_DISCARDED     =  $113b;  // Discarded by LINK /OPT:REF (experimental, see richards)

  S_COMPILE3      =  $113c;  // Replacement for S_COMPILE2
  S_ENVBLOCK      =  $113d;  // Environment block split off from S_COMPILE2

  S_LOCAL         =  $113e;  // defines a local symbol in optimized code
  S_DEFRANGE      =  $113f;  // defines a single range of addresses in which symbol can be evaluated
  S_DEFRANGE_SUBFIELD =  $1140;           // ranges for a subfield

  S_DEFRANGE_REGISTER =  $1141;           // ranges for en-registered symbol
  S_DEFRANGE_FRAMEPOINTER_REL =  $1142;   // range for stack symbol.
  S_DEFRANGE_SUBFIELD_REGISTER =  $1143;  // ranges for en-registered field of symbol
  S_DEFRANGE_FRAMEPOINTER_REL_FULL_SCOPE =  $1144; // range for stack symbol span valid full scope of function body, gap might apply.
  S_DEFRANGE_REGISTER_REL =  $1145; // range for symbol address as register + offset.

  // S_PROC symbols that reference ID instead of type
  S_LPROC32_ID     =  $1146;
  S_GPROC32_ID     =  $1147;
  S_LPROCMIPS_ID   =  $1148;
  S_GPROCMIPS_ID   =  $1149;
  S_LPROCIA64_ID   =  $114a;
  S_GPROCIA64_ID   =  $114b;

  S_BUILDINFO      = $114c; // build information.
  S_INLINESITE     = $114d; // inlined function callsite.
  S_INLINESITE_END = $114e;
  S_PROC_ID_END    = $114f;

  S_DEFRANGE_HLSL  = $1150;
  S_GDATA_HLSL     = $1151;
  S_LDATA_HLSL     = $1152;

  S_FILESTATIC     = $1153;

{$if defined(CC_DP_CXX)}

  S_LOCAL_DPC_GROUPSHARED = $1154; // DPC groupshared variable
  S_LPROC32_DPC = $1155; // DPC local procedure start
  S_LPROC32_DPC_ID =  $1156;
  S_DEFRANGE_DPC_PTR_TAG =  $1157; // DPC pointer tag definition range
  S_DPC_SYM_TAG_MAP = $1158; // DPC pointer tag value to symbol record map

{$endif CC_DP_CXX}

  S_ARMSWITCHTABLE  = $1159;
  S_CALLEES = $115a;
  S_CALLERS = $115b;
  S_POGODATA = $115c;
  S_INLINESITE2 = $115d;      // extended inline site information

  S_HEAPALLOCSITE = $115e;    // heap allocation site

  S_MOD_TYPEREF = $115f;      // only generated at link time

  S_REF_MINIPDB = $1160;      // only generated at link time for mini PDB
  S_PDBMAP      = $1161;      // only generated at link time for mini PDB

  S_GDATA_HLSL32 = $1162;
  S_LDATA_HLSL32 = $1163;

  S_GDATA_HLSL32_EX = $1164;
  S_LDATA_HLSL32_EX = $1165;

  S_RECTYPE_MAX = $1166;      // one greater than last
  S_RECTYPE_LAST  = S_RECTYPE_MAX - 1;
  S_RECTYPE_PAD   = S_RECTYPE_MAX + $100; // Used *only* to verify symbol record types so that current PDB code can potentially read
                              // future PDBs (assuming no format change, etc).



//  enum describing compile flag ambient data model


const
  CV_CFL_DNEAR    = $00;
  CV_CFL_DFAR     = $01;
  CV_CFL_DHUGE    = $02;




//  enum describing compile flag ambiant code model


  CV_CFL_CNEAR    = $00;
  CV_CFL_CFAR     = $01;
  CV_CFL_CHUGE    = $02;




//  enum describing compile flag target floating point package

    CV_CFL_NDP      = $00;
    CV_CFL_EMU      = $01;
    CV_CFL_ALT      = $02;


// enum describing function return method

type
  CV_PROCFLAGS = packed record
    function GetCV_PFLAG_NOFPO: UInt8; inline;
    function GetCV_PFLAG_INT: UInt8; inline;
    function GetCV_PFLAG_FAR: UInt8; inline;
    function GetCV_PFLAG_NEVER: UInt8; inline;
    function GetCV_PFLAG_NOTREACHED: UInt8; inline;
    function GetCV_PFLAG_CUST_CALL: UInt8; inline;
    function GetCV_PFLAG_NOINLINE: UInt8; inline;
    function GetCV_PFLAG_OPTDBGINFO: UInt8; inline;
    procedure SetCV_PFLAG_NOFPO(Value: UInt8); inline;
    procedure SetCV_PFLAG_INT(Value: UInt8); inline;
    procedure SetCV_PFLAG_FAR(Value: UInt8); inline;
    procedure SetCV_PFLAG_NEVER(Value: UInt8); inline;
    procedure SetCV_PFLAG_NOTREACHED(Value: UInt8); inline;
    procedure SetCV_PFLAG_CUST_CALL(Value: UInt8); inline;
    procedure SetCV_PFLAG_NOINLINE(Value: UInt8); inline;
    procedure SetCV_PFLAG_OPTDBGINFO(Value: UInt8); inline;
    property CV_PFLAG_NOFPO: UInt8 read GetCV_PFLAG_NOFPO write SetCV_PFLAG_NOFPO;
    property CV_PFLAG_INT: UInt8 read GetCV_PFLAG_INT write SetCV_PFLAG_INT;
    property CV_PFLAG_FAR: UInt8 read GetCV_PFLAG_FAR write SetCV_PFLAG_FAR;
    property CV_PFLAG_NEVER: UInt8 read GetCV_PFLAG_NEVER write SetCV_PFLAG_NEVER;
    property CV_PFLAG_NOTREACHED: UInt8 read GetCV_PFLAG_NOTREACHED write SetCV_PFLAG_NOTREACHED;
    property CV_PFLAG_CUST_CALL: UInt8 read GetCV_PFLAG_CUST_CALL write SetCV_PFLAG_CUST_CALL;
    property CV_PFLAG_NOINLINE: UInt8 read GetCV_PFLAG_NOINLINE write SetCV_PFLAG_NOINLINE;
    property CV_PFLAG_OPTDBGINFO: UInt8 read GetCV_PFLAG_OPTDBGINFO write SetCV_PFLAG_OPTDBGINFO;
//    unsigned char CV_PFLAG_NOFPO     :1; // frame pointer present
//    unsigned char CV_PFLAG_INT       :1; // interrupt return
//    unsigned char CV_PFLAG_FAR       :1; // far return
//    unsigned char CV_PFLAG_NEVER     :1; // function does not return
//    unsigned char CV_PFLAG_NOTREACHED:1; // label isn't fallen into
//    unsigned char CV_PFLAG_CUST_CALL :1; // custom calling convention
//    unsigned char CV_PFLAG_NOINLINE  :1; // function marked as noinline
//    unsigned char CV_PFLAG_OPTDBGINFO:1; // function has debug information for optimized code
  case Integer of
    0: (bAll: UInt8);
    1: (grfAll: UInt8);
    2: (_props: UInt8);
  end;

// Extended proc flags
//
  CV_EXPROCFLAGS = packed record
    cvpf: CV_PROCFLAGS;
  case Integer of
    0: (grfAll: UInt8);
    1: (__reserved_byte: UInt8); // must be zero
  end;

// local variable flags
  CV_LVARFLAGS = packed record
    _props: UInt16;
    function GetfIsParam: UInt16; inline;
    function GetfAddrTaken: UInt16; inline;
    function GetfCompGenx: UInt16; inline;
    function GetfIsAggregate: UInt16; inline;
    function GetfIsAggregated: UInt16; inline;
    function GetfIsAliased: UInt16; inline;
    function GetfIsAlias: UInt16; inline;
    function GetfIsRetValue: UInt16; inline;
    function GetfIsOptimizedOut: UInt16; inline;
    function GetfIsEnregGlob: UInt16; inline;
    function GetfIsEnregStat: UInt16; inline;
    function Getunused: UInt16; inline;
    procedure SetfIsParam(Value: UInt16); inline;
    procedure SetfAddrTaken(Value: UInt16); inline;
    procedure SetfCompGenx(Value: UInt16); inline;
    procedure SetfIsAggregate(Value: UInt16); inline;
    procedure SetfIsAggregated(Value: UInt16); inline;
    procedure SetfIsAliased(Value: UInt16); inline;
    procedure SetfIsAlias(Value: UInt16); inline;
    procedure SetfIsRetValue(Value: UInt16); inline;
    procedure SetfIsOptimizedOut(Value: UInt16); inline;
    procedure SetfIsEnregGlob(Value: UInt16); inline;
    procedure SetfIsEnregStat(Value: UInt16); inline;
    procedure Setunused(Value: UInt16); inline;
    property fIsParam: UInt16 read GetfIsParam write SetfIsParam;
    property fAddrTaken: UInt16 read GetfAddrTaken write SetfAddrTaken;
    property fCompGenx: UInt16 read GetfCompGenx write SetfCompGenx;
    property fIsAggregate: UInt16 read GetfIsAggregate write SetfIsAggregate;
    property fIsAggregated: UInt16 read GetfIsAggregated write SetfIsAggregated;
    property fIsAliased: UInt16 read GetfIsAliased write SetfIsAliased;
    property fIsAlias: UInt16 read GetfIsAlias write SetfIsAlias;
    property fIsRetValue: UInt16 read GetfIsRetValue write SetfIsRetValue;
    property fIsOptimizedOut: UInt16 read GetfIsOptimizedOut write SetfIsOptimizedOut;
    property fIsEnregGlob: UInt16 read GetfIsEnregGlob write SetfIsEnregGlob;
    property fIsEnregStat: UInt16 read GetfIsEnregStat write SetfIsEnregStat;
    property unused: UInt16 read Getunused write Setunused;
//    unsigned short fIsParam          :1; // variable is a parameter
//    unsigned short fAddrTaken        :1; // address is taken
//    unsigned short fCompGenx         :1; // variable is compiler generated
//    unsigned short fIsAggregate      :1; // the symbol is splitted in temporaries,
//                                         // which are treated by compiler as
//                                         // independent entities
//    unsigned short fIsAggregated     :1; // Counterpart of fIsAggregate - tells
//                                         // that it is a part of a fIsAggregate symbol
//    unsigned short fIsAliased        :1; // variable has multiple simultaneous lifetimes
//    unsigned short fIsAlias          :1; // represents one of the multiple simultaneous lifetimes
//    unsigned short fIsRetValue       :1; // represents a function return value
//    unsigned short fIsOptimizedOut   :1; // variable has no lifetimes
//    unsigned short fIsEnregGlob      :1; // variable is an enregistered global
//    unsigned short fIsEnregStat      :1; // variable is an enregistered static
//
//    unsigned short unused            :5; // must be zero
  end;

// extended attributes common to all local variables
  PCV_lvar_attr = ^CV_lvar_attr;
  CV_lvar_attr = packed record
    off:   CV_uoff32_t;       // first code address where var is live
    seg:   UInt16;
    flags: CV_LVARFLAGS;      // local var flags
  end;

// This is max length of a lexical linear IP range.
// The upper number are reserved for seeded and flow based range

const
  CV_LEXICAL_RANGE_MAX = $F000;

// represents an address range, used for optimized code debug info

type
  PCV_LVAR_ADDR_RANGE = ^CV_LVAR_ADDR_RANGE;
  CV_LVAR_ADDR_RANGE = packed record       // defines a range of addresses
    offStart:   CV_uoff32_t;
    isectStart: UInt16;
    cbRange:    UInt16;
  end;

// Represents the holes in overall address range, all address is pre-bbt.
// it is for compress and reduce the amount of relocations need.

  PCV_LVAR_ADDR_GAP = ^CV_LVAR_ADDR_GAP;
  CV_LVAR_ADDR_GAP = packed record
    gapStartOffset: UInt16;         // relative offset from the beginning of the live range.
    cbRange:        UInt16;         // length of this gap.
  end;

{$if defined(CC_DP_CXX)}

// Represents a mapping from a DPC pointer tag value to the corresponding symbol record
  PCV_DPC_SYM_TAG_MAP_ENTRY = ^CV_DPC_SYM_TAG_MAP_ENTRY;
  CV_DPC_SYM_TAG_MAP_ENTRY = packed record
    tagValue: UInt32;               // address taken symbol's pointer tag value.
    symRecordOffset: CV_off32_t;    // offset of the symbol record from the S_LPROC32_DPC record it is nested within
  end;

{$endif CC_DP_CXX}

// enum describing function data return method

const
  CV_GENERIC_VOID   = $00;       // void return type
  CV_GENERIC_REG    = $01;       // return data is in registers
  CV_GENERIC_ICAN   = $02;       // indirect caller allocated near
  CV_GENERIC_ICAF   = $03;       // indirect caller allocated far
  CV_GENERIC_IRAN   = $04;       // indirect returnee allocated near
  CV_GENERIC_IRAF   = $05;       // indirect returnee allocated far
  CV_GENERIC_UNUSED = $06;       // first unused


type
  PCV_GENERIC_FLAG = ^CV_GENERIC_FLAG;
  CV_GENERIC_FLAG = packed record
    _props: UInt16;
    function Getcstyle: UInt16; inline;
    function Getrsclean: UInt16; inline;
    function Getunused: UInt16; inline;
    procedure Setcstyle(Value: UInt16); inline;
    procedure Setrsclean(Value: UInt16); inline;
    procedure Setunused(Value: UInt16); inline;
    property cstyle: UInt16 read Getcstyle write Setcstyle;
    property rsclean: UInt16 read Getrsclean write Setrsclean;
    property unused: UInt16 read Getunused write Setunused;
//    unsigned short  cstyle  :1;     // true push varargs right to left
//    unsigned short  rsclean :1;     // true if returnee stack cleanup
//    unsigned short  unused  :14;    // unused
  end;


// flag bitfields for separated code attributes

  CV_SEPCODEFLAGS = packed record
    _props: UInt32;
    function GetfIsLexicalScope: UInt32; inline;
    function GetfReturnsToParent: UInt32; inline;
    function Getpad: UInt32; inline;
    procedure SetfIsLexicalScope(Value: UInt32); inline;
    procedure SetfReturnsToParent(Value: UInt32); inline;
    procedure Setpad(Value: UInt32); inline;
    property fIsLexicalScope: UInt32 read GetfIsLexicalScope write SetfIsLexicalScope;
    property fReturnsToParent: UInt32 read GetfReturnsToParent write SetfReturnsToParent;
    property pad: UInt32 read Getpad write Setpad;
//    unsigned long fIsLexicalScope : 1;     // S_SEPCODE doubles as lexical scope
//    unsigned long fReturnsToParent : 1;    // code frag returns to parent
//    unsigned long pad : 30;                // must be zero
  end;

// Generic layout for symbol records

  PSYMTYPE = ^SYMTYPE;
  SYMTYPE = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // Record type
    data: array [0..0] of Int8;
  end;

function NextSym(pSym: PSYMTYPE): PSYMTYPE; inline;

//      non-model specific symbol types


type
  PREGSYM_16t = ^REGSYM_16t;
  REGSYM_16t = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_REGISTER_16t
    typind: CV_typ16_t;             // Type index
    reg:    UInt16;                 // register enumerate
    name:   array [0..0] of UInt8;  // Length-prefixed name
  end;

  PREGSYM = ^REGSYM;
  REGSYM = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_REGISTER
    typind: CV_typ_t;               // Type index or Metadata token
    reg:    UInt16;                 // register enumerate
    name:   array [0..0] of UInt8;  // Length-prefixed name
  end;

  PATTRREGSYM = ^ATTRREGSYM;
  ATTRREGSYM = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_MANREGISTER | S_ATTR_REGISTER
    typind: CV_typ_t;               // Type index or Metadata token
    attr:   CV_lvar_attr;           // local var attributes
    reg:    UInt16;                 // register enumerate
    name:   array [0..0] of UInt8;  // Length-prefixed name
  end;

  PMANYREGSYM_16t = ^MANYREGSYM_16t;
  MANYREGSYM_16t = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_MANYREG_16t
    typind: CV_typ16_t;             // Type index
    count:  UInt8;                  // count of number of registers
    reg:    array [0..0] of UInt8;  // count register enumerates followed by
                                    // length-prefixed name.  Registers are
                                    // most significant first.
  end;

  PMANYREGSYM = ^MANYREGSYM;
  MANYREGSYM = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_MANYREG
    typind: CV_typ_t;               // Type index or metadata token
    count:  UInt8;                  // count of number of registers
    reg:    array [0..0] of UInt8;  // count register enumerates followed by
                                    // length-prefixed name.  Registers are
                                    // most significant first.
  end;

  PMANYREGSYM2 = ^MANYREGSYM2;
  MANYREGSYM2 = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_MANYREG2
    typind: CV_typ_t;               // Type index or metadata token
    count:  UInt16;                 // count of number of registers
    reg:    array [0..0] of UInt16; // count register enumerates followed by
                                    // length-prefixed name.  Registers are
                                    // most significant first.
  end;

  PATTRMANYREGSYM = ^ATTRMANYREGSYM;
  ATTRMANYREGSYM = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_MANMANYREG
    typind: CV_typ_t;               // Type index or metadata token
    attr:   CV_lvar_attr;           // local var attributes
    count:  UInt8;                  // count of number of registers
    reg:    array [0..0] of UInt8;  // count register enumerates followed by
                                    // length-prefixed name.  Registers are
                                    // most significant first.
    name:   array [0..0] of UInt8;  // utf-8 encoded zero terminate name
  end;

  PATTRMANYREGSYM2 = ^ATTRMANYREGSYM2;
  ATTRMANYREGSYM2 = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_MANMANYREG2 | S_ATTR_MANYREG
    typind: CV_typ_t;               // Type index or metadata token
    attr:   CV_lvar_attr;           // local var attributes
    count:  UInt16;                 // count of number of registers
    reg:    array [0..0] of UInt16; // count register enumerates followed by
                                    // length-prefixed name.  Registers are
                                    // most significant first.
    name:   array [0..0] of UInt8;  // utf-8 encoded zero terminate name
  end;

  PCONSTSYM_16t = ^CONSTSYM_16t;
  CONSTSYM_16t = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_CONSTANT_16t
    typind: CV_typ16_t;             // Type index (containing enum if enumerate)
    value:  UInt16;                 // numeric leaf containing value
    name:   array [0..0] of UInt8;  // Length-prefixed name
  end;

  PCONSTSYM = ^CONSTSYM;
  CONSTSYM = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_CONSTANT or S_MANCONSTANT
    typind: CV_typ_t;               // Type index (containing enum if enumerate) or metadata token
    value:  UInt16;                 // numeric leaf containing value
    name:   array [0..0] of UInt8;  // Length-prefixed name
  end;


  PUDTSYM_16t = ^UDTSYM_16t;
  UDTSYM_16t = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_UDT_16t | S_COBOLUDT_16t
    typind: CV_typ16_t;             // Type index
    name:   array [0..0] of UInt8;  // Length-prefixed name
  end;


  PUDTSYM = ^UDTSYM;
  UDTSYM = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_UDT | S_COBOLUDT
    typind: CV_typ_t;               // Type index
    name:   array [0..0] of UInt8;  // Length-prefixed name
  end;

  PMANTYPREF = ^MANTYPREF;
  MANTYPREF = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_MANTYPREF
    typind: CV_typ_t;               // Type index
  end;

  PSEARCHSYM = ^SEARCHSYM;
  SEARCHSYM = packed record
    reclen:   UInt16;               // Record length
    rectyp:   UInt16;               // S_SSEARCH
    startsym: UInt32;               // offset of the procedure
    seg:      UInt16;               // segment of symbol
  end;

  CFLAGSYM_FLAGS = packed record
    language: UInt8;
    _props: array [0..1] of UInt8;
    function Getpcode: UInt8; inline;
    function Getfloatprec: UInt8; inline;
    function Getfloatpkg: UInt8; inline;
    function Getambdata: UInt8; inline;
    function Getambcode: UInt8; inline;
    function Getmode32: UInt8; inline;
    function Getpad: UInt8; inline;
    procedure Setpcode(Value: UInt8); inline;
    procedure Setfloatprec(Value: UInt8); inline;
    procedure Setfloatpkg(Value: UInt8); inline;
    procedure Setambdata(Value: UInt8); inline;
    procedure Setambcode(Value: UInt8); inline;
    procedure Setmode32(Value: UInt8); inline;
    procedure Setpad(Value: UInt8); inline;
    property pcode: UInt8 read Getpcode write Setpcode;
    property floatprec: UInt8 read Getfloatprec write Setfloatprec;
    property floatpkg: UInt8 read Getfloatpkg write Setfloatpkg;
    property ambdata: UInt8 read Getambdata write Setambdata;
    property ambcode: UInt8 read Getambcode write Setambcode;
    property mode32: UInt8 read Getmode32 write Setmode32;
    property pad: UInt8 read Getpad write Setpad;
//     unsigned char   language    :8; // language index
//     unsigned char   pcode       :1; // true if pcode present
//     unsigned char   floatprec   :2; // floating precision
//     unsigned char   floatpkg    :2; // float package
//     unsigned char   ambdata     :3; // ambient data model
//     unsigned char   ambcode     :3; // ambient code model
//     unsigned char   mode32      :1; // true if compiled 32 bit mode
//     unsigned char   pad         :4; // reserved
  end;

  PCFLAGSYM = ^CFLAGSYM;
  CFLAGSYM = packed record
    reclen:  UInt16;                // Record length
    rectyp:  UInt16;                // S_COMPILE
    machine: UInt8;                 // target processor
    flags:   CFLAGSYM_FLAGS;
    ver:     array [0..0] of UInt8; // Length-prefixed compiler version string
  end;


  COMPILESYM_FLAGS = packed record
    _props: UInt32;
    function GetiLanguage: UInt32; inline;
    function GetfEC: UInt32; inline;
    function GetfNoDbgInfo: UInt32; inline;
    function GetfLTCG: UInt32; inline;
    function GetfNoDataAlign: UInt32; inline;
    function GetfManagedPresent: UInt32; inline;
    function GetfSecurityChecks: UInt32; inline;
    function GetfHotPatch: UInt32; inline;
    function GetfCVTCIL: UInt32; inline;
    function GetfMSILModule: UInt32; inline;
    function Getpad: UInt32; inline;
    procedure SetiLanguage(Value: UInt32); inline;
    procedure SetfEC(Value: UInt32); inline;
    procedure SetfNoDbgInfo(Value: UInt32); inline;
    procedure SetfLTCG(Value: UInt32); inline;
    procedure SetfNoDataAlign(Value: UInt32); inline;
    procedure SetfManagedPresent(Value: UInt32); inline;
    procedure SetfSecurityChecks(Value: UInt32); inline;
    procedure SetfHotPatch(Value: UInt32); inline;
    procedure SetfCVTCIL(Value: UInt32); inline;
    procedure SetfMSILModule(Value: UInt32); inline;
    procedure Setpad(Value: UInt32); inline;
    property iLanguage: UInt32 read GetiLanguage write SetiLanguage;
    property fEC: UInt32 read GetfEC write SetfEC;
    property fNoDbgInfo: UInt32 read GetfNoDbgInfo write SetfNoDbgInfo;
    property fLTCG: UInt32 read GetfLTCG write SetfLTCG;
    property fNoDataAlign: UInt32 read GetfNoDataAlign write SetfNoDataAlign;
    property fManagedPresent: UInt32 read GetfManagedPresent write SetfManagedPresent;
    property fSecurityChecks: UInt32 read GetfSecurityChecks write SetfSecurityChecks;
    property fHotPatch: UInt32 read GetfHotPatch write SetfHotPatch;
    property fCVTCIL: UInt32 read GetfCVTCIL write SetfCVTCIL;
    property fMSILModule: UInt32 read GetfMSILModule write SetfMSILModule;
    property pad: UInt32 read Getpad write Setpad;
//    unsigned long   iLanguage       :  8;   // language index
//    unsigned long   fEC             :  1;   // compiled for E/C
//    unsigned long   fNoDbgInfo      :  1;   // not compiled with debug info
//    unsigned long   fLTCG           :  1;   // compiled with LTCG
//    unsigned long   fNoDataAlign    :  1;   // compiled with -Bzalign
//    unsigned long   fManagedPresent :  1;   // managed code/data present
//    unsigned long   fSecurityChecks :  1;   // compiled with /GS
//    unsigned long   fHotPatch       :  1;   // compiled with /hotpatch
//    unsigned long   fCVTCIL         :  1;   // converted with CVTCIL
//    unsigned long   fMSILModule     :  1;   // MSIL netmodule
//    unsigned long   pad             : 15;   // reserved, must be 0
  end;

  PCOMPILESYM = ^COMPILESYM;
  COMPILESYM = packed record
    reclen:     UInt16;             // Record length
    rectyp:     UInt16;             // S_COMPILE2
    flags:      COMPILESYM_FLAGS;
    machine:    UInt16;             // target processor
    verFEMajor: UInt16;             // front end major version #
    verFEMinor: UInt16;             // front end minor version #
    verFEBuild: UInt16;             // front end build version #
    verMajor:   UInt16;             // back end major version #
    verMinor:   UInt16;             // back end minor version #
    verBuild:   UInt16;             // back end build version #
    verSt:      array [0..0] of UInt8;  // Length-prefixed compiler version string, followed
                                    //  by an optional block of zero terminated strings
                                    //  terminated with a double zero.
  end;

  COMPILESYM3_FLAGS = packed record
    _props: UInt32;
    function GetiLanguage: UInt32; inline;
    function GetfEC: UInt32; inline;
    function GetfNoDbgInfo: UInt32; inline;
    function GetfLTCG: UInt32; inline;
    function GetfNoDataAlign: UInt32; inline;
    function GetfManagedPresent: UInt32; inline;
    function GetfSecurityChecks: UInt32; inline;
    function GetfHotPatch: UInt32; inline;
    function GetfCVTCIL: UInt32; inline;
    function GetfMSILModule: UInt32; inline;
    function GetfSdl: UInt32; inline;
    function GetfPGO: UInt32; inline;
    function GetfExp: UInt32; inline;
    function Getpad: UInt32; inline;
    procedure SetiLanguage(Value: UInt32); inline;
    procedure SetfEC(Value: UInt32); inline;
    procedure SetfNoDbgInfo(Value: UInt32); inline;
    procedure SetfLTCG(Value: UInt32); inline;
    procedure SetfNoDataAlign(Value: UInt32); inline;
    procedure SetfManagedPresent(Value: UInt32); inline;
    procedure SetfSecurityChecks(Value: UInt32); inline;
    procedure SetfHotPatch(Value: UInt32); inline;
    procedure SetfCVTCIL(Value: UInt32); inline;
    procedure SetfMSILModule(Value: UInt32); inline;
    procedure SetfSdl(Value: UInt32); inline;
    procedure SetfPGO(Value: UInt32); inline;
    procedure SetfExp(Value: UInt32); inline;
    procedure Setpad(Value: UInt32); inline;
    property iLanguage: UInt32 read GetiLanguage write SetiLanguage;
    property fEC: UInt32 read GetfEC write SetfEC;
    property fNoDbgInfo: UInt32 read GetfNoDbgInfo write SetfNoDbgInfo;
    property fLTCG: UInt32 read GetfLTCG write SetfLTCG;
    property fNoDataAlign: UInt32 read GetfNoDataAlign write SetfNoDataAlign;
    property fManagedPresent: UInt32 read GetfManagedPresent write SetfManagedPresent;
    property fSecurityChecks: UInt32 read GetfSecurityChecks write SetfSecurityChecks;
    property fHotPatch: UInt32 read GetfHotPatch write SetfHotPatch;
    property fCVTCIL: UInt32 read GetfCVTCIL write SetfCVTCIL;
    property fMSILModule: UInt32 read GetfMSILModule write SetfMSILModule;
    property fSdl: UInt32 read GetfSdl write SetfSdl;
    property fPGO: UInt32 read GetfPGO write SetfPGO;
    property fExp: UInt32 read GetfExp write SetfExp;
    property pad: UInt32 read Getpad write Setpad;
//    unsigned long   iLanguage       :  8;   // language index
//    unsigned long   fEC             :  1;   // compiled for E/C
//    unsigned long   fNoDbgInfo      :  1;   // not compiled with debug info
//    unsigned long   fLTCG           :  1;   // compiled with LTCG
//    unsigned long   fNoDataAlign    :  1;   // compiled with -Bzalign
//    unsigned long   fManagedPresent :  1;   // managed code/data present
//    unsigned long   fSecurityChecks :  1;   // compiled with /GS
//    unsigned long   fHotPatch       :  1;   // compiled with /hotpatch
//    unsigned long   fCVTCIL         :  1;   // converted with CVTCIL
//    unsigned long   fMSILModule     :  1;   // MSIL netmodule
//    unsigned long   fSdl            :  1;   // compiled with /sdl
//    unsigned long   fPGO            :  1;   // compiled with /ltcg:pgo or pgu
//    unsigned long   fExp            :  1;   // .exp module
//    unsigned long   pad             : 12;   // reserved, must be 0
  end;

  PCOMPILESYM3 = ^COMPILESYM3;
  COMPILESYM3 = packed record
    reclen:     UInt16;             // Record length
    rectyp:     UInt16;             // S_COMPILE3
    flags:      COMPILESYM3_FLAGS;
    machine:    UInt16;             // target processor
    verFEMajor: UInt16;             // front end major version #
    verFEMinor: UInt16;             // front end minor version #
    verFEBuild: UInt16;             // front end build version #
    verFEQFE:   UInt16;             // front end QFE version #
    verMajor:   UInt16;             // back end major version #
    verMinor:   UInt16;             // back end minor version #
    verBuild:   UInt16;             // back end build version #
    verQFE:     UInt16;             // back end QFE version #
    verSz:      array [0..0] of Int8; // Zero terminated compiler version string
  end;

  ENVBLOCKSYM_FLAGS = packed record
    _props: UInt8;
    function Getrev: UInt8; inline;
    function Getpad: UInt8; inline;
    procedure Setrev(Value: UInt8); inline;
    procedure Setpad(Value: UInt8); inline;
    property rev: UInt8 read Getrev write Setrev;
    property pad: UInt8 read Getpad write Setpad;
//    unsigned char  rev              : 1;    // reserved
//    unsigned char  pad              : 7;    // reserved, must be 0
  end;

  PENVBLOCKSYM = ^ENVBLOCKSYM;
  ENVBLOCKSYM = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_ENVBLOCK
    flags:  ENVBLOCKSYM_FLAGS;
    rgsz:   array [0..0] of UInt8;  // Sequence of zero-terminated strings
  end;

  POBJNAMESYM = ^OBJNAMESYM;
  OBJNAMESYM = packed record
    reclen:    UInt16;              // Record length
    rectyp:    UInt16;              // S_OBJNAME
    signature: UInt32;              // signature
    name:      array [0..0] of UInt8; // Length-prefixed name
  end;


  PENDARGSYM = ^ENDARGSYM;
  ENDARGSYM = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_ENDARG
  end;


  PRETURNSYM = ^RETURNSYM;
  RETURNSYM = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_RETURN
    flags:  CV_GENERIC_FLAG;        // flags
    style:  UInt8;                  // CV_GENERIC_STYLE_e return style
                                    // followed by return method data
  end;


  PENTRYTHISSYM = ^ENTRYTHISSYM;
  ENTRYTHISSYM = packed record
    reclen:  UInt16;                // Record length
    rectyp:  UInt16;                // S_ENTRYTHIS
    thissym: UInt8;                 // symbol describing this pointer on entry
  end;


//      symbol types for 16:16 memory model


  PBPRELSYM16 = ^BPRELSYM16;
  BPRELSYM16 = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_BPREL16
    off:    CV_off16_t;             // BP-relative offset
    typind: CV_typ16_t;             // Type index
    name:   array [0..0] of UInt8;  // Length-prefixed name
  end;


  PDATASYM16 = ^DATASYM16;
  DATASYM16 = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_LDATA or S_GDATA
    off:    CV_uoff16_t;            // offset of symbol
    seg:    UInt16;                 // segment of symbol
    typind: CV_typ16_t;             // Type index
    name:   array [0..0] of UInt8;  // Length-prefixed name
  end;
  PPUBSYM16 = PDATASYM16;
  PUBSYM16 = DATASYM16;


  PPROCSYM16 = ^PROCSYM16;
  PROCSYM16 = packed record
    reclen:   UInt16;               // Record length
    rectyp:   UInt16;               // S_GPROC16 or S_LPROC16
    pParent:  UInt32;               // pointer to the parent
    pEnd:     UInt32;               // pointer to this blocks end
    pNext:    UInt32;               // pointer to next symbol
    len:      UInt16;               // Proc length
    DbgStart: UInt16;               // Debug start offset
    DbgEnd:   UInt16;               // Debug end offset
    off:      CV_uoff16_t;          // offset of symbol
    seg:      UInt16;               // segment of symbol
    typind:   CV_typ16_t;           // Type index
    flags:    CV_PROCFLAGS;         // Proc flags
    name:     array [0..0] of UInt8;  // Length-prefixed name
  end;


  PTHUNKSYM16 = ^THUNKSYM16;
  THUNKSYM16 = packed record
    reclen:  UInt16;                // Record length
    rectyp:  UInt16;                // S_THUNK
    pParent: UInt32;                // pointer to the parent
    pEnd:    UInt32;                // pointer to this blocks end
    pNext:   UInt32;                // pointer to next symbol
    off:     CV_uoff16_t;           // offset of symbol
    seg:     UInt16;                // segment of symbol
    len:     UInt16;                // length of thunk
    ord:     UInt8;                 // THUNK_ORDINAL specifying type of thunk
    name:    array [0..0] of UInt8; // name of thunk
    variant: array [0..0] of UInt8; // variant portion of thunk
  end;

  PLABELSYM16 = ^LABELSYM16;
  LABELSYM16 = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_LABEL16
    off:    CV_uoff16_t;            // offset of symbol
    seg:    UInt16;                 // segment of symbol
    flags:  CV_PROCFLAGS;           // flags
    name:   array [0..0] of UInt8;  // Length-prefixed name
  end;


  PBLOCKSYM16 = ^BLOCKSYM16;
  BLOCKSYM16 = packed record
    reclen:  UInt16;                // Record length
    rectyp:  UInt16;                // S_BLOCK16
    pParent: UInt32;                // pointer to the parent
    pEnd:    UInt32;                // pointer to this blocks end
    len:     UInt16;                // Block length
    off:     CV_uoff16_t;           // offset of symbol
    seg:     UInt16;                // segment of symbol
    name:    array [0..0] of UInt8; // Length-prefixed name
  end;


  PWITHSYM16 = ^WITHSYM16;
  WITHSYM16 = packed record
    reclen:  UInt16;                // Record length
    rectyp:  UInt16;                // S_WITH16
    pParent: UInt32;                // pointer to the parent
    pEnd:    UInt32;                // pointer to this blocks end
    len:     UInt16;                // Block length
    off:     CV_uoff16_t;           // offset of symbol
    seg:     UInt16;                // segment of symbol
    expr:    array [0..0] of UInt8; // Length-prefixed expression
  end;


const
    CEXM_MDL_table          = $00; // not executable
    CEXM_MDL_jumptable      = $01; // Compiler generated jump table
    CEXM_MDL_datapad        = $02; // Data padding for alignment
    CEXM_MDL_native         = $20; // native (actually not-pcode)
    CEXM_MDL_cobol          = $21; // cobol
    CEXM_MDL_codepad        = $22; // Code padding for alignment
    CEXM_MDL_code           = $23; // code
    CEXM_MDL_sql            = $30; // sql
    CEXM_MDL_pcode          = $40; // pcode
    CEXM_MDL_pcode32Mac     = $41; // macintosh 32 bit pcode
    CEXM_MDL_pcode32MacNep  = $42; // macintosh 32 bit pcode native entry point
    CEXM_MDL_javaInt        = $50;
    CEXM_MDL_unknown        = $ff;

// use the correct enumerate name
//#define CEXM_MDL_SQL CEXM_MDL_sql

    CV_COBOL_dontstop = 0;
    CV_COBOL_pfm      = 1;
    CV_COBOL_false    = 2;
    CV_COBOL_extcall  = 3;

type
  CEXMSYM16_PCODE = packed record
    pcdtable: CV_uoff16_t;          // offset to pcode function table
    pcdspi:   CV_uoff16_t;          // offset to segment pcode information
  end;

  CEXMSYM16_COBOL = packed record
    subtype: UInt16;                // see CV_COBOL_e above
    flag:    UInt16;
  end;

  PCEXMSYM16 = ^CEXMSYM16;
  CEXMSYM16 = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_CEXMODEL16
    off:    CV_uoff16_t;            // offset of symbol
    seg:    UInt16;                 // segment of symbol
    model:  UInt16;                 // execution model
  case Integer of
    0: (pcode: CEXMSYM16_PCODE);
    1: (cobol: CEXMSYM16_COBOL);
  end;


  PVPATHSYM16 = ^VPATHSYM16;
  VPATHSYM16 = packed record
    reclen: UInt16;                 // record length
    rectyp: UInt16;                 // S_VFTPATH16
    off:    CV_uoff16_t;            // offset of virtual function table
    seg:    UInt16;                 // segment of virtual function table
    root:   CV_typ16_t;             // type index of the root of path
    path:   CV_typ16_t;             // type index of the path record
  end;


  PREGREL16 = ^REGREL16;
  REGREL16 = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_REGREL16
    off:    CV_uoff16_t;            // offset of symbol
    reg:    UInt16;                 // register index
    typind: CV_typ16_t;             // Type index
    name:   array [0..0] of UInt8;  // Length-prefixed name
  end;


  PBPRELSYM32_16t = ^BPRELSYM32_16t;
  BPRELSYM32_16t = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_BPREL32_16t
    off:    CV_off32_t;             // BP-relative offset
    typind: CV_typ16_t;             // Type index
    name:   array [0..0] of UInt8;  // Length-prefixed name
  end;

  PBPRELSYM32 = ^BPRELSYM32;
  BPRELSYM32 = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_BPREL32
    off:    CV_off32_t;             // BP-relative offset
    typind: CV_typ_t;               // Type index or Metadata token
    name:   array [0..0] of UInt8;  // Length-prefixed name
  end;

  PFRAMERELSYM = ^FRAMERELSYM;
  FRAMERELSYM = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_MANFRAMEREL | S_ATTR_FRAMEREL
    off:    CV_off32_t;             // Frame relative offset
    typind: CV_typ_t;               // Type index or Metadata token
    attr:   CV_lvar_attr;           // local var attributes
    name:   array [0..0] of UInt8;  // Length-prefixed name
  end;

  PATTRFRAMERELSYM = PFRAMERELSYM;
  ATTRFRAMERELSYM = FRAMERELSYM;


  PSLOTSYM32 = ^SLOTSYM32;
  SLOTSYM32 = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_LOCALSLOT or S_PARAMSLOT
    iSlot:  UInt32;                 // slot index
    typind: CV_typ_t;               // Type index or Metadata token
    name:   array [0..0] of UInt8;  // Length-prefixed name
  end;

  PATTRSLOTSYM = ^ATTRSLOTSYM;
  ATTRSLOTSYM = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_MANSLOT
    iSlot:  UInt32;                 // slot index
    typind: CV_typ_t;               // Type index or Metadata token
    attr:   CV_lvar_attr;           // local var attributes
    name:   array [0..0] of UInt8;  // Length-prefixed name
  end;

  PANNOTATIONSYM = ^ANNOTATIONSYM;
  ANNOTATIONSYM = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_ANNOTATION
    off:    CV_uoff32_t;
    seg:    UInt16;
    csz:    UInt16;                 // Count of zero terminated annotation strings
    rgsz:   array [0..0] of UInt8;  // Sequence of zero terminated annotation strings
  end;

  PDATASYM32_16t = ^DATASYM32_16t;
  DATASYM32_16t = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_LDATA32_16t, S_GDATA32_16t or S_PUB32_16t
    off:    CV_uoff32_t;
    seg:    UInt16;
    typind: CV_typ16_t;             // Type index
    name:   array [0..0] of UInt8;  // Length-prefixed name
  end;
  PPUBSYM32_16t = PDATASYM32_16t;
  PUBSYM32_16t = DATASYM32_16t;

  PDATASYM32 = ^DATASYM32;
  DATASYM32 = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_LDATA32, S_GDATA32, S_LMANDATA, S_GMANDATA
    typind: CV_typ_t;               // Type index, or Metadata token if a managed symbol
    off:    CV_uoff32_t;
    seg:    UInt16;
    name:   array [0..0] of UInt8;  // Length-prefixed name
  end;

  PDATASYMHLSL = ^DATASYMHLSL;
  DATASYMHLSL = packed record
    reclen:   UInt16;               // Record length
    rectyp:   UInt16;               // S_GDATA_HLSL, S_LDATA_HLSL
    typind:   CV_typ_t;             // Type index
    regType:  UInt16;               // register type from CV_HLSLREG_e
    dataslot: UInt16;               // Base data (cbuffer, groupshared, etc.) slot
    dataoff:  UInt16;               // Base data byte offset start
    texslot:  UInt16;               // Texture slot start
    sampslot: UInt16;               // Sampler slot start
    uavslot:  UInt16;               // UAV slot start
    name:     array [0..0] of UInt8;  // name
  end;

  PDATASYMHLSL32 = ^DATASYMHLSL32;
  DATASYMHLSL32 = packed record
    reclen:   UInt16;               // Record length
    rectyp:   UInt16;               // S_GDATA_HLSL32, S_LDATA_HLSL32
    typind:   CV_typ_t;             // Type index
    dataslot: UInt32;               // Base data (cbuffer, groupshared, etc.) slot
    dataoff:  UInt32;               // Base data byte offset start
    texslot:  UInt32;               // Texture slot start
    sampslot: UInt32;               // Sampler slot start
    uavslot:  UInt32;               // UAV slot start
    regType:  UInt16;               // register type from CV_HLSLREG_e
    name:     array [0..0] of UInt8;  // name
  end;

  PDATASYMHLSL32_EX = ^DATASYMHLSL32_EX;
  DATASYMHLSL32_EX = packed record
    reclen:    UInt16;              // Record length
    rectyp:    UInt16;              // S_GDATA_HLSL32_EX, S_LDATA_HLSL32_EX
    typind:    CV_typ_t;            // Type index
    regID:     UInt32;              // Register index
    dataoff:   UInt32;              // Base data byte offset start
    bindSpace: UInt32;              // Binding space
    bindSlot:  UInt32;              // Lower bound in binding space
    regType:   UInt16;              // register type from CV_HLSLREG_e
    name:      array [0..0] of UInt8; // name
  end;

const
  cvpsfNone     = 0;
  cvpsfCode     = $00000001;
  cvpsfFunction = $00000002;
  cvpsfManaged  = $00000004;
  cvpsfMSIL     = $00000008;

type
  CV_PUBSYMFLAGS = packed record
    grfFlags: CV_pubsymflag_t;
    function GetfCode: CV_pubsymflag_t; inline;
    function GetfFunction: CV_pubsymflag_t; inline;
    function GetfManaged: CV_pubsymflag_t; inline;
    function GetfMSIL: CV_pubsymflag_t; inline;
    function Get__unused: CV_pubsymflag_t; inline;
    procedure SetfCode(Value: CV_pubsymflag_t); inline;
    procedure SetfFunction(Value: CV_pubsymflag_t); inline;
    procedure SetfManaged(Value: CV_pubsymflag_t); inline;
    procedure SetfMSIL(Value: CV_pubsymflag_t); inline;
    procedure Set__unused(Value: CV_pubsymflag_t); inline;
    property fCode: CV_pubsymflag_t read GetfCode write SetfCode;
    property fFunction: CV_pubsymflag_t read GetfFunction write SetfFunction;
    property fManaged: CV_pubsymflag_t read GetfManaged write SetfManaged;
    property fMSIL: CV_pubsymflag_t read GetfMSIL write SetfMSIL;
    property __unused: CV_pubsymflag_t read Get__unused write Set__unused;
//    CV_pubsymflag_t fCode       :  1;    // set if public symbol refers to a code address
//    CV_pubsymflag_t fFunction   :  1;    // set if public symbol is a function
//    CV_pubsymflag_t fManaged    :  1;    // set if managed code (native or IL)
//    CV_pubsymflag_t fMSIL       :  1;    // set if managed IL code
//    CV_pubsymflag_t __unused    : 28;    // must be zero
  end;

  PPUBSYM32 = ^PUBSYM32;
  PUBSYM32 = packed record
    reclen:      UInt16;            // Record length
    rectyp:      UInt16;            // S_PUB32
    pubsymflags: CV_PUBSYMFLAGS;
    off:         CV_uoff32_t;
    seg:         UInt16;
    name:        array [0..0] of UInt8; // Length-prefixed name
  end;


  PPROCSYM32_16t = ^PROCSYM32_16t;
  PROCSYM32_16t = packed record
    reclen:   UInt16;               // Record length
    rectyp:   UInt16;               // S_GPROC32_16t or S_LPROC32_16t
    pParent:  UInt32;               // pointer to the parent
    pEnd:     UInt32;               // pointer to this blocks end
    pNext:    UInt32;               // pointer to next symbol
    len:      UInt32;               // Proc length
    DbgStart: UInt32;               // Debug start offset
    DbgEnd:   UInt32;               // Debug end offset
    off:      CV_uoff32_t;
    seg:      UInt16;
    typind:   CV_typ16_t;           // Type index
    flags:    CV_PROCFLAGS;         // Proc flags
    name:     array [0..0] of UInt8;  // Length-prefixed name
  end;

  PPROCSYM32 = ^PROCSYM32;
  PROCSYM32 = packed record
    reclen:   UInt16;               // Record length
    rectyp:   UInt16;               // S_GPROC32, S_LPROC32, S_GPROC32_ID, S_LPROC32_ID, S_LPROC32_DPC or S_LPROC32_DPC_ID
    pParent:  UInt32;               // pointer to the parent
    pEnd:     UInt32;               // pointer to this blocks end
    pNext:    UInt32;               // pointer to next symbol
    len:      UInt32;               // Proc length
    DbgStart: UInt32;               // Debug start offset
    DbgEnd:   UInt32;               // Debug end offset
    typind:   CV_typ_t;             // Type index or ID
    off:      CV_uoff32_t;
    seg:      UInt16;
    flags:    CV_PROCFLAGS;         // Proc flags
    name:     array [0..0] of UInt8;  // Length-prefixed name
  end;

  PMANPROCSYM = ^MANPROCSYM;
  MANPROCSYM = packed record
    reclen:   UInt16;               // Record length
    rectyp:   UInt16;               // S_GMANPROC, S_LMANPROC, S_GMANPROCIA64 or S_LMANPROCIA64
    pParent:  UInt32;               // pointer to the parent
    pEnd:     UInt32;               // pointer to this blocks end
    pNext:    UInt32;               // pointer to next symbol
    len:      UInt32;               // Proc length
    DbgStart: UInt32;               // Debug start offset
    DbgEnd:   UInt32;               // Debug end offset
    token:    CV_tkn_t;             // COM+ metadata token for method
    off:      CV_uoff32_t;
    seg:      UInt16;
    flags:    CV_PROCFLAGS;         // Proc flags
    retReg:   UInt16;               // Register return value is in (may not be used for all archs)
    name:     array [0..0] of UInt8;  // optional name field
  end;

  PMANPROCSYMMIPS = ^MANPROCSYMMIPS;
  MANPROCSYMMIPS = packed record
    reclen:   UInt16;               // Record length
    rectyp:   UInt16;               // S_GMANPROCMIPS or S_LMANPROCMIPS
    pParent:  UInt32;               // pointer to the parent
    pEnd:     UInt32;               // pointer to this blocks end
    pNext:    UInt32;               // pointer to next symbol
    len:      UInt32;               // Proc length
    DbgStart: UInt32;               // Debug start offset
    DbgEnd:   UInt32;               // Debug end offset
    regSave:  UInt32;               // int register save mask
    fpSave:   UInt32;               // fp register save mask
    intOff:   CV_uoff32_t;          // int register save offset
    fpOff:    CV_uoff32_t;          // fp register save offset
    token:    CV_tkn_t;             // COM+ token type
    off:      CV_uoff32_t;
    seg:      UInt16;
    retReg:   UInt8;                // Register return value is in
    frameReg: UInt8;                // Frame pointer register
    name:     array [0..0] of UInt8;  // optional name field
  end;

  PTHUNKSYM32 = ^THUNKSYM32;
  THUNKSYM32 = packed record
    reclen:  UInt16;                // Record length
    rectyp:  UInt16;                // S_THUNK32
    pParent: UInt32;                // pointer to the parent
    pEnd:    UInt32;                // pointer to this blocks end
    pNext:   UInt32;                // pointer to next symbol
    off:     CV_uoff32_t;
    seg:     UInt16;
    len:     UInt16;                // length of thunk
    ord:     UInt8;                 // THUNK_ORDINAL specifying type of thunk
    name:    array [0..0] of UInt8; // Length-prefixed name
    variant: array [0..0] of UInt8; // variant portion of thunk
  end;

const      // Trampoline subtype
  trampIncremental  = 0;            // incremental thunks
  trampBranchIsland = 1;            // Branch island thunks

type
  PTRAMPOLINESYM = ^TRAMPOLINESYM;
  TRAMPOLINESYM = packed record     // Trampoline thunk symbol
    reclen:     UInt16;             // Record length
    rectyp:     UInt16;             // S_TRAMPOLINE
    trampType:  UInt16;             // trampoline sym subtype
    cbThunk:    UInt16;             // size of the thunk
    offThunk:   CV_uoff32_t;        // offset of the thunk
    offTarget:  CV_uoff32_t;        // offset of the target of the thunk
    sectThunk:  UInt16;             // section index of the thunk
    sectTarget: UInt16;             // section index of the target of the thunk
  end;

  PLABELSYM32 = ^LABELSYM32;
  LABELSYM32 = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_LABEL32
    off:    CV_uoff32_t;
    seg:    UInt16;
    flags:  CV_PROCFLAGS;           // flags
    name:   array [0..0] of UInt8;  // Length-prefixed name
  end;


  PBLOCKSYM32 = ^BLOCKSYM32;
  BLOCKSYM32 = packed record
    reclen:  UInt16;                // Record length
    rectyp:  UInt16;                // S_BLOCK32
    pParent: UInt32;                // pointer to the parent
    pEnd:    UInt32;                // pointer to this blocks end
    len:     UInt32;                // Block length
    off:     CV_uoff32_t;           // Offset in code segment
    seg:     UInt16;                // segment of label
    name:    array [0..0] of UInt8; // Length-prefixed name
  end;


  PWITHSYM32 = ^WITHSYM32;
  WITHSYM32 = packed record
    reclen:  UInt16;                // Record length
    rectyp:  UInt16;                // S_WITH32
    pParent: UInt32;                // pointer to the parent
    pEnd:    UInt32;                // pointer to this blocks end
    len:     UInt32;                // Block length
    off:     CV_uoff32_t;           // Offset in code segment
    seg:     UInt16;                // segment of label
    expr:    array [0..0] of UInt8; // Length-prefixed expression string
  end;



  CEXMSYM32_PCODE = packed record
    pcdtable: CV_uoff32_t;          // offset to pcode function table
    pcdspi:   CV_uoff32_t;          // offset to segment pcode information
  end;

  CEXMSYM32_COBOL = packed record
    subtype: UInt16;                // see CV_COBOL_e above
    flag:    UInt16;
  end;

  CEXMSYM32_PCODE32MAC = packed record
    calltableOff: CV_uoff32_t;      // offset to function table
    calltableSeg: UInt16;           // segment of function table
  end;

  PCEXMSYM32 = ^CEXMSYM32;
  CEXMSYM32 = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_CEXMODEL32
    off:    CV_uoff32_t;            // offset of symbol
    seg:    UInt16;                 // segment of symbol
    model:  UInt16;                 // execution model
  case Integer of
    0: (pcode: CEXMSYM32_PCODE);
    1: (cobol: CEXMSYM32_COBOL);
    2: (pcode32Mac: CEXMSYM32_PCODE32MAC);
  end;



  PVPATHSYM32_16t = ^VPATHSYM32_16t;
  VPATHSYM32_16t = packed record
    reclen: UInt16;                 // record length
    rectyp: UInt16;                 // S_VFTABLE32_16t
    off:    CV_uoff32_t;            // offset of virtual function table
    seg:    UInt16;                 // segment of virtual function table
    root:   CV_typ16_t;             // type index of the root of path
    path:   CV_typ16_t;             // type index of the path record
  end;

  PVPATHSYM32 = ^VPATHSYM32;
  VPATHSYM32 = packed record
    reclen: UInt16;                 // record length
    rectyp: UInt16;                 // S_VFTABLE32
    root:   CV_typ_t;               // type index of the root of path
    path:   CV_typ_t;               // type index of the path record
    off:    CV_uoff32_t;            // offset of virtual function table
    seg:    UInt16;                 // segment of virtual function table
  end;





  PREGREL32_16t = ^REGREL32_16t;
  REGREL32_16t = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_REGREL32_16t
    off:    CV_uoff32_t;            // offset of symbol
    reg:    UInt16;                 // register index for symbol
    typind: CV_typ16_t;             // Type index
    name:   array [0..0] of UInt8;  // Length-prefixed name
  end;

  PREGREL32 = ^REGREL32;
  REGREL32 = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_REGREL32
    off:    CV_uoff32_t;            // offset of symbol
    typind: CV_typ_t;               // Type index or metadata token
    reg:    UInt16;                 // register index for symbol
    name:   array [0..0] of UInt8;  // Length-prefixed name
  end;

  PATTRREGREL = ^ATTRREGREL;
  ATTRREGREL = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_MANREGREL | S_ATTR_REGREL
    off:    CV_uoff32_t;            // offset of symbol
    typind: CV_typ_t;               // Type index or metadata token
    reg:    UInt16;                 // register index for symbol
    attr:   CV_lvar_attr;           // local var attributes
    name:   array [0..0] of UInt8;  // Length-prefixed name
  end;

  PATTRREGRELSYM = PATTRREGREL;
  ATTRREGRELSYM = ATTRREGREL;

  PTHREADSYM32_16t = ^THREADSYM32_16t;
  THREADSYM32_16t = packed record
    reclen: UInt16;                 // record length
    rectyp: UInt16;                 // S_LTHREAD32_16t | S_GTHREAD32_16t
    off:    CV_uoff32_t;            // offset into thread storage
    seg:    UInt16;                 // segment of thread storage
    typind: CV_typ16_t;             // type index
    name:   array [0..0] of UInt8;  // length prefixed name
  end;

  PTHREADSYM32 = ^THREADSYM32;
  THREADSYM32 = packed record
    reclen: UInt16;                 // record length
    rectyp: UInt16;                 // S_LTHREAD32 | S_GTHREAD32
    typind: CV_typ_t;               // type index
    off:    CV_uoff32_t;            // offset into thread storage
    seg:    UInt16;                 // segment of thread storage
    name:   array [0..0] of UInt8;  // length prefixed name
  end;

  PSLINK32 = ^SLINK32;
  SLINK32 = packed record
    reclen:    UInt16;              // record length
    rectyp:    UInt16;              // S_SLINK32
    framesize: UInt32;              // frame size of parent procedure
    off:       CV_off32_t;          // signed offset where the static link was saved relative to the value of reg
    reg:       UInt16;
  end;

  PPROCSYMMIPS_16t = ^PROCSYMMIPS_16t;
  PROCSYMMIPS_16t = packed record
    reclen:   UInt16;               // Record length
    rectyp:   UInt16;               // S_GPROCMIPS_16t or S_LPROCMIPS_16t
    pParent:  UInt32;               // pointer to the parent
    pEnd:     UInt32;               // pointer to this blocks end
    pNext:    UInt32;               // pointer to next symbol
    len:      UInt32;               // Proc length
    DbgStart: UInt32;               // Debug start offset
    DbgEnd:   UInt32;               // Debug end offset
    regSave:  UInt32;               // int register save mask
    fpSave:   UInt32;               // fp register save mask
    intOff:   CV_uoff32_t;          // int register save offset
    fpOff:    CV_uoff32_t;          // fp register save offset
    off:      CV_uoff32_t;          // Symbol offset
    seg:      UInt16;               // Symbol segment
    typind:   CV_typ16_t;           // Type index
    retReg:   UInt8;                // Register return value is in
    frameReg: UInt8;                // Frame pointer register
    name:     array [0..0] of UInt8;  // Length-prefixed name
  end;

  PPROCSYMMIPS = ^PROCSYMMIPS;
  PROCSYMMIPS = packed record
    reclen:   UInt16;               // Record length
    rectyp:   UInt16;               // S_GPROCMIPS or S_LPROCMIPS
    pParent:  UInt32;               // pointer to the parent
    pEnd:     UInt32;               // pointer to this blocks end
    pNext:    UInt32;               // pointer to next symbol
    len:      UInt32;               // Proc length
    DbgStart: UInt32;               // Debug start offset
    DbgEnd:   UInt32;               // Debug end offset
    regSave:  UInt32;               // int register save mask
    fpSave:   UInt32;               // fp register save mask
    intOff:   CV_uoff32_t;          // int register save offset
    fpOff:    CV_uoff32_t;          // fp register save offset
    typind:   CV_typ_t;             // Type index
    off:      CV_uoff32_t;          // Symbol offset
    seg:      UInt16;               // Symbol segment
    retReg:   UInt8;                // Register return value is in
    frameReg: UInt8;                // Frame pointer register
    name:     array [0..0] of UInt8;  // Length-prefixed name
  end;

  PPROCSYMIA64 = ^PROCSYMIA64;
  PROCSYMIA64 = packed record
    reclen:   UInt16;               // Record length
    rectyp:   UInt16;               // S_GPROCIA64 or S_LPROCIA64
    pParent:  UInt32;               // pointer to the parent
    pEnd:     UInt32;               // pointer to this blocks end
    pNext:    UInt32;               // pointer to next symbol
    len:      UInt32;               // Proc length
    DbgStart: UInt32;               // Debug start offset
    DbgEnd:   UInt32;               // Debug end offset
    typind:   CV_typ_t;             // Type index
    off:      CV_uoff32_t;          // Symbol offset
    seg:      UInt16;               // Symbol segment
    retReg:   UInt16;               // Register return value is in
    flags:    CV_PROCFLAGS;         // Proc flags
    name:     array [0..0] of UInt8;  // Length-prefixed name
  end;

  PREFSYM = ^REFSYM;
  REFSYM = packed record
    reclen:  UInt16;                // Record length
    rectyp:  UInt16;                // S_PROCREF_ST, S_DATAREF_ST, or S_LPROCREF_ST
    sumName: UInt32;                // SUC of the name
    ibSym:   UInt32;                // Offset of actual symbol in $$Symbols
    imod:    UInt16;                // Module containing the actual symbol
    usFill:  UInt16;                // align this record
  end;

  PREFSYM2 = ^REFSYM2;
  REFSYM2 = packed record
    reclen:  UInt16;                // Record length
    rectyp:  UInt16;                // S_PROCREF, S_DATAREF, or S_LPROCREF
    sumName: UInt32;                // SUC of the name
    ibSym:   UInt32;                // Offset of actual symbol in $$Symbols
    imod:    UInt16;                // Module containing the actual symbol
    name:    array [0..0] of UInt8; // hidden name made a first class member
  end;

  PALIGNSYM = ^ALIGNSYM;
  ALIGNSYM = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_ALIGN
  end;

  POEMSYMBOL = ^OEMSYMBOL;
  OEMSYMBOL = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_OEM
    idOem:  array [0..15] of UInt8; // an oem ID (GUID)
    typind: CV_typ_t;               // Type index
    rgl:    array [0..0] of UInt32; // user data, force 4-byte alignment
  end;

//  generic block definition symbols
//  these are similar to the equivalent 16:16 or 16:32 symbols but
//  only define the length, type and linkage fields

  PPROCSYM = ^PROCSYM;
  PROCSYM = packed record
    reclen:  UInt16;                // Record length
    rectyp:  UInt16;                // S_GPROC16 or S_LPROC16
    pParent: UInt32;                // pointer to the parent
    pEnd:    UInt32;                // pointer to this blocks end
    pNext:   UInt32;                // pointer to next symbol
  end;


  PTHUNKSYM = ^THUNKSYM;
  THUNKSYM = packed record
    reclen:  UInt16;                // Record length
    rectyp:  UInt16;                // S_THUNK
    pParent: UInt32;                // pointer to the parent
    pEnd:    UInt32;                // pointer to this blocks end
    pNext:   UInt32;                // pointer to next symbol
  end;

  PBLOCKSYM = ^BLOCKSYM;
  BLOCKSYM = packed record
    reclen:  UInt16;                // Record length
    rectyp:  UInt16;                // S_BLOCK16
    pParent: UInt32;                // pointer to the parent
    pEnd:    UInt32;                // pointer to this blocks end
  end;


  PWITHSYM = ^WITHSYM;
  WITHSYM = packed record
    reclen:  UInt16;                // Record length
    rectyp:  UInt16;                // S_WITH16
    pParent: UInt32;                // pointer to the parent
    pEnd:    UInt32;                // pointer to this blocks end
  end;

  FRAMEPROCSYM_FLAGS = packed record
    _props: UInt32;
    function GetfHasAlloca: UInt32; inline;
    function GetfHasSetJmp: UInt32; inline;
    function GetfHasLongJmp: UInt32; inline;
    function GetfHasInlAsm: UInt32; inline;
    function GetfHasEH: UInt32; inline;
    function GetfInlSpec: UInt32; inline;
    function GetfHasSEH: UInt32; inline;
    function GetfNaked: UInt32; inline;
    function GetfSecurityChecks: UInt32; inline;
    function GetfAsyncEH: UInt32; inline;
    function GetfGSNoStackOrdering: UInt32; inline;
    function GetfWasInlined: UInt32; inline;
    function GetfGSCheck: UInt32; inline;
    function GetfSafeBuffers: UInt32; inline;
    function GetencodedLocalBasePointer: UInt32; inline;
    function GetencodedParamBasePointer: UInt32; inline;
    function GetfPogoOn: UInt32; inline;
    function GetfValidCounts: UInt32; inline;
    function GetfOptSpeed: UInt32; inline;
    function GetfGuardCF: UInt32; inline;
    function GetfGuardCFW: UInt32; inline;
    function Getpad: UInt32; inline;
    procedure SetfHasAlloca(Value: UInt32); inline;
    procedure SetfHasSetJmp(Value: UInt32); inline;
    procedure SetfHasLongJmp(Value: UInt32); inline;
    procedure SetfHasInlAsm(Value: UInt32); inline;
    procedure SetfHasEH(Value: UInt32); inline;
    procedure SetfInlSpec(Value: UInt32); inline;
    procedure SetfHasSEH(Value: UInt32); inline;
    procedure SetfNaked(Value: UInt32); inline;
    procedure SetfSecurityChecks(Value: UInt32); inline;
    procedure SetfAsyncEH(Value: UInt32); inline;
    procedure SetfGSNoStackOrdering(Value: UInt32); inline;
    procedure SetfWasInlined(Value: UInt32); inline;
    procedure SetfGSCheck(Value: UInt32); inline;
    procedure SetfSafeBuffers(Value: UInt32); inline;
    procedure SetencodedLocalBasePointer(Value: UInt32); inline;
    procedure SetencodedParamBasePointer(Value: UInt32); inline;
    procedure SetfPogoOn(Value: UInt32); inline;
    procedure SetfValidCounts(Value: UInt32); inline;
    procedure SetfOptSpeed(Value: UInt32); inline;
    procedure SetfGuardCF(Value: UInt32); inline;
    procedure SetfGuardCFW(Value: UInt32); inline;
    procedure Setpad(Value: UInt32); inline;
    property fHasAlloca: UInt32 read GetfHasAlloca write SetfHasAlloca;
    property fHasSetJmp: UInt32 read GetfHasSetJmp write SetfHasSetJmp;
    property fHasLongJmp: UInt32 read GetfHasLongJmp write SetfHasLongJmp;
    property fHasInlAsm: UInt32 read GetfHasInlAsm write SetfHasInlAsm;
    property fHasEH: UInt32 read GetfHasEH write SetfHasEH;
    property fInlSpec: UInt32 read GetfInlSpec write SetfInlSpec;
    property fHasSEH: UInt32 read GetfHasSEH write SetfHasSEH;
    property fNaked: UInt32 read GetfNaked write SetfNaked;
    property fSecurityChecks: UInt32 read GetfSecurityChecks write SetfSecurityChecks;
    property fAsyncEH: UInt32 read GetfAsyncEH write SetfAsyncEH;
    property fGSNoStackOrdering: UInt32 read GetfGSNoStackOrdering write SetfGSNoStackOrdering;
    property fWasInlined: UInt32 read GetfWasInlined write SetfWasInlined;
    property fGSCheck: UInt32 read GetfGSCheck write SetfGSCheck;
    property fSafeBuffers: UInt32 read GetfSafeBuffers write SetfSafeBuffers;
    property encodedLocalBasePointer: UInt32 read GetencodedLocalBasePointer write SetencodedLocalBasePointer;
    property encodedParamBasePointer: UInt32 read GetencodedParamBasePointer write SetencodedParamBasePointer;
    property fPogoOn: UInt32 read GetfPogoOn write SetfPogoOn;
    property fValidCounts: UInt32 read GetfValidCounts write SetfValidCounts;
    property fOptSpeed: UInt32 read GetfOptSpeed write SetfOptSpeed;
    property fGuardCF: UInt32 read GetfGuardCF write SetfGuardCF;
    property fGuardCFW: UInt32 read GetfGuardCFW write SetfGuardCFW;
    property pad: UInt32 read Getpad write Setpad;
//    unsigned long   fHasAlloca  :  1;   // function uses _alloca()
//    unsigned long   fHasSetJmp  :  1;   // function uses setjmp()
//    unsigned long   fHasLongJmp :  1;   // function uses longjmp()
//    unsigned long   fHasInlAsm  :  1;   // function uses inline asm
//    unsigned long   fHasEH      :  1;   // function has EH states
//    unsigned long   fInlSpec    :  1;   // function was speced as inline
//    unsigned long   fHasSEH     :  1;   // function has SEH
//    unsigned long   fNaked      :  1;   // function is __declspec(naked)
//    unsigned long   fSecurityChecks :  1;   // function has buffer security check introduced by /GS.
//    unsigned long   fAsyncEH    :  1;   // function compiled with /EHa
//    unsigned long   fGSNoStackOrdering :  1;   // function has /GS buffer checks, but stack ordering couldn't be done
//    unsigned long   fWasInlined :  1;   // function was inlined within another function
//    unsigned long   fGSCheck    :  1;   // function is __declspec(strict_gs_check)
//    unsigned long   fSafeBuffers : 1;   // function is __declspec(safebuffers)
//    unsigned long   encodedLocalBasePointer : 2;  // record function's local pointer explicitly.
//    unsigned long   encodedParamBasePointer : 2;  // record function's parameter pointer explicitly.
//    unsigned long   fPogoOn      : 1;   // function was compiled with PGO/PGU
//    unsigned long   fValidCounts : 1;   // Do we have valid Pogo counts?
//    unsigned long   fOptSpeed    : 1;  // Did we optimize for speed?
//    unsigned long   fGuardCF    :  1;   // function contains CFG checks (and no write checks)
//    unsigned long   fGuardCFW   :  1;   // function contains CFW checks and/or instrumentation
//    unsigned long   pad          : 9;   // must be zero
  end;

  PFRAMEPROCSYM = ^FRAMEPROCSYM;
  FRAMEPROCSYM = packed record
    reclen:     UInt16;             // Record length
    rectyp:     UInt16;             // S_FRAMEPROC
    cbFrame:    UInt32;             // count of bytes of total frame of procedure
    cbPad:      UInt32;             // count of bytes of padding in the frame
    offPad:     CV_uoff32_t;        // offset (relative to frame poniter) to where
                                    //  padding starts
    cbSaveRegs: UInt32;             // count of bytes of callee save registers
    offExHdlr:  CV_uoff32_t;        // offset of exception handler
    sectExHdlr: UInt16;             // section id of exception handler
    flags:      FRAMEPROCSYM_FLAGS;
  end;

function ExpandEncodedBasePointerReg(machineType, encodedFrameReg: UInt32): UInt16;

type
  PUNAMESPACE = ^UNAMESPACE;
  UNAMESPACE = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_UNAMESPACE
    name:   array [0..0] of UInt8;  // name
  end;

  PSEPCODESYM = ^SEPCODESYM;
  SEPCODESYM = packed record
    reclen:     UInt16;             // Record length
    rectyp:     UInt16;             // S_SEPCODE
    pParent:    UInt32;             // pointer to the parent
    pEnd:       UInt32;             // pointer to this block's end
    length:     UInt32;             // count of bytes of this block
    scf:        CV_SEPCODEFLAGS;    // flags
    off:        CV_uoff32_t;        // sect:off of the separated code
    offParent:  CV_uoff32_t;        // sectParent:offParent of the enclosing scope
    sect:       UInt16;             //  (proc, block, or sepcode)
    sectParent: UInt16;
  end;

  PBUILDINFOSYM = ^BUILDINFOSYM;
  BUILDINFOSYM = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_BUILDINFO
    id:     CV_ItemId;              // CV_ItemId of Build Info.
  end;

  PINLINESITESYM = ^INLINESITESYM;
  INLINESITESYM = packed record
    reclen:            UInt16;      // Record length
    rectyp:            UInt16;      // S_INLINESITE
    pParent:           UInt32;      // pointer to the inliner
    pEnd:              UInt32;      // pointer to this block's end
    inlinee:           CV_ItemId;   // CV_ItemId of inlinee
    binaryAnnotations: array [0..0] of UInt8; // an array of compressed binary annotations.
  end;

  PINLINESITESYM2 = ^INLINESITESYM2;
  INLINESITESYM2 = packed record
    reclen:            UInt16;      // Record length
    rectyp:            UInt16;      // S_INLINESITE2
    pParent:           UInt32;      // pointer to the inliner
    pEnd:              UInt32;      // pointer to this block's end
    inlinee:           CV_ItemId;   // CV_ItemId of inlinee
    invocations:       UInt32;      // entry count
    binaryAnnotations: array [0..0] of UInt8; // an array of compressed binary annotations.
  end;


// Defines a locals and it is live range, how to evaluate.
// S_DEFRANGE modifies previous local S_LOCAL, it has to consecutive.

  PLOCALSYM = ^LOCALSYM;
  LOCALSYM = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_LOCAL
    typind: CV_typ_t;               // type index
    flags:  CV_LVARFLAGS;           // local var flags

    name:   array [0..0] of UInt8;  // Name of this symbol, a null terminated array of UTF8 characters.
  end;

  PFILESTATICSYM = ^FILESTATICSYM;
  FILESTATICSYM = packed record
    reclen:    UInt16;              // Record length
    rectyp:    UInt16;              // S_FILESTATIC
    typind:    CV_typ_t;            // type index
    modOffset: CV_uoff32_t;         // index of mod filename in stringtable
    flags:     CV_LVARFLAGS;        // local var flags

    name:      array [0..0] of UInt8; // Name of this symbol, a null terminated array of UTF8 characters
  end;

  PDEFRANGESYM = ^DEFRANGESYM;
  DEFRANGESYM = packed record       // A live range of sub field of variable
    reclen:   UInt16;               // Record length
    rectyp:   UInt16;               // S_DEFRANGE

    &program: CV_uoff32_t;          // DIA program to evaluate the value of the symbol

    range:    CV_LVAR_ADDR_RANGE;   // Range of addresses where this program is valid
    gaps:     array [0..0] of CV_LVAR_ADDR_GAP; // The value is not available in following gaps.
  end;

  PDEFRANGESYMSUBFIELD = ^DEFRANGESYMSUBFIELD;
  DEFRANGESYMSUBFIELD = packed record // A live range of sub field of variable. like locala.i
    reclen:    UInt16;              // Record length
    rectyp:    UInt16;              // S_DEFRANGE_SUBFIELD

    &program:  CV_uoff32_t;         // DIA program to evaluate the value of the symbol

    offParent: CV_uoff32_t;         // Offset in parent variable.

    range:     CV_LVAR_ADDR_RANGE ; // Range of addresses where this program is valid
    gaps:      array [0..0] of CV_LVAR_ADDR_GAP;  // The value is not available in following gaps.
  end;

  CV_RANGEATTR = packed record
    _props: UInt16;
    function Getmaybe: UInt16; inline;
    function Getpadding: UInt16; inline;
    procedure Setmaybe(Value: UInt16); inline;
    procedure Setpadding(Value: UInt16); inline;
    property maybe: UInt16 read Getmaybe write Setmaybe;
    property padding: UInt16 read Getpadding write Setpadding;
//    unsigned short  maybe : 1;    // May have no user name on one of control flow path.
//    unsigned short  padding : 15; // Padding for future use.
  end;

  PDEFRANGESYMREGISTER = ^DEFRANGESYMREGISTER;
  DEFRANGESYMREGISTER = packed record // A live range of en-registed variable
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_DEFRANGE_REGISTER
    reg:    UInt16;                 // Register to hold the value of the symbol
    attr:   CV_RANGEATTR;           // Attribute of the register range.
    range:  CV_LVAR_ADDR_RANGE;     // Range of addresses where this program is valid
    gaps:   array [0..0] of CV_LVAR_ADDR_GAP; // The value is not available in following gaps.
  end;

  PDEFRANGESYMFRAMEPOINTERREL = ^DEFRANGESYMFRAMEPOINTERREL;
  DEFRANGESYMFRAMEPOINTERREL = packed record  // A live range of frame variable
    reclen:          UInt16;        // Record length
    rectyp:          UInt16;        // S_DEFRANGE_FRAMEPOINTER_REL

    offFramePointer: CV_off32_t;    // offset to frame pointer

    range:           CV_LVAR_ADDR_RANGE;  // Range of addresses where this program is valid
    gaps:            array [0..0] of CV_LVAR_ADDR_GAP;  // The value is not available in following gaps.
  end;

  PDEFRANGESYMFRAMEPOINTERREL_FULL_SCOPE = ^DEFRANGESYMFRAMEPOINTERREL_FULL_SCOPE;
  DEFRANGESYMFRAMEPOINTERREL_FULL_SCOPE = packed record // A frame variable valid in all function scope
    reclen:          UInt16;        // Record length
    rectyp:          UInt16;        // S_DEFRANGE_FRAMEPOINTER_REL

    offFramePointer: CV_off32_t;    // offset to frame pointer
  end;

const
  CV_OFFSET_PARENT_LENGTH_LIMIT = 12;

type
// Note DEFRANGESYMREGISTERREL and DEFRANGESYMSUBFIELDREGISTER had same layout.
  PDEFRANGESYMSUBFIELDREGISTER = ^DEFRANGESYMSUBFIELDREGISTER;
  DEFRANGESYMSUBFIELDREGISTER = packed record // A live range of sub field of variable. like locala.i
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_DEFRANGE_SUBFIELD_REGISTER

    reg:    UInt16;                 // Register to hold the value of the symbol
    attr:   CV_RANGEATTR;           // Attribute of the register range.
    _props: CV_uoff32_t;
    range:  CV_LVAR_ADDR_RANGE;     // Range of addresses where this program is valid
    gaps:   array [0..0] of CV_LVAR_ADDR_GAP; // The value is not available in following gaps.

    function GetoffParent: CV_uoff32_t; inline;
    function Getpadding: CV_uoff32_t; inline;
    procedure SetoffParent(Value: CV_uoff32_t); inline;
    procedure Setpadding(Value: CV_uoff32_t); inline;
    property offParent: CV_uoff32_t read GetoffParent write SetoffParent;
    property padding: CV_uoff32_t read Getpadding write Setpadding;
//    CV_uoff32_t        offParent : CV_OFFSET_PARENT_LENGTH_LIMIT;  // Offset in parent variable.
//    CV_uoff32_t        padding   : 20;  // Padding for future use.
  end;

// Note DEFRANGESYMREGISTERREL and DEFRANGESYMSUBFIELDREGISTER had same layout.
// Used when /GS Copy parameter as local variable or other variable don't cover by FRAMERELATIVE.
  PDEFRANGESYMREGISTERREL = ^DEFRANGESYMREGISTERREL;
  DEFRANGESYMREGISTERREL = packed record  // A live range of variable related to a register.
    reclen:         UInt16;         // Record length
    rectyp:         UInt16;         // S_DEFRANGE_REGISTER_REL

    baseReg:        UInt16;         // Register to hold the base pointer of the symbol
    _props:         UInt16;
    offBasePointer: CV_off32_t;     // offset to register

    range:          CV_LVAR_ADDR_RANGE; // Range of addresses where this program is valid
    gaps:           array [0..0] of CV_LVAR_ADDR_GAP; // The value is not available in following gaps.

    function GetspilledUdtMember: UInt16; inline;
    function Getpadding: UInt16; inline;
    function GetoffsetParent: UInt16; inline;
    procedure SetspilledUdtMember(Value: UInt16); inline;
    procedure Setpadding(Value: UInt16); inline;
    procedure SetoffsetParent(Value: UInt16); inline;
    property spilledUdtMember: UInt16 read GetspilledUdtMember write SetspilledUdtMember;
    property padding: UInt16 read Getpadding write Setpadding;
    property offsetParent: UInt16 read GetoffsetParent write SetoffsetParent;
//    unsigned short  spilledUdtMember : 1;   // Spilled member for s.i.
//    unsigned short  padding          : 3;   // Padding for future use.
//    unsigned short  offsetParent     : CV_OFFSET_PARENT_LENGTH_LIMIT;  // Offset in parent variable.
  end;

  PDEFRANGESYMHLSL = ^DEFRANGESYMHLSL;
  DEFRANGESYMHLSL = packed record   // A live range of variable related to a symbol in HLSL code.
    reclen:       UInt16;           // Record length
    rectyp:       UInt16;           // S_DEFRANGE_HLSL or S_DEFRANGE_DPC_PTR_TAG

    regType:      UInt16;           // register type from CV_HLSLREG_e

    _props:       UInt16;

    offsetParent: UInt16;           // Offset in parent variable.
    sizeInParent: UInt16;           // Size of enregistered portion

    range:        CV_LVAR_ADDR_RANGE; // Range of addresses where this program is valid
    data:         array [0..0] of UInt8;  // variable length data specifying gaps where the value is not available
                                    // followed by multi-dimensional offset of variable location in register
                                    // space (see CV_DEFRANGESYMHLSL_* macros below)

    function GetregIndices: UInt16; inline;
    function GetspilledUdtMember: UInt16; inline;
    function GetmemorySpace: UInt16; inline;
    function Getpadding: UInt16; inline;
    procedure SetregIndices(Value: UInt16); inline;
    procedure SetspilledUdtMember(Value: UInt16); inline;
    procedure SetmemorySpace(Value: UInt16); inline;
    procedure Setpadding(Value: UInt16); inline;
    property regIndices: UInt16 read GetregIndices write SetregIndices;
    property spilledUdtMember: UInt16 read GetspilledUdtMember write SetspilledUdtMember;
    property memorySpace: UInt16 read GetmemorySpace write SetmemorySpace;
    property padding: UInt16 read Getpadding write Setpadding;
//    unsigned short  regIndices       : 2;   // 0, 1 or 2, dimensionality of register space
//    unsigned short  spilledUdtMember : 1;   // this is a spilled member
//    unsigned short  memorySpace      : 4;   // memory space
//    unsigned short  padding          : 9;   // for future use
  end;

function CV_DEFRANGESYM_GAPS_COUNT(const x: DEFRANGESYM): Integer; inline;
function CV_DEFRANGESYMSUBFIELD_GAPS_COUNT(const x: DEFRANGESYMSUBFIELD): Integer; inline;
function CV_DEFRANGESYMHLSL_GAPS_COUNT(const x: DEFRANGESYMHLSL): Integer; inline;
//#define CV_DEFRANGESYMHLSL_GAPS_PTR_BASE(x, t)  reinterpret_cast<t>((x)->data)
function CV_DEFRANGESYMHLSL_GAPS_CONST_PTR(const x: DEFRANGESYMHLSL): PCV_LVAR_ADDR_GAP; inline;
function CV_DEFRANGESYMHLSL_GAPS_PTR(const x: DEFRANGESYMHLSL): PCV_LVAR_ADDR_GAP; inline;
//#define CV_DEFRANGESYMHLSL_OFFSET_PTR_BASE(x, t) \
//    reinterpret_cast<t>(((CV_LVAR_ADDR_GAP*)(x)->data) + CV_DEFRANGESYMHLSL_GAPS_COUNT(x))
function CV_DEFRANGESYMHLSL_OFFSET_CONST_PTR(const x: DEFRANGESYMHLSL): PCV_uoff32_t; inline;
function CV_DEFRANGESYMHLSL_OFFSET_PTR(const x: DEFRANGESYMHLSL): PCV_uoff32_t; inline;

{$if defined(CC_DP_CXX)}

// Defines a local DPC group shared variable and its location.
  PLOCALDPCGROUPSHAREDSYM = ^LOCALDPCGROUPSHAREDSYM;
  LOCALDPCGROUPSHAREDSYM = packed record
    reclen:   unsigned short;       // Record length
    rectyp:   unsigned short;       // S_LOCAL_DPC_GROUPSHARED
    typind:   CV_typ_t;             // type index
    flags:    CV_LVARFLAGS;         // local var flags

    dataslot: unsigned short;       // Base data (cbuffer, groupshared, etc.) slot
    dataoff:  unsigned short;       // Base data byte offset start

    name:     array [0..0] of unsigned Int8;  // Name of this symbol, a null terminated array of UTF8 characters.
  end;

  PDPCSYMTAGMAP = ^DPCSYMTAGMAP;
  DPCSYMTAGMAP = packed record      // A map for DPC pointer tag values to symbol records.
    reclen: unsigned short;         // Record length
    rectyp: unsigned short;         // S_DPC_SYM_TAG_MAP

    mapEntries: array [0..0] of CV_DPC_SYM_TAG_MAP_ENTRY; // Array of mappings from DPC pointer tag values to symbol record offsets
  end;

function CV_DPCSYMTAGMAP_COUNT(const x: DPCSYMTAGMAP): Integer; inline;

{$endif CC_DP_CXX}

const
  CV_SWT_INT1         = 0;
  CV_SWT_UINT1        = 1;
  CV_SWT_INT2         = 2;
  CV_SWT_UINT2        = 3;
  CV_SWT_INT4         = 4;
  CV_SWT_UINT4        = 5;
  CV_SWT_POINTER      = 6;
  CV_SWT_UINT1SHL1    = 7;
  CV_SWT_UINT2SHL1    = 8;
  CV_SWT_INT1SHL1     = 9;
  CV_SWT_INT2SHL1     = 10;
  CV_SWT_TBB          = CV_SWT_UINT1SHL1;
  CV_SWT_TBH          = CV_SWT_UINT2SHL1;

type
  PFUNCTIONLIST = ^FUNCTIONLIST;
  FUNCTIONLIST = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_CALLERS or S_CALLEES

    count:  UInt32;                 // Number of functions
    funcs:  array [0..0] of CV_typ_t; // List of functions, dim == count
    // unsigned long   invocations[CV_ZEROLEN]; Followed by a parallel array of
    // invocation counts. Counts > reclen are assumed to be zero
  end;

  PPOGOINFO = ^POGOINFO;
  POGOINFO = packed record
    reclen:      UInt16;            // Record length
    rectyp:      UInt16;            // S_POGODATA

    invocations: UInt32;            // Number of times function was called
    dynCount:    Int64;             // Dynamic instruction count
    numInstrs:   UInt32;            // Static instruction count
    staInstLive: UInt32;            // Final static instruction count (post inlining)
  end;

  PARMSWITCHTABLE = ^ARMSWITCHTABLE;
  ARMSWITCHTABLE = packed record
    reclen:       UInt16;           // Record length
    rectyp:       UInt16;           // S_ARMSWITCHTABLE

    offsetBase:   CV_uoff32_t;      // Section-relative offset to the base for switch offsets
    sectBase:     UInt16;           // Section index of the base for switch offsets
    switchType:   UInt16;           // type of each entry
    offsetBranch: CV_uoff32_t;      // Section-relative offset to the table branch instruction
    offsetTable:  CV_uoff32_t;      // Section-relative offset to the start of the table
    sectBranch:   UInt16;           // Section index of the table branch instruction
    sectTable:    UInt16;           // Section index of the table
    cEntries:     UInt32;           // number of switch table entries
  end;

  PMODTYPEREF = ^MODTYPEREF;
  MODTYPEREF = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_MOD_TYPEREF

    _props: UInt32;

    word0:  UInt16;                 // these two words contain SN or module index depending
    word1:  UInt16;                 // on above flags
    function GetfNone: UInt32; inline;
    function GetfRefTMPCT: UInt32; inline;
    function GetfOwnTMPCT: UInt32; inline;
    function GetfOwnTMR: UInt32; inline;
    function GetfOwnTM: UInt32; inline;
    function GetfRefTM: UInt32; inline;
    function Getreserved: UInt32; inline;
    procedure SetfNone(Value: UInt32); inline; inline; inline;
    procedure SetfRefTMPCT(Value: UInt32); inline;
    procedure SetfOwnTMPCT(Value: UInt32); inline;
    procedure SetfOwnTMR(Value: UInt32); inline;
    procedure SetfOwnTM(Value: UInt32); inline;
    procedure SetfRefTM(Value: UInt32); inline;
    procedure Setreserved(Value: UInt32); inline;
    property fNone: UInt32 read GetfNone write SetfNone;
    property fRefTMPCT: UInt32 read GetfRefTMPCT write SetfRefTMPCT;
    property fOwnTMPCT: UInt32 read GetfOwnTMPCT write SetfOwnTMPCT;
    property fOwnTMR: UInt32 read GetfOwnTMR write SetfOwnTMR;
    property fOwnTM: UInt32 read GetfOwnTM write SetfOwnTM;
    property fRefTM: UInt32 read GetfRefTM write SetfRefTM;
    property reserved: UInt32 read Getreserved write Setreserved;
//    unsigned long   fNone     : 1;      // module doesn't reference any type
//    unsigned long   fRefTMPCT : 1;      // reference /Z7 PCH types
//    unsigned long   fOwnTMPCT : 1;      // module contains /Z7 PCH types
//    unsigned long   fOwnTMR   : 1;      // module contains type info (/Z7)
//    unsigned long   fOwnTM    : 1;      // module contains type info (/Zi or /ZI)
//    unsigned long   fRefTM    : 1;      // module references type info owned by other module
//    unsigned long   reserved  : 9;
  end;

  PSECTIONSYM = ^SECTIONSYM;
  SECTIONSYM = packed record
    reclen:          UInt16;        // Record length
    rectyp:          UInt16;        // S_SECTION

    isec:            UInt16;        // Section number
    align:           UInt8;         // Alignment of this section (power of 2)
    bReserved:       UInt8;         // Reserved.  Must be zero.
    rva:             UInt32;
    cb:              UInt32;
    characteristics: UInt32;
    name:            array [0..0] of UInt8; // name
  end;

  PCOFFGROUPSYM = ^COFFGROUPSYM;
  COFFGROUPSYM = packed record
    reclen:          UInt16;        // Record length
    rectyp:          UInt16;        // S_COFFGROUP

    cb:              UInt32;
    characteristics: UInt32;
    off:             CV_uoff32_t;   // Symbol offset
    seg:             UInt16;        // Symbol segment
    name:            array [0..0] of UInt8; // name
  end;

  EXPORTSYM = packed record
    reclen:  UInt16;                // Record length
    rectyp:  UInt16;                // S_EXPORT

    ordinal: UInt16;
    _props:  UInt16;
    name:    array [0..0] of UInt8; // name of
    function GetfConstant: UInt16; inline;
    function GetfData: UInt16; inline;
    function GetfPrivate: UInt16; inline;
    function GetfNoName: UInt16; inline;
    function GetfOrdinal: UInt16; inline;
    function GetfForwarder: UInt16; inline;
    function Getreserved: UInt16; inline;
    procedure SetfConstant(Value: UInt16); inline;
    procedure SetfData(Value: UInt16); inline;
    procedure SetfPrivate(Value: UInt16); inline;
    procedure SetfNoName(Value: UInt16); inline;
    procedure SetfOrdinal(Value: UInt16); inline;
    procedure SetfForwarder(Value: UInt16); inline;
    procedure Setreserved(Value: UInt16); inline;
    property fConstant: UInt16 read GetfConstant write SetfConstant;
    property fData: UInt16 read GetfData write SetfData;
    property fPrivate: UInt16 read GetfPrivate write SetfPrivate;
    property fNoName: UInt16 read GetfNoName write SetfNoName;
    property fOrdinal: UInt16 read GetfOrdinal write SetfOrdinal;
    property fForwarder: UInt16 read GetfForwarder write SetfForwarder;
    property reserved: UInt16 read Getreserved write Setreserved;
//    unsigned short  fConstant : 1;      // CONSTANT
//    unsigned short  fData : 1;          // DATA
//    unsigned short  fPrivate : 1;       // PRIVATE
//    unsigned short  fNoName : 1;        // NONAME
//    unsigned short  fOrdinal : 1;       // Ordinal was explicitly assigned
//    unsigned short  fForwarder : 1;     // This is a forwarder
//    unsigned short  reserved : 10;      // Reserved. Must be zero.
  end;

//
// Symbol for describing indirect calls when they are using
// a function pointer cast on some other type or temporary.
// Typical content will be an LF_POINTER to an LF_PROCEDURE
// type record that should mimic an actual variable with the
// function pointer type in question.
//
// Since the compiler can sometimes tail-merge a function call
// through a function pointer, there may be more than one
// S_CALLSITEINFO record at an address.  This is similar to what
// you could do in your own code by:
//
//  if (expr)
//      pfn = &function1;
//  else
//      pfn = &function2;
//
//  (*pfn)(arg list);
//

  PCALLSITEINFO = ^CALLSITEINFO;
  CALLSITEINFO = packed record
    reclen:       UInt16;           // Record length
    rectyp:       UInt16;           // S_CALLSITEINFO
    off:          CV_off32_t;       // offset of call site
    sect:         UInt16;           // section index of call site
    __reserved_0: UInt16;           // alignment padding field, must be zero
    typind:       CV_typ_t;         // type index describing function signature
  end;

  PHEAPALLOCSITE = ^HEAPALLOCSITE;
  HEAPALLOCSITE = packed record
    reclen:  UInt16;                // Record length
    rectyp:  UInt16;                // S_HEAPALLOCSITE
    off:     CV_off32_t;            // offset of call site
    sect:    UInt16;                // section index of call site
    cbInstr: UInt16;                // length of heap allocation call instruction
    typind:  CV_typ_t;              // type index describing function signature
  end;

// Frame cookie information

{$MINENUMSIZE 4}
  CV_cookietype_e =
  (
    CV_COOKIETYPE_COPY = 0,
    CV_COOKIETYPE_XOR_SP,
    CV_COOKIETYPE_XOR_BP,
    CV_COOKIETYPE_XOR_R13
  );
{$MINENUMSIZE 1}

// Symbol for describing security cookie's position and type
// (raw, xor'd with esp, xor'd with ebp).

type
  PFRAMECOOKIE = ^FRAMECOOKIE;
  FRAMECOOKIE = packed record
    reclen:     UInt16;             // Record length
    rectyp:     UInt16;             // S_FRAMECOOKIE
    off:        CV_off32_t;         // Frame relative offset
    reg:        UInt16;             // Register index
    cookietype: CV_cookietype_e;    // Type of the cookie
    flags:      UInt8;              // Flags describing this cookie
  end;

const
  CV_DISCARDED_UNKNOWN = 0;
  CV_DISCARDED_NOT_SELECTED = 1;
  CV_DISCARDED_NOT_REFERENCED = 2;

type
  DISCARDEDSYM = packed record
    reclen:  UInt16;                // Record length
    rectyp:  UInt16;                // S_DISCARDED
    _props:  UInt32;
    fileid:  UInt32;                // First FILEID if line number info present
    linenum: UInt32;                // First line number
    data:    array [0..0] of Int8;  // Original record(s) with invalid type indices
    function Getdiscarded: UInt32; inline;
    function Getreserved: UInt32; inline;
    procedure Setdiscarded(Value: UInt32); inline;
    procedure Setreserved(Value: UInt32); inline;
    property discarded: UInt32 read Getdiscarded write Setdiscarded;
    property reserved: UInt32 read Getreserved write Setreserved;
//    unsigned long   discarded : 8;      // CV_DISCARDED_e
//    unsigned long   reserved : 24;      // Unused
  end;

  REFMINIPDB_COFFTYPE = packed record
  case Integer of
    0: (isectCoff: UInt32);         // coff section
    1: (typind: CV_typ_t);          // type index
  end;

  PREFMINIPDB = ^REFMINIPDB;
  REFMINIPDB = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_REF_MINIPDB
    u:      REFMINIPDB_COFFTYPE;
    imod:   UInt16;                 // mod index
    _props: UInt16;
    name:   array [0..0] of UInt8;  // zero terminated name string
    function GetfLocal: UInt16; inline;
    function GetfData: UInt16; inline;
    function GetfUDT: UInt16; inline;
    function GetfLabel: UInt16; inline;
    function GetfConst: UInt16; inline;
    function Getreserved: UInt16; inline;
    procedure SetfLocal(Value: UInt16); inline;
    procedure SetfData(Value: UInt16); inline;
    procedure SetfUDT(Value: UInt16); inline;
    procedure SetfLabel(Value: UInt16); inline;
    procedure SetfConst(Value: UInt16); inline;
    procedure Setreserved(Value: UInt16); inline;
    property fLocal: UInt16 read GetfLocal write SetfLocal;
    property fData: UInt16 read GetfData write SetfData;
    property fUDT: UInt16 read GetfUDT write SetfUDT;
    property fLabel: UInt16 read GetfLabel write SetfLabel;
    property fConst: UInt16 read GetfConst write SetfConst;
    property reserved: UInt16 read Getreserved write Setreserved;
//    unsigned short  fLocal   :  1;      // reference to local (vs. global) func or data
//    unsigned short  fData    :  1;      // reference to data (vs. func)
//    unsigned short  fUDT     :  1;      // reference to UDT
//    unsigned short  fLabel   :  1;      // reference to label
//    unsigned short  fConst   :  1;      // reference to const
//    unsigned short  reserved : 11;      // reserved, must be zero
  end;

  PPDBMAP = ^PDBMAP;
  PDBMAP = packed record
    reclen: UInt16;                 // Record length
    rectyp: UInt16;                 // S_PDBMAP
    name:   array [0..0] of UInt8;  // zero terminated source PDB filename followed by zero
                                    // terminated destination PDB filename, both in wchar_t
  end;

//
// V7 line number data types
//

{$MINENUMSIZE 4}
  DEBUG_S_SUBSECTION_TYPE = (
    DEBUG_S_IGNORE = -2147483648 (* $80000000 *),     // if this bit is set in a subsection type then ignore the subsection contents

    DEBUG_S_SYMBOLS = $f1,
    DEBUG_S_LINES,
    DEBUG_S_STRINGTABLE,
    DEBUG_S_FILECHKSMS,
    DEBUG_S_FRAMEDATA,
    DEBUG_S_INLINEELINES,
    DEBUG_S_CROSSSCOPEIMPORTS,
    DEBUG_S_CROSSSCOPEEXPORTS,

    DEBUG_S_IL_LINES,
    DEBUG_S_FUNC_MDTOKEN_MAP,
    DEBUG_S_TYPE_MDTOKEN_MAP,
    DEBUG_S_MERGED_ASSEMBLYINPUT,

    DEBUG_S_COFF_SYMBOL_RVA
  );
{$MINENUMSIZE 1}

  PCV_DebugSSubsectionHeader_t = ^CV_DebugSSubsectionHeader_t;
  CV_DebugSSubsectionHeader_t = packed record
    &type: DEBUG_S_SUBSECTION_TYPE;
    cbLen: CV_off32_t;
  end;

  PCV_DebugSLinesHeader_t = ^CV_DebugSLinesHeader_t;
  CV_DebugSLinesHeader_t = packed record
    offCon: CV_off32_t;
    segCon: UInt16;
    flags:  UInt16;
    cbCon:  CV_off32_t;
  end;

  CV_DebugSLinesFileBlockHeader_t = packed record
    offFile:    CV_off32_t;
    nLines:     CV_off32_t;
    cbBlock:    CV_off32_t;
    // lines:   array [0..nLines-1] of CV_Line_t;
    // columns: array [0..nColumns-1] of CV_Column_t;
  end;

//
// Line flags (data present)
//
const
  CV_LINES_HAVE_COLUMNS = $0001;

type
  CV_Line_t = record
    offset:     UInt32;             // Offset to start of code bytes for line number
    _props:  UInt32;
    function GetlinenumStart: UInt32; inline;
    function GetdeltaLineEnd: UInt32; inline;
    function GetfStatement: UInt32; inline;
    procedure SetlinenumStart(Value: UInt32); inline;
    procedure SetdeltaLineEnd(Value: UInt32); inline;
    procedure SetfStatement(Value: UInt32); inline;
    property linenumStart: UInt32 read GetlinenumStart write SetlinenumStart;
    property deltaLineEnd: UInt32 read GetdeltaLineEnd write SetdeltaLineEnd;
    property fStatement: UInt32 read GetfStatement write SetfStatement;
//        unsigned long   linenumStart:24;    // line where statement/expression starts
//        unsigned long   deltaLineEnd:7;     // delta to line where statement ends (optional)
//        unsigned long   fStatement:1;       // true if a statement linenumber, else an expression line num
  end;

  CV_columnpos_t = UInt16;          // byte offset in a source line

  CV_Column_t = record
    offColumnStart: CV_columnpos_t;
    offColumnEnd:   CV_columnpos_t;
  end;

  PFRAMEDATA = ^FRAMEDATA;
  FRAMEDATA = packed record
    ulRvaStart:  UInt32;
    cbBlock:     UInt32;
    cbLocals:    UInt32;
    cbParams:    UInt32;
    cbStkMax:    UInt32;
    frameFunc:   UInt32;
    cbProlog:    UInt16;
    cbSavedRegs: UInt16;
    _props:      UInt32;
    function GetfHasSEH: UInt32; inline;
    function GetfHasEH: UInt32; inline;
    function GetfIsFunctionStart: UInt32; inline;
    function Getreserved: UInt32; inline;
    procedure SetfHasSEH(Value: UInt32); inline;
    procedure SetfHasEH(Value: UInt32); inline;
    procedure SetfIsFunctionStart(Value: UInt32); inline;
    procedure Setreserved(Value: UInt32); inline;
    property fHasSEH: UInt32 read GetfHasSEH write SetfHasSEH;
    property fHasEH: UInt32 read GetfHasEH write SetfHasEH;
    property fIsFunctionStart: UInt32 read GetfIsFunctionStart write SetfIsFunctionStart;
    property reserved: UInt32 read Getreserved write Setreserved;
//    unsigned long   fHasSEH:1;
//    unsigned long   fHasEH:1;
//    unsigned long   fIsFunctionStart:1;
//    unsigned long   reserved:29;
  end;

  XFIXUP_DATA = packed record
    wType: UInt16;
    wExtra: UInt16;
    rva: UInt32;
    rvaTarget: UInt32;
  end;

// Those cross scope IDs are private convention,
// it used to delay the ID merging for frontend and backend even linker.
// It is transparent for DIA client.
// Use those ID will let DIA run a litter slower and but
// avoid the copy type tree in some scenarios.

  PComboID = ^ComboID;
  ComboID = packed record
  public const
    IndexBitWidth: UInt32 = 20;
    ImodBitWidth: UInt32 = 12;
  public
    constructor Create(imod: UInt16; index: UInt32); overload;
    constructor Create(comboID: UInt32); overload;
    class operator Implicit(const Value: ComboID): UInt32;
    function GetModIndex: UInt16;
    function GetIndex: UInt32;
  private
    m_comboID: UInt32;
  end;


  PCrossScopeId = ^CrossScopeId;
  CrossScopeId = packed record
  const
    LocalIdBitWidth = 20;
    IdScopeBitWidth = 11;
  const
//    StartCrossScopeId = 1 shl (LocalIdBitWidth + IdScopeBitWidth);
    StartCrossScopeId = $80000000;
//    LocalIdMask = (1 shl LocalIdBitWidth) - 1;
    LocalIdMask = $000FFFFF;
//    ScopeIdMask = StartCrossScopeId - (1 shl LocalIdBitWidth);
    ScopeIdMask = $7FF00000;

    // Compilation unit at most reference 1M constructed type.
//    MaxLocalId = (1 shl LocalIdBitWidth) - 1;
    MaxLocalId = $000FFFFF;

    // Compilation unit at most reference to another 2K compilation units.
//    MaxScopeId = (1 shl IdScopeBitWidth) - 1;
    MaxScopeId = $000007FF;

    constructor Create(aIdScopeId: UInt16; aLocalId: UInt32);
    class operator Implicit(const Value: CrossScopeId): UInt32;
    function GetLocalId: UInt32;
    function GetIdScopeId: UInt32;
    class function IsCrossScopeId(i: UInt32): Boolean; static;
    class function Decode(i: UInt32): CrossScopeId; static;
  private
    crossScopeId: UInt32;
  end;

// Combined encoding of TI or FuncId, In compiler implementation
// Id prefixed by 1 if it is function ID.

  PDecoratedItemId = ^DecoratedItemId;
  DecoratedItemId = packed record
    constructor Create(isFuncId: Boolean; inputId: CV_ItemId); overload;
    constructor Create(encodedId: CV_ItemId); overload;
    class operator Implicit(const Value: DecoratedItemId): UInt32;
    function IsFuncId: Boolean;
    function GetItemId: CV_ItemId;
  private
    decoratedItemId: UInt32;
  end;

// Compilation Unit object file path include library name
// Or compile time PDB full path

  PPdbIdScope = ^PdbIdScope;
  PdbIdScope = packed record
    offObjectFilePath: CV_off32_t;
  end;

// An array of all imports by import module.
// List all cross reference for a specific ID scope.
// Format of DEBUG_S_CROSSSCOPEIMPORTS subsection is
  PCrossScopeReferences = ^CrossScopeReferences;
  CrossScopeReferences = packed record
    externalScope:          PdbIdScope;   // Module of definition Scope.
    countOfCrossReferences: UInt32;       // Count of following array.
    referenceIds:           array [0..0] of CV_ItemId;  // CV_ItemId in another compilation unit.
  end;

// An array of all exports in this module.
// Format of DEBUG_S_CROSSSCOPEEXPORTS subsection is
  PLocalIdAndGlobalIdPair = ^LocalIdAndGlobalIdPair;
  LocalIdAndGlobalIdPair = packed record
    localId:  CV_ItemId;    // local id inside the compile time PDB scope. 0 based
    globalId: CV_ItemId;    // global id inside the link time PDB scope, if scope are different.
  end;

// Format of DEBUG_S_INLINEELINEINFO subsection
// List start source file information for an inlined function.

const
  CV_INLINEE_SOURCE_LINE_SIGNATURE    = $0;
  CV_INLINEE_SOURCE_LINE_SIGNATURE_EX = $1;

type
  PInlineeSourceLine = ^InlineeSourceLine;
  InlineeSourceLine = packed record
    inlinee:       CV_ItemId;       // function id.
    fileId:        CV_off32_t;      // offset into file table DEBUG_S_FILECHKSMS
    sourceLineNum: CV_off32_t;      // definition start line number.
  end;

  PInlineeSourceLineEx = ^InlineeSourceLineEx;
  InlineeSourceLineEx = packed record
    inlinee:           CV_ItemId;   // function id
    fileId:            CV_off32_t;  // offset into file table DEBUG_S_FILECHKSMS
    sourceLineNum:     CV_off32_t;  // definition start line number
    countOfExtraFiles: UInt32;
    extraFileId:       array [0..0] of CV_off32_t;
  end;

// BinaryAnnotations ::= BinaryAnnotationInstruction+
// BinaryAnnotationInstruction ::= BinaryAnnotationOpcode Operand+
//
// The binary annotation mechanism supports recording a list of annotations
// in an instruction stream.  The X64 unwind code and the DWARF standard have
// similar design.
//
// One annotation contains opcode and a number of 32bits operands.
//
// The initial set of annotation instructions are for line number table
// encoding only.  These annotations append to S_INLINESITE record, and
// operands are unsigned except for BA_OP_ChangeLineOffset.

{$MINENUMSIZE 4}
  BinaryAnnotationOpcode = (
    BA_OP_Invalid,               // link time pdb contains PADDINGs
    BA_OP_CodeOffset,            // param : start offset
    BA_OP_ChangeCodeOffsetBase,  // param : nth separated code chunk (main code chunk == 0)
    BA_OP_ChangeCodeOffset,      // param : delta of offset
    BA_OP_ChangeCodeLength,      // param : length of code, default next start
    BA_OP_ChangeFile,            // param : fileId
    BA_OP_ChangeLineOffset,      // param : line offset (signed)
    BA_OP_ChangeLineEndDelta,    // param : how many lines, default 1
    BA_OP_ChangeRangeKind,       // param : either 1 (default, for statement)
                                 //         or 0 (for expression)

    BA_OP_ChangeColumnStart,     // param : start column number, 0 means no column info
    BA_OP_ChangeColumnEndDelta,  // param : end column number delta (signed)

    // Combo opcodes for smaller encoding size.

    BA_OP_ChangeCodeOffsetAndLineOffset,  // param : ((sourceDelta << 4) | CodeDelta)
    BA_OP_ChangeCodeLengthAndCodeOffset,  // param : codeLength, codeOffset

    BA_OP_ChangeColumnEnd        // param : end column number
  );
{$MINENUMSIZE 1}

function BinaryAnnotationInstructionOperandCount(op: BinaryAnnotationOpcode): Integer; inline;

///////////////////////////////////////////////////////////////////////////////
//
// This routine a simplified variant from cor.h.
//
// Compress an unsigned integer (iLen) and store the result into pDataOut.
//
// Return value is the number of bytes that the compressed data occupies.  It
// is caller's responsibilityt to ensure *pDataOut has at least 4 bytes to be
// written to.
//
// Note that this function returns -1 if iLen is too big to be compressed.
// We currently can only encode numbers no larger than 0x1FFFFFFF.
//
///////////////////////////////////////////////////////////////////////////////

type
  CompressedAnnotation = UInt8;
  PCompressedAnnotation = ^CompressedAnnotation;

function CVCompressData(
    iLen:     UInt32;         // [IN]  given uncompressed data
    pDataOut: Pointer):       // [OUT] buffer for the compressed data
    UInt32; inline;

///////////////////////////////////////////////////////////////////////////////
//
// Uncompress the data in pData and store the result into pDataOut.
//
// Return value is the uncompressed unsigned integer.  pData is incremented to
// point to the next piece of uncompressed data.
//
// Returns -1 if what is passed in is incorrectly compressed data, such as
// (*pBytes & 0xE0) == 0xE0.
//
///////////////////////////////////////////////////////////////////////////////

function CVUncompressData(
    var pData: PCompressedAnnotation):
    UInt32; inline;           // [IN,OUT] compressed data

// Encode smaller absolute numbers with smaller buffer.
//
// General compression only work for input < 0x1FFFFFFF
// algorithm will not work on 0x80000000

function EncodeSignedInt32(input: Int32): UInt32; inline;

function DecodeSignedInt32(input: UInt32): Int32; inline;

implementation

uses
  CVConst;

function CV_MODE(typ: CV_typ_t): CV_typ_t; inline;
begin
  Result := (typ and CV_MMASK) shr CV_MSHIFT;
end;

function CV_TYPE(typ: CV_typ_t): CV_typ_t; inline;
begin
  Result := (typ and CV_TMASK) shr CV_TSHIFT;
end;

function CV_SUBT(typ: CV_typ_t): CV_typ_t; inline;
begin
  Result := (typ and CV_SMASK) shr CV_SSHIFT;
end;

function CV_NEWMODE(typ: CV_typ_t; nm: UInt32): CV_typ_t; inline;
begin
  Result := (typ and (not CV_MMASK)) or (nm shl CV_MSHIFT);
end;

function CV_NEWTYPE(typ: CV_typ_t; nt: UInt32): CV_typ_t; inline;
begin
  Result := (typ and (not CV_TMASK)) or (nt shl CV_TSHIFT);
end;

function CV_NEWSUBT(typ: CV_typ_t; ns: UInt32): CV_typ_t; inline;
begin
  Result := (typ and (not CV_SMASK)) or (ns shl CV_SSHIFT);
end;

function CV_TYP_IS_DIRECT(typ: CV_typ_t): Boolean; inline;
begin
  Result := CV_MODE(typ) = CV_TM_DIRECT;
end;

function CV_TYP_IS_PTR(typ: CV_typ_t): Boolean; inline;
begin
  Result := CV_MODE(typ) <> CV_TM_DIRECT;
end;

function CV_TYP_IS_NPTR(typ: CV_typ_t): Boolean; inline;
begin
  Result := CV_MODE(typ) = CV_TM_NPTR;
end;

function CV_TYP_IS_FPTR(typ: CV_typ_t): Boolean; inline;
begin
  Result := CV_MODE(typ) = CV_TM_FPTR;
end;

function CV_TYP_IS_HPTR(typ: CV_typ_t): Boolean; inline;
begin
  Result := CV_MODE(typ) = CV_TM_HPTR;
end;

function CV_TYP_IS_NPTR32(typ: CV_typ_t): Boolean; inline;
begin
  Result := CV_MODE(typ) = CV_TM_NPTR32;
end;

function CV_TYP_IS_FPTR32(typ: CV_typ_t): Boolean; inline;
begin
  Result := CV_MODE(typ) = CV_TM_FPTR32;
end;

function CV_TYP_IS_SIGNED(typ: CV_typ_t): Boolean; inline;
begin
  Result := ((CV_TYPE(typ) = CV_SIGNED) and CV_TYP_IS_DIRECT(typ)) or
            (typ = T_INT1)  or
            (typ = T_INT2)  or
            (typ = T_INT4)  or
            (typ = T_INT8)  or
            (typ = T_INT16) or
            (typ = T_RCHAR);
end;

function CV_TYP_IS_UNSIGNED(typ: CV_typ_t): Boolean; inline;
begin
  Result := ((CV_TYPE(typ) = CV_UNSIGNED) and CV_TYP_IS_DIRECT(typ)) or
            (typ = T_UINT1) or
            (typ = T_UINT2) or
            (typ = T_UINT4) or
            (typ = T_UINT8) or
            (typ = T_UINT16);
end;

function CV_TYP_IS_REAL(typ: CV_typ_t): Boolean; inline;
begin
  Result := (CV_TYPE(typ) = CV_REAL) and CV_TYP_IS_DIRECT(typ);
end;

function CV_IS_PRIMITIVE(typ: CV_typ_t): Boolean; inline;
begin
  Result := typ < CV_FIRST_NONPRIM;
end;

function CV_TYP_IS_COMPLEX(typ: CV_typ_t): Boolean; inline;
begin
  Result := (CV_TYPE(typ) = CV_COMPLEX) and CV_TYP_IS_DIRECT(typ);
end;

function CV_IS_INTERNAL_PTR(typ: CV_typ_t): Boolean; inline;
begin
  Result := CV_IS_PRIMITIVE(typ) and
            (CV_TYPE(typ) = CV_CVRESERVED) and
            CV_TYP_IS_PTR(typ);
end;

function CV_modifier_t.GetMOD_const: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 0)) shr 0;
end;

function CV_modifier_t.GetMOD_volatile: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 1)) shr 1;
end;

function CV_modifier_t.GetMOD_unaligned: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 2)) shr 2;
end;

function CV_modifier_t.GetMOD_unused: UInt16;
begin
  Result := (_props and (((1 shl 13)-1) shl 3)) shr 3;
end;

procedure CV_modifier_t.SetMOD_const(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 0))) or ((Value and ((1 shl 1)-1)) shl 0);
end;

procedure CV_modifier_t.SetMOD_volatile(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 1))) or ((Value and ((1 shl 1)-1)) shl 1);
end;

procedure CV_modifier_t.SetMOD_unaligned(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 2))) or ((Value and ((1 shl 1)-1)) shl 2);
end;

procedure CV_modifier_t.SetMOD_unused(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 13)-1) shl 3))) or ((Value and ((1 shl 13)-1)) shl 3);
end;

function CV_prop_t.Getpacked: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 0)) shr 0;
end;

function CV_prop_t.Getctor: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 1)) shr 1;
end;

function CV_prop_t.Getovlops: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 2)) shr 2;
end;

function CV_prop_t.Getisnested: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 3)) shr 3;
end;

function CV_prop_t.Getcnested: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 4)) shr 4;
end;

function CV_prop_t.Getopassign: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 5)) shr 5;
end;

function CV_prop_t.Getopcast: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 6)) shr 6;
end;

function CV_prop_t.Getfwdref: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 7)) shr 7;
end;

function CV_prop_t.Getscoped: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 8)) shr 8;
end;

function CV_prop_t.Gethasuniquename: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 9)) shr 9;
end;

function CV_prop_t.Getsealed: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 10)) shr 10;
end;

function CV_prop_t.Gethfa: UInt16;
begin
  Result := (_props and (((1 shl 2)-1) shl 11)) shr 11;
end;

function CV_prop_t.Getintrinsic: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 13)) shr 13;
end;

function CV_prop_t.Getmocom: UInt16;
begin
  Result := (_props and (((1 shl 2)-1) shl 14)) shr 14;
end;

procedure CV_prop_t.Setpacked(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 0))) or ((Value and ((1 shl 1)-1)) shl 0);
end;

procedure CV_prop_t.Setctor(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 1))) or ((Value and ((1 shl 1)-1)) shl 1);
end;

procedure CV_prop_t.Setovlops(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 2))) or ((Value and ((1 shl 1)-1)) shl 2);
end;

procedure CV_prop_t.Setisnested(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 3))) or ((Value and ((1 shl 1)-1)) shl 3);
end;

procedure CV_prop_t.Setcnested(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 4))) or ((Value and ((1 shl 1)-1)) shl 4);
end;

procedure CV_prop_t.Setopassign(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 5))) or ((Value and ((1 shl 1)-1)) shl 5);
end;

procedure CV_prop_t.Setopcast(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 6))) or ((Value and ((1 shl 1)-1)) shl 6);
end;

procedure CV_prop_t.Setfwdref(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 7))) or ((Value and ((1 shl 1)-1)) shl 7);
end;

procedure CV_prop_t.Setscoped(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 8))) or ((Value and ((1 shl 1)-1)) shl 8);
end;

procedure CV_prop_t.Sethasuniquename(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 9))) or ((Value and ((1 shl 1)-1)) shl 9);
end;

procedure CV_prop_t.Setsealed(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 10))) or ((Value and ((1 shl 1)-1)) shl 10);
end;

procedure CV_prop_t.Sethfa(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 2)-1) shl 11))) or ((Value and ((1 shl 2)-1)) shl 11);
end;

procedure CV_prop_t.Setintrinsic(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 13))) or ((Value and ((1 shl 1)-1)) shl 13);
end;

procedure CV_prop_t.Setmocom(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 2)-1) shl 14))) or ((Value and ((1 shl 2)-1)) shl 14);
end;

function CV_fldattr_t.Getaccess: UInt16;
begin
  Result := (_props and (((1 shl 2)-1) shl 0)) shr 0;
end;

function CV_fldattr_t.Getmprop: UInt16;
begin
  Result := (_props and (((1 shl 3)-1) shl 2)) shr 2;
end;

function CV_fldattr_t.Getpseudo: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 5)) shr 5;
end;

function CV_fldattr_t.Getnoinherit: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 6)) shr 6;
end;

function CV_fldattr_t.Getnoconstruct: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 7)) shr 7;
end;

function CV_fldattr_t.Getcompgenx: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 8)) shr 8;
end;

function CV_fldattr_t.Getsealed: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 9)) shr 9;
end;

function CV_fldattr_t.Getunused: UInt16;
begin
  Result := (_props and (((1 shl 6)-1) shl 10)) shr 10;
end;

procedure CV_fldattr_t.Setaccess(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 2)-1) shl 0))) or ((Value and ((1 shl 2)-1)) shl 0);
end;

procedure CV_fldattr_t.Setmprop(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 3)-1) shl 2))) or ((Value and ((1 shl 3)-1)) shl 2);
end;

procedure CV_fldattr_t.Setpseudo(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 5))) or ((Value and ((1 shl 1)-1)) shl 5);
end;

procedure CV_fldattr_t.Setnoinherit(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 6))) or ((Value and ((1 shl 1)-1)) shl 6);
end;

procedure CV_fldattr_t.Setnoconstruct(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 7))) or ((Value and ((1 shl 1)-1)) shl 7);
end;

procedure CV_fldattr_t.Setcompgenx(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 8))) or ((Value and ((1 shl 1)-1)) shl 8);
end;

procedure CV_fldattr_t.Setsealed(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 9))) or ((Value and ((1 shl 1)-1)) shl 9);
end;

procedure CV_fldattr_t.Setunused(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 6)-1) shl 10))) or ((Value and ((1 shl 6)-1)) shl 10);
end;

function CV_funcattr_t.Getcxxreturnudt: UInt8;
begin
  Result := (_props and (((1 shl 1)-1) shl 0)) shr 0;
end;

function CV_funcattr_t.Getctor: UInt8;
begin
  Result := (_props and (((1 shl 1)-1) shl 1)) shr 1;
end;

function CV_funcattr_t.Getctorvbase: UInt8;
begin
  Result := (_props and (((1 shl 1)-1) shl 2)) shr 2;
end;

function CV_funcattr_t.Getunused: UInt8;
begin
  Result := (_props and (((1 shl 5)-1) shl 3)) shr 3;
end;

procedure CV_funcattr_t.Setcxxreturnudt(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 0))) or ((Value and ((1 shl 1)-1)) shl 0);
end;

procedure CV_funcattr_t.Setctor(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 1))) or ((Value and ((1 shl 1)-1)) shl 1);
end;

procedure CV_funcattr_t.Setctorvbase(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 2))) or ((Value and ((1 shl 1)-1)) shl 2);
end;

procedure CV_funcattr_t.Setunused(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 5)-1) shl 3))) or ((Value and ((1 shl 5)-1)) shl 3);
end;

function CV_matrixattr_t.Getrow_major: UInt8;
begin
  Result := (_props and (((1 shl 1)-1) shl 0)) shr 0;
end;

function CV_matrixattr_t.Getunused: UInt8;
begin
  Result := (_props and (((1 shl 7)-1) shl 1)) shr 1;
end;

procedure CV_matrixattr_t.Setrow_major(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 0))) or ((Value and ((1 shl 1)-1)) shl 0);
end;

procedure CV_matrixattr_t.Setunused(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 7)-1) shl 1))) or ((Value and ((1 shl 7)-1)) shl 1);
end;

function NextType(pType: PTYPTYPE): PTYPTYPE; inline;
begin
{$POINTERMATH ON}
  Result := PTYPTYPE(PUInt8(pType) + pType.len + SizeOf(pType.len));
{$POINTERMATH OFF}
end;

function lfPointer_16t.lfPointerAttr_16t.Getptrtype: UInt16;
begin
  Result := (_props and (((1 shl 5)-1) shl 0)) shr 0;
end;

function lfPointer_16t.lfPointerAttr_16t.Getptrmode: UInt16;
begin
  Result := (_props and (((1 shl 3)-1) shl 5)) shr 5;
end;

function lfPointer_16t.lfPointerAttr_16t.Getisflat32: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 8)) shr 8;
end;

function lfPointer_16t.lfPointerAttr_16t.Getisvolatile: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 9)) shr 9;
end;

function lfPointer_16t.lfPointerAttr_16t.Getisconst: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 10)) shr 10;
end;

function lfPointer_16t.lfPointerAttr_16t.Getisunaligned: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 11)) shr 11;
end;

function lfPointer_16t.lfPointerAttr_16t.Getunused: UInt16;
begin
  Result := (_props and (((1 shl 4)-1) shl 12)) shr 12;
end;

procedure lfPointer_16t.lfPointerAttr_16t.Setptrtype(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 5)-1) shl 0))) or ((Value and ((1 shl 5)-1)) shl 0);
end;

procedure lfPointer_16t.lfPointerAttr_16t.Setptrmode(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 3)-1) shl 5))) or ((Value and ((1 shl 3)-1)) shl 5);
end;

procedure lfPointer_16t.lfPointerAttr_16t.Setisflat32(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 8))) or ((Value and ((1 shl 1)-1)) shl 8);
end;

procedure lfPointer_16t.lfPointerAttr_16t.Setisvolatile(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 9))) or ((Value and ((1 shl 1)-1)) shl 9);
end;

procedure lfPointer_16t.lfPointerAttr_16t.Setisconst(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 10))) or ((Value and ((1 shl 1)-1)) shl 10);
end;

procedure lfPointer_16t.lfPointerAttr_16t.Setisunaligned(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 11))) or ((Value and ((1 shl 1)-1)) shl 11);
end;

procedure lfPointer_16t.lfPointerAttr_16t.Setunused(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 4)-1) shl 12))) or ((Value and ((1 shl 4)-1)) shl 12);
end;

function lfPointer.lfPointerAttr.Getptrtype: UInt32;
begin
  Result := (_props and (((1 shl 5)-1) shl 0)) shr 0;
end;

function lfPointer.lfPointerAttr.Getptrmode: UInt32;
begin
  Result := (_props and (((1 shl 3)-1) shl 5)) shr 5;
end;

function lfPointer.lfPointerAttr.Getisflat32: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 8)) shr 8;
end;

function lfPointer.lfPointerAttr.Getisvolatile: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 9)) shr 9;
end;

function lfPointer.lfPointerAttr.Getisconst: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 10)) shr 10;
end;

function lfPointer.lfPointerAttr.Getisunaligned: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 11)) shr 11;
end;

function lfPointer.lfPointerAttr.Getisrestrict: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 12)) shr 12;
end;

function lfPointer.lfPointerAttr.Getsize: UInt32;
begin
  Result := (_props and (((1 shl 6)-1) shl 13)) shr 13;
end;

function lfPointer.lfPointerAttr.Getismocom: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 19)) shr 19;
end;

function lfPointer.lfPointerAttr.Getislref: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 20)) shr 20;
end;

function lfPointer.lfPointerAttr.Getisrref: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 21)) shr 21;
end;

function lfPointer.lfPointerAttr.Getunused: UInt32;
begin
  Result := (_props and (((1 shl 10)-1) shl 22)) shr 22;
end;

procedure lfPointer.lfPointerAttr.Setptrtype(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 5)-1) shl 0))) or ((Value and ((1 shl 5)-1)) shl 0);
end;

procedure lfPointer.lfPointerAttr.Setptrmode(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 3)-1) shl 5))) or ((Value and ((1 shl 3)-1)) shl 5);
end;

procedure lfPointer.lfPointerAttr.Setisflat32(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 8))) or ((Value and ((1 shl 1)-1)) shl 8);
end;

procedure lfPointer.lfPointerAttr.Setisvolatile(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 9))) or ((Value and ((1 shl 1)-1)) shl 9);
end;

procedure lfPointer.lfPointerAttr.Setisconst(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 10))) or ((Value and ((1 shl 1)-1)) shl 10);
end;

procedure lfPointer.lfPointerAttr.Setisunaligned(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 11))) or ((Value and ((1 shl 1)-1)) shl 11);
end;

procedure lfPointer.lfPointerAttr.Setisrestrict(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 12))) or ((Value and ((1 shl 1)-1)) shl 12);
end;

procedure lfPointer.lfPointerAttr.Setsize(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 6)-1) shl 13))) or ((Value and ((1 shl 6)-1)) shl 13);
end;

procedure lfPointer.lfPointerAttr.Setismocom(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 19))) or ((Value and ((1 shl 1)-1)) shl 19);
end;

procedure lfPointer.lfPointerAttr.Setislref(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 20))) or ((Value and ((1 shl 1)-1)) shl 20);
end;

procedure lfPointer.lfPointerAttr.Setisrref(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 21))) or ((Value and ((1 shl 1)-1)) shl 21);
end;

procedure lfPointer.lfPointerAttr.Setunused(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 10)-1) shl 22))) or ((Value and ((1 shl 10)-1)) shl 22);
end;

function lfHLSL.Getnumprops: UInt16;
begin
  Result := (_props and (((1 shl 4)-1) shl 0)) shr 0;
end;

function lfHLSL.Getunused: UInt16;
begin
  Result := (_props and (((1 shl 12)-1) shl 4)) shr 4;
end;

procedure lfHLSL.Setnumprops(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 4)-1) shl 0))) or ((Value and ((1 shl 4)-1)) shl 0);
end;

procedure lfHLSL.Setunused(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 12)-1) shl 4))) or ((Value and ((1 shl 12)-1)) shl 4);
end;

function CV_PROCFLAGS.GetCV_PFLAG_NOFPO: UInt8;
begin
  Result := (_props and (((1 shl 1)-1) shl 0)) shr 0;
end;

function CV_PROCFLAGS.GetCV_PFLAG_INT: UInt8;
begin
  Result := (_props and (((1 shl 1)-1) shl 1)) shr 1;
end;

function CV_PROCFLAGS.GetCV_PFLAG_FAR: UInt8;
begin
  Result := (_props and (((1 shl 1)-1) shl 2)) shr 2;
end;

function CV_PROCFLAGS.GetCV_PFLAG_NEVER: UInt8;
begin
  Result := (_props and (((1 shl 1)-1) shl 3)) shr 3;
end;

function CV_PROCFLAGS.GetCV_PFLAG_NOTREACHED: UInt8;
begin
  Result := (_props and (((1 shl 1)-1) shl 4)) shr 4;
end;

function CV_PROCFLAGS.GetCV_PFLAG_CUST_CALL: UInt8;
begin
  Result := (_props and (((1 shl 1)-1) shl 5)) shr 5;
end;

function CV_PROCFLAGS.GetCV_PFLAG_NOINLINE: UInt8;
begin
  Result := (_props and (((1 shl 1)-1) shl 6)) shr 6;
end;

function CV_PROCFLAGS.GetCV_PFLAG_OPTDBGINFO: UInt8;
begin
  Result := (_props and (((1 shl 1)-1) shl 7)) shr 7;
end;

procedure CV_PROCFLAGS.SetCV_PFLAG_NOFPO(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 0))) or ((Value and ((1 shl 1)-1)) shl 0);
end;

procedure CV_PROCFLAGS.SetCV_PFLAG_INT(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 1))) or ((Value and ((1 shl 1)-1)) shl 1);
end;

procedure CV_PROCFLAGS.SetCV_PFLAG_FAR(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 2))) or ((Value and ((1 shl 1)-1)) shl 2);
end;

procedure CV_PROCFLAGS.SetCV_PFLAG_NEVER(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 3))) or ((Value and ((1 shl 1)-1)) shl 3);
end;

procedure CV_PROCFLAGS.SetCV_PFLAG_NOTREACHED(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 4))) or ((Value and ((1 shl 1)-1)) shl 4);
end;

procedure CV_PROCFLAGS.SetCV_PFLAG_CUST_CALL(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 5))) or ((Value and ((1 shl 1)-1)) shl 5);
end;

procedure CV_PROCFLAGS.SetCV_PFLAG_NOINLINE(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 6))) or ((Value and ((1 shl 1)-1)) shl 6);
end;

procedure CV_PROCFLAGS.SetCV_PFLAG_OPTDBGINFO(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 7))) or ((Value and ((1 shl 1)-1)) shl 7);
end;

function CV_LVARFLAGS.GetfIsParam: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 0)) shr 0;
end;

function CV_LVARFLAGS.GetfAddrTaken: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 1)) shr 1;
end;

function CV_LVARFLAGS.GetfCompGenx: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 2)) shr 2;
end;

function CV_LVARFLAGS.GetfIsAggregate: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 3)) shr 3;
end;

function CV_LVARFLAGS.GetfIsAggregated: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 4)) shr 4;
end;

function CV_LVARFLAGS.GetfIsAliased: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 5)) shr 5;
end;

function CV_LVARFLAGS.GetfIsAlias: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 6)) shr 6;
end;

function CV_LVARFLAGS.GetfIsRetValue: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 7)) shr 7;
end;

function CV_LVARFLAGS.GetfIsOptimizedOut: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 8)) shr 8;
end;

function CV_LVARFLAGS.GetfIsEnregGlob: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 9)) shr 9;
end;

function CV_LVARFLAGS.GetfIsEnregStat: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 10)) shr 10;
end;

function CV_LVARFLAGS.Getunused: UInt16;
begin
  Result := (_props and (((1 shl 5)-1) shl 11)) shr 11;
end;

procedure CV_LVARFLAGS.SetfIsParam(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 0))) or ((Value and ((1 shl 1)-1)) shl 0);
end;

procedure CV_LVARFLAGS.SetfAddrTaken(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 1))) or ((Value and ((1 shl 1)-1)) shl 1);
end;

procedure CV_LVARFLAGS.SetfCompGenx(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 2))) or ((Value and ((1 shl 1)-1)) shl 2);
end;

procedure CV_LVARFLAGS.SetfIsAggregate(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 3))) or ((Value and ((1 shl 1)-1)) shl 3);
end;

procedure CV_LVARFLAGS.SetfIsAggregated(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 4))) or ((Value and ((1 shl 1)-1)) shl 4);
end;

procedure CV_LVARFLAGS.SetfIsAliased(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 5))) or ((Value and ((1 shl 1)-1)) shl 5);
end;

procedure CV_LVARFLAGS.SetfIsAlias(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 6))) or ((Value and ((1 shl 1)-1)) shl 6);
end;

procedure CV_LVARFLAGS.SetfIsRetValue(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 7))) or ((Value and ((1 shl 1)-1)) shl 7);
end;

procedure CV_LVARFLAGS.SetfIsOptimizedOut(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 8))) or ((Value and ((1 shl 1)-1)) shl 8);
end;

procedure CV_LVARFLAGS.SetfIsEnregGlob(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 9))) or ((Value and ((1 shl 1)-1)) shl 9);
end;

procedure CV_LVARFLAGS.SetfIsEnregStat(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 10))) or ((Value and ((1 shl 1)-1)) shl 10);
end;

procedure CV_LVARFLAGS.Setunused(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 5)-1) shl 11))) or ((Value and ((1 shl 5)-1)) shl 11);
end;

function CV_GENERIC_FLAG.Getcstyle: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 0)) shr 0;
end;

function CV_GENERIC_FLAG.Getrsclean: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 1)) shr 1;
end;

function CV_GENERIC_FLAG.Getunused: UInt16;
begin
  Result := (_props and (((1 shl 14)-1) shl 2)) shr 2;
end;

procedure CV_GENERIC_FLAG.Setcstyle(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 0))) or ((Value and ((1 shl 1)-1)) shl 0);
end;

procedure CV_GENERIC_FLAG.Setrsclean(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 1))) or ((Value and ((1 shl 1)-1)) shl 1);
end;

procedure CV_GENERIC_FLAG.Setunused(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 14)-1) shl 2))) or ((Value and ((1 shl 14)-1)) shl 2);
end;

function CV_SEPCODEFLAGS.GetfIsLexicalScope: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 0)) shr 0;
end;

function CV_SEPCODEFLAGS.GetfReturnsToParent: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 1)) shr 1;
end;

function CV_SEPCODEFLAGS.Getpad: UInt32;
begin
  Result := (_props and (((1 shl 30)-1) shl 2)) shr 2;
end;

procedure CV_SEPCODEFLAGS.SetfIsLexicalScope(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 0))) or ((Value and ((1 shl 1)-1)) shl 0);
end;

procedure CV_SEPCODEFLAGS.SetfReturnsToParent(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 1))) or ((Value and ((1 shl 1)-1)) shl 1);
end;

procedure CV_SEPCODEFLAGS.Setpad(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 30)-1) shl 2))) or ((Value and ((1 shl 30)-1)) shl 2);
end;

function NextSym(pSym: PSYMTYPE): PSYMTYPE; inline;
begin
{$POINTERMATH ON}
  Result := PSYMTYPE(PUInt8(pSym) + pSym.reclen + SizeOf(pSym.reclen));
{$POINTERMATH OFF}
end;

function CFLAGSYM_FLAGS.Getpcode: UInt8;
begin
  Result := (_props[0] and (((1 shl 1)-1) shl 0)) shr 0;
end;

function CFLAGSYM_FLAGS.Getfloatprec: UInt8;
begin
  Result := (_props[0] and (((1 shl 2)-1) shl 1)) shr 1;
end;

function CFLAGSYM_FLAGS.Getfloatpkg: UInt8;
begin
  Result := (_props[0] and (((1 shl 2)-1) shl 3)) shr 3;
end;

function CFLAGSYM_FLAGS.Getambdata: UInt8;
begin
  Result := (_props[0] and (((1 shl 3)-1) shl 5)) shr 5;
end;

function CFLAGSYM_FLAGS.Getambcode: UInt8;
begin
  Result := (_props[1] and (((1 shl 3)-1) shl 0)) shr 0;
end;

function CFLAGSYM_FLAGS.Getmode32: UInt8;
begin
  Result := (_props[1] and (((1 shl 1)-1) shl 3)) shr 3;
end;

function CFLAGSYM_FLAGS.Getpad: UInt8;
begin
  Result := (_props[1] and (((1 shl 4)-1) shl 4)) shr 4;
end;

procedure CFLAGSYM_FLAGS.Setpcode(Value: UInt8);
begin
  _props[0] := (_props[0] and (not (((1 shl 1)-1) shl 0))) or ((Value and ((1 shl 1)-1)) shl 0);
end;

procedure CFLAGSYM_FLAGS.Setfloatprec(Value: UInt8);
begin
  _props[0] := (_props[0] and (not (((1 shl 2)-1) shl 1))) or ((Value and ((1 shl 2)-1)) shl 1);
end;

procedure CFLAGSYM_FLAGS.Setfloatpkg(Value: UInt8);
begin
  _props[0] := (_props[0] and (not (((1 shl 2)-1) shl 3))) or ((Value and ((1 shl 2)-1)) shl 3);
end;

procedure CFLAGSYM_FLAGS.Setambdata(Value: UInt8);
begin
  _props[0] := (_props[0] and (not (((1 shl 3)-1) shl 5))) or ((Value and ((1 shl 3)-1)) shl 5);
end;

procedure CFLAGSYM_FLAGS.Setambcode(Value: UInt8);
begin
  _props[1] := (_props[1] and (not (((1 shl 3)-1) shl 0))) or ((Value and ((1 shl 3)-1)) shl 0);
end;

procedure CFLAGSYM_FLAGS.Setmode32(Value: UInt8);
begin
  _props[1] := (_props[1] and (not (((1 shl 1)-1) shl 3))) or ((Value and ((1 shl 1)-1)) shl 3);
end;

procedure CFLAGSYM_FLAGS.Setpad(Value: UInt8);
begin
  _props[1] := (_props[1] and (not (((1 shl 4)-1) shl 4))) or ((Value and ((1 shl 4)-1)) shl 4);
end;

function COMPILESYM_FLAGS.GetiLanguage: UInt32;
begin
  Result := (_props and (((1 shl 8)-1) shl 0)) shr 0;
end;

function COMPILESYM_FLAGS.GetfEC: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 8)) shr 8;
end;

function COMPILESYM_FLAGS.GetfNoDbgInfo: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 9)) shr 9;
end;

function COMPILESYM_FLAGS.GetfLTCG: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 10)) shr 10;
end;

function COMPILESYM_FLAGS.GetfNoDataAlign: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 11)) shr 11;
end;

function COMPILESYM_FLAGS.GetfManagedPresent: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 12)) shr 12;
end;

function COMPILESYM_FLAGS.GetfSecurityChecks: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 13)) shr 13;
end;

function COMPILESYM_FLAGS.GetfHotPatch: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 14)) shr 14;
end;

function COMPILESYM_FLAGS.GetfCVTCIL: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 15)) shr 15;
end;

function COMPILESYM_FLAGS.GetfMSILModule: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 16)) shr 16;
end;

function COMPILESYM_FLAGS.Getpad: UInt32;
begin
  Result := (_props and (((1 shl 15)-1) shl 17)) shr 17;
end;

procedure COMPILESYM_FLAGS.SetiLanguage(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 8)-1) shl 0))) or ((Value and ((1 shl 8)-1)) shl 0);
end;

procedure COMPILESYM_FLAGS.SetfEC(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 8))) or ((Value and ((1 shl 1)-1)) shl 8);
end;

procedure COMPILESYM_FLAGS.SetfNoDbgInfo(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 9))) or ((Value and ((1 shl 1)-1)) shl 9);
end;

procedure COMPILESYM_FLAGS.SetfLTCG(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 10))) or ((Value and ((1 shl 1)-1)) shl 10);
end;

procedure COMPILESYM_FLAGS.SetfNoDataAlign(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 11))) or ((Value and ((1 shl 1)-1)) shl 11);
end;

procedure COMPILESYM_FLAGS.SetfManagedPresent(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 12))) or ((Value and ((1 shl 1)-1)) shl 12);
end;

procedure COMPILESYM_FLAGS.SetfSecurityChecks(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 13))) or ((Value and ((1 shl 1)-1)) shl 13);
end;

procedure COMPILESYM_FLAGS.SetfHotPatch(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 14))) or ((Value and ((1 shl 1)-1)) shl 14);
end;

procedure COMPILESYM_FLAGS.SetfCVTCIL(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 15))) or ((Value and ((1 shl 1)-1)) shl 15);
end;

procedure COMPILESYM_FLAGS.SetfMSILModule(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 16))) or ((Value and ((1 shl 1)-1)) shl 16);
end;

procedure COMPILESYM_FLAGS.Setpad(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 15)-1) shl 17))) or ((Value and ((1 shl 15)-1)) shl 17);
end;

function COMPILESYM3_FLAGS.GetiLanguage: UInt32;
begin
  Result := (_props and (((1 shl 8)-1) shl 0)) shr 0;
end;

function COMPILESYM3_FLAGS.GetfEC: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 8)) shr 8;
end;

function COMPILESYM3_FLAGS.GetfNoDbgInfo: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 9)) shr 9;
end;

function COMPILESYM3_FLAGS.GetfLTCG: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 10)) shr 10;
end;

function COMPILESYM3_FLAGS.GetfNoDataAlign: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 11)) shr 11;
end;

function COMPILESYM3_FLAGS.GetfManagedPresent: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 12)) shr 12;
end;

function COMPILESYM3_FLAGS.GetfSecurityChecks: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 13)) shr 13;
end;

function COMPILESYM3_FLAGS.GetfHotPatch: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 14)) shr 14;
end;

function COMPILESYM3_FLAGS.GetfCVTCIL: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 15)) shr 15;
end;

function COMPILESYM3_FLAGS.GetfMSILModule: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 16)) shr 16;
end;

function COMPILESYM3_FLAGS.GetfSdl: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 17)) shr 17;
end;

function COMPILESYM3_FLAGS.GetfPGO: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 18)) shr 18;
end;

function COMPILESYM3_FLAGS.GetfExp: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 19)) shr 19;
end;

function COMPILESYM3_FLAGS.Getpad: UInt32;
begin
  Result := (_props and (((1 shl 12)-1) shl 20)) shr 20;
end;

procedure COMPILESYM3_FLAGS.SetiLanguage(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 8)-1) shl 0))) or ((Value and ((1 shl 8)-1)) shl 0);
end;

procedure COMPILESYM3_FLAGS.SetfEC(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 8))) or ((Value and ((1 shl 1)-1)) shl 8);
end;

procedure COMPILESYM3_FLAGS.SetfNoDbgInfo(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 9))) or ((Value and ((1 shl 1)-1)) shl 9);
end;

procedure COMPILESYM3_FLAGS.SetfLTCG(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 10))) or ((Value and ((1 shl 1)-1)) shl 10);
end;

procedure COMPILESYM3_FLAGS.SetfNoDataAlign(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 11))) or ((Value and ((1 shl 1)-1)) shl 11);
end;

procedure COMPILESYM3_FLAGS.SetfManagedPresent(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 12))) or ((Value and ((1 shl 1)-1)) shl 12);
end;

procedure COMPILESYM3_FLAGS.SetfSecurityChecks(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 13))) or ((Value and ((1 shl 1)-1)) shl 13);
end;

procedure COMPILESYM3_FLAGS.SetfHotPatch(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 14))) or ((Value and ((1 shl 1)-1)) shl 14);
end;

procedure COMPILESYM3_FLAGS.SetfCVTCIL(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 15))) or ((Value and ((1 shl 1)-1)) shl 15);
end;

procedure COMPILESYM3_FLAGS.SetfMSILModule(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 16))) or ((Value and ((1 shl 1)-1)) shl 16);
end;

procedure COMPILESYM3_FLAGS.SetfSdl(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 17))) or ((Value and ((1 shl 1)-1)) shl 17);
end;

procedure COMPILESYM3_FLAGS.SetfPGO(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 18))) or ((Value and ((1 shl 1)-1)) shl 18);
end;

procedure COMPILESYM3_FLAGS.SetfExp(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 19))) or ((Value and ((1 shl 1)-1)) shl 19);
end;

procedure COMPILESYM3_FLAGS.Setpad(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 12)-1) shl 20))) or ((Value and ((1 shl 12)-1)) shl 20);
end;

function ENVBLOCKSYM_FLAGS.Getrev: UInt8;
begin
  Result := (_props and (((1 shl 1)-1) shl 0)) shr 0;
end;

function ENVBLOCKSYM_FLAGS.Getpad: UInt8;
begin
  Result := (_props and (((1 shl 7)-1) shl 1)) shr 1;
end;

procedure ENVBLOCKSYM_FLAGS.Setrev(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 0))) or ((Value and ((1 shl 1)-1)) shl 0);
end;

procedure ENVBLOCKSYM_FLAGS.Setpad(Value: UInt8);
begin
  _props := (_props and (not (((1 shl 7)-1) shl 1))) or ((Value and ((1 shl 7)-1)) shl 1);
end;

function CV_PUBSYMFLAGS.GetfCode: CV_pubsymflag_t;
begin
  Result := (grfFlags and (((1 shl 1)-1) shl 0)) shr 0;
end;

function CV_PUBSYMFLAGS.GetfFunction: CV_pubsymflag_t;
begin
  Result := (grfFlags and (((1 shl 1)-1) shl 1)) shr 1;
end;

function CV_PUBSYMFLAGS.GetfManaged: CV_pubsymflag_t;
begin
  Result := (grfFlags and (((1 shl 1)-1) shl 2)) shr 2;
end;

function CV_PUBSYMFLAGS.GetfMSIL: CV_pubsymflag_t;
begin
  Result := (grfFlags and (((1 shl 1)-1) shl 3)) shr 3;
end;

function CV_PUBSYMFLAGS.Get__unused: CV_pubsymflag_t;
begin
  Result := (grfFlags and (((1 shl 28)-1) shl 4)) shr 4;
end;

procedure CV_PUBSYMFLAGS.SetfCode(Value: CV_pubsymflag_t);
begin
  grfFlags := (grfFlags and (not (((1 shl 1)-1) shl 0))) or ((Value and ((1 shl 1)-1)) shl 0);
end;

procedure CV_PUBSYMFLAGS.SetfFunction(Value: CV_pubsymflag_t);
begin
  grfFlags := (grfFlags and (not (((1 shl 1)-1) shl 1))) or ((Value and ((1 shl 1)-1)) shl 1);
end;

procedure CV_PUBSYMFLAGS.SetfManaged(Value: CV_pubsymflag_t);
begin
  grfFlags := (grfFlags and (not (((1 shl 1)-1) shl 2))) or ((Value and ((1 shl 1)-1)) shl 2);
end;

procedure CV_PUBSYMFLAGS.SetfMSIL(Value: CV_pubsymflag_t);
begin
  grfFlags := (grfFlags and (not (((1 shl 1)-1) shl 3))) or ((Value and ((1 shl 1)-1)) shl 3);
end;

procedure CV_PUBSYMFLAGS.Set__unused(Value: CV_pubsymflag_t);
begin
  grfFlags := (grfFlags and (not (((1 shl 28)-1) shl 4))) or ((Value and ((1 shl 28)-1)) shl 4);
end;

function FRAMEPROCSYM_FLAGS.GetfHasAlloca: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 0)) shr 0;
end;

function FRAMEPROCSYM_FLAGS.GetfHasSetJmp: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 1)) shr 1;
end;

function FRAMEPROCSYM_FLAGS.GetfHasLongJmp: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 2)) shr 2;
end;

function FRAMEPROCSYM_FLAGS.GetfHasInlAsm: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 3)) shr 3;
end;

function FRAMEPROCSYM_FLAGS.GetfHasEH: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 4)) shr 4;
end;

function FRAMEPROCSYM_FLAGS.GetfInlSpec: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 5)) shr 5;
end;

function FRAMEPROCSYM_FLAGS.GetfHasSEH: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 6)) shr 6;
end;

function FRAMEPROCSYM_FLAGS.GetfNaked: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 7)) shr 7;
end;

function FRAMEPROCSYM_FLAGS.GetfSecurityChecks: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 8)) shr 8;
end;

function FRAMEPROCSYM_FLAGS.GetfAsyncEH: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 9)) shr 9;
end;

function FRAMEPROCSYM_FLAGS.GetfGSNoStackOrdering: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 10)) shr 10;
end;

function FRAMEPROCSYM_FLAGS.GetfWasInlined: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 11)) shr 11;
end;

function FRAMEPROCSYM_FLAGS.GetfGSCheck: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 12)) shr 12;
end;

function FRAMEPROCSYM_FLAGS.GetfSafeBuffers: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 13)) shr 13;
end;

function FRAMEPROCSYM_FLAGS.GetencodedLocalBasePointer: UInt32;
begin
  Result := (_props and (((1 shl 2)-1) shl 14)) shr 14;
end;

function FRAMEPROCSYM_FLAGS.GetencodedParamBasePointer: UInt32;
begin
  Result := (_props and (((1 shl 2)-1) shl 16)) shr 16;
end;

function FRAMEPROCSYM_FLAGS.GetfPogoOn: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 18)) shr 18;
end;

function FRAMEPROCSYM_FLAGS.GetfValidCounts: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 19)) shr 19;
end;

function FRAMEPROCSYM_FLAGS.GetfOptSpeed: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 20)) shr 20;
end;

function FRAMEPROCSYM_FLAGS.GetfGuardCF: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 21)) shr 21;
end;

function FRAMEPROCSYM_FLAGS.GetfGuardCFW: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 22)) shr 22;
end;

function FRAMEPROCSYM_FLAGS.Getpad: UInt32;
begin
  Result := (_props and (((1 shl 9)-1) shl 23)) shr 23;
end;

procedure FRAMEPROCSYM_FLAGS.SetfHasAlloca(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 0))) or ((Value and ((1 shl 1)-1)) shl 0);
end;

procedure FRAMEPROCSYM_FLAGS.SetfHasSetJmp(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 1))) or ((Value and ((1 shl 1)-1)) shl 1);
end;

procedure FRAMEPROCSYM_FLAGS.SetfHasLongJmp(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 2))) or ((Value and ((1 shl 1)-1)) shl 2);
end;

procedure FRAMEPROCSYM_FLAGS.SetfHasInlAsm(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 3))) or ((Value and ((1 shl 1)-1)) shl 3);
end;

procedure FRAMEPROCSYM_FLAGS.SetfHasEH(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 4))) or ((Value and ((1 shl 1)-1)) shl 4);
end;

procedure FRAMEPROCSYM_FLAGS.SetfInlSpec(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 5))) or ((Value and ((1 shl 1)-1)) shl 5);
end;

procedure FRAMEPROCSYM_FLAGS.SetfHasSEH(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 6))) or ((Value and ((1 shl 1)-1)) shl 6);
end;

procedure FRAMEPROCSYM_FLAGS.SetfNaked(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 7))) or ((Value and ((1 shl 1)-1)) shl 7);
end;

procedure FRAMEPROCSYM_FLAGS.SetfSecurityChecks(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 8))) or ((Value and ((1 shl 1)-1)) shl 8);
end;

procedure FRAMEPROCSYM_FLAGS.SetfAsyncEH(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 9))) or ((Value and ((1 shl 1)-1)) shl 9);
end;

procedure FRAMEPROCSYM_FLAGS.SetfGSNoStackOrdering(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 10))) or ((Value and ((1 shl 1)-1)) shl 10);
end;

procedure FRAMEPROCSYM_FLAGS.SetfWasInlined(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 11))) or ((Value and ((1 shl 1)-1)) shl 11);
end;

procedure FRAMEPROCSYM_FLAGS.SetfGSCheck(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 12))) or ((Value and ((1 shl 1)-1)) shl 12);
end;

procedure FRAMEPROCSYM_FLAGS.SetfSafeBuffers(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 13))) or ((Value and ((1 shl 1)-1)) shl 13);
end;

procedure FRAMEPROCSYM_FLAGS.SetencodedLocalBasePointer(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 2)-1) shl 14))) or ((Value and ((1 shl 2)-1)) shl 14);
end;

procedure FRAMEPROCSYM_FLAGS.SetencodedParamBasePointer(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 2)-1) shl 16))) or ((Value and ((1 shl 2)-1)) shl 16);
end;

procedure FRAMEPROCSYM_FLAGS.SetfPogoOn(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 18))) or ((Value and ((1 shl 1)-1)) shl 18);
end;

procedure FRAMEPROCSYM_FLAGS.SetfValidCounts(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 19))) or ((Value and ((1 shl 1)-1)) shl 19);
end;

procedure FRAMEPROCSYM_FLAGS.SetfOptSpeed(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 20))) or ((Value and ((1 shl 1)-1)) shl 20);
end;

procedure FRAMEPROCSYM_FLAGS.SetfGuardCF(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 21))) or ((Value and ((1 shl 1)-1)) shl 21);
end;

procedure FRAMEPROCSYM_FLAGS.SetfGuardCFW(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 22))) or ((Value and ((1 shl 1)-1)) shl 22);
end;

procedure FRAMEPROCSYM_FLAGS.Setpad(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 9)-1) shl 23))) or ((Value and ((1 shl 9)-1)) shl 23);
end;

function ExpandEncodedBasePointerReg(machineType, encodedFrameReg: UInt32): UInt16;
const
  rgFramePointerRegX86: array [0..3] of UInt16 = (
    CV_REG_NONE, CV_ALLREG_VFRAME, CV_REG_EBP, CV_REG_EBX);
  rgFramePointerRegX64: array [0..3] of UInt16 = (
    CV_REG_NONE, CV_AMD64_RSP, CV_AMD64_RBP, CV_AMD64_R13);
  rgFramePointerRegArm: array [0..3] of UInt16 = (
    CV_REG_NONE, CV_ARM_SP, CV_ARM_R7, CV_REG_NONE);
begin
  if encodedFrameReg >= 4 then
    Exit(CV_REG_NONE);

  case machineType of
    CV_CFL_8080,
    CV_CFL_8086,
    CV_CFL_80286,
    CV_CFL_80386,
    CV_CFL_80486,
    CV_CFL_PENTIUM,
    CV_CFL_PENTIUMII,
    CV_CFL_PENTIUMIII:
      Exit(rgFramePointerRegX86[encodedFrameReg]);
    CV_CFL_AMD64:
      Exit(rgFramePointerRegX64[encodedFrameReg]);
    CV_CFL_ARMNT:
      Exit(rgFramePointerRegArm[encodedFrameReg]);
  else
    Result := CV_REG_NONE;
  end;
end;

function CV_RANGEATTR.Getmaybe: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 0)) shr 0;
end;

function CV_RANGEATTR.Getpadding: UInt16;
begin
  Result := (_props and (((1 shl 15)-1) shl 1)) shr 1;
end;

procedure CV_RANGEATTR.Setmaybe(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 0))) or ((Value and ((1 shl 1)-1)) shl 0);
end;

procedure CV_RANGEATTR.Setpadding(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 15)-1) shl 1))) or ((Value and ((1 shl 15)-1)) shl 1);
end;

function DEFRANGESYMSUBFIELDREGISTER.GetoffParent: CV_uoff32_t;
begin
  Result := (_props and (((1 shl CV_OFFSET_PARENT_LENGTH_LIMIT)-1) shl 0)) shr 0;
end;

function DEFRANGESYMSUBFIELDREGISTER.Getpadding: CV_uoff32_t;
begin
  Result := (_props and (((1 shl 20)-1) shl CV_OFFSET_PARENT_LENGTH_LIMIT)) shr CV_OFFSET_PARENT_LENGTH_LIMIT;
end;

procedure DEFRANGESYMSUBFIELDREGISTER.SetoffParent(Value: CV_uoff32_t);
begin
  _props := (_props and (not (((1 shl CV_OFFSET_PARENT_LENGTH_LIMIT)-1) shl 0))) or ((Value and ((1 shl CV_OFFSET_PARENT_LENGTH_LIMIT)-1)) shl 0);
end;

procedure DEFRANGESYMSUBFIELDREGISTER.Setpadding(Value: CV_uoff32_t);
begin
  _props := (_props and (not (((1 shl 20)-1) shl CV_OFFSET_PARENT_LENGTH_LIMIT))) or ((Value and ((1 shl 20)-1)) shl CV_OFFSET_PARENT_LENGTH_LIMIT);
end;

function DEFRANGESYMREGISTERREL.GetspilledUdtMember: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 0)) shr 0;
end;

function DEFRANGESYMREGISTERREL.Getpadding: UInt16;
begin
  Result := (_props and (((1 shl 3)-1) shl 1)) shr 1;
end;

function DEFRANGESYMREGISTERREL.GetoffsetParent: UInt16;
begin
  Result := (_props and (((1 shl CV_OFFSET_PARENT_LENGTH_LIMIT)-1) shl 4)) shr 4;
end;

procedure DEFRANGESYMREGISTERREL.SetspilledUdtMember(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 0))) or ((Value and ((1 shl 1)-1)) shl 0);
end;

procedure DEFRANGESYMREGISTERREL.Setpadding(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 3)-1) shl 1))) or ((Value and ((1 shl 3)-1)) shl 1);
end;

procedure DEFRANGESYMREGISTERREL.SetoffsetParent(Value: UInt16);
begin
  _props := (_props and (not (((1 shl CV_OFFSET_PARENT_LENGTH_LIMIT)-1) shl 4))) or ((Value and ((1 shl CV_OFFSET_PARENT_LENGTH_LIMIT)-1)) shl 4);
end;

function DEFRANGESYMHLSL.GetregIndices: UInt16;
begin
  Result := (_props and (((1 shl 2)-1) shl 0)) shr 0;
end;

function DEFRANGESYMHLSL.GetspilledUdtMember: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 2)) shr 2;
end;

function DEFRANGESYMHLSL.GetmemorySpace: UInt16;
begin
  Result := (_props and (((1 shl 4)-1) shl 3)) shr 3;
end;

function DEFRANGESYMHLSL.Getpadding: UInt16;
begin
  Result := (_props and (((1 shl 9)-1) shl 7)) shr 7;
end;

procedure DEFRANGESYMHLSL.SetregIndices(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 2)-1) shl 0))) or ((Value and ((1 shl 2)-1)) shl 0);
end;

procedure DEFRANGESYMHLSL.SetspilledUdtMember(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 2))) or ((Value and ((1 shl 1)-1)) shl 2);
end;

procedure DEFRANGESYMHLSL.SetmemorySpace(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 4)-1) shl 3))) or ((Value and ((1 shl 4)-1)) shl 3);
end;

procedure DEFRANGESYMHLSL.Setpadding(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 9)-1) shl 7))) or ((Value and ((1 shl 9)-1)) shl 7);
end;

function CV_DEFRANGESYM_GAPS_COUNT(const x: DEFRANGESYM): Integer; inline;
begin
  Result := (x.reclen + SizeOf(x.reclen) - SizeOf(DEFRANGESYM)) div SizeOf(CV_LVAR_ADDR_GAP)
end;

function CV_DEFRANGESYMSUBFIELD_GAPS_COUNT(const x: DEFRANGESYMSUBFIELD): Integer; inline;
begin
  Result := (x.reclen + SizeOf(x.reclen) - SizeOf(DEFRANGESYMSUBFIELD)) div SizeOf(CV_LVAR_ADDR_GAP)
end;

function CV_DEFRANGESYMHLSL_GAPS_COUNT(const x: DEFRANGESYMHLSL): Integer; inline;
begin
  Result := (x.reclen + SizeOf(x.reclen) - SizeOf(DEFRANGESYMHLSL) - x.regIndices * SizeOf(CV_uoff32_t)) div SizeOf(CV_LVAR_ADDR_GAP)
end;

function CV_DEFRANGESYMHLSL_GAPS_CONST_PTR(const x: DEFRANGESYMHLSL): PCV_LVAR_ADDR_GAP; inline;
begin
  Result := PCV_LVAR_ADDR_GAP(@x.data[0]);
end;

function CV_DEFRANGESYMHLSL_GAPS_PTR(const x: DEFRANGESYMHLSL): PCV_LVAR_ADDR_GAP; inline;
begin
  Result := PCV_LVAR_ADDR_GAP(@x.data[0]);
end;

function CV_DEFRANGESYMHLSL_OFFSET_CONST_PTR(const x: DEFRANGESYMHLSL): PCV_uoff32_t; inline;
begin
{$POINTERMATH ON}
  Result := PCV_uoff32_t(@PCV_LVAR_ADDR_GAP(@x.data[0])[CV_DEFRANGESYMHLSL_GAPS_COUNT(x)]);
{$POINTERMATH OFF}
end;

function CV_DEFRANGESYMHLSL_OFFSET_PTR(const x: DEFRANGESYMHLSL): PCV_uoff32_t; inline;
begin
{$POINTERMATH ON}
  Result := PCV_uoff32_t(@PCV_LVAR_ADDR_GAP(@x.data[0])[CV_DEFRANGESYMHLSL_GAPS_COUNT(x)]);
{$POINTERMATH OFF}
end;

{$if defined(CC_DP_CXX)}

function CV_DPCSYMTAGMAP_COUNT(const x: DPCSYMTAGMAP): Integer; inline;
begin
  Result := (x.reclen + SizeOf(x.reclen) - SizeOf(DPCSYMTAGMAP)) div SizeOf(CV_DPC_SYM_TAG_MAP_ENTRY);
end;

{$endif CC_DP_CXX}

function MODTYPEREF.GetfNone: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 0)) shr 0;
end;

function MODTYPEREF.GetfRefTMPCT: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 1)) shr 1;
end;

function MODTYPEREF.GetfOwnTMPCT: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 2)) shr 2;
end;

function MODTYPEREF.GetfOwnTMR: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 3)) shr 3;
end;

function MODTYPEREF.GetfOwnTM: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 4)) shr 4;
end;

function MODTYPEREF.GetfRefTM: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 5)) shr 5;
end;

function MODTYPEREF.Getreserved: UInt32;
begin
  Result := (_props and (((1 shl 9)-1) shl 6)) shr 6;
end;

procedure MODTYPEREF.SetfNone(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 0))) or ((Value and ((1 shl 1)-1)) shl 0);
end;

procedure MODTYPEREF.SetfRefTMPCT(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 1))) or ((Value and ((1 shl 1)-1)) shl 1);
end;

procedure MODTYPEREF.SetfOwnTMPCT(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 2))) or ((Value and ((1 shl 1)-1)) shl 2);
end;

procedure MODTYPEREF.SetfOwnTMR(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 3))) or ((Value and ((1 shl 1)-1)) shl 3);
end;

procedure MODTYPEREF.SetfOwnTM(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 4))) or ((Value and ((1 shl 1)-1)) shl 4);
end;

procedure MODTYPEREF.SetfRefTM(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 5))) or ((Value and ((1 shl 1)-1)) shl 5);
end;

procedure MODTYPEREF.Setreserved(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 9)-1) shl 6))) or ((Value and ((1 shl 9)-1)) shl 6);
end;

function EXPORTSYM.GetfConstant: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 0)) shr 0;
end;

function EXPORTSYM.GetfData: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 1)) shr 1;
end;

function EXPORTSYM.GetfPrivate: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 2)) shr 2;
end;

function EXPORTSYM.GetfNoName: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 3)) shr 3;
end;

function EXPORTSYM.GetfOrdinal: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 4)) shr 4;
end;

function EXPORTSYM.GetfForwarder: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 5)) shr 5;
end;

function EXPORTSYM.Getreserved: UInt16;
begin
  Result := (_props and (((1 shl 10)-1) shl 6)) shr 6;
end;

procedure EXPORTSYM.SetfConstant(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 0))) or ((Value and ((1 shl 1)-1)) shl 0);
end;

procedure EXPORTSYM.SetfData(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 1))) or ((Value and ((1 shl 1)-1)) shl 1);
end;

procedure EXPORTSYM.SetfPrivate(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 2))) or ((Value and ((1 shl 1)-1)) shl 2);
end;

procedure EXPORTSYM.SetfNoName(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 3))) or ((Value and ((1 shl 1)-1)) shl 3);
end;

procedure EXPORTSYM.SetfOrdinal(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 4))) or ((Value and ((1 shl 1)-1)) shl 4);
end;

procedure EXPORTSYM.SetfForwarder(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 5))) or ((Value and ((1 shl 1)-1)) shl 5);
end;

procedure EXPORTSYM.Setreserved(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 10)-1) shl 6))) or ((Value and ((1 shl 10)-1)) shl 6);
end;

function DISCARDEDSYM.Getdiscarded: UInt32;
begin
  Result := (_props and (((1 shl 8)-1) shl 0)) shr 0;
end;

function DISCARDEDSYM.Getreserved: UInt32;
begin
  Result := (_props and (((1 shl 24)-1) shl 8)) shr 8;
end;

procedure DISCARDEDSYM.Setdiscarded(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 8)-1) shl 0))) or ((Value and ((1 shl 8)-1)) shl 0);
end;

procedure DISCARDEDSYM.Setreserved(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 24)-1) shl 8))) or ((Value and ((1 shl 24)-1)) shl 8);
end;

function REFMINIPDB.GetfLocal: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 0)) shr 0;
end;

function REFMINIPDB.GetfData: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 1)) shr 1;
end;

function REFMINIPDB.GetfUDT: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 2)) shr 2;
end;

function REFMINIPDB.GetfLabel: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 3)) shr 3;
end;

function REFMINIPDB.GetfConst: UInt16;
begin
  Result := (_props and (((1 shl 1)-1) shl 4)) shr 4;
end;

function REFMINIPDB.Getreserved: UInt16;
begin
  Result := (_props and (((1 shl 11)-1) shl 5)) shr 5;
end;

procedure REFMINIPDB.SetfLocal(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 0))) or ((Value and ((1 shl 1)-1)) shl 0);
end;

procedure REFMINIPDB.SetfData(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 1))) or ((Value and ((1 shl 1)-1)) shl 1);
end;

procedure REFMINIPDB.SetfUDT(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 2))) or ((Value and ((1 shl 1)-1)) shl 2);
end;

procedure REFMINIPDB.SetfLabel(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 3))) or ((Value and ((1 shl 1)-1)) shl 3);
end;

procedure REFMINIPDB.SetfConst(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 4))) or ((Value and ((1 shl 1)-1)) shl 4);
end;

procedure REFMINIPDB.Setreserved(Value: UInt16);
begin
  _props := (_props and (not (((1 shl 11)-1) shl 5))) or ((Value and ((1 shl 11)-1)) shl 5);
end;

function CV_Line_t.GetlinenumStart: UInt32;
begin
  Result := (_props and (((1 shl 24)-1) shl 0)) shr 0;
end;

function CV_Line_t.GetdeltaLineEnd: UInt32;
begin
  Result := (_props and (((1 shl 7)-1) shl 24)) shr 24;
end;

function CV_Line_t.GetfStatement: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 31)) shr 31;
end;

procedure CV_Line_t.SetlinenumStart(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 24)-1) shl 0))) or ((Value and ((1 shl 24)-1)) shl 0);
end;

procedure CV_Line_t.SetdeltaLineEnd(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 7)-1) shl 24))) or ((Value and ((1 shl 7)-1)) shl 24);
end;

procedure CV_Line_t.SetfStatement(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 31))) or ((Value and ((1 shl 1)-1)) shl 31);
end;

function FRAMEDATA.GetfHasSEH: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 0)) shr 0;
end;

function FRAMEDATA.GetfHasEH: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 1)) shr 1;
end;

function FRAMEDATA.GetfIsFunctionStart: UInt32;
begin
  Result := (_props and (((1 shl 1)-1) shl 2)) shr 2;
end;

function FRAMEDATA.Getreserved: UInt32;
begin
  Result := (_props and (((1 shl 29)-1) shl 3)) shr 3;
end;

procedure FRAMEDATA.SetfHasSEH(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 0))) or ((Value and ((1 shl 1)-1)) shl 0);
end;

procedure FRAMEDATA.SetfHasEH(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 1))) or ((Value and ((1 shl 1)-1)) shl 1);
end;

procedure FRAMEDATA.SetfIsFunctionStart(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 1)-1) shl 2))) or ((Value and ((1 shl 1)-1)) shl 2);
end;

procedure FRAMEDATA.Setreserved(Value: UInt32);
begin
  _props := (_props and (not (((1 shl 29)-1) shl 3))) or ((Value and ((1 shl 29)-1)) shl 3);
end;

constructor ComboID.Create(imod: UInt16; index: UInt32);
begin
  m_comboID := (UInt32(imod) shl IndexBitWidth) or index;
end;

constructor ComboID.Create(comboID: UInt32);
begin
  m_comboID := comboID;
end;

class operator ComboID.Implicit(const Value: ComboID): UInt32;
begin
  Result := Value.m_comboID;
end;

function ComboID.GetModIndex(): UInt16;
begin
  Result := UInt16(m_comboID shr IndexBitWidth);
end;

function ComboID.GetIndex: UInt32;
begin
  Result := m_comboID and ((1 shl IndexBitWidth) - 1);
end;

constructor CrossScopeID.Create(aIdScopeId: UInt16; aLocalId: UInt32);
begin
  crossScopeId := StartCrossScopeId
         or (aIdScopeId shl LocalIdBitWidth)
         or aLocalId;
end;

class operator CrossScopeID.Implicit(const Value: CrossScopeId): UInt32;
begin
  Result := Value.crossScopeId;
end;

function CrossScopeID.GetLocalId: UInt32;
begin
  Result := crossScopeId and LocalIdMask;
end;

function CrossScopeID.GetIdScopeId: UInt32;
begin
  Result := (crossScopeId and ScopeIdMask) shr LocalIdBitWidth;
end;

class function CrossScopeID.IsCrossScopeId(i: UInt32): Boolean;
begin
  Result := (StartCrossScopeId and i) <> 0;
end;

class function CrossScopeID.Decode(i: UInt32): CrossScopeId;
begin
  Result.crossScopeId := i;
end;

constructor DecoratedItemId.Create(isFuncId: Boolean; inputId: CV_ItemId);
begin
  if (isFuncId) then
    decoratedItemId := $80000000 or inputId
  else
    decoratedItemId := inputId;
end;

constructor DecoratedItemId.Create(encodedId: CV_ItemId);
begin
  decoratedItemId := encodedId;
end;

class operator DecoratedItemId.Implicit(const Value: DecoratedItemId): UInt32;
begin
  Result := Value.decoratedItemId;
end;

function DecoratedItemId.IsFuncId: Boolean;
begin
  Result := (decoratedItemId and $80000000) = $80000000;
end;

function DecoratedItemId.GetItemId: CV_ItemId;
begin
  Result := decoratedItemId and $7fffffff;
end;

function BinaryAnnotationInstructionOperandCount(op: BinaryAnnotationOpcode): Integer; inline;
begin
  if op = BA_OP_ChangeCodeLengthAndCodeOffset then
    Result := 2
  else
    Result := 1;
end;

function CVCompressData(
    iLen:     UInt32;     // [IN]  given uncompressed data
    pDataOut: Pointer):   // [OUT] buffer for the compressed data
    UInt32; inline;
var
  pBytes: ^UInt8;
begin
{$POINTERMATH ON}
  pBytes := pDataOut;

  if iLen <= $7F then begin
    pBytes[0] := UInt8(iLen);
    Exit(1);
  end;

  if iLen <= $3FFF then begin
    pBytes[0] := UInt8((iLen shr 8) or $80);
    pBytes[1] := UInt8(iLen and $ff);
    Exit(2);
  end;

  if iLen <= $1FFFFFFF then begin
    pBytes[0] := UInt8((iLen shr 24) and $C0);
    pBytes[1] := UInt8((iLen shr 16) and $ff);
    pBytes[2] := UInt8((iLen shr 8)  and $ff);
    pBytes[3] := UInt8(iLen and $ff);
    Exit(4);
  end;

  Result := UInt32(-1);
{$POINTERMATH OFF}
end;

function CVUncompressData(
    var pData: PCompressedAnnotation):
    UInt32; inline;    // [IN,OUT] compressed data
begin
  Result := UInt32(-1);

  if (pData^ and $80) = $00 then begin
    // 0??? ????

    Result := UInt32(pData^);
    Inc(pData);
  end
  else if ((pData^ and $C0) = $80) then begin
    // 10?? ????

    Result := (pData^ and $3f) shl 8;
    Inc(pData);
    Result := Result or pData^;
    Inc(pData);
  end
  else if ((pData^ and $E0) = $C0) then begin
    // 110? ????

    Result := (pData^ and $1f) shl 24;
    Inc(pData);
    Result := Result or (pData^ shl 16);
    Inc(pData);
    Result := Result or (pData^ shl 8);
    Inc(pData);
    Result := Result or pData^;
    Inc(pData);
  end;
end;

function EncodeSignedInt32(input: Int32): UInt32; inline;
begin
  if input >= 0 then
    Result := input shl 1
  else
    Result := ((-input) shl 1) or 1;
end;

function DecodeSignedInt32(input: UInt32): Int32; inline;
begin
  if (input and 1) = 1 then
    Result := -Int32(input shr 1)
  else
    Result := input shr 1;
end;

end.
