--
--  Copyright (C) 2025, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with A0B.STM32F401.USART.Configuration_Utilities;

package body Configuration
  with Preelaborate
is

   procedure Initialize_UART;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      Initialize_UART;
   end Initialize;

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

end Configuration;
