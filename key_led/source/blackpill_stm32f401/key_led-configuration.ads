--
--  Copyright (C) 2024-2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.STM32F401.GPIO.PIOA;
with A0B.STM32F401.GPIO.PIOC;

package Key_LED.Configuration
  with Preelaborate
is

   LED : A0B.STM32F401.GPIO.GPIO_Line renames A0B.STM32F401.GPIO.PIOC.PC13;
   Key : A0B.STM32F401.GPIO.GPIO_Line renames A0B.STM32F401.GPIO.PIOA.PA0;

   procedure Initialize;
   --  Configure pins.

end Key_LED.Configuration;
