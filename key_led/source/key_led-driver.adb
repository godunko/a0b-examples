--
--  Copyright (C) 2024-2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.ARMv7M.Instructions;

with Key_LED.Application;

procedure Key_LED.Driver is
begin
   Key_LED.Application.Initialize;

   A0B.ARMv7M.Instructions.Enable_Interrupts;

   loop
      --  Switch CPU into lower power mode.

      A0B.ARMv7M.Instructions.Wait_For_Interrupt;
   end loop;
end Key_LED.Driver;
