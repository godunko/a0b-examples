--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Blackpill STM32F401

with A0B.ARMv7M.CMSIS;
with A0B.ARMv7M.SysTick;
with A0B.STM32F401.TIM11_Timer;

with PCA9685_PS2C_Servo.Configuration;
with PCA9685_PS2C_Servo.Demo;

procedure PCA9685_PS2C_Servo.Driver is
begin
   A0B.ARMv7M.SysTick.Initialize
    (Use_Processor_Clock => True,
     Clock_Frequency     => 84_000_000);
   A0B.STM32F401.TIM11_Timer.Initialize
     (Timer_Peripheral_Frequency => 84_000_000);

   PCA9685_PS2C_Servo.Configuration.Initialize;

   PCA9685_PS2C_Servo.Demo.Run;

   loop
      A0B.ARMv7M.CMSIS.Wait_For_Interrupt;
   end loop;
end PCA9685_PS2C_Servo.Driver;
