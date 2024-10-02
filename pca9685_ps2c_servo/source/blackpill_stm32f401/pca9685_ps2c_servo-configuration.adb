--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.STM32F401.SVD.RCC;

package body PCA9685_PS2C_Servo.Configuration is

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      A0B.STM32F401.SVD.RCC.RCC_Periph.AHB1ENR.GPIOAEN  := True;
      A0B.STM32F401.SVD.RCC.RCC_Periph.AHB1ENR.GPIOBEN  := True;
      A0B.STM32F401.SVD.RCC.RCC_Periph.APB2ENR.SYSCFGEN := True;

      I2C1.I2C1.Configure;

      USART2_SPI.USART2_SPI.Configure;

      ACK_Pin.Configure_EXTI
        (Mode => A0B.STM32F401.GPIO.Rising_Edge,
         Pull => A0B.STM32F401.GPIO.No);

      PS2C_Controller.Initialize;
   end Initialize;

end PCA9685_PS2C_Servo.Configuration;
