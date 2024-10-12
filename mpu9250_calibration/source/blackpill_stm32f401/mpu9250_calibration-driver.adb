--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.ARMv7M.SysTick;
with A0B.STM32F401.TIM11_Timer;

with MPU9250_Calibration.Configuration;
with MPU9250_Calibration.UI;

procedure MPU9250_Calibration.Driver is
begin
   A0B.ARMv7M.SysTick.Initialize
    (Use_Processor_Clock => True,
     Clock_Frequency     => 84_000_000);
   A0B.STM32F401.TIM11_Timer.Initialize
     (Timer_Peripheral_Frequency => 84_000_000);

   MPU9250_Calibration.Configuration.Initialize;

   MPU9250_Calibration.UI.Run;
end MPU9250_Calibration.Driver;
