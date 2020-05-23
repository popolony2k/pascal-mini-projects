(*<systypes.pas>
 * Type definition for system operations related.
 * CopyLeft (c) since 1995 by PopolonY2k.
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


(**
  * The host interrupt timing.
  *)
Type THostInterruptTiming = ( TimingUndefined, Timing50Hz, Timing60Hz );


(**
  * MSX system variables for timming control.
  *)
Var
         JIFFY     : Integer Absolute $FC9E; { MSX JIFFY variable  }
