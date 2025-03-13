--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.STM32G474.GPIO;
with A0B.STM32G474.GPIOC;

package Blink_LED.Configuration
  with Preelaborate
is

   LED : A0B.STM32G474.GPIO.GPIO_EXTI_Line
     renames A0B.STM32G474.GPIOC.PC6;

   procedure Initialize;
   --  Configure SysTick timer and pins.

end Blink_LED.Configuration;
