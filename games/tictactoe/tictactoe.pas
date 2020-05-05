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
Program TicTacToe;

Uses crt;

Var
     aBoard     : Array [1..3, 1..3] Of Integer;
     aScore     : Array[0..1] Of Integer;
     bMatch,
     bFinished  : Boolean;
     nPlayer,
     nRow,
     nCol,
     nMoveCnt   : Byte;

(**
  * Init board structure.
  *)
Procedure InitBoard;
Var
     nCol,
     nRow   : Byte;
     nCount : Integer;

Begin
  nCount   := -$FF;
  bMatch   := True;
  nMoveCnt := 0;

  { Initialize board with a sequence of negative numbers }
  For nRow := 1 To 3 Do
    For nCol := 1 To 3 Do
    Begin
      aBoard[nRow, nCol ] := nCount;
      nCount := Pred( nCount );
    End;
End;

(**
  * Draw game grid and score boards.
  *)
Procedure DrawBoard;
Begin

  { Draw title }
  GotoXY( 35, 7 );
  Write( 'Tic-Tac-Toe' );

  { Draw grid }
  GotoXY( 40, 10 );
  WriteLn( '    1   2   3' );
  GotoXY( 40, 12 );
  WriteLn( '1     |   |     1' );
  GotoXY( 40, 13 );
  WriteLn( '   ___|___|___' );
  GotoXY( 40, 14 );
  WriteLn( '2     |   |     2' );
  GotoXY( 40, 15 );
  WriteLn( '   -----------' );
  GotoXY( 40, 16 );
  WriteLn( '3     |   |     3' );
  GotoXY( 40, 17 );
  WriteLn( '      |   |' );
  GotoXY( 40, 19 );
  WriteLn( '    1   2   3' );

  { Draw score }
  GotoXY( 5, 20 );
  Write( 'Score' );
  GotoXY( 15, 20 );
  Write( 'Player 0 -> ', aScore[0] );
  GotoXY( 15, 21 );
  Write( 'Player 1 -> ', aScore[1] );
End;

(**
  * Update player score.
  * @param nPlayerId The player id to update;
  *)
Procedure UpdateScore( nPlayerId : Integer );
Begin
  If( bMatch ) Then
  Begin
    aScore[nPlayerId] := aScore[nPlayerId] + 1;
    GotoXY( 27, 20 + nPlayerId );
    WriteLn( aScore[nPlayerId] );
  End;
End;

(**
  * Draw user input movement.
  *)
Procedure DrawMove;
Begin
  nMoveCnt := nMoveCnt + 1;
  aBoard[nRow, nCol] := nPlayer;
  GotoXY( 40 + ( nCol * 4 ), 10 + ( nRow * 2 ) );
  Write( nPlayer );
End;

(**
  * Process user input.
  *)
Procedure Input;
Begin
  GotoXY( 10, 10 );
  WriteLn( 'Player -> ', nPlayer );

  Repeat
    Repeat
      GotoXY( 10, 12 );
      Write( 'Row      -> ' );
      ReadLn( nRow );
    Until( nRow <= 3 );

    Repeat
      GotoXY( 10, 13 );
      Write( 'Column   -> ' );
      ReadLn( nCol );
    Until( nCol <= 3 );
  Until( aBoard[nRow, nCol] < 0 );
End;

(**
  * Check end game.
  *)
Procedure GameOverChk;
Var
     nLastMove  : Integer;

  (**
    * Check by row or by column.
    * @param bByColumn True if column checking;
    *)
  Procedure __Check( bByCol : Boolean );
  Var
     nRow, nCol : Byte;

  Begin
    nRow      := 1;
    nLastMove := $FF;

    { Check by column }
    While( nRow <= 3 ) Do
    Begin
      bMatch := True;

      If( bByCol )  Then
        nLastMove := aBoard[nRow, 1]
      Else
        nLastMove := aBoard[1, nRow];

      For nCol := 2 To 3 Do
      Begin
        If( bByCol )  Then
        Begin
          bMatch := ( bMatch And ( aBoard[nRow, nCol] = nLastMove ) );
          nLastMove := aBoard[nRow, nCol];
        End
        Else
        Begin
          bMatch := ( bMatch And ( aBoard[nCol, nRow] = nLastMove ) );
          nLastMove := aBoard[nCol, nRow];
        End;
      End;

      If( bMatch )  Then
        nRow := $FF
      Else
        nRow := nRow + 1;
    End;
  End;

Begin  { GameOverChk entry }
  __Check( True );        { Check by column }

  If( Not bMatch )  Then
    __Check( False );     { Check by row }

  { Check diagonal }
  If( Not bMatch )  Then
  Begin
    nLastMove := aBoard[1,1];
    bMatch    := ( ( nLastMove = aBoard[2,2] ) And
                   ( nLastMove = aBoard[3,3] ) );

    If( Not bMatch )  Then
    Begin
     nLastMove := aBoard[3,1];
     bMatch    := ( ( nLastMove = aBoard[2,2] ) And
                    ( nLastMove = aBoard[1,3] ) );
    End;
  End;

  If( bMatch )  Then
  Begin
    GotoXY( 10, 18 );
    Write( 'Player -> ', nLastMove, ' won' );
    UpdateScore( nLastMove );
  End
  Else
  Begin
    If( nMoveCnt = 9 )  Then   { No winner }
    Begin
      GotoXY( 10, 18 );
      Write( 'End game - no winner' );
      bMatch := True;          { Fake match - to redraw board }
    End;

    { Change player order when no winner or a normal round }
    nPlayer := ( ( Not nPlayer ) And 1 );
  End;
End;

(**
  * Main application entry.
  *)
Begin
  { First time initialization }
  nPlayer   := 0;
  bMatch    := True;
  bFinished := False;
  FillChar( aScore, SizeOf( aScore ), 0 );

  Repeat
    If( bMatch And Not bFinished ) Then
    Begin
      ClrScr;
      InitBoard;
      DrawBoard;
    End;

    Input;
    DrawMove;
    GameOverChk;

    GotoXY( 10, 16 );
    Write( 'Continue (Y/n) ???' );
    bFinished := ( UpCase( ReadKey ) = 'N' );
  Until( bFinished );

  ClrScr;
  WriteLn( 'Thanks for playing.' );
End.
