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

Program CommandLineFPaS;

(*
 * There is a problem is runtime (program exit), when it is compiled with
 * ncurses + crt).
 *)
{$IFDEF __NCURSES}
  {$IFNDEF __NCRT}
    {$ERROR This program doesn't run when compiled with (ncurses + crt),
    use (ncurses + ncrt)}
  {$ENDIF  __NCRT}
{$ENDIF __NCURSES}

Uses   SysUtils, DateUtils, Math, PairRealSort
{$IFDEF __NCRT}
       ,NCrt
{$ELSE  __CRT}
       , Crt
{$ENDIF __NCRT}
{$IFDEF __NCURSES}
       ,NCurses
{$ENDIF __NCURSES}
       ;

{$r-}

(*
 * Constants and data structures definition.
 *)
Const
         ctMili              = 1000;    { Miliseconds  scale              }
         ctMicro             = 1000000; { Microseconds scale              }

         ctClockScale        = ctMicro; { Set clock scale                 }
         ctScreenWidth       =  120;    { Console Screen Size X (columns) }
         ctScreenHeight      =   40;    { Console Screen Size Y (rows)    }
         ctMapWidth          =   16;    { World Dimensions                }
         ctMapHeight         =   16;
         ctPlayerX           =  8.0;    { Player initial coordinates      }
         ctPlayerY           =  8.0;
         ctSpeed      : Real = 5.0;     { Walking speed                   }
         ctDepth      : Real = 16.0;    { Maximum rendering distance      }
         ctBound      : Real = 0.01;    { Ray boundary precision          }


Type
{$IFDEF __WIDECHAR}
      TChar        = WideChar;
      TMapStatus   = WideString;              { Map status bar            }
{$ELSE  __CHAR}
      TChar        = Char;
      TMapStatus   = String[40];              { Map status bar            }
{$ENDIF __WIDECHAR}
      (* From (types.pas) - PopolonY2k Framework *)
      TDynCharArray = Array[0..0] Of TChar;   { Unchecked array just to   }
      PDynCharArray = ^TDynCharArray;         { work easily like C does   }
      TMapRowData   = String[ctMapWidth+1];   { Map row data              }


Var
      fPlayerA        : Real;                 { Player Start Rotation     }
      fPlayerX        : Real;                 { Player start              }
      fPlayerY        : Real;                 { position                  }
      fFOV            : Real;                 { Field of View             }
      fTp1, fTp2      : Real;
      fElapsedTime    : Real;
      fRayAngle       : Real;
      fStepSize       : Real;
      fDistanceToWall : Real;
      fEyeX           : Real;
      fEyeY           : Real;
      vy, vx          : Real;
      b, d, dot       : Real;
      aScreenBuffer   : Array[0..ctScreenWidth-1, 0..ctScreenHeight-1] Of TChar;
      aMapBuffer      : Array[0..ctMapWidth-1, 0..ctMapHeight-1] Of TChar;
      aMap            : TDynCharArray Absolute aMapBuffer;
      aScreen         : TDynCharArray Absolute aScreenBuffer;
      nTestX          : Integer;
      nTestY          : Integer;
      x, y, tx, ty    : Integer;
      nx, ny          : Integer;
      nCount          : Integer;
      nCeiling        : Integer;
      nFloor          : Integer;
      chShade         : TChar;
      chKey           : TChar;
      bRunning        : Boolean;
      bHitWall        : Boolean;
      bBoundary       : Boolean;
      p               : TPairRealArray;
      strStats        : TMapStatus;


(**
  * Get the tick count for FPS calculation.
  *)
Function GetClockTickCount : Real;
Begin
  GetClockTickCount := ( Now *  ctClockScale );
End;

(**
  * Fill map for a given row.
  * @param nRow Row to fill map data;
  * @param strData The row data to store;
  *)
Procedure FillMapData( nRow : Integer; strData : TMapRowData );
Var
     nCount,
     nLen     : Integer;
Begin
  nLen := ( Length( strData ) - 1 );

  For nCount := 0 To nLen Do
    aMapBuffer[nRow, nCount] := strData[nCount+1];
End;

(**
  * Initialize engine data, maps and variables.
  *)
