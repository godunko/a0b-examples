--
--  Copyright (C) 2024-2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.ARMv7M.Instructions;

with Button_LED.Application;

procedure Button_LED.Driver is
begin
   Button_LED.Application.Initialize;

   A0B.ARMv7M.Instructions.Enable_Interrupts;

   loop
      --  Switch CPU into lower power mode.

      A0B.ARMv7M.Instructions.Wait_For_Interrupt;
   end loop;
end Button_LED.Driver;
