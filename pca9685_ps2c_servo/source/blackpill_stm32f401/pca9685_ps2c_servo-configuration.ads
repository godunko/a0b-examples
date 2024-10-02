--
--  Copyright (C) 2024, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  PCA9685/PS2C/Servo configuration for BlackPill STM32F401 board

with A0B.PCA9685.Drivers;
with A0B.PlayStation2_Controllers.Communications;
with A0B.STM32F401.DMA.DMA1.Stream0;
with A0B.STM32F401.DMA.DMA1.Stream6;
with A0B.STM32F401.GPIO.PIOA;
with A0B.STM32F401.GPIO.PIOB;
with A0B.STM32F401.I2C.Generic_I2C1;
with A0B.STM32F401.USART.Generic_USART2_SPI;

package PCA9685_PS2C_Servo.Configuration
  with Preelaborate
is

   package I2C1 is
     new A0B.STM32F401.I2C.Generic_I2C1
       (Transmit_Stream => A0B.STM32F401.DMA.DMA1.Stream6.DMA1_Stream6'Access,
        Receive_Stream  => A0B.STM32F401.DMA.DMA1.Stream0.DMA1_Stream0'Access,
        SCL_Pin         => A0B.STM32F401.GPIO.PIOB.PB8'Access,
        SDA_Pin         => A0B.STM32F401.GPIO.PIOB.PB9'Access);

   PWM_Controller : aliased A0B.PCA9685.Drivers.PCA9685_Controller_Driver
    (Controller => I2C1.I2C1'Access,
     Address    => 16#40#);

   package USART2_SPI is
     new A0B.STM32F401.USART.Generic_USART2_SPI
       (MOSI_Pin => A0B.STM32F401.GPIO.PIOA.PA2'Access,
        MISO_Pin => A0B.STM32F401.GPIO.PIOA.PA3'Access,
        SCK_Pin  => A0B.STM32F401.GPIO.PIOA.PA4'Access,
        NSS_Pin  => A0B.STM32F401.GPIO.PIOA.PA1'Access);

   SPI_Device : A0B.STM32F401.USART.USART_SPI_Device
     renames USART2_SPI.USART2_SPI;
   ACK_Pin    : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOB.PB2;

   PS2C_Controller :
     A0B.PlayStation2_Controllers.Communications.Communication_Driver
       (SPI_Device'Access,
        ACK_Pin'Access);

   procedure Initialize;

end PCA9685_PS2C_Servo.Configuration;
