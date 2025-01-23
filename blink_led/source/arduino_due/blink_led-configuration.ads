--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  It is configuration file for Arduino Due board.

with A0B.ATSAM3X8E.PIO.PIOB;

package Blink_LED.Configuration
  with Preelaborate
is

   LED : A0B.ATSAM3X8E.PIO.ATSAM3X8E_Pin renames A0B.ATSAM3X8E.PIO.PIOB.PB27;

   procedure Initialize;
   --  Configure SysTick timer and pins.

end Blink_LED.Configuration;
