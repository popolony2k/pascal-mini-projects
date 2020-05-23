(*
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>
 *)

(**
  *
  * $Id: $
  * $Author: $
  * $Date: $
  * $Revision: $
  * $HeadURL: $
  *)

(*
 * This module depends on folowing include files (respect the order):
 * - types.pas;
 * - systypes.pas;
 * - system.pas;
 * - dvram.pas;
 * - msxbios.pas;
 * - conio.pas;
 * - fixedpt.pas;
 * - cmdtpdef.pas;
 * - cmdlndef.pas;
 * - cmdlnvar.pas;
 * - cmdhwmsx.pas;
 *)


(**
  * Fill map for a given row.
  * @param y Row to fill map data;
  * @param strData The row data to store;
  *)
Procedure FillMapData( y : Integer; strData : TMapRowData );
Var
     x,
     nLen     : Integer;
Begin
  nLen := ( Length( strData ) - 1 );

  For x := 0 To nLen Do
    aMap[x, y] := strData[x+1];
End;

(**
  * Initialize engine data, maps and variables.
  *)
Procedure InitEngine;
Begin
  { Create Map of world space # = wall block, . = space }
  FillMapData( 0, '############' );
  FillMapData( 1, '#..........#' );
  FillMapData( 2, '#....##....#' );
  FillMapData( 3, '#....##....#' );
  FillMapData( 4, '###........#' );
  FillMapData( 5, '##.........#' );
  FillMapData( 6, '#....###..##' );
  FillMapData( 7, '#....#.....#' );
  FillMapData( 8, '#..........#' );
  FillMapData( 9, '#....#######' );
  FillMapData( 10,'#..........#' );
  FillMapData( 11,'############' );

  FillChar( aScreen, SizeOf( aScreen ), ' ' );
End;

(**
  * Execute the First Person Shooter engine.
  *)
Procedure RunEngine;
Var
      fptStepAngle      : TFixedPoint;
      fpt_025           : TFixedPoint;
      fpt_05            : TFixedPoint;
      fpt_075           : TFixedPoint;
      fpt_09            : TFixedPoint;
      fptDepth          : TFixedPoint;
      fptDepth_3        : TFixedPoint;        { ctDepth / 3.0         }
      fptDepth_4        : TFixedPoint;        { ctDepth / 4.0         }
      fptDepth_5        : TFixedPoint;        { ctDepth / 5.0         }
      fptStepSize       : TFixedPoint;
      fptRotSpeed       : TFixedPoint;        { Rotation speed        }
      fptPlayerA        : TFixedPoint;        { Player Start Rotation }
      fptPlayerX        : TFixedPoint;        { Player start          }
      fptPlayerY        : TFixedPoint;        { position              }
      fptTwoPI          : TFixedPoint;        { PI * 2                }
      fptScreenHeight   : TFixedPoint;
      fptScreenHeight_2 : TFixedPoint;        { ctScreenHeight / 2.0  }
      fptDistanceToWall : TFixedPoint;
      fptEyeX           : TFixedPoint;
      fptEyeY           : TFixedPoint;
      b                 : TFixedPoint;
      pCos              : PDynFixedPointArray;
      pSin              : PDynFixedPointArray;
      pRayAngle         : PDynFixedPointArray;
      pShader           : PDynFixedPointArray;
      x, y              : TInteger;
      nCeiling          : TInteger;
      nFloor            : TInteger;
      nIniTime          : TInteger;
      nEndTime          : TInteger;
      nAngles           : TInteger;
      nRayAngle         : TInteger;
      nStatusPos        : TInteger;
      chShade           : TChar;
      fFOV              : Real;               { Field of View         }
      fFrequency        : Real;
      fElapsedTime      : Real;
      fStepAngle        : Real;
      bDisplayStatus    : Boolean;

Label __loop,
      __end;

Begin
  _GotoXY( 1, 1 );
  Write( 'Warming up' );

  { Pre calculated static values }
  nStatusPos  := ( 1 + ctMapWidth );
  fFOV        := ( PI / ctFOVDivisor );
  fpt_025     := RealToFixed( 0.25, ctFixedBitsFrac );
  fpt_05      := RealToFixed( 0.5, ctFixedBitsFrac );
  fpt_075     := RealToFixed( 0.75, ctFixedBitsFrac );
  fpt_09      := RealToFixed( 0.9, ctFixedBitsFrac );
  fptTwoPI    := RealToFixed( ( PI * 2 ), ctFixedBitsFrac );
  fptRotSpeed := RealToFixed( ( PI / 6.0 ), ctFixedBitsFrac );
  fptPlayerX  := RealToFixed( ctPlayerX, ctFixedBitsFrac );
  fptPlayerY  := RealToFixed( ctPlayerY, ctFixedBitsFrac );
  fptPlayerA  := RealToFixed( 0.0, ctFixedBitsFrac );
  fptStepSize := RealToFixed( ctStepSize, ctFixedBitsFrac );
  fptDepth    := RealToFixed( ctDepth, ctFixedBitsFrac );
  fptDepth_3  := RealToFixed( ( ctDepth / 3.0 ), ctFixedBitsFrac );
  fptDepth_4  := RealToFixed( ( ctDepth / 4.0 ), ctFixedBitsFrac );
  fptDepth_5  := RealToFixed( ( ctDepth / 5.0 ), ctFixedBitsFrac );
  fptScreenHeight   := IntToFixed( ctScreenHeight, ctFixedBitsFrac );
  fptScreenHeight_2 := IntToFixed( ( ctScreenHeight Div 2 ), ctFixedBitsFrac );
  bDisplayStatus    := False;

  { Get machine frequency }
  fFrequency := GetFrequency;

  { Create trigonometric lookup table - Thanks Israel F. Araujo }
  nAngles      := Trunc( ( PI * 2.0 ) * ( ctScreenWidth / fFOV ) );
  fStepAngle   := ( ( PI * 2.0 ) / nAngles );
  fptStepAngle := RealToFixed( fStepAngle, ctFixedBitsFrac );

  GetMem( pCos, ( nAngles * SizeOf( TFixedPoint ) ) );
  GetMem( pSin, ( nAngles * SizeOf( TFixedPoint ) ) );

  fElapsedTime := 0.0;

  For x := 0 To ( nAngles - 1 ) Do
  Begin
    pCos^[x] := RealToFixed( Cos( fElapsedTime ), ctFixedBitsFrac );
    pSin^[x] := RealToFixed( Sin( fElapsedTime ), ctFixedBitsFrac );
    fElapsedTime := fElapsedTime + fStepAngle;
  End;

  { Create ray angle lookup table - Thanks Israel F. Araujo }
  GetMem( pRayAngle, ( ctScreenWidth * SizeOf( TFixedPoint ) ) );

  For x := 0 To ctScrnBufWidth Do
    pRayAngle^[x] := RealToFixed( ( ( fFOV / 2.0 ) -
                                    ( x / ctScreenWidth ) * fFOV ),
                                    ctFixedBitsFrac );

  { Create shader calculated values lookup table }
  GetMem( pShader, ( ctScreenHeight * SizeOf( TFixedPoint ) ) );

  For y := 0 To ctScrnBufHeight Do
    pShader^[y] := RealToFixed( ( 1.0 -
                                 ( ( y - ( ctScreenHeight / 2.0 ) ) /
                                   ( ctScreenHeight / 2.0 ) ) ),
                                ctFixedBitsFrac );

  { Setup parameters specific to current hardware }
  InitHW( fptPlayerX, fptPlayerY );

  { Main engine loop }
  nIniTime := JIFFY;

  { While( True ) Do }
  { Begin }
  __loop:
    (*
     * We'll need time differential per frame to calculate modification
     * to movement speeds, to ensure consistant movement, as ray-tracing
     * is non-deterministic.
     *)
    nEndTime     := JIFFY;
    fElapsedTime := ( ( nEndTime - nIniTime ) * fFrequency );
    nIniTime     := nEndTime;

    { Display status }
    If( bDisplayStatus )  Then
    Begin
      _GotoXY( nStatusPos, 1 );
      Write( 'X=', fptPlayerX, ' Y=', fptPlayerY, ' A=', fptPlayerA,
             ' SPF=', fElapsedTime:4:4 );
    End;

    For x := 0 To ctScrnBufWidth Do
    Begin
      { For each column, calculate the projected ray angle into world space }
      nRayAngle := ( ( fptPlayerA - pRayAngle^[x] ) Div fptStepAngle );

      If( nRayAngle < 0 )  Then
        nRayAngle := nRayAngle + nAngles
      Else
      If( nRayAngle > nAngles )  Then
        nRayAngle := nRayAngle - nAngles;

      { Find distance to wall }
      fptDistanceToWall := 0;

      fptEyeX := pSin^[nRayAngle];
      fptEyeY := pCos^[nRayAngle];

      (*
       * Incrementally cast ray from player, along ray angle
       * testing for intersection with a block.
       *)
      Repeat
        fptDistanceToWall := fptDistanceToWall + fptStepSize;
        chShade := aMap[FixedToInt( fptPlayerX +
                                    MulFixedUFixed( fptEyeX,
                                                    fptDistanceToWall,
                                                    ctFixedBitsFrac ),
                                    ctFixedBitsFrac ),
                        FixedToInt( fptPlayerY +
                                    MulFixedUFixed( fptEyeY,
                                                    fptDistanceToWall,
                                                    ctFixedBitsFrac ),
                                    ctFixedBitsFrac )];
      Until( chShade = '#' );

      { Calculate distance to ceiling and floor }
      nCeiling := FixedToInt( ( fptScreenHeight_2 -
                              DivFixed( fptscreenHeight,
                                        fptDistanceToWall,
                                        ctFixedBitsFrac ) ),
                              ctFixedBitsFrac );
      nFloor := ( ctScreenHeight - nCeiling );

      { Shader walls based on distance }
      If( fptDistanceToWall <= fptDepth_5 )  Then
        chShade := ctCloseDistShade
      Else
      If( fptDistanceToWall <= fptDepth_4 )  Then
        chShade := ctLowDistShade
      Else If( fptDistanceToWall < fptDepth_3 )  Then
        chShade := ctMedDistShade
      Else If( fptDistanceToWall < fptDepth )  Then
        chShade := ctHighDistShade
      Else
        chShade := ctFarDistShade;            { Too far away }

      For y := 0 To ctScrnBufHeight Do
      Begin
        { Each Row }
        If( y <= nCeiling )  Then
          aScreen[x, y] := ' '
        Else
          If( ( y > nCeiling ) And ( y <= nFloor ) )  Then
            aScreen[x, y] := chShade
          Else  { Floor }
          Begin
            { Shade floor based on distance }
            b := pShader^[y];

            If( b < fpt_025 )  Then
              chShade := '#'
            Else
            If( b < fpt_05 )  Then
              chShade := '~'
            Else
            If( b < fpt_075 )  Then
              chShade := '.'
            Else
            If( b < fpt_09 )  Then
              chShade := '-'
            Else
              chShade := ' ';

            aScreen[x, y] := chShade;
          End;
      End;
    End;

    WriteOutput{( pfptPlayerX, pfptPlayerY )};

    { Keyboard handling }
    Case ProcessInput Of
      ' ' : Goto __loop; { Goto loop beggining }

      'A' : Begin  {  Handle CCW Rotation }
              fptPlayerA := fptPlayerA - fptRotSpeed;

              If( fptPlayerA < 0 )  Then
                fptPlayerA := fptTwoPI - fptRotSpeed;
            End;

      'D' : Begin  { Handle CW Rotation }
              fptPlayerA := fptPlayerA + fptRotSpeed;

              If( fptPlayerA >= fptTwoPI )  Then
                fptPlayerA := 0;
            End;

      'W' : Begin  { Handle Forwards movement & collision }
              nRayAngle := FixedToInt( DivFixed( fptPlayerA,
                                                 fptStepAngle,
                                                 ctFixedBitsFrac ),
                                       ctFixedBitsFrac );

              fptPlayerX := fptPlayerX + pSin^[nRayAngle];
              fptPlayerY := fptPlayerY + pCos^[nRayAngle];

              If( aMap[FixedToInt( fptPlayerX, ctFixedBitsFrac ),
                       FixedToInt( fptPlayerY, ctFixedBitsFrac )] = '#' )  Then
              Begin
                fptPlayerX := fptPlayerX - pSin^[nRayAngle];
                fptPlayerY := fptPlayerY - pCos^[nRayAngle];
              End;
            End;

      'S' : Begin  { Handle backwards movement & collision }
              nRayAngle := FixedToInt( DivFixed( fptPlayerA,
                                                 fptStepAngle,
                                                 ctFixedBitsFrac ),
                                       ctFixedBitsFrac );

              fptPlayerX := fptPlayerX - pSin^[nRayAngle];
              fptPlayerY := fptPlayerY - pCos^[nRayAngle];

              If( aMap[FixedToInt( fptPlayerX, ctFixedBitsFrac ),
                       FixedToInt( fptPlayerY, ctFixedBitsFrac )] = '#' )  Then
              Begin
                fptPlayerX := fptPlayerX + pSin^[nRayAngle];
                fptPlayerY := fptPlayerY + pCos^[nRayAngle];
              End;
            End;

      'T' : bDisplayStatus := Not bDisplayStatus; { Toggle on/off status }

      #27 : Goto __end;  { ESC - Exit }
    End;

    Goto __loop;

  __end:  { End engine loop }
  { End; }

  EndHW;
  FreeMem( pCos, ( nAngles * SizeOf( TFixedPoint ) ) );
  FreeMem( pSin, ( nAngles * SizeOf( TFixedPoint ) ) );
  FreeMem( pRayAngle, ( ctScreenWidth * SizeOf( TFixedPoint ) ) );
  FreeMem( pShader, ( ctScreenHeight * SizeOf( TFixedPoint ) ) );
End;
