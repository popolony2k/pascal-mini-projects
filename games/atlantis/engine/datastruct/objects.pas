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

(*
 * This module depends on following include files (respect the order):
 * -
 *)

Type TSize = Record     { Object size definition }
  nWidth   : Integer;
  nHeight  : Integer;
End;

Type TPosition = Record { Object position definition }
  x,y      : Integer;
End;

Type TTile = Record     { Tile object definition }
  nIndex   : Integer;
  size     : TSize;
  position : TPosition;
End;

Type TSprite = TTile;   { Sprite object definition }
