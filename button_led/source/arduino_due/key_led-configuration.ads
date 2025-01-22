--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  It is configuration file for Arduino Due board.
--
--  It use on board LED and pin 53 to connect button.

with A0B.ATSAM3X8E.PIO.PIOB;

package Key_LED.Configuration
  with Preelaborate
is

   LED : A0B.ATSAM3X8E.PIO.ATSAM3X8E_Pin renames A0B.ATSAM3X8E.PIO.PIOB.PB27;
   Key : A0B.ATSAM3X8E.PIO.ATSAM3X8E_Pin renames A0B.ATSAM3X8E.PIO.PIOB.PB14;
   --  Pin 53

   procedure Initialize;
   --  Configure pins.

end Key_LED.Configuration;
