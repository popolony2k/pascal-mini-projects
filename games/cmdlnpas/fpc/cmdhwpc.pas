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
 * - fixedpt.pas;
 * - cmdfpdef.pas;
 * - cmdlndef.pas;
 * - cmdlnvar.pas;
 *)

(*
 * Internal module variables and definitions.
 *)
Var
       pfptPlayerX,
       pfptPlayerY      : ^TFixedPoint;


(**
  * Perform specific harware initialization.
  * @param fptPlayerX Reference to fPlayerX engine variable;
  * @param fptPlayerY Reference to fPlayerY engine variable;
  *)
Procedure InitHW( Var fptPlayerX, fptPlayerY : TFixedPoint );
Var
         y : Integer;

Begin
  pfptPlayerX := @fptPlayerX;
  pfptPlayerY := @fptPlayerY;
End;

(**
  * Perform specific hardware finlization.
  *)
Procedure EndHW;
Begin

End;

(**
  * Get Machine frequency.
  *)
Function GetFrequency : Real;
Var
      fFrequency : Real;

Begin
  GetFrequency := 1.0;   { TODO: FINISHIM! Retrieve the frequency here }
End;

(**
  * Clock simulation based on hardware clock cycles.
  *)
Function JIFFY : TInteger;
Begin
  JIFFY := 1;            { TODO: FINISHIM! Retrieve the clock time }
End;

(**
  * Initialize the output device.
  *)
Procedure OpenOutputDevice;
Begin
  ClrScr;
End;

(**
  * Close the output device.
  *)
Procedure CloseOutputDevice;
Begin
  ClrScr;
End;

(**
  * Process keyboard input handling.
  *)
Function ProcessInput : TChar;
Var
      chRes   : TChar ;

Begin
  If( KeyPressed ) Then
    chRes := UpCase( ReadKey )
  Else
    chRes := ' ';

  ProcessInput := chRes;
End;

(**
  * Wrapper to keep main runner engine compatibility between
  * MSX and PC.
  *)
Procedure _GotoXY( x, y : Integer );
Begin
  GotoXY( x, y );
End;

(**
  * Write content to output device.
  * @param pfptPlayerX Player X position (@see <cmdlndef.pas>;
  * @param pfptPlayerY Player Y position (@see <cmdlndef.pas>;
  * @pMultiplier Precalculated lookup table (@see <cmdlndef.pas>;
  *)
Procedure WriteOutput{( pfptPlayerX, pfptPlayerY : ^Real;
                        pMultiplier : PDynIntArray )};
Var
     x, y    : Integer;

Begin
  { Copy map to screen buffer }
  For x := 0 To ctMapBufWidth Do
    For y := 0 To ctMapBufHeight Do
      aScreen[x,y] := aMap[x,y];

  aScreen[FixedToInt( pfptPlayerX^, ctFixedBitsFrac ),
          FixedToInt( pfptPlayerY^, ctFixedBitsFrac )] := 'O';

  { Write screen buffer }
  For x := 0 To ctScrnBufWidth Do
    For y := 0 To ctScrnBufHeight Do
    Begin
      _GotoXY( ( x + 1 ) ,( y + 1 ) );
      Write( aScreen[x,y] );
    End;
End;
