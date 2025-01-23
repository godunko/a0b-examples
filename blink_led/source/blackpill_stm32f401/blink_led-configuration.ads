--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.STM32F401.GPIO.PIOC;

package Blink_LED.Configuration
  with Preelaborate
is

   LED : A0B.STM32F401.GPIO.GPIO_Line renames A0B.STM32F401.GPIO.PIOC.PC13;

   procedure Initialize;
   --  Configure SysTick timer and pins.

end Blink_LED.Configuration;
