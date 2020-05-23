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
 * - cmdtpdef.pas;
 * - cmdpdefs.pas;
 *)

(*
 * Constants and data structures definition.
 *)
Const
         ctFixedBitsFrac        =    6;    { Fractional fixed point bits     }
         ctPlayerX       : Real =  4.0;    { Player initial coordinates      }
         ctPlayerY       : Real =  8.0;
         ctDepth         : Real = 16.0;    { Maximum rendering distance      }
         ctFOVDivisor    : Real =  2.0;    { Field of view divisor           }
         ctStepSize      : Real =  0.1;    { Increment size for ray casting, }
                                           { decrease to increase resolution }
                                           { unit vector for ray in player   }
                                           { space                           }

Type
      TMapRowData   = String[ctMapRowData];          { Map row data          }