Procedure InitEngine;
Begin
  fFOV     := ( Pi / 4.0 );
  fPlayerX := ctPlayerX;
  fPlayerY := ctPlayerY;
  fPlayerA := 0.0;
  fTp1     := GetClockTickCount;
  bRunning := True;

  { Create Map of world space # = wall block, . = space }
  FillMapData( 0, '#########.......' );
  FillMapData( 1, '#...............' );
  FillMapData( 2, '#.......########' );
  FillMapData( 3, '#..............#' );
  FillMapData( 4, '#......##......#' );
  FillMapData( 5, '#......##......#' );
  FillMapData( 6, '#..............#' );
  FillMapData( 7, '###............#' );
  FillMapData( 8, '##.............#' );
  FillMapData( 9, '#......####..###' );
  FillMapData( 10,'#......#.......#' );
  FillMapData( 11,'#......#.......#'  );
  FillMapData( 12,'#..............#'  );
  FillMapData( 13,'#......#########'  );
  FillMapData( 14,'#..............#'  );
  FillMapData( 15,'################'  );

  FillChar( aScreenBuffer, SizeOf( aScreenBuffer ), ' ' );
End;

(**
  * Initialize the output device.
  *)
Procedure OpenOutputDevice;
Begin
{$IFDEF __NCURSES}
  InitScr;
  NoEcho;                  { No echo user input        }
  NoDelay( StdScr, True ); { No input delay            }
  Curs_Set( 0 );           { No cursor                 }
  ResizeTerm( ctScreenHeight, ctScreenWidth );
{$ENDIF __NCURSES}
End;

(**
  * Close the output device.
  *)
Procedure CloseOutputDevice;
Begin
{$IFDEF __NCURSES}
  EndWin;
{$ENDIF __NCURSES}
End;

(**
  * Process keyboard input handling.
  *)
Function ProcessInput : TChar;
Var
      chRes   : TChar ;

Begin
{$IFDEF __NCURSES}
  chRes := TChar( getch );

  Case Ord( chRes ) Of
    KEY_LEFT  : chRes := 'A';
    KEY_RIGHT : chRes := 'D';
    KEY_UP    : chRes := 'W';
    KEY_DOWN  : chRes := 'S';
  End;
{$ELSE  __CRT}
  If( KeyPressed ) Then
    chRes := UpCase( ReadKey );
{$ENDIF __NCURSES}

  ProcessInput := chRes;
End;

(**
  * Write content to output device.
  *)
Procedure WriteOutput;
Begin
{$IFDEF __NCURSES}
  MvPrintW( 0, 0, '%s', aScreen );
  Refresh;
{$ELSE  __CRT}
  GotoXY( 1, 1 );
  Write( StrPas( aScreen ) );
{$ENDIF __NCURSES}
End;


Begin                   { Main entry point }
  ClrScr;
  InitEngine;           { Initialize engine data       }
  OpenOutputDevice;     { Initialize the output device }

  While( bRunning ) Do
  Begin
    (*
     * We'll need time differential per frame to calculate modification
     * to movement speeds, to ensure consistant movement, as ray-tracing
     * is non-deterministic.
     *)
    fTp2 := GetClockTickCount;
    fElapsedTime := ( fTp2 - fTp1 );
    fTp1  := fTp2;
    chKey := ' ';

    { Keyboard handling }
    chKey := ProcessInput;

    Case chKey Of
      {  Handle CCW Rotation }
      'A' : fPlayerA := fPlayerA - ( ctSpeed * 0.75 ) * fElapsedTime;

      { Handle CW Rotation }
      'D' : fPlayerA := fPlayerA +  ( ctSpeed * 0.75 ) * fElapsedTime;

      // Handle Forwards movement & collision
      'W' : Begin
              fPlayerX := fPlayerX + Sin( fPlayerA ) * ctSpeed * fElapsedTime;
              fPlayerY := fPlayerY + Cos( fPlayerA ) * ctSpeed * fElapsedTime;

              if( aMap[Trunc( fPlayerX ) * ctMapWidth + Trunc( fPlayerY ) ] = '#' )  Then
              Begin
	        fPlayerX := fPlayerX - Sin( fPlayerA ) * ctSpeed * fElapsedTime;
		fPlayerY := fPlayerY - Cos( fPlayerA ) * ctSpeed * fElapsedTime;
              End;
            End;

      // Handle backwards movement & collision
      'S' : Begin
	      fPlayerX := fPlayerX - Sin( fPlayerA ) * ctSpeed * fElapsedTime;
	      fPlayerY := fPlayerY - Cos( fPlayerA ) * ctSpeed * fElapsedTime;

              if( aMap[Trunc( fPlayerX ) * ctMapWidth + Trunc( fPlayerY ) ] = '#' )  Then
	      Begin
                fPlayerX := fPlayerX + Sin( fPlayerA ) * ctSpeed * fElapsedTime;
		fPlayerY := fPlayerY + Cos( fPlayerA ) * ctSpeed * fElapsedTime;
              End;
            End;

      #27 : bRunning := False;   { ESC - Exit }
    End;

    For x := 0 To ( ctScreenWidth - 1 ) Do
    Begin
      { For each column, calculate the projected ray angle into world space }
      fRayAngle := ( fPlayerA - fFOV / 2.0 ) + ( x / ctScreenWidth ) * fFOV;

      { Find distance to wall }
      fStepSize       := 0.1;    { Increment size for ray casting,     }
      fDistanceToWall := 0.0;    { decrease to increase resolution     }
      bHitWall        := False;  { Set when ray hits wall block        }
      bBoundary       := False;  { Set when ray hits boundary          }
                                 { between two wall blocks             }
      fEyeX := Sin( fRayAngle ); { Unit vector for ray in player space }
      fEyeY := Cos( fRayAngle );

      (*
       * Incrementally cast ray from player, along ray angle
       * testing for intersection with a block.
       *)
      While( Not bHitWall And ( fDistanceToWall < ctDepth ) ) Do
      Begin
        fDistanceToWall := fDistanceToWall + fStepSize;
        nTestX := Trunc( fPlayerX + fEyeX * fDistanceToWall );
        nTestY := Trunc( fPlayerY + fEyeY * fDistanceToWall );

        { Test if ray is out of bounds }
        if( ( nTestX < 0 ) Or ( nTestX >= ctMapWidth ) Or
            ( nTestY < 0 ) Or ( nTestY >= ctMapHeight ) )  Then
        Begin
          bHitWall        := True; { Just set distance to maximum depth }
          fDistanceToWall := ctDepth;
        End
        Else
        Begin
          { Ray is inbounds so test to see if the ray cell is a wall block }
          If( aMap[nTestX * ctMapWidth + nTestY] = '#')  Then
          Begin
            { Ray has hit wall }
            bHitWall := True;

            (*
             * To highlight tile boundaries, cast a ray from each corner
             * of the tile, to the player. The more coincident this ray
             * is to the rendering ray, the closer we are to a tile
             * boundary, which we'll shade to add detail to the walls
             *)
            nCount := 0;

            (*
             * Test each corner of hit tile, storing the distance from
             * the player, and the calculated dot product of the two rays
             *)
            For tx := 0 To 1 Do
              For ty := 0 To 1 Do
              Begin
                { Angle of corner to eye }
                vy  := nTestY + ty - fPlayerY;
                vx  := nTestX + tx - fPlayerX;
                {d   := Sqrt( ( vx * vx ) + ( vy * vy ) );}
                d   := Sqrt( Sqr( vx ) + Sqr( vy ) );
                dot := ( fEyeX * vx / d ) + ( fEyeY * vy / d );
                p[nCount].first  := d;
                p[nCount].second := dot;
                nCount := Succ( nCount );
              End;

            { Sort Pairs from closest to farthest }
            PairRealSort.SortPairRealArray( p );

            { First two/three are closest (we will never see all four) }
            If( ArcCos( p[0].second ) < ctBound ) Then
              bBoundary := True;
            If( ArcCos( p[1].second ) < ctBound ) Then
              bBoundary := True;
            If( ArcCos( p[2].second ) < ctBound ) Then
              bBoundary := True;
          End;
        End;
      End;

      { Calculate distance to ceiling and floor }
      nCeiling := Trunc( ( ctScreenHeight / 2.0 ) - ctScreenHeight /
                           fDistanceToWall );
      nFloor   := ( ctScreenHeight - nCeiling );

      { Shader walls based on distance }
      chShade := ' ';

      If( fDistanceToWall <= ctDepth / 4.0 )  Then
        chShade := 'X' {#$2F} {#$DB}  {#$2588}  { Very close }
      Else If( fDistanceToWall < ctDepth / 3.0 )  Then
        chShade := 'x' {#$5C} {#$B2}  {#$2593}
      Else If( fDistanceToWall < ctDepth / 2.0 )  Then
        chShade := '*' {#$2A} {#$B1}  {#$2592}
      Else If( fDistanceToWall < ctDepth )  Then
        chShade := '^' {#$5E} {#$B0}  {#$2591}
      Else
        chShade := ' ';            { Too far away }

      if( bBoundary )  Then
        chShade := ' ';            { Black it out }

      For y := 0 To ( ctScreenHeight - 1 ) Do
      Begin
        { Each Row }
        If( y <= nCeiling )  Then
          aScreen[y*ctScreenWidth + x] := ' '
        Else
        if( ( y > nCeiling ) And ( y <= nFloor ) )  Then
          aScreen[y*ctScreenWidth + x] := chShade
        Else  { Floor }
        Begin
          { Shade floor based on distance }
          b := 1.0 - ( ( y - ctScreenHeight / 2.0 ) / ( ctScreenHeight / 2.0 ) );

          If( b < 0.25 )  Then
            chShade := '#'
          Else
          If( b < 0.5 )  Then
            chShade := 'x'
          Else
          If( b < 0.75 )  Then
            chShade := '.'
          Else
          if( b < 0.9 )  Then
            chShade := '-'
          Else
            chShade := ' ';

          aScreen[y*ctScreenWidth + x] := chShade;
        End;
      End;
    End;

    { Display stats }
    strStats := Format( 'X=%3.2f, Y=%3.2f, A=%3.2f FPS=%3.8f ', [fPlayerX, fPlayerY, fPlayerA, {1.0 /} fElapsedTime ] );
    System.Move( strStats[1], aScreen, Length( strStats ) );

    { Display Map }
    For nx := 0 To ( ctMapWidth - 1 ) Do
      For ny := 0 To ( ctMapHeight -1 ) Do
      Begin
        aScreen[( ny + 1 ) * ctScreenWidth + nx] := aMap[ny * ctMapWidth + nx];
      End;

    aScreen[Trunc( fPlayerX + 1 ) * ctScreenWidth + Trunc( fPlayerY )] := 'P';

    { Display Frame }
    aScreen[ctScreenWidth * ctScreenHeight - 1] := #0;

    WriteOutput;
  End;

  CloseOutputDevice;
End.

{ That's It!! - PopolonY2k }
