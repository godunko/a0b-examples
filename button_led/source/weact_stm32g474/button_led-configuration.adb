--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.STM32;

package body Button_LED.Configuration is

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Key.Initialize_External_Interrupt
        (Mode => A0B.STM32.Falling_Edge,
         Pull => A0B.STM32G474.GPIO.Pull_Down);

      LED.Initialize_Output;
   end Initialize;

end Button_LED.Configuration;
