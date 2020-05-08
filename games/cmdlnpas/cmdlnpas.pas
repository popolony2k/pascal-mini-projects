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

Uses   Crt, SysUtils, DateUtils, Math, PairRealSort, EpikTimer;

{$r-}

(*
 * Constanbts and data structures definition.
 *)
Const
         ctScreenWidth       = 120 {80};    { Console Screen Size X (columns) }
         ctScreenHeight      = 40 {23};    { Console Screen Size Y (rows)    }
         ctMapWidth          = 16;    { World Dimensions                }
         ctMapHeight         = 16;
         ctPlayerX           = 8.0  {14.7};   { Player initial coordinates      }
         ctPlayerY           = 8.0  {5.09};

         ctSpeed      : Real = 5.0;   { Walking speed                   }
         ctDepth      : Real = 16.0;  { Maximum rendering distance      }

(* From (types.pas) - PopolonY2k Framework *)
Type  TDynCharArray = Array[0..0] Of Char;  { Unchecked array just to   }
      PDynCharArray = ^TDynCharArray;       { work easily like C does   }
      TMapRowData   = String[ctMapWidth+1]; { Map row data              }

      Var
         fPlayerA        : Real;      { Player Start Rotation           }
         fPlayerX        : Real;      { Player start                    }
         fPlayerY        : Real;      { position                        }
         fFOV            : Real;      { Field of View                   }
         fTp1, fTp2      : Real;
         fElapsedTime    : Real;
         fRayAngle       : Real;
         fStepSize       : Real;
	 fDistanceToWall : Real;
         fEyeX           : Real;
         fEyeY           : Real;
         fBound          : Real;
         vy, vx          : Real;
         b, d, dot       : Real;
         aScreenBuffer   : Array[0..ctScreenWidth-1, 0..ctScreenHeight-1] Of Char;
         aMap            : Array[0..ctMapWidth-1, 0..ctMapHeight-1] Of Char;
         pMap            : PDynCharArray;
         pScreenBuffer   : PDynCharArray;
         nTestX          : Integer;
         nTestY          : Integer;
         x, y, tx, ty    : Integer;
         nx, ny          : Integer;
         nBytesWritten   : Integer;
         nCount          : Integer;
         nCeiling        : Integer;
         nFloor          : Integer;
	 chShade         : Char;
         chKey           : Char;
         bRunning        : Boolean;
         bHitWall        : Boolean;
	 bBoundary       : Boolean;
         p               : TPairRealArray;
         strStats        : String[40];
         timer           : TEpikTimer;

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
  nLen := Length( strData );

  For nCount := 0 To nLen Do
    aMap[nRow, nCount] := strData[nCount+1];
End;

(**
  * Initialize engine data, maps and variables.
  *)
Procedure InitEngine;
Var
       strMap : String[17];
       nCX, nCY : Integer;
Begin
  fFOV      := ( Pi / 4.0 );
  fPlayerX  := ctPlayerX;
  fPlayerY  := ctPlayerY;
  fPlayerA  := 0.0;
  timer     := TEpikTimer.Create( Nil );

  WriteLn( SizeOf( Char ) );
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
  pMap := @aMap; { pMap := Ptr( Addr( aMap ) ); (* TP3 *) }

  FillChar( aScreenBuffer, SizeOf( aScreenBuffer ), ' ' );
  pScreenBuffer := @aScreenBuffer; { pScreenBuffer := Ptr( Addr( aScreenBuffer ) ); (* TP3 *) }
End;


