unit Main;

interface

procedure MainProc;

implementation

uses
  System.Classes, PDBInterface, CVInfo, TDSParser, TDSTypesConv, TDSSymbolsConv;

procedure MainProc;
var
  ParserImage: TPeBorTDSParserImage;
  TypesConverter: TTDSToPDBTypesConverter;
  SymbolsConverter: TTDSToPDBSymbolsConverter;
begin
  ParserImage := TPeBorTDSParserImage.Create;
  TypesConverter := nil;
  SymbolsConverter := nil;
  try
    ParserImage.FileName := ParamStr(1);
    TypesConverter := TTDSToPDBTypesConverter.Create(ParserImage.TDSParser);
    SymbolsConverter := TTDSToPDBSymbolsConverter.Create(ParserImage.TDSParser, TypesConverter);
  finally
    SymbolsConverter.Free;
    TypesConverter.Free;
    ParserImage.Free;
  end;
end;

procedure MainProcOld;
var
  PDB: PPDB;
  DBI: PDBI;
  &Mod: PMod;
  error: EC;
  errstr: array [0..cbErrMax-1] of Char;
  cbErr: NativeUInt;
  MemStream: TMemoryStream;
  locname: UTF8String;
  LenPos: Integer;
begin
  cbErr := cbErrMax;
  MemStream := TMemoryStream.Create;
  try
    if PPDB.Open2W('Test.pdb', pdbWrite, error, errstr, cbErr, PDB) and (PDB <> nil) then begin
      if PDB.CreateDBI(nil, DBI) and (DBI <> nil) then begin
        if DBI.OpenModW('SYSTEM', 'System.pas', &Mod) and (&Mod <> nil) then begin
          MemStream.WriteData(UInt32(CV_SIGNATURE_C13));
          LenPos := MemStream.Position;
          MemStream.WriteData(UInt16(0));
          MemStream.WriteData(UInt16(LF_POINTER));
          MemStream.WriteData(UInt32($00000074));
          MemStream.WriteData(UInt8($0A));
          MemStream.WriteData(UInt8($01));
          MemStream.Position := LenPos;
          MemStream.WriteData(UInt16(MemStream.Size-4-2));
          if not &Mod.AddTypes(MemStream.Memory, MemStream.Size) then begin
            error := PDB.QueryLastErrorExW(@errstr[0], cbErrMax);
            Writeln(PChar(@errstr[0]));
            Writeln(Ord(error));
            Writeln('failed');
            Exit;
          end;

          MemStream.Clear;
          locname := 'PInteger';
          MemStream.WriteData(UInt32(CV_SIGNATURE_C13));
          MemStream.WriteData(UInt32($000000F1));
          LenPos := MemStream.Position;
          MemStream.WriteData(UInt32(0));
          MemStream.WriteData(UInt16(0));
          MemStream.WriteData(UInt16(S_UDT));
          MemStream.WriteData(UInt32($00001000));
          MemStream.WriteData(UInt8(Length(locname)));
          MemStream.Write(locname[1], Length(locname));
          MemStream.Position := LenPos;
          MemStream.WriteData(UInt32(MemStream.Size-12));
          MemStream.WriteData(UInt16(MemStream.Size-14));



//          Inc(curptr, SizeOf(LongWord));
//          with PUDTSYM(curptr)^ do begin
//            reclen := SizeOf(UDTSYM) + Length(locname) - SizeOf(UInt16);
//            rectyp := S_UDT;
//            typind := $00000074;
//            name[0] := Length(locname);
//          end;
//          Inc(curptr, SizeOf(UDTSYM));
//          Move(locname[1], curptr^, Length(locname));
//          if not &Mod.AddSymbols(buffer, buflen) then begin
          if not &Mod.AddSymbols(MemStream.Memory, MemStream.Size) then begin
            error := PDB.QueryLastErrorExW(@errstr[0], cbErrMax);
            Writeln(PChar(@errstr[0]));
            Writeln(Ord(error));
            Writeln('failed');
          end;
          &Mod.Close;
        end;
        DBI.Close;
      end;
      PDB.Commit;
      PDB.Close;
      PDB := nil;
    end;
  finally
    MemStream.Free;
  end;
end;

end.
