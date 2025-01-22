--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package body Key_LED.Configuration is

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Key.Controller.Configure_Debouncing_Divider (1_024);
      Key.Configure_EXTI
        (Mode   => A0B.ATSAM3X8E.PIO.Falling_Edge,
         Filter => A0B.ATSAM3X8E.PIO.Debouncing,
         Pullup => True);

      LED.Configure_Output;
   end Initialize;

end Key_LED.Configuration;