Begin       { Main entry point }
  InitEngine;           { Initialize engine data }
  timer.Start;
  nBytesWritten := 0;
  fTp1     := timer.Elapsed;
  bRunning := True;

  ClrScr;

  While( bRunning ) Do
  Begin
    (*
     * We'll need time differential per frame to calculate modification
     * to movement speeds, to ensure consistant movement, as ray-tracing
     * is non-deterministic.
     *)
    fTp2 := timer.Elapsed;
    fElapsedTime := ( fTp2 - fTp1 );
    fTp1  := fTp2;
    chKey := ' ';

    { Keyboard handling }
    If( KeyPressed ) Then
      chKey := UpCase( ReadKey );

    Case chKey Of
      {  Handle CCW Rotation }
      'A' : fPlayerA := fPlayerA - ( ctSpeed * 0.75 ) * fElapsedTime;

      { Handle CW Rotation }
      'D' : fPlayerA := fPlayerA +  ( ctSpeed * 0.75 ) * fElapsedTime;

      // Handle Forwards movement & collision
      'W' : Begin
              fPlayerX := fPlayerX + Sin( fPlayerA ) * ctSpeed * fElapsedTime;
              fPlayerY := fPlayerY + Cos( fPlayerA ) * ctSpeed * fElapsedTime;

              if( pMap^[Trunc(fPlayerX * ctMapWidth +fPlayerY )] = '#' )  Then
              Begin
	        fPlayerX := fPlayerX - Sin( fPlayerA ) * ctSpeed * fElapsedTime;
		fPlayerY := fPlayerY - Cos( fPlayerA ) * ctSpeed * fElapsedTime;
              End;
            End;

      // Handle backwards movement & collision
      'S' : Begin
	      fPlayerX := fPlayerX - Sin( fPlayerA ) * ctSpeed * fElapsedTime;
	      fPlayerY := fPlayerY - Cos( fPlayerA ) * ctSpeed * fElapsedTime;

              if( pMap^[Trunc( fPlayerX * ctMapWidth + fPlayerY )] = '#' )  Then
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
      { TODO: Check Real cast below, at the end }
      fRayAngle := ( fPlayerA - fFOV / 2.0 ) + ( Real( x ) / Real( ctScreenWidth ) ) * fFOV;

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
          If( pMap^[nTestX * ctMapWidth + nTestY] = '#')  Then
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
            fBound := 0.01;

            If( ArcCos( p[0].second ) < fBound ) Then
              bBoundary := True;
            If( ArcCos( p[1].second ) < fBound ) Then
              bBoundary := True;
            If( ArcCos( p[2].second ) < fBound ) Then
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
        chShade := #$DB    {0x2588}  { Very close }
      Else If( fDistanceToWall < ctDepth / 3.0 )  Then
        chShade := #$B2  {0x2593}
      Else If( fDistanceToWall < ctDepth / 2.0 )  Then
        chShade := #$B1  {0x2592}
      Else If( fDistanceToWall < ctDepth )  Then
        chShade := #$B0  {0x2591}
      Else
        chShade := ' ';            { Too far away }

      if( bBoundary )  Then
        chShade := ' ';            { Black it out }

      For y := 0 To ( ctScreenHeight - 1 ) Do
      Begin
        { Each Row }
        If( y <= nCeiling )  Then
          pScreenBuffer^[y*ctScreenWidth + x] := ' '
        Else
        if( ( y > nCeiling ) And ( y <= nFloor ) )  Then
          pScreenBuffer^[y*ctScreenWidth + x] := chShade
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

          pScreenBuffer^[y*ctScreenWidth + x] := chShade;
        End;
      End;
    End;

    { Display stats }
    strStats := Format( 'X=%3.2f, Y=%3.2f, A=%3.2f FPS=%3.8f ', [fPlayerX, fPlayerY, fPlayerA, {1.0 /} fElapsedTime ] );
    For nx := 0 To Length( strStats ) Do
      pScreenBuffer^[nx] := strStats[nx+1];

    { Display Map }
    For nx := 0 To ( ctMapWidth - 1 ) Do
      For ny := 0 To ( ctMapHeight -1 ) Do
      Begin
        pScreenBuffer^[( ny + 1 ) * ctScreenWidth + nx] := pMap^[ny * ctMapWidth + nx];
      End;

    pScreenBuffer^[Trunc( fPlayerX + 1 ) * ctScreenWidth + Trunc( fPlayerY )] := 'P';

    { Display Frame }
    pScreenBuffer^[ctScreenWidth * ctScreenHeight - 1] := #0;

    ClrScr;
    Write( StrPas( pScreenBuffer^ ) );
  End;

  timer.Stop;
End.

{ That's It!! - PopolonY2k }