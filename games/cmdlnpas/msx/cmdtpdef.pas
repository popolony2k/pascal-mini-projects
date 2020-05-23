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
 * -
 *)


(*
 * Constants, variables and data structures definitions.
 *)
Const
      ctScreenWidth       =  40;       { Console Screen Size X (columns) }
      ctScreenHeight      =  23;       { Console Screen Size Y (rows)    }
      ctScrnBufWidth      =  39;       { ctScreenWidth  - 1              }
      ctScrnBufHeight     =  22;       { ctScreenHeight - 1              }
      ctMapWidth          =  12;       { World Dimensions                }
      ctMapHeight         =  12;
      ctMapBufWidth       =  11;       { ctMapWidth - 1                  }
      ctMapBufHeight      =  11;       { ctMapHeight - 1                 }
      ctMapRowData        =  13;       { ctMapWidth + 1                  }
      { Shade definition }
      ctCloseDistShade    = 'X';       { Very close shade                }
      ctLowDistShade      = 'x';       { Low distance shade              }
      ctMedDistShade      = '*';       { Medium distance shade           }
      ctHighDistShade     = '''';      { High distance shade             }
      ctFarDistShade      = ' ';       { Too far away shade              }

Type
      TMapStatus   = String[40];       { Map status bar                  }
