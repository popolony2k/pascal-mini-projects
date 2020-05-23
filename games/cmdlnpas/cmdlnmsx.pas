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
 * - fixedpt.pas
 * - cmdtpdef.pas;
 * - cmdlndef.pas;
 * - cmdlnvar.pas;
 * - cmdhwmsx.pas;
 * - cmdlnrun.pas;
 *)

{$r- x+ a- v- c-}

{$i .\poplib\types.pas}
{$i .\poplib\systypes.pas}
{$i .\poplib\system.pas}
{$i .\poplib\dvram.pas}
{$i .\poplib\msxbios.pas}
{$i .\poplib\conio.pas}
{$i .\poplib\fixedpt.pas}
{$i .\msx\cmdtpdef.pas}
{$i .\common\cmdlndef.pas}
{$i .\common\cmdlnvar.pas}
{$i .\msx\cmdhwmsx.pas}
{$i .\common\cmdlnrun.pas}


Begin                   { Main entry point }
  InitEngine;           { Initialize engine data       }
  OpenOutputDevice;     { Initialize the output device }
  RunEngine;            { Run FPS engine               }
  CloseOutputDevice;    { Close the output device      }
End.

{ That's It!! - PopolonY2k }