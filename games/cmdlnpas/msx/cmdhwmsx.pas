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
 *)

(*
 * Internal module variables and definitions.
 *)
Var
       pfptPlayerX,
       pfptPlayerY      : ^TFixedPoint;
       oldScrStatus     : TScreenStatus;
       nOldWriteHandler : Integer;




(**
  * Perform specific harware initialization.
  * @param fptPlayerX Reference to fPlayerX engine variable;
  * @param fptPlayerY Reference to fPlayerY engine variable;
  *)
Procedure InitHW( Var fptPlayerX, fptPlayerY : TFixedPoint );
Var
         y : Integer;

Begin
  pfptPlayerX := Ptr( Addr( fptPlayerX ) );
  pfptPlayerY := Ptr( Addr( fptPlayerY ) );
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
  { Get machine frequency }
  If( GetHostFrequency = Timing50Hz )  Then
    fFrequency := ( 1/50 )
  Else
    fFrequency := ( 1/60 );

  GetFrequency := fFrequency;
End;

(**
  * Initialize the output device.
  *)
Procedure OpenOutputDevice;
Var
     scrStatus : TScreenStatus;

Begin
  ClrScr;
  GetScreenStatus( scrStatus );

  With scrStatus Do
  Begin
    nWidth    := 40;
    nFgColor  := 15;
    nBkColor  := 0;
    nBdrColor := 0;
    bFnKeyOn  := False;
  End;

  SetScreenStatus( scrStatus, oldScrStatus );
  nOldWriteHandler := ConOutPtr;
  ConOutPtr := Addr( DirectWrite );
End;

(**
  * Close the output device.
  *)
Procedure CloseOutputDevice;
Var
     scrStatus : TScreenStatus;

Begin
  ConOutPtr := nOldWriteHandler;
  SetScreenStatus( oldScrStatus, scrStatus );
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
  Begin
    Read( Kbd, chRes );
    chRes := UpCase( chRes );
  End
  Else
    chRes := ' ';

  ProcessInput := chRes;
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
     nAddr,
     x, y    : Integer;
     LINL40  : Byte Absolute $F3AE; { Width for SCREEN 0 }

Begin
  InLine( $F3 ); { DI }

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
      nAddr     := ( ( LINL40 * y ) + x );
      Port[$99] := Lo( nAddr );
      Port[$99] := ( Hi( nAddr ) And $3F ) Or $40;
      Port[$98] := Byte( aScreen[x, y] );
    End;

  InLine( $FB ); { EI }
End;
