--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.ARMv7M.SysTick_Clock_Timer;

package body Blink_LED.Configuration is

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      A0B.ARMv7M.SysTick_Clock_Timer.Initialize
        (Use_Processor_Clock => True,
         Clock_Frequency     => 150_000_000);

      LED.Initialize_Output;
   end Initialize;

end Blink_LED.Configuration;
