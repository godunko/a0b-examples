--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  with A0B.ARMv7M.Instructions;
with A0B.ARMv7M.SysTick_Clock;
with A0B.STM32F401.TIM11_Timer;

with Configuration;
with DC_Motor_L298.Application;

procedure DC_Motor_L298.Driver is
begin
   A0B.ARMv7M.SysTick_Clock.Initialize
     (Use_Processor_Clock => True,
      Clock_Frequency     => 84_000_000);
   A0B.STM32F401.TIM11_Timer.Initialize
     (Timer_Peripheral_Frequency => 84_000_000);

   Configuration.Initialize;
   DC_Motor_L298.Application.Initialize;
   DC_Motor_L298.Application.Run;

   --  A0B.ARMv7M.Instructions.Enable_Interrupts;
end DC_Motor_L298.Driver;
