--
--  Copyright (C) 2024-2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package body Button_LED.Configuration is

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Key.Configure_EXTI
        (Mode => A0B.STM32F401.GPIO.Falling_Edge,
         Pull => A0B.STM32F401.GPIO.Pull_Up);

      LED.Configure_Output;
   end Initialize;

end Button_LED.Configuration;
