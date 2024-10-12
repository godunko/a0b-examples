--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.STM32F401.USART.Configuration_Utilities;

package body MPU9250_Calibration.Configuration is

   procedure Initialize_UART;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Initialize_UART;

      I2C1.I2C1.Configure;

      IMU_INT_Pin.Configure_EXTI
        (Mode => A0B.STM32F401.GPIO.Rising_Edge,
         Pull => A0B.STM32F401.GPIO.No);
   end Initialize;

   --  procedure LCH is null
   --    with Export, Link_Name => "__gnat_last_chance_handler";

   ---------------------
   -- Initialize_UART --
   ---------------------

   procedure Initialize_UART is
      Configuration : A0B.STM32F401.USART.Asynchronous_Configuration;

   begin
      A0B.STM32F401.USART.Configuration_Utilities.Compute_Configuration
        (Peripheral_Frequency => 84_000_000,
         Baud_Rate            => 115_200,
         Configuration        => Configuration);

      UART1.USART1_Asynchronous.Configure (Configuration);
   end Initialize_UART;

end MPU9250_Calibration.Configuration;
