Unit PairRealSort;

  {$ifdef fpc}
    {$mode delphi}
    {$H+}
  {$endif}

  Interface

  (*
   * Pair structure (could be generics BUT it will run on MSX (TP3)
   * so forget this idea).
   *)
  Type TPairReal = Record
     first  : Real;
     second : Real;
  End;

  TPairRealArray = Array[0..3] Of TPairReal;

  Procedure SortPairRealArray( Var arr : TPairRealArray );

  Implementation

  Uses AnySort;

  Function ComparePairReal( Const d1, d2 ) : Integer;
  Var
    i1      : TPairReal Absolute d1;
    i2      : TPairReal Absolute d2;
    nResult : Integer;

  Begin
    If( i1.first = i2.first )  Then
      nResult:=0
    Else
    If( i1.first < i2.first )  Then
      nResult:=-1
    Else
      nResult:=1;

    ComparePairReal := nResult;
  End;

  Procedure SortPairRealArray( Var arr : TPairRealArray );
  Begin
    AnySort.AnySort( arr, Length( arr ),
                     SizeOf( TPairReal ),
                     @ComparePairReal );
  End;
End.
