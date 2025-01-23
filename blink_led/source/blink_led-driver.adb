--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.ARMv7M.Instructions;

with Blink_LED.Application;
with Blink_LED.Configuration;

procedure Blink_LED.Driver is
begin
   Blink_LED.Configuration.Initialize;
   Blink_LED.Application.Initialize;

   A0B.ARMv7M.Instructions.Enable_Interrupts;

   loop
      --  Switch CPU into lower power mode.

      A0B.ARMv7M.Instructions.Wait_For_Interrupt;
   end loop;
end Blink_LED.Driver;
