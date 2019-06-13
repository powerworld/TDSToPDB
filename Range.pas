unit Range;

interface

uses
  System.Generics.Defaults;

type
  TUInt32RangeSet = record
  private type
    TIntervalPoint = record
    private class var
      FComparer: IComparer<TIntervalPoint>;
    public
      Point: UInt32;
      IsStart: Boolean;
      constructor Create(APoint: UInt32; AIsStart: Boolean);
      function IsEnd: Boolean; inline;
      class function Comparison(const Left, Right: TIntervalPoint): Integer; static;
    end;
  public type
    TRange = record
      Start,
      _End: UInt32;
      constructor Create(AStart, AEnd: UInt32);
    end;
  private
    FRanges: TArray<TRange>;
    class procedure BuildPoints(const Left, Right: TArray<TRange>; var Points: TArray<TIntervalPoint>); static;
    function GetRange(idx: Integer): TRange; inline;
    function GetCount: Integer; inline;
  public
    class operator Implicit(Range: TRange): TUInt32RangeSet;
    // Union
    class operator BitwiseOr(const Left, Right: TUInt32RangeSet): TUInt32RangeSet;
    // Difference
    class operator Subtract(const Left, Right: TUInt32RangeSet): TUInt32RangeSet; inline;
    // Intersection
    class operator BitwiseAnd(const Left, Right: TUInt32RangeSet): TUInt32RangeSet;
    // Disjoint Union
    class operator BitwiseXor(const Left, Right: TUInt32RangeSet): TUInt32RangeSet;
    // Inverse
    class operator LogicalNot(const Value: TUInt32RangeSet): TUInt32RangeSet;
    // Set contains
    class operator In(const Left: UInt32; const Right: TUInt32RangeSet): Boolean;
    class operator Equal(const Left, Right: TUInt32RangeSet): Boolean;
    class operator NotEqual(const Left, Right: TUInt32RangeSet): Boolean; inline;
    // Left contains all elements in Right: (Left or Right) = Left
    class operator GreaterThanOrEqual(const Left, Right: TUInt32RangeSet): Boolean; inline;
    // Right contains all elements in Left: (Left or Right) = Right
    class operator LessThanOrEqual(const Left, Right: TUInt32RangeSet): Boolean; inline;
    procedure Clear; inline;
    function IsEmpty: Boolean; inline;
    function Start: UInt32; inline;
    function _End: UInt32; inline;
    property Ranges[idx: Integer]: TRange read GetRange; default;
    property Count: Integer read GetCount;
  end;

function UInt32Range(AStart, AEnd: UInt32): TUInt32RangeSet.TRange; inline;

implementation

uses
  System.SysUtils, System.Generics.Collections;

constructor TUInt32RangeSet.TIntervalPoint.Create(APoint: UInt32; AIsStart: Boolean);
begin
  Point := APoint;
  IsStart := AIsStart;
end;

function TUInt32RangeSet.TIntervalPoint.IsEnd: Boolean;
begin
  Result := not IsStart;
end;

class function TUInt32RangeSet.TIntervalPoint.Comparison(const Left, Right: TIntervalPoint): Integer;
begin
  if      UInt32(Left.Point) < UInt32(Right.Point)  then Result := -1
  else if UInt32(Left.Point) > UInt32(Right.Point)  then Result := 1
  else if Left.IsStart and Right.IsEnd              then Result := -1
  else if Left.IsEnd and Right.IsStart              then Result := 1
  else                                                   Result := 0;
end;

constructor TUInt32RangeSet.TRange.Create(AStart, AEnd: UInt32);
begin
  Start := AStart;
  _End := AEnd;
end;

class procedure TUInt32RangeSet.BuildPoints(const Left, Right: TArray<TRange>;
  var Points: TArray<TIntervalPoint>);
var
  I, J: Integer;
begin
  SetLength(Points, (Length(Left) + Length(Right)) * 2);
  J := 0;
  for I := 0 to Length(Left) - 1 do begin
    Points[J + 0] := TIntervalPoint.Create(Left[I].Start, True);
    Points[J + 1] := TIntervalPoint.Create(Left[I]._End, False);
    Inc(J, 2);
  end;
  for I := 0 to Length(Right) - 1 do begin
    Points[J + 0] := TIntervalPoint.Create(Right[I].Start, True);
    Points[J + 1] := TIntervalPoint.Create(Right[I]._End, False);
    Inc(J, 2);
  end;

  TArray.Sort<TIntervalPoint>(Points, TIntervalPoint.FComparer);
end;

function TUInt32RangeSet.GetRange(idx: Integer): TRange;
begin
  Result := FRanges[idx];
end;

function TUInt32RangeSet.GetCount: Integer;
begin
  Result := Length(FRanges);
end;

class operator TUInt32RangeSet.Implicit(Range: TRange): TUInt32RangeSet;
begin
  // Only allow properly ordered ranges
  if Range.Start <= Range._End then
    Result.FRanges := [Range]
  else
    Result.FRanges := [];
end;

class operator TUInt32RangeSet.BitwiseOr(const Left, Right: TUInt32RangeSet): TUInt32RangeSet;
var
  I, J, Nesting: Integer;
  Points: TArray<TIntervalPoint>;
begin
  SetLength(Result.FRanges, Length(Left.FRanges) + Length(Right.FRanges));
  BuildPoints(Left.FRanges, Right.FRanges, Points);
  J := 0;
  Nesting := 0;
  for I := 0 to Length(Points) - 1 do begin
    if Points[I].IsStart then
      Inc(Nesting)
    else
      Dec(Nesting);
    if Nesting = 0 then begin
      Result.FRanges[J]._End := Points[I].Point;
      Inc(J);
    end
    else if (Nesting = 1) and Points[I].IsStart then
      Result.FRanges[J].Start := Points[I].Point;
  end;
  SetLength(Result.FRanges, J);
