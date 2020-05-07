unit AnySort;

  {$ifdef fpc}
    {$mode delphi}
    {$H+}
  {$endif}

  interface

  type
    TCompareFunc = function (const elem1, elem2): Integer;

  procedure AnySort(var Arr; Count: Integer; Stride: Integer; CompareFunc: TCompareFunc);

  implementation

  type
    TByteArray = array [Word] of byte;
    PByteArray = ^TByteArray;

  procedure AnyQuickSort(var Arr; idxL, idxH: Integer;
    Stride: Integer; CompareFunc: TCompareFunc; var SwapBuf);
  var
    ls,hs : Integer;
    li,hi : Integer;
    mi    : Integer;
    ms    : Integer;
    pb    : PByteArray;
  begin
    pb:=@Arr;
    li:=idxL;
    hi:=idxH;
    mi:=(li+hi) div 2;
    ls:=li*Stride;
    hs:=hi*Stride;
    ms:=mi*Stride;
    repeat
      while CompareFunc( pb[ls], pb[ms] ) < 0 do begin
        inc(ls, Stride);
        inc(li);
      end;
      while CompareFunc( pb[ms], pb[hs] ) < 0 do begin
        dec(hs, Stride);
        dec(hi);
      end;
      if ls <= hs then begin
        Move(pb[ls], SwapBuf, Stride);
        Move(pb[hs], pb[ls], Stride);
        Move(SwapBuf, pb[hs], Stride);
        inc(ls, Stride); inc(li);
        dec(hs, Stride); dec(hi);
      end;
    until ls>hs;
    if hi>idxL then AnyQuickSort(Arr, idxL, hi, Stride, CompareFunc, SwapBuf);
    if li<idxH then AnyQuickSort(Arr, li, idxH, Stride, CompareFunc, SwapBuf);
  end;

  procedure AnySort(var Arr; Count: Integer; Stride: Integer; CompareFunc: TCompareFunc);
  var
    buf: array of byte;
  begin
    SetLength(buf, Stride);
    AnyQuickSort(Arr, 0, Count-1, Stride, compareFunc, buf[0]);
  end;
end.