end;

class operator TUInt32RangeSet.Subtract(const Left, Right: TUInt32RangeSet): TUInt32RangeSet;
begin
  // This is slow, but it's the easy implementation
  Result := Left and (Left xor Right);
end;

class operator TUInt32RangeSet.BitwiseAnd(const Left, Right: TUInt32RangeSet): TUInt32RangeSet;
var
  I, J, Nesting: Integer;
  Points: TArray<TIntervalPoint>;
begin
  SetLength(Result.FRanges, Length(Left.FRanges) + Length(Right.FRanges));
  BuildPoints(Left.FRanges, Right.FRanges, Points);
  J := 0;
  Nesting := 0;
  for I := 0 to Length(Points) - 1 do begin
    if Points[I].IsStart then
      Inc(Nesting)
    else
      Dec(Nesting);
    if Nesting = 2 then
      Result.FRanges[J].Start := Points[I].Point
    else if (Nesting = 1) and Points[I].IsEnd then begin
      Result.FRanges[J]._End := Points[I].Point;
      Inc(J);
    end;
  end;
  SetLength(Result.FRanges, J);
end;

class operator TUInt32RangeSet.BitwiseXor(const Left, Right: TUInt32RangeSet): TUInt32RangeSet;
var
  I, J, Nesting: Integer;
  Points: TArray<TIntervalPoint>;
begin
  SetLength(Result.FRanges, Length(Left.FRanges) + Length(Right.FRanges));
  BuildPoints(Left.FRanges, Right.FRanges, Points);
  J := 0;
  Nesting := 0;
  for I := 0 to Length(Points) - 1 do begin
    if Points[I].IsStart then
      Inc(Nesting)
    else
      Dec(Nesting);
    if Nesting = 1 then
      Result.FRanges[J].Start := Points[I].Point
    else begin
      Result.FRanges[J]._End := Points[I].Point;
      Inc(J);
    end;
  end;
  SetLength(Result.FRanges, J);
end;

class operator TUInt32RangeSet.LogicalNot(const Value: TUInt32RangeSet): TUInt32RangeSet;
var
  I, J: Integer;
begin
  SetLength(Result.FRanges, Length(Value.FRanges) + 1);
  if Value.FRanges[0].Start <> UInt32.MinValue then begin
    Result.FRanges[0].Start := UInt32.MinValue;
    Result.FRanges[0]._End := Value.FRanges[0].Start - 1;
    J := 1;
  end
  else
    J := 0;

  for I := 0 to Length(Value.FRanges) - 2 do begin
    Result.FRanges[J].Start := Value.FRanges[I]._End + 1;
    Result.FRanges[J]._End := Value.FRanges[I + 1].Start - 1;
    Inc(J);
  end;
  if Value.FRanges[Length(Value.FRanges) - 1]._End <> UInt32.MaxValue then begin
    Result.FRanges[J].Start := Value.FRanges[Length(Value.FRanges) - 1]._End + 1;
    Result.FRanges[J]._End := UInt32.MaxValue;
    Inc(J);
  end;
  SetLength(Result.FRanges, J);
end;

class operator TUInt32RangeSet.In(const Left: UInt32; const Right: TUInt32RangeSet): Boolean;
var
  I: Integer;
begin
  for I := 0 to Length(Right.FRanges) - 1 do
    with Right.FRanges[I] do
      if (UInt32(Left) >= UInt32(Start)) and (UInt32(Left) <= UInt32(_End)) then
        Exit(True);
  Result := False;
end;

class operator TUInt32RangeSet.Equal(const Left, Right: TUInt32RangeSet): Boolean;
var
  I: Integer;
begin
  Result := Length(Left.FRanges) = Length(Right.FRanges);
  if Result then
    for I := 0 to Length(Left.FRanges) - 1 do
      if (Left.FRanges[I].Start <> Right.FRanges[I].Start) or
         (Left.FRanges[I]._End <> Right.FRanges[I]._End) then
        Exit(False);
end;

class operator TUInt32RangeSet.NotEqual(const Left, Right: TUInt32RangeSet): Boolean;
begin
  Result := not (Left = Right);
end;

class operator TUInt32RangeSet.GreaterThanOrEqual(const Left, Right: TUInt32RangeSet): Boolean;
begin
  Result := (Left or Right) = Left;
end;

class operator TUInt32RangeSet.LessThanOrEqual(const Left, Right: TUInt32RangeSet): Boolean;
begin
  Result := (Left or Right) = Right;
end;

procedure TUInt32RangeSet.Clear;
begin
  SetLength(FRanges, 0);
end;

function TUInt32RangeSet.IsEmpty: Boolean;
begin
  Result := Length(FRanges) = 0;
end;

function TUInt32RangeSet.Start: UInt32;
begin
  Result := FRanges[0].Start;
end;

function TUInt32RangeSet._End: UInt32;
begin
  Result := FRanges[Length(FRanges) - 1]._End;
end;

function UInt32Range(AStart, AEnd: UInt32): TUInt32RangeSet.TRange; inline;
begin
  Result := TUInt32RangeSet.TRange.Create(AStart, AEnd);
end;

initialization
  TUInt32RangeSet.TIntervalPoint.FComparer :=
    TComparer<TUInt32RangeSet.TIntervalPoint>.Construct(TUInt32RangeSet.TIntervalPoint.Comparison);

finalization

end.
